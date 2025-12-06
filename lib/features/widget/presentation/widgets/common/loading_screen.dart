import 'package:flutter/material.dart';
import '../../l10n/widget_translations.dart';
import '../../theme/minimalist_colors.dart';

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

  /// Optional custom loading message (if null, uses localized default)
  final String? message;

  const WidgetLoadingScreen({super.key, required this.isDarkMode, this.message});

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final displayMessage = message ?? WidgetTranslations.of(context).loadingBookingWidget;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colors.buttonPrimary),
            const SizedBox(height: 24),
            Text(displayMessage, style: TextStyle(fontSize: 16, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
