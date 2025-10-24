import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exceptions.dart';

/// Service for managing Stripe Customers and Payment Methods
///
/// Handles:
/// - Creating Stripe Customers (via Edge Function)
/// - Retrieving saved payment methods
/// - Detaching payment methods
/// - Payment Intent creation with advance payment support
class StripeCustomerService {
  final SupabaseClient _supabase;

  StripeCustomerService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Create a Stripe Customer for the current user
  ///
  /// This calls the `create-stripe-customer` Edge Function which:
  /// - Creates a Stripe Customer via Stripe API
  /// - Stores the customer ID in user_profiles table
  /// - Returns the customer ID for future use
  Future<String> createCustomer({
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw AuthenticationException('User not authenticated');
      }

      // Call Edge Function to create Stripe Customer
      final response = await _supabase.functions.invoke(
        'create-stripe-customer',
        body: {
          'email': email,
          'name': '$firstName $lastName',
          'phone': phone,
        },
      );

      if (response.status != 200) {
        throw PaymentException(
          'Failed to create Stripe customer: ${response.data}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final customerId = data['customerId'] as String?;

      if (customerId == null) {
        throw PaymentException('No customer ID returned from Stripe');
      }

      return customerId;
    } on AuthenticationException {
      rethrow;
    } on PaymentException {
      rethrow;
    } catch (e) {
      throw PaymentException('Error creating Stripe customer: $e');
    }
  }

  /// Get the Stripe Customer ID for the current user
  ///
  /// Retrieves from user_profiles table. If not found, returns null.
  Future<String?> getCustomerId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw AuthenticationException('User not authenticated');
      }

      final response = await _supabase
          .from('user_profiles')
          .select('stripe_customer_id')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return response['stripe_customer_id'] as String?;
    } on AuthenticationException {
      rethrow;
    } catch (e) {
      throw DatabaseException(message: 'Error fetching Stripe customer ID: $e');
    }
  }

  /// Get or create Stripe Customer ID
  ///
  /// If customer already exists, returns existing ID.
  /// Otherwise, creates a new customer.
  Future<String> getOrCreateCustomerId({
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    // Try to get existing customer ID
    final existingId = await getCustomerId();
    if (existingId != null) {
      return existingId;
    }

    // Create new customer
    return await createCustomer(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
  }

  /// List saved payment methods for the current user's Stripe Customer
  ///
  /// Calls Edge Function to retrieve payment methods from Stripe.
  Future<List<PaymentMethodInfo>> listPaymentMethods() async {
    try {
      final customerId = await getCustomerId();
      if (customerId == null) {
        return []; // No customer yet, no payment methods
      }

      // Call Edge Function to list payment methods
      final response = await _supabase.functions.invoke(
        'list-payment-methods',
        body: {'customerId': customerId},
      );

      if (response.status != 200) {
        throw PaymentException(
          'Failed to list payment methods: ${response.data}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      final methods = data['paymentMethods'] as List<dynamic>? ?? [];

      return methods
          .map((m) => PaymentMethodInfo.fromJson(m as Map<String, dynamic>))
          .toList();
    } on PaymentException {
      rethrow;
    } catch (e) {
      throw PaymentException('Error listing payment methods: $e');
    }
  }

  /// Detach (delete) a payment method from the Stripe Customer
  Future<void> detachPaymentMethod(String paymentMethodId) async {
    try {
      // Call Edge Function to detach payment method
      final response = await _supabase.functions.invoke(
        'detach-payment-method',
        body: {'paymentMethodId': paymentMethodId},
      );

      if (response.status != 200) {
        throw PaymentException(
          'Failed to detach payment method: ${response.data}',
        );
      }
    } on PaymentException {
      rethrow;
    } catch (e) {
      throw PaymentException('Error detaching payment method: $e');
    }
  }

  /// Create a PaymentIntent for a booking with advance payment support
  ///
  /// Calls the `create-payment-intent` Edge Function which:
  /// - Calculates the correct amount (20% or 100%)
  /// - Creates a Stripe PaymentIntent
  /// - Returns clientSecret for Stripe Payment Sheet
  Future<PaymentIntentResult> createPaymentIntent({
    required String bookingId,
    required double totalAmount,
    required double advancePaymentAmount,
    required bool isFullPayment,
    String? paymentMethodId, // For saved payment methods
  }) async {
    try {
      final customerId = await getCustomerId();
      if (customerId == null) {
        throw PaymentException('No Stripe customer found');
      }

      // Determine amount to charge
      final amountToCharge = isFullPayment ? totalAmount : advancePaymentAmount;

      // Convert to cents (Stripe uses smallest currency unit)
      final amountInCents = (amountToCharge * 100).round();

      // Call Edge Function to create PaymentIntent
      final response = await _supabase.functions.invoke(
        'create-payment-intent',
        body: {
          'bookingId': bookingId,
          'amount': amountInCents,
          'currency': 'eur',
          'customerId': customerId,
          'paymentMethodId': paymentMethodId,
          'metadata': {
            'bookingId': bookingId,
            'isFullPayment': isFullPayment,
            'totalAmount': totalAmount.toStringAsFixed(2),
            'advancePaymentAmount': advancePaymentAmount.toStringAsFixed(2),
          },
        },
      );

      if (response.status != 200) {
        throw PaymentException(
          'Failed to create payment intent: ${response.data}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      return PaymentIntentResult(
        clientSecret: data['clientSecret'] as String,
        paymentIntentId: data['paymentIntentId'] as String,
        ephemeralKey: data['ephemeralKey'] as String?,
      );
    } on PaymentException {
      rethrow;
    } catch (e) {
      throw PaymentException('Error creating payment intent: $e');
    }
  }

  /// Confirm that a payment was successful and update booking
  Future<void> confirmPayment({
    required String bookingId,
    required String paymentIntentId,
  }) async {
    try {
      // Update booking with payment information
      await _supabase.from('bookings').update({
        'stripe_payment_id': paymentIntentId,
        'payment_status': 'paid',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw DatabaseException(message: 'Error confirming payment: $e');
    }
  }
}

/// Payment Method information from Stripe
class PaymentMethodInfo {
  final String id;
  final String type; // 'card', 'sepa_debit', etc.
  final String? last4;
  final String? brand; // 'visa', 'mastercard', etc.
  final int? expMonth;
  final int? expYear;
  final bool isDefault;

  PaymentMethodInfo({
    required this.id,
    required this.type,
    this.last4,
    this.brand,
    this.expMonth,
    this.expYear,
    this.isDefault = false,
  });

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfo(
      id: json['id'] as String,
      type: json['type'] as String,
      last4: json['last4'] as String?,
      brand: json['brand'] as String?,
      expMonth: json['exp_month'] as int?,
      expYear: json['exp_year'] as int?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  /// Get display name for the payment method
  String get displayName {
    if (type == 'card' && brand != null && last4 != null) {
      return '${_formatBrand(brand!)} •••• $last4';
    }
    return 'Payment method';
  }

  /// Get expiration display (MM/YY)
  String? get expirationDisplay {
    if (expMonth != null && expYear != null) {
      final month = expMonth!.toString().padLeft(2, '0');
      final year = (expYear! % 100).toString().padLeft(2, '0');
      return '$month/$year';
    }
    return null;
  }

  /// Format brand name for display
  String _formatBrand(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'amex':
        return 'American Express';
      case 'discover':
        return 'Discover';
      case 'diners':
        return 'Diners Club';
      case 'jcb':
        return 'JCB';
      case 'unionpay':
        return 'UnionPay';
      default:
        return brand.toUpperCase();
    }
  }
}

/// Result from creating a Payment Intent
class PaymentIntentResult {
  final String clientSecret;
  final String paymentIntentId;
  final String? ephemeralKey;

  PaymentIntentResult({
    required this.clientSecret,
    required this.paymentIntentId,
    this.ephemeralKey,
  });
}
