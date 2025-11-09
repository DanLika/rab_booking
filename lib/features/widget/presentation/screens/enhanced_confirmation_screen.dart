import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_flow_provider.dart';
import '../providers/theme_provider.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../theme/responsive_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/powered_by_badge.dart';
import '../widgets/progress_indicator_widget.dart';
import '../components/adaptive_glass_card.dart';
import '../components/glass_modal.dart';
import '../../domain/models/widget_config.dart';
import '../../domain/models/widget_settings.dart';
import '../../../../shared/providers/repository_providers.dart';

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
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    final room = ref.watch(selectedRoomProvider);
    final checkIn = ref.watch(checkInDateProvider);
    final checkOut = ref.watch(checkOutDateProvider);

    // Generate booking reference if not provided
    final reference = bookingReference ?? _generateBookingReference();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          BookingProgressIndicator(
            colors: colors,
            currentStep: 4,
            onStepTapped: (step) {
              // Allow navigation back during confirmation
              if (step == 1) context.go('/rooms');
              if (step == 2) context.go('/summary');
              if (step == 3) context.go('/payment');
            },
          ),
          Expanded(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = ResponsiveHelper.isMobile(context);

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
                      _buildSuccessHeader(colors),

                      const SizedBox(height: 32),

                      // Booking reference
                      _buildBookingReference(context, reference, colors),

                      const SizedBox(height: 32),

                      // Confirmation message
                      _buildConfirmationMessage(isStripePayment, colors),

                      const SizedBox(height: 32),

                      // Booking details card
                      if (room != null && checkIn != null && checkOut != null)
                        _buildBookingDetailsCard(room, checkIn, checkOut, colors),

                      const SizedBox(height: 24),

                      // Next steps
                      _buildNextSteps(isStripePayment, colors),

                      const SizedBox(height: 32),

                      // Action buttons
                      _buildActionButtons(context, ref, colors),

                      const SizedBox(height: 32),

                      // Footer
                      _buildFooter(colors),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader(WidgetColorScheme colors) {
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
                  color: colors.success, // Success green
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.success.withValues(alpha: 0.3),
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
        Text(
          'Booking Confirmed!',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBookingReference(BuildContext context, String reference, WidgetColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        children: [
          Text(
            'Booking Reference',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                reference,
                style: GoogleFonts.robotoMono(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.copy, size: 20, color: colors.textSecondary),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: reference));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Reference copied to clipboard'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: colors.success,
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

  Widget _buildConfirmationMessage(bool isStripePayment, WidgetColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isStripePayment ? Icons.check_circle : Icons.pending_actions,
            color: colors.success,
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
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isStripePayment
                      ? 'Your booking is confirmed and payment has been processed.'
                      : 'Your booking is pending. Please complete the bank transfer to confirm.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colors.textSecondary,
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
    WidgetColorScheme colors,
  ) {
    final nights = checkOut.difference(checkIn).inDays;

    return AdaptiveGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Details',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          Divider(height: 24, color: colors.borderDefault),

          // Room name
          _buildDetailRow(
            Icons.hotel,
            'Room',
            room.name,
            colors,
          ),

          const SizedBox(height: 12),

          // Check-in
          _buildDetailRow(
            Icons.login,
            'Check-in',
            DateFormat('EEEE, MMM d, yyyy').format(checkIn),
            colors,
          ),

          const SizedBox(height: 12),

          // Check-out
          _buildDetailRow(
            Icons.logout,
            'Check-out',
            DateFormat('EEEE, MMM d, yyyy').format(checkOut),
            colors,
          ),

          const SizedBox(height: 12),

          // Duration
          _buildDetailRow(
            Icons.nightlight_round,
            'Duration',
            '$nights ${nights == 1 ? 'night' : 'nights'}',
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, WidgetColorScheme colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colors.success,
          ),
        ),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextSteps(bool isStripePayment, WidgetColorScheme colors) {
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
        color: colors.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s Next?',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
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
                        color: colors.success,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          step['icon'] as IconData,
                          color: colors.backgroundCard,
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
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['description'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: colors.textSecondary,
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
                    color: colors.success.withValues(alpha: 0.3),
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

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, WidgetColorScheme colors) {
    return Column(
      children: [
        // PDF Download and Email buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _downloadPDF(context, colors);
                },
                icon: Icon(Icons.picture_as_pdf, color: colors.primary),
                label: Text('Download PDF', style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                )),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _emailConfirmation(context, colors);
                },
                icon: Icon(Icons.email_outlined, color: colors.primary),
                label: Text('Email Me', style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                )),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _resetBookingFlow(ref);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: Icon(Icons.home, color: colors.backgroundCard),
            label: Text('Back to Home', style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: colors.backgroundCard,
            )),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.backgroundCard,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _showContactInfo(context, colors);
            },
            icon: Icon(Icons.help_outline, color: colors.primary),
            label: Text('Need Help?', style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: colors.primary,
            )),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(WidgetColorScheme colors) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),

        // Powered by BedBooking badge
        // NOTE: Currently respects URL parameter only (config.showPoweredByBadge)
        // TODO: Add Firestore settings check using DynamicThemeService.shouldShowBranding()
        PoweredByBedBookingBadge(
          colors: colors,
          show: config?.showPoweredByBadge ?? true,
        ),

        const SizedBox(height: 8),
        Text(
          '© ${DateTime.now().year} BedBooking. All rights reserved.',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: colors.textSecondary,
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

  void _showContactInfo(BuildContext context, WidgetColorScheme colors) {
    showGlassDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          // Try to fetch widget settings if we have config with propertyId and unitId
          if (config?.propertyId != null && config?.unitId != null) {
            return FutureBuilder<WidgetSettings?>(
              future: ref.read(widgetSettingsRepositoryProvider).getWidgetSettings(
                propertyId: config!.propertyId!,
                unitId: config!.unitId!,
              ),
              builder: (context, snapshot) {
                final contactOptions = snapshot.data?.contactOptions;

                return AlertDialog(
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
                      if (contactOptions?.showEmail == true && contactOptions?.emailAddress != null)
                        ...[
                          _buildContactRow(Icons.email, contactOptions!.emailAddress!, colors),
                          const SizedBox(height: 12),
                        ],
                      if (contactOptions?.showPhone == true && contactOptions?.phoneNumber != null)
                        ...[
                          _buildContactRow(Icons.phone, contactOptions!.phoneNumber!, colors),
                          const SizedBox(height: 12),
                        ],
                      if (contactOptions?.showWhatsApp == true && contactOptions?.whatsAppNumber != null)
                        ...[
                          _buildContactRow(Icons.message, 'WhatsApp: ${contactOptions!.whatsAppNumber}', colors),
                          const SizedBox(height: 12),
                        ],
                      // Fallback to hardcoded jasko-rab info if no contact info available
                      if (contactOptions == null || !contactOptions.hasContactMethod)
                        ...[
                          _buildContactRow(Icons.email, 'info@jasko-rab.com', colors),
                          const SizedBox(height: 12),
                        ],
                      _buildContactRow(Icons.access_time, 'Mon-Sun: 8:00 - 20:00', colors),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          }

          // Fallback dialog if no config available
          return AlertDialog(
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
                _buildContactRow(Icons.email, 'info@jasko-rab.com', colors),
                const SizedBox(height: 12),
                _buildContactRow(Icons.access_time, 'Mon-Sun: 8:00 - 20:00', colors),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, WidgetColorScheme colors) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.success),
        const SizedBox(width: 12),
        Text(text, style: GoogleFonts.inter(
          fontSize: 15,
          color: colors.textPrimary,
        )),
      ],
    );
  }

  void _downloadPDF(BuildContext context, WidgetColorScheme colors) {
    // TODO: Implement PDF generation and download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PDF download feature coming soon!',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _emailConfirmation(BuildContext context, WidgetColorScheme colors) {
    // TODO: Implement email confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Confirmation email sent!',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: colors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
