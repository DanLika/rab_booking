import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../theme/minimalist_colors.dart';
import '../../../utils/form_validators.dart';
import '../../common/theme_colors_helper.dart';

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
class GuestNameFields extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First Name field
        Expanded(
          child: TextFormField(
            controller: firstNameController,
            maxLength: 50, // Bug #60: Maximum field length validation
            style: TextStyle(
              color: getColor(
                MinimalistColors.textPrimary,
                MinimalistColorsDark.textPrimary,
              ),
            ),
            decoration: InputDecoration(
              counterText: '', // Hide character counter
              labelText: 'First Name *',
              hintText: 'John',
              labelStyle: TextStyle(
                color: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
              ),
              hintStyle: TextStyle(
                color: getColor(
                  MinimalistColors.textSecondary,
                  MinimalistColorsDark.textSecondary,
                ),
              ),
              filled: true,
              fillColor: getColor(
                MinimalistColors.backgroundSecondary,
                MinimalistColorsDark.backgroundSecondary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
                borderSide: BorderSide(
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
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
                height: 1.0,
              ),
              errorMaxLines: 1,
              prefixIcon: Icon(
                Icons.person_outline,
                color: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
              ),
            ),
            // Real-time validation
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: FirstNameValidator.validate,
          ),
        ),
        const SizedBox(width: SpacingTokens.m),
        // Last Name field
        Expanded(
          child: TextFormField(
            controller: lastNameController,
            maxLength: 50, // Bug #60: Maximum field length validation
            style: TextStyle(
              color: getColor(
                MinimalistColors.textPrimary,
                MinimalistColorsDark.textPrimary,
              ),
            ),
            decoration: InputDecoration(
              counterText: '', // Hide character counter
              labelText: 'Last Name *',
              hintText: 'Doe',
              labelStyle: TextStyle(
                color: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
              ),
              hintStyle: TextStyle(
                color: getColor(
                  MinimalistColors.textSecondary,
                  MinimalistColorsDark.textSecondary,
                ),
              ),
              filled: true,
              fillColor: getColor(
                MinimalistColors.backgroundSecondary,
                MinimalistColorsDark.backgroundSecondary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderTokens.circularMedium,
                borderSide: BorderSide(
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
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
                height: 1.0,
              ),
              errorMaxLines: 1,
            ),
            // Real-time validation
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: LastNameValidator.validate,
          ),
        ),
      ],
    );
  }
}
