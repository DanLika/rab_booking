import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository for handling subscription-related data and operations
class SubscriptionRepository {
  final FirebaseFunctions _functions;

  SubscriptionRepository(this._functions);

  /// Create a Stripe Checkout Session for subscription
  ///
  /// [priceId] is the Stripe Price ID for the selected plan
  /// Returns the session URL to redirect the user to
  Future<String> createCheckoutSession({
    required String priceId,
    required String returnUrl,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('createSubscriptionCheckoutSession')
          .call({
            'priceId': priceId,
            'returnUrl': returnUrl,
          });

      final data = result.data as Map; // Use Map instead of Map<String, dynamic> to avoid cast error

      if (data['url'] == null) {
        throw Exception('Checkout URL missing from response');
      }

      return data['url'] as String;
    } catch (e) {
      // Allow specific Firebase errors to bubble up or wrap them
      throw Exception('Failed to create subscription session: $e');
    }
  }

  /// Portal session creation (for managing existing subscriptions)
  Future<String> createPortalSession({required String returnUrl}) async {
    try {
      final result = await _functions
          .httpsCallable('createCustomerPortalSession')
          .call({
            'returnUrl': returnUrl,
          });

      final data = result.data as Map; // Use Map instead of Map<String, dynamic>
      return data['url'] as String;
    } catch (e) {
      throw Exception('Failed to create portal session: $e');
    }
  }
}

/// Provider for SubscriptionRepository
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(FirebaseFunctions.instance);
});
