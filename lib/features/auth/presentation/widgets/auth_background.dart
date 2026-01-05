import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Premium auth background with gradient
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? AppColors.authBackgroundGradientDark
              : AppColors.authBackgroundGradient,
        ),
        child: child,
      ),
    );
  }
}
