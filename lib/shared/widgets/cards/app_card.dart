import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';

/// Base card widget with consistent styling
/// Provides standard card appearance across the app
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.border,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: borderRadius ?? BorderRadius.circular(AppDimensions.radiusM),
        border: border,
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).toInt()),
                  blurRadius: elevation!,
                  offset: Offset(0, elevation! / 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppDimensions.spaceS),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(AppDimensions.radiusM),
        child: card,
      );
    }

    return card;
  }
}

/// Premium Stat card - for displaying statistics with icon, value, and label
class StatCard extends StatefulWidget {
  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.authPrimary,
    this.trend,
    this.onTap,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend; // e.g., "+12%", "-5%"
  final VoidCallback? onTap;

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AppDimensions.mobile;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.color.withAlpha((0.08 * 255).toInt()),
              widget.color.withAlpha((0.03 * 255).toInt()),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: _isHovered
                ? widget.color.withAlpha((0.3 * 255).toInt())
                : widget.color.withAlpha((0.15 * 255).toInt()),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withAlpha(((_isHovered ? 0.15 : 0.08) * 255).toInt()),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 6 : 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 6 : AppDimensions.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with premium container
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.color.withAlpha((0.15 * 255).toInt()),
                          widget.color.withAlpha((0.08 * 255).toInt()),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withAlpha((0.2 * 255).toInt()),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: isMobile ? 16 : 26,
                    ),
                  ),
                  SizedBox(height: isMobile ? 6 : AppDimensions.spaceM),

                  // Value with premium style
                  Flexible(
                    child: Text(
                      widget.value,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 20 : 36,
                            color: const Color(0xFF2D3748),
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Title
                  Flexible(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF4A5568),
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 9 : 14,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),

                  // Trend (optional) with better styling
                  if (widget.trend != null) ...[
                    const SizedBox(height: AppDimensions.spaceS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (widget.trend!.startsWith('+')
                                ? AppColors.success
                                : AppColors.error)
                            .withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.trend!.startsWith('+')
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 16,
                            color: widget.trend!.startsWith('+')
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.trend!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: widget.trend!.startsWith('+')
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Content card - elevated card with shadow for main content areas
class ContentCard extends StatelessWidget {
  const ContentCard({
    required this.child,
    this.title,
    this.trailing,
    this.padding,
    this.margin,
    this.onTap,
    super.key,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevation: AppDimensions.elevation1,
      padding: const EdgeInsets.all(0),
      margin: margin,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || trailing != null)
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceS),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          Padding(
            padding: padding ?? const EdgeInsets.all(AppDimensions.spaceS),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Interactive card - card with hover effect for clickable items
class InteractiveCard extends StatefulWidget {
  const InteractiveCard({
    required this.child,
    required this.onTap,
    this.padding,
    this.margin,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: AppDimensions.animationFast,
        child: AppCard(
          elevation: _isHovered ? AppDimensions.elevation3 : AppDimensions.elevation2,
          padding: widget.padding,
          margin: widget.margin,
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}

/// List card - flat card with bottom border for list items
class ListCard extends StatelessWidget {
  const ListCard({
    required this.child,
    this.padding,
    this.showBorder = true,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevation: 0,
      borderRadius: BorderRadius.zero,
      border: showBorder
          ? const Border(
              bottom: BorderSide(color: AppColors.borderLight),
            )
          : null,
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceM,
      ),
      onTap: onTap,
      child: child,
    );
  }
}
