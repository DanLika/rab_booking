import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/widget/domain/models/widget_settings.dart';
import '../../shared/models/booking_model.dart';
// ignore: unused_import
import '../utils/date_time_parser.dart'; // Used in commented example code
import 'logging_service.dart';
import '../exceptions/app_exceptions.dart';

/// Service for syncing with external calendar platforms (Booking.com, Airbnb)
///
/// This service handles:
/// - OAuth authentication with external platforms
/// - Periodic sync of external bookings
/// - Importing external bookings to prevent double-booking
/// - Updating sync status
class ExternalCalendarSyncService {
  final FirebaseFirestore _firestore;
  final http.Client _httpClient;

  ExternalCalendarSyncService({
    FirebaseFirestore? firestore,
    http.Client? httpClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _httpClient = httpClient ?? http.Client();

  /// Check if sync is needed based on sync interval
  bool isSyncNeeded(ExternalCalendarConfig config) {
    if (!config.enabled) return false;
    if (config.lastSyncedAt == null) return true;

    final nextSync = config.lastSyncedAt!
        .add(Duration(minutes: config.syncIntervalMinutes));
    return DateTime.now().isAfter(nextSync);
  }

  /// Sync all external calendars for a property
  ///
  /// This should be called periodically (e.g., via Cloud Function)
  Future<void> syncExternalCalendars({
    required String propertyId,
    required String ownerId,
    required ExternalCalendarConfig config,
  }) async {
    try {
      LoggingService.logOperation(
          '[ExternalCalendarSync] Starting sync for property $propertyId');

      final bookings = <BookingModel>[];

      // Sync Booking.com
      if (config.syncBookingCom &&
          config.bookingComAccountId != null &&
          config.bookingComAccessToken != null) {
        LoggingService.logDebug('[ExternalCalendarSync] Syncing Booking.com...');
        final bookingComBookings = await _syncBookingCom(
          propertyId: propertyId,
          ownerId: ownerId,
          accountId: config.bookingComAccountId!,
          accessToken: config.bookingComAccessToken!,
        );
        bookings.addAll(bookingComBookings);
        LoggingService.logSuccess(
            '[ExternalCalendarSync] Booking.com sync complete: ${bookingComBookings.length} bookings');
      }

      // Sync Airbnb
      if (config.syncAirbnb &&
          config.airbnbAccountId != null &&
          config.airbnbAccessToken != null) {
        LoggingService.logDebug('[ExternalCalendarSync] Syncing Airbnb...');
        final airbnbBookings = await _syncAirbnb(
          propertyId: propertyId,
          ownerId: ownerId,
          accountId: config.airbnbAccountId!,
          accessToken: config.airbnbAccessToken!,
        );
        bookings.addAll(airbnbBookings);
        LoggingService.logSuccess(
            '[ExternalCalendarSync] Airbnb sync complete: ${airbnbBookings.length} bookings');
      }

      // Import bookings to Firestore
      if (bookings.isNotEmpty) {
        await _importExternalBookings(bookings, propertyId);
        LoggingService.logSuccess(
            '[ExternalCalendarSync] Imported ${bookings.length} external bookings');
      }

      // Update last synced timestamp in widget settings
      await _updateLastSyncedTimestamp(propertyId);

      LoggingService.logSuccess(
          '[ExternalCalendarSync] Sync complete for property $propertyId');
    } catch (e) {
      await LoggingService.logError(
          '[ExternalCalendarSync] Sync failed for property $propertyId', e);
      throw ExternalCalendarSyncException('External calendar sync failed: $e');
    }
  }

  /// Sync bookings from Booking.com API
  ///
  /// Note: This is a placeholder implementation
  /// Actual Booking.com API integration requires:
  /// 1. Partner Hub account approval
  /// 2. OAuth 2.0 flow implementation
  /// 3. Booking.com Connectivity API access
  Future<List<BookingModel>> _syncBookingCom({
    required String propertyId,
    required String ownerId,
    required String accountId,
    required String accessToken,
  }) async {
    try {
      // TODO: Implement actual Booking.com API integration
      // For now, this is a placeholder that demonstrates the structure

      // Booking.com Connectivity API endpoint (example)
      // https://connect.booking.com/v1/reservations

      LoggingService.logWarning(
          '[ExternalCalendarSync] Booking.com API not yet implemented - using placeholder');

      // In production, you would:
      // 1. Make authenticated request to Booking.com API
      // 2. Fetch reservations for the property
      // 3. Transform API response to BookingModel
      // 4. Filter for future bookings only

      // Example API call (commented out as it requires real credentials):
      /*
      final response = await _httpClient.get(
        Uri.parse('https://connect.booking.com/v1/reservations?property_id=$accountId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw IntegrationException.apiFailed('Booking.com', 'HTTP ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final bookings = <BookingModel>[];

      for (final reservation in data['reservations']) {
        bookings.add(BookingModel(
          id: 'bookingcom_${reservation['id']}',
          unitId: propertyId, // Map to your unit
          ownerId: ownerId,
          guestName: reservation['guest']['name'],
          guestEmail: reservation['guest']['email'],
          guestPhone: reservation['guest']['phone'],
          checkIn: DateTimeParser.parseOrThrow(
            reservation['check_in'],
            context: 'ExternalCalendarSync.bookingcom.check_in',
          ),
          checkOut: DateTimeParser.parseOrThrow(
            reservation['check_out'],
            context: 'ExternalCalendarSync.bookingcom.check_out',
          ),
          status: BookingStatus.confirmed,
          totalPrice: reservation['total_price'].toDouble(),
          paidAmount: reservation['paid_amount'].toDouble(),
          paymentMethod: 'external',
          paymentStatus: 'paid',
          source: 'booking.com',
          guestCount: reservation['guest_count'],
          createdAt: DateTime.now(),
        ));
      }

      return bookings;
      */

      return []; // Placeholder return
    } catch (e) {
      await LoggingService.logError(
          '[ExternalCalendarSync] Booking.com sync error', e);
      return [];
    }
  }

  /// Sync bookings from Airbnb API
  ///
  /// Note: This is a placeholder implementation
  /// Actual Airbnb API integration requires:
  /// 1. Airbnb Partner program access
  /// 2. OAuth 2.0 flow implementation
  /// 3. Airbnb API credentials
  Future<List<BookingModel>> _syncAirbnb({
    required String propertyId,
    required String ownerId,
    required String accountId,
    required String accessToken,
  }) async {
    try {
      // TODO: Implement actual Airbnb API integration
      // For now, this is a placeholder that demonstrates the structure

      // Airbnb API endpoint (example)
      // https://api.airbnb.com/v2/reservations

      LoggingService.logWarning(
          '[ExternalCalendarSync] Airbnb API not yet implemented - using placeholder');

      // In production, you would:
      // 1. Make authenticated request to Airbnb API
      // 2. Fetch reservations for the listing
      // 3. Transform API response to BookingModel
      // 4. Filter for future bookings only

      // Example API call (commented out as it requires real credentials):
      /*
      final response = await _httpClient.get(
        Uri.parse('https://api.airbnb.com/v2/reservations?listing_id=$accountId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Airbnb-API-Key': 'YOUR_API_KEY',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw IntegrationException.apiFailed('Airbnb', 'HTTP ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final bookings = <BookingModel>[];

      for (final reservation in data['reservations']) {
        bookings.add(BookingModel(
          id: 'airbnb_${reservation['confirmation_code']}',
          unitId: propertyId, // Map to your unit
          ownerId: ownerId,
          guestName: reservation['guest']['name'],
          guestEmail: reservation['guest']['email'],
          guestPhone: reservation['guest']['phone'],
          checkIn: DateTimeParser.parseOrThrow(
            reservation['start_date'],
            context: 'ExternalCalendarSync.airbnb.start_date',
          ),
          checkOut: DateTimeParser.parseOrThrow(
            reservation['end_date'],
            context: 'ExternalCalendarSync.airbnb.end_date',
          ),
          status: BookingStatus.confirmed,
          totalPrice: reservation['listing_total'].toDouble(),
          paidAmount: reservation['listing_total'].toDouble(),
          paymentMethod: 'external',
          paymentStatus: 'paid',
          source: 'airbnb',
          guestCount: reservation['number_of_guests'],
          createdAt: DateTime.now(),
        ));
      }

      return bookings;
      */

      return []; // Placeholder return
    } catch (e) {
      await LoggingService.logError('[ExternalCalendarSync] Airbnb sync error', e);
      return [];
    }
  }

  /// Import external bookings to Firestore
  ///
  /// This prevents double-booking by marking dates as unavailable
  Future<void> _importExternalBookings(
    List<BookingModel> bookings,
    String propertyId,
  ) async {
    final batch = _firestore.batch();

    for (final booking in bookings) {
      // Only import future bookings
      if (booking.checkOut.isBefore(DateTime.now())) {
        continue;
      }

      // Check if booking already exists
      final existingDoc =
          await _firestore.collection('bookings').doc(booking.id).get();

      if (existingDoc.exists) {
        // Update existing booking
        batch.update(existingDoc.reference, {
          ...booking.toJson(),
          'updated_at': FieldValue.serverTimestamp(),
          'external_sync': true,
        });
      } else {
        // Create new booking
        batch.set(
          _firestore.collection('bookings').doc(booking.id),
          {
            ...booking.toJson(),
            'created_at': FieldValue.serverTimestamp(),
            'external_sync': true,
          },
        );
      }
    }

    await batch.commit();
  }

  /// Update last synced timestamp in widget settings
  Future<void> _updateLastSyncedTimestamp(String propertyId) async {
    final settingsQuery = await _firestore
        .collection('widget_settings')
        .where('property_id', isEqualTo: propertyId)
        .limit(1)
        .get();

    if (settingsQuery.docs.isNotEmpty) {
      await settingsQuery.docs.first.reference.update({
        'external_calendar_config.last_synced_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get OAuth authorization URL for Booking.com
  ///
  /// This URL should be opened in a browser for the user to authorize
  String getBookingComAuthUrl({
    required String clientId,
    required String redirectUri,
    String? state,
  }) {
    // TODO: Replace with actual Booking.com OAuth endpoint
    // This is a placeholder structure

    final params = {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'reservations.read',
      if (state != null) 'state': state,
    };

    final queryString =
        params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

    return 'https://account.booking.com/oauth2/authorize?$queryString';
  }

  /// Get OAuth authorization URL for Airbnb
  ///
  /// This URL should be opened in a browser for the user to authorize
  String getAirbnbAuthUrl({
    required String clientId,
    required String redirectUri,
    String? state,
  }) {
    // TODO: Replace with actual Airbnb OAuth endpoint
    // This is a placeholder structure

    final params = {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'reservations.read',
      if (state != null) 'state': state,
    };

    final queryString =
        params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');

    return 'https://www.airbnb.com/oauth2/auth?$queryString';
  }

  /// Exchange authorization code for access token (Booking.com)
  ///
  /// Called after user authorizes and is redirected back with a code
  Future<String> exchangeBookingComCode({
    required String code,
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  }) async {
    // TODO: Implement actual OAuth token exchange
    // This is a placeholder

    try {
      final response = await _httpClient.post(
        Uri.parse('https://account.booking.com/oauth2/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': clientId,
          'client_secret': clientSecret,
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode != 200) {
        throw IntegrationException('Token exchange failed: ${response.body}', code: 'integration/token-exchange-failed');
      }

      final data = json.decode(response.body);
      return data['access_token'];
    } catch (e) {
      await LoggingService.logError(
          '[ExternalCalendarSync] Booking.com token exchange failed', e);
      throw ExternalCalendarSyncException('Token exchange failed: $e');
    }
  }

  /// Exchange authorization code for access token (Airbnb)
  ///
  /// Called after user authorizes and is redirected back with a code
  Future<String> exchangeAirbnbCode({
    required String code,
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  }) async {
    // TODO: Implement actual OAuth token exchange
    // This is a placeholder

    try {
      final response = await _httpClient.post(
        Uri.parse('https://api.airbnb.com/v1/oauth2/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': clientId,
          'client_secret': clientSecret,
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode != 200) {
        throw IntegrationException('Token exchange failed: ${response.body}', code: 'integration/token-exchange-failed');
      }

      final data = json.decode(response.body);
      return data['access_token'];
    } catch (e) {
      await LoggingService.logError(
          '[ExternalCalendarSync] Airbnb token exchange failed', e);
      throw ExternalCalendarSyncException('Token exchange failed: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// Exception thrown when external calendar sync operations fail
class ExternalCalendarSyncException implements Exception {
  final String message;
  ExternalCalendarSyncException(this.message);

  @override
  String toString() => 'ExternalCalendarSyncException: $message';
}
