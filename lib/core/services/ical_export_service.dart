import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/unit_model.dart';
import '../../shared/repositories/booking_repository.dart';
import '../../features/widget/data/repositories/firebase_widget_settings_repository.dart';
import '../constants/enums.dart';
import 'ical_generator.dart';
import 'logging_service.dart';

/// Service for managing iCal export functionality
///
/// Handles:
/// - Generating .ics files from bookings
/// - Uploading to Firebase Storage
/// - Auto-regeneration when bookings change
/// - Public URL management
class IcalExportService {
  final BookingRepository _bookingRepository;
  final FirebaseWidgetSettingsRepository _settingsRepository;
  final FirebaseStorage _storage;

  IcalExportService({
    required BookingRepository bookingRepository,
    required FirebaseWidgetSettingsRepository settingsRepository,
    FirebaseStorage? storage,
  })  : _bookingRepository = bookingRepository,
        _settingsRepository = settingsRepository,
        _storage = storage ?? FirebaseStorage.instance;

  /// Generate and upload iCal file for a unit
  ///
  /// Returns the public download URL
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

      // 2. Generate .ics content
      final icsContent = IcalGenerator.generateUnitCalendar(
        unit: unit,
        bookings: bookings,
      );

      // 3. Upload to Firebase Storage
      final downloadUrl = await _uploadToStorage(
        propertyId: propertyId,
        unitId: unitId,
        icsContent: icsContent,
        unitName: unit.name,
      );

      // 4. Update widget settings with URL and timestamp
      await _updateWidgetSettings(
        propertyId: propertyId,
        unitId: unitId,
        downloadUrl: downloadUrl,
      );

      LoggingService.log(
        'iCal export completed successfully for unit: $unitId',
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

  /// Auto-regenerate iCal if enabled
  ///
  /// Called when bookings are created/updated/cancelled
  /// Only regenerates if icalExportEnabled is true
  Future<void> autoRegenerateIfEnabled({
    required String propertyId,
    required String unitId,
    required UnitModel unit,
  }) async {
    try {
      // Check if iCal export is enabled for this unit
      final settings = await _settingsRepository.getWidgetSettings(
        propertyId: propertyId,
        unitId: unitId,
      );

      if (settings == null || !settings.icalExportEnabled) {
        LoggingService.log(
          'iCal export disabled for unit: $unitId, skipping auto-regeneration',
          tag: 'IcalExportService',
        );
        return;
      }

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
      final allBookings = await _bookingRepository.fetchUnitBookings(unitId);

      // Filter to only include confirmed and pending bookings
      // Exclude cancelled bookings
      final activeBookings = allBookings
          .where((booking) =>
              booking.status == BookingStatus.confirmed ||
              booking.status == BookingStatus.pending ||
              booking.status == BookingStatus.completed)
          .toList();

      // Sort by check-in date
      activeBookings.sort((a, b) => a.checkIn.compareTo(b.checkIn));

      return activeBookings;
    } catch (e) {
      LoggingService.log(
        'Error fetching unit bookings: $e',
        tag: 'IcalExportService',
      );
      rethrow;
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

      LoggingService.log(
        'iCal file uploaded successfully: $path',
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

  /// Update widget settings with iCal URL and timestamp
  Future<void> _updateWidgetSettings({
    required String propertyId,
    required String unitId,
    required String downloadUrl,
  }) async {
    try {
      final settings = await _settingsRepository.getWidgetSettings(
        propertyId: propertyId,
        unitId: unitId,
      );

      if (settings == null) {
        LoggingService.log(
          'Widget settings not found for unit: $unitId, cannot update iCal URL',
          tag: 'IcalExportService',
        );
        return;
      }

      final updatedSettings = settings.copyWith(
        icalExportUrl: downloadUrl,
        icalExportLastGenerated: DateTime.now(),
      );

      await _settingsRepository.updateWidgetSettings(updatedSettings);

      LoggingService.log(
        'Widget settings updated with iCal URL',
        tag: 'IcalExportService',
      );
    } catch (e) {
      LoggingService.log(
        'Error updating widget settings: $e',
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
}
