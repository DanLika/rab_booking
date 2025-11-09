import 'package:flutter/material.dart';

/// Premium glass morphism card for auth screens
class GlassCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.maxWidth = 460,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Responsive padding based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final responsivePadding = padding ?? EdgeInsets.all(
      screenWidth < 400 ? 16 : (screenWidth < 600 ? 24 : 32)
    );

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withAlpha((0.08 * 255).toInt()),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: theme.colorScheme.shadow.withAlpha((0.04 * 255).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [
                const Color(0xFF1E1E1E).withAlpha((0.95 * 255).toInt()), // Dark gray for dark mode
                const Color(0xFF2A2A2A).withAlpha((0.90 * 255).toInt()),
              ] : [
                Colors.white.withAlpha((0.95 * 255).toInt()), // White for light mode
                Colors.white.withAlpha((0.90 * 255).toInt()),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha((0.1 * 255).toInt())
                  : Colors.white.withAlpha((0.4 * 255).toInt()),
              width: 1.5,
            ),
          ),
          padding: responsivePadding,
          child: child,
        ),
      ),
    );
  }
}
