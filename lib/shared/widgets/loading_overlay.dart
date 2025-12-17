import 'package:flutter/material.dart';
import 'bookbed_branded_loader.dart';

/// Loading overlay with BookBed branded loader
///
/// Shows BookBed logo with animated progress bar.
/// Used for route transitions and async operations in owner dashboard.
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({super.key, this.message, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final bgColor = backgroundColor ??
        (isDarkMode ? Colors.black.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95));

    return Container(
      color: bgColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BookBedBrandedLoader(isDarkMode: isDarkMode),
            if (message != null) ...[
              const SizedBox(height: 24),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
