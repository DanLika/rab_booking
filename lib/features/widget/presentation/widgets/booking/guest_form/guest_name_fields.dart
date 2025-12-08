import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../l10n/widget_translations.dart';
import '../../../theme/minimalist_colors.dart';
import '../../../utils/widget_input_decoration_helper.dart';
import '../../../../../../shared/utils/validators/form_validators.dart';

/// Row containing first name and last name text fields.
///
/// Extracted from booking_widget_screen.dart name fields section.
/// Displays two equally sized text fields side by side.
///
/// Usage:
/// ```dart
/// GuestNameFields(
///   firstNameController: _firstNameController,
///   lastNameController: _lastNameController,
///   isDarkMode: isDarkMode,
/// )
/// ```
class GuestNameFields extends ConsumerWidget {
  /// Controller for the first name text field
  final TextEditingController firstNameController;

  /// Controller for the last name text field
  final TextEditingController lastNameController;

  /// Whether dark mode is active
  final bool isDarkMode;

  const GuestNameFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First Name field
        Expanded(
          child: TextFormField(
            controller: firstNameController,
            maxLength: 50,
            style: TextStyle(color: colors.textPrimary),
            decoration: WidgetInputDecorationHelper.buildDecoration(
              labelText: WidgetTranslations.of(context, ref).labelFirstName,
              hintText: 'John',
              prefixIcon: Icon(Icons.person_outline, color: colors.textPrimary),
              isDarkMode: isDarkMode,
              isDense: true,
              errorMaxLines: 1,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: FirstNameValidator.validate,
          ),
        ),
        const SizedBox(width: SpacingTokens.m),
        // Last Name field
        Expanded(
          child: TextFormField(
            controller: lastNameController,
            maxLength: 50,
            style: TextStyle(color: colors.textPrimary),
            decoration: WidgetInputDecorationHelper.buildDecoration(
              labelText: WidgetTranslations.of(context, ref).labelLastName,
              hintText: 'Doe',
              isDarkMode: isDarkMode,
              isDense: true,
              errorMaxLines: 1,
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: LastNameValidator.validate,
          ),
        ),
      ],
    );
  }
}
