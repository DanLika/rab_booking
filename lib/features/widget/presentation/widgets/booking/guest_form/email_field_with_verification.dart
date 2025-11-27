import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../theme/minimalist_colors.dart';
import '../../../../../../shared/utils/validators/form_validators.dart';
import '../../common/theme_colors_helper.dart';

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
class EmailFieldWithVerification extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);

    if (!requireVerification) {
      // Standard email field without verification
      return TextFormField(
        controller: controller,
        maxLength: 100, // Bug #60: Maximum field length validation
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(
          color: getColor(
            MinimalistColors.textPrimary,
            MinimalistColorsDark.textPrimary,
          ),
        ),
        decoration: InputDecoration(
          counterText: '', // Hide character counter
          labelText: 'Email *',
          hintText: 'john@example.com',
          labelStyle: TextStyle(
            color: getColor(
              MinimalistColors.textPrimary,
              MinimalistColorsDark.textPrimary,
            ),
          ),
          hintStyle: TextStyle(
            color: getColor(
              MinimalistColors.textSecondary,
              MinimalistColorsDark.textSecondary,
            ),
          ),
          filled: true,
          fillColor: getColor(
            MinimalistColors.backgroundSecondary,
            MinimalistColorsDark.backgroundSecondary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderTokens.circularMedium,
            borderSide: BorderSide(
              color: getColor(
                MinimalistColors.textSecondary,
                MinimalistColorsDark.textSecondary,
              ),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderTokens.circularMedium,
            borderSide: BorderSide(
              color: getColor(
                MinimalistColors.textSecondary,
                MinimalistColorsDark.textSecondary,
              ),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderTokens.circularMedium,
            borderSide: BorderSide(
              color: getColor(
                MinimalistColors.textPrimary,
                MinimalistColorsDark.textPrimary,
              ),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderTokens.circularMedium,
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderTokens.circularMedium,
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          errorStyle: const TextStyle(
            color: Colors.red,
            fontSize: 12,
            height: 1.0,
          ),
          errorMaxLines: 1,
          prefixIcon: Icon(
            Icons.email_outlined,
            color: getColor(
              MinimalistColors.textPrimary,
              MinimalistColorsDark.textPrimary,
            ),
          ),
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
            maxLength: 100, // Bug #60: Maximum field length validation
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: getColor(
                MinimalistColors.textPrimary,
                MinimalistColorsDark.textPrimary,
              ),
            ),
            decoration: InputDecoration(
              counterText: '', // Hide character counter
              labelText: 'Email *',
              hintText: 'john@example.com',
              labelStyle: TextStyle(
                color: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
              ),
              hintStyle: TextStyle(
                color: getColor(
                  MinimalistColors.textSecondary,
                  MinimalistColorsDark.textSecondary,
                ),
              ),
              filled: true,
              fillColor: getColor(
                MinimalistColors.backgroundSecondary,
                MinimalistColorsDark.backgroundSecondary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
                borderSide: BorderSide(
                  color: getColor(
                    MinimalistColors.textSecondary,
                    MinimalistColorsDark.textSecondary,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
                borderSide: BorderSide(
                  color: getColor(
                    MinimalistColors.textSecondary,
                    MinimalistColorsDark.textSecondary,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
                borderSide: BorderSide(
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              errorStyle: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                height: 1.0,
              ),
              errorMaxLines: 1,
              prefixIcon: Icon(
                Icons.email_outlined,
                color: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
              ),
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
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: MinimalistColors.success.withValues(alpha: 0.1),
              borderRadius: BorderTokens.circularMedium,
              border: Border.all(color: MinimalistColors.success, width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.verified,
                color: MinimalistColors.success,
                size: 24,
              ),
            ),
          )
        else
          SizedBox(
            width: 100,
            height: 44,
            child: ElevatedButton(
              onPressed: onVerifyPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
                foregroundColor: getColor(
                  MinimalistColors.backgroundPrimary,
                  MinimalistColorsDark.backgroundPrimary,
                ),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderTokens.circularMedium,
                ),
              ),
              child: const Text('Verify'),
            ),
          ),
      ],
    );
  }
}
