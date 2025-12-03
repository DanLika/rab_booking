import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../theme/minimalist_colors.dart';
import '../../../../../../shared/utils/validators/form_validators.dart';

/// Phone number input field with country-specific formatting and validation.
///
/// Extracted from booking_widget_screen.dart phone field section.
/// Used alongside CountryCodeDropdown for complete phone input.
///
/// Usage:
/// ```dart
/// Row(
///   children: [
///     CountryCodeDropdown(...),
///     SizedBox(width: SpacingTokens.s),
///     Expanded(
///       child: PhoneField(
///         controller: _phoneController,
///         isDarkMode: isDarkMode,
///         dialCode: _selectedCountry.dialCode,
///       ),
///     ),
///   ],
/// )
/// ```
class PhoneField extends StatelessWidget {
  /// Controller for the phone text field
  final TextEditingController controller;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Country dial code for formatting and validation (e.g., '+385')
  final String dialCode;

  const PhoneField({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.dialCode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return TextFormField(
      controller: controller,
      maxLength: 20, // Bug #60: Maximum field length validation
      keyboardType: TextInputType.phone,
      inputFormatters: [
        PhoneNumberFormatter(dialCode),
      ],
      style: TextStyle(
        color: colors.textPrimary,
      ),
      decoration: InputDecoration(
        counterText: '', // Hide character counter
        labelText: 'Phone Number *',
        hintText: '99 123 4567',
        labelStyle: TextStyle(
          color: colors.textSecondary,
        ),
        hintStyle: TextStyle(
          color: colors.textSecondary.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: colors.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderTokens.circularMedium,
          borderSide: BorderSide(
            color: colors.textSecondary,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderTokens.circularMedium,
          borderSide: BorderSide(
            color: colors.textSecondary,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderTokens.circularMedium,
          borderSide: BorderSide(
            color: colors.textPrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderTokens.circularMedium,
          borderSide: BorderSide(
            color: colors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderTokens.circularMedium,
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        errorStyle: TextStyle(
          color: colors.error,
          fontSize: 12,
        ),
        prefixIcon: Icon(
          Icons.phone_outlined,
          color: colors.textSecondary,
        ),
      ),
      // Real-time validation with country-specific rules
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        return PhoneValidator.validate(value, dialCode);
      },
    );
  }
}
