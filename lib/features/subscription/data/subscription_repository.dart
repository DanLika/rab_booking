import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository for handling subscription-related data and operations
class SubscriptionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  SubscriptionRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  /// Check if the user has an active subscription
  Future<bool> hasActiveSubscription(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data == null) return false;
      return data['accountStatus'] == 'active' || data['accountStatus'] == 'trial';
    } catch (e) {
      throw Exception('Failed to get subscription status: $e');
    }
  }

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
          .call({'priceId': priceId, 'returnUrl': returnUrl});

      final data =
          result.data
              as Map; // Use Map instead of Map<String, dynamic> to avoid cast error

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
          .call({'returnUrl': returnUrl});

      final data =
          result.data as Map; // Use Map instead of Map<String, dynamic>
      return data['url'] as String;
    } catch (e) {
      throw Exception('Failed to create portal session: $e');
    }
  }
}

/// Provider for SubscriptionRepository
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instance,
  );
});
