/// Payment option - full amount vs down payment
enum PaymentOption {
  /// Pay full amount
  full,

  /// Pay down payment (partial)
  downPayment,
}

extension PaymentOptionExtension on PaymentOption {
  String get label {
    switch (this) {
      case PaymentOption.full:
        return 'Total amount';
      case PaymentOption.downPayment:
        return 'Down payment';
    }
  }

  String getDescription(double fullAmount, double downPaymentAmount) {
    switch (this) {
      case PaymentOption.full:
        return '\$$fullAmount USD + service payment on place';
      case PaymentOption.downPayment:
        final remaining = fullAmount - downPaymentAmount;
        return 'Prepayment + \$$remaining USD on place required';
    }
  }
}

/// Payment method - bank transfer vs stripe vs payment on place
enum PaymentMethod {
  /// Bank transfer
  bankTransfer,

  /// Stripe credit card payment (instant)
  stripe,

  /// Payment on arrival at property
  onPlace,
}

extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return 'Bank transfer';
      case PaymentMethod.stripe:
        return 'Credit Card';
      case PaymentMethod.onPlace:
        return 'Payment on place';
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return 'Waiting time for a bank transfer: 3 working days. If you do not make the transfer, the reservation will be cancelled.';
      case PaymentMethod.stripe:
        return 'Instant confirmation with credit card payment via Stripe. Secure and fast.';
      case PaymentMethod.onPlace:
        return 'Pay on place';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return '🏛️';
      case PaymentMethod.stripe:
        return '💳';
      case PaymentMethod.onPlace:
        return '🏛️';
    }
  }
}
