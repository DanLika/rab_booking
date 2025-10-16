import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/property_model.dart';
import '../../../property/domain/models/property_unit.dart';

part 'booking_flow_notifier.freezed.dart';
part 'booking_flow_notifier.g.dart';

/// Booking flow state
@freezed
class BookingFlowState with _$BookingFlowState {
  const factory BookingFlowState({
    // Current step: review, payment, success
    @Default(BookingStep.review) BookingStep currentStep,

    // Selected property and unit
    PropertyModel? property,
    PropertyUnit? selectedUnit,

    // Booking details
    DateTime? checkInDate,
    DateTime? checkOutDate,
    @Default(2) int numberOfGuests,

    // Guest details
    String? guestFirstName,
    String? guestLastName,
    String? guestEmail,
    String? guestPhone,
    String? specialRequests,

    // Price calculation
    @Default(0.0) double basePrice,
    @Default(0.0) double serviceFee,
    @Default(0.0) double cleaningFee,
    @Default(0.0) double totalPrice,
    @Default(0.0) double advanceAmount,

    // Booking ID (created after review)
    String? bookingId,

    // Loading and error states
    @Default(false) bool isLoading,
    String? error,
  }) = _BookingFlowState;
}

/// Booking flow steps
enum BookingStep {
  review,
  payment,
  success;

  String get label {
    switch (this) {
      case BookingStep.review:
        return 'Pregled';
      case BookingStep.payment:
        return 'Plaćanje';
      case BookingStep.success:
        return 'Potvrda';
    }
  }
}

/// Booking flow notifier
@riverpod
class BookingFlowNotifier extends _$BookingFlowNotifier {
  @override
  BookingFlowState build() {
    return const BookingFlowState();
  }

  /// Initialize booking flow with property and unit
  void initializeBooking({
    required PropertyModel property,
    required PropertyUnit unit,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) {
    // Calculate number of nights
    final nights = checkOut.difference(checkIn).inDays;

    // Calculate prices
    final basePrice = unit.pricePerNight * nights;
    final serviceFee = basePrice * 0.10; // 10% service fee
    final cleaningFee = 50.0; // Fixed cleaning fee
    final totalPrice = basePrice + serviceFee + cleaningFee;
    final advanceAmount = totalPrice * 0.20; // 20% advance

    state = state.copyWith(
      property: property,
      selectedUnit: unit,
      checkInDate: checkIn,
      checkOutDate: checkOut,
      numberOfGuests: guests,
      basePrice: basePrice,
      serviceFee: serviceFee,
      cleaningFee: cleaningFee,
      totalPrice: totalPrice,
      advanceAmount: advanceAmount,
      currentStep: BookingStep.review,
    );
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

  /// Move to next step
  void nextStep() {
    switch (state.currentStep) {
      case BookingStep.review:
        state = state.copyWith(currentStep: BookingStep.payment);
        break;
      case BookingStep.payment:
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
      case BookingStep.review:
        // Already at first step
        break;
      case BookingStep.payment:
        state = state.copyWith(currentStep: BookingStep.review);
        break;
      case BookingStep.success:
        state = state.copyWith(currentStep: BookingStep.payment);
        break;
    }
  }

  /// Set booking ID after creation
  void setBookingId(String bookingId) {
    state = state.copyWith(bookingId: bookingId);
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
}
