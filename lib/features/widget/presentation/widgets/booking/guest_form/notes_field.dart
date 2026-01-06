import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/widget_translations.dart';
import '../../../theme/minimalist_colors.dart';
import '../../../utils/widget_input_decoration_helper.dart';
import '../../../../../../shared/utils/validators/form_validators.dart';

/// Multi-line text field for special requests/notes.
///
/// Optional field with 3 lines and 500 character max length.
class NotesField extends ConsumerWidget {
  final TextEditingController controller;
  final bool isDarkMode;

  const NotesField({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  static const _maxLines = 3;
  static const _maxLength = 500;
  static const _contentPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 7,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final tr = WidgetTranslations.of(context, ref);

    return TextFormField(
      controller: controller,
      maxLines: _maxLines,
      maxLength: _maxLength,
      style: TextStyle(color: colors.textPrimary),
      scrollPadding: const EdgeInsets.all(250.0),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: NotesValidator.validate,
      decoration: WidgetInputDecorationHelper.buildDecoration(
        labelText: tr.labelSpecialRequests,
        hintText: tr.hintSpecialRequests,
        prefixIcon: Icon(Icons.notes, color: colors.textSecondary),
        isDarkMode: isDarkMode,
        hideCounter: false,
      ).copyWith(contentPadding: _contentPadding),
    );
  }
}
