import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../theme/minimalist_colors.dart';
import '../../../../../../shared/utils/validators/form_validators.dart';
import '../../common/theme_colors_helper.dart';

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
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);

    return TextFormField(
      controller: controller,
      maxLength: 20, // Bug #60: Maximum field length validation
      keyboardType: TextInputType.phone,
      inputFormatters: [
        PhoneNumberFormatter(dialCode),
      ],
      style: TextStyle(
        color: getColor(
          MinimalistColors.textPrimary,
          MinimalistColorsDark.textPrimary,
        ),
      ),
      decoration: InputDecoration(
        counterText: '', // Hide character counter
        labelText: 'Phone Number *',
        hintText: '99 123 4567',
        labelStyle: TextStyle(
          color: getColor(
            MinimalistColors.textSecondary,
            MinimalistColorsDark.textSecondary,
          ),
        ),
        hintStyle: TextStyle(
          color: getColor(
            MinimalistColors.textSecondary,
            MinimalistColorsDark.textSecondary,
          ).withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
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
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderTokens.circularMedium,
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
        ),
        prefixIcon: Icon(
          Icons.phone_outlined,
          color: getColor(
            MinimalistColors.textSecondary,
            MinimalistColorsDark.textSecondary,
          ),
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
