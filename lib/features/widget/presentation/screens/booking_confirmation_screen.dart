import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../mixins/theme_detection_mixin.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../../../shared/models/booking_model.dart';
import '../../domain/models/widget_settings.dart';
import '../widgets/common/info_card_widget.dart';
import '../widgets/confirmation/confirmation_header.dart';
import '../widgets/confirmation/booking_reference_card.dart';
import '../widgets/confirmation/email_spam_warning_card.dart';
import '../widgets/confirmation/booking_summary_card.dart';
import '../widgets/confirmation/calendar_export_button.dart';
import '../widgets/confirmation/bank_transfer_instructions_card.dart';
import '../widgets/confirmation/email_confirmation_card.dart';
import '../widgets/confirmation/cancellation_policy_section.dart';
import '../widgets/confirmation/next_steps_section.dart';

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
  final String paymentMethod;
  final BookingModel? booking;
  final EmailNotificationConfig? emailConfig;
  final WidgetSettings? widgetSettings;
  /// Property ID for clean URL redirect when closing confirmation
  final String? propertyId;
  /// Unit ID for clean URL redirect when closing confirmation
  final String? unitId;
  /// Optional callback for state-based close (direct bookings)
  /// If provided, this is called instead of URL navigation
  final VoidCallback? onClose;

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
    this.propertyId,
    this.unitId,
    this.onClose,
  });

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen>
    with SingleTickerProviderStateMixin, ThemeDetectionMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Detect system theme on first load (only once to preserve manual toggle)
    detectSystemTheme();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Navigate back to calendar
  /// Uses Navigator.pop() which works for:
  /// - Direct bookings (Pay on Arrival, Bank Transfer) - pushed via Navigator
  /// - Stripe returns - also pushed via Navigator
  /// The parent widget handles form reset and URL cleanup after pop
  void _navigateToCleanCalendar() {
    debugPrint('[ConfirmationScreen] _navigateToCleanCalendar called');
    debugPrint('[ConfirmationScreen] onClose=${widget.onClose != null}');

    // Priority 1: Custom close callback (if provided)
    if (widget.onClose != null) {
      debugPrint('[ConfirmationScreen] Using custom onClose callback');
      widget.onClose!();
      return;
    }

    // Priority 2: Navigator.pop() - works for all Navigator.push scenarios
    debugPrint('[ConfirmationScreen] Using Navigator.pop()');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    // Use pure black background for dark theme in widget
    final backgroundColor =
        isDarkMode ? ColorTokens.pureBlack : colors.backgroundPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              // Custom header with centered title and back button
              _buildHeader(colors),
              Divider(height: 1, thickness: 1, color: colors.borderDefault),
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
                          // Animated header with icon and message
                          ConfirmationHeader(
                            paymentMethod: widget.paymentMethod,
                            colors: colors,
                            scaleAnimation: _scaleAnimation,
                            customLogoUrl: widget
                                .widgetSettings?.themeOptions?.customLogoUrl,
                          ),

                          const SizedBox(height: SpacingTokens.m),

                          // Payment verification warning (Stripe pending)
                          if (_shouldShowPaymentVerificationWarning)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: SpacingTokens.m),
                              child: InfoCardWidget(
                                title: 'Payment Verification in Progress',
                                message:
                                    'Your payment was successful, but we\'re still verifying it with the payment provider. You will receive a confirmation email within a few minutes. If you don\'t receive it, please contact the property owner.',
                                isDarkMode: isDarkMode,
                              ),
                            ),

                          // Booking reference card
                          BookingReferenceCard(
                            bookingReference: widget.bookingReference,
                            colors: colors,
                          ),

                          const SizedBox(height: SpacingTokens.m),

                          // Email spam folder warning
                          EmailSpamWarningCard(colors: colors),

                          const SizedBox(height: SpacingTokens.l),

                          // Booking summary card
                          BookingSummaryCard(
                            propertyName: widget.propertyName,
                            unitName: widget.unitName,
                            guestName: widget.guestName,
                            guestEmail: widget.guestEmail,
                            checkIn: widget.checkIn,
                            checkOut: widget.checkOut,
                            nights: widget.nights,
                            guests: widget.guests,
                            totalPrice: widget.totalPrice,
                            isDarkMode: isDarkMode,
                            colors: colors,
                          ),

                          const SizedBox(height: SpacingTokens.l),

                          // Calendar export button
                          if (widget.booking != null &&
                              (widget.widgetSettings?.icalExportEnabled ??
                                  false))
                            CalendarExportButton(
                              booking: widget.booking!,
                              unitName: widget.unitName ?? widget.propertyName,
                              bookingReference: widget.bookingReference,
                              colors: colors,
                            ),

                          // Bank transfer instructions
                          if (widget.paymentMethod == 'bank_transfer' &&
                              widget.widgetSettings?.bankTransferConfig
                                      ?.hasCompleteDetails ==
                                  true)
                            BankTransferInstructionsCard(
                              bankConfig:
                                  widget.widgetSettings!.bankTransferConfig!,
                              bookingReference: widget.bookingReference,
                              colors: colors,
                            ),

                          // Email confirmation with resend option
                          EmailConfirmationCard(
                            guestEmail: widget.guestEmail,
                            colors: colors,
                            booking: widget.booking,
                            emailConfig: widget.emailConfig,
                            widgetSettings: widget.widgetSettings,
                            propertyName: widget.propertyName,
                            bookingReference: widget.bookingReference,
                          ),

                          // Cancellation policy
                          if (widget.widgetSettings?.allowGuestCancellation ==
                                  true &&
                              widget.widgetSettings?.cancellationDeadlineHours !=
                                  null)
                            CancellationPolicySection(
                              isDarkMode: isDarkMode,
                              deadlineHours: widget
                                  .widgetSettings!.cancellationDeadlineHours!,
                              bookingReference: widget.bookingReference,
                              fromEmail: widget.emailConfig?.fromEmail,
                            ),

                          // Next steps section
                          NextStepsSection(
                            isDarkMode: isDarkMode,
                            paymentMethod: widget.paymentMethod,
                          ),

                          const SizedBox(height: SpacingTokens.xl),

                          // Close button
                          _buildCloseButton(colors, isDark: isDarkMode),

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

  bool get _shouldShowPaymentVerificationWarning {
    if (widget.paymentMethod != 'stripe' || widget.booking == null) {
      return false;
    }
    // Defensive null checks for payment status and booking status
    final paymentStatus = widget.booking!.paymentStatus;
    final bookingStatus = widget.booking!.status.value;
    return paymentStatus == 'pending' || bookingStatus == 'pending';
  }

  Widget _buildHeader(WidgetColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.m,
        vertical: SpacingTokens.s,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: _navigateToCleanCalendar,
          ),
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
          const SizedBox(width: 48), // Balance back button
        ],
      ),
    );
  }

  Widget _buildCloseButton(WidgetColorScheme colors, {required bool isDark}) {
    // Use white button with black text for dark theme
    final buttonBg = isDark ? ColorTokens.pureWhite : colors.buttonPrimary;
    final buttonText = isDark ? ColorTokens.pureBlack : colors.buttonPrimaryText;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _navigateToCleanCalendar,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBg,
          foregroundColor: buttonText,
          padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
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
    );
  }
}
