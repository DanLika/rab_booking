import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/payment_intent_model.dart';
import '../domain/models/payment_record.dart';

part 'payment_service.g.dart';

/// Payment service for Stripe operations
class PaymentService {
  final SupabaseClient _supabase;

  PaymentService(this._supabase);

  /// Create payment intent via Supabase Edge Function
  Future<PaymentIntentModel> createPaymentIntent({
    required String bookingId,
    required int totalAmount,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-payment-intent',
        body: {
          'bookingId': bookingId,
          'totalAmount': totalAmount,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create payment intent: ${response.data}');
      }

      return PaymentIntentModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  /// Confirm payment with card details
  Future<PaymentIntent> confirmPayment({
    required String clientSecret,
    required BillingDetails billingDetails,
  }) async {
    try {
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Rab Booking',
          billingDetails: billingDetails,
          style: ThemeMode.system,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Retrieve payment intent to get status
      final paymentIntent = await Stripe.instance.retrievePaymentIntent(
        clientSecret,
      );

      return paymentIntent;
    } catch (e) {
      if (e is StripeException) {
        throw _handleStripeError(e);
      }
      rethrow;
    }
  }

  /// Handle payment success - update booking and create payment record
  Future<PaymentRecord> handlePaymentSuccess({
    required String bookingId,
    required String paymentIntentId,
    required int amount,
    String? receiptUrl,
  }) async {
    try {
      // Update booking status to confirmed
      await _supabase
          .from('bookings')
          .update({'status': 'confirmed', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', bookingId);

      // Create payment record
      final paymentData = {
        'booking_id': bookingId,
        'amount': amount,
        'status': 'completed',
        'stripe_payment_id': paymentIntentId,
        'receipt_url': receiptUrl,
        'currency': 'eur',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('payments')
          .insert(paymentData)
          .select()
          .single();

      return PaymentRecord.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to save payment record: $e');
    }
  }

  /// Handle payment error
  Future<void> handlePaymentError({
    required String bookingId,
    required String errorMessage,
  }) async {
    try {
      // Update booking status to failed
      await _supabase
          .from('bookings')
          .update({
            'status': 'payment_failed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);

      // Optionally create a failed payment record
      await _supabase.from('payments').insert({
        'booking_id': bookingId,
        'amount': 0,
        'status': 'failed',
        'stripe_payment_id': '',
        'failure_message': errorMessage,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log error but don't throw - this is a cleanup operation
      print('Error handling payment failure: $e');
    }
  }

  /// Get payment records for booking
  Future<List<PaymentRecord>> getPaymentRecords(String bookingId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PaymentRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch payment records: $e');
    }
  }

  /// Handle Stripe errors with user-friendly messages
  Exception _handleStripeError(StripeException error) {
    switch (error.error.code) {
      case FailureCode.Canceled:
        return Exception('Plaćanje je otkazano');
      case FailureCode.Failed:
        return Exception('Plaćanje nije uspjelo. Molimo pokušajte ponovo.');
      case FailureCode.Timeout:
        return Exception('Plaćanje je isteklo. Molimo pokušajte ponovo.');
      default:
        return Exception(
          error.error.localizedMessage ?? 'Greška prilikom plaćanja',
        );
    }
  }
}

/// Provider for payment service
@riverpod
PaymentService paymentService(PaymentServiceRef ref) {
  return PaymentService(Supabase.instance.client);
}
