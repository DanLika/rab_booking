import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../core/utils/responsive_dialog_utils.dart';
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

    // Responsive sizing using utility
    final dialogWidth = ResponsiveDialogUtils.getDialogWidth(context);
    final contentPadding = ResponsiveDialogUtils.getContentPadding(context);
    final headerPadding = ResponsiveDialogUtils.getHeaderPadding(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
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
              padding: EdgeInsets.all(headerPadding),
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
                padding: EdgeInsets.all(contentPadding),
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

                    _ThemedDivider(),

                    // Guest Information
                    _SectionHeader(icon: Icons.person_outline, title: l10n.ownerDetailsGuestInfo),
                    const SizedBox(height: 12),
                    _DetailRow(label: l10n.ownerDetailsName, value: ownerBooking.guestName),
                    _DetailRow(label: l10n.ownerDetailsEmail, value: ownerBooking.guestEmail),
                    if (ownerBooking.guestPhone != null)
                      _DetailRow(label: l10n.ownerDetailsPhone, value: ownerBooking.guestPhone!),

                    _ThemedDivider(),

                    // Property Information
                    _SectionHeader(icon: Icons.home_outlined, title: l10n.ownerDetailsPropertyInfo),
                    const SizedBox(height: 12),
                    _DetailRow(label: l10n.ownerDetailsProperty, value: property.name),
                    _DetailRow(label: l10n.ownerDetailsUnit, value: unit.name),
                    _DetailRow(label: l10n.ownerDetailsLocation, value: property.location),

                    _ThemedDivider(),

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

                    _ThemedDivider(),

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
                      _ThemedDivider(),
                      _SectionHeader(icon: Icons.note_outlined, title: l10n.ownerDetailsNotes),
                      const SizedBox(height: 12),
                      Text(booking.notes!, style: TextStyle(color: theme.colorScheme.onSurface)),
                    ],

                    if (booking.status == BookingStatus.cancelled) ...[
                      _ThemedDivider(),
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

                    _ThemedDivider(),

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

            // Actions - responsive layout
            Container(
              padding: EdgeInsets.symmetric(horizontal: contentPadding, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.dialogFooterDark : AppColors.dialogFooterLight,
                border: Border(
                  top: BorderSide(color: isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary actions row - wrap to prevent overflow
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (booking.status != BookingStatus.cancelled)
                        _ActionButton(
                          icon: Icons.edit_outlined,
                          label: l10n.ownerDetailsEdit,
                          onPressed: () {
                            Navigator.of(context).pop();
                            showEditBookingDialog(context, ref, booking);
                          },
                        ),
                      _ActionButton(
                        icon: Icons.email_outlined,
                        label: l10n.ownerDetailsEmail,
                        onPressed: () => showSendEmailDialog(context, ref, booking),
                      ),
                      if (booking.status != BookingStatus.cancelled)
                        _ActionButton(
                          icon: Icons.replay_outlined,
                          label: l10n.ownerDetailsResend,
                          onPressed: () => _resendConfirmationEmail(context, ref, l10n),
                        ),
                    ],
                  ),
                  // Divider between action groups
                  if (booking.status == BookingStatus.confirmed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        height: 1,
                        color: isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight,
                      ),
                    ),
                  // Secondary actions row (Cancel + Close)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (booking.status == BookingStatus.confirmed)
                        Flexible(
                          child: _ActionButton(
                            icon: Icons.cancel_outlined,
                            label: l10n.ownerDetailsCancel,
                            onPressed: () => _confirmCancellation(context, ref, l10n),
                            isDestructive: true,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Flexible(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: AutoSizeText(
                            l10n.ownerDetailsClose,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            minFontSize: 10,
                          ),
                        ),
                      ),
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.ownerDetailsCancelConfirmMessage, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Builder(
                builder: (ctx) => TextField(
                  controller: reasonController,
                  decoration: InputDecorationHelper.buildDecoration(
                    labelText: l10n.ownerDetailsCancellationReason,
                    hintText: l10n.ownerDetailsCancellationHint,
                    context: ctx,
                  ),
                  maxLines: 3,
                ),
              ),
            ],
          ),
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
      builder: (dialogContext) {
        final dialogTheme = Theme.of(dialogContext);
        final dialogIsDark = dialogTheme.brightness == Brightness.dark;
        final dialogL10n = AppLocalizations.of(dialogContext);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: dialogContext.gradients.sectionBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dialogContext.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
              boxShadow: dialogIsDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: dialogContext.gradients.brandPrimary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).toInt()),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.email, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dialogL10n.ownerDetailsResendTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dialogL10n.ownerDetailsResendMessage(ownerBooking.guestName),
                        style: dialogTheme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),

                      // Email info card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dialogTheme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: dialogTheme.colorScheme.primary.withAlpha((0.3 * 255).toInt())),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.email_outlined, size: 20, color: dialogTheme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dialogL10n.ownerDetailsEmail,
                                    style: TextStyle(fontSize: 12, color: dialogTheme.colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ownerBooking.guestEmail,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: dialogTheme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dialogTheme.colorScheme.tertiaryContainer.withAlpha((0.5 * 255).toInt()),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: dialogTheme.colorScheme.tertiary.withAlpha((0.3 * 255).toInt())),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 20, color: dialogTheme.colorScheme.tertiary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                dialogL10n.ownerDetailsResendNote,
                                style: TextStyle(fontSize: 13, color: dialogTheme.colorScheme.onSurface),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer with actions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: dialogIsDark ? AppColors.dialogFooterDark : AppColors.dialogFooterLight,
                    border: Border(
                      top: BorderSide(
                        color: dialogIsDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight,
                      ),
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                        child: Text(dialogL10n.ownerMultiSelectCancel),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: dialogContext.gradients.brandPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.send, size: 18),
                          label: Text(dialogL10n.ownerDetailsSend),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

/// Themed divider that uses consistent colors from design system
class _ThemedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 24,
      thickness: 1,
      color: isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight,
    );
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
          // More responsive label width based on available space
          final isVeryNarrow = constraints.maxWidth < 320;
          final isNarrow = constraints.maxWidth < 400;
          final labelWidth = isVeryNarrow ? 70.0 : (isNarrow ? 85.0 : 120.0);
          final fontSize = isVeryNarrow ? 12.0 : 14.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: AutoSizeText(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: context.textColorSecondary, fontSize: fontSize),
                  maxLines: 1,
                  minFontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: valueColor, fontSize: fontSize),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Action button with AutoSizeText to prevent text breaking
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onPressed, this.isDestructive = false});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error.withAlpha((0.8 * 255).toInt()) : null;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: AutoSizeText(
              label,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              minFontSize: 9,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
