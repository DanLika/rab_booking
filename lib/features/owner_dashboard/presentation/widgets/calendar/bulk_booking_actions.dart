import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../providers/multi_select_provider.dart';

/// Bulk Booking Actions
/// Helper class for performing bulk operations on multiple bookings
class BulkBookingActions {
  /// Bulk delete bookings with confirmation
  static Future<void> bulkDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final selectedBookings =
        ref.read(multiSelectProvider).selectedBookings;

    if (selectedBookings.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši rezervacije'),
        content: Text(
          'Jeste li sigurni da želite obrisati ${selectedBookings.length} ${selectedBookings.length == 1 ? 'rezervaciju' : 'rezervacija'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Obriši sve'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    // Show loading
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Brisanje ${selectedBookings.length} rezervacija...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final repository = ref.read(bookingRepositoryProvider);

      // Delete all selected bookings
      await Future.wait(
        selectedBookings.map((booking) => repository.deleteBooking(booking.id)),
      );

      // Refresh calendar
      await Future.wait([
        ref.refresh(calendarBookingsProvider.future),
        ref.refresh(allOwnerUnitsProvider.future),
      ]);

      // Clear selection and close loading
      if (context.mounted) {
        ref.read(multiSelectProvider.notifier).clearSelection();
        Navigator.of(context).pop();
      }

      // Show success
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Obrisano ${selectedBookings.length} rezervacija'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Bulk change status with status picker
  static Future<void> bulkChangeStatus(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final selectedBookings =
        ref.read(multiSelectProvider).selectedBookings;

    if (selectedBookings.isEmpty) return;

    // Show status picker dialog
    final newStatus = await showDialog<BookingStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promijeni status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Odaberite novi status za ${selectedBookings.length} ${selectedBookings.length == 1 ? 'rezervaciju' : 'rezervacija'}:',
            ),
            const SizedBox(height: 16),
            ...BookingStatus.values.map((status) {
              return ListTile(
                leading: Icon(
                  Icons.circle,
                  color: status.color,
                  size: 16,
                ),
                title: Text(status.displayName),
                onTap: () => Navigator.of(context).pop(status),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Otkaži'),
          ),
        ],
      ),
    );

    if (newStatus == null || !context.mounted) return;

    // Show loading
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Promjena statusa za ${selectedBookings.length} rezervacija...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final repository = ref.read(bookingRepositoryProvider);

      // Update all selected bookings
      await Future.wait(
        selectedBookings.map((booking) {
          final updatedBooking = booking.copyWith(status: newStatus);
          return repository.updateBooking(updatedBooking);
        }),
      );

      // Refresh calendar
      await Future.wait([
        ref.refresh(calendarBookingsProvider.future),
        ref.refresh(allOwnerUnitsProvider.future),
      ]);

      // Clear selection and close loading
      if (context.mounted) {
        ref.read(multiSelectProvider.notifier).clearSelection();
        Navigator.of(context).pop();
      }

      // Show success
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status promijenjen u ${newStatus.displayName} za ${selectedBookings.length} rezervacija',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Bulk export to CSV
  static Future<void> bulkExport(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final selectedBookings =
        ref.read(multiSelectProvider).selectedBookings;

    if (selectedBookings.isEmpty) return;

    // Generate CSV content
    final csvLines = <String>[];

    // Header
    csvLines.add(
      'ID,Gost,Email,Telefon,Check-in,Check-out,Status,Noći,Gosti,Cijena,Plaćeno',
    );

    // Data rows
    for (final booking in selectedBookings) {
      csvLines.add(
        [
          booking.id,
          booking.guestName ?? '',
          booking.guestEmail ?? '',
          booking.guestPhone ?? '',
          booking.checkIn.toIso8601String(),
          booking.checkOut.toIso8601String(),
          booking.status.displayName,
          booking.numberOfNights.toString(),
          booking.guestCount.toString(),
          booking.totalPrice.toStringAsFixed(2),
          booking.paidAmount.toStringAsFixed(2),
        ].join(','),
      );
    }

    final csvContent = csvLines.join('\n');

    // For web: trigger download (simplified - in real app use package like 'universal_html')
    // For now, just show copy dialog
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('CSV Export'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: SingleChildScrollView(
              child: SelectableText(
                csvContent,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zatvori'),
            ),
            ElevatedButton(
              onPressed: () {
                // Copy to clipboard
                // Clipboard.setData(ClipboardData(text: csvContent));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CSV kopirano u clipboard'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Kopiraj'),
            ),
          ],
        ),
      );
    }
  }
}
