import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../l10n/widget_translations.dart';
import '../../../theme/minimalist_colors.dart';
import '../../../utils/widget_input_decoration_helper.dart';
import '../../../../../../shared/utils/validators/form_validators.dart';

/// Email field with optional verification button.
///
/// Supports both simple email input and email with verification flow.
class EmailFieldWithVerification extends ConsumerWidget {
  final TextEditingController controller;
  final bool isDarkMode;
  final bool requireVerification;
  final bool emailVerified;
  final bool isLoading;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onVerifyPressed;

  const EmailFieldWithVerification({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.requireVerification,
    required this.emailVerified,
    this.isLoading = false,
    required this.onEmailChanged,
    required this.onVerifyPressed,
  });

  static const _verifyButtonWidth = 100.0;
  static const _verifyButtonHeight = 50.0;
  static const _successContainerSize = 50.0;
  static const _maxEmailLength = 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final tr = WidgetTranslations.of(context, ref);

    final emailField = _buildEmailField(colors, tr);

    if (!requireVerification) {
      return emailField;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: emailField),
        const SizedBox(width: SpacingTokens.m),
        _buildVerificationStatus(colors, tr),
      ],
    );
  }

  Widget _buildEmailField(
    MinimalistColorSchemeAdapter colors,
    WidgetTranslations tr,
  ) {
    return TextFormField(
      controller: controller,
      maxLength: _maxEmailLength,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: colors.textPrimary),
      scrollPadding: const EdgeInsets.all(150.0),
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

  Widget _buildVerificationStatus(
    MinimalistColorSchemeAdapter colors,
    WidgetTranslations tr,
  ) {
    if (emailVerified) {
      return Container(
        width: _successContainerSize,
        height: _successContainerSize,
        decoration: BoxDecoration(
          color: colors.success.withValues(alpha: 0.1),
          borderRadius: BorderTokens.circularMedium,
          border: Border.all(color: colors.success, width: 1.5),
        ),
        child: Center(
          child: Icon(Icons.verified, color: colors.success, size: 24),
        ),
      );
    }

    return SizedBox(
      width: _verifyButtonWidth,
      height: _verifyButtonHeight,
      child: ElevatedButton(
        // Bug #33 Fix: Use null instead of empty function to properly disable button
        onPressed: isLoading ? null : onVerifyPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.textPrimary,
          foregroundColor: colors.backgroundPrimary,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderTokens.circularMedium,
          ),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colors.backgroundPrimary,
                    ),
                  ),
                ),
              )
            : Center(child: Text(tr.verifyEmail, textAlign: TextAlign.center)),
      ),
    );
  }
}
