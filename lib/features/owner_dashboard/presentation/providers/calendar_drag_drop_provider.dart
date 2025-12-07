import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/repositories/booking_repository.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../utils/booking_overlap_detector.dart';
import 'owner_calendar_provider.dart';

/// Drag-and-drop state for calendar
class DragDropState {
  final BookingModel? draggingBooking;
  final bool isValidDrop;
  final String? errorMessage;

  const DragDropState({
    this.draggingBooking,
    this.isValidDrop = false,
    this.errorMessage,
  });

  DragDropState copyWith({
    BookingModel? draggingBooking,
    bool? isValidDrop,
    String? errorMessage,
  }) {
    return DragDropState(
      draggingBooking: draggingBooking ?? this.draggingBooking,
      isValidDrop: isValidDrop ?? this.isValidDrop,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider for drag-and-drop state and operations
final dragDropProvider =
    StateNotifierProvider<DragDropNotifier, DragDropState>((ref) {
  final bookingRepository = ref.watch(bookingRepositoryProvider);
  return DragDropNotifier(bookingRepository, ref);
});

/// Notifier for drag-and-drop operations
class DragDropNotifier extends StateNotifier<DragDropState> {
  final BookingRepository _bookingRepository;
  final Ref _ref;

  DragDropNotifier(this._bookingRepository, this._ref)
      : super(const DragDropState());

  /// Start dragging a booking
  void startDragging(BookingModel booking) {
    state = DragDropState(draggingBooking: booking);
  }

  /// Stop dragging (cancelled)
  void stopDragging() {
    state = const DragDropState();
  }

  /// Validate drop target
  bool validateDrop({
    required DateTime dropDate,
    required String targetUnitId,
    required Map<String, List<BookingModel>> allBookings,
  }) {
    final booking = state.draggingBooking;
    if (booking == null) return false;

    // Normalize dates to midnight to avoid time-of-day issues
    final normalizedCheckIn = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
    final normalizedCheckOut = DateTime(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);
    final normalizedDropDate = DateTime(dropDate.year, dropDate.month, dropDate.day);

    // Calculate new dates
    final duration = normalizedCheckOut.difference(normalizedCheckIn);
    final newCheckIn = normalizedDropDate;
    final newCheckOut = newCheckIn.add(duration);

    // Validate using overlap detector
    final validation = BookingOverlapDetector.validateBookingMove(
      bookingId: booking.id,
      currentUnitId: booking.unitId,
      targetUnitId: targetUnitId,
      newCheckIn: newCheckIn,
      newCheckOut: newCheckOut,
      allBookings: allBookings,
    );

    // Update state
    state = state.copyWith(
      isValidDrop: validation.isValid,
      errorMessage: validation.isValid ? null : validation.reason,
    );

    return validation.isValid;
  }

  /// Execute drop (move booking to new date/unit)
  Future<bool> executeDrop({
    required DateTime dropDate,
    required UnitModel targetUnit,
    required Map<String, List<BookingModel>> allBookings,
    required BuildContext context,
  }) async {
    final booking = state.draggingBooking;
    if (booking == null) return false;

    // Normalize dates to midnight to avoid time-of-day issues
    final normalizedCheckIn = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
    final normalizedCheckOut = DateTime(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);
    final normalizedDropDate = DateTime(dropDate.year, dropDate.month, dropDate.day);

    // Calculate new dates
    final duration = normalizedCheckOut.difference(normalizedCheckIn);
    final newCheckIn = normalizedDropDate;
    final newCheckOut = newCheckIn.add(duration);

    // Final validation
    if (!validateDrop(
      dropDate: dropDate,
      targetUnitId: targetUnit.id,
      allBookings: allBookings,
    )) {
      // Show error snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage ?? 'Cannot move booking here'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Moving booking...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Update booking in Firestore
      final updatedBooking = booking.copyWith(
        unitId: targetUnit.id,
        checkIn: newCheckIn,
        checkOut: newCheckOut,
        updatedAt: DateTime.now(),
      );

      await _bookingRepository.updateBooking(updatedBooking);

      // Invalidate calendar to refresh
      _ref.invalidate(calendarBookingsProvider);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking moved to ${targetUnit.name} (${newCheckIn.day}/${newCheckIn.month} - ${newCheckOut.day}/${newCheckOut.month})',
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                _undoBookingMove(booking, context);
              },
            ),
          ),
        );
      }

      // Clear drag state
      state = const DragDropState();
      return true;
    } catch (e) {
      // FIXED: Use ErrorDisplayUtils to hide stack traces from users
      if (context.mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri premještanju rezervacije',
          onRetry: () {
            executeDrop(
              dropDate: dropDate,
              targetUnit: targetUnit,
              allBookings: allBookings,
              context: context,
            );
          },
        );
      }

      // Clear drag state
      state = const DragDropState();
      return false;
    }
  }

  /// Undo booking move (restore to original position)
  Future<void> _undoBookingMove(
    BookingModel originalBooking,
    BuildContext context,
  ) async {
    try {
      await _bookingRepository.updateBooking(originalBooking);
      _ref.invalidate(calendarBookingsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking restored to original position'),
            backgroundColor: AppColors.authSecondary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to undo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
