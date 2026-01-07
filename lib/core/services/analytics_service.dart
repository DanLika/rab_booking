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

  AnalyticsService._() : _analytics = FirebaseAnalytics.instance;

  static final AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;

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
      if (kDebugMode) {
        print(
          '[Analytics] Stripe payment initiated: $method ($browser, $deviceType)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Analytics] Error logging stripe_payment_initiated: $e');
      }
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
      if (kDebugMode) {
        print('[Analytics] Stripe popup blocked: $browser, $deviceType');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Analytics] Error logging stripe_popup_blocked: $e');
      }
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
      if (kDebugMode) {
        print(
          '[Analytics] Stripe payment completed: $sessionId ($method, ${timeToCompleteSeconds}s)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Analytics] Error logging stripe_payment_completed: $e');
      }
    }
  }

}
