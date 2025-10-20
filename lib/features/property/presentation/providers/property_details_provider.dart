import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/property_model.dart';
import '../../data/repositories/property_details_repository.dart';
import '../../domain/models/property_unit.dart';

part 'property_details_provider.g.dart';

/// Property details provider (fetch by ID)
@riverpod
Future<PropertyModel?> propertyDetails(
  Ref ref,
  String propertyId,
) async {
  final repository = ref.watch(propertyDetailsRepositoryProvider);
  return await repository.getPropertyById(propertyId);
}

/// Units provider (fetch units for a property)
@riverpod
Future<List<PropertyUnit>> propertyUnits(
  Ref ref,
  String propertyId,
) async {
  final repository = ref.watch(propertyDetailsRepositoryProvider);
  return await repository.getUnitsForProperty(propertyId);
}

/// Single unit provider (fetch unit by ID)
@riverpod
Future<PropertyUnit?> unitDetails(
  Ref ref,
  String unitId,
) async {
  final repository = ref.watch(propertyDetailsRepositoryProvider);
  return await repository.getUnitById(unitId);
}

/// Selected dates provider for booking
@riverpod
class SelectedDatesNotifier extends _$SelectedDatesNotifier {
  @override
  SelectedDates build() {
    return const SelectedDates();
  }

  void setCheckIn(DateTime? date) {
    state = state.copyWith(checkIn: date);
  }

  void setCheckOut(DateTime? date) {
    state = state.copyWith(checkOut: date);
  }

  void setDates(DateTime? checkIn, DateTime? checkOut) {
    state = state.copyWith(checkIn: checkIn, checkOut: checkOut);
  }

  void clearDates() {
    state = const SelectedDates();
  }

  int get numberOfNights {
    if (state.checkIn == null || state.checkOut == null) return 0;
    return state.checkOut!.difference(state.checkIn!).inDays;
  }
}

/// Selected dates model
class SelectedDates {
  final DateTime? checkIn;
  final DateTime? checkOut;

  const SelectedDates({
    this.checkIn,
    this.checkOut,
  });

  SelectedDates copyWith({
    DateTime? checkIn,
    DateTime? checkOut,
  }) {
    return SelectedDates(
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
    );
  }

  bool get hasCompleteDates => checkIn != null && checkOut != null;
}

/// Selected guests provider
@riverpod
class SelectedGuestsNotifier extends _$SelectedGuestsNotifier {
  @override
  int build() {
    return 2; // Default 2 guests
  }

  void setGuests(int guests) {
    state = guests;
  }

  void increment() {
    state++;
  }

  void decrement() {
    if (state > 1) state--;
  }
}

/// Booking calculation provider (calculates total price)
@riverpod
Future<Map<String, dynamic>?> bookingCalculation(
  Ref ref,
  String unitId,
) async {
  final dates = ref.watch(selectedDatesNotifierProvider);
  final guests = ref.watch(selectedGuestsNotifierProvider);

  if (!dates.hasCompleteDates) return null;

  final repository = ref.watch(propertyDetailsRepositoryProvider);

  return await repository.calculateBookingPrice(
    unitId: unitId,
    checkIn: dates.checkIn!,
    checkOut: dates.checkOut!,
    guests: guests,
  );
}

/// Blocked dates provider for a unit
@riverpod
Future<List<DateTime>> blockedDates(
  Ref ref,
  String unitId,
) async {
  final repository = ref.watch(propertyDetailsRepositoryProvider);
  return await repository.getBlockedDatesForUnit(unitId);
}

/// Unit availability provider
@riverpod
Future<bool> unitAvailability(
  Ref ref,
  String unitId,
) async {
  final dates = ref.watch(selectedDatesNotifierProvider);

  if (!dates.hasCompleteDates) return false;

  final repository = ref.watch(propertyDetailsRepositoryProvider);

  return await repository.checkUnitAvailability(
    unitId: unitId,
    checkIn: dates.checkIn!,
    checkOut: dates.checkOut!,
  );
}
