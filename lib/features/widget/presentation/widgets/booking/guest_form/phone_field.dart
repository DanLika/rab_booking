import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../theme/minimalist_colors.dart';
import '../../../utils/widget_input_decoration_helper.dart';
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

  const PhoneField({super.key, required this.controller, required this.isDarkMode, required this.dialCode});

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return TextFormField(
      controller: controller,
      maxLength: 20,
      keyboardType: TextInputType.phone,
      inputFormatters: [PhoneNumberFormatter(dialCode)],
      style: TextStyle(color: colors.textPrimary),
      decoration: WidgetInputDecorationHelper.buildDecoration(
        labelText: 'Phone Number *',
        hintText: '99 123 4567',
        prefixIcon: Icon(Icons.phone_outlined, color: colors.textSecondary),
        isDarkMode: isDarkMode,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) => PhoneValidator.validate(value, dialCode),
    );
  }
}
