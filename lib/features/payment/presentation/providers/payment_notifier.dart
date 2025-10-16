import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/payment_service.dart';
import '../../domain/models/payment_intent_model.dart';
import '../../domain/models/payment_record.dart';

part 'payment_notifier.freezed.dart';
part 'payment_notifier.g.dart';

/// Payment state
@freezed
class PaymentState with _$PaymentState {
  const factory PaymentState({
    // Payment intent
    PaymentIntentModel? paymentIntent,

    // Payment record
    PaymentRecord? paymentRecord,

    // Processing state
    @Default(false) bool isProcessing,
    @Default(false) bool isSuccess,
    @Default(false) bool isFailed,

    // Error handling
    String? error,

    // Stripe payment intent status
    String? paymentStatus,
  }) = _PaymentState;
}

/// Payment notifier
@riverpod
class PaymentNotifier extends _$PaymentNotifier {
  @override
  PaymentState build() {
    return const PaymentState();
  }

  PaymentService get _paymentService => ref.read(paymentServiceProvider);

  /// Create payment intent
  Future<void> createPaymentIntent({
    required String bookingId,
    required int totalAmount,
  }) async {
    state = state.copyWith(
      isProcessing: true,
      error: null,
    );

    try {
      final paymentIntent = await _paymentService.createPaymentIntent(
        bookingId: bookingId,
        totalAmount: totalAmount,
      );

      state = state.copyWith(
        paymentIntent: paymentIntent,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        isFailed: true,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Process payment with Stripe
  Future<void> processPayment({
    required String bookingId,
    required BillingDetails billingDetails,
  }) async {
    if (state.paymentIntent == null) {
      throw Exception('Payment intent not initialized');
    }

    state = state.copyWith(
      isProcessing: true,
      error: null,
    );

    try {
      // Confirm payment with Stripe
      final result = await _paymentService.confirmPayment(
        clientSecret: state.paymentIntent!.clientSecret,
        billingDetails: billingDetails,
      );

      // Check payment status
      if (result.status == PaymentIntentsStatus.Succeeded) {
        // Handle successful payment
        final paymentRecord = await _paymentService.handlePaymentSuccess(
          bookingId: bookingId,
          paymentIntentId: state.paymentIntent!.paymentIntentId,
          amount: state.paymentIntent!.amount,
          receiptUrl: result.receiptEmail,
        );

        state = state.copyWith(
          isProcessing: false,
          isSuccess: true,
          paymentRecord: paymentRecord,
          paymentStatus: result.status.name,
        );
      } else {
        // Payment failed or requires action
        await _paymentService.handlePaymentError(
          bookingId: bookingId,
          errorMessage: 'Payment status: ${result.status.name}',
        );

        state = state.copyWith(
          isProcessing: false,
          isFailed: true,
          paymentStatus: result.status.name,
          error: 'Plaćanje nije uspjelo. Status: ${result.status.name}',
        );
      }
    } catch (e) {
      // Handle payment error
      await _paymentService.handlePaymentError(
        bookingId: bookingId,
        errorMessage: e.toString(),
      );

      state = state.copyWith(
        isProcessing: false,
        isFailed: true,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Get payment records for booking
  Future<void> loadPaymentRecords(String bookingId) async {
    try {
      final records = await _paymentService.getPaymentRecords(bookingId);
      if (records.isNotEmpty) {
        state = state.copyWith(paymentRecord: records.first);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Reset payment state
  void reset() {
    state = const PaymentState();
  }

  /// Set error
  void setError(String error) {
    state = state.copyWith(
      error: error,
      isFailed: true,
      isProcessing: false,
    );
  }
}
