import 'package:cloud_functions/cloud_functions.dart';
import 'logging_service.dart';

/// Service for Stripe payment integration.
///
/// This service calls existing Firebase Cloud Functions:
/// - createStripeCheckoutSession (stripePayment.ts)
/// - handleStripeWebhook (stripePayment.ts)
///
/// Usage:
/// ```dart
/// final service = StripeService();
///
/// // Create checkout session (booking created after payment)
/// final result = await service.createCheckoutSession(
///   bookingData: bookingData,
///   returnUrl: returnUrl,
/// );
/// // Redirect to result.checkoutUrl
///
/// // Check Stripe account status
/// final status = await service.getAccountStatus();
/// if (!status.isFullySetup) {
///   // Prompt owner to complete Stripe onboarding
/// }
/// ```
class StripeService {
  final FirebaseFunctions _functions;

  StripeService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  /// Create Stripe Checkout Session
  ///
  /// Calls the existing Cloud Function: createStripeCheckoutSession
  ///
  /// NEW FLOW (2025-12-02):
  /// - Booking is NOT created before Stripe checkout
  /// - All booking data is passed to create the checkout session
  /// - Booking will be created by webhook AFTER payment succeeds
  ///
  /// Parameters:
  /// - [bookingData]: All booking data (from createBooking validation result)
  /// - [returnUrl]: URL to redirect after payment
  ///
  /// Returns:
  /// - sessionId: Stripe checkout session ID
  /// - checkoutUrl: URL to redirect user to Stripe checkout
  /// - bookingReference: Generated booking reference for UI display
  Future<StripeCheckoutResult> createCheckoutSession({
    required Map<String, dynamic> bookingData,
    String? returnUrl,
  }) async {
    try {
      LoggingService.logOperation(
        '[StripeService] Creating checkout session for: ${bookingData['guestEmail']}',
      );

      final result = await _functions
          .httpsCallable('createStripeCheckoutSession')
          .call({'bookingData': bookingData, 'returnUrl': returnUrl});

      final data = result.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw StripeServiceException(
          'Checkout session creation failed',
          data['error'] as String?,
        );
      }

      LoggingService.logSuccess(
        '[StripeService] Checkout session created: ${data['sessionId']}',
      );

      return StripeCheckoutResult(
        success: true,
        sessionId: data['sessionId'] as String,
        checkoutUrl: data['checkoutUrl'] as String,
        bookingReference: data['bookingReference'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      await LoggingService.logError(
        '[StripeService] Firebase Functions error: ${e.code} - ${e.message}',
        e,
      );

      // Provide more detailed error messages based on error code
      String userMessage;
      switch (e.code) {
        case 'invalid-argument':
          userMessage =
              e.message ??
              'Invalid booking data. Please check your information and try again.';
          break;
        case 'failed-precondition':
          userMessage =
              e.message ??
              'Payment setup incomplete. Please contact the property owner.';
          break;
        case 'already-exists':
          userMessage =
              e.message ??
              'These dates are no longer available. Please select different dates.';
          break;
        case 'permission-denied':
          userMessage =
              'Permission denied. Please refresh the page and try again.';
          break;
        default:
          userMessage =
              e.message ??
              'Failed to create checkout session. Please try again.';
      }

      throw StripeServiceException(userMessage, e.code);
    } catch (e) {
      await LoggingService.logError('[StripeService] Unexpected error', e);
      throw StripeServiceException(
        'Unexpected error creating checkout session. Please try again.',
        e.toString(),
      );
    }
  }

  /// Get Stripe Account Status
  ///
  /// Calls the existing Cloud Function: getStripeAccountStatus
  Future<StripeAccountStatus> getAccountStatus() async {
    try {
      LoggingService.logOperation(
        '[StripeService] Getting Stripe account status',
      );

      final result = await _functions
          .httpsCallable('getStripeAccountStatus')
          .call();

      final data = result.data as Map<String, dynamic>;

      LoggingService.logSuccess('[StripeService] Account status retrieved');

      return StripeAccountStatus.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      await LoggingService.logError(
        '[StripeService] Error getting account status: ${e.message}',
        e,
      );
      throw StripeServiceException(
        'Failed to get account status: ${e.message}',
        e.code,
      );
    }
  }

  /// Create Stripe Connect Account Link
  ///
  /// Calls the existing Cloud Function: createStripeConnectAccount
  Future<StripeConnectResult> createConnectAccount({
    required String returnUrl,
    required String refreshUrl,
  }) async {
    try {
      LoggingService.logOperation(
        '[StripeService] Creating Stripe Connect account',
      );

      final result = await _functions
          .httpsCallable('createStripeConnectAccount')
          .call({'returnUrl': returnUrl, 'refreshUrl': refreshUrl});

      final data = result.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw StripeServiceException(
          'Failed to create Connect account',
          data['error'] as String?,
        );
      }

      LoggingService.logSuccess('[StripeService] Connect account created');

      return StripeConnectResult(
        success: true,
        accountId: data['accountId'] as String,
        onboardingUrl: data['onboardingUrl'] as String,
      );
    } on FirebaseFunctionsException catch (e) {
      await LoggingService.logError(
        '[StripeService] Error creating Connect account: ${e.message}',
        e,
      );
      throw StripeServiceException(
        'Failed to create Connect account: ${e.message}',
        e.code,
      );
    }
  }
}

// ===================================================================
// MODELS
// ===================================================================

/// Result of creating a Stripe Checkout Session
class StripeCheckoutResult {
  final bool success;
  final String sessionId;
  final String checkoutUrl;

  /// Booking reference generated for UI display (booking created after payment)
  final String? bookingReference;

  StripeCheckoutResult({
    required this.success,
    required this.sessionId,
    required this.checkoutUrl,
    this.bookingReference,
  });
}

/// Result of creating a Stripe Connect Account
class StripeConnectResult {
  final bool success;
  final String accountId;
  final String onboardingUrl;

  StripeConnectResult({
    required this.success,
    required this.accountId,
    required this.onboardingUrl,
  });
}

/// Stripe Account Status
class StripeAccountStatus {
  final bool connected;
  final String? accountId;
  final bool? onboarded;
  final bool? chargesEnabled;
  final bool? payoutsEnabled;
  final String? email;
  final String? country;
  final Map<String, dynamic>? balance;
  final Map<String, dynamic>? requirements;

  StripeAccountStatus({
    required this.connected,
    this.accountId,
    this.onboarded,
    this.chargesEnabled,
    this.payoutsEnabled,
    this.email,
    this.country,
    this.balance,
    this.requirements,
  });

  factory StripeAccountStatus.fromMap(Map<String, dynamic> map) {
    return StripeAccountStatus(
      connected: map['connected'] as bool,
      accountId: map['accountId'] as String?,
      onboarded: map['onboarded'] as bool?,
      chargesEnabled: map['chargesEnabled'] as bool?,
      payoutsEnabled: map['payoutsEnabled'] as bool?,
      email: map['email'] as String?,
      country: map['country'] as String?,
      balance: map['balance'] as Map<String, dynamic>?,
      requirements: map['requirements'] as Map<String, dynamic>?,
    );
  }

  bool get isFullySetup =>
      connected && (onboarded ?? false) && (chargesEnabled ?? false);
}

/// Custom exception for Stripe service errors
class StripeServiceException implements Exception {
  final String message;
  final String? code;

  StripeServiceException(this.message, [this.code]);

  @override
  String toString() =>
      'StripeServiceException: $message${code != null ? ' (code: $code)' : ''}';
}
