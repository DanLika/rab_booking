import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/stripe_customer_service.dart';

part 'stripe_customer_provider.g.dart';

/// Provider for StripeCustomerService
@riverpod
StripeCustomerService stripeCustomerService(StripeCustomerServiceRef ref) {
  return StripeCustomerService(
    supabase: Supabase.instance.client,
  );
}

/// Provider for Stripe Customer ID
///
/// Fetches or creates a Stripe Customer ID for the current user.
@riverpod
class StripeCustomerId extends _$StripeCustomerId {
  @override
  Future<String?> build() async {
    final service = ref.read(stripeCustomerServiceProvider);
    return await service.getCustomerId();
  }

  /// Create or get Stripe Customer ID
  Future<String> getOrCreate({
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final service = ref.read(stripeCustomerServiceProvider);
    final customerId = await service.getOrCreateCustomerId(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );

    // Update state
    state = AsyncData(customerId);
    return customerId;
  }

  /// Refresh customer ID from database
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(stripeCustomerServiceProvider);
      return await service.getCustomerId();
    });
  }
}

/// Provider for saved payment methods
///
/// Lists all saved payment methods for the current user's Stripe Customer.
@riverpod
class SavedPaymentMethods extends _$SavedPaymentMethods {
  @override
  Future<List<PaymentMethodInfo>> build() async {
    final service = ref.read(stripeCustomerServiceProvider);
    return await service.listPaymentMethods();
  }

  /// Refresh payment methods list
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(stripeCustomerServiceProvider);
      return await service.listPaymentMethods();
    });
  }

  /// Detach (remove) a payment method
  Future<void> detachPaymentMethod(String paymentMethodId) async {
    final service = ref.read(stripeCustomerServiceProvider);
    await service.detachPaymentMethod(paymentMethodId);

    // Refresh the list
    await refresh();
  }
}

/// Provider for creating a PaymentIntent
///
/// This is used when initiating a payment in the booking flow.
@riverpod
class PaymentIntentCreator extends _$PaymentIntentCreator {
  @override
  PaymentIntentResult? build() {
    return null;
  }

  /// Create a payment intent for a booking
  Future<PaymentIntentResult> createPaymentIntent({
    required String bookingId,
    required double totalAmount,
    required double advancePaymentAmount,
    required bool isFullPayment,
    String? paymentMethodId,
  }) async {
    state = null; // Reset state

    final service = ref.read(stripeCustomerServiceProvider);
    final result = await service.createPaymentIntent(
      bookingId: bookingId,
      totalAmount: totalAmount,
      advancePaymentAmount: advancePaymentAmount,
      isFullPayment: isFullPayment,
      paymentMethodId: paymentMethodId,
    );

    state = result;
    return result;
  }

  /// Confirm payment after successful Stripe payment
  Future<void> confirmPayment({
    required String bookingId,
    required String paymentIntentId,
  }) async {
    final service = ref.read(stripeCustomerServiceProvider);
    await service.confirmPayment(
      bookingId: bookingId,
      paymentIntentId: paymentIntentId,
    );
  }

  /// Reset state
  void reset() {
    state = null;
  }
}
