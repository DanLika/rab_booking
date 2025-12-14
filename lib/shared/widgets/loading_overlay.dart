import 'package:flutter/material.dart';

/// Simple loading overlay with spinner - used for route transitions
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({super.key, this.message, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Minimalistic: Use only black and white
    final bgColor = backgroundColor ?? (isDarkMode ? Colors.black.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95));

    // Minimalistic: Use black in light mode, white in dark mode
    final loaderColor = isDarkMode ? Colors.white : Colors.black;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      color: bgColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(loaderColor)),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
