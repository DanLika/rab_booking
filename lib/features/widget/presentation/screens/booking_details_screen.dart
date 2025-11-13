import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../../domain/models/booking_details_model.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../theme/responsive_helper.dart';
import '../components/adaptive_glass_card.dart';

/// Booking Details Screen
/// Displays complete booking information for guest
class BookingDetailsScreen extends ConsumerWidget {
  final BookingDetailsModel booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                if (booking.ownerEmail != null || booking.ownerPhone != null)
                  _buildContactCard(colors),

                const SizedBox(height: 16),

                // Additional notes
                if (booking.notes != null && booking.notes!.isNotEmpty)
                  _buildNotesCard(colors),

                const SizedBox(height: 24),

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

    switch (booking.status.toLowerCase()) {
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
        statusText = booking.status;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
    return AdaptiveGlassCard(
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
                  booking.bookingReference,
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
                      ClipboardData(text: booking.bookingReference),
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
    return AdaptiveGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Property',
              booking.propertyName,
              Icons.apartment,
              colors,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Unit', booking.unitName, Icons.home, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard(WidgetColorScheme colors) {
    final checkIn = DateTime.parse(booking.checkIn);
    final checkOut = DateTime.parse(booking.checkOut);
    final formatter = DateFormat('MMM d, yyyy');

    return AdaptiveGlassCard(
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
              '${booking.nights} night${booking.nights > 1 ? 's' : ''}',
              Icons.nights_stay,
              colors,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Guests',
              '${booking.guestCount.adults} adult${booking.guestCount.adults > 1 ? 's' : ''}${booking.guestCount.children > 0 ? ', ${booking.guestCount.children} child${booking.guestCount.children > 1 ? 'ren' : ''}' : ''}',
              Icons.people,
              colors,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(WidgetColorScheme colors) {
    return AdaptiveGlassCard(
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
            _buildPaymentRow('Total', booking.totalPrice, colors, bold: true),
            const SizedBox(height: 8),
            _buildPaymentRow('Deposit', booking.depositAmount, colors),
            const SizedBox(height: 8),
            _buildPaymentRow(
              'Paid',
              booking.paidAmount,
              colors,
              color: colors.success,
            ),
            const SizedBox(height: 8),
            _buildPaymentRow(
              'Remaining',
              booking.remainingAmount,
              colors,
              color: booking.remainingAmount > 0
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
                  _formatPaymentMethod(booking.paymentMethod),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            if (booking.paymentDeadline != null) ...[
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
                    ).format(DateTime.parse(booking.paymentDeadline!)),
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
    return AdaptiveGlassCard(
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
            if (booking.ownerEmail != null)
              _buildInfoRow('Email', booking.ownerEmail!, Icons.email, colors),
            if (booking.ownerPhone != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Phone', booking.ownerPhone!, Icons.phone, colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(WidgetColorScheme colors) {
    return AdaptiveGlassCard(
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
              booking.notes!,
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

    switch (booking.paymentStatus.toLowerCase()) {
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
        statusText = booking.paymentStatus;
        break;
      default:
        statusColor = colors.textSecondary;
        statusText = booking.paymentStatus;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
            if (booking.ownerEmail != null)
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Send Email'),
                subtitle: Text(booking.ownerEmail!),
                onTap: () {
                  // Open email client
                  Navigator.pop(context);
                },
              ),
            if (booking.ownerPhone != null)
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Call'),
                subtitle: Text(booking.ownerPhone!),
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
}
