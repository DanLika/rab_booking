import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/services/email_notification_service.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../domain/models/widget_settings.dart';
import '../../../../../../shared/utils/ui/snackbar_helper.dart';

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

  Future<void> _resendConfirmationEmail() async {
    if (widget.booking == null || widget.emailConfig == null) {
      SnackBarHelper.showError(
        context: context,
        message: 'Unable to resend email - missing configuration',
      );
      return;
    }

    // Check if email service is enabled and configured
    if (widget.emailConfig!.enabled != true ||
        widget.emailConfig!.isConfigured != true) {
      SnackBarHelper.showWarning(
        context: context,
        message:
            'Email service is not enabled or configured. Please contact the property owner.',
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
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final canResend = widget.emailConfig != null && widget.booking != null;

    return Container(
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
                if (canResend) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  TextButton.icon(
                    onPressed:
                        _isResendingEmail ? null : _resendConfirmationEmail,
                    icon: _isResendingEmail
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            _emailResent ? Icons.check : Icons.refresh,
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
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
