import 'package:firebase_analytics/firebase_analytics.dart';
import 'logging_service.dart';

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
      LoggingService.logDebug('[Analytics] User ID set: $userId');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error setting user ID',
        e,
        stackTrace,
      );
    }
  }

  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      LoggingService.logDebug('[Analytics] User property set: $name = $value');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error setting user property',
        e,
        stackTrace,
      );
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
      LoggingService.logDebug('[Analytics] Booking created: $bookingId');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging booking_created',
        e,
        stackTrace,
      );
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
      LoggingService.logDebug('[Analytics] Booking confirmed: $bookingId');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging booking_confirmed',
        e,
        stackTrace,
      );
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
      LoggingService.logDebug('[Analytics] Booking cancelled: $bookingId');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging booking_cancelled',
        e,
        stackTrace,
      );
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
      LoggingService.logDebug('[Analytics] Property viewed: $propertyName');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging property_viewed',
        e,
        stackTrace,
      );
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
      LoggingService.logDebug('[Analytics] Unit viewed: $unitName');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging unit_viewed',
        e,
        stackTrace,
      );
    }
  }

  /// Property Creation Funnel
  Future<void> logAddPropertyStart() async {
    try {
      await _analytics.logEvent(name: 'add_property_start');
      LoggingService.logDebug('[Analytics] Add property started');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging add_property_start',
        e,
        stackTrace,
      );
    }
  }

  Future<void> logPropertyCreated({
    required String propertyId,
    required String propertyName,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'property_created',
        parameters: {'property_id': propertyId, 'property_name': propertyName},
      );
      LoggingService.logDebug('[Analytics] Property created: $propertyName');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging property_created',
        e,
        stackTrace,
      );
    }
  }

  /// Subscription Funnel
  Future<void> logViewSubscription({required int currentUnitCount}) async {
    try {
      await _analytics.logEvent(
        name: 'view_subscription',
        parameters: {'current_unit_count': currentUnitCount},
      );
      LoggingService.logDebug(
        '[Analytics] View subscription (units: $currentUnitCount)',
      );
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging view_subscription',
        e,
        stackTrace,
      );
    }
  }

  Future<void> logBeginCheckout({
    required String planId,
    required double price,
  }) async {
    try {
      await _analytics.logBeginCheckout(
        value: price,
        currency: 'EUR',
        items: [
          AnalyticsEventItem(
            itemId: planId,
            itemName: 'Subscription $planId',
            itemCategory: 'subscription',
            price: price,
          ),
        ],
      );
      LoggingService.logDebug('[Analytics] Begin checkout: $planId');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging begin_checkout',
        e,
        stackTrace,
      );
    }
  }

  Future<void> logSubscriptionPurchase({
    required String planId,
    required double price,
    required String transactionId,
  }) async {
    try {
      await _analytics.logPurchase(
        value: price,
        currency: 'EUR',
        transactionId: transactionId,
        items: [
          AnalyticsEventItem(
            itemId: planId,
            itemName: 'Subscription $planId',
            itemCategory: 'subscription',
            price: price,
          ),
        ],
      );
      LoggingService.logDebug('[Analytics] Subscription purchased: $planId');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging subscription_purchase',
        e,
        stackTrace,
      );
    }
  }

  /// Authentication Events
  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      LoggingService.logDebug('[Analytics] Login: $method');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging login',
        e,
        stackTrace,
      );
    }
  }

  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      LoggingService.logDebug('[Analytics] Sign up: $method');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging sign_up',
        e,
        stackTrace,
      );
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
      LoggingService.logDebug('[Analytics] Widget loaded: $unitId');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging widget_loaded',
        e,
        stackTrace,
      );
    }
  }

  Future<void> logDateSelectionStarted() async {
    try {
      await _analytics.logEvent(name: 'date_selection_started');
      LoggingService.logDebug('[Analytics] Date selection started');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging date_selection_started',
        e,
        stackTrace,
      );
    }
  }

  Future<void> logGuestDetailsEntered() async {
    try {
      await _analytics.logEvent(name: 'guest_details_entered');
      LoggingService.logDebug('[Analytics] Guest details entered');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging guest_details_entered',
        e,
        stackTrace,
      );
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
      LoggingService.logDebug(
        '[Analytics] Stripe payment initiated: $method ($browser, $deviceType)',
      );
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging stripe_payment_initiated',
        e,
        stackTrace,
      );
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
      LoggingService.logDebug(
        '[Analytics] Stripe popup blocked: $browser, $deviceType',
      );
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging stripe_popup_blocked',
        e,
        stackTrace,
      );
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
      LoggingService.logDebug(
        '[Analytics] Stripe payment completed: $sessionId ($method, ${timeToCompleteSeconds}s)',
      );
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging stripe_payment_completed',
        e,
        stackTrace,
      );
    }
  }

  /// Search Events
  Future<void> logSearch(String searchTerm) async {
    try {
      await _analytics.logSearch(searchTerm: searchTerm);
      LoggingService.logDebug('[Analytics] Search: $searchTerm');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging search',
        e,
        stackTrace,
      );
    }
  }

  /// Custom Events
  Future<void> logCustomEvent(
    String eventName,
    Map<String, Object>? parameters,
  ) async {
    try {
      await _analytics.logEvent(name: eventName, parameters: parameters);
      LoggingService.logDebug('[Analytics] Custom event: $eventName');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging custom event',
        e,
        stackTrace,
      );
    }
  }

  /// Screen Views (handled automatically by observer, but can be called manually)
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      LoggingService.logDebug('[Analytics] Screen view: $screenName');
    } catch (e, stackTrace) {
      await LoggingService.logError(
        '[Analytics] Error logging screen_view',
        e,
        stackTrace,
      );
    }
  }
}
