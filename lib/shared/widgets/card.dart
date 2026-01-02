import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/constants/app_dimensions.dart';

/// Premium card component with multiple variants and effects
/// Supports: Elevated, Outlined, Filled, Glass variants
/// Features: Hover effects, shadows, glass morphism, responsive design
class PremiumCard extends StatefulWidget {
  /// Card child widget
  final Widget child;

  /// Card variant style
  final CardVariant variant;

  /// Card elevation level (0-5)
  final int elevation;

  /// Border radius
  final double? borderRadius;

  /// Card padding
  final EdgeInsets? padding;

  /// Card margin
  final EdgeInsets? margin;

  /// Width constraint
  final double? width;

  /// Height constraint
  final double? height;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Enable hover effect
  final bool enableHover;

  /// Custom background color (overrides variant color)
  final Color? backgroundColor;

  /// Custom border color (for outline variant)
  final Color? borderColor;

  /// Image header widget (optional)
  final Widget? imageHeader;

  /// Image aspect ratio (if imageHeader is provided)
  final double imageAspectRatio;

  /// Enable glass morphism effect
  final bool enableGlassMorphism;

  const PremiumCard({
    super.key,
    required this.child,
    this.variant = CardVariant.elevated,
    this.elevation = 2,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.enableHover = true,
    this.backgroundColor,
    this.borderColor,
    this.imageHeader,
    this.imageAspectRatio = 16 / 9,
    this.enableGlassMorphism = false,
  });

  /// Elevated card (with shadow)
  factory PremiumCard.elevated({
    required Widget child,
    int elevation = 2,
    double? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? width,
    double? height,
    VoidCallback? onTap,
    bool enableHover = true,
    Color? backgroundColor,
    Widget? imageHeader,
    double imageAspectRatio = 16 / 9,
  }) {
    return PremiumCard(
      variant: CardVariant.elevated,
      elevation: elevation,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      enableHover: enableHover,
      backgroundColor: backgroundColor,
      imageHeader: imageHeader,
      imageAspectRatio: imageAspectRatio,
      child: child,
    );
  }

  /// Outlined card (with border)
  factory PremiumCard.outlined({
    required Widget child,
    double? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? width,
    double? height,
    VoidCallback? onTap,
    bool enableHover = true,
    Color? backgroundColor,
    Color? borderColor,
    Widget? imageHeader,
    double imageAspectRatio = 16 / 9,
  }) {
    return PremiumCard(
      variant: CardVariant.outlined,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      enableHover: enableHover,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      imageHeader: imageHeader,
      imageAspectRatio: imageAspectRatio,
      child: child,
    );
  }

  /// Filled card (solid background)
  factory PremiumCard.filled({
    required Widget child,
    double? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? width,
    double? height,
    VoidCallback? onTap,
    bool enableHover = true,
    Color? backgroundColor,
    Widget? imageHeader,
    double imageAspectRatio = 16 / 9,
  }) {
    return PremiumCard(
      variant: CardVariant.filled,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      enableHover: enableHover,
      backgroundColor: backgroundColor,
      imageHeader: imageHeader,
      imageAspectRatio: imageAspectRatio,
      child: child,
    );
  }

  /// Glass morphism card (blurred transparent background)
  factory PremiumCard.glass({
    required Widget child,
    double? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? width,
    double? height,
    VoidCallback? onTap,
    bool enableHover = true,
    Widget? imageHeader,
    double imageAspectRatio = 16 / 9,
  }) {
    return PremiumCard(
      variant: CardVariant.glass,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      onTap: onTap,
      enableHover: enableHover,
      imageHeader: imageHeader,
      imageAspectRatio: imageAspectRatio,
      enableGlassMorphism: true,
      child: child,
    );
  }

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _isHovered = false;

  // Optimization: Pre-compute the transformation matrix to avoid creating a new
  // Matrix4 object on every build during hover. This reduces garbage collection pressure.
  static final _hoverTransform = Matrix4.translationValues(0, -4, 0);

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? AppDimensions.radiusL;
    final effectivePadding = widget.padding ?? const EdgeInsets.all(AppDimensions.spaceM);

    final Widget cardContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.imageHeader != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(effectiveRadius),
            ),
            child: AspectRatio(
              aspectRatio: widget.imageAspectRatio,
              child: widget.imageHeader!,
            ),
          ),
        ],
        Padding(
          padding: effectivePadding,
          child: widget.child,
        ),
      ],
    );

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: MouseRegion(
        onEnter: (_) {
          if (widget.enableHover) {
            setState(() => _isHovered = true);
          }
        },
        onExit: (_) {
          if (widget.enableHover) {
            setState(() => _isHovered = false);
          }
        },
        child: AnimatedContainer(
          duration: AppAnimations.hover.duration,
          curve: AppAnimations.hover.curve,
          decoration: _buildDecoration(context, effectiveRadius),
          transform: widget.enableHover && _isHovered
              ? _hoverTransform
              : Matrix4.identity(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(effectiveRadius),
            child: widget.onTap != null
                ? InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(effectiveRadius),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: cardContent,
                    ),
                  )
                : SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: cardContent,
                  ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(BuildContext context, double radius) {
    final Color backgroundColor;
    final Border? border;
    final List<BoxShadow>? boxShadow;
    final Gradient? gradient;

    switch (widget.variant) {
      case CardVariant.elevated:
        // Use theme-aware surface color
        backgroundColor = widget.backgroundColor ?? context.surfaceColor;
        border = null;
        // Use theme-aware shadow color in elevation shadows
        boxShadow = _isHovered
            ? AppShadows.getElevation(widget.elevation + 1, isDark: context.isDarkMode)
            : AppShadows.getElevation(widget.elevation, isDark: context.isDarkMode);
        gradient = null;
        break;

      case CardVariant.outlined:
        // Use theme-aware surface color for background
        backgroundColor = widget.backgroundColor ?? context.surfaceColor;
        // Use theme-aware border color
        border = Border.all(
          color: widget.borderColor ?? context.borderColor,
          width: 1.5,
        );
        boxShadow = _isHovered ? AppShadows.elevation1 : null;
        gradient = null;
        break;

      case CardVariant.filled:
        // Use theme-aware surface variant color for filled cards
        backgroundColor = widget.backgroundColor ?? context.surfaceVariantColor;
        border = null;
        boxShadow = _isHovered ? AppShadows.elevation1 : null;
        gradient = null;
        break;

      case CardVariant.glass:
        // Glass morphism uses transparent background with theme-aware borders and shadows
        backgroundColor = Colors.transparent;
        border = Border.all(
          color: AppColors.withOpacity(
            Colors.white,
            context.isDarkMode ? AppColors.opacity10 : AppColors.opacity20,
          ),
          width: 1,
        );
        // Use theme-aware shadow color for glass effect
        boxShadow = _isHovered
            ? AppShadows.elevation2
            : [
                BoxShadow(
                  color: context.shadowColorProminent,
                  blurRadius: context.isDarkMode ? 12 : 8,
                  offset: Offset(0, context.isDarkMode ? 6 : 4),
                ),
              ];
        // Gradient remains as-is (already theme-aware via AppColors)
        gradient = context.isDarkMode
            ? AppColors.glassGradientDark
            : AppColors.glassGradient;
        break;
    }

    return BoxDecoration(
      color: gradient == null ? backgroundColor : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: border,
      boxShadow: boxShadow,
    );
  }
}

/// Card variant enum
enum CardVariant {
  /// Elevated card with shadow
  elevated,

  /// Outlined card with border
  outlined,

  /// Filled card with solid background
  filled,

  /// Glass morphism card with blur effect
  glass,
}
