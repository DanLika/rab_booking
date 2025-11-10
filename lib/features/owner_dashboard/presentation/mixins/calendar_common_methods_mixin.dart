import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/models/booking_model.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/notifications_provider.dart';
import '../widgets/calendar/calendar_search_dialog.dart';
import '../widgets/calendar/calendar_filters_panel.dart';
import '../widgets/calendar/booking_inline_edit_dialog.dart';

/// Mixin with common methods shared across calendar screens
/// (Week, Month, Timeline)
mixin CalendarCommonMethodsMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {

  /// Show search dialog (unified with Month and Timeline views)
  void showSearchDialog() async {
    final selectedBooking = await showDialog<BookingModel>(
      context: context,
      builder: (context) => const CalendarSearchDialog(),
    );

    // If user selected a booking from search results, show its details
    if (selectedBooking != null && mounted) {
      unawaited(showBookingDetailsDialog(selectedBooking));
    }
  }

  /// Refresh calendar data - FULL page refresh
  Future<void> refreshCalendarData() async {
    // Show loading snackbar
    ErrorDisplayUtils.showLoadingSnackBar(context, 'Osvježavam podatke...');

    try {
      // Properly await all provider refreshes
      await Future.wait([
        ref.refresh(calendarBookingsProvider.future),
        ref.refresh(allOwnerUnitsProvider.future),
        ref.refresh(unreadNotificationsCountProvider.future),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ErrorDisplayUtils.showSuccessSnackBar(context, 'Podaci osvježeni');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ErrorDisplayUtils.showErrorSnackBar(context, e);
      }
    }
  }

  /// Show filters panel
  Future<void> showFiltersPanel() async {
    await showDialog(
      context: context,
      builder: (context) => const CalendarFiltersPanel(),
    );
  }

  /// Show notifications panel
  void showNotificationsPanel() {
    // TODO: Implement notifications panel
    ErrorDisplayUtils.showInfoSnackBar(
      context,
      'Notifications panel - coming soon',
    );
  }

  /// Show booking details dialog with quick edit option
  Future<void> showBookingDetailsDialog(BookingModel booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BookingInlineEditDialog(booking: booking),
    );

    // If edited successfully, result will be true
    if (result == true && mounted) {
      // Calendar already refreshed by dialog
    }
  }
}
