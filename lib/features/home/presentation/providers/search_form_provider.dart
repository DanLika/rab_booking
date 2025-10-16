import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../state/search_form_state.dart';

part 'search_form_provider.g.dart';

/// Search form state notifier
@riverpod
class SearchFormNotifier extends _$SearchFormNotifier {
  @override
  SearchFormState build() {
    return const SearchFormState();
  }

  /// Update location
  void updateLocation(String location) {
    state = state.copyWith(location: location);
  }

  /// Update check-in date
  void updateCheckInDate(DateTime? date) {
    state = state.copyWith(checkInDate: date);
  }

  /// Update check-out date
  void updateCheckOutDate(DateTime? date) {
    state = state.copyWith(checkOutDate: date);
  }

  /// Update date range
  void updateDateRange(DateTime? checkIn, DateTime? checkOut) {
    state = state.copyWith(
      checkInDate: checkIn,
      checkOutDate: checkOut,
    );
  }

  /// Update adults count
  void updateAdults(int count) {
    if (count >= 1) {
      state = state.copyWith(adults: count);
    }
  }

  /// Update children count
  void updateChildren(int count) {
    if (count >= 0) {
      state = state.copyWith(children: count);
    }
  }

  /// Update infants count
  void updateInfants(int count) {
    if (count >= 0) {
      state = state.copyWith(infants: count);
    }
  }

  /// Increment adults
  void incrementAdults() {
    if (state.adults < 20) {
      state = state.copyWith(adults: state.adults + 1);
    }
  }

  /// Decrement adults
  void decrementAdults() {
    if (state.adults > 1) {
      state = state.copyWith(adults: state.adults - 1);
    }
  }

  /// Increment children
  void incrementChildren() {
    if (state.children < 10) {
      state = state.copyWith(children: state.children + 1);
    }
  }

  /// Decrement children
  void decrementChildren() {
    if (state.children > 0) {
      state = state.copyWith(children: state.children - 1);
    }
  }

  /// Increment infants
  void incrementInfants() {
    if (state.infants < 5) {
      state = state.copyWith(infants: state.infants + 1);
    }
  }

  /// Decrement infants
  void decrementInfants() {
    if (state.infants > 0) {
      state = state.copyWith(infants: state.infants - 1);
    }
  }

  /// Reset form
  void reset() {
    state = const SearchFormState();
  }
}

/// Available locations on Rab island
const rabLocations = [
  'Otok Rab',
  'Rab (grad)',
  'Banjol',
  'Barbat',
  'Kampor',
  'Lopar',
  'Mundanije',
  'Palit',
  'Supetarska Draga',
];
