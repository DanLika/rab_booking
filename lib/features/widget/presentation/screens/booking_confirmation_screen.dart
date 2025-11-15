import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/minimalist_colors.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../../../core/services/email_notification_service.dart';
import '../../../../core/services/ical_generator.dart';
import '../../../../shared/models/booking_model.dart';
import '../../domain/models/widget_settings.dart';

/// Simplified Booking Confirmation Screen for Embedded Widget
/// Shows booking confirmation with reference number and details
/// Can be accessed via URL: ?confirmation=BOOKING_REF&email=USER_EMAIL
class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final String bookingReference;
  final String guestEmail;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalPrice;
  final int nights;
  final int guests;
  final String propertyName;
  final String? unitName;
  final String
  paymentMethod; // 'stripe', 'bankTransfer', 'payOnArrival', 'pending'
  final BookingModel? booking; // Optional - for resend email functionality
  final EmailNotificationConfig?
  emailConfig; // Optional - for resend email functionality
  final WidgetSettings?
  widgetSettings; // Optional - for cancellation policy display

  const BookingConfirmationScreen({
    super.key,
    required this.bookingReference,
    required this.guestEmail,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.totalPrice,
    required this.nights,
    required this.guests,
    required this.propertyName,
    this.unitName,
    required this.paymentMethod,
    this.booking,
    this.emailConfig,
    this.widgetSettings,
  });

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isResendingEmail = false;
  bool _emailResent = false;
  bool _isGeneratingIcs = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color getColor(Color light, Color dark) {
    final isDarkMode = ref.watch(themeProvider);
    return isDarkMode ? dark : light;
  }

  String _getConfirmationMessage() {
    switch (widget.paymentMethod) {
      case 'stripe':
        return 'Payment successful! Your booking is confirmed.';
      case 'bankTransfer':
        return 'Booking received! Please complete the bank transfer to confirm.';
      case 'payOnArrival':
        return 'Booking confirmed! You can pay at the property.';
      case 'pending':
        return 'Booking request sent! Waiting for owner approval.';
      default:
        return 'Your booking has been confirmed!';
    }
  }

  Icon _getConfirmationIcon() {
    switch (widget.paymentMethod) {
      case 'stripe':
        return const Icon(Icons.check_circle, size: 80, color: Colors.green);
      case 'bankTransfer':
        return Icon(Icons.schedule, size: 80, color: Colors.orange.shade700);
      case 'payOnArrival':
        return const Icon(Icons.hotel, size: 80, color: Colors.blue);
      case 'pending':
        return Icon(Icons.pending, size: 80, color: Colors.orange.shade700);
      default:
        return const Icon(Icons.check_circle, size: 80, color: Colors.green);
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.bookingReference));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Booking reference copied to clipboard!'),
          backgroundColor: getColor(
            MinimalistColors.success,
            MinimalistColorsDark.success,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resendConfirmationEmail() async {
    if (widget.booking == null || widget.emailConfig == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to resend email - missing configuration'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isResendingEmail = true;
    });

    try {
      final emailService = EmailNotificationService();
      await emailService.sendBookingConfirmationEmail(
        booking: widget.booking!,
        emailConfig: widget.emailConfig!,
        propertyName: widget.propertyName,
        bookingReference: widget.bookingReference,
        allowGuestCancellation:
            widget.widgetSettings?.allowGuestCancellation ?? false,
        cancellationDeadlineHours:
            widget.widgetSettings?.cancellationDeadlineHours,
        ownerEmail: widget.widgetSettings?.contactOptions.emailAddress,
        ownerPhone: widget.widgetSettings?.contactOptions.phoneNumber,
        customLogoUrl: widget.widgetSettings?.themeOptions?.customLogoUrl,
      );

      setState(() {
        _isResendingEmail = false;
        _emailResent = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirmation email sent successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isResendingEmail = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Handle "Add to Calendar" button click
  /// Generates .ics file and triggers download
  Future<void> _handleAddToCalendar() async {
    setState(() => _isGeneratingIcs = true);

    try {
      // Validate booking data
      final booking = widget.booking;
      if (booking == null) {
        throw Exception('Booking data not available');
      }

      // Generate .ics content using Terminal 2's IcalGenerator service
      final unitName = widget.unitName ?? widget.propertyName;
      final icsContent = IcalGenerator.generateBookingEvent(
        booking: booking,
        unitName: unitName,
      );

      // Download file (platform-specific)
      final filename = 'booking-${widget.bookingReference}.ics';
      await _downloadIcsFile(icsContent, filename);

      // Success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Calendar event downloaded! Check your downloads folder.',
            ),
            backgroundColor: getColor(
              MinimalistColors.statusAvailableBorder,
              MinimalistColorsDark.statusAvailableBorder,
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Error handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate calendar file: $e'),
            backgroundColor: MinimalistColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingIcs = false);
      }
    }
  }

  /// Download .ics file (platform-specific implementation)
  /// Web: Triggers browser download via anchor tag
  /// Mobile/Desktop: Shares .ics file via share dialog using share_plus
  Future<void> _downloadIcsFile(String content, String filename) async {
    if (kIsWeb) {
      // Web: Use anchor tag download
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], 'text/calendar');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile/Desktop: Save to temporary directory and share
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$filename');
        await file.writeAsString(content);

        // Share the file using share_plus
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/calendar')],
          subject: 'Booking Calendar Event',
          text: 'Add your booking to your calendar',
        );
      } catch (e) {
        throw Exception('Failed to share calendar file: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getColor(
        MinimalistColors.backgroundPrimary,
        MinimalistColorsDark.backgroundPrimary,
      ),
      appBar: AppBar(
        title: Text(
          'Booking Confirmation',
          style: TextStyle(
            color: getColor(
              MinimalistColors.textPrimary,
              MinimalistColorsDark.textPrimary,
            ),
          ),
        ),
        backgroundColor: getColor(
          MinimalistColors.backgroundPrimary,
          MinimalistColorsDark.backgroundPrimary,
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: getColor(
              MinimalistColors.textPrimary,
              MinimalistColorsDark.textPrimary,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingTokens.l),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Custom logo display (if configured)
                  if (widget.widgetSettings?.themeOptions?.customLogoUrl !=
                          null &&
                      widget
                          .widgetSettings!
                          .themeOptions!
                          .customLogoUrl!
                          .isNotEmpty) ...[
                    CachedNetworkImage(
                      imageUrl:
                          widget.widgetSettings!.themeOptions!.customLogoUrl!,
                      height: 80,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          const SizedBox(height: 80, width: 80),
                      errorWidget: (context, url, error) =>
                          const SizedBox.shrink(),
                    ),
                    const SizedBox(height: SpacingTokens.l),
                  ],

                  // Success icon with animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _getConfirmationIcon(),
                  ),

                  const SizedBox(height: SpacingTokens.l),

                  // Confirmation message
                  Text(
                    _getConfirmationMessage(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeXL,
                      fontWeight: TypographyTokens.bold,
                      color: getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: SpacingTokens.m),

                  // Bug #40: Warning if payment still pending after Stripe webhook timeout
                  if (widget.paymentMethod == 'stripe' &&
                      widget.booking != null &&
                      (widget.booking!.paymentStatus == 'pending' ||
                          widget.booking!.status.value == 'pending')) ...[
                    Container(
                      padding: const EdgeInsets.all(SpacingTokens.m),
                      decoration: BoxDecoration(
                        color: getColor(
                          MinimalistColors.statusPendingBackground,
                          MinimalistColorsDark.statusPendingBackground,
                        ),
                        borderRadius: BorderTokens.circularMedium,
                        border: Border.all(
                          color: getColor(
                            MinimalistColors.statusPendingBorder,
                            MinimalistColorsDark.statusPendingBorder,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: getColor(
                              MinimalistColors.statusPendingText,
                              MinimalistColorsDark.statusPendingText,
                            ),
                            size: 24,
                          ),
                          const SizedBox(width: SpacingTokens.s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment Verification in Progress',
                                  style: TextStyle(
                                    fontSize: TypographyTokens.fontSizeM,
                                    fontWeight: TypographyTokens.bold,
                                    color: getColor(
                                      MinimalistColors.statusPendingText,
                                      MinimalistColorsDark.statusPendingText,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: SpacingTokens.xs),
                                Text(
                                  'Your payment was successful, but we\'re still verifying it with the payment provider. You will receive a confirmation email within a few minutes. If you don\'t receive it, please contact the property owner.',
                                  style: TextStyle(
                                    fontSize: TypographyTokens.fontSizeS,
                                    color: getColor(
                                      MinimalistColors.statusPendingText,
                                      MinimalistColorsDark.statusPendingText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.m),
                  ],

                  // Booking reference card
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.m),
                    decoration: BoxDecoration(
                      color: getColor(
                        MinimalistColors.backgroundSecondary,
                        MinimalistColorsDark.backgroundSecondary,
                      ),
                      borderRadius: BorderTokens.circularMedium,
                      border: Border.all(
                        color: getColor(
                          MinimalistColors.borderDefault,
                          MinimalistColorsDark.borderDefault,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Booking Reference',
                          style: TextStyle(
                            fontSize: TypographyTokens.fontSizeS,
                            color: getColor(
                              MinimalistColors.textSecondary,
                              MinimalistColorsDark.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.bookingReference,
                              style: TextStyle(
                                fontSize: TypographyTokens.fontSizeXL,
                                fontWeight: TypographyTokens.bold,
                                letterSpacing: 2,
                                color: getColor(
                                  MinimalistColors.textPrimary,
                                  MinimalistColorsDark.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: SpacingTokens.s),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: getColor(
                                  MinimalistColors.textSecondary,
                                  MinimalistColorsDark.textSecondary,
                                ),
                              ),
                              onPressed: _copyToClipboard,
                              tooltip: 'Copy reference',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: SpacingTokens.m),

                  // Bug #43: Email spam folder warning
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.m),
                    decoration: BoxDecoration(
                      color: getColor(
                        MinimalistColors.statusAvailableBackground,
                        MinimalistColorsDark.statusAvailableBackground,
                      ),
                      borderRadius: BorderTokens.circularMedium,
                      border: Border.all(
                        color: getColor(
                          MinimalistColors.statusAvailableBorder,
                          MinimalistColorsDark.statusAvailableBorder,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.mail_outline,
                          color: getColor(
                            MinimalistColors.statusAvailableText,
                            MinimalistColorsDark.statusAvailableText,
                          ),
                          size: 20,
                        ),
                        const SizedBox(width: SpacingTokens.s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confirmation Email Sent',
                                style: TextStyle(
                                  fontSize: TypographyTokens.fontSizeM,
                                  fontWeight: TypographyTokens.semiBold,
                                  color: getColor(
                                    MinimalistColors.statusAvailableText,
                                    MinimalistColorsDark.statusAvailableText,
                                  ),
                                ),
                              ),
                              const SizedBox(height: SpacingTokens.xxs),
                              Text(
                                'Check your inbox for booking confirmation. If you don\'t see it within a few minutes, please check your spam or junk folder.',
                                style: TextStyle(
                                  fontSize: TypographyTokens.fontSizeS,
                                  color: getColor(
                                    MinimalistColors.statusAvailableText,
                                    MinimalistColorsDark.statusAvailableText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: SpacingTokens.l),

                  // Booking details card
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.m),
                    decoration: BoxDecoration(
                      color: getColor(
                        MinimalistColors.backgroundSecondary,
                        MinimalistColorsDark.backgroundSecondary,
                      ),
                      borderRadius: BorderTokens.circularMedium,
                      border: Border.all(
                        color: getColor(
                          MinimalistColors.borderDefault,
                          MinimalistColorsDark.borderDefault,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Details',
                          style: TextStyle(
                            fontSize: TypographyTokens.fontSizeL,
                            fontWeight: TypographyTokens.bold,
                            color: getColor(
                              MinimalistColors.textPrimary,
                              MinimalistColorsDark.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.m),
                        _buildDetailRow(
                          'Property',
                          widget.unitName ?? widget.propertyName,
                        ),
                        _buildDetailRow('Guest', widget.guestName),
                        _buildDetailRow('Email', widget.guestEmail),
                        const SizedBox(height: SpacingTokens.s),
                        _buildDetailRow(
                          'Check-in',
                          DateFormat(
                            'EEEE, MMM dd, yyyy',
                          ).format(widget.checkIn),
                        ),
                        _buildDetailRow(
                          'Check-out',
                          DateFormat(
                            'EEEE, MMM dd, yyyy',
                          ).format(widget.checkOut),
                        ),
                        _buildDetailRow(
                          'Duration',
                          '${widget.nights} ${widget.nights == 1 ? 'night' : 'nights'}',
                        ),
                        _buildDetailRow(
                          'Guests',
                          '${widget.guests} ${widget.guests == 1 ? 'guest' : 'guests'}',
                        ),
                        const SizedBox(height: SpacingTokens.s),
                        _buildDetailRow(
                          'Total Price',
                          '€${widget.totalPrice.toStringAsFixed(2)}',
                          isHighlighted: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: SpacingTokens.l),

                  // Add to Calendar button (if booking data available and iCal export enabled)
                  if (widget.booking != null &&
                      (widget.widgetSettings?.icalExportEnabled ?? false))
                    Container(
                      margin: const EdgeInsets.only(bottom: SpacingTokens.l),
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingIcs
                            ? null
                            : _handleAddToCalendar,
                        icon: Icon(
                          _isGeneratingIcs
                              ? Icons.hourglass_empty
                              : Icons.calendar_today,
                        ),
                        label: Text(
                          _isGeneratingIcs
                              ? 'Generating...'
                              : 'Add to My Calendar',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getColor(
                            MinimalistColors.statusAvailableBorder,
                            MinimalistColorsDark.statusAvailableBorder,
                          ),
                          foregroundColor: getColor(
                            MinimalistColors.backgroundPrimary,
                            MinimalistColorsDark.backgroundPrimary,
                          ),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              BorderTokens.radiusMedium,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Bank Transfer Instructions (if payment method is bank transfer)
                  if (widget.paymentMethod == 'bankTransfer' &&
                      widget
                              .widgetSettings
                              ?.bankTransferConfig
                              ?.hasCompleteDetails ==
                          true)
                    Container(
                      margin: const EdgeInsets.only(bottom: SpacingTokens.l),
                      padding: const EdgeInsets.all(SpacingTokens.m),
                      decoration: BoxDecoration(
                        color: getColor(
                          MinimalistColors.statusPendingBackground,
                          MinimalistColorsDark.statusPendingBackground,
                        ),
                        borderRadius: BorderTokens.circularMedium,
                        border: Border.all(
                          color: getColor(
                            MinimalistColors.statusPendingBorder,
                            MinimalistColorsDark.statusPendingBorder,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance,
                                color: getColor(
                                  MinimalistColors.statusPendingText,
                                  MinimalistColorsDark.statusPendingText,
                                ),
                                size: 24,
                              ),
                              const SizedBox(width: SpacingTokens.s),
                              Text(
                                'Bank Transfer Instructions',
                                style: TextStyle(
                                  fontSize: TypographyTokens.fontSizeL,
                                  fontWeight: TypographyTokens.bold,
                                  color: getColor(
                                    MinimalistColors.textPrimary,
                                    MinimalistColorsDark.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: SpacingTokens.m),
                          _buildBankTransferDetail(
                            'Bank Name',
                            widget
                                .widgetSettings!
                                .bankTransferConfig!
                                .bankName!,
                          ),
                          const SizedBox(height: SpacingTokens.s),
                          _buildBankTransferDetail(
                            'Account Holder',
                            widget
                                .widgetSettings!
                                .bankTransferConfig!
                                .accountHolder!,
                          ),
                          const SizedBox(height: SpacingTokens.s),
                          if (widget.widgetSettings!.bankTransferConfig!.iban !=
                              null)
                            _buildBankTransferDetail(
                              'IBAN',
                              widget.widgetSettings!.bankTransferConfig!.iban!,
                              copyable: true,
                            )
                          else if (widget
                                  .widgetSettings!
                                  .bankTransferConfig!
                                  .accountNumber !=
                              null)
                            _buildBankTransferDetail(
                              'Account Number',
                              widget
                                  .widgetSettings!
                                  .bankTransferConfig!
                                  .accountNumber!,
                              copyable: true,
                            ),
                          if (widget
                                  .widgetSettings!
                                  .bankTransferConfig!
                                  .swift !=
                              null) ...[
                            const SizedBox(height: SpacingTokens.s),
                            _buildBankTransferDetail(
                              'SWIFT/BIC',
                              widget.widgetSettings!.bankTransferConfig!.swift!,
                              copyable: true,
                            ),
                          ],
                          const SizedBox(height: SpacingTokens.s),
                          _buildBankTransferDetail(
                            'Reference',
                            widget.bookingReference,
                            copyable: true,
                            highlight: true,
                          ),
                          const SizedBox(height: SpacingTokens.m),
                          Container(
                            padding: const EdgeInsets.all(SpacingTokens.s),
                            decoration: BoxDecoration(
                              color: getColor(
                                MinimalistColors.statusAvailableBackground,
                                MinimalistColorsDark.statusAvailableBackground,
                              ),
                              borderRadius: BorderTokens.circularSmall,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: getColor(
                                    MinimalistColors.statusAvailableText,
                                    MinimalistColorsDark.statusAvailableText,
                                  ),
                                ),
                                const SizedBox(width: SpacingTokens.xs),
                                Expanded(
                                  child: Text(
                                    'Please complete the transfer within 3 days and include the reference number.',
                                    style: TextStyle(
                                      fontSize: TypographyTokens.fontSizeS,
                                      color: getColor(
                                        MinimalistColors.statusAvailableText,
                                        MinimalistColorsDark
                                            .statusAvailableText,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Email confirmation info
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.m),
                    decoration: BoxDecoration(
                      color: getColor(
                        Colors.blue.shade50,
                        Colors.blue.shade900.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderTokens.circularMedium,
                      border: Border.all(
                        color: getColor(
                          Colors.blue.shade200,
                          Colors.blue.shade700,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: getColor(
                            Colors.blue.shade700,
                            Colors.blue.shade300,
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confirmation Email Sent',
                                style: TextStyle(
                                  fontSize: TypographyTokens.fontSizeM,
                                  fontWeight: TypographyTokens.semiBold,
                                  color: getColor(
                                    Colors.blue.shade900,
                                    Colors.blue.shade100,
                                  ),
                                ),
                              ),
                              const SizedBox(height: SpacingTokens.xxs),
                              Text(
                                'Check your email at ${widget.guestEmail} for booking details.',
                                style: TextStyle(
                                  fontSize: TypographyTokens.fontSizeS,
                                  color: getColor(
                                    Colors.blue.shade800,
                                    Colors.blue.shade200,
                                  ),
                                ),
                              ),
                              if (widget.emailConfig != null &&
                                  widget.booking != null) ...[
                                const SizedBox(height: SpacingTokens.xs),
                                TextButton.icon(
                                  onPressed: _isResendingEmail
                                      ? null
                                      : _resendConfirmationEmail,
                                  icon: _isResendingEmail
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          _emailResent
                                              ? Icons.check
                                              : Icons.refresh,
                                          size: 16,
                                        ),
                                  label: Text(
                                    _emailResent
                                        ? 'Email sent!'
                                        : 'Didn\'t receive? Resend email',
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cancellation policy (if enabled)
                  if (widget.widgetSettings?.allowGuestCancellation == true &&
                      widget.widgetSettings?.cancellationDeadlineHours != null)
                    _buildCancellationPolicy(),

                  // Next steps section
                  _buildNextSteps(),

                  const SizedBox(height: SpacingTokens.xl),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: getColor(
                          MinimalistColors.buttonPrimary,
                          MinimalistColorsDark.buttonPrimary,
                        ),
                        foregroundColor: getColor(
                          MinimalistColors.buttonPrimaryText,
                          MinimalistColorsDark.buttonPrimaryText,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: SpacingTokens.m,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderTokens.circularRounded,
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: TypographyTokens.fontSizeL,
                          fontWeight: TypographyTokens.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: SpacingTokens.m),

                  // Helpful info
                  Text(
                    'Save this booking reference for your records. You can use it to check your booking status.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeS,
                      color: getColor(
                        MinimalistColors.textSecondary,
                        MinimalistColorsDark.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeM,
              color: getColor(
                MinimalistColors.textSecondary,
                MinimalistColorsDark.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeM,
              fontWeight: isHighlighted
                  ? TypographyTokens.bold
                  : TypographyTokens.regular,
              color: isHighlighted
                  ? getColor(
                      MinimalistColors.buttonPrimary,
                      MinimalistColorsDark.buttonPrimary,
                    )
                  : getColor(
                      MinimalistColors.textPrimary,
                      MinimalistColorsDark.textPrimary,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build cancellation policy widget
  Widget _buildCancellationPolicy() {
    final deadlineHours = widget.widgetSettings!.cancellationDeadlineHours!;

    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.l),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.m),
        decoration: BoxDecoration(
          color: getColor(
            MinimalistColors.statusAvailableBackground,
            MinimalistColorsDark.statusAvailableBackground,
          ),
          borderRadius: BorderTokens.circularMedium,
          border: Border.all(
            color: getColor(
              MinimalistColors.statusAvailableBorder,
              MinimalistColorsDark.statusAvailableBorder,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_available,
                  color: getColor(
                    MinimalistColors.success,
                    MinimalistColorsDark.success,
                  ),
                  size: 24,
                ),
                const SizedBox(width: SpacingTokens.s),
                Text(
                  'Cancellation Policy',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeL,
                    fontWeight: TypographyTokens.bold,
                    color: getColor(
                      MinimalistColors.textPrimary,
                      MinimalistColorsDark.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.s),
            Text(
              'Free cancellation up to $deadlineHours hours before check-in',
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                fontWeight: TypographyTokens.semiBold,
                color: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              'To cancel your booking:',
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: getColor(
                  MinimalistColors.textSecondary,
                  MinimalistColorsDark.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            _buildCancellationStep('Reply to the confirmation email'),
            _buildCancellationStep(
              'Include your booking reference: ${widget.bookingReference}',
            ),
            if (widget.emailConfig?.fromEmail != null)
              _buildCancellationStep(
                'Or email: ${widget.emailConfig!.fromEmail}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancellationStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        left: SpacingTokens.m,
        top: SpacingTokens.xxs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeM,
              color: getColor(
                MinimalistColors.textSecondary,
                MinimalistColorsDark.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: getColor(
                  MinimalistColors.textSecondary,
                  MinimalistColorsDark.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build next steps section based on payment method
  Widget _buildNextSteps() {
    final List<Map<String, dynamic>> steps;

    switch (widget.paymentMethod) {
      case 'stripe':
        steps = [
          {
            'icon': Icons.email,
            'title': 'Check Your Email',
            'description': 'Confirmation email sent with all booking details',
          },
          {
            'icon': Icons.calendar_today,
            'title': 'Add to Calendar',
            'description':
                'Click the "Add to My Calendar" button above to download the event',
          },
          {
            'icon': Icons.directions,
            'title': 'Prepare for Your Stay',
            'description': 'Check-in instructions will be sent 24h before',
          },
        ];
        break;

      case 'bankTransfer':
        steps = [
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
        break;

      case 'payOnArrival':
        steps = [
          {
            'icon': Icons.email,
            'title': 'Check Your Email',
            'description':
                'Confirmation email sent with all booking details and payment instructions',
          },
          {
            'icon': Icons.calendar_today,
            'title': 'Add to Calendar',
            'description':
                'Click the "Add to My Calendar" button above to download the event',
          },
          {
            'icon': Icons.payments_outlined,
            'title': 'Payment on Arrival',
            'description':
                'Bring payment with you - cash or card accepted at the property',
          },
          {
            'icon': Icons.directions,
            'title': 'Prepare for Your Stay',
            'description':
                'Check-in instructions will be sent 24h before arrival',
          },
        ];
        break;

      default:
        steps = [
          {
            'icon': Icons.email,
            'title': 'Check Your Email',
            'description': 'Confirmation email sent with all booking details',
          },
          {
            'icon': Icons.pending,
            'title': 'Awaiting Processing',
            'description': 'Your booking is being processed',
          },
        ];
    }

    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.l),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.m),
        decoration: BoxDecoration(
          color: getColor(
            MinimalistColors.backgroundSecondary,
            MinimalistColorsDark.backgroundSecondary,
          ),
          borderRadius: BorderTokens.circularMedium,
          border: Border.all(
            color: getColor(
              MinimalistColors.borderDefault,
              MinimalistColorsDark.borderDefault,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s Next?',
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeL,
                fontWeight: TypographyTokens.bold,
                color: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: SpacingTokens.m),
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
                          color: getColor(
                            MinimalistColors.success,
                            MinimalistColorsDark.success,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            step['icon'] as IconData,
                            color: getColor(
                              MinimalistColors.backgroundPrimary,
                              MinimalistColorsDark.backgroundPrimary,
                            ),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['title'] as String,
                              style: TextStyle(
                                fontSize: TypographyTokens.fontSizeM,
                                fontWeight: TypographyTokens.semiBold,
                                color: getColor(
                                  MinimalistColors.textPrimary,
                                  MinimalistColorsDark.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: SpacingTokens.xxs),
                            Text(
                              step['description'] as String,
                              style: TextStyle(
                                fontSize: TypographyTokens.fontSizeS,
                                color: getColor(
                                  MinimalistColors.textSecondary,
                                  MinimalistColorsDark.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: SpacingTokens.m),
                    Container(
                      margin: const EdgeInsets.only(left: 20),
                      width: 2,
                      height: 24,
                      color: getColor(
                        MinimalistColors.success,
                        MinimalistColorsDark.success,
                      ).withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: SpacingTokens.m),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Build bank transfer detail row with optional copy functionality
  Widget _buildBankTransferDetail(
    String label,
    String value, {
    bool copyable = false,
    bool highlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeS,
              fontWeight: TypographyTokens.semiBold,
              color: getColor(
                MinimalistColors.textSecondary,
                MinimalistColorsDark.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.s),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: highlight
                      ? const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.xs,
                          vertical: SpacingTokens.xxs,
                        )
                      : null,
                  decoration: highlight
                      ? BoxDecoration(
                          color: getColor(
                            MinimalistColors.statusAvailableBackground,
                            MinimalistColorsDark.statusAvailableBackground,
                          ),
                          borderRadius: BorderTokens.circularSmall,
                          border: Border.all(
                            color: getColor(
                              MinimalistColors.statusAvailableBorder,
                              MinimalistColorsDark.statusAvailableBorder,
                            ),
                          ),
                        )
                      : null,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeS,
                      fontWeight: highlight
                          ? TypographyTokens.bold
                          : TypographyTokens.medium,
                      color: highlight
                          ? getColor(
                              MinimalistColors.statusAvailableText,
                              MinimalistColorsDark.statusAvailableText,
                            )
                          : getColor(
                              MinimalistColors.textPrimary,
                              MinimalistColorsDark.textPrimary,
                            ),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              if (copyable) ...[
                const SizedBox(width: SpacingTokens.xs),
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    size: 16,
                    color: getColor(
                      MinimalistColors.textSecondary,
                      MinimalistColorsDark.textSecondary,
                    ),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$label copied to clipboard'),
                          backgroundColor: getColor(
                            MinimalistColors.statusAvailableBorder,
                            MinimalistColorsDark.statusAvailableBorder,
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  tooltip: 'Copy $label',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
