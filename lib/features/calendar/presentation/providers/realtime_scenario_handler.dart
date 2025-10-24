import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/calendar_permissions.dart';
import '../../domain/models/calendar_update_event.dart';
import '../../domain/models/booking_flow_state.dart';
import 'booking_flow_provider.dart';
import 'calendar_providers_refactored.dart';
import 'calendar_update_tracker.dart';
import 'calendar_permissions_provider.dart';

part 'realtime_scenario_handler.g.dart';

/// Handler for different real-time update scenarios
@riverpod
class RealtimeScenarioHandler extends _$RealtimeScenarioHandler {
  @override
  void build() {
    // Listen to realtime updates and handle scenarios
    return;
  }

  /// Scenario 1: Guest A viewing while Guest B makes booking
  /// Shows pulse animation on updated cells
  Future<void> handleGuestBookingConflict({
    required String unitId,
    required CalendarUpdateEvent event,
    required String propertyId,
  }) async {
    final permissions = ref.read(calendarPermissionsProvider);

    // Only handle for guest users
    if (permissions.role != UserRole.guest) return;

    final bookingFlow = ref.read(bookingFlowProvider(propertyId, unitId));

    // Check if guest has dates selected
    if (!bookingFlow.hasDatesSelected) {
      // Guest is just viewing, show pulse animation only
      return;
    }

    // Check if the update overlaps with guest's selection
    if (_hasOverlap(
      bookingFlow.checkInDate!,
      bookingFlow.checkOutDate!,
      event.checkInDate!,
      event.checkOutDate!,
    )) {
      // Conflict detected - mark conflicting dates
      final conflictingDates = _getOverlappingDates(
        bookingFlow.checkInDate!,
        bookingFlow.checkOutDate!,
        event.checkInDate!,
        event.checkOutDate!,
      );

      ref.read(calendarConflictDetectorProvider.notifier).markConflicts(
            conflictingDates,
          );

      // Show conflict notification
      ref.read(updateNotificationManagerProvider.notifier).show(
            message:
                'Selected dates are no longer available. Please choose different dates.',
            action: CalendarUpdateAction.insert,
            duration: const Duration(seconds: 5),
          );

      // Clear the guest's selection
      ref.read(bookingFlowProvider(propertyId, unitId).notifier).clearDates();
    }
  }

  /// Scenario 2: Owner blocks dates while guest is selecting
  /// Shows conflict indicator and prevents booking
  Future<void> handleOwnerBlockingConflict({
    required String unitId,
    required CalendarUpdateEvent event,
    required String propertyId,
  }) async {
    final permissions = ref.read(calendarPermissionsProvider);

    // Only handle for guest users
    if (permissions.role != UserRole.guest) return;

    final bookingFlow = ref.read(bookingFlowProvider(propertyId, unitId));

    if (!bookingFlow.hasDatesSelected) return;

    // Check if blocking overlaps with selection
    if (_hasOverlap(
      bookingFlow.checkInDate!,
      bookingFlow.checkOutDate!,
      event.checkInDate!,
      event.checkOutDate!,
    )) {
      // Show blocking notification
      ref.read(updateNotificationManagerProvider.notifier).show(
            message:
                'Owner has blocked selected dates. Please choose different dates.',
            action: CalendarUpdateAction.delete,
            duration: const Duration(seconds: 5),
          );

      // Mark as conflict
      final conflictingDates = _getOverlappingDates(
        bookingFlow.checkInDate!,
        bookingFlow.checkOutDate!,
        event.checkInDate!,
        event.checkOutDate!,
      );

      ref.read(calendarConflictDetectorProvider.notifier).markConflicts(
            conflictingDates,
          );

      // Clear selection
      ref.read(bookingFlowProvider(propertyId, unitId).notifier).clearDates();
    }
  }

  /// Scenario 3: Concurrent date selection by multiple users
  /// Last write wins, show notification to earlier user
  Future<void> handleConcurrentSelection({
    required String unitId,
    required CalendarUpdateEvent event,
    required String propertyId,
  }) async {
    final permissions = ref.read(calendarPermissionsProvider);

    // Only handle for guest users
    if (permissions.role != UserRole.guest) return;

    final bookingFlow = ref.read(bookingFlowProvider(propertyId, unitId));

    // If guest is in middle of booking flow (not just selecting)
    if (bookingFlow.currentStep != BookingFlowStep.selectDates &&
        bookingFlow.hasDatesSelected) {

      // Check for overlap
      if (_hasOverlap(
        bookingFlow.checkInDate!,
        bookingFlow.checkOutDate!,
        event.checkInDate!,
        event.checkOutDate!,
      )) {
        // Show race condition notification
        ref.read(updateNotificationManagerProvider.notifier).show(
              message:
                  'Another user just booked these dates. Your booking cannot proceed.',
              action: CalendarUpdateAction.insert,
              duration: const Duration(seconds: 7),
            );

        // Reset to date selection
        ref.read(bookingFlowProvider(propertyId, unitId).notifier).reset();

        // Mark conflicts
        final conflictingDates = _getOverlappingDates(
          bookingFlow.checkInDate!,
          bookingFlow.checkOutDate!,
          event.checkInDate!,
          event.checkOutDate!,
        );

        ref.read(calendarConflictDetectorProvider.notifier).markConflicts(
              conflictingDates,
            );
      }
    }
  }

  /// Scenario 4: Owner viewing their calendar gets real-time updates
  /// Shows detailed update information
  Future<void> handleOwnerViewUpdate({
    required String unitId,
    required CalendarUpdateEvent event,
  }) async {
    final permissions = ref.read(calendarPermissionsProvider);

    // Only handle for owner/super admin
    if (!permissions.canSeeBookingDetails) return;

    // Show detailed notification for owners
    String message;
    switch (event.action) {
      case CalendarUpdateAction.insert:
        message = 'New booking received for ${_formatDateRange(event)}';
        break;
      case CalendarUpdateAction.update:
        message = 'Booking updated for ${_formatDateRange(event)}';
        break;
      case CalendarUpdateAction.delete:
        message = 'Booking cancelled for ${_formatDateRange(event)}';
        break;
    }

    ref.read(updateNotificationManagerProvider.notifier).show(
          message: message,
          action: event.action,
          duration: const Duration(seconds: 4),
        );
  }

  /// Scenario 5: Real-time booking cancellation
  /// Updates calendar immediately, shows notification
  Future<void> handleBookingCancellation({
    required String unitId,
    required CalendarUpdateEvent event,
    required String propertyId,
  }) async {
    // Show cancellation notification
    ref.read(updateNotificationManagerProvider.notifier).show(
          message: 'Booking cancelled. Dates are now available.',
          action: CalendarUpdateAction.delete,
          duration: const Duration(seconds: 3),
        );

    // If guest had those dates selected, clear conflict
    final permissions = ref.read(calendarPermissionsProvider);
    if (permissions.role == UserRole.guest) {
      final bookingFlow = ref.read(bookingFlowProvider(propertyId, unitId));

      if (bookingFlow.hasDatesSelected) {
        // Check if cancellation affects selection
        if (_hasOverlap(
          bookingFlow.checkInDate!,
          bookingFlow.checkOutDate!,
          event.checkInDate!,
          event.checkOutDate!,
        )) {
          // Dates became available - clear any existing conflicts
          ref.read(calendarConflictDetectorProvider.notifier).clearConflicts();

          ref.read(updateNotificationManagerProvider.notifier).show(
                message: 'Great news! Your selected dates just became available.',
                action: CalendarUpdateAction.delete,
                duration: const Duration(seconds: 4),
              );
        }
      }
    }
  }

  /// Scenario 6: Optimistic update with rollback
  /// Shows loading state, then either confirms or rolls back
  Future<void> handleOptimisticUpdate({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required CalendarUpdateAction action,
  }) async {
    final tracker = ref.read(calendarUpdateTrackerProvider.notifier);

    // Mark as pending with shimmer effect
    tracker.markRangeUpdated(checkIn, checkOut, action);

    try {
      // Wait for server confirmation (this would be actual API call)
      await Future.delayed(const Duration(milliseconds: 200));

      // Success - update confirmed
      ref.read(updateNotificationManagerProvider.notifier).show(
            message: 'Changes saved successfully',
            action: action,
            duration: const Duration(seconds: 2),
          );
    } catch (error) {
      // Rollback on error
      ref.read(updateNotificationManagerProvider.notifier).show(
            message: 'Update failed. Please try again.',
            action: CalendarUpdateAction.delete,
            duration: const Duration(seconds: 4),
          );

      // Refresh calendar to get server state
      await ref.refresh(calendarDataProvider(unitId, DateTime.now()).future);
    }
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  /// Check if two date ranges overlap
  bool _hasOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  /// Get overlapping dates between two ranges
  Set<DateTime> _getOverlappingDates(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    final overlapping = <DateTime>{};

    // Find the overlap range
    final overlapStart = start1.isAfter(start2) ? start1 : start2;
    final overlapEnd = end1.isBefore(end2) ? end1 : end2;

    if (overlapStart.isBefore(overlapEnd) ||
        overlapStart.isAtSameMomentAs(overlapEnd)) {
      var current = overlapStart;
      while (current.isBefore(overlapEnd) ||
          current.isAtSameMomentAs(overlapEnd)) {
        overlapping.add(current);
        current = current.add(const Duration(days: 1));
      }
    }

    return overlapping;
  }

  /// Format date range for display
  String _formatDateRange(CalendarUpdateEvent event) {
    if (event.checkInDate == null || event.checkOutDate == null) {
      return '';
    }

    final checkIn = event.checkInDate!;
    final checkOut = event.checkOutDate!;

    return '${_formatDate(checkIn)} - ${_formatDate(checkOut)}';
  }

  /// Format single date
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

/// Provider for automatic scenario handling
@riverpod
class AutoScenarioHandler extends _$AutoScenarioHandler {
  @override
  void build(String unitId, String propertyId) {
    // Listen to realtime updates and automatically route to appropriate handler
    ref.listen(
      calendarRealtimeProvider(unitId),
      (prev, next) {
        next.whenData((event) {
          _routeScenario(event);
        });
      },
    );
  }

  /// Route update event to appropriate scenario handler
  void _routeScenario(CalendarUpdateEvent event) {
    final handler = ref.read(realtimeScenarioHandlerProvider.notifier);
    final permissions = ref.read(calendarPermissionsProvider);

    switch (event.action) {
      case CalendarUpdateAction.insert:
        if (permissions.role == UserRole.guest) {
          handler.handleGuestBookingConflict(
            unitId: unitId,
            event: event,
            propertyId: propertyId,
          );
        } else {
          handler.handleOwnerViewUpdate(
            unitId: unitId,
            event: event,
          );
        }
        break;

      case CalendarUpdateAction.update:
        if (permissions.role == UserRole.guest) {
          handler.handleConcurrentSelection(
            unitId: unitId,
            event: event,
            propertyId: propertyId,
          );
        } else {
          handler.handleOwnerViewUpdate(
            unitId: unitId,
            event: event,
          );
        }
        break;

      case CalendarUpdateAction.delete:
        handler.handleBookingCancellation(
          unitId: unitId,
          event: event,
          propertyId: propertyId,
        );
        break;
    }
  }
}
