import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/navigation_helpers.dart';

part 'home_search_provider.g.dart';

/// Simple search state for HomePage hero section
/// For detailed search, users go to SearchPage
class HomeSearchState {
  final String? destination;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int guests;
  final String? propertyType; // villa, apartment, house, studio

  const HomeSearchState({
    this.destination,
    this.checkIn,
    this.checkOut,
    this.guests = 2,
    this.propertyType,
  });

  HomeSearchState copyWith({
    String? destination,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    String? propertyType,
  }) {
    return HomeSearchState(
      destination: destination ?? this.destination,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guests: guests ?? this.guests,
      propertyType: propertyType ?? this.propertyType,
    );
  }

  /// Check if search has enough data to perform
  bool get canSearch => destination != null || propertyType != null;

  /// Convert to query params for SearchPage navigation
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (destination != null && destination!.isNotEmpty) {
      params['location'] = destination;
    }
    if (checkIn != null) {
      params['checkIn'] = checkIn!.toIso8601String();
    }
    if (checkOut != null) {
      params['checkOut'] = checkOut!.toIso8601String();
    }
    if (guests > 0) {
      params['guests'] = guests;
    }
    if (propertyType != null && propertyType!.isNotEmpty) {
      params['propertyType'] = propertyType;
    }

    return params;
  }
}

/// State notifier for home search
@riverpod
class HomeSearch extends _$HomeSearch {
  @override
  HomeSearchState build() {
    return const HomeSearchState();
  }

  void setDestination(String? value) {
    state = state.copyWith(destination: value);
  }

  void setCheckIn(DateTime? date) {
    state = state.copyWith(checkIn: date);
  }

  void setCheckOut(DateTime? date) {
    state = state.copyWith(checkOut: date);
  }

  void setGuests(int count) {
    state = state.copyWith(guests: count);
  }

  void setPropertyType(String? type) {
    state = state.copyWith(propertyType: type);
  }

  void reset() {
    state = const HomeSearchState();
  }
}
