import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/booking_model.dart';

/// Resize mode enum
enum ResizeMode {
  none,
  resizingStart, // Dragging left edge (check-in date)
  resizingEnd, // Dragging right edge (check-out date)
}

/// Resize state model
class BookingResizeState {
  final BookingModel? bookingBeingResized;
  final ResizeMode mode;
  final DateTime? originalCheckIn;
  final DateTime? originalCheckOut;
  final DateTime? previewCheckIn;
  final DateTime? previewCheckOut;
  final bool isValid;
  final String? errorMessage;

  const BookingResizeState({
    this.bookingBeingResized,
    this.mode = ResizeMode.none,
    this.originalCheckIn,
    this.originalCheckOut,
    this.previewCheckIn,
    this.previewCheckOut,
    this.isValid = true,
    this.errorMessage,
  });

  bool get isResizing => mode != ResizeMode.none;

  BookingResizeState copyWith({
    BookingModel? bookingBeingResized,
    ResizeMode? mode,
    DateTime? originalCheckIn,
    DateTime? originalCheckOut,
    DateTime? previewCheckIn,
    DateTime? previewCheckOut,
    bool? isValid,
    String? errorMessage,
  }) {
    return BookingResizeState(
      bookingBeingResized: bookingBeingResized ?? this.bookingBeingResized,
      mode: mode ?? this.mode,
      originalCheckIn: originalCheckIn ?? this.originalCheckIn,
      originalCheckOut: originalCheckOut ?? this.originalCheckOut,
      previewCheckIn: previewCheckIn ?? this.previewCheckIn,
      previewCheckOut: previewCheckOut ?? this.previewCheckOut,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage,
    );
  }
}

/// Booking resize state notifier
class BookingResizeNotifier extends StateNotifier<BookingResizeState> {
  BookingResizeNotifier() : super(const BookingResizeState());

  /// Start resizing booking (left edge = check-in, right edge = check-out)
  void startResize(BookingModel booking, ResizeMode mode) {
    state = BookingResizeState(
      bookingBeingResized: booking,
      mode: mode,
      originalCheckIn: booking.checkIn,
      originalCheckOut: booking.checkOut,
      previewCheckIn: booking.checkIn,
      previewCheckOut: booking.checkOut,
    );
  }

  /// Update preview dates during drag
  void updatePreview({DateTime? checkIn, DateTime? checkOut}) {
    if (!state.isResizing) return;

    final newCheckIn = checkIn ?? state.previewCheckIn!;
    final newCheckOut = checkOut ?? state.previewCheckOut!;

    // Validate: check-in must be before check-out
    final isValid = newCheckIn.isBefore(newCheckOut);
    final errorMessage = isValid ? null : 'Check-in mora biti prije check-out datuma';

    // Minimum 1 night stay
    final nights = newCheckOut.difference(newCheckIn).inDays;
    final hasMinimumNights = nights >= 1;
    final finalIsValid = isValid && hasMinimumNights;
    final finalErrorMessage = !hasMinimumNights ? 'Minimalno trajanje je 1 noć' : errorMessage;

    state = state.copyWith(
      previewCheckIn: newCheckIn,
      previewCheckOut: newCheckOut,
      isValid: finalIsValid,
      errorMessage: finalErrorMessage,
    );
  }

  /// Cancel resize operation
  void cancelResize() {
    state = const BookingResizeState();
  }

  /// Get the updated booking with new dates (ready to save)
  BookingModel? getUpdatedBooking() {
    if (!state.isResizing || !state.isValid) return null;

    return state.bookingBeingResized!.copyWith(checkIn: state.previewCheckIn!, checkOut: state.previewCheckOut!);
  }

  /// Clear state after successful save
  void clearState() {
    state = const BookingResizeState();
  }
}

/// Booking resize provider
final bookingResizeProvider = StateNotifierProvider<BookingResizeNotifier, BookingResizeState>((ref) {
  return BookingResizeNotifier();
});
