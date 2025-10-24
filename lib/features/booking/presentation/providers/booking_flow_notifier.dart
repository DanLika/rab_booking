import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../property/domain/models/property_unit.dart';
import '../../../property/presentation/providers/unavailable_dates_provider.dart';
import '../../domain/constants/booking_constants.dart';
import '../../domain/models/refund_policy.dart';
import '../../domain/models/booking_status.dart';

part 'booking_flow_notifier.freezed.dart';
part 'booking_flow_notifier.g.dart';

/// Booking flow state
@freezed
class BookingFlowState with _$BookingFlowState {
  const factory BookingFlowState({
    // Current step: 6-step wizard
    @Default(BookingStep.guestDetails) BookingStep currentStep,

    // Selected property and unit
    PropertyModel? property,
    PropertyUnit? selectedUnit,

    // Booking details
    DateTime? checkInDate,
    DateTime? checkOutDate,
    @Default(1) int numberOfGuests, // Changed default to 1

    // Guest details
    String? guestFirstName,
    String? guestLastName,
    String? guestEmail,
    String? guestPhone,
    String? specialRequests,

    // Price calculation (with tax - FlutterFlow style)
    @Default(0.0) double basePrice, // price per night * nights * guests
    @Default(0.0) double serviceFee,
    @Default(0.0) double cleaningFee,
    @Default(0.0825) double taxRate, // 8.25% like FlutterFlow
    @Default(0.0) double taxAmount, // calculated from basePrice
    @Default(0.0) double totalPrice, // basePrice + serviceFee + cleaningFee + taxAmount

    // Advance payment (20% default)
    @Default(0.20) double advancePaymentPercentage,
    @Default(0.0) double advancePaymentAmount,
    @Default(false) bool isFullPaymentSelected,

    // Stripe Customer & Payment Methods
    String? stripeCustomerId,
    String? savedPaymentMethodId,
    @Default(false) bool savePaymentMethod,

    // Refund policy
    RefundPolicy? currentRefundPolicy,
    @Default(true) bool canCancelBooking,
    @Default(0.0) double cancellationFee,

    // E-Receipt
    String? receiptPdfUrl,
    @Default(false) bool receiptEmailSent,

    // Booking ID (created after review)
    String? bookingId,

    // Loading and error states
    @Default(false) bool isLoading,
    String? error,
  }) = _BookingFlowState;
}

/// Booking flow steps - 6-step wizard
enum BookingStep {
  guestDetails,     // 1. Guest information form
  dateSelection,    // 2. Real-time calendar date picker
  reviewSummary,    // 3. Review booking details + special requests
  paymentMethod,    // 4. Select payment amount (20% or full) + saved cards
  paymentProcessing,// 5. Stripe payment sheet
  success;          // 6. Success animation + e-receipt

  String get label {
    switch (this) {
      case BookingStep.guestDetails:
        return 'Podaci gosta';
      case BookingStep.dateSelection:
        return 'Datum';
      case BookingStep.reviewSummary:
        return 'Pregled';
      case BookingStep.paymentMethod:
        return 'Način plaćanja';
      case BookingStep.paymentProcessing:
        return 'Plaćanje';
      case BookingStep.success:
        return 'Potvrda';
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStep.guestDetails:
        return Icons.person_outline;
      case BookingStep.dateSelection:
        return Icons.calendar_month;
      case BookingStep.reviewSummary:
        return Icons.assignment_outlined;
      case BookingStep.paymentMethod:
        return Icons.payment;
      case BookingStep.paymentProcessing:
        return Icons.credit_card;
      case BookingStep.success:
        return Icons.check_circle_outline;
    }
  }

  int get stepNumber => index + 1;
  int get totalSteps => BookingStep.values.length;
}

/// Booking flow notifier
@riverpod
class BookingFlowNotifier extends _$BookingFlowNotifier {
  @override
  BookingFlowState build() {
    return const BookingFlowState();
  }

  /// Initialize booking flow with property and unit
  /// Validates dates against unavailable dates from Supabase
  Future<bool> initializeBooking({
    required PropertyModel property,
    required PropertyUnit unit,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) async {
    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Validate dates against unavailable dates
      final unavailableDates = await ref.read(
        unitUnavailableDatesProvider(unit.id).future,
      );

      // Check if selected range contains any unavailable dates
      final hasUnavailableDates = _hasUnavailableDatesInRange(
        checkIn,
        checkOut,
        unavailableDates,
      );

      if (hasUnavailableDates) {
        state = state.copyWith(
          isLoading: false,
          error: 'Odabrani period sadrži zauzete datume. Molimo odaberite drugi period.',
        );
        return false;
      }

      // Calculate number of nights
      final nights = checkOut.difference(checkIn).inDays;

      // Calculate base price with guest multiplier (FlutterFlow style)
      final basePrice = unit.pricePerNight * nights * guests;

      // Calculate tax on base price
      final taxAmount = basePrice * state.taxRate;

      // Calculate service fee and cleaning fee
      final serviceFee = BookingConstants.calculateServiceFee(basePrice);
      final cleaningFee = BookingConstants.cleaningFeeEur;

      // Total price includes tax
      final totalPrice = basePrice + taxAmount + serviceFee + cleaningFee;

      // Calculate advance payment (20% or full)
      final advanceAmount = state.isFullPaymentSelected
        ? totalPrice
        : totalPrice * state.advancePaymentPercentage;

      // Get applicable refund policy
      final refundPolicy = RefundPolicies.getApplicablePolicy(
        checkInDate: checkIn,
      );

      final canCancel = RefundPolicies.canCancelBooking(
        checkInDate: checkIn,
      );

      state = state.copyWith(
        property: property,
        selectedUnit: unit,
        checkInDate: checkIn,
        checkOutDate: checkOut,
        numberOfGuests: guests,
        basePrice: basePrice,
        taxAmount: taxAmount,
        serviceFee: serviceFee,
        cleaningFee: cleaningFee,
        totalPrice: totalPrice,
        advancePaymentAmount: advanceAmount,
        currentRefundPolicy: refundPolicy,
        canCancelBooking: canCancel,
        cancellationFee: refundPolicy.calculateCancellationFee(totalPrice),
        currentStep: BookingStep.guestDetails, // Start at guest details
        isLoading: false,
        error: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Greška pri validaciji datuma: $e',
      );
      return false;
    }
  }

  /// Initialize booking flow with just unit ID (fetches unit and property data)
  /// Used by BookingWizardScreen to load unit data on startup
  Future<void> initializeWithUnit(String unitId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch unit details
      final unitRepository = ref.read(unitRepositoryProvider);
      final unitModel = await unitRepository.fetchUnitById(unitId);

      if (unitModel == null) {
        throw Exception('Unit not found');
      }

      // Convert UnitModel to PropertyUnit
      final unit = PropertyUnit(
        id: unitModel.id,
        propertyId: unitModel.propertyId,
        name: unitModel.name,
        description: unitModel.description,
        pricePerNight: unitModel.pricePerNight,
        maxGuests: unitModel.maxGuests,
        bedrooms: unitModel.bedrooms,
        bathrooms: unitModel.bathrooms,
        area: unitModel.areaSqm ?? 0.0,
        amenities: [], // UnitModel doesn't have amenities
        images: unitModel.images,
        isAvailable: unitModel.isAvailable,
      );

      // Fetch property details
      final propertyRepository = ref.read(propertyRepositoryProvider);
      final property = await propertyRepository.fetchPropertyById(unit.propertyId);

      if (property == null) {
        throw Exception('Property not found for this unit');
      }

      // Update state with unit and property
      state = state.copyWith(
        selectedUnit: unit,
        property: property,
        isLoading: false,
        error: null,
      );

      debugPrint('✅ Booking flow initialized with unit: ${unit.name}, property: ${property.name}');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load unit details: $e',
      );
      debugPrint('❌ Failed to initialize booking flow: $e');
    }
  }

  /// Update guest details
  void updateGuestDetails({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? specialRequests,
  }) {
    state = state.copyWith(
      guestFirstName: firstName,
      guestLastName: lastName,
      guestEmail: email,
      guestPhone: phone,
      specialRequests: specialRequests,
    );
  }

  /// Move to next step (6-step wizard)
  void nextStep() {
    switch (state.currentStep) {
      case BookingStep.guestDetails:
        state = state.copyWith(currentStep: BookingStep.dateSelection);
        break;
      case BookingStep.dateSelection:
        state = state.copyWith(currentStep: BookingStep.reviewSummary);
        break;
      case BookingStep.reviewSummary:
        state = state.copyWith(currentStep: BookingStep.paymentMethod);
        break;
      case BookingStep.paymentMethod:
        state = state.copyWith(currentStep: BookingStep.paymentProcessing);
        break;
      case BookingStep.paymentProcessing:
        state = state.copyWith(currentStep: BookingStep.success);
        break;
      case BookingStep.success:
        // Already at final step
        break;
    }
  }

  /// Move to previous step
  void previousStep() {
    switch (state.currentStep) {
      case BookingStep.guestDetails:
        // Already at first step
        break;
      case BookingStep.dateSelection:
        state = state.copyWith(currentStep: BookingStep.guestDetails);
        break;
      case BookingStep.reviewSummary:
        state = state.copyWith(currentStep: BookingStep.dateSelection);
        break;
      case BookingStep.paymentMethod:
        state = state.copyWith(currentStep: BookingStep.reviewSummary);
        break;
      case BookingStep.paymentProcessing:
        state = state.copyWith(currentStep: BookingStep.paymentMethod);
        break;
      case BookingStep.success:
        state = state.copyWith(currentStep: BookingStep.paymentProcessing);
        break;
    }
  }

  /// Set booking ID after creation
  void setBookingId(String bookingId) {
    state = state.copyWith(bookingId: bookingId);
  }

  /// Create booking in database
  ///
  /// This should be called BEFORE moving to PaymentMethodStep.
  /// Creates a booking with initial status and stores the ID in state.
  Future<String> createBooking() async {
    // Validate we have all required data
    if (state.property == null ||
        state.selectedUnit == null ||
        state.checkInDate == null ||
        state.checkOutDate == null ||
        state.guestFirstName == null ||
        state.guestLastName == null ||
        state.guestEmail == null ||
        state.guestPhone == null) {
      throw Exception('Missing required booking data');
    }

    // Get current user
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Create booking model
      final booking = BookingModel(
        id: '', // Will be generated by database
        unitId: state.selectedUnit!.id,
        userId: currentUser.id,
        checkIn: state.checkInDate!,
        checkOut: state.checkOutDate!,
        status: BookingStatus.pending, // Initial status
        totalPrice: state.totalPrice,
        paidAmount: 0.0, // Not paid yet
        guestCount: state.numberOfGuests,
        notes: state.specialRequests,
        paymentIntentId: null, // Will be set after payment
        createdAt: DateTime.now(),
      );

      // Create in database
      final bookingRepository = ref.read(bookingRepositoryProvider);
      final createdBooking = await bookingRepository.createBooking(booking);

      // Update state with booking ID
      state = state.copyWith(
        bookingId: createdBooking.id,
        isLoading: false,
      );

      return createdBooking.id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create booking: $e',
      );
      rethrow;
    }
  }

  /// Process payment and create booking
  /// This confirms the Stripe PaymentIntent and creates the booking in database
  Future<void> processPayment() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Create booking in database
      final bookingId = await createBooking();

      // Update state with success
      state = state.copyWith(
        bookingId: bookingId,
        isLoading: false,
        error: null,
      );

      debugPrint('✅ Payment processed successfully. Booking ID: $bookingId');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Payment processing failed: $e',
      );
      debugPrint('❌ Payment processing error: $e');
      rethrow;
    }
  }

  /// Set loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Set error
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Reset booking flow
  void reset() {
    state = const BookingFlowState();
  }

  /// Get number of nights
  int get nights {
    if (state.checkInDate == null || state.checkOutDate == null) return 0;
    return state.checkOutDate!.difference(state.checkInDate!).inDays;
  }

  /// Validate guest details
  bool validateGuestDetails() {
    return state.guestFirstName != null &&
        state.guestFirstName!.isNotEmpty &&
        state.guestLastName != null &&
        state.guestLastName!.isNotEmpty &&
        state.guestEmail != null &&
        state.guestEmail!.isNotEmpty &&
        state.guestPhone != null &&
        state.guestPhone!.isNotEmpty;
  }

  /// Recalculate prices with tax and guest multiplier (FlutterFlow style)
  void recalculatePrices() {
    if (state.selectedUnit == null || state.checkInDate == null || state.checkOutDate == null) {
      return;
    }

    final nights = this.nights;
    final basePrice = state.selectedUnit!.pricePerNight * nights * state.numberOfGuests;
    final taxAmount = basePrice * state.taxRate;
    final serviceFee = BookingConstants.calculateServiceFee(basePrice);
    final cleaningFee = BookingConstants.cleaningFeeEur;
    final totalPrice = basePrice + taxAmount + serviceFee + cleaningFee;

    final advanceAmount = state.isFullPaymentSelected
        ? totalPrice
        : totalPrice * state.advancePaymentPercentage;

    state = state.copyWith(
      basePrice: basePrice,
      taxAmount: taxAmount,
      serviceFee: serviceFee,
      cleaningFee: cleaningFee,
      totalPrice: totalPrice,
      advancePaymentAmount: advanceAmount,
      cancellationFee: state.currentRefundPolicy?.calculateCancellationFee(totalPrice) ?? 0.0,
    );
  }

  /// Toggle between full payment and advance payment (20%)
  void toggleFullPayment(bool isFullPayment) {
    state = state.copyWith(isFullPaymentSelected: isFullPayment);
    recalculatePrices();
  }

  /// Update number of guests and recalculate prices
  void updateNumberOfGuests(int guests) {
    state = state.copyWith(numberOfGuests: guests);
    recalculatePrices();
  }

  /// Update refund policy based on current check-in date
  void updateRefundPolicy() {
    if (state.checkInDate == null) return;

    final refundPolicy = RefundPolicies.getApplicablePolicy(
      checkInDate: state.checkInDate!,
    );

    final canCancel = RefundPolicies.canCancelBooking(
      checkInDate: state.checkInDate!,
    );

    state = state.copyWith(
      currentRefundPolicy: refundPolicy,
      canCancelBooking: canCancel,
      cancellationFee: refundPolicy.calculateCancellationFee(state.totalPrice),
    );
  }

  /// Set Stripe Customer ID
  void setStripeCustomerId(String customerId) {
    state = state.copyWith(stripeCustomerId: customerId);
  }

  /// Set saved payment method
  void setSavedPaymentMethod(String? paymentMethodId) {
    state = state.copyWith(savedPaymentMethodId: paymentMethodId);
  }

  /// Toggle save payment method for future bookings
  void toggleSavePaymentMethod(bool save) {
    state = state.copyWith(savePaymentMethod: save);
  }

  /// Set receipt PDF URL after generation
  void setReceiptPdfUrl(String url) {
    state = state.copyWith(receiptPdfUrl: url);
  }

  /// Mark receipt email as sent
  void markReceiptEmailSent() {
    state = state.copyWith(receiptEmailSent: true);
  }

  /// Update receipt status (combines PDF URL and email sent)
  void updateReceiptStatus({
    String? receiptPdfUrl,
    bool? receiptEmailSent,
  }) {
    state = state.copyWith(
      receiptPdfUrl: receiptPdfUrl,
      receiptEmailSent: receiptEmailSent ?? state.receiptEmailSent,
    );
  }

  /// Get current refund policy description
  String? get refundPolicyDescription => state.currentRefundPolicy?.displayDescription;

  /// Check if date range contains any unavailable dates
  bool _hasUnavailableDatesInRange(
    DateTime start,
    DateTime end,
    List<DateTime> unavailableDates,
  ) {
    // Normalize dates to midnight
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    // Calculate range in days
    final range = normalizedEnd.difference(normalizedStart).inDays;

    // Check each date in the range
    for (var i = 0; i <= range; i++) {
      final date = normalizedStart.add(Duration(days: i));

      // Check if this date is unavailable
      final isUnavailable = unavailableDates.any((unavailable) {
        final normalizedUnavailable =
            DateTime(unavailable.year, unavailable.month, unavailable.day);
        return normalizedUnavailable.isAtSameMomentAs(date);
      });

      if (isUnavailable) {
        return true;
      }
    }

    return false;
  }
}
