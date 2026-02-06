import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../features/owner_dashboard/domain/models/ical_feed.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/unit_model.dart';
import '../../shared/repositories/booking_repository.dart';
import 'ical_generator.dart';
import 'logging_service.dart';

/// Service for managing iCal export functionality.
///
/// Handles:
/// - Generating .ics files from bookings
/// - Uploading to Firebase Storage
/// - Auto-regeneration when bookings change
/// - Public URL management
///
/// Usage:
/// ```dart
/// final service = IcalExportService(bookingRepository: repo);
///
/// // Generate and upload iCal
/// final url = await service.generateAndUploadIcal(
///   propertyId: 'prop123',
///   unitId: 'unit456',
///   unit: unitModel,
/// );
///
/// // Auto-regenerate on booking changes
/// await service.autoRegenerateIfEnabled(
///   propertyId: 'prop123',
///   unitId: 'unit456',
///   unit: unitModel,
/// );
/// ```
class IcalExportService {
  final BookingRepository _bookingRepository;
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  IcalExportService({
    required BookingRepository bookingRepository,
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  }) : _bookingRepository = bookingRepository,
       _storage = storage ?? FirebaseStorage.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Generate and upload iCal file for a unit
  ///
  /// Returns the public download URL
  /// Includes both native bookings AND imported iCal events from external platforms
  Future<String> generateAndUploadIcal({
    required String propertyId,
    required String unitId,
    required UnitModel unit,
  }) async {
    try {
      LoggingService.log(
        'Starting iCal generation for unit: $unitId',
        tag: 'IcalExportService',
      );

      // 1. Fetch all bookings for the unit
      final bookings = await _fetchUnitBookings(unitId);

      LoggingService.log(
        'Fetched ${bookings.length} bookings for unit: $unitId',
        tag: 'IcalExportService',
      );

      // 2. Fetch imported iCal events (from Booking.com, Airbnb, etc.)
      final importedEvents = await _fetchImportedIcalEvents(propertyId, unitId);

      LoggingService.log(
        'Fetched ${importedEvents.length} imported iCal events for unit: $unitId',
        tag: 'IcalExportService',
      );

      // 3. Generate .ics content (includes both bookings and imported events)
      final icsContent = IcalGenerator.generateUnitCalendar(
        unit: unit,
        bookings: bookings,
        importedEvents: importedEvents,
      );

      // 4. Upload to Firebase Storage
      final downloadUrl = await _uploadToStorage(
        propertyId: propertyId,
        unitId: unitId,
        icsContent: icsContent,
        unitName: unit.name,
      );

      LoggingService.log(
        'iCal export completed successfully for unit: $unitId, URL: ${_redactTokenFromUrl(downloadUrl)}',
        tag: 'IcalExportService',
      );

      return downloadUrl;
    } catch (e, stackTrace) {
      await LoggingService.logError(
        'Error generating iCal export: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Auto-regenerate iCal (always enabled)
  ///
  /// Called when bookings are created/updated/cancelled
  Future<void> autoRegenerateIfEnabled({
    required String propertyId,
    required String unitId,
    required UnitModel unit,
  }) async {
    try {
      LoggingService.log(
        'Auto-regenerating iCal for unit: $unitId',
        tag: 'IcalExportService',
      );

      await generateAndUploadIcal(
        propertyId: propertyId,
        unitId: unitId,
        unit: unit,
      );
    } catch (e) {
      LoggingService.log(
        'Error in auto-regeneration: $e',
        tag: 'IcalExportService',
      );
      // Don't rethrow - auto-regeneration failures shouldn't break booking operations
    }
  }

  /// Delete iCal file from storage
  ///
  /// Called when iCal export is disabled or unit is deleted
  Future<void> deleteIcalFile({
    required String propertyId,
    required String unitId,
  }) async {
    try {
      final path = _getStoragePath(propertyId, unitId);
      final ref = _storage.ref(path);

      await ref.delete();

      LoggingService.log(
        'iCal file deleted for unit: $unitId',
        tag: 'IcalExportService',
      );
    } catch (e) {
      if (e is FirebaseException && e.code == 'object-not-found') {
        // File doesn't exist, that's fine
        LoggingService.log(
          'iCal file not found for unit: $unitId (already deleted)',
          tag: 'IcalExportService',
        );
      } else {
        LoggingService.log(
          'Error deleting iCal file: $e',
          tag: 'IcalExportService',
        );
        rethrow;
      }
    }
  }

  /// Check if iCal file exists in storage
  Future<bool> icalFileExists({
    required String propertyId,
    required String unitId,
  }) async {
    try {
      final path = _getStoragePath(propertyId, unitId);
      final ref = _storage.ref(path);

      // Try to get metadata - if it exists, no exception is thrown
      await ref.getMetadata();
      return true;
    } catch (e) {
      if (e is FirebaseException && e.code == 'object-not-found') {
        return false;
      }
      rethrow;
    }
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Fetch all confirmed bookings for a unit
  Future<List<BookingModel>> _fetchUnitBookings(String unitId) async {
    try {
      // Repository now returns only confirmed, pending, completed bookings
      // (cancelled bookings are excluded at the query level for security rules compliance)
      final bookings = await _bookingRepository.fetchUnitBookings(unitId);

      // Sort by check-in date
      final sortedBookings = List<BookingModel>.from(bookings)
        ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

      return sortedBookings;
    } catch (e) {
      LoggingService.log(
        'Error fetching unit bookings: $e',
        tag: 'IcalExportService',
      );
      rethrow;
    }
  }

  /// Fetch imported iCal events for a unit
  ///
  /// These are reservations imported from external platforms (Booking.com, Airbnb, etc.)
  /// Stored in: properties/{propertyId}/ical_events/{eventId}
  Future<List<IcalEvent>> _fetchImportedIcalEvents(
    String propertyId,
    String unitId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ical_events')
          .where('unit_id', isEqualTo: unitId)
          .orderBy('start_date')
          .get();

      final events = snapshot.docs
          .map(IcalEvent.fromFirestore)
          .where(
            (e) => !e.isConfirmedEcho,
          ) // Exclude confirmed echoes from export
          .toList();

      return events;
    } catch (e) {
      LoggingService.log(
        'Error fetching imported iCal events: $e',
        tag: 'IcalExportService',
      );
      // Return empty list on error - don't fail the export
      // Native bookings are more important than imported events
      return [];
    }
  }

  /// Upload .ics content to Firebase Storage
  ///
  /// Returns public download URL
  Future<String> _uploadToStorage({
    required String propertyId,
    required String unitId,
    required String icsContent,
    required String unitName,
  }) async {
    try {
      final path = _getStoragePath(propertyId, unitId);
      final ref = _storage.ref(path);

      // Convert string to bytes (UTF-8 encoding)
      final bytes = utf8.encode(icsContent);

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'text/calendar',
        contentDisposition:
            'attachment; filename="${IcalGenerator.generateFilename(unitName)}"',
        customMetadata: {
          'unitId': unitId,
          'propertyId': propertyId,
          'generatedAt': DateTime.now().toIso8601String(),
        },
      );

      await ref.putData(bytes, metadata);

      // Get public download URL
      final downloadUrl = await ref.getDownloadURL();

      // Log success but REDACT the token from the URL to prevent leaks in logs
      // The full URL contains a long-lived token that allows public access
      final redactedUrl = _redactTokenFromUrl(downloadUrl);
      LoggingService.log(
        'iCal file uploaded successfully: $path (URL: $redactedUrl)',
        tag: 'IcalExportService',
      );

      return downloadUrl;
    } catch (e) {
      LoggingService.log(
        'Error uploading to storage: $e',
        tag: 'IcalExportService',
      );
      rethrow;
    }
  }

  /// Get Firebase Storage path for iCal file
  ///
  /// Path format: ical-exports/{propertyId}/{unitId}/calendar.ics
  String _getStoragePath(String propertyId, String unitId) {
    return 'ical-exports/$propertyId/$unitId/calendar.ics';
  }

  /// Redact token parameter from URL for logging safety
  String _redactTokenFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (!uri.queryParameters.containsKey('token')) return url;

      final newParams = Map<String, dynamic>.from(uri.queryParameters);
      newParams['token'] = '[REDACTED]';

      return uri.replace(queryParameters: newParams).toString();
    } catch (e) {
      return url;
    }
  }
}
