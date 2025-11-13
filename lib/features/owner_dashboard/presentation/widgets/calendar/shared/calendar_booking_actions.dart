import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/constants/enums.dart';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši rezervaciju'),
        content: Text(
          'Jeste li sigurni da želite obrisati rezervaciju za ${booking.guestName ?? 'N/A'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Show loading indicator
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Brisanje rezervacije...'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervacija obrisana'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

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
  }

  /// Change booking status
  static Future<void> changeBookingStatus(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
    BookingStatus newStatus,
  ) async {
    // Show loading indicator
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
                  Text('Promjena statusa u ${newStatus.displayName}...'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status promijenjen u ${newStatus.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

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

  /// Send email to guest
  static void sendEmailToGuest(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
  ) {
    showSendEmailDialog(context, ref, booking);
  }
}
