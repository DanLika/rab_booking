import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/models/booking_model.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/notifications_provider.dart';
import '../widgets/calendar/calendar_search_dialog.dart';
import '../widgets/calendar/calendar_filters_panel.dart';
import '../widgets/calendar/booking_inline_edit_dialog.dart';

/// Mixin with common methods shared across calendar screens
/// (Week, Month, Timeline)
mixin CalendarCommonMethodsMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
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
        ErrorDisplayUtils.showSuccessSnackBar(context, 'Podaci osvježeni');
      }
    } catch (e) {
      if (mounted) {
        // SECURITY FIX SF-012: Prevent info leakage - show generic message
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: 'Greška pri osvježavanju kalendara');
      }
    }
  }

  /// Show filters panel
  /// Returns true if filters were applied, false/null otherwise
  Future<bool?> showFiltersPanel() async {
    final result = await showDialog<bool>(context: context, builder: (context) => const CalendarFiltersPanel());
    return result;
  }

  /// Show notifications page
  void showNotificationsPanel() {
    context.go('/owner/notifications');
  }

  /// Show booking details dialog with quick edit option
  /// Calendar is refreshed by the dialog itself on successful edit
  Future<void> showBookingDetailsDialog(BookingModel booking) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => BookingInlineEditDialog(booking: booking),
    );
  }
}
