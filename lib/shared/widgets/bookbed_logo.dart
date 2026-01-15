import 'package:flutter/material.dart';

/// BookBed logo widget that displays the official logo image
///
/// Uses the Apple_App_Icon.png asset (1024x1024px) for high-quality rendering.
/// In dark mode, the logo colors are automatically inverted to ensure visibility on dark backgrounds.
///
/// Usage:
/// ```dart
/// BookBedLogo(size: 80)
/// ```
class BookBedLogo extends StatelessWidget {
  /// The size of the logo (width and height will be equal)
  final double size;

  /// Optional box shadow for glow effect
  final bool showGlow;

  /// Glow color (defaults to primary color with low opacity)
  final Color? glowColor;

  const BookBedLogo({
    super.key,
    this.size = 80,
    this.showGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Calculate cache size based on widget size and pixel ratio for memory optimization
    final cacheSize = (size * MediaQuery.of(context).devicePixelRatio).toInt();

    Widget logoImage = Image.asset(
      'assets/images/Apple_App_Icon.png',
      width: size,
      height: size,
      cacheWidth: cacheSize,
      fit: BoxFit.contain,
      // Provide error handling for asset loading
      errorBuilder: (context, error, stackTrace) {
        // Fallback to a simple icon if image fails to load
        return Icon(
          Icons.home_work_outlined,
          size: size * 0.6,
          color: Theme.of(context).colorScheme.primary,
        );
      },
    );

    // In dark mode, invert the logo colors so it's visible on dark backgrounds
    if (isDarkMode) {
      logoImage = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: logoImage,
      );
    }

    if (!showGlow) {
      return logoImage;
    }

    // Apply glow effect if requested
    final effectiveGlowColor =
        glowColor ?? Theme.of(context).colorScheme.primary.withAlpha(40);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: effectiveGlowColor, blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: logoImage,
    );
  }
}
