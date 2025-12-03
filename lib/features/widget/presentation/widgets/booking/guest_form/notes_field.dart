import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../theme/minimalist_colors.dart';

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

  const NotesField({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return TextFormField(
      controller: controller,
      maxLines: 3,
      maxLength: 500,
      style: TextStyle(
        color: colors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: 'Special Requests (Optional)',
        hintText: 'Any special requirements or preferences...',
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
        prefixIcon: Icon(
          Icons.notes,
          color: colors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ), // Reduced by 10px total (5px top + 5px bottom)
      ),
    );
  }
}
