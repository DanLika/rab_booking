import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../../shared/utils/ui/snackbar_helper.dart';
import '../../l10n/widget_translations.dart';

/// Card showing email confirmation status with resend functionality.
///
/// Displays email sent confirmation and provides option to resend
/// using Cloud Function (no owner API key required).
///
/// Usage:
/// ```dart
/// EmailConfirmationCard(
///   guestEmail: 'guest@example.com',
///   bookingReference: 'BK-2024-001234',
///   colors: ColorTokens.light,
/// )
/// ```
class EmailConfirmationCard extends ConsumerStatefulWidget {
  /// Guest email address
  final String guestEmail;

  /// Booking reference for Cloud Function verification
  final String bookingReference;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const EmailConfirmationCard({
    super.key,
    required this.guestEmail,
    required this.bookingReference,
    required this.colors,
  });

  @override
  ConsumerState<EmailConfirmationCard> createState() =>
      _EmailConfirmationCardState();
}

class _EmailConfirmationCardState extends ConsumerState<EmailConfirmationCard> {
  bool _isResendingEmail = false;
  bool _emailResent = false;
  int _resendCount = 0;

  /// Maximum number of times a user can resend confirmation email (client-side)
  /// Server also has rate limiting (3 per hour per booking)
  static const int _maxResendAttempts = 5;

  Future<void> _resendConfirmationEmail(WidgetTranslations tr) async {
    // Check if we have required data
    if (widget.guestEmail.isEmpty || widget.bookingReference.isEmpty) {
      SnackBarHelper.showError(
        context: context,
        message: tr.unableToResendEmail,
      );
      return;
    }

    // Check client-side rate limit
    if (_resendCount >= _maxResendAttempts) {
      SnackBarHelper.showWarning(
        context: context,
        message: tr.maxResendAttemptsReached,
      );
      return;
    }

    setState(() {
      _isResendingEmail = true;
    });

    try {
      // Call Cloud Function to resend email
      // Uses platform's Resend API key - no owner config needed
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('resendGuestBookingEmail');

      await callable.call<Map<String, dynamic>>({
        'bookingReference': widget.bookingReference,
        'guestEmail': widget.guestEmail,
      });

      setState(() {
        _isResendingEmail = false;
        _emailResent = true;
        _resendCount++;
      });

      if (mounted) {
        SnackBarHelper.showSuccess(
          context: context,
          message: tr.confirmationEmailSentSuccessfully,
        );
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _isResendingEmail = false;
      });

      if (mounted) {
        // Handle specific error codes
        final message = switch (e.code) {
          'resource-exhausted' => tr.maxResendAttemptsReached,
          'not-found' => tr.bookingNotFound,
          'permission-denied' => tr.emailMismatch,
          _ => tr.failedToSendEmail(e.message ?? 'Unknown error'),
        };
        SnackBarHelper.showError(
          context: context,
          message: message,
          duration: const Duration(seconds: 5),
        );
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
    final tr = WidgetTranslations.of(context, ref);
    // Enable resend if we have email and booking reference
    final canResend =
        widget.guestEmail.isNotEmpty && widget.bookingReference.isNotEmpty;
    // Detect dark mode for better contrast
    final isDark = colors.backgroundPrimary.computeLuminance() < 0.5;
    // Dark mode: pure black background matching parent, with visible border
    final cardBackground = isDark
        ? ColorTokens.pureBlack
        : colors.backgroundSecondary;
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
                // Bug #57 Fix: Add Semantics for accessibility
                Semantics(
                  label: tr.confirmationEmailSentTitle,
                  header: true,
                  child: Text(
                    tr.confirmationEmailSentTitle,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeM,
                      fontWeight: TypographyTokens.semiBold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: SpacingTokens.xxs),
                // Bug #54 Fix: Check for empty email string
                // Bug #57 Fix: Add Semantics for accessibility
                Semantics(
                  label: widget.guestEmail.isEmpty
                      ? '${tr.checkYourEmailAt} ${tr.forBookingDetails}'
                      : '${tr.checkYourEmailAt} ${widget.guestEmail} ${tr.forBookingDetails}',
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: tr.checkYourEmailAt,
                          style: TextStyle(
                            fontSize: TypographyTokens.fontSizeS,
                            color: colors.textSecondary,
                          ),
                        ),
                        if (widget.guestEmail.isEmpty)
                          TextSpan(
                            text: tr.forBookingDetails,
                            style: TextStyle(
                              fontSize: TypographyTokens.fontSizeS,
                              color: colors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else ...[
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
                            style: TextStyle(
                              fontSize: TypographyTokens.fontSizeS,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (canResend) ...[
                  const SizedBox(height: SpacingTokens.s),
                  // Bug #57 Fix: Add Semantics for accessibility
                  Semantics(
                    label: _emailResent
                        ? tr.emailSent
                        : tr.didntReceiveResendEmail,
                    button: true,
                    enabled: !_isResendingEmail,
                    child: InkWell(
                      onTap: _isResendingEmail
                          ? null
                          : () => _resendConfirmationEmail(tr),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: SpacingTokens.xxs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isResendingEmail)
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.textSecondary,
                                ),
                              )
                            else
                              Icon(
                                _emailResent ? Icons.check : Icons.refresh,
                                size: 14,
                                color: colors.textSecondary,
                              ),
                            const SizedBox(width: SpacingTokens.xxs),
                            Text(
                              _emailResent
                                  ? tr.emailSent
                                  : tr.didntReceiveResendEmail,
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
