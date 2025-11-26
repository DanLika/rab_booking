import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/theme_provider.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../../../core/services/email_notification_service.dart';
import '../../../../core/services/ical_generator.dart';
import '../../../../shared/models/booking_model.dart';
import '../../domain/models/widget_settings.dart';
import '../utils/snackbar_helper.dart';
import '../../utils/ics_download.dart';
import '../widgets/common/detail_row_widget.dart';
import '../widgets/common/info_card_widget.dart';

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
  paymentMethod; // 'stripe', 'bank_transfer', 'pay_on_arrival', 'pending'
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

  String _getConfirmationMessage() {
    switch (widget.paymentMethod) {
      case 'stripe':
        return 'Payment successful! Your booking is confirmed.';
      case 'bank_transfer':
        return 'Booking received! Please complete the bank transfer to confirm.';
      case 'pay_on_arrival':
        return 'Booking confirmed! You can pay at the property.';
      case 'pending':
        return 'Booking request sent! Waiting for owner approval.';
      default:
        return 'Your booking has been confirmed!';
    }
  }

  Widget _getConfirmationIcon() {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    switch (widget.paymentMethod) {
      case 'stripe':
        return Icon(Icons.check_circle, size: 80, color: colors.textPrimary);
      case 'bank_transfer':
        return Icon(Icons.schedule, size: 80, color: colors.textSecondary);
      case 'pay_on_arrival':
        return Icon(Icons.hotel, size: 80, color: colors.textPrimary);
      case 'pending':
        return Icon(Icons.pending, size: 80, color: colors.textSecondary);
      default:
        return Icon(Icons.check_circle, size: 80, color: colors.textPrimary);
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.bookingReference));
    if (mounted) {
      final isDarkMode = ref.read(themeProvider);
      SnackBarHelper.showSuccess(
        context: context,
        message: 'Booking reference copied to clipboard!',
        isDarkMode: isDarkMode,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _resendConfirmationEmail() async {
    final isDarkMode = ref.read(themeProvider);

    if (widget.booking == null || widget.emailConfig == null) {
      SnackBarHelper.showError(
        context: context,
        message: 'Unable to resend email - missing configuration',
        isDarkMode: isDarkMode,
      );
      return;
    }

    // Bug #15: Check if email service is enabled and configured
    if (widget.emailConfig!.enabled != true ||
        widget.emailConfig!.isConfigured != true) {
      SnackBarHelper.showWarning(
        context: context,
        message:
            'Email service is not enabled or configured. Please contact the property owner.',
        isDarkMode: isDarkMode,
        duration: const Duration(seconds: 4),
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
        SnackBarHelper.showSuccess(
          context: context,
          message: 'Confirmation email sent successfully!',
          isDarkMode: isDarkMode,
        );
      }
    } catch (e) {
      setState(() {
        _isResendingEmail = false;
      });

      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: 'Failed to send email: $e',
          isDarkMode: isDarkMode,
          duration: const Duration(seconds: 5),
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
        final isDarkMode = ref.read(themeProvider);
        SnackBarHelper.showSuccess(
          context: context,
          message: 'Calendar event downloaded! Check your downloads folder.',
          isDarkMode: isDarkMode,
        );
      }
    } catch (e) {
      // Error handling
      if (mounted) {
        final isDarkMode = ref.read(themeProvider);
        SnackBarHelper.showError(
          context: context,
          message: 'Failed to generate calendar file: $e',
          isDarkMode: isDarkMode,
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingIcs = false);
      }
    }
  }

  /// Downloads/shares ICS file using platform-specific implementation
  ///
  /// Web: Triggers browser download via Blob + Anchor element
  /// Mobile/Desktop: Opens native share sheet via share_plus
  ///
  /// The implementation is automatically selected at compile-time
  /// using conditional imports (see lib/features/widget/utils/ics_download.dart)
  Future<void> _downloadIcsFile(String content, String filename) async {
    try {
      // Platform-specific implementation selected automatically at compile-time
      await downloadIcsFile(content, filename);
    } catch (e) {
      // Show error to user if download/share fails
      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: 'Failed to download calendar file: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              // Custom header with centered title and back button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.m,
                  vertical: SpacingTokens.s,
                ),
                child: Row(
                  children: [
                    // Back button (aligned to the left)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: colors.textPrimary,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    // Centered title with Expanded to take remaining space
                    Expanded(
                      child: Center(
                        child: Text(
                          'Booking Confirmation',
                          style: TextStyle(
                            fontSize: TypographyTokens.fontSizeXL,
                            fontWeight: TypographyTokens.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    // Invisible spacer to balance the back button width
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // Divider
              Divider(
                height: 1,
                thickness: 1,
                color: colors.borderDefault,
              ),
              // Content
              Expanded(
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
                      color: colors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: SpacingTokens.m),

                  // Bug #40: Warning if payment still pending after Stripe webhook timeout
                  if (widget.paymentMethod == 'stripe' &&
                      widget.booking != null &&
                      (widget.booking!.paymentStatus == 'pending' ||
                          widget.booking!.status.value == 'pending')) ...[
                    InfoCardWidget(
                      title: 'Payment Verification in Progress',
                      message:
                          'Your payment was successful, but we\'re still verifying it with the payment provider. You will receive a confirmation email within a few minutes. If you don\'t receive it, please contact the property owner.',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: SpacingTokens.m),
                  ],

                  // Booking reference card
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.m),
                    decoration: BoxDecoration(
                      color: colors.backgroundSecondary,
                      borderRadius: BorderTokens.circularMedium,
                      border: Border.all(
                        color: colors.borderDefault,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Booking Reference',
                          style: TextStyle(
                            fontSize: TypographyTokens.fontSizeS,
                            color: colors.textSecondary,
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
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: SpacingTokens.s),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: colors.textSecondary,
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
                      color: colors.backgroundSecondary,
                      borderRadius: BorderTokens.circularMedium,
                      border: Border.all(
                        color: colors.borderDefault,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.mail_outline,
                          color: colors.textSecondary,
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
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: SpacingTokens.xxs),
                              Text(
                                'Check your inbox for booking confirmation. If you don\'t see it within a few minutes, please check your spam or junk folder.',
                                style: TextStyle(
                                  fontSize: TypographyTokens.fontSizeS,
                                  color: colors.textSecondary,
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
                      color: colors.backgroundSecondary,
                      borderRadius: BorderTokens.circularMedium,
                      border: Border.all(
                        color: colors.borderDefault,
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
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.m),
                        DetailRowWidget(
                          label: 'Property',
                          value: widget.unitName ?? widget.propertyName,
                          isDarkMode: isDarkMode,
                          hasPadding: true,
                          valueFontWeight: FontWeight.w400,
                        ),
                        DetailRowWidget(
                          label: 'Guest',
                          value: widget.guestName,
                          isDarkMode: isDarkMode,
                          hasPadding: true,
                          valueFontWeight: FontWeight.w400,
                        ),
                        DetailRowWidget(
                          label: 'Email',
                          value: widget.guestEmail,
                          isDarkMode: isDarkMode,
                          hasPadding: true,
                          valueFontWeight: FontWeight.w400,
                        ),
                        const SizedBox(height: SpacingTokens.s),
                        DetailRowWidget(
                          label: 'Check-in',
                          value: DateFormat(
                            'EEEE, MMM dd, yyyy',
                          ).format(widget.checkIn),
                          isDarkMode: isDarkMode,
                          hasPadding: true,
                          valueFontWeight: FontWeight.w400,
                        ),
                        DetailRowWidget(
                          label: 'Check-out',
                          value: DateFormat(
                            'EEEE, MMM dd, yyyy',
                          ).format(widget.checkOut),
                          isDarkMode: isDarkMode,
                          hasPadding: true,
                          valueFontWeight: FontWeight.w400,
                        ),
                        DetailRowWidget(
                          label: 'Duration',
                          value: '${widget.nights} ${widget.nights == 1 ? 'night' : 'nights'}',
                          isDarkMode: isDarkMode,
                          hasPadding: true,
                          valueFontWeight: FontWeight.w400,
                        ),
                        DetailRowWidget(
                          label: 'Guests',
                          value: '${widget.guests} ${widget.guests == 1 ? 'guest' : 'guests'}',
                          isDarkMode: isDarkMode,
                          hasPadding: true,
                          valueFontWeight: FontWeight.w400,
                        ),
                        const SizedBox(height: SpacingTokens.s),
                        DetailRowWidget(
                          label: 'Total Price',
                          value: '€${widget.totalPrice.toStringAsFixed(2)}',
                          isDarkMode: isDarkMode,
                          hasPadding: true,
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
                          backgroundColor: colors.backgroundSecondary,
                          foregroundColor: colors.textPrimary,
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
                  if (widget.paymentMethod == 'bank_transfer' &&
                      widget
                              .widgetSettings
                              ?.bankTransferConfig
                              ?.hasCompleteDetails ==
                          true)
                    Container(
                      margin: const EdgeInsets.only(bottom: SpacingTokens.l),
                      padding: const EdgeInsets.all(SpacingTokens.m),
                      decoration: BoxDecoration(
                        color: colors.backgroundSecondary,
                        borderRadius: BorderTokens.circularMedium,
                        border: Border.all(
                          color: colors.borderDefault,
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
                                color: colors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(width: SpacingTokens.s),
                              Text(
                                'Bank Transfer Instructions',
                                style: TextStyle(
                                  fontSize: TypographyTokens.fontSizeL,
                                  fontWeight: TypographyTokens.bold,
                                  color: colors.textPrimary,
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
                              color: colors.backgroundSecondary,
                              borderRadius: BorderTokens.circularSmall,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(width: SpacingTokens.xs),
                                Expanded(
                                  child: Text(
                                    'Please complete the transfer within 3 days and include the reference number.',
                                    style: TextStyle(
                                      fontSize: TypographyTokens.fontSizeS,
                                      color: colors.textSecondary,
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
                      color: colors.backgroundSecondary,
                      borderRadius: BorderTokens.circularMedium,
                      border: Border.all(
                        color: colors.borderDefault,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: colors.textPrimary,
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
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: SpacingTokens.xxs),
                              Text(
                                'Check your email at ${widget.guestEmail} for booking details.',
                                style: TextStyle(
                                  fontSize: TypographyTokens.fontSizeS,
                                  color: colors.textSecondary,
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
                                    foregroundColor: colors.textPrimary,
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
                        backgroundColor: colors.buttonPrimary,
                        foregroundColor: colors.buttonPrimaryText,
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
                      color: colors.textSecondary,
                    ),
                  ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build cancellation policy widget
  Widget _buildCancellationPolicy() {
    final isDarkMode = ref.read(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final deadlineHours = widget.widgetSettings!.cancellationDeadlineHours!;

    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.l),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.m),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderTokens.circularMedium,
          border: Border.all(
            color: colors.borderDefault,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_available,
                  color: colors.textPrimary,
                  size: 24,
                ),
                const SizedBox(width: SpacingTokens.s),
                Text(
                  'Cancellation Policy',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeL,
                    fontWeight: TypographyTokens.bold,
                    color: colors.textPrimary,
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
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              'To cancel your booking:',
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: colors.textSecondary,
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
    final isDarkMode = ref.read(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

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
              color: colors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build next steps section based on payment method
  Widget _buildNextSteps() {
    final isDarkMode = ref.read(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
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

      case 'bank_transfer':
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

      case 'pay_on_arrival':
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
          color: colors.backgroundSecondary,
          borderRadius: BorderTokens.circularMedium,
          border: Border.all(
            color: colors.borderDefault,
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
                color: colors.textPrimary,
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
                          color: colors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            step['icon'] as IconData,
                            color: colors.backgroundPrimary,
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
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: SpacingTokens.xxs),
                            Text(
                              step['description'] as String,
                              style: TextStyle(
                                fontSize: TypographyTokens.fontSizeS,
                                color: colors.textSecondary,
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
                      color: colors.textPrimary.withOpacity(0.3),
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
    final isDarkMode = ref.read(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

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
              color: colors.textSecondary,
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
                          color: colors.backgroundSecondary,
                          borderRadius: BorderTokens.circularSmall,
                          border: Border.all(
                            color: colors.borderDefault,
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
                          ? colors.textPrimary
                          : colors.textPrimary,
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
                    color: colors.textSecondary,
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (mounted) {
                      final isDarkMode = ref.read(themeProvider);
                      SnackBarHelper.showSuccess(
                        context: context,
                        message: '$label copied to clipboard',
                        isDarkMode: isDarkMode,
                        duration: const Duration(seconds: 2),
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
