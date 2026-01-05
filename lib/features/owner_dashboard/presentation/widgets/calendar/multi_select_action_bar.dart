import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../providers/multi_select_provider.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../../../../l10n/app_localizations.dart';

/// Action bar for multi-select mode
/// Shows bulk actions when bookings are selected
class MultiSelectActionBar extends ConsumerWidget {
  const MultiSelectActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiSelectState = ref.watch(multiSelectProvider);

    if (!multiSelectState.isEnabled || !multiSelectState.hasSelection) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final selectedCount = multiSelectState.selectionCount;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        boxShadow: AppShadows.getElevation(2, isDark: isDark),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Selection count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$selectedCount ${selectedCount == 1 ? l10n.ownerMultiSelectSelected : l10n.ownerMultiSelectSelectedPlural}',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Clear selection button
          TextButton.icon(
            onPressed: () {
              ref.read(multiSelectProvider.notifier).clearSelection();
            },
            icon: const Icon(Icons.clear, size: 18),
            label: Text(l10n.ownerMultiSelectClear),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            ),
          ),

          const SizedBox(width: 8),

          // Change status action
          MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                icon: const Icon(Icons.edit_note),
                tooltip: l10n.ownerMultiSelectChangeStatus,
                color: theme.colorScheme.primary,
              );
            },
            menuChildren: [
              MenuItemButton(
                leadingIcon: Icon(
                  Icons.check_circle,
                  color: BookingStatus.confirmed.color,
                  size: 20,
                ),
                child: Text(l10n.ownerStatusConfirmed),
                onPressed: () =>
                    _bulkUpdateStatus(context, ref, BookingStatus.confirmed),
              ),
              MenuItemButton(
                leadingIcon: Icon(
                  Icons.hourglass_empty,
                  color: BookingStatus.pending.color,
                  size: 20,
                ),
                child: Text(l10n.ownerStatusPending),
                onPressed: () =>
                    _bulkUpdateStatus(context, ref, BookingStatus.pending),
              ),
              MenuItemButton(
                leadingIcon: Icon(
                  Icons.cancel,
                  color: BookingStatus.cancelled.color,
                  size: 20,
                ),
                child: Text(l10n.ownerStatusCancelled),
                onPressed: () =>
                    _bulkUpdateStatus(context, ref, BookingStatus.cancelled),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // Delete action
          IconButton(
            onPressed: () => _confirmBulkDelete(context, ref),
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.ownerMultiSelectDeleteSelected,
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }

  /// Bulk update booking status
  Future<void> _bulkUpdateStatus(
    BuildContext context,
    WidgetRef ref,
    BookingStatus newStatus,
  ) async {
    final l10n = AppLocalizations.of(context);
    final multiSelectState = ref.read(multiSelectProvider);
    final selectedBookings = multiSelectState.selectedBookings;

    if (selectedBookings.isEmpty) return;

    final countLabel = selectedBookings.length == 1
        ? l10n.ownerMultiSelectReservation
        : l10n.ownerMultiSelectReservations;

    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.ownerMultiSelectConfirmation),
          content: Text(
            l10n.ownerMultiSelectChangeStatusConfirm(
              selectedBookings.length,
              countLabel,
              _getStatusLabel(newStatus, l10n),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.ownerMultiSelectCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.ownerMultiSelectConfirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);

      // Update all selected bookings
      for (final booking in selectedBookings) {
        await bookingRepo.updateBooking(booking.copyWith(status: newStatus));
      }

      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        final countLabel = selectedBookings.length == 1
            ? l10n.ownerMultiSelectReservation
            : l10n.ownerMultiSelectReservations;
        // Refresh calendar
        ref.invalidate(calendarBookingsProvider);

        // Clear selection and show success
        ref.read(multiSelectProvider.notifier).clearSelection();

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          l10n.ownerMultiSelectStatusChanged(
            selectedBookings.length,
            countLabel,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.ownerMultiSelectStatusError,
        );
      }
    }
  }

  /// Confirm bulk delete
  Future<void> _confirmBulkDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final multiSelectState = ref.read(multiSelectProvider);
    final selectedBookings = multiSelectState.selectedBookings;

    if (selectedBookings.isEmpty) return;

    final countLabel = selectedBookings.length == 1
        ? l10n.ownerMultiSelectReservation
        : l10n.ownerMultiSelectReservations;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 8),
              Text(l10n.ownerMultiSelectDeleteConfirmTitle),
            ],
          ),
          content: Text(
            l10n.ownerMultiSelectDeleteConfirmMessage(
              selectedBookings.length,
              countLabel,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.ownerMultiSelectCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.ownerMultiSelectDelete),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);

      // Delete all selected bookings
      for (final booking in selectedBookings) {
        await bookingRepo.deleteBooking(booking.id);
      }

      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        final countLabel = selectedBookings.length == 1
            ? l10n.ownerMultiSelectReservation
            : l10n.ownerMultiSelectReservations;
        // Refresh calendar
        ref.invalidate(calendarBookingsProvider);

        // Clear selection and show success
        ref.read(multiSelectProvider.notifier).disableMultiSelect();

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          l10n.ownerMultiSelectDeleted(selectedBookings.length, countLabel),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.ownerMultiSelectDeleteError,
        );
      }
    }
  }

  String _getStatusLabel(BookingStatus status, AppLocalizations l10n) {
    switch (status) {
      case BookingStatus.pending:
        return l10n.ownerStatusPending;
      case BookingStatus.confirmed:
        return l10n.ownerStatusConfirmed;
      case BookingStatus.completed:
        return l10n.ownerStatusCompleted;
      case BookingStatus.cancelled:
        return l10n.ownerStatusCancelled;
    }
  }
}
