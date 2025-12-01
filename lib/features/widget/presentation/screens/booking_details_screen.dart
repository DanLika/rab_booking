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
/// Displays complete booking information for guest
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
    if (widget.widgetSettings == null ||
        !widget.widgetSettings!.allowGuestCancellation) {
      return false;
    }

    // Only confirmed, approved, or pending bookings can be cancelled
    final status = widget.booking.status.toLowerCase();
    if (status != 'confirmed' && status != 'pending' && status != 'approved') {
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

        // Navigate back after short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
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

  void _showContactDialog(BuildContext context, WidgetColorScheme colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Contact Property Owner',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.booking.ownerEmail != null)
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Send Email'),
                subtitle: Text(widget.booking.ownerEmail!),
                onTap: () => Navigator.pop(context),
              ),
            if (widget.booking.ownerPhone != null)
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Call'),
                subtitle: Text(widget.booking.ownerPhone!),
                onTap: () => Navigator.pop(context),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Booking Details',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 700,
            ),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status banner
                BookingStatusBanner(
                  status: widget.booking.status,
                  colors: colors,
                ),

                const SizedBox(height: SpacingTokens.l),

                // Booking reference card
                DetailsReferenceCard(
                  bookingReference: widget.booking.bookingReference,
                  colors: colors,
                ),

                const SizedBox(height: SpacingTokens.m),

                // Property & Unit info
                PropertyInfoCard(
                  propertyName: widget.booking.propertyName,
                  unitName: widget.booking.unitName,
                  colors: colors,
                ),

                const SizedBox(height: SpacingTokens.m),

                // Dates & Guest info
                BookingDatesCard(
                  checkIn: widget.booking.checkIn,
                  checkOut: widget.booking.checkOut,
                  nights: widget.booking.nights,
                  adults: widget.booking.guestCount.adults,
                  children: widget.booking.guestCount.children,
                  colors: colors,
                ),

                const SizedBox(height: SpacingTokens.m),

                // Payment info
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

                const SizedBox(height: SpacingTokens.m),

                // Cancellation policy (if enabled)
                if (widget.widgetSettings != null &&
                    widget.widgetSettings!.allowGuestCancellation)
                  CancellationPolicyCard(
                    deadlineHours:
                        widget.widgetSettings!.cancellationDeadlineHours ?? 48,
                    checkIn: widget.booking.checkIn,
                    colors: colors,
                  ),

                const SizedBox(height: SpacingTokens.m),

                // Additional notes
                if (widget.booking.notes != null &&
                    widget.booking.notes!.isNotEmpty)
                  BookingNotesCard(
                    notes: widget.booking.notes!,
                    colors: colors,
                  ),

                const SizedBox(height: SpacingTokens.l),

                // Cancel Booking Button (if allowed and within deadline)
                if (_canCancelBooking())
                  Padding(
                    padding: const EdgeInsets.only(bottom: SpacingTokens.m),
                    child: _buildCancelButton(colors),
                  ),

                // Contact owner button
                _buildContactButton(context, colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(WidgetColorScheme colors) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isCancelling ? null : _handleCancelBooking,
        icon: _isCancelling
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cancel_outlined),
        label: Text(
          _isCancelling ? 'Cancelling...' : 'Cancel This Booking',
          style: GoogleFonts.inter(
            fontSize: TypographyTokens.fontSizeM,
            fontWeight: TypographyTokens.semiBold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.error,
          side: BorderSide(color: colors.error, width: 2),
          padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
          shape: RoundedRectangleBorder(
            borderRadius: BorderTokens.circularMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton(BuildContext context, WidgetColorScheme colors) {
    return ElevatedButton.icon(
      onPressed: () => _showContactDialog(context, colors),
      icon: const Icon(Icons.contact_support),
      label: Text(
        'Contact Property Owner',
        style: GoogleFonts.inter(
          fontSize: TypographyTokens.fontSizeM,
          fontWeight: TypographyTokens.semiBold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
        shape: RoundedRectangleBorder(
          borderRadius: BorderTokens.circularMedium,
        ),
        elevation: 0,
      ),
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
      title: Text(
        'Cancel Booking',
        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to cancel this booking?',
            style: GoogleFonts.inter(fontSize: 16),
          ),
          const SizedBox(height: SpacingTokens.s),
          Text(
            'Booking Reference: $bookingReference',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.1),
              borderRadius: BorderTokens.circularSmall,
              border: Border.all(
                color: colors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: colors.warning, size: 20),
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
            style: GoogleFonts.inter(color: colors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancel Booking'),
        ),
      ],
    );
  }
}
