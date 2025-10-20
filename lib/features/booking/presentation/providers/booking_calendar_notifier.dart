import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/date_range.dart';

part 'booking_calendar_notifier.g.dart';

/// Booking calendar state
class BookingCalendarState {
  final DateTime? selectedCheckIn;
  final DateTime? selectedCheckOut;
  final List<DateRange> bookedRanges;
  final bool isLoading;
  final String? error;

  const BookingCalendarState({
    this.selectedCheckIn,
    this.selectedCheckOut,
    this.bookedRanges = const [],
    this.isLoading = false,
    this.error,
  });

  BookingCalendarState copyWith({
    DateTime? selectedCheckIn,
    DateTime? selectedCheckOut,
    List<DateRange>? bookedRanges,
    bool? isLoading,
    String? error,
  }) {
    return BookingCalendarState(
      selectedCheckIn: selectedCheckIn ?? this.selectedCheckIn,
      selectedCheckOut: selectedCheckOut ?? this.selectedCheckOut,
      bookedRanges: bookedRanges ?? this.bookedRanges,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Check if dates are selected
  bool get hasSelection => selectedCheckIn != null && selectedCheckOut != null;

  /// Number of selected nights
  int get selectedNights {
    if (!hasSelection) return 0;
    return selectedCheckOut!.difference(selectedCheckIn!).inDays;
  }

  /// Check if a date is available (not booked)
  bool isDateAvailable(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Check if date is in any booked range
    for (final range in bookedRanges) {
      if (range.contains(normalizedDate)) {
        return false;
      }
    }

    return true;
  }

  /// Check if a date is a check-in day
  bool isCheckInDay(DateTime date) {
    if (selectedCheckIn == null) return false;
    return _isSameDay(date, selectedCheckIn!);
  }

  /// Check if a date is a check-out day
  bool isCheckOutDay(DateTime date) {
    if (selectedCheckOut == null) return false;
    return _isSameDay(date, selectedCheckOut!);
  }

  /// Check if a date is in the selected range
  bool isInSelectedRange(DateTime date) {
    if (!hasSelection) return false;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(
      selectedCheckIn!.year,
      selectedCheckIn!.month,
      selectedCheckIn!.day,
    );
    final normalizedEnd = DateTime(
      selectedCheckOut!.year,
      selectedCheckOut!.month,
      selectedCheckOut!.day,
    );

    return (normalizedDate.isAtSameMomentAs(normalizedStart) ||
            normalizedDate.isAfter(normalizedStart)) &&
        normalizedDate.isBefore(normalizedEnd);
  }

  /// Check if a date range would overlap with booked dates
  bool wouldOverlapWithBookings(DateTime checkIn, DateTime checkOut) {
    final selectedRange = DateRange(start: checkIn, end: checkOut);

    for (final bookedRange in bookedRanges) {
      if (selectedRange.overlaps(bookedRange)) {
        return true;
      }
    }

    return false;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Booking calendar notifier
@riverpod
class BookingCalendarNotifier extends _$BookingCalendarNotifier {
  RealtimeChannel? _realtimeSubscription;

  @override
  BookingCalendarState build(String unitId) {
    // Fetch booked dates on initialization
    _fetchBookedDates(unitId);

    // Setup real-time subscription
    _setupRealtimeSubscription(unitId);

    // Cancel subscription on dispose
    ref.onDispose(() {
      _realtimeSubscription?.unsubscribe();
    });

    return const BookingCalendarState();
  }

  /// Fetch booked dates from Supabase
  Future<void> _fetchBookedDates(String unitId) async {
    state = state.copyWith(isLoading: true);

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('bookings')
          .select('check_in, check_out')
          .eq('unit_id', unitId)
          .inFilter('status', ['confirmed', 'pending']);

      final bookedRanges = (response as List).map((booking) {
        return DateRange(
          start: DateTime.parse(booking['check_in'] as String),
          end: DateTime.parse(booking['check_out'] as String),
        );
      }).toList();

      state = state.copyWith(
        bookedRanges: bookedRanges,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch bookings: $e',
      );
    }
  }

  /// Setup real-time subscription for booking updates
  void _setupRealtimeSubscription(String unitId) {
    final supabase = Supabase.instance.client;

    _realtimeSubscription = supabase
        .channel('bookings:$unitId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'unit_id',
            value: unitId,
          ),
          callback: (payload) {
            // Refresh booked dates when bookings change
            _fetchBookedDates(unitId);
          },
        )
        .subscribe();
  }

  /// Select a date (check-in or check-out logic)
  void selectDate(DateTime date, {int minStayNights = 1}) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Check if date is available
    if (!state.isDateAvailable(normalizedDate)) {
      return; // Cannot select booked dates
    }

    // First selection: set check-in
    if (state.selectedCheckIn == null) {
      state = state.copyWith(
        selectedCheckIn: normalizedDate,
        selectedCheckOut: null,
      );
      return;
    }

    // Second selection: set check-out
    if (state.selectedCheckOut == null) {
      // Check if selected date is before check-in
      if (normalizedDate.isBefore(state.selectedCheckIn!)) {
        // Reset and set as new check-in
        state = state.copyWith(
          selectedCheckIn: normalizedDate,
          selectedCheckOut: null,
        );
        return;
      }

      // Validate minimum stay
      final nights = normalizedDate.difference(state.selectedCheckIn!).inDays;
      if (nights < minStayNights) {
        // Too short, reset
        state = state.copyWith(
          selectedCheckIn: normalizedDate,
          selectedCheckOut: null,
        );
        return;
      }

      // Check if range overlaps with bookings
      if (state.wouldOverlapWithBookings(
        state.selectedCheckIn!,
        normalizedDate,
      )) {
        // Overlaps, reset
        state = state.copyWith(
          selectedCheckIn: normalizedDate,
          selectedCheckOut: null,
        );
        return;
      }

      // Valid selection
      state = state.copyWith(selectedCheckOut: normalizedDate);
      return;
    }

    // Third selection: reset and start new selection
    state = state.copyWith(
      selectedCheckIn: normalizedDate,
      selectedCheckOut: null,
    );
  }

  /// Clear selected dates
  void clearDates() {
    state = state.copyWith(
      selectedCheckIn: null,
      selectedCheckOut: null,
    );
  }

  /// Set specific check-in and check-out dates
  void setDates(DateTime checkIn, DateTime checkOut) {
    final normalizedCheckIn = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final normalizedCheckOut =
        DateTime(checkOut.year, checkOut.month, checkOut.day);

    state = state.copyWith(
      selectedCheckIn: normalizedCheckIn,
      selectedCheckOut: normalizedCheckOut,
    );
  }

  /// Refresh booked dates manually
  Future<void> refresh(String unitId) async {
    await _fetchBookedDates(unitId);
  }
}
