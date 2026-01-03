import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/unit_model.dart';
import '../../domain/models/guest_details.dart';
import '../../domain/models/payment_option.dart';

/// Current step in booking flow
/// 0 = Room selection
/// 1 = Summary & additional services
/// 2 = Guest details & payment
/// 3 = Confirmation
final bookingStepProvider = StateProvider<int>((ref) => 0);

/// Selected check-in date
final checkInDateProvider = StateProvider<DateTime?>((ref) => null);

/// Selected check-out date
final checkOutDateProvider = StateProvider<DateTime?>((ref) => null);

/// Number of adults
final adultsCountProvider = StateProvider<int>((ref) => 2);

/// Number of children
final childrenCountProvider = StateProvider<int>((ref) => 0);

/// Selected room/unit
final selectedRoomProvider = StateProvider<UnitModel?>((ref) => null);

/// Whether to show booking summary sidebar
final showSummaryProvider = StateProvider<bool>((ref) => false);

/// Selected additional services (serviceId -> quantity)
final selectedServicesProvider =
    StateProvider<Map<String, int>>((ref) => {});

/// Guest details from form
final guestDetailsProvider = StateProvider<GuestDetails>((ref) => GuestDetails.empty());

/// Selected payment option (full vs down payment)
final paymentOptionProvider =
    StateProvider<PaymentOption>((ref) => PaymentOption.full);

/// Selected payment method (bank transfer vs on place)
final paymentMethodProvider =
    StateProvider<PaymentMethod>((ref) => PaymentMethod.onPlace);

/// Calculate number of nights
final numberOfNightsProvider = Provider<int>((ref) {
  final checkIn = ref.watch(checkInDateProvider);
  final checkOut = ref.watch(checkOutDateProvider);

  if (checkIn == null || checkOut == null) return 1;

  return checkOut.difference(checkIn).inDays;
});

/// Calculate total amount for booking
final bookingTotalProvider = Provider<double>((ref) {
  final room = ref.watch(selectedRoomProvider);
  final nights = ref.watch(numberOfNightsProvider);
  final selectedServices = ref.watch(selectedServicesProvider);

  double total = 0;

  // Room cost
  if (room != null) {
    total += room.pricePerNight * nights;
  }

  // Additional services cost (implement when we have services repository)
  // For now, assume each service costs $10
  selectedServices.forEach((serviceId, quantity) {
    total += 10.0 * quantity;
  });

  return total;
});

/// Calculate down payment amount (80% of total)
final downPaymentAmountProvider = Provider<double>((ref) {
  final total = ref.watch(bookingTotalProvider);
  return total * 0.8; // 80% down payment
});
