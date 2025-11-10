import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../../../shared/models/booking_model.dart';

/// State for embed booking widget
class EmbedBookingState {
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final Map<DateTime, DailyPriceModel> prices;
  final Map<DateTime, BookingModel> bookings;
  final bool isLoading;
  final String? error;

  const EmbedBookingState({
    this.checkInDate,
    this.checkOutDate,
    this.prices = const {},
    this.bookings = const {},
    this.isLoading = false,
    this.error,
  });

  EmbedBookingState copyWith({
    DateTime? checkInDate,
    DateTime? checkOutDate,
    Map<DateTime, DailyPriceModel>? prices,
    Map<DateTime, BookingModel>? bookings,
    bool? isLoading,
    String? error,
  }) {
    return EmbedBookingState(
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      prices: prices ?? this.prices,
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Calculate total price for selected dates
  double get totalPrice {
    if (checkInDate == null || checkOutDate == null) return 0.0;

    double total = 0.0;
    DateTime current = checkInDate!;

    while (current.isBefore(checkOutDate!)) {
      final dateKey = _normalizeDate(current);
      final price = prices[dateKey];
      if (price != null) {
        total += price.price;
      }
      current = current.add(const Duration(days: 1));
    }

    return total;
  }

  /// Calculate number of nights
  int get nights {
    if (checkInDate == null || checkOutDate == null) return 0;
    return checkOutDate!.difference(checkInDate!).inDays;
  }

  /// Normalize date to midnight UTC for consistent comparison
  static DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }
}

/// Notifier for embed booking state
class EmbedBookingNotifier extends StateNotifier<EmbedBookingState> {
  final String unitId;
  final FirebaseFirestore _firestore;

  EmbedBookingNotifier({required this.unitId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      super(const EmbedBookingState()) {
    _loadData();
  }

  /// Load prices and bookings from Firestore
  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);

    try {
      // Load prices and bookings for current year + next year
      final currentYear = DateTime.now().year;
      final years = [currentYear, currentYear + 1];

      final pricesMap = <DateTime, DailyPriceModel>{};
      final bookingsMap = <DateTime, BookingModel>{};

      // Load prices
      for (final year in years) {
        final pricesSnapshot = await _firestore
            .collection('daily_prices')
            .doc(unitId)
            .collection(year.toString())
            .get();

        for (final monthDoc in pricesSnapshot.docs) {
          final monthData = monthDoc.data();
          monthData.forEach((dayStr, priceData) {
            try {
              final day = int.parse(dayStr);
              final month = int.parse(monthDoc.id);
              final date = DateTime.utc(year, month, day);

              if (priceData is Map<String, dynamic>) {
                pricesMap[date] = DailyPriceModel.fromJson(priceData);
              }
            } catch (e) {
              // Skip invalid entries
            }
          });
        }
      }

      // Load bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('unitId', isEqualTo: unitId)
          .where(
            'status',
            whereIn: ['confirmed', 'deposit_paid', 'pending_payment'],
          )
          .get();

      for (final bookingDoc in bookingsSnapshot.docs) {
        try {
          final booking = BookingModel.fromJson(bookingDoc.data());

          // Mark all days between check-in and check-out as booked
          DateTime current = booking.checkIn;
          while (current.isBefore(booking.checkOut)) {
            final dateKey = DateTime.utc(
              current.year,
              current.month,
              current.day,
            );
            bookingsMap[dateKey] = booking;
            current = current.add(const Duration(days: 1));
          }
        } catch (e) {
          // Skip invalid bookings
        }
      }

      state = state.copyWith(
        prices: pricesMap,
        bookings: bookingsMap,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Select check-in date
  void selectCheckIn(DateTime date) {
    final normalized = DateTime.utc(date.year, date.month, date.day);

    // If selecting new check-in, clear check-out if it's before new check-in
    if (state.checkOutDate != null && normalized.isAfter(state.checkOutDate!)) {
      state = state.copyWith(checkInDate: normalized);
    } else {
      state = state.copyWith(checkInDate: normalized);
    }
  }

  /// Select check-out date
  void selectCheckOut(DateTime date) {
    final normalized = DateTime.utc(date.year, date.month, date.day);

    // Check-out must be after check-in
    if (state.checkInDate != null && normalized.isAfter(state.checkInDate!)) {
      state = state.copyWith(checkOutDate: normalized);
    }
  }

  /// Clear selection
  void clearSelection() {
    state = state.copyWith(checkOutDate: null);
  }

  /// Check if date is available for booking
  bool isDateAvailable(DateTime date) {
    final normalized = DateTime.utc(date.year, date.month, date.day);

    // Has price and not booked
    return state.prices.containsKey(normalized) &&
        !state.bookings.containsKey(normalized);
  }

  /// Get price for specific date
  double? getPriceForDate(DateTime date) {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    return state.prices[normalized]?.price;
  }

  /// Check if date is booked
  bool isDateBooked(DateTime date) {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    return state.bookings.containsKey(normalized);
  }
}

/// Provider for embed booking state
final embedBookingProvider =
    StateNotifierProvider.family<
      EmbedBookingNotifier,
      EmbedBookingState,
      String
    >((ref, unitId) => EmbedBookingNotifier(unitId: unitId));
