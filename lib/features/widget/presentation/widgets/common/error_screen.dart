import 'package:flutter/material.dart';
import '../../../../../core/localization/error_messages.dart';
import '../../theme/minimalist_colors.dart';

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
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    // Responsive padding: smaller on mobile devices
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 16.0 : 32.0;

    // Responsive icon and text sizes
    final iconSize = screenWidth < 600 ? 48.0 : 64.0;
    final titleFontSize = screenWidth < 600 ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: iconSize,
                color: colors.error,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text(ErrorMessages.retryButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.buttonPrimary,
                  foregroundColor: colors.buttonPrimaryText,
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
