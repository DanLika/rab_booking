import 'package:flutter/material.dart';

/// Premium auth background with gradient
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  const Color(0xFF1A1A1A), // Dark gray
                  const Color(0xFF2D2D2D), // Lighter dark gray
                ]
              : [
                  const Color(0xFFFAF8F3), // Beige
                  const Color(0xFFFFFFFF), // White
                ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: child,
    );
  }
}
