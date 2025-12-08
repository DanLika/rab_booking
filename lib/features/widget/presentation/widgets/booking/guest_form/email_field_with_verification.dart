import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../../core/localization/error_messages.dart';
import '../../../l10n/widget_translations.dart';
import '../../../theme/minimalist_colors.dart';
import '../../../utils/widget_input_decoration_helper.dart';
import '../../../../../../shared/utils/validators/form_validators.dart';

/// Email field with optional verification button.
///
/// Extracted from booking_widget_screen.dart _buildEmailFieldWithVerification method.
/// Supports both simple email input and email with verification flow.
///
/// Usage:
/// ```dart
/// // Simple email field (no verification)
/// EmailFieldWithVerification(
///   controller: _emailController,
///   isDarkMode: isDarkMode,
///   requireVerification: false,
///   emailVerified: false,
///   onEmailChanged: (value) {},
///   onVerifyPressed: () {},
/// )
///
/// // With verification
/// EmailFieldWithVerification(
///   controller: _emailController,
///   isDarkMode: isDarkMode,
///   requireVerification: true,
///   emailVerified: _emailVerified,
///   onEmailChanged: (value) {
///     if (_emailVerified) setState(() => _emailVerified = false);
///   },
///   onVerifyPressed: _openVerificationDialog,
/// )
/// ```
class EmailFieldWithVerification extends ConsumerWidget {
  /// Controller for the email text field
  final TextEditingController controller;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Whether email verification is required
  final bool requireVerification;

  /// Whether the email has been verified
  final bool emailVerified;

  /// Callback when email text changes
  final ValueChanged<String> onEmailChanged;

  /// Callback when verify button is pressed
  final VoidCallback onVerifyPressed;

  const EmailFieldWithVerification({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.requireVerification,
    required this.emailVerified,
    required this.onEmailChanged,
    required this.onVerifyPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    final tr = WidgetTranslations.of(context, ref);

    if (!requireVerification) {
      // Standard email field without verification
      return TextFormField(
        controller: controller,
        maxLength: 100,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(color: colors.textPrimary),
        decoration: WidgetInputDecorationHelper.buildDecoration(
          labelText: tr.labelEmail,
          hintText: 'john@example.com',
          prefixIcon: Icon(Icons.email_outlined, color: colors.textPrimary),
          isDarkMode: isDarkMode,
          isDense: true,
          errorMaxLines: 1,
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: EmailValidator.validate,
        onChanged: onEmailChanged,
      );
    }

    // Email field with verification button
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            maxLength: 100,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: colors.textPrimary),
            decoration: WidgetInputDecorationHelper.buildDecoration(
              labelText: tr.labelEmail,
              hintText: 'john@example.com',
              prefixIcon: Icon(Icons.email_outlined, color: colors.textPrimary),
              isDarkMode: isDarkMode,
              isDense: true,
              errorMaxLines: 1,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: EmailValidator.validate,
            onChanged: onEmailChanged,
          ),
        ),
        const SizedBox(width: SpacingTokens.m),
        // Verification status/button
        if (emailVerified)
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.1),
              borderRadius: BorderTokens.circularMedium,
              border: Border.all(color: colors.success, width: 1.5),
            ),
            child: Center(child: Icon(Icons.verified, color: colors.success, size: 24)),
          )
        else
          SizedBox(
            width: 100,
            height: 44,
            child: ElevatedButton(
              onPressed: onVerifyPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.textPrimary,
                foregroundColor: colors.backgroundPrimary,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderTokens.circularMedium),
              ),
              child: const Text(ErrorMessages.verifyButton),
            ),
          ),
      ],
    );
  }
}
