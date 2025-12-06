import 'package:flutter/material.dart';
import '../../../l10n/widget_translations.dart';
import '../../../theme/minimalist_colors.dart';
import '../../../utils/widget_input_decoration_helper.dart';
import '../../../../../../shared/utils/validators/form_validators.dart';

/// Multi-line text field for special requests/notes.
///
/// Extracted from booking_widget_screen.dart special requests field section.
/// Optional field with 3 lines and 500 character max length.
///
/// Usage:
/// ```dart
/// NotesField(
///   controller: _notesController,
///   isDarkMode: isDarkMode,
/// )
/// ```
class NotesField extends StatelessWidget {
  /// Controller for the notes text field
  final TextEditingController controller;

  /// Whether dark mode is active
  final bool isDarkMode;

  const NotesField({super.key, required this.controller, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return TextFormField(
      controller: controller,
      maxLines: 3,
      maxLength: 500,
      style: TextStyle(color: colors.textPrimary),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: NotesValidator.validate,
      decoration: WidgetInputDecorationHelper.buildDecoration(
        labelText: WidgetTranslations.of(context).labelSpecialRequests,
        hintText: WidgetTranslations.of(context).hintSpecialRequests,
        prefixIcon: Icon(Icons.notes, color: colors.textSecondary),
        isDarkMode: isDarkMode,
        hideCounter: false,
      ).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7)),
    );
  }
}
