import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/booking_flow_state.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/calendar_permissions.dart';
import '../../domain/models/validation_result.dart';
import 'calendar_providers_refactored.dart';
import 'calendar_update_tracker.dart';
import 'booking_validation_provider.dart';

part 'booking_flow_provider.g.dart';

// =============================================================================
// BOOKING FLOW PROVIDERS (Guest Users)
// =============================================================================

/// Provider for booking flow state
@riverpod
class BookingFlow extends _$BookingFlow {
  @override
  BookingFlowState build(String propertyId, String unitId) {
    return BookingFlowState(
      currentStep: BookingFlowStep.selectDates,
      propertyId: propertyId,
      unitId: unitId,
    );
  }

  /// Select check-in date
  void selectCheckIn(DateTime date) {
    state = state.copyWith(
      checkInDate: date,
      checkOutDate: null, // Reset check-out when check-in changes
    );
  }

  /// Select check-out date
  void selectCheckOut(DateTime date) async {
    if (state.checkInDate == null) {
      // If no check-in, set as check-in instead
      selectCheckIn(date);
      return;
    }

    if (date.isBefore(state.checkInDate!)) {
      // If before check-in, swap them
      state = state.copyWith(
        checkInDate: date,
        checkOutDate: state.checkInDate,
      );
    } else {
      state = state.copyWith(checkOutDate: date);
    }

    // Validate date range
    final validationResult = await ref.read(
      validateDateRangeProvider(
        unitId,
        state.checkInDate!,
        state.checkOutDate!,
      ).future,
    );

    if (!validationResult.isValid) {
      // Show validation error
      state = state.copyWith(
        error: validationResult.errorMessage,
        checkOutDate: null, // Clear invalid selection
      );
      return;
    }

    // Check for conflicts with recent updates
    ref.read(calendarConflictDetectorProvider.notifier).checkConflicts(
          state.checkInDate,
          state.checkOutDate,
        );

    // Calculate price when dates are selected
    _calculatePrice();
  }

  /// Clear selected dates
  void clearDates() {
    state = state.copyWith(
      checkInDate: null,
      checkOutDate: null,
      totalPrice: null,
      totalNights: null,
    );
  }

  /// Set guest count
  void setGuestCount(int count) {
    state = state.copyWith(guestCount: count);
    _calculatePrice(); // Recalculate if price depends on guests
  }

  /// Calculate price based on selected dates
  void _calculatePrice() {
    if (state.checkInDate == null || state.checkOutDate == null) {
      return;
    }

    final nights =
        state.checkOutDate!.difference(state.checkInDate!).inDays;

    // TODO: Get actual price from property/unit
    // For now, use a dummy price
    final pricePerNight = 120.0;
    final total = pricePerNight * nights;

    state = state.copyWith(
      pricePerNight: pricePerNight,
      totalNights: nights,
      totalPrice: total,
    );
  }

  /// Proceed to next step
  void nextStep() {
    if (!state.canProceed) return;

    final nextStep = BookingFlowStep.values[
        (state.currentStep.index + 1) % BookingFlowStep.values.length];

    state = state.copyWith(currentStep: nextStep);
  }

  /// Go back to previous step
  void previousStep() {
    if (state.currentStep.index == 0) return;

    final prevStep = BookingFlowStep.values[state.currentStep.index - 1];

    state = state.copyWith(currentStep: prevStep);
  }

  /// Set guest details
  void setGuestDetails({
    required String name,
    required String email,
    required String phone,
    String? specialRequests,
  }) {
    state = state.copyWith(
      guestName: name,
      guestEmail: email,
      guestPhone: phone,
      specialRequests: specialRequests,
    );
  }

  /// Complete booking
  Future<void> completeBooking() async {
    if (!state.hasDatesSelected) {
      throw Exception('Dates not selected');
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      // Step 1: Final validation before payment
      final validationResult = await ref.read(
        validateFullBookingProvider(
          unitId,
          state.checkInDate!,
          state.checkOutDate!,
        ).future,
      );

      if (!validationResult.isValid) {
        throw ValidationException(
          validationResult.errorMessage ?? 'Validation failed',
          result: validationResult,
        );
      }

      // Step 2: Create booking atomically (prevents race conditions)
      final atomicHandler = ref.read(atomicBookingHandlerProvider);

      final result = await atomicHandler.createBookingAtomic(
        unitId: unitId,
        checkIn: state.checkInDate!,
        checkOut: state.checkOutDate!,
        userId: '', // TODO: Get from auth
        guestCount: state.guestCount,
        totalPrice: state.totalPrice ?? 0.0,
        notes: state.specialRequests,
      );

      // Step 3: Move to confirmation step
      state = state.copyWith(
        currentStep: BookingFlowStep.confirmation,
        isProcessing: false,
      );
    } on BookingConflictException catch (e) {
      // Handle race condition gracefully
      state = state.copyWith(
        isProcessing: false,
        error: e.message,
      );

      // Show conflict and reset to date selection
      ref.read(updateNotificationManagerProvider.notifier).show(
            message: e.message,
            action: CalendarUpdateAction.insert,
            duration: const Duration(seconds: 7),
          );

      // Reset flow
      reset();
    } on ValidationException catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Reset flow
  void reset() {
    state = BookingFlowState(
      currentStep: BookingFlowStep.selectDates,
      propertyId: propertyId,
      unitId: unitId,
    );
  }
}

// =============================================================================
// DATE BLOCKING FLOW PROVIDERS (Owner Users)
// =============================================================================

/// Provider for date blocking flow state
@riverpod
class BlockingFlow extends _$BlockingFlow {
  @override
  BlockingFlowState build(String unitId) {
    return BlockingFlowState(
      currentStep: BlockingFlowStep.selectDates,
      unitId: unitId,
    );
  }

  /// Select start date
  void selectStartDate(DateTime date) {
    state = state.copyWith(
      startDate: date,
      endDate: null, // Reset end date
    );
  }

  /// Select end date
  void selectEndDate(DateTime date) {
    if (state.startDate == null) {
      selectStartDate(date);
      return;
    }

    if (date.isBefore(state.startDate!)) {
      // Swap if before start
      state = state.copyWith(
        startDate: date,
        endDate: state.startDate,
      );
    } else {
      state = state.copyWith(endDate: date);
    }
  }

  /// Clear selected dates
  void clearDates() {
    state = state.copyWith(
      startDate: null,
      endDate: null,
    );
  }

  /// Set blocking reason
  void setReason(String reason, {String? notes}) {
    state = state.copyWith(
      reason: reason,
      notes: notes,
    );
  }

  /// Proceed to next step
  void nextStep() {
    if (!state.canProceed) return;

    final nextStep = BlockingFlowStep.values[
        (state.currentStep.index + 1) % BlockingFlowStep.values.length];

    state = state.copyWith(currentStep: nextStep);
  }

  /// Go back
  void previousStep() {
    if (state.currentStep.index == 0) return;

    final prevStep =
        BlockingFlowStep.values[state.currentStep.index - 1];

    state = state.copyWith(currentStep: prevStep);
  }

  /// Complete blocking
  Future<void> completeBlocking() async {
    if (!state.hasDatesSelected || state.reason == null) {
      throw Exception('Required fields missing');
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      // Block dates via repository
      await ref.read(blockedDatesRefactoredProvider(unitId).notifier).blockDates(
        from: state.startDate!,
        to: state.endDate!,
        reason: state.reason!,
        notes: state.notes,
      );

      // Move to confirmation
      state = state.copyWith(
        currentStep: BlockingFlowStep.confirmation,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Reset flow
  void reset() {
    state = BlockingFlowState(
      currentStep: BlockingFlowStep.selectDates,
      unitId: unitId,
    );
  }
}

// =============================================================================
// CALENDAR INTERACTION PROVIDERS
// =============================================================================

/// Provider for calendar interaction state
@riverpod
class CalendarInteraction extends _$CalendarInteraction {
  @override
  CalendarInteractionState build() {
    return const CalendarInteractionState(
      mode: DateSelectionMode.checkIn,
    );
  }

  /// Handle date tap
  void onDateTap(DateTime date, CalendarDay dayData) {
    switch (state.mode) {
      case DateSelectionMode.checkIn:
        // First tap - select check-in
        state = state.copyWith(
          firstSelectedDate: date,
          mode: DateSelectionMode.checkOut,
        );
        break;

      case DateSelectionMode.checkOut:
        // Second tap - select check-out
        if (date.isBefore(state.firstSelectedDate!)) {
          // If before first date, swap them
          state = state.copyWith(
            secondSelectedDate: state.firstSelectedDate,
            firstSelectedDate: date,
            mode: DateSelectionMode.complete,
          );
        } else {
          state = state.copyWith(
            secondSelectedDate: date,
            mode: DateSelectionMode.complete,
          );
        }
        break;

      case DateSelectionMode.complete:
        // Third tap - reset and start over
        state = state.copyWith(
          firstSelectedDate: date,
          secondSelectedDate: null,
          mode: DateSelectionMode.checkOut,
        );
        break;
    }
  }

  /// Handle date hover (for desktop/web)
  void onDateHover(DateTime? date) {
    state = state.copyWith(hoveredDate: date);
  }

  /// Handle long press start
  void onLongPressStart(CalendarDay dayData) {
    state = state.copyWith(
      isLongPressing: true,
      longPressedDay: dayData,
    );
  }

  /// Handle long press end
  void onLongPressEnd() {
    state = state.copyWith(
      isLongPressing: false,
      longPressedDay: null,
    );
  }

  /// Clear selection
  void clearSelection() {
    state = const CalendarInteractionState(
      mode: DateSelectionMode.checkIn,
    );
  }

  /// Get selected date range
  DateTimeRange? getSelectedRange() {
    return state.selectedRange;
  }
}

// =============================================================================
// BOOKING SUMMARY PROVIDER
// =============================================================================

/// Provider for booking summary
@riverpod
class BookingSummaryNotifier extends _$BookingSummaryNotifier {
  @override
  BookingSummary? build(String propertyId, String unitId) {
    return null;
  }

  /// Calculate and set booking summary
  void calculate({
    required DateTime checkIn,
    required DateTime checkOut,
    required double pricePerNight,
    required int guestCount,
    String? propertyName,
    String? unitName,
  }) {
    final nights = checkOut.difference(checkIn).inDays;
    final subtotal = pricePerNight * nights;

    // Calculate fees (example calculations)
    final serviceFee = subtotal * 0.10; // 10% service fee
    final cleaningFee = 50.0; // Fixed cleaning fee
    final taxes = (subtotal + serviceFee + cleaningFee) * 0.08; // 8% tax

    final total = subtotal + serviceFee + cleaningFee + taxes;

    state = BookingSummary(
      checkIn: checkIn,
      checkOut: checkOut,
      checkInTime: '3:00 PM',
      checkOutTime: '10:00 AM',
      nights: nights,
      pricePerNight: pricePerNight,
      subtotal: subtotal,
      serviceFee: serviceFee,
      cleaningFee: cleaningFee,
      taxes: taxes,
      total: total,
      currency: '€',
      guestCount: guestCount,
      propertyName: propertyName,
      unitName: unitName,
    );
  }

  /// Clear summary
  void clear() {
    state = null;
  }
}
