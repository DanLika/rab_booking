import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../data/services/owner_booking_callable_service.dart';
import '../../utils/booking_overlap_detector.dart';
import 'owner_calendar_provider.dart';
import 'calendar_filters_provider.dart';

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
final dragDropProvider = StateNotifierProvider<DragDropNotifier, DragDropState>(
  (ref) {
    final callableService = ref.watch(ownerBookingCallableServiceProvider);
    return DragDropNotifier(callableService, ref);
  },
);

/// Helper record for normalized booking dates
typedef _NormalizedDates = ({
  DateTime checkIn,
  DateTime checkOut,
  DateTime dropDate,
  Duration duration,
  DateTime newCheckIn,
  DateTime newCheckOut,
});

/// Normalize dates to midnight and calculate new booking dates
_NormalizedDates _normalizeBookingDates({
  required DateTime checkIn,
  required DateTime checkOut,
  required DateTime dropDate,
}) {
  final normalizedCheckIn = DateTime(checkIn.year, checkIn.month, checkIn.day);
  final normalizedCheckOut = DateTime(
    checkOut.year,
    checkOut.month,
    checkOut.day,
  );
  final normalizedDropDate = DateTime(
    dropDate.year,
    dropDate.month,
    dropDate.day,
  );
  final duration = normalizedCheckOut.difference(normalizedCheckIn);

  return (
    checkIn: normalizedCheckIn,
    checkOut: normalizedCheckOut,
    dropDate: normalizedDropDate,
    duration: duration,
    newCheckIn: normalizedDropDate,
    newCheckOut: normalizedDropDate.add(duration),
  );
}

/// Notifier for drag-and-drop operations
class DragDropNotifier extends StateNotifier<DragDropState> {
  final OwnerBookingCallableService _callableService;
  final Ref _ref;

  DragDropNotifier(this._callableService, this._ref)
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

    final dates = _normalizeBookingDates(
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
      dropDate: dropDate,
    );

    // Validate using overlap detector
    final validation = BookingOverlapDetector.validateBookingMove(
      bookingId: booking.id,
      currentUnitId: booking.unitId,
      targetUnitId: targetUnitId,
      newCheckIn: dates.newCheckIn,
      newCheckOut: dates.newCheckOut,
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

    final dates = _normalizeBookingDates(
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
      dropDate: dropDate,
    );

    // Final validation
    if (!validateDrop(
      dropDate: dropDate,
      targetUnitId: targetUnit.id,
      allBookings: allBookings,
    )) {
      // Show error snackbar
      if (context.mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          state.errorMessage ?? 'Cannot move booking here',
        );
      }
      return false;
    }

    try {
      // Show loading indicator
      if (context.mounted) {
        ErrorDisplayUtils.showLoadingSnackBar(context, 'Moving booking...');
      }

      // audit/26 PR-A: route through updateBookingAtomic so the overlap check
      // runs server-side inside a txn (the in-memory check above is a UX
      // preview only). The CF re-validates that auth.uid owns BOTH the source
      // booking AND the target property, and writes owner_id from the
      // validated target property — never trusting client-sent values.
      await _callableService.updateBooking(
        bookingId: booking.id,
        propertyId: booking.propertyId,
        unitId: booking.unitId,
        targetPropertyId: targetUnit.propertyId,
        targetUnitId: targetUnit.id,
        checkIn: dates.newCheckIn,
        checkOut: dates.newCheckOut,
      );

      // Invalidate calendar providers to refresh UI
      // MUST invalidate both: base provider AND filtered provider that UI watches
      _ref.invalidate(calendarBookingsProvider);
      _ref.invalidate(timelineCalendarBookingsProvider);

      // Show success message with undo action
      if (context.mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Booking moved to ${targetUnit.name} (${dates.newCheckIn.day}/${dates.newCheckIn.month} - ${dates.newCheckOut.day}/${dates.newCheckOut.month})',
          actionLabel: 'Undo',
          onAction: () => _undoBookingMove(booking, context),
        );
      }

      // Clear drag state
      state = const DragDropState();
      return true;
    } catch (e, stackTrace) {
      await LoggingService.logError('Failed to move booking', e, stackTrace);

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
  ///
  /// The booking is currently at the "moved" location; we send the original
  /// booking's IDs as the target so the CF moves it back. Server re-validates
  /// ownership of both source (current location) and target (restore point).
  Future<void> _undoBookingMove(
    BookingModel originalBooking,
    BuildContext context,
  ) async {
    final movedBooking = state.draggingBooking;
    try {
      // Determine current location: if state still has the drag context use
      // it; otherwise fall back to the original (no move happened).
      final currentPropertyId =
          movedBooking?.propertyId ?? originalBooking.propertyId;
      final currentUnitId = movedBooking?.unitId ?? originalBooking.unitId;
      await _callableService.updateBooking(
        bookingId: originalBooking.id,
        propertyId: currentPropertyId,
        unitId: currentUnitId,
        targetPropertyId: originalBooking.propertyId,
        targetUnitId: originalBooking.unitId,
        checkIn: originalBooking.checkIn,
        checkOut: originalBooking.checkOut,
      );
      _ref.invalidate(calendarBookingsProvider);

      if (context.mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Booking restored to original position',
        );
      }
    } catch (e, stackTrace) {
      await LoggingService.logError(
        'Failed to undo booking move',
        e,
        stackTrace,
      );
      if (context.mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Failed to undo booking move',
        );
      }
    }
  }
}
