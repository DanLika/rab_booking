import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Simple loading overlay with spinner - used for route transitions
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({super.key, this.message, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? (isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.8));

    return Container(
      color: bgColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(isDark ? AppColors.primaryLight : AppColors.primary),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white70 : Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
