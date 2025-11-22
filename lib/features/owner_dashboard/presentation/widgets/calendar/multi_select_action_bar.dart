import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../providers/multi_select_provider.dart';
import '../../providers/owner_calendar_provider.dart';

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
                  '$selectedCount ${selectedCount == 1 ? 'odabrana' : 'odabrano'}',
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
            label: const Text('Poništi'),
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
                tooltip: 'Promijeni status',
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
                child: const Text('Potvrđeno'),
                onPressed: () => _bulkUpdateStatus(
                  context,
                  ref,
                  BookingStatus.confirmed,
                ),
              ),
              MenuItemButton(
                leadingIcon: Icon(
                  Icons.hourglass_empty,
                  color: BookingStatus.pending.color,
                  size: 20,
                ),
                child: const Text('Na čekanju'),
                onPressed: () => _bulkUpdateStatus(
                  context,
                  ref,
                  BookingStatus.pending,
                ),
              ),
              MenuItemButton(
                leadingIcon: Icon(
                  Icons.cancel,
                  color: BookingStatus.cancelled.color,
                  size: 20,
                ),
                child: const Text('Otkazano'),
                onPressed: () => _bulkUpdateStatus(
                  context,
                  ref,
                  BookingStatus.cancelled,
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // Delete action
          IconButton(
            onPressed: () => _confirmBulkDelete(context, ref),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Obriši odabrano',
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
    final multiSelectState = ref.read(multiSelectProvider);
    final selectedBookings = multiSelectState.selectedBookings;

    if (selectedBookings.isEmpty) return;

    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda'),
        content: Text(
          'Promijeni status za ${selectedBookings.length} ${selectedBookings.length == 1 ? 'rezervaciju' : 'rezervacija'} u "${_getStatusLabel(newStatus)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);

      // Update all selected bookings
      for (final booking in selectedBookings) {
        await bookingRepo.updateBooking(
          booking.copyWith(status: newStatus),
        );
      }

      if (context.mounted) {
        // Refresh calendar
        ref.invalidate(calendarBookingsProvider);

        // Clear selection and show success
        ref.read(multiSelectProvider.notifier).clearSelection();

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Status promijenjen za ${selectedBookings.length} ${selectedBookings.length == 1 ? 'rezervaciju' : 'rezervacija'}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri promjeni statusa',
        );
      }
    }
  }

  /// Confirm bulk delete
  Future<void> _confirmBulkDelete(BuildContext context, WidgetRef ref) async {
    final multiSelectState = ref.read(multiSelectProvider);
    final selectedBookings = multiSelectState.selectedBookings;

    if (selectedBookings.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Potvrda brisanja'),
          ],
        ),
        content: Text(
          'Jeste li sigurni da želite obrisati ${selectedBookings.length} ${selectedBookings.length == 1 ? 'rezervaciju' : 'rezervacija'}?\n\nOva akcija se ne može poništiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);

      // Delete all selected bookings
      for (final booking in selectedBookings) {
        await bookingRepo.deleteBooking(booking.id);
      }

      if (context.mounted) {
        // Refresh calendar
        ref.invalidate(calendarBookingsProvider);

        // Clear selection and show success
        ref.read(multiSelectProvider.notifier).disableMultiSelect();

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Obrisano ${selectedBookings.length} ${selectedBookings.length == 1 ? 'rezervacija' : 'rezervacije'}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri brisanju rezervacija',
        );
      }
    }
  }

  String _getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Na čekanju';
      case BookingStatus.confirmed:
        return 'Potvrđeno';
      case BookingStatus.completed:
        return 'Završeno';
      case BookingStatus.cancelled:
        return 'Otkazano';
    }
  }
}
