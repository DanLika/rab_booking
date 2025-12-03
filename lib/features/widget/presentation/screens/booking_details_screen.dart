import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/theme_provider.dart';
import '../../domain/models/booking_details_model.dart';
import '../../domain/models/widget_settings.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../theme/responsive_helper.dart';
import '../../../../../shared/utils/ui/snackbar_helper.dart';
import '../widgets/details/booking_status_banner.dart';
import '../widgets/details/details_reference_card.dart';
import '../widgets/details/property_info_card.dart';
import '../widgets/details/booking_dates_card.dart';
import '../widgets/details/payment_info_card.dart';
import '../widgets/details/contact_owner_card.dart';
import '../widgets/details/cancellation_policy_card.dart';
import '../widgets/details/booking_notes_card.dart';

/// Booking Details Screen
/// Displays complete booking information for guest (accessed from email link)
///
/// This screen is separate from BookingConfirmationScreen which shows
/// immediately after booking is created. This screen is for guests
/// returning to view/manage their booking.
class BookingDetailsScreen extends ConsumerStatefulWidget {
  final BookingDetailsModel booking;
  final WidgetSettings? widgetSettings;

  const BookingDetailsScreen({
    super.key,
    required this.booking,
    this.widgetSettings,
  });

  @override
  ConsumerState<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  bool _isCancelling = false;

  /// Check if booking can be cancelled based on cancellation deadline
  bool _canCancelBooking() {
    // Only confirmed, approved, or pending bookings can be cancelled
    final status = widget.booking.status.toLowerCase();
    if (status != 'confirmed' && status != 'pending' && status != 'approved') {
      return false;
    }

    // If widget settings not available, allow cancellation (owner can decide)
    if (widget.widgetSettings == null) {
      return true;
    }

    // Check if guest cancellation is enabled
    if (!widget.widgetSettings!.allowGuestCancellation) {
      return false;
    }

    // Check cancellation deadline
    final deadlineHours =
        widget.widgetSettings!.cancellationDeadlineHours ?? 48;
    final checkInDate = DateTime.parse(widget.booking.checkIn);
    final now = DateTime.now();
    final hoursUntilCheckIn = checkInDate.difference(now).inHours;

    return hoursUntilCheckIn >= deadlineHours;
  }

  /// Get reason why booking cannot be cancelled (for tooltip)
  String? _getCancelDisabledReason() {
    final status = widget.booking.status.toLowerCase();
    if (status == 'cancelled') {
      return 'This booking is already cancelled';
    }
    if (status != 'confirmed' && status != 'pending' && status != 'approved') {
      return 'This booking cannot be cancelled';
    }

    if (widget.widgetSettings != null &&
        !widget.widgetSettings!.allowGuestCancellation) {
      return 'Guest cancellation is not enabled for this property';
    }

    final deadlineHours =
        widget.widgetSettings?.cancellationDeadlineHours ?? 48;
    final checkInDate = DateTime.parse(widget.booking.checkIn);
    final now = DateTime.now();
    final hoursUntilCheckIn = checkInDate.difference(now).inHours;

    if (hoursUntilCheckIn < deadlineHours) {
      return 'Cancellation deadline has passed ($deadlineHours hours before check-in)';
    }

    return null;
  }

  /// Handle booking cancellation
  Future<void> _handleCancelBooking() async {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _CancelConfirmationDialog(
        bookingReference: widget.booking.bookingReference,
        colors: colors,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      // Call Cloud Function to cancel booking
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('guestCancelBooking');

      final result = await callable.call({
        'booking_id': widget.booking.bookingId,
        'booking_reference': widget.booking.bookingReference,
        'guest_email': widget.booking.guestEmail,
      });

      if (mounted) {
        SnackBarHelper.showSuccess(
          context: context,
          message: result.data['message'] ??
              'Booking cancelled successfully. You will receive a confirmation email.',
          duration: const Duration(seconds: 5),
        );

        // Reload page to show updated status
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          // Just rebuild to show cancelled state
          setState(() => _isCancelling = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        SnackBarHelper.showError(
          context: context,
          message: 'Failed to cancel booking: ${e.toString()}',
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      // AppBar without back button (no navigation from email link)
      appBar: AppBar(
        title: Text(
          'My Booking',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.backgroundPrimary,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              padding: EdgeInsets.all(isDesktop ? 32 : (isTablet ? 24 : 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status banner - full width
                  BookingStatusBanner(
                    status: widget.booking.status,
                    colors: colors,
                  ),

                  const SizedBox(height: SpacingTokens.l),

                  // Booking reference - full width, prominent
                  DetailsReferenceCard(
                    bookingReference: widget.booking.bookingReference,
                    colors: colors,
                  ),

                  const SizedBox(height: SpacingTokens.l),

                  // Responsive grid: 2 columns on desktop, 1 on mobile
                  if (isDesktop || isTablet)
                    _buildDesktopLayout(colors)
                  else
                    _buildMobileLayout(colors),

                  const SizedBox(height: SpacingTokens.l),

                  // Action buttons - full width
                  _buildActionButtons(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Desktop/Tablet layout with 2 columns
  Widget _buildDesktopLayout(WidgetColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - Property & Dates
        Expanded(
          child: Column(
            children: [
              PropertyInfoCard(
                propertyName: widget.booking.propertyName,
                unitName: widget.booking.unitName,
                colors: colors,
              ),
              const SizedBox(height: SpacingTokens.m),
              BookingDatesCard(
                checkIn: widget.booking.checkIn,
                checkOut: widget.booking.checkOut,
                nights: widget.booking.nights,
                adults: widget.booking.guestCount.adults,
                children: widget.booking.guestCount.children,
                colors: colors,
              ),
              // Notes (if any)
              if (widget.booking.notes != null &&
                  widget.booking.notes!.isNotEmpty) ...[
                const SizedBox(height: SpacingTokens.m),
                BookingNotesCard(
                  notes: widget.booking.notes!,
                  colors: colors,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: SpacingTokens.l),

        // Right column - Payment & Contact
        Expanded(
          child: Column(
            children: [
              PaymentInfoCard(
                totalPrice: widget.booking.totalPrice,
                depositAmount: widget.booking.depositAmount,
                paidAmount: widget.booking.paidAmount,
                remainingAmount: widget.booking.remainingAmount,
                paymentStatus: widget.booking.paymentStatus,
                paymentMethod: widget.booking.paymentMethod,
                paymentDeadline: widget.booking.paymentDeadline,
                colors: colors,
              ),
              const SizedBox(height: SpacingTokens.m),
              // Contact info
              if (widget.booking.ownerEmail != null ||
                  widget.booking.ownerPhone != null)
                ContactOwnerCard(
                  ownerEmail: widget.booking.ownerEmail,
                  ownerPhone: widget.booking.ownerPhone,
                  colors: colors,
                ),
              // Cancellation policy
              if (widget.widgetSettings != null &&
                  widget.widgetSettings!.allowGuestCancellation) ...[
                const SizedBox(height: SpacingTokens.m),
                CancellationPolicyCard(
                  deadlineHours:
                      widget.widgetSettings!.cancellationDeadlineHours ?? 48,
                  checkIn: widget.booking.checkIn,
                  colors: colors,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Mobile layout with single column
  Widget _buildMobileLayout(WidgetColorScheme colors) {
    return Column(
      children: [
        PropertyInfoCard(
          propertyName: widget.booking.propertyName,
          unitName: widget.booking.unitName,
          colors: colors,
        ),
        const SizedBox(height: SpacingTokens.m),
        BookingDatesCard(
          checkIn: widget.booking.checkIn,
          checkOut: widget.booking.checkOut,
          nights: widget.booking.nights,
          adults: widget.booking.guestCount.adults,
          children: widget.booking.guestCount.children,
          colors: colors,
        ),
        const SizedBox(height: SpacingTokens.m),
        PaymentInfoCard(
          totalPrice: widget.booking.totalPrice,
          depositAmount: widget.booking.depositAmount,
          paidAmount: widget.booking.paidAmount,
          remainingAmount: widget.booking.remainingAmount,
          paymentStatus: widget.booking.paymentStatus,
          paymentMethod: widget.booking.paymentMethod,
          paymentDeadline: widget.booking.paymentDeadline,
          colors: colors,
        ),
        // Contact info
        if (widget.booking.ownerEmail != null ||
            widget.booking.ownerPhone != null) ...[
          const SizedBox(height: SpacingTokens.m),
          ContactOwnerCard(
            ownerEmail: widget.booking.ownerEmail,
            ownerPhone: widget.booking.ownerPhone,
            colors: colors,
          ),
        ],
        // Cancellation policy
        if (widget.widgetSettings != null &&
            widget.widgetSettings!.allowGuestCancellation) ...[
          const SizedBox(height: SpacingTokens.m),
          CancellationPolicyCard(
            deadlineHours:
                widget.widgetSettings!.cancellationDeadlineHours ?? 48,
            checkIn: widget.booking.checkIn,
            colors: colors,
          ),
        ],
        // Notes
        if (widget.booking.notes != null &&
            widget.booking.notes!.isNotEmpty) ...[
          const SizedBox(height: SpacingTokens.m),
          BookingNotesCard(
            notes: widget.booking.notes!,
            colors: colors,
          ),
        ],
      ],
    );
  }

  /// Action buttons (Cancel booking if allowed)
  Widget _buildActionButtons(WidgetColorScheme colors) {
    final canCancel = _canCancelBooking();
    final cancelReason = _getCancelDisabledReason();
    final status = widget.booking.status.toLowerCase();
    final isCancelled = status == 'cancelled';

    return Column(
      children: [
        // Cancel button (if booking is active)
        if (!isCancelled)
          Tooltip(
            message: cancelReason ?? '',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: canCancel && !_isCancelling
                    ? _handleCancelBooking
                    : null,
                icon: _isCancelling
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.error,
                        ),
                      )
                    : Icon(
                        Icons.cancel_outlined,
                        color: canCancel ? colors.error : colors.textTertiary,
                      ),
                label: Text(
                  _isCancelling ? 'Cancelling...' : 'Cancel Booking',
                  style: GoogleFonts.inter(
                    fontSize: TypographyTokens.fontSizeM,
                    fontWeight: TypographyTokens.semiBold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: canCancel ? colors.error : colors.textTertiary,
                  side: BorderSide(
                    color: canCancel
                        ? colors.error
                        : colors.borderDefault,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderTokens.circularMedium,
                  ),
                ),
              ),
            ),
          ),

        // Help text
        const SizedBox(height: SpacingTokens.m),
        Text(
          'Need help? Contact the property owner using the information above.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: TypographyTokens.fontSizeS,
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// Confirmation dialog for cancellation
class _CancelConfirmationDialog extends StatelessWidget {
  final String bookingReference;
  final WidgetColorScheme colors;

  const _CancelConfirmationDialog({
    required this.bookingReference,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colors.backgroundPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderTokens.circularLarge,
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.error, size: 28),
          const SizedBox(width: SpacingTokens.s),
          Text(
            'Cancel Booking',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to cancel this booking?',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacingTokens.m),
            decoration: BoxDecoration(
              color: colors.backgroundSecondary,
              borderRadius: BorderTokens.circularMedium,
              border: Border.all(color: colors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Reference',
                  style: GoogleFonts.inter(
                    fontSize: TypographyTokens.fontSizeXS,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xxs),
                Text(
                  bookingReference,
                  style: GoogleFonts.inter(
                    fontSize: TypographyTokens.fontSizeM,
                    fontWeight: TypographyTokens.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.08),
              borderRadius: BorderTokens.circularSmall,
              border: Border.all(
                color: colors.error.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colors.error, size: 18),
                const SizedBox(width: SpacingTokens.xs),
                Expanded(
                  child: Text(
                    'This action cannot be undone. You will receive a cancellation confirmation email.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Keep Booking',
            style: GoogleFonts.inter(
              color: colors.textSecondary,
              fontWeight: TypographyTokens.medium,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderTokens.circularMedium,
            ),
          ),
          child: Text(
            'Cancel Booking',
            style: GoogleFonts.inter(fontWeight: TypographyTokens.semiBold),
          ),
        ),
      ],
    );
  }
}
