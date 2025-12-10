import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/widget_translations.dart';
import '../../../theme/minimalist_colors.dart';
import '../../../utils/widget_input_decoration_helper.dart';
import '../../../../../../shared/utils/validators/form_validators.dart';

/// Phone number input field with country-specific formatting and validation.
///
/// Used alongside CountryCodeDropdown for complete phone input.
class PhoneField extends ConsumerWidget {
  final TextEditingController controller;
  final bool isDarkMode;

  /// Country dial code for formatting and validation (e.g., '+385')
  final String dialCode;

  const PhoneField({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.dialCode,
  });

  static const _maxLength = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final tr = WidgetTranslations.of(context, ref);

    return TextFormField(
      controller: controller,
      maxLength: _maxLength,
      keyboardType: TextInputType.phone,
      inputFormatters: [PhoneNumberFormatter(dialCode)],
      style: TextStyle(color: colors.textPrimary),
      decoration: WidgetInputDecorationHelper.buildDecoration(
        labelText: tr.labelPhone,
        hintText: '99 123 4567',
        prefixIcon: Icon(Icons.phone_outlined, color: colors.textSecondary),
        isDarkMode: isDarkMode,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) => PhoneValidator.validate(value, dialCode),
    );
  }
}
