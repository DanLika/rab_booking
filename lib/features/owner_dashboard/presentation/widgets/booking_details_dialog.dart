import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          gradient: context.gradients.sectionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.ownerDetailsTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Booking ID and Status
                    _DetailRow(label: l10n.ownerDetailsBookingId, value: booking.id),
                    _DetailRow(
                      label: l10n.ownerDetailsStatus,
                      value: booking.status.displayName,
                      valueColor: booking.status.color,
                    ),

                    const Divider(height: 24),

                    // Guest Information
                    _SectionHeader(icon: Icons.person_outline, title: l10n.ownerDetailsGuestInfo),
                    const SizedBox(height: 12),
                    _DetailRow(label: l10n.ownerDetailsName, value: ownerBooking.guestName),
                    _DetailRow(label: l10n.ownerDetailsEmail, value: ownerBooking.guestEmail),
                    if (ownerBooking.guestPhone != null)
                      _DetailRow(label: l10n.ownerDetailsPhone, value: ownerBooking.guestPhone!),

                    const Divider(height: 24),

                    // Property Information
                    _SectionHeader(icon: Icons.home_outlined, title: l10n.ownerDetailsPropertyInfo),
                    const SizedBox(height: 12),
                    _DetailRow(label: l10n.ownerDetailsProperty, value: property.name),
                    _DetailRow(label: l10n.ownerDetailsUnit, value: unit.name),
                    _DetailRow(label: l10n.ownerDetailsLocation, value: property.location),

                    const Divider(height: 24),

                    // Booking Details
                    _SectionHeader(icon: Icons.calendar_today_outlined, title: l10n.ownerDetailsStayInfo),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: l10n.ownerDetailsCheckIn,
                      value: '${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}.',
                    ),
                    _DetailRow(
                      label: l10n.ownerDetailsCheckOut,
                      value: '${booking.checkOut.day}.${booking.checkOut.month}.${booking.checkOut.year}.',
                    ),
                    _DetailRow(label: l10n.ownerDetailsNights, value: '${booking.numberOfNights}'),
                    _DetailRow(label: l10n.ownerDetailsGuests, value: '${booking.guestCount}'),

                    const Divider(height: 24),

                    // Payment Information
                    _SectionHeader(icon: Icons.payment_outlined, title: l10n.ownerDetailsPaymentInfo),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: l10n.ownerDetailsTotalPrice,
                      value: booking.formattedTotalPrice,
                      valueColor: theme.colorScheme.primary,
                    ),
                    _DetailRow(label: l10n.ownerDetailsPaid, value: booking.formattedPaidAmount),
                    _DetailRow(
                      label: l10n.ownerDetailsRemaining,
                      value: booking.formattedRemainingBalance,
                      valueColor: booking.isFullyPaid ? theme.colorScheme.primary : theme.colorScheme.error,
                    ),
                    if (booking.paymentIntentId != null)
                      _DetailRow(label: 'Payment Intent ID', value: booking.paymentIntentId!),

                    if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _SectionHeader(icon: Icons.note_outlined, title: l10n.ownerDetailsNotes),
                      const SizedBox(height: 12),
                      Text(booking.notes!, style: TextStyle(color: theme.colorScheme.onSurface)),
                    ],

                    if (booking.status == BookingStatus.cancelled) ...[
                      const Divider(height: 24),
                      _SectionHeader(icon: Icons.cancel_outlined, title: l10n.ownerDetailsCancellationInfo),
                      const SizedBox(height: 12),
                      if (booking.cancelledAt != null)
                        _DetailRow(
                          label: l10n.ownerDetailsCancelledOn,
                          value:
                              '${booking.cancelledAt!.day}.${booking.cancelledAt!.month}.${booking.cancelledAt!.year}.',
                        ),
                      if (booking.cancellationReason != null)
                        _DetailRow(label: l10n.ownerDetailsReason, value: booking.cancellationReason!),
                    ],

                    const Divider(height: 24),

                    // Timestamps
                    _DetailRow(
                      label: l10n.ownerDetailsCreated,
                      value:
                          '${booking.createdAt.day}.${booking.createdAt.month}.${booking.createdAt.year}. ${booking.createdAt.hour}:${booking.createdAt.minute.toString().padLeft(2, '0')}',
                    ),
                    if (booking.updatedAt != null)
                      _DetailRow(
                        label: l10n.ownerDetailsUpdated,
                        value:
                            '${booking.updatedAt!.day}.${booking.updatedAt!.month}.${booking.updatedAt!.year}. ${booking.updatedAt!.hour}:${booking.updatedAt!.minute.toString().padLeft(2, '0')}',
                      ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt()))),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Left side - Edit, Email, and Resend
                  Wrap(
                    children: [
                      if (booking.status != BookingStatus.cancelled)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            showEditBookingDialog(context, ref, booking);
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(l10n.ownerDetailsEdit),
                        ),
                      TextButton.icon(
                        onPressed: () {
                          showSendEmailDialog(context, ref, booking);
                        },
                        icon: const Icon(Icons.email_outlined, size: 18),
                        label: Text(l10n.ownerDetailsEmail),
                      ),
                      if (booking.status != BookingStatus.cancelled)
                        TextButton.icon(
                          onPressed: () => _resendConfirmationEmail(context, ref, l10n),
                          icon: const Icon(Icons.replay_outlined, size: 18),
                          label: Text(l10n.ownerDetailsResend),
                        ),
                    ],
                  ),

                  // Right side - Cancel and Close
                  Wrap(
                    children: [
                      if (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed)
                        TextButton.icon(
                          onPressed: () => _confirmCancellation(context, ref, l10n),
                          icon: Icon(Icons.cancel_outlined, color: theme.colorScheme.error, size: 18),
                          label: Text(l10n.ownerDetailsCancel, style: TextStyle(color: theme.colorScheme.error)),
                        ),
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.ownerDetailsClose)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show cancellation confirmation dialog
  Future<void> _confirmCancellation(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final TextEditingController reasonController = TextEditingController();
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ownerDetailsCancelConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.ownerDetailsCancelConfirmMessage, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.ownerDetailsCancellationReason,
                border: const OutlineInputBorder(),
                hintText: l10n.ownerDetailsCancellationHint,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.ownerMultiSelectCancel)),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error),
            child: Text(l10n.ownerDetailsCancelBooking),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _cancelBooking(context, ref, reasonController.text.trim(), l10n);
    }
  }

  /// Cancel the booking
  Future<void> _cancelBooking(BuildContext context, WidgetRef ref, String? reason, AppLocalizations l10n) async {
    try {
      // FIXED: Show loading snackbar instead of dialog
      if (context.mounted) {
        ErrorDisplayUtils.showLoadingSnackBar(context, l10n.ownerDetailsCancelling);
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

        ErrorDisplayUtils.showSuccessSnackBar(context, l10n.ownerDetailsCancelSuccess);

        // Invalidate providers to refresh the list
        ref.invalidate(allOwnerBookingsProvider);
        ref.invalidate(ownerBookingsProvider);

        // Auto-regenerate iCal if enabled
        _triggerIcalRegeneration(ref);
      }
    } catch (e) {
      // FIXED: Use ErrorDisplayUtils for user-friendly error messages
      if (context.mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.ownerDetailsCancelError);
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
  Future<void> _resendConfirmationEmail(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ownerDetailsResendTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.ownerDetailsResendMessage(ownerBooking.guestName)),
            const SizedBox(height: 12),
            Text(
              '${l10n.ownerDetailsEmail}: ${ownerBooking.guestEmail}',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w500),
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
                  Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.ownerDetailsResendNote, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.ownerMultiSelectCancel)),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.send, size: 18),
            label: Text(l10n.ownerDetailsSend),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Show loading
      ErrorDisplayUtils.showLoadingSnackBar(context, l10n.ownerDetailsSending);

      // Call Cloud Function
      final functions = ref.read(firebaseFunctionsProvider);
      final callable = functions.httpsCallable('resendBookingEmail');

      await callable.call({'bookingId': ownerBooking.booking.id});

      if (context.mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(context, l10n.ownerDetailsSendSuccess(ownerBooking.guestEmail));
      }
    } catch (e) {
      if (context.mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.ownerDetailsSendError);
      }
    }
  }
}

/// Section header widget with icon and gradient accent
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: context.gradients.brandPrimary,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// Detail row widget
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textColorSecondary),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: valueColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
