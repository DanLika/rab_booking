import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_form_state.freezed.dart';

/// Search form state
@freezed
class SearchFormState with _$SearchFormState {
  const factory SearchFormState({
    @Default('Otok Rab') String location,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    @Default(2) int adults,
    @Default(0) int children,
    @Default(0) int infants,
  }) = _SearchFormState;

  const SearchFormState._();

  /// Get total guest count
  int get totalGuests => adults + children + infants;

  /// Get guests display string
  String get guestsDisplay {
    final parts = <String>[];

    if (adults > 0) {
      parts.add('$adults ${adults == 1 ? 'odrasli' : 'odraslih'}');
    }

    if (children > 0) {
      parts.add('$children ${children == 1 ? 'dijete' : 'djece'}');
    }

    if (infants > 0) {
      parts.add('$infants ${infants == 1 ? 'beba' : 'beba'}');
    }

    return parts.isEmpty ? 'Gosti' : parts.join(', ');
  }

  /// Get dates display string
  String get datesDisplay {
    if (checkInDate == null || checkOutDate == null) {
      return 'Dolazak - Odlazak';
    }

    final checkIn = _formatDate(checkInDate!);
    final checkOut = _formatDate(checkOutDate!);

    return '$checkIn - $checkOut';
  }

  /// Format date to "22 Oct" format
  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  /// Get number of nights
  int? get nights {
    if (checkInDate == null || checkOutDate == null) return null;
    return checkOutDate!.difference(checkInDate!).inDays;
  }

  /// Validate search form
  bool get isValid {
    return location.isNotEmpty &&
        checkInDate != null &&
        checkOutDate != null &&
        checkOutDate!.isAfter(checkInDate!) &&
        totalGuests > 0;
  }
}
