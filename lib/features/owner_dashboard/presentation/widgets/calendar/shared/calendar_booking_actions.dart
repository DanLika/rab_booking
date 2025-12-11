import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/constants/enums.dart';
import '../../../../../../core/utils/error_display_utils.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../shared/models/booking_model.dart';
import '../../../../../../shared/providers/repository_providers.dart';
import '../../send_email_dialog.dart';

/// Shared Calendar Booking Actions
/// Contains common booking operations used across calendar views
class CalendarBookingActions {
  /// Delete booking with confirmation
  static Future<void> deleteBooking(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.calendarActionsDeleteTitle),
        content: Text(
          l10n.calendarActionsDeleteConfirm(booking.guestName ?? 'N/A'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.calendarActionsCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.calendarActionsDelete),
          ),
        ],
      ),
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
        await repository.deleteBooking(booking.id);

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
                    l10n.calendarActionsChangingStatus(newStatus.displayName),
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
          l10nSuccess.calendarActionsStatusChanged(newStatus.displayName),
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
