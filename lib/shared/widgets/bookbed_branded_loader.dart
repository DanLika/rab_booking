import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/design_tokens/design_tokens.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/widgets/auth_logo_icon.dart';

/// Branded BookBed loader with primary colors for owner dashboard
///
/// Uses AppColors.primary instead of minimalistic black/white.
/// Shows animated BookBed logo with progress indication.
///
/// Usage:
/// ```dart
/// BookBedBrandedLoader(
///   isDarkMode: false,
///   progress: 0.45, // 45%
/// )
/// ```
class BookBedBrandedLoader extends StatelessWidget {
  // Layout constants
  static const double _defaultLogoSize = 80;
  static const double _logoToBarSpacing = 32;
  static const double _progressBarWidth = 200;
  static const double _progressBarHeight = 4;
  static const double _progressBarRadius = 2;
  static const double _barToTextSpacing = 12;
  static const double _percentageFontSize = 14;
  static const double _backgroundOpacity = 0.2;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Loading progress (0.0 to 1.0)
  /// If null, shows indeterminate progress
  final double? progress;

  /// Logo size
  final double logoSize;

  const BookBedBrandedLoader({
    super.key,
    required this.isDarkMode,
    this.progress,
    this.logoSize = _defaultLogoSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthLogoIcon(size: logoSize, isWhite: isDarkMode),
        const SizedBox(height: _logoToBarSpacing),
        SizedBox(
          width: _progressBarWidth,
          child: Column(
            children: [
              _buildProgressBar(),
              const SizedBox(height: _barToTextSpacing),
              if (progress != null) _buildPercentageText(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    // Branded: Use primary colors
    final progressColor = isDarkMode
        ? AppColors.primaryLight
        : AppColors.primary;
    final backgroundColor = progressColor.withValues(alpha: _backgroundOpacity);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_progressBarRadius),
      child: SizedBox(
        height: _progressBarHeight,
        child: Stack(
          children: [
            Container(color: backgroundColor),
            if (progress != null)
              FractionallySizedBox(
                widthFactor: progress!.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(color: progressColor),
              )
            else
              _BrandedIndeterminateProgress(color: progressColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageText() {
    // Branded: Use primary color for text
    final textColor = isDarkMode ? AppColors.primaryLight : AppColors.primary;

    return Text(
      '${(progress! * 100).toInt()}%',
      style: TextStyle(
        fontSize: _percentageFontSize,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: TypographyTokens.primaryFont,
      ),
    );
  }
}

/// Indeterminate progress animation with branded colors
/// Indeterminate progress animation with branded colors
/// Refactored to use flutter_animate for consistency and simplicity.
class _BrandedIndeterminateProgress extends StatelessWidget {
  static const Duration _animationDuration = Duration(milliseconds: 1500);
  static const double _indicatorWidth = 0.3;

  final Color color;

  const _BrandedIndeterminateProgress({required this.color});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _indicatorWidth,
      child: Container(color: color),
    ).animate(onPlay: (controller) => controller.repeat()).slideX(
          duration: _animationDuration,
          begin: -1.5,
          end: 1.5,
          curve: Curves.easeInOut,
        );
  }
}
