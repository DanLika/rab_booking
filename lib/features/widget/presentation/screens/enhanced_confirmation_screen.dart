import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/bedbooking_theme.dart';
import '../widgets/powered_by_badge.dart';
import '../../domain/models/widget_config.dart';

/// Enhanced Confirmation Screen (Step 3 of Flow B)
class EnhancedConfirmationScreen extends ConsumerWidget {
  final bool isStripePayment;
  final String? bookingReference;
  final WidgetConfig? config;

  const EnhancedConfirmationScreen({
    super.key,
    this.isStripePayment = false,
    this.bookingReference,
    this.config,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(selectedRoomProvider);
    final checkIn = ref.watch(checkInDateProvider);
    final checkOut = ref.watch(checkOutDateProvider);

    // Generate booking reference if not provided
    final reference = bookingReference ?? _generateBookingReference();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;

            return Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 600,
                  ),
                  padding: EdgeInsets.all(isMobile ? 20 : 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Success animation/icon
                      _buildSuccessHeader(),

                      const SizedBox(height: 32),

                      // Booking reference
                      _buildBookingReference(context, reference),

                      const SizedBox(height: 32),

                      // Confirmation message
                      _buildConfirmationMessage(isStripePayment),

                      const SizedBox(height: 32),

                      // Booking details card
                      if (room != null && checkIn != null && checkOut != null)
                        _buildBookingDetailsCard(room, checkIn, checkOut),

                      const SizedBox(height: 24),

                      // Next steps
                      _buildNextSteps(isStripePayment),

                      const SizedBox(height: 32),

                      // Action buttons
                      _buildActionButtons(context, ref),

                      const SizedBox(height: 32),

                      // Footer
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        // Animated checkmark
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: BedBookingColors.primaryGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: BedBookingColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Success title
        const Text(
          'Booking Confirmed!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: BedBookingColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBookingReference(BuildContext context, String reference) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BedBookingColors.backgroundGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            'Booking Reference',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                reference,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: reference));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reference copied to clipboard'),
                      duration: Duration(seconds: 2),
                      backgroundColor: BedBookingColors.success,
                    ),
                  );
                },
                tooltip: 'Copy',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationMessage(bool isStripePayment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BedBookingColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BedBookingColors.primaryGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isStripePayment ? Icons.check_circle : Icons.pending_actions,
            color: BedBookingColors.primaryGreen,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isStripePayment
                      ? 'Payment Successful'
                      : 'Awaiting Payment Confirmation',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isStripePayment
                      ? 'Your booking is confirmed and payment has been processed.'
                      : 'Your booking is pending. Please complete the bank transfer to confirm.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard(
    dynamic room,
    DateTime checkIn,
    DateTime checkOut,
  ) {
    final nights = checkOut.difference(checkIn).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BedBookingCards.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: BedBookingTextStyles.heading3,
          ),
          const Divider(height: 24),

          // Room name
          _buildDetailRow(
            Icons.hotel,
            'Room',
            room.name,
          ),

          const SizedBox(height: 12),

          // Check-in
          _buildDetailRow(
            Icons.login,
            'Check-in',
            DateFormat('EEEE, MMM d, yyyy').format(checkIn),
          ),

          const SizedBox(height: 12),

          // Check-out
          _buildDetailRow(
            Icons.logout,
            'Check-out',
            DateFormat('EEEE, MMM d, yyyy').format(checkOut),
          ),

          const SizedBox(height: 12),

          // Duration
          _buildDetailRow(
            Icons.nightlight_round,
            'Duration',
            '$nights ${nights == 1 ? 'night' : 'nights'}',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BedBookingColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: BedBookingColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextSteps(bool isStripePayment) {
    final steps = isStripePayment
        ? [
            {
              'icon': Icons.email,
              'title': 'Check Your Email',
              'description':
                  'Confirmation email sent with all booking details',
            },
            {
              'icon': Icons.calendar_today,
              'title': 'Add to Calendar',
              'description': 'Download the .ics file from your email',
            },
            {
              'icon': Icons.directions,
              'title': 'Prepare for Your Stay',
              'description': 'Check-in instructions will be sent 24h before',
            },
          ]
        : [
            {
              'icon': Icons.account_balance,
              'title': 'Complete Bank Transfer',
              'description':
                  'Transfer the deposit amount within 3 days using the reference number',
            },
            {
              'icon': Icons.email,
              'title': 'Check Your Email',
              'description':
                  'Bank transfer instructions and booking details have been sent',
            },
            {
              'icon': Icons.pending,
              'title': 'Awaiting Confirmation',
              'description':
                  'We\'ll confirm your booking once payment is received (usually within 24h)',
            },
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BedBookingColors.backgroundGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s Next?',
            style: BedBookingTextStyles.heading3,
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: BedBookingColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          step['icon'] as IconData,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['description'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.only(left: 20),
                    width: 2,
                    height: 24,
                    color: BedBookingColors.primaryGreen.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to property page or close widget
              _resetBookingFlow(ref);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
            style: BedBookingButtons.primaryButton.copyWith(
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Open email or show contact info
              _showContactInfo(context);
            },
            icon: const Icon(Icons.help_outline),
            label: const Text('Need Help?'),
            style: BedBookingButtons.secondaryButton,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),

        // Powered by BedBooking badge
        PoweredByBedBookingBadge(
          show: config?.showPoweredByBadge ?? true,
        ),

        const SizedBox(height: 8),
        Text(
          '© ${DateTime.now().year} BedBooking. All rights reserved.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _generateBookingReference() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final random =
        (now.millisecond * 1000 + now.second).toString().padLeft(4, '0');
    return 'BK-$dateStr-$random';
  }

  void _resetBookingFlow(WidgetRef ref) {
    ref.read(bookingStepProvider.notifier).state = 0;
    ref.read(selectedRoomProvider.notifier).state = null;
    ref.read(checkInDateProvider.notifier).state = null;
    ref.read(checkOutDateProvider.notifier).state = null;
    ref.read(adultsCountProvider.notifier).state = 2;
    ref.read(childrenCountProvider.notifier).state = 0;
  }

  void _showContactInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Need Help?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact us if you have any questions:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildContactRow(Icons.email, 'info@jasko-rab.com'),
            const SizedBox(height: 12),
            _buildContactRow(Icons.phone, '+385 XX XXX XXXX'),
            const SizedBox(height: 12),
            _buildContactRow(Icons.access_time, 'Mon-Sun: 8:00 - 20:00'),
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

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: BedBookingColors.primaryGreen),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 15)),
      ],
    );
  }
}
