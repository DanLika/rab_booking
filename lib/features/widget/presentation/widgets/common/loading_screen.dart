import 'package:flutter/material.dart';
import '../../theme/minimalist_colors.dart';
import 'theme_colors_helper.dart';

/// Loading screen displayed while booking widget is initializing.
///
/// Shows a centered loading indicator with a message.
/// Used during initial validation of unit/property parameters.
///
/// Usage:
/// ```dart
/// if (_isValidating) {
///   return WidgetLoadingScreen(isDarkMode: isDarkMode);
/// }
/// ```
class WidgetLoadingScreen extends StatelessWidget {
  /// Whether dark mode is active
  final bool isDarkMode;

  /// Optional custom loading message
  final String message;

  const WidgetLoadingScreen({
    super.key,
    required this.isDarkMode,
    this.message = 'Loading booking widget...',
  });

  @override
  Widget build(BuildContext context) {
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);

    return Scaffold(
      backgroundColor: getColor(
        MinimalistColors.backgroundPrimary,
        MinimalistColorsDark.backgroundPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: getColor(
                MinimalistColors.buttonPrimary,
                MinimalistColorsDark.buttonPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: getColor(
                  MinimalistColors.textSecondary,
                  MinimalistColorsDark.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
