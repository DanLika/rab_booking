import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../providers/theme_provider.dart';
import '../../domain/models/booking_details_model.dart';
import '../../domain/models/widget_settings.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../theme/responsive_helper.dart';
import '../../../../../shared/utils/ui/snackbar_helper.dart';

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
      print('[CANCEL] widgetSettings null or cancellation not allowed');
      return false;
    }

    // Only confirmed, approved, or pending bookings can be cancelled
    final status = widget.booking.status.toLowerCase();
    if (status != 'confirmed' && status != 'pending' && status != 'approved') {
      print('[CANCEL] Invalid status: $status');
      return false;
    }

    // Check cancellation deadline
    final deadlineHours =
        widget.widgetSettings!.cancellationDeadlineHours ?? 48;
    final checkInDate = DateTime.parse(widget.booking.checkIn);
    final now = DateTime.now();
    final hoursUntilCheckIn = checkInDate.difference(now).inHours;

    print('[CANCEL] Status: $status, Hours until check-in: $hoursUntilCheckIn, Deadline: $deadlineHours');

    return hoursUntilCheckIn >= deadlineHours;
  }

  /// Handle booking cancellation
  Future<void> _handleCancelBooking() async {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            const SizedBox(height: 12),
            Text(
              'Booking Reference: ${widget.booking.bookingReference}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: colors.warning, size: 20),
                  const SizedBox(width: 8),
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
                _buildStatusBanner(colors),

                const SizedBox(height: 24),

                // Booking reference card
                _buildBookingReferenceCard(colors),

                const SizedBox(height: 16),

                // Property & Unit info
                _buildPropertyCard(colors),

                const SizedBox(height: 16),

                // Dates & Guest info
                _buildDatesCard(colors),

                const SizedBox(height: 16),

                // Payment info
                _buildPaymentCard(colors),

                const SizedBox(height: 16),

                // Contact info
                if (widget.booking.ownerEmail != null ||
                    widget.booking.ownerPhone != null)
                  _buildContactCard(colors),

                const SizedBox(height: 16),

                // Cancellation policy (if enabled)
                if (widget.widgetSettings != null &&
                    widget.widgetSettings!.allowGuestCancellation)
                  _buildCancellationPolicyCard(colors),

                const SizedBox(height: 16),

                // Additional notes
                if (widget.booking.notes != null &&
                    widget.booking.notes!.isNotEmpty)
                  _buildNotesCard(colors),

                const SizedBox(height: 24),

                // Cancel Booking Button (if allowed and within deadline)
                if (_canCancelBooking()) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildCancelButton(context, colors),
                  ),
                ] else ...[
                  // Debug: Show why cancel is not available
                  if (widget.widgetSettings != null) 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '[DEBUG] Cancel not available - Status: ${widget.booking.status}, Check-in: ${widget.booking.checkIn}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colors.warning,
                          ),
                        ),
                      ),
                    ),
                ],

                // Contact owner button
                _buildContactButton(context, colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(WidgetColorScheme colors) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (widget.booking.status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        statusColor = colors.success;
        statusText = 'Confirmed';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = colors.warning;
        statusText = 'Pending';
        statusIcon = Icons.schedule;
        break;
      case 'cancelled':
        statusColor = colors.error;
        statusText = 'Cancelled';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = colors.textSecondary;
        statusText = widget.booking.status;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Status',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingReferenceCard(WidgetColorScheme colors) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Booking Reference',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.booking.bookingReference,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: widget.booking.bookingReference),
                    );
                    // Show snackbar (context not available in ConsumerWidget)
                  },
                  color: colors.primary,
                  tooltip: 'Copy reference',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(WidgetColorScheme colors) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Property',
              widget.booking.propertyName,
              Icons.apartment,
              colors,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Unit', widget.booking.unitName, Icons.home, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard(WidgetColorScheme colors) {
    final checkIn = DateTime.parse(widget.booking.checkIn);
    final checkOut = DateTime.parse(widget.booking.checkOut);
    final formatter = DateFormat('MMM d, yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Check-in',
              formatter.format(checkIn),
              Icons.login,
              colors,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Check-out',
              formatter.format(checkOut),
              Icons.logout,
              colors,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Nights',
              '${widget.booking.nights} night${widget.booking.nights > 1 ? 's' : ''}',
              Icons.nights_stay,
              colors,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Guests',
              '${widget.booking.guestCount.adults} adult${widget.booking.guestCount.adults > 1 ? 's' : ''}${widget.booking.guestCount.children > 0 ? ', ${widget.booking.guestCount.children} child${widget.booking.guestCount.children > 1 ? 'ren' : ''}' : ''}',
              Icons.people,
              colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(WidgetColorScheme colors) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Information',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentRow('Total', widget.booking.totalPrice, colors, bold: true),
            const SizedBox(height: 8),
            _buildPaymentRow('Deposit', widget.booking.depositAmount, colors),
            const SizedBox(height: 8),
            _buildPaymentRow(
              'Paid',
              widget.booking.paidAmount,
              colors,
              color: colors.success,
            ),
            const SizedBox(height: 8),
            _buildPaymentRow(
              'Remaining',
              widget.booking.remainingAmount,
              colors,
              color: widget.booking.remainingAmount > 0
                  ? colors.error
                  : colors.success,
            ),
            const SizedBox(height: 12),
            Divider(color: colors.borderDefault),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Status',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
                _buildPaymentStatusChip(colors),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  _formatPaymentMethod(widget.booking.paymentMethod),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            if (widget.booking.paymentDeadline != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Deadline',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'MMM d, yyyy',
                    ).format(DateTime.parse(widget.booking.paymentDeadline!)),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(WidgetColorScheme colors) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property Owner Contact',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.booking.ownerEmail != null)
              _buildInfoRow('Email', widget.booking.ownerEmail!, Icons.email, colors),
            if (widget.booking.ownerPhone != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Phone', widget.booking.ownerPhone!, Icons.phone, colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(WidgetColorScheme colors) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, size: 20, color: colors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Additional Notes',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.booking.notes!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton(BuildContext context, WidgetColorScheme colors) {
    return ElevatedButton.icon(
      onPressed: () {
        // Show contact options dialog
        _showContactDialog(context, colors);
      },
      icon: const Icon(Icons.contact_support),
      label: Text(
        'Contact Property Owner',
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    WidgetColorScheme colors,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(
    String label,
    double amount,
    WidgetColorScheme colors, {
    bool bold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color ?? colors.textSecondary,
          ),
        ),
        Text(
          '€${amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: bold ? 18 : 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusChip(WidgetColorScheme colors) {
    Color statusColor;
    String statusText;

    switch (widget.booking.paymentStatus.toLowerCase()) {
      case 'paid':
      case 'completed':
        statusColor = colors.success;
        statusText = 'Paid';
        break;
      case 'pending':
        statusColor = colors.warning;
        statusText = 'Pending';
        break;
      case 'failed':
      case 'refunded':
        statusColor = colors.error;
        statusText = widget.booking.paymentStatus;
        break;
      default:
        statusColor = colors.textSecondary;
        statusText = widget.booking.paymentStatus;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'stripe':
        return 'Credit Card (Stripe)';
      case 'cash':
        return 'Cash';
      default:
        return method;
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
                onTap: () {
                  // Open email client
                  Navigator.pop(context);
                },
              ),
            if (widget.booking.ownerPhone != null)
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Call'),
                subtitle: Text(widget.booking.ownerPhone!),
                onTap: () {
                  // Open phone dialer
                  Navigator.pop(context);
                },
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

  Widget _buildCancellationPolicyCard(WidgetColorScheme colors) {
    final deadlineHours =
        widget.widgetSettings!.cancellationDeadlineHours ?? 48;
    final checkInDate = DateTime.parse(widget.booking.checkIn);
    final now = DateTime.now();
    final hoursUntilCheckIn = checkInDate.difference(now).inHours;
    final canCancel = hoursUntilCheckIn >= deadlineHours;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  canCancel ? Icons.event_available : Icons.event_busy,
                  size: 20,
                  color: canCancel ? colors.success : colors.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cancellation Policy',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (canCancel ? colors.success : colors.warning)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (canCancel ? colors.success : colors.warning)
                      .withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    canCancel
                        ? '✓ Free cancellation available'
                        : '✗ Cancellation deadline passed',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: canCancel ? colors.success : colors.warning,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can cancel free of charge up to $deadlineHours hours before check-in.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                  if (!canCancel) ...[
                    const SizedBox(height: 8),
                    Text(
                      'The cancellation deadline has passed. Please contact the property owner if you need to cancel.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, WidgetColorScheme colors) {
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
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.error,
          side: BorderSide(color: colors.error, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
