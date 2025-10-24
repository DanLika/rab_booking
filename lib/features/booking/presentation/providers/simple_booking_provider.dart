import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple booking state
class SimpleBookingState {
  final bool isLoading;
  final String? error;
  final String? bookingId;

  const SimpleBookingState({
    this.isLoading = false,
    this.error,
    this.bookingId,
  });

  SimpleBookingState copyWith({
    bool? isLoading,
    String? error,
    String? bookingId,
  }) {
    return SimpleBookingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bookingId: bookingId ?? this.bookingId,
    );
  }
}

/// Simple booking provider - Minimal MVP version
class SimpleBookingNotifier extends StateNotifier<SimpleBookingState> {
  final SupabaseClient _supabase;

  SimpleBookingNotifier(this._supabase) : super(const SimpleBookingState());

  /// Create booking - Minimal version
  Future<bool> createBooking({
    required String unitId,
    required String unitName,
    required String guestFirstName,
    required String guestLastName,
    required String guestEmail,
    required String guestPhone,
    required int numberOfGuests,
    required DateTime checkIn,
    required DateTime checkOut,
    required double totalPrice,
    String? specialRequests,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Calculate nights
      final nights = checkOut.difference(checkIn).inDays;

      // Create booking in database
      final response = await _supabase.from('bookings').insert({
        'unit_id': unitId,
        'guest_first_name': guestFirstName,
        'guest_last_name': guestLastName,
        'guest_email': guestEmail,
        'guest_phone': guestPhone,
        'number_of_guests': numberOfGuests,
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut.toIso8601String(),
        'nights': nights,
        'total_price': totalPrice,
        'advance_amount': totalPrice * 0.2, // 20% avans
        'status': 'pending', // Čeka uplatu avansa
        'special_requests': specialRequests,
        'source': 'web', // Može biti 'web' ili 'embed'
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final bookingId = response['id'] as String;

      state = state.copyWith(
        isLoading: false,
        bookingId: bookingId,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Greška pri kreiranju rezervacije: ${e.toString()}',
      );
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = const SimpleBookingState();
  }
}

/// Provider instance
final simpleBookingProvider =
    StateNotifierProvider<SimpleBookingNotifier, SimpleBookingState>((ref) {
  final supabase = Supabase.instance.client;
  return SimpleBookingNotifier(supabase);
});
