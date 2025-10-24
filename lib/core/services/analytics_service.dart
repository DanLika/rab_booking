import 'package:flutter/foundation.dart';
import 'supabase_analytics_service.dart';

/// Analytics and error tracking service
///
/// Now using Supabase Analytics as the primary analytics backend
/// Can be extended with Firebase/Sentry for additional tracking
class AnalyticsService {
  /// Initialize Firebase Crashlytics for error tracking
  ///
  /// To use this:
  /// 1. Add firebase_crashlytics to pubspec.yaml
  /// 2. Set up Firebase in your project
  /// 3. Uncomment the implementation below
  static Future<void> initializeCrashlytics() async {
    // Uncomment when Firebase Crashlytics is set up:
    // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    debugPrint('[ANALYTICS] Firebase Crashlytics initialization placeholder');
  }

  /// Initialize Sentry for error tracking
  ///
  /// To use this:
  /// 1. Add sentry_flutter to pubspec.yaml
  /// 2. Get your Sentry DSN from sentry.io
  /// 3. Uncomment the implementation below
  static Future<void> initializeSentry() async {
    // Uncomment when Sentry is set up:
    // await SentryFlutter.init(
    //   (options) {
    //     options.dsn = 'YOUR_SENTRY_DSN';
    //     options.tracesSampleRate = 1.0;
    //     options.environment = kReleaseMode ? 'production' : 'development';
    //   },
    // );
    debugPrint('[ANALYTICS] Sentry initialization placeholder');
  }

  /// Log custom event
  ///
  /// Examples:
  /// - User actions (booking_created, payment_completed)
  /// - Feature usage (search_performed, filter_applied)
  /// - Business metrics (property_viewed, booking_cancelled)
  static Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    debugPrint('[ANALYTICS] Event: $eventName, params: $parameters');

    // Track with Supabase Analytics
    await SupabaseAnalyticsService.trackEvent(
      eventName: eventName,
      properties: parameters,
    );

    // Can also send to Firebase Analytics if configured:
    // await FirebaseAnalytics.instance.logEvent(
    //   name: eventName,
    //   parameters: parameters,
    // );
  }

  /// Track screen view
  ///
  /// Call this when navigating to a new screen to track user flow
  static void logScreenView(String screenName, {String? screenClass}) {
    logEvent('screen_view', parameters: {
      'screen_name': screenName,
      if (screenClass != null) 'screen_class': screenClass,
    });
  }

  /// Set user ID for analytics
  ///
  /// Call this after successful login to track user-specific metrics
  static void setUserId(String userId) {
    debugPrint('[ANALYTICS] Set user ID: $userId');

    // Uncomment when Firebase Analytics is set up:
    // await FirebaseAnalytics.instance.setUserId(id: userId);
  }

  /// Set user properties
  ///
  /// Track user attributes like role, subscription tier, etc.
  static void setUserProperties(Map<String, String> properties) {
    debugPrint('[ANALYTICS] Set user properties: $properties');

    // Uncomment when Firebase Analytics is set up:
    // for (final entry in properties.entries) {
    //   await FirebaseAnalytics.instance.setUserProperty(
    //     name: entry.key,
    //     value: entry.value,
    //   );
    // }
  }

  /// Report error to tracking services
  ///
  /// This is called automatically by ErrorHandler.logError()
  static Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? extra,
  }) async {
    if (kDebugMode) {
      debugPrint('[ANALYTICS] Would report error in production: $error');
      return;
    }

    // Uncomment when error tracking services are set up:
    // Send to Firebase Crashlytics
    // await FirebaseCrashlytics.instance.recordError(
    //   error,
    //   stackTrace,
    //   reason: extra?['reason'],
    // );

    // Send to Sentry
    // await Sentry.captureException(
    //   error,
    //   stackTrace: stackTrace,
    //   hint: extra != null ? Hint.withMap(extra) : null,
    // );
  }

  /// Log a message to error tracking services
  ///
  /// Useful for non-exception logs that should appear in crash reports
  static void logMessage(String message, {String? level}) {
    debugPrint('[ANALYTICS] Message ($level): $message');

    // Uncomment when error tracking services are set up:
    // await FirebaseCrashlytics.instance.log(message);
    // await Sentry.captureMessage(message, level: _parseSentryLevel(level));
  }

  /// Add breadcrumb to error tracking
  ///
  /// Breadcrumbs help understand the sequence of events leading to an error
  static void addBreadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) {
    debugPrint('[ANALYTICS] Breadcrumb: $message (category: $category)');

    // Uncomment when Sentry is set up:
    // Sentry.addBreadcrumb(
    //   Breadcrumb(
    //     message: message,
    //     category: category,
    //     data: data,
    //   ),
    // );
  }

  // Booking-specific analytics

  /// Track booking creation
  static void logBookingCreated({
    required String propertyId,
    required double amount,
    required int nights,
  }) {
    logEvent('booking_created', parameters: {
      'property_id': propertyId,
      'amount': amount,
      'nights': nights,
    });
  }

  /// Track booking cancellation
  static void logBookingCancelled({
    required String bookingId,
    required String reason,
  }) {
    logEvent('booking_cancelled', parameters: {
      'booking_id': bookingId,
      'reason': reason,
    });
  }

  /// Track payment completion
  static void logPaymentCompleted({
    required String bookingId,
    required double amount,
    required String method,
  }) {
    logEvent('payment_completed', parameters: {
      'booking_id': bookingId,
      'amount': amount,
      'payment_method': method,
    });
  }

  /// Track search performed
  static void logSearchPerformed({
    required String location,
    int? guests,
    DateTime? checkIn,
    DateTime? checkOut,
  }) {
    logEvent('search_performed', parameters: {
      'location': location,
      if (guests != null) 'guests': guests,
      if (checkIn != null) 'check_in': checkIn.toIso8601String(),
      if (checkOut != null) 'check_out': checkOut.toIso8601String(),
    });
  }

  /// Track property viewed
  static Future<void> logPropertyViewed(String propertyId, {String? propertyName, double? price}) async {
    await SupabaseAnalyticsService.trackPropertyView(
      propertyId: propertyId,
      propertyName: propertyName ?? '',
      price: price,
    );
  }

  /// Clear analytics session (call on logout)
  static void clearSession() {
    SupabaseAnalyticsService.clearSession();
  }
}
