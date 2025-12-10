import 'package:flutter/material.dart';
import '../../theme/minimalist_colors.dart';
import 'bookbed_loader.dart';

/// Loading screen displayed while booking widget is initializing.
///
/// Shows BookBed logo with progress bar and percentage.
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

  /// Optional loading progress (0.0 to 1.0)
  final double? progress;

  const WidgetLoadingScreen({
    super.key,
    required this.isDarkMode,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Center(
        child: BookBedLoader(isDarkMode: isDarkMode, progress: progress),
      ),
    );
  }
}
