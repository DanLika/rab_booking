import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../l10n/widget_translations.dart';
import '../../../theme/minimalist_colors.dart';
import '../../../utils/widget_input_decoration_helper.dart';
import '../../../../../../shared/utils/validators/form_validators.dart';

/// Row containing first name and last name text fields.
///
/// Displays two equally sized text fields side by side.
class GuestNameFields extends ConsumerWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final bool isDarkMode;

  const GuestNameFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.isDarkMode,
  });

  static const _maxNameLength = 50;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final tr = WidgetTranslations.of(context, ref);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildNameField(
            controller: firstNameController,
            labelText: tr.labelFirstName,
            hintText: 'John',
            showIcon: true,
            colors: colors,
            validator: FirstNameValidator.validate,
          ),
        ),
        const SizedBox(width: SpacingTokens.m),
        Expanded(
          child: _buildNameField(
            controller: lastNameController,
            labelText: tr.labelLastName,
            hintText: 'Doe',
            showIcon: false,
            colors: colors,
            validator: LastNameValidator.validate,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required bool showIcon,
    required MinimalistColorSchemeAdapter colors,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: _maxNameLength,
      style: TextStyle(color: colors.textPrimary),
      decoration: WidgetInputDecorationHelper.buildDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: showIcon
            ? Icon(Icons.person_outline, color: colors.textPrimary)
            : null,
        isDarkMode: isDarkMode,
        isDense: true,
        errorMaxLines: 1,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
    );
  }
}
