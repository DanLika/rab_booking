import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics Service - Phase 3 Feature
///
/// Centralized service for tracking user events and behavior across the app.
///
/// Usage:
/// ```dart
/// // Track booking created
/// AnalyticsService.instance.logBookingCreated(
///   bookingId: 'abc123',
///   unitId: 'unit456',
///   amount: 150.0,
///   paymentMethod: 'stripe',
/// );
///
/// // Track screen views (use observer in GoRouter)
/// GoRouter(observers: [AnalyticsService.instance.observer])
/// ```
class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final FirebaseAnalyticsObserver _observer;

  AnalyticsService._()
    : _analytics = FirebaseAnalytics.instance,
      _observer = FirebaseAnalyticsObserver(
        analytics: FirebaseAnalytics.instance,
      );

  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;

  /// Get analytics observer for navigation tracking
  FirebaseAnalyticsObserver get observer => _observer;

  /// Set user properties
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      if (kDebugMode) print('[Analytics] User ID set: $userId');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error setting user ID: $e');
    }
  }

  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) print('[Analytics] User property set: $name = $value');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error setting user property: $e');
    }
  }

  /// Booking Events
  Future<void> logBookingCreated({
    required String bookingId,
    required String unitId,
    required double amount,
    required String paymentMethod,
    String? source,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'booking_created',
        parameters: {
          'booking_id': bookingId,
          'unit_id': unitId,
          'value': amount,
          'currency': 'EUR',
          'payment_method': paymentMethod,
          'source': source ?? 'widget',
        },
      );
      if (kDebugMode) print('[Analytics] Booking created: $bookingId');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging booking_created: $e');
    }
  }

  Future<void> logBookingConfirmed({
    required String bookingId,
    required double amount,
  }) async {
    try {
      await _analytics.logPurchase(
        value: amount,
        currency: 'EUR',
        parameters: {'booking_id': bookingId, 'transaction_id': bookingId},
      );
      if (kDebugMode) print('[Analytics] Booking confirmed: $bookingId');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging booking_confirmed: $e');
    }
  }

  Future<void> logBookingCancelled({
    required String bookingId,
    required String reason,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'booking_cancelled',
        parameters: {'booking_id': bookingId, 'reason': reason},
      );
      if (kDebugMode) print('[Analytics] Booking cancelled: $bookingId');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging booking_cancelled: $e');
    }
  }

  /// Property Events
  Future<void> logPropertyViewed({
    required String propertyId,
    required String propertyName,
  }) async {
    try {
      await _analytics.logViewItem(
        items: [
          AnalyticsEventItem(
            itemId: propertyId,
            itemName: propertyName,
            itemCategory: 'property',
          ),
        ],
      );
      if (kDebugMode) print('[Analytics] Property viewed: $propertyName');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging property_viewed: $e');
    }
  }

  Future<void> logUnitViewed({
    required String unitId,
    required String unitName,
    double? price,
  }) async {
    try {
      await _analytics.logViewItem(
        items: [
          AnalyticsEventItem(
            itemId: unitId,
            itemName: unitName,
            itemCategory: 'unit',
            price: price,
          ),
        ],
      );
      if (kDebugMode) print('[Analytics] Unit viewed: $unitName');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging unit_viewed: $e');
    }
  }

  /// Authentication Events
  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      if (kDebugMode) print('[Analytics] Login: $method');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging login: $e');
    }
  }

  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      if (kDebugMode) print('[Analytics] Sign up: $method');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging sign_up: $e');
    }
  }

  /// Widget Events
  Future<void> logWidgetLoaded({
    required String unitId,
    String? referrer,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'widget_loaded',
        parameters: {'unit_id': unitId, 'referrer': referrer ?? 'direct'},
      );
      if (kDebugMode) print('[Analytics] Widget loaded: $unitId');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging widget_loaded: $e');
    }
  }

  Future<void> logDateSelectionStarted() async {
    try {
      await _analytics.logEvent(name: 'date_selection_started');
      if (kDebugMode) print('[Analytics] Date selection started');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging event: $e');
    }
  }

  Future<void> logGuestDetailsEntered() async {
    try {
      await _analytics.logEvent(name: 'guest_details_entered');
      if (kDebugMode) print('[Analytics] Guest details entered');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging event: $e');
    }
  }

  /// Stripe Payment Events
  Future<void> logStripePaymentInitiated({
    required String method, // 'popup', 'redirect', 'blocked'
    required String browser,
    required String deviceType, // 'desktop', 'mobile', 'tablet'
    bool isInIframe = false,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'stripe_payment_initiated',
        parameters: {
          'method': method,
          'browser': browser,
          'device_type': deviceType,
          'is_in_iframe': isInIframe,
        },
      );
      if (kDebugMode)
        print(
          '[Analytics] Stripe payment initiated: $method ($browser, $deviceType)',
        );
    } catch (e) {
      if (kDebugMode)
        print('[Analytics] Error logging stripe_payment_initiated: $e');
    }
  }

  Future<void> logStripePopupBlocked({
    required String browser,
    required String deviceType,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'stripe_popup_blocked',
        parameters: {'browser': browser, 'device_type': deviceType},
      );
      if (kDebugMode)
        print('[Analytics] Stripe popup blocked: $browser, $deviceType');
    } catch (e) {
      if (kDebugMode)
        print('[Analytics] Error logging stripe_popup_blocked: $e');
    }
  }

  Future<void> logStripePaymentCompleted({
    required String sessionId,
    required String method, // 'popup', 'redirect'
    required String browser,
    required String deviceType,
    required int timeToCompleteSeconds,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'stripe_payment_completed',
        parameters: {
          'session_id': sessionId,
          'method': method,
          'browser': browser,
          'device_type': deviceType,
          'time_to_complete_seconds': timeToCompleteSeconds,
        },
      );
      if (kDebugMode)
        print(
          '[Analytics] Stripe payment completed: $sessionId ($method, ${timeToCompleteSeconds}s)',
        );
    } catch (e) {
      if (kDebugMode)
        print('[Analytics] Error logging stripe_payment_completed: $e');
    }
  }

  /// Search Events
  Future<void> logSearch(String searchTerm) async {
    try {
      await _analytics.logSearch(searchTerm: searchTerm);
      if (kDebugMode) print('[Analytics] Search: $searchTerm');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging search: $e');
    }
  }

  /// Custom Events
  Future<void> logCustomEvent(
    String eventName,
    Map<String, Object>? parameters,
  ) async {
    try {
      await _analytics.logEvent(name: eventName, parameters: parameters);
      if (kDebugMode) print('[Analytics] Custom event: $eventName');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging custom event: $e');
    }
  }

  /// Screen Views (handled automatically by observer, but can be called manually)
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      if (kDebugMode) print('[Analytics] Screen view: $screenName');
    } catch (e) {
      if (kDebugMode) print('[Analytics] Error logging screen_view: $e');
    }
  }
}
