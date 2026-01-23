import 'package:flutter/material.dart';

/// BookBed logo widget that displays the official logo image
///
/// Uses separate logo assets for light/dark modes:
/// - logo-light.png = purple logo for light backgrounds
/// - logo-dark.png = white logo for dark backgrounds
///
/// This approach is more reliable than ColorFilter which can produce artifacts.
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

    // Use separate logo assets for light/dark modes
    // logo-light.png = purple logo for light backgrounds
    // logo-dark.png = white logo for dark backgrounds
    // This is more reliable than ColorFilter which can produce artifacts
    final logoPath = isDarkMode
        ? 'assets/images/logo-dark.png'
        : 'assets/images/logo-light.png';

    final logoImage = Image.asset(
      logoPath,
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
