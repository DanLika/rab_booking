import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../constants/app_dimensions.dart';

/// Application visual effects
/// Provides blur effects, glass morphism, and other premium visual effects
class AppEffects {
  AppEffects._(); // Private constructor

  // ============================================================================
  // BLUR EFFECTS
  // ============================================================================

  /// Light blur effect (sigma 4)
  static final ImageFilter blurLight = ImageFilter.blur(sigmaX: 4, sigmaY: 4);

  /// Medium blur effect (sigma 8)
  static final ImageFilter blurMedium = ImageFilter.blur(sigmaX: 8, sigmaY: 8);

  /// Strong blur effect (sigma 16)
  static final ImageFilter blurStrong = ImageFilter.blur(sigmaX: 16, sigmaY: 16);

  /// Extra strong blur effect (sigma 24)
  static final ImageFilter blurExtraStrong = ImageFilter.blur(sigmaX: 24, sigmaY: 24);

  // ============================================================================
  // GLASS MORPHISM DECORATIONS
  // ============================================================================

  /// Light glass morphism decoration (light mode)
  /// Semi-transparent white background with blur
  static final BoxDecoration glassMorphismLight = BoxDecoration(
        gradient: AppColors.glassGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 16)
        border: Border.all(
          color: AppColors.withOpacity(Colors.white, AppColors.opacity20),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // 5% black
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      );

  /// Dark glass morphism decoration (dark mode)
  /// Semi-transparent dark background with blur
  static final BoxDecoration glassMorphismDark = BoxDecoration(
        gradient: AppColors.glassGradientDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 16)
        border: Border.all(
          color: AppColors.withOpacity(Colors.white, AppColors.opacity10),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000), // 20% black
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      );

  /// Frosted glass effect (for app bars, cards)
  static final BoxDecoration frostedGlass = BoxDecoration(
        color: AppColors.withOpacity(Colors.white, AppColors.opacity80),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius
        border: Border.all(
          color: AppColors.withOpacity(Colors.white, AppColors.opacity40),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // 8% black
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );

  /// Tinted glass effect with primary color
  static final BoxDecoration tintedGlassPrimary = BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.withOpacity(AppColors.primary, AppColors.opacity20),
            AppColors.withOpacity(AppColors.primary, AppColors.opacity10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 16)
        border: Border.all(
          color: AppColors.withOpacity(AppColors.primary, AppColors.opacity30),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.withOpacity(AppColors.primary, AppColors.opacity20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Tinted glass effect with secondary color
  static final BoxDecoration tintedGlassSecondary = BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.withOpacity(AppColors.secondary, AppColors.opacity20),
            AppColors.withOpacity(AppColors.secondary, AppColors.opacity10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 16)
        border: Border.all(
          color: AppColors.withOpacity(AppColors.secondary, AppColors.opacity30),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.withOpacity(AppColors.secondary, AppColors.opacity20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // ============================================================================
  // BACKDROP FILTER WIDGETS
  // ============================================================================

  /// Light backdrop blur widget (wraps child with blur effect)
  static Widget blurredBackdrop({
    required Widget child,
    ImageFilter? filter,
    double opacity = 0.8,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 16)
      child: BackdropFilter(
        filter: filter ?? blurMedium,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.withOpacity(Colors.white, opacity),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Dark backdrop blur widget
  static Widget blurredBackdropDark({
    required Widget child,
    ImageFilter? filter,
    double opacity = 0.6,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 16)
      child: BackdropFilter(
        filter: filter ?? blurMedium,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.withOpacity(Colors.black, opacity),
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================================
  // BORDER DECORATIONS
  // ============================================================================

  /// Hairline border (very thin, subtle)
  static final Border hairlineBorder = Border.all(
        color: AppColors.borderLight,
        width: 0.5,
      );

  /// Hairline border (dark mode)
  static final Border hairlineBorderDark = Border.all(
        color: AppColors.borderDark,
        width: 0.5,
      );

  /// Thin border (standard)
  static final Border thinBorder = Border.all(
        color: AppColors.borderLight,
        width: 1.0,
      );

  /// Thin border (dark mode)
  static final Border thinBorderDark = Border.all(
        color: AppColors.borderDark,
        width: 1.0,
      );

  /// Medium border (emphasis)
  static final Border mediumBorder = Border.all(
        color: AppColors.borderLight,
        width: 2.0,
      );

  /// Medium border (dark mode)
  static final Border mediumBorderDark = Border.all(
        color: AppColors.borderDark,
        width: 2.0,
      );

  /// Thick border (strong emphasis)
  static final Border thickBorder = Border.all(
        color: AppColors.borderLight,
        width: 3.0,
      );

  /// Thick border (dark mode)
  static final Border thickBorderDark = Border.all(
        color: AppColors.borderDark,
        width: 3.0,
      );

  /// Primary colored border
  static final Border primaryBorder = Border.all(
        color: AppColors.primary,
        width: 2.0,
      );

  /// Secondary colored border
  static final Border secondaryBorder = Border.all(
        color: AppColors.secondary,
        width: 2.0,
      );

  /// Gradient border effect (using decoration)
  static final BoxDecoration gradientBorderPrimary = BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius
        border: Border.all(
          color: Colors.transparent,
          width: 2,
        ),
        gradient: AppColors.primaryGradient,
      );

  /// Gradient border effect with secondary color
  static final BoxDecoration gradientBorderSecondary = BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius
        border: Border.all(
          color: Colors.transparent,
          width: 2,
        ),
        gradient: AppColors.secondaryGradient,
      );

  // ============================================================================
  // SHIMMER EFFECT (for loading states)
  // ============================================================================

  /// Shimmer gradient (light mode)
  static final LinearGradient shimmerGradientLight = const LinearGradient(
        colors: [
          AppColors.shimmerBase,
          AppColors.shimmerHighlight,
          AppColors.shimmerBase,
        ],
        stops: [0.0, 0.5, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Shimmer gradient (dark mode)
  static final LinearGradient shimmerGradientDark = const LinearGradient(
        colors: [
          AppColors.surfaceVariantDark,
          AppColors.surfaceDark,
          AppColors.surfaceVariantDark,
        ],
        stops: [0.0, 0.5, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ============================================================================
  // OVERLAY DECORATIONS
  // ============================================================================

  /// Scrim overlay (for modal backdrops)
  static final BoxDecoration scrimOverlayLight = const BoxDecoration(
        color: AppColors.scrimLight,
      );

  /// Scrim overlay (dark mode)
  static final BoxDecoration scrimOverlayDark = const BoxDecoration(
        color: AppColors.scrimDark,
      );

  /// Gradient overlay for images (dark bottom)
  static final BoxDecoration imageOverlay = const BoxDecoration(
        gradient: AppColors.overlayGradient,
      );

  /// Gradient overlay for images (light center, dark edges)
  static final BoxDecoration imageOverlayRadial = const BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Color(0x00000000), // Transparent center
            Color(0x80000000), // 50% black edges
          ],
          center: Alignment.center,
          radius: 1.0,
        ),
      );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Create custom blur effect with specified sigma
  static ImageFilter customBlur(double sigma) {
    return ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
  }

  /// Create custom glass morphism with parameters
  static BoxDecoration customGlass({
    required Color backgroundColor,
    required Color borderColor,
    double borderWidth = 1.0,
    double borderRadius = 16.0,
    double blurOpacity = 0.1,
  }) {
    return BoxDecoration(
      color: AppColors.withOpacity(backgroundColor, blurOpacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  /// Create custom border with color and width
  static Border customBorder({
    required Color color,
    double width = 1.0,
  }) {
    return Border.all(
      color: color,
      width: width,
    );
  }
}
