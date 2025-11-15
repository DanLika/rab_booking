/// Price breakdown for a booking with deposit calculation
class BookingPriceBreakdown {
  final double subtotal;
  final List<NightlyPrice> nightlyPrices;
  final int numberOfNights;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final double additionalServicesTotal;
  final List<AdditionalServicePrice> additionalServices;
  final double depositPercentage; // Default 20%

  const BookingPriceBreakdown({
    required this.subtotal,
    required this.nightlyPrices,
    required this.numberOfNights,
    this.checkIn,
    this.checkOut,
    this.additionalServicesTotal = 0.0,
    this.additionalServices = const [],
    this.depositPercentage = 0.20, // 20% default
  });

  /// Total amount including additional services
  double get total => subtotal + additionalServicesTotal;

  /// Deposit amount (calculated client-side for display purposes only)
  ///
  /// ⚠️ SECURITY WARNING: This is CLIENT-SIDE calculation and can be manipulated!
  /// The createBookingAtomic Cloud Function MUST recalculate and validate the
  /// deposit amount server-side before creating Stripe checkout sessions.
  /// Never trust client-provided deposit amounts for payment processing.
  double get depositAmount => total * depositPercentage;

  /// Remaining balance after deposit
  double get remainingBalance => total - depositAmount;

  /// Average price per night
  double get averageNightlyRate =>
      numberOfNights > 0 ? subtotal / numberOfNights : 0.0;

  // Formatted strings
  String get formattedSubtotal => '€${subtotal.toStringAsFixed(2)}';
  String get formattedTotal => '€${total.toStringAsFixed(2)}';
  String get formattedAdditionalServices =>
      '€${additionalServicesTotal.toStringAsFixed(2)}';
  String get formattedDepositAmount => '€${depositAmount.toStringAsFixed(2)}';
  String get formattedRemainingBalance =>
      '€${remainingBalance.toStringAsFixed(2)}';
  String get formattedAverageNightlyRate =>
      '€${averageNightlyRate.toStringAsFixed(2)}';

  /// Copy with method for immutability
  BookingPriceBreakdown copyWith({
    double? subtotal,
    List<NightlyPrice>? nightlyPrices,
    int? numberOfNights,
    DateTime? checkIn,
    DateTime? checkOut,
    double? additionalServicesTotal,
    List<AdditionalServicePrice>? additionalServices,
    double? depositPercentage,
  }) {
    return BookingPriceBreakdown(
      subtotal: subtotal ?? this.subtotal,
      nightlyPrices: nightlyPrices ?? this.nightlyPrices,
      numberOfNights: numberOfNights ?? this.numberOfNights,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      additionalServicesTotal:
          additionalServicesTotal ?? this.additionalServicesTotal,
      additionalServices: additionalServices ?? this.additionalServices,
      depositPercentage: depositPercentage ?? this.depositPercentage,
    );
  }
}

/// Price for a single night
class NightlyPrice {
  final DateTime date;
  final double price;

  const NightlyPrice({
    required this.date,
    required this.price,
  });

  String get formattedPrice => '€${price.toStringAsFixed(2)}';
}

/// Additional service with pricing
class AdditionalServicePrice {
  final String serviceId;
  final String serviceName;
  final double pricePerUnit;
  final int quantity;
  final String pricingType; // 'per_stay', 'per_night', 'per_person'

  const AdditionalServicePrice({
    required this.serviceId,
    required this.serviceName,
    required this.pricePerUnit,
    required this.quantity,
    required this.pricingType,
  });

  double get totalPrice => pricePerUnit * quantity;

  String get formattedTotal => '€${totalPrice.toStringAsFixed(2)}';
  String get formattedPricePerUnit => '€${pricePerUnit.toStringAsFixed(2)}';
}
