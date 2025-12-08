import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/services/email_notification_service.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../domain/models/widget_settings.dart';
import '../../../../../../shared/utils/ui/snackbar_helper.dart';
import '../../l10n/widget_translations.dart';

/// Card showing email confirmation status with resend functionality.
///
/// Displays email sent confirmation and provides option to resend
/// if booking and email config are available.
///
/// Usage:
/// ```dart
/// EmailConfirmationCard(
///   guestEmail: 'guest@example.com',
///   colors: ColorTokens.light,
///   booking: bookingModel,
///   emailConfig: emailConfig,
///   widgetSettings: settings,
///   propertyName: 'Beach Villa',
///   bookingReference: 'ABC123',
/// )
/// ```
class EmailConfirmationCard extends StatefulWidget {
  /// Guest email address
  final String guestEmail;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  /// Optional booking model for resend functionality
  final BookingModel? booking;

  /// Optional email config for resend functionality
  final EmailNotificationConfig? emailConfig;

  /// Optional widget settings for resend functionality
  final WidgetSettings? widgetSettings;

  /// Property name for email content
  final String propertyName;

  /// Booking reference for email content
  final String bookingReference;

  const EmailConfirmationCard({
    super.key,
    required this.guestEmail,
    required this.colors,
    this.booking,
    this.emailConfig,
    this.widgetSettings,
    required this.propertyName,
    required this.bookingReference,
  });

  @override
  State<EmailConfirmationCard> createState() => _EmailConfirmationCardState();
}

class _EmailConfirmationCardState extends State<EmailConfirmationCard> {
  bool _isResendingEmail = false;
  bool _emailResent = false;
  int _resendCount = 0;

  /// Maximum number of times a user can resend confirmation email
  static const int _maxResendAttempts = 5;

  Future<void> _resendConfirmationEmail(WidgetTranslations tr) async {
    if (widget.booking == null || widget.emailConfig == null) {
      SnackBarHelper.showError(context: context, message: tr.unableToResendEmail);
      return;
    }

    // Check rate limit - prevent spam
    if (_resendCount >= _maxResendAttempts) {
      SnackBarHelper.showWarning(context: context, message: tr.maxResendAttemptsReached);
      return;
    }

    // Only check if API key and from email are configured (not the 'enabled' flag)
    // The 'enabled' flag controls email verification on the booking form, not confirmation emails
    final config = widget.emailConfig!;
    if (config.resendApiKey == null || config.fromEmail == null) {
      SnackBarHelper.showWarning(context: context, message: tr.emailServiceNotConfigured);
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
        allowGuestCancellation: widget.widgetSettings?.allowGuestCancellation ?? false,
        cancellationDeadlineHours: widget.widgetSettings?.cancellationDeadlineHours,
        ownerEmail: widget.widgetSettings?.contactOptions.emailAddress,
        ownerPhone: widget.widgetSettings?.contactOptions.phoneNumber,
        customLogoUrl: widget.widgetSettings?.themeOptions?.customLogoUrl,
      );

      setState(() {
        _isResendingEmail = false;
        _emailResent = true;
        _resendCount++;
      });

      if (mounted) {
        SnackBarHelper.showSuccess(context: context, message: tr.confirmationEmailSentSuccessfully);
      }
    } catch (e) {
      setState(() {
        _isResendingEmail = false;
      });

      if (mounted) {
        SnackBarHelper.showError(
          context: context,
          message: tr.failedToSendEmail(e.toString()),
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final canResend = widget.emailConfig != null && widget.booking != null;
    final tr = WidgetTranslations.of(context);
    // Detect dark mode for better contrast
    final isDark = colors.backgroundPrimary.computeLuminance() < 0.5;
    final cardBackground = isDark ? colors.backgroundTertiary : colors.backgroundSecondary;
    final cardBorder = isDark ? colors.borderMedium : colors.borderDefault;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(color: cardBorder, width: isDark ? 1.5 : 1.0),
      ),
      child: Row(
        children: [
          Icon(Icons.email_outlined, color: colors.textPrimary),
          const SizedBox(width: SpacingTokens.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.confirmationEmailSentTitle,
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeM,
                    fontWeight: TypographyTokens.semiBold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xxs),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: tr.checkYourEmailAt,
                        style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
                      ),
                      TextSpan(
                        text: ' ${widget.guestEmail} ',
                        style: TextStyle(
                          fontSize: TypographyTokens.fontSizeS,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: tr.forBookingDetails,
                        style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (canResend) ...[
                  const SizedBox(height: SpacingTokens.s),
                  InkWell(
                    onTap: _isResendingEmail ? null : () => _resendConfirmationEmail(tr),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xxs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isResendingEmail)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: colors.textSecondary),
                            )
                          else
                            Icon(_emailResent ? Icons.check : Icons.refresh, size: 14, color: colors.textSecondary),
                          const SizedBox(width: SpacingTokens.xxs),
                          Text(
                            _emailResent ? tr.emailSent : tr.didntReceiveResendEmail,
                            style: TextStyle(
                              fontSize: TypographyTokens.fontSizeS,
                              color: colors.textSecondary,
                              decoration: TextDecoration.underline,
                              decorationColor: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
