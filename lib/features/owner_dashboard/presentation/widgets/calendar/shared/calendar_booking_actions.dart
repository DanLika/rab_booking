import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/constants/enums.dart';
import '../../../../../../core/constants/booking_status_extensions.dart';
import '../../../../../../core/utils/error_display_utils.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../shared/models/booking_model.dart';
import '../../../../../../shared/providers/repository_providers.dart';
import '../../send_email_dialog.dart';
import '../../../providers/owner_calendar_provider.dart';
import '../../../providers/calendar_filters_provider.dart';
import '../../booking_actions/booking_delete_dialog.dart';

/// Shared Calendar Booking Actions
/// Contains common booking operations used across calendar views
class CalendarBookingActions {
  /// Delete booking with confirmation
  static Future<void> deleteBooking(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          BookingDeleteDialog(guestName: booking.guestName ?? 'N/A'),
    );

    if (confirm == true && context.mounted) {
      final l10nMounted = AppLocalizations.of(context);
      // Show loading indicator
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10nMounted.calendarActionsDeleting),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      try {
        final repository = ref.read(bookingRepositoryProvider);
        // Pass full booking to avoid permission issues with collection group query
        await repository.deleteBooking(booking.id, booking: booking);

        // Invalidate calendar providers to refresh UI
        ref.invalidate(calendarBookingsProvider);
        ref.invalidate(timelineCalendarBookingsProvider);

        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (context.mounted) {
          final l10nSuccess = AppLocalizations.of(context);
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10nSuccess.calendarActionsDeleted,
          );
        }
      } catch (e) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (context.mounted) {
          ErrorDisplayUtils.showErrorSnackBar(context, e);
        }
      }
    }
  }

  /// Change booking status
  static Future<void> changeBookingStatus(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
    BookingStatus newStatus,
  ) async {
    final l10n = AppLocalizations.of(context);
    // Show loading indicator
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.calendarActionsChangingStatus(
                      newStatus.displayNameLocalized(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final repository = ref.read(bookingRepositoryProvider);
      final updatedBooking = booking.copyWith(status: newStatus);
      await repository.updateBooking(updatedBooking);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        final l10nSuccess = AppLocalizations.of(context);
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          l10nSuccess.calendarActionsStatusChanged(
            newStatus.displayNameLocalized(context),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, e);
      }
    }
  }

  /// Send email to guest
  static void sendEmailToGuest(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
  ) {
    showSendEmailDialog(context, ref, booking);
  }
}
