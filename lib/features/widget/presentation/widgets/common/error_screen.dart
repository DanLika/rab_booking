import 'package:flutter/material.dart';
import '../../theme/minimalist_colors.dart';
import 'theme_colors_helper.dart';

/// Error screen displayed when booking widget configuration fails.
///
/// Shows an error icon, title, message, and retry button.
/// Used when URL parameters are invalid or unit/property doesn't exist.
///
/// Usage:
/// ```dart
/// if (_validationError != null) {
///   return WidgetErrorScreen(
///     isDarkMode: isDarkMode,
///     errorMessage: _validationError!,
///     onRetry: _validateUnitAndProperty,
///   );
/// }
/// ```
class WidgetErrorScreen extends StatelessWidget {
  /// Whether dark mode is active
  final bool isDarkMode;

  /// Error title (defaults to "Configuration Error")
  final String title;

  /// Error message to display
  final String errorMessage;

  /// Callback when retry button is pressed
  final VoidCallback onRetry;

  const WidgetErrorScreen({
    super.key,
    required this.isDarkMode,
    this.title = 'Configuration Error',
    required this.errorMessage,
    required this.onRetry,
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: getColor(
                  MinimalistColors.error,
                  MinimalistColorsDark.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: getColor(
                    MinimalistColors.textSecondary,
                    MinimalistColorsDark.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: getColor(
                    MinimalistColors.buttonPrimary,
                    MinimalistColorsDark.buttonPrimary,
                  ),
                  foregroundColor: getColor(
                    MinimalistColors.buttonPrimaryText,
                    MinimalistColorsDark.buttonPrimaryText,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
