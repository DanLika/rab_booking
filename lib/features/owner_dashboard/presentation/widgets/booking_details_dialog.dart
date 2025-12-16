import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/accessibility/accessibility_helpers.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/message_box.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../shared/providers/repository_providers.dart';
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

    // Responsive sizing using utility (maxWidth: 500 to match other dialogs like BookingCreateDialog)
    final dialogWidth = ResponsiveDialogUtils.getDialogWidth(context, maxWidth: 500);
    final contentPadding = ResponsiveDialogUtils.getContentPadding(context);
    final headerPadding = ResponsiveDialogUtils.getHeaderPadding(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Constrain height for small screens to prevent overflow
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * ResponsiveSpacingHelper.getDialogMaxHeightPercent(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          gradient: context.gradients.sectionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.gradients.sectionBorder.withValues(alpha: 0.5)),
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.ownerDetailsTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  AccessibleIconButton(
                    icon: Icons.close,
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                    semanticLabel: l10n.close,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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

            // Actions - modern layout (Close button moved to header)
            // Use Wrap on small screens to prevent overflow
            Container(
              padding: EdgeInsets.symmetric(horizontal: contentPadding, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.dialogFooterDark : AppColors.dialogFooterLight,
                border: Border(
                  top: BorderSide(color: isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 400;
                  
                  if (isNarrow) {
                    // Stack buttons vertically on narrow screens
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (booking.status != BookingStatus.cancelled) ...[
                          SizedBox(
                            width: double.infinity,
                            child: _ModernActionButton(
                              icon: Icons.edit_outlined,
                              label: l10n.ownerDetailsEdit,
                              onPressed: () {
                                Navigator.of(context).pop();
                                showEditBookingDialog(context, ref, booking);
                              },
                              gradient: context.gradients.brandPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: _ModernActionButton(
                            icon: Icons.email_outlined,
                            label: l10n.ownerDetailsEmail,
                            onPressed: () {
                              // FIXED BUG #6: Close parent dialog before opening send email dialog
                              Navigator.of(context).pop();
                              showSendEmailDialog(context, ref, booking);
                            },
                            gradient: context.gradients.brandPrimary,
                          ),
                        ),
                        if (booking.status != BookingStatus.cancelled) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: _ModernActionButton(
                              icon: Icons.replay_outlined,
                              label: l10n.ownerDetailsResend,
                              onPressed: () => _resendConfirmationEmail(context, ref, l10n),
                              gradient: context.gradients.brandPrimary,
                            ),
                          ),
                        ],
                      ],
                    );
                  } else {
                    // Use Row on wider screens
                    return Row(
                      children: [
                        if (booking.status != BookingStatus.cancelled) ...[
                          Expanded(
                            child: _ModernActionButton(
                              icon: Icons.edit_outlined,
                              label: l10n.ownerDetailsEdit,
                              onPressed: () {
                                Navigator.of(context).pop();
                                showEditBookingDialog(context, ref, booking);
                              },
                              gradient: context.gradients.brandPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: _ModernActionButton(
                            icon: Icons.email_outlined,
                            label: l10n.ownerDetailsEmail,
                            onPressed: () {
                              // FIXED BUG #6 (wide screen): Close parent dialog before opening send email dialog
                              Navigator.of(context).pop();
                              showSendEmailDialog(context, ref, booking);
                            },
                            gradient: context.gradients.brandPrimary,
                          ),
                        ),
                        if (booking.status != BookingStatus.cancelled) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ModernActionButton(
                              icon: Icons.replay_outlined,
                              label: l10n.ownerDetailsResend,
                              onPressed: () => _resendConfirmationEmail(context, ref, l10n),
                              gradient: context.gradients.brandPrimary,
                            ),
                          ),
                        ],
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
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

        // Constrain height for small screens (landscape phones)
        final dialogScreenHeight = MediaQuery.of(dialogContext).size.height;
        final dialogMaxHeight = dialogScreenHeight * ResponsiveSpacingHelper.getDialogMaxHeightPercent(dialogContext);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: BoxConstraints(maxWidth: 400, maxHeight: dialogMaxHeight),
            decoration: BoxDecoration(
              gradient: dialogContext.gradients.sectionBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dialogContext.gradients.sectionBorder.withValues(alpha: 0.5)),
              boxShadow: dialogIsDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient (includes close button)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: dialogContext.gradients.brandPrimary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.email, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dialogL10n.ownerDetailsResendTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      AccessibleIconButton(
                        icon: Icons.close,
                        color: Colors.white,
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        semanticLabel: dialogL10n.close,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Content (scrollable for small screens)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dialogL10n.ownerDetailsResendMessage(ownerBooking.guestName),
                          style: dialogTheme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),

                        // Email info card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: dialogTheme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: dialogTheme.colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.email_outlined, size: 18, color: dialogTheme.colorScheme.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dialogL10n.ownerDetailsEmail,
                                      style: TextStyle(fontSize: 11, color: dialogTheme.colorScheme.onSurfaceVariant),
                                    ),
                                    Text(
                                      ownerBooking.guestEmail,
                                      style: TextStyle(
                                        fontSize: 13,
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

                        const SizedBox(height: 12),

                        // Info note - Standardized warning message
                        MessageBox.warning(
                          message: dialogL10n.ownerDetailsResendNote,
                          padding: const EdgeInsets.all(10),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer with send button only (close moved to header)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: dialogIsDark ? AppColors.dialogFooterDark : AppColors.dialogFooterLight,
                    border: Border(
                      top: BorderSide(
                        color: dialogIsDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight,
                      ),
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.send, size: 18),
                        label: Text(dialogL10n.ownerDetailsSend),
                      ),
                    ),
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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Modern action button with gradient background
class _ModernActionButton extends StatelessWidget {
  const _ModernActionButton({required this.icon, required this.label, required this.onPressed, required this.gradient});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha((0.3 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: AutoSizeText(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1,
                minFontSize: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
