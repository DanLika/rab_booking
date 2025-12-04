import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../providers/owner_bookings_provider.dart';
import 'edit_booking_dialog.dart';
import 'send_email_dialog.dart';

/// Booking details dialog - displays comprehensive booking information with actions
class BookingDetailsDialog extends ConsumerWidget {
  const BookingDetailsDialog({super.key, required this.ownerBooking});

  final OwnerBooking ownerBooking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: GradientTokens.brandPrimary,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Detalji rezervacije'),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Booking ID and Status
              _DetailRow(
                label: 'ID rezervacije',
                value: booking.id,
              ),
              _DetailRow(
                label: 'Status',
                value: booking.status.displayName,
                valueColor: booking.status.color,
              ),

              const Divider(height: 24),

              // Guest Information
              const _SectionHeader(
                icon: Icons.person_outline,
                title: 'Informacije o gostu',
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Ime', value: ownerBooking.guestName),
              _DetailRow(label: 'Email', value: ownerBooking.guestEmail),
              if (ownerBooking.guestPhone != null)
                _DetailRow(label: 'Telefon', value: ownerBooking.guestPhone!),

              const Divider(height: 24),

              // Property Information
              const _SectionHeader(
                icon: Icons.home_outlined,
                title: 'Informacije o objektu',
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Objekt', value: property.name),
              _DetailRow(label: 'Jedinica', value: unit.name),
              _DetailRow(label: 'Lokacija', value: property.location),

              const Divider(height: 24),

              // Booking Details
              const _SectionHeader(
                icon: Icons.calendar_today_outlined,
                title: 'Detalji boravka',
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Prijava',
                value: '${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}.',
              ),
              _DetailRow(
                label: 'Odjava',
                value: '${booking.checkOut.day}.${booking.checkOut.month}.${booking.checkOut.year}.',
              ),
              _DetailRow(
                label: 'Broj noći',
                value: '${booking.numberOfNights}',
              ),
              _DetailRow(
                label: 'Broj gostiju',
                value: '${booking.guestCount}',
              ),

              const Divider(height: 24),

              // Payment Information
              const _SectionHeader(
                icon: Icons.payment_outlined,
                title: 'Informacije o plaćanju',
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Ukupna cijena',
                value: booking.formattedTotalPrice,
                valueColor: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).primaryColor,
              ),
              _DetailRow(
                label: 'Plaćeno',
                value: booking.formattedPaidAmount,
              ),
              _DetailRow(
                label: 'Preostalo',
                value: booking.formattedRemainingBalance,
                valueColor: booking.isFullyPaid ? AppColors.success : AppColors.warning,
              ),
              if (booking.paymentIntentId != null)
                _DetailRow(
                  label: 'Payment Intent ID',
                  value: booking.paymentIntentId!,
                ),

              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const Divider(height: 24),
                const _SectionHeader(
                  icon: Icons.note_outlined,
                  title: 'Napomene',
                ),
                const SizedBox(height: 12),
                Text(booking.notes!),
              ],

              if (booking.status == BookingStatus.cancelled) ...[
                const Divider(height: 24),
                const _SectionHeader(
                  icon: Icons.cancel_outlined,
                  title: 'Informacije o otkazivanju',
                ),
                const SizedBox(height: 12),
                if (booking.cancelledAt != null)
                  _DetailRow(
                    label: 'Otkazano',
                    value:
                        '${booking.cancelledAt!.day}.${booking.cancelledAt!.month}.${booking.cancelledAt!.year}.',
                  ),
                if (booking.cancellationReason != null)
                  _DetailRow(
                    label: 'Razlog',
                    value: booking.cancellationReason!,
                  ),
              ],

              const Divider(height: 24),

              // Timestamps
              _DetailRow(
                label: 'Kreirano',
                value:
                    '${booking.createdAt.day}.${booking.createdAt.month}.${booking.createdAt.year}. ${booking.createdAt.hour}:${booking.createdAt.minute.toString().padLeft(2, '0')}',
              ),
              if (booking.updatedAt != null)
                _DetailRow(
                  label: 'Ažurirano',
                  value:
                      '${booking.updatedAt!.day}.${booking.updatedAt!.month}.${booking.updatedAt!.year}. ${booking.updatedAt!.hour}:${booking.updatedAt!.minute.toString().padLeft(2, '0')}',
                ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        // Left side - Edit, Email, and Resend
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (booking.status != BookingStatus.cancelled)
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  showEditBookingDialog(context, ref, booking);
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Uredi'),
              ),
            TextButton.icon(
              onPressed: () {
                showSendEmailDialog(context, ref, booking);
              },
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text('Email'),
            ),
            if (booking.status != BookingStatus.cancelled)
              TextButton.icon(
                onPressed: () => _resendConfirmationEmail(context, ref),
                icon: const Icon(Icons.replay_outlined, size: 18),
                label: const Text('Ponovo pošalji'),
              ),
          ],
        ),

        // Right side - Cancel and Close
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (booking.status == BookingStatus.pending ||
                booking.status == BookingStatus.confirmed)
              TextButton.icon(
                onPressed: () => _confirmCancellation(context, ref),
                icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                label: const Text('Otkaži', style: TextStyle(color: AppColors.error)),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zatvori'),
            ),
          ],
        ),
      ],
    );
  }

  /// Show cancellation confirmation dialog
  Future<void> _confirmCancellation(BuildContext context, WidgetRef ref) async {
    final TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda otkazivanja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jeste li sigurni da želite otkazati ovu rezervaciju?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Razlog otkazivanja (opciono)',
                border: OutlineInputBorder(),
                hintText: 'Npr. Greška u datumu, Zahtjev gosta...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Otkaži rezervaciju'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _cancelBooking(context, ref, reasonController.text.trim());
    }
  }

  /// Cancel the booking
  Future<void> _cancelBooking(
    BuildContext context,
    WidgetRef ref,
    String? reason,
  ) async {
    try {
      // FIXED: Show loading snackbar instead of dialog
      if (context.mounted) {
        ErrorDisplayUtils.showLoadingSnackBar(
          context,
          'Otkaz rezervacije u tijeku...',
        );
      }

      // Cancel booking via repository
      final repository = ref.read(ownerBookingsRepositoryProvider);
      await repository.cancelBooking(
        ownerBooking.booking.id,
        reason ?? '', // reason is required positional parameter
      );

      // Close details dialog and show success
      if (context.mounted) {
        Navigator.of(context).pop(); // Close details dialog

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Rezervacija uspješno otkazana',
        );

        // Invalidate providers to refresh the list
        ref.invalidate(allOwnerBookingsProvider);
        ref.invalidate(ownerBookingsProvider);

        // Auto-regenerate iCal if enabled
        _triggerIcalRegeneration(ref);
      }
    } catch (e) {
      // FIXED: Use ErrorDisplayUtils for user-friendly error messages
      if (context.mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška prilikom otkazivanja rezervacije',
        );
      }
    }
  }

  /// Trigger iCal regeneration for the unit after booking status changes
  void _triggerIcalRegeneration(WidgetRef ref) async {
    try {
      // Get iCal export service
      final icalService = ref.read(icalExportServiceProvider);

      // Auto-regenerate if enabled (service will check if enabled)
      await icalService.autoRegenerateIfEnabled(
        propertyId: ownerBooking.property.id,
        unitId: ownerBooking.unit.id,
        unit: ownerBooking.unit,
      );
    } catch (e) {
      // Silently fail - iCal regeneration is non-critical
    }
  }

  /// Resend the original booking confirmation email with View My Booking link
  Future<void> _resendConfirmationEmail(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ponovo pošalji email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Želite li ponovo poslati email potvrde rezervacije gostu ${ownerBooking.guestName}?',
            ),
            const SizedBox(height: 12),
            Text(
              'Email: ${ownerBooking.guestEmail}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Email će sadržavati link "View My Booking" za pregled rezervacije.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Pošalji'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Show loading
      ErrorDisplayUtils.showLoadingSnackBar(
        context,
        'Slanje emaila...',
      );

      // Call Cloud Function
      final functions = ref.read(firebaseFunctionsProvider);
      final callable = functions.httpsCallable('resendBookingEmail');

      await callable.call({
        'bookingId': ownerBooking.booking.id,
      });

      if (context.mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Email uspješno poslan na ${ownerBooking.guestEmail}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri slanju emaila',
        );
      }
    }
  }
}

/// Section header widget with icon and gradient accent
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            gradient: GradientTokens.brandPrimary,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

/// Detail row widget
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 400;
          final labelWidth = isMobile ? 100.0 : 140.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.textColorSecondary,
                      ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: valueColor,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
