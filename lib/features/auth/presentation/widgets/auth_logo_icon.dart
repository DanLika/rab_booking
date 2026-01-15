import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

/// Animated logo icon for auth screens and loaders
///
/// Displays the BookBed logo image with optional animation effects.
/// Uses flutter_animate for scale pulse and glow opacity animation.
class AuthLogoIcon extends StatelessWidget {
  final double size;
  final bool isWhite;

  /// If true, uses minimalistic black/white colors (for preloader)
  /// If false, uses brand purple colors (for login/register pages)
  final bool useMinimalistic;

  /// If true, enables pulse animation
  final bool animate;

  const AuthLogoIcon({
    super.key,
    this.size = 100,
    this.isWhite = false,
    this.useMinimalistic = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Determine glow color based on mode
    final Color glowColor;
    if (useMinimalistic) {
      // Minimalistic: Use black in light mode, white in dark mode (for preloader)
      glowColor = isWhite
          ? Colors.white
          : (isDarkMode ? Colors.white : Colors.black);
    } else {
      // Colorized: Use brand purple colors (for login/register pages)
      glowColor = isWhite
          ? Colors.white
          : (isDarkMode ? AppColors.primaryLight : AppColors.primary);
    }

    // Calculate cache size based on widget size and pixel ratio for memory optimization
    final cacheSize = (size * MediaQuery.of(context).devicePixelRatio).toInt();

    // Build the logo image with optional color inversion for dark mode
    Widget logoImage = Image.asset(
      'assets/images/Apple_App_Icon.png',
      width: size,
      height: size,
      cacheWidth: cacheSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if image fails to load
        return Icon(
          Icons.home_work_outlined,
          size: size * 0.6,
          color: glowColor,
        );
      },
    );

    // In dark mode, invert the logo colors so it's visible on dark backgrounds
    if ((isWhite || isDarkMode) && !useMinimalistic) {
      logoImage = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        child: logoImage,
      );
    }

    final logoWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withAlpha((0.3 * 255 * 0.25).toInt()),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: logoImage,
    );

    if (!animate) {
      return logoWidget;
    }

    return logoWidget
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          duration: const Duration(seconds: 3),
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          curve: Curves.easeInOut,
        )
        .custom(
          delay: Duration.zero, // Run simultaneously with scale
          duration: const Duration(seconds: 3),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            // Animate glow opacity from 0.3 to 0.6
            final glowOpacity = 0.3 + (value * 0.3);
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withAlpha(
                      (glowOpacity * 255 * 0.25).toInt(),
                    ),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            );
          },
        );
  }
}
