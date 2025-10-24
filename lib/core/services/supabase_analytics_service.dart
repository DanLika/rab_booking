import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:universal_io/io.dart' show Platform;

/// Supabase-based analytics service
/// Tracks user events and behavior using Supabase as backend
class SupabaseAnalyticsService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final _uuid = const Uuid();

  /// Generate or retrieve session ID
  static String? _sessionId;
  static String get sessionId {
    _sessionId ??= _uuid.v4();
    return _sessionId!;
  }

  /// Track an analytics event
  static Future<void> trackEvent({
    required String eventName,
    String? eventCategory,
    Map<String, dynamic>? properties,
  }) async {
    try {
      // Don't track in debug mode unless explicitly enabled
      if (kDebugMode) {
        debugPrint('[Supabase Analytics] $eventName: $properties');
        // Uncomment to enable analytics in debug mode:
        // return;
      }

      final userId = _supabase.auth.currentUser?.id;

      final deviceInfo = _getDeviceInfo();

      await _supabase.from('analytics_events').insert({
        'user_id': userId,
        'session_id': sessionId,
        'event_name': eventName,
        'event_category': eventCategory,
        'properties': properties ?? {},
        'device_info': deviceInfo,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('[Analytics] Event tracked: $eventName');
    } catch (e, stackTrace) {
      // Don't let analytics errors break the app
      debugPrint('[Analytics] Error tracking event $eventName: $e');
      if (kDebugMode) {
        debugPrint('[Analytics] Stack trace: $stackTrace');
      }
    }
  }

  /// Get device information
  static Map<String, dynamic> _getDeviceInfo() {
    try {
      if (kIsWeb) {
        return {
          'platform': 'web',
          'user_agent': 'web_browser',
        };
      }

      return {
        'platform': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'is_mobile': Platform.isAndroid || Platform.isIOS,
      };
    } catch (e) {
      return {'platform': 'unknown'};
    }
  }

  // Predefined event tracking methods

  /// Track page/screen view
  static Future<void> trackScreenView(String screenName) async {
    await trackEvent(
      eventName: 'screen_view',
      eventCategory: 'navigation',
      properties: {'screen_name': screenName},
    );
  }

  /// Track property view
  static Future<void> trackPropertyView({
    required String propertyId,
    required String propertyName,
    double? price,
  }) async {
    await trackEvent(
      eventName: 'property_viewed',
      eventCategory: 'property',
      properties: {
        'property_id': propertyId,
        'property_name': propertyName,
        if (price != null) 'price': price,
      },
    );
  }

  /// Track search
  static Future<void> trackSearch({
    String? location,
    int? guests,
    DateTime? checkIn,
    DateTime? checkOut,
    int? resultCount,
  }) async {
    await trackEvent(
      eventName: 'search_performed',
      eventCategory: 'search',
      properties: {
        if (location != null) 'location': location,
        if (guests != null) 'guests': guests,
        if (checkIn != null) 'check_in': checkIn.toIso8601String(),
        if (checkOut != null) 'check_out': checkOut.toIso8601String(),
        if (resultCount != null) 'result_count': resultCount,
      },
    );
  }

  /// Track booking creation
  static Future<void> trackBookingCreated({
    required String bookingId,
    required String propertyId,
    required double amount,
    required int nights,
    required int guests,
  }) async {
    await trackEvent(
      eventName: 'booking_created',
      eventCategory: 'booking',
      properties: {
        'booking_id': bookingId,
        'property_id': propertyId,
        'amount': amount,
        'nights': nights,
        'guests': guests,
      },
    );
  }

  /// Track booking cancellation
  static Future<void> trackBookingCancelled({
    required String bookingId,
    required String reason,
  }) async {
    await trackEvent(
      eventName: 'booking_cancelled',
      eventCategory: 'booking',
      properties: {
        'booking_id': bookingId,
        'reason': reason,
      },
    );
  }

  /// Track authentication
  static Future<void> trackAuth(String action, {String? method}) async {
    await trackEvent(
      eventName: 'auth_$action',
      eventCategory: 'auth',
      properties: {
        if (method != null) 'method': method,
      },
    );
  }

  /// Track favorite action
  static Future<void> trackFavorite({
    required String propertyId,
    required bool added,
  }) async {
    await trackEvent(
      eventName: added ? 'favorite_added' : 'favorite_removed',
      eventCategory: 'engagement',
      properties: {'property_id': propertyId},
    );
  }

  /// Track share
  static Future<void> trackShare({
    required String contentType,
    required String contentId,
    String? platform,
  }) async {
    await trackEvent(
      eventName: 'content_shared',
      eventCategory: 'engagement',
      properties: {
        'content_type': contentType,
        'content_id': contentId,
        if (platform != null) 'platform': platform,
      },
    );
  }

  /// Track error
  static Future<void> trackError({
    required String error,
    String? screen,
    Map<String, dynamic>? context,
  }) async {
    await trackEvent(
      eventName: 'error_occurred',
      eventCategory: 'error',
      properties: {
        'error': error,
        if (screen != null) 'screen': screen,
        if (context != null) ...context,
      },
    );
  }

  /// Set user properties (for segmentation)
  static Future<void> setUserProperties(Map<String, dynamic> properties) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Store in user metadata
      await _supabase.auth.updateUser(
        UserAttributes(
          data: properties,
        ),
      );

      debugPrint('[Analytics] User properties set: $properties');
    } catch (e) {
      debugPrint('[Analytics] Error setting user properties: $e');
    }
  }

  /// Clear session (call on logout)
  static void clearSession() {
    _sessionId = null;
    debugPrint('[Analytics] Session cleared');
  }
}
