import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/accessibility/accessibility_helpers.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/constants/booking_status_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/message_box.dart';
import '../../../../shared/widgets/platform_icon.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../shared/providers/repository_providers.dart';
import 'edit_booking_dialog.dart';
import 'send_email_dialog.dart';

/// Booking details dialog V2 - Redesigned with better spacing and typography
/// Changes from V1:
/// - Tighter spacing (30% reduction)
/// - Larger fonts for better hierarchy (18px header, 16px sections, 15px values)
/// - Better visual distinction between labels and values
/// - More compact footer
class BookingDetailsDialogV2 extends ConsumerWidget {
  const BookingDetailsDialogV2({super.key, required this.ownerBooking});

  final OwnerBooking ownerBooking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;

    // Responsive sizing - slightly narrower max width for tighter feel
    final dialogWidth = ResponsiveDialogUtils.getDialogWidth(
      context,
      maxWidth: 480,
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Constrain height for small screens
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight =
        screenHeight *
        ResponsiveSpacingHelper.getDialogMaxHeightPercent(context);

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
          border: Border.all(
            color: context.gradients.sectionBorder.withValues(alpha: 0.5),
          ),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header - 18px title for prominence
            _buildHeader(context, l10n),

            // Content with tighter padding
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Booking Info Section
                    _SectionHeaderV2(
                      icon: Icons.confirmation_number_outlined,
                      title: l10n.ownerDetailsBookingInfo,
                      isFirst: true,
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsBookingId,
                      value: booking.bookingReference ?? booking.id,
                    ),
                    _DetailRowWithWidgetV2(
                      label: l10n.ownerDetailsStatus,
                      child: _StatusBadgeV2(status: booking.status),
                    ),

                    // Guest Information
                    _SectionHeaderV2(
                      icon: Icons.person_outline,
                      title: l10n.ownerDetailsGuestInfo,
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsName,
                      value: ownerBooking.guestName,
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsEmail,
                      value: ownerBooking.guestEmail,
                    ),
                    if (ownerBooking.guestPhone != null)
                      _DetailRowV2(
                        label: l10n.ownerDetailsPhone,
                        value: ownerBooking.guestPhone!,
                      ),

                    // Booking source (for external platforms)
                    if (booking.isExternalBooking)
                      _DetailRowWithWidgetV2(
                        label: l10n.ownerDetailsSource,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PlatformIcon(
                              source: booking.source,
                              size: 17,
                              showTooltip: false,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              booking.sourceDisplayName,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Property Information
                    _SectionHeaderV2(
                      icon: Icons.home_outlined,
                      title: l10n.ownerDetailsPropertyInfo,
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsProperty,
                      value: property.name,
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsUnit,
                      value: unit.name,
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsLocation,
                      value: property.location,
                    ),

                    // Booking Details
                    _SectionHeaderV2(
                      icon: Icons.calendar_today_outlined,
                      title: l10n.ownerDetailsStayInfo,
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsCheckIn,
                      value: _formatDate(booking.checkIn),
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsCheckOut,
                      value: _formatDate(booking.checkOut),
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsNights,
                      value: '${booking.numberOfNights}',
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsGuests,
                      value: '${booking.guestCount}',
                    ),

                    // Payment Information
                    _SectionHeaderV2(
                      icon: Icons.payment_outlined,
                      title: l10n.ownerDetailsPaymentInfo,
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsTotalPrice,
                      value: booking.formattedTotalPrice,
                      valueColor: theme.colorScheme.primary,
                      isHighlighted: true,
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsPaid,
                      value: booking.formattedPaidAmount,
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsRemaining,
                      value: booking.formattedRemainingBalance,
                      valueColor: booking.isFullyPaid
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                    _DetailRowV2(
                      label: l10n.ownerDetailsPaymentMethod,
                      value: _getPaymentMethodDisplay(
                        booking.paymentMethod,
                        l10n,
                      ),
                    ),
                    if (booking.paymentOption != null)
                      _DetailRowV2(
                        label: l10n.ownerDetailsPaymentOption,
                        value: _getPaymentOptionDisplay(
                          booking.paymentOption!,
                          l10n,
                        ),
                      ),

                    // Notes section
                    if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                      _SectionHeaderV2(
                        icon: Icons.note_outlined,
                        title: l10n.ownerDetailsNotes,
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          booking.notes!,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],

                    // Cancellation info
                    if (booking.status == BookingStatus.cancelled) ...[
                      _SectionHeaderV2(
                        icon: Icons.cancel_outlined,
                        title: l10n.ownerDetailsCancellationInfo,
                      ),
                      if (booking.cancelledAt != null)
                        _DetailRowV2(
                          label: l10n.ownerDetailsCancelledOn,
                          value: _formatDate(booking.cancelledAt!),
                        ),
                      if (booking.cancellationReason != null)
                        _DetailRowV2(
                          label: l10n.ownerDetailsReason,
                          value: booking.cancellationReason!,
                        ),
                    ],

                    // Small bottom spacing
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            // Footer with action buttons
            _buildFooter(context, ref, l10n, booking, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: context.gradients.brandPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.ownerDetailsTitle,
              style: const TextStyle(
                fontSize: 18, // Increased from 16px
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    dynamic booking,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.dialogFooterDark
            : AppColors.dialogFooterLight,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.sectionDividerDark
                : AppColors.sectionDividerLight,
          ),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
      ),
      child: Row(
        children: [
          if (booking.status != BookingStatus.cancelled) ...[
            Expanded(
              child: _ActionButtonV2(
                icon: Icons.edit_outlined,
                label: l10n.ownerDetailsEdit,
                onPressed: () {
                  Navigator.of(context).pop();
                  showEditBookingDialog(context, ref, booking);
                },
                gradient: context.gradients.brandPrimary,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: _ActionButtonV2(
              icon: Icons.email_outlined,
              label: l10n.ownerDetailsEmail,
              onPressed: () {
                Navigator.of(context).pop();
                showSendEmailDialog(context, ref, booking);
              },
              gradient: context.gradients.brandPrimary,
            ),
          ),
          if (booking.status != BookingStatus.cancelled) ...[
            const SizedBox(width: 6),
            Expanded(
              child: _ActionButtonV2(
                icon: Icons.replay_outlined,
                label: l10n.ownerDetailsResend,
                onPressed: () => _resendConfirmationEmail(context, ref, l10n),
                gradient: context.gradients.brandPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}.';
  }

  String _getPaymentMethodDisplay(
    String? paymentMethod,
    AppLocalizations l10n,
  ) {
    switch (paymentMethod) {
      case 'stripe':
        return l10n.paymentMethodStripe;
      case 'bank_transfer':
        return l10n.paymentMethodBankTransfer;
      case 'cash':
        return l10n.paymentMethodCash;
      case 'other':
        return l10n.paymentMethodOther;
      default:
        return l10n.paymentMethodUnknown;
    }
  }

  String _getPaymentOptionDisplay(String paymentOption, AppLocalizations l10n) {
    switch (paymentOption) {
      case 'deposit':
        return l10n.paymentOptionDeposit;
      case 'full_payment':
        return l10n.paymentOptionFullPayment;
      default:
        return paymentOption;
    }
  }

  Future<void> _resendConfirmationEmail(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          _ResendEmailDialog(ownerBooking: ownerBooking),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      ErrorDisplayUtils.showLoadingSnackBar(context, l10n.ownerDetailsSending);

      final functions = ref.read(firebaseFunctionsProvider);
      final callable = functions.httpsCallable('resendBookingEmail');

      await callable
          .call({'bookingId': ownerBooking.booking.id})
          .withCloudFunctionTimeout('resendBookingEmail');

      if (context.mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          l10n.ownerDetailsSendSuccess(ownerBooking.guestEmail),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.ownerDetailsSendError,
        );
      }
    }
  }
}

/// Section header - compact divider style
class _SectionHeaderV2 extends StatelessWidget {
  const _SectionHeaderV2({
    required this.icon,
    required this.title,
    this.isFirst = false,
  });

  final IconData icon;
  final String title;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 14, bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: primaryColor, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail row - ULTRA COMPACT with inline label:value format
class _DetailRowV2 extends StatelessWidget {
  const _DetailRowV2({
    required this.label,
    required this.value,
    this.valueColor,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: context.textColorSecondary, fontSize: 15),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                color: valueColor ?? theme.colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail row with widget - ULTRA COMPACT inline format
class _DetailRowWithWidgetV2 extends StatelessWidget {
  const _DetailRowWithWidgetV2({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: context.textColorSecondary, fontSize: 15),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Status badge - inline compact pill
class _StatusBadgeV2 extends StatelessWidget {
  const _StatusBadgeV2({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final statusColor = status.color;
    final statusText = status.displayNameLocalized(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Action button for footer - compact but readable
class _ActionButtonV2 extends StatelessWidget {
  const _ActionButtonV2({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withAlpha((0.25 * 255).toInt()),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: Colors.white),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Resend email confirmation dialog - compact version
class _ResendEmailDialog extends StatelessWidget {
  const _ResendEmailDialog({required this.ownerBooking});

  final OwnerBooking ownerBooking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight =
        screenHeight *
        ResponsiveSpacingHelper.getDialogMaxHeightPercent(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(maxWidth: 380, maxHeight: maxHeight),
        decoration: BoxDecoration(
          gradient: context.gradients.sectionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.gradients.sectionBorder.withValues(alpha: 0.5),
          ),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.email,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.ownerDetailsResendTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  AccessibleIconButton(
                    icon: Icons.close,
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).pop(false),
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ownerDetailsResendMessage(ownerBooking.guestName),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),

                    // Email info card
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ownerBooking.guestEmail,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    MessageBox.warning(message: l10n.ownerDetailsResendNote),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.dialogFooterDark
                    : AppColors.dialogFooterLight,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.sectionDividerDark
                        : AppColors.sectionDividerLight,
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(11),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: context.gradients.brandPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.send, size: 18),
                    label: Text(l10n.ownerDetailsSend),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
