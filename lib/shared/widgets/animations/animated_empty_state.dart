import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/design_tokens/animation_tokens.dart';

/// Animated empty state widget with fade + scale entrance animation
///
/// Uses flutter_animate for declarative animations with BookBed's
/// animation design tokens.
///
/// Usage:
/// ```dart
/// AnimatedEmptyState(
///   icon: Icons.inbox_outlined,
///   title: 'No bookings yet',
///   subtitle: 'Your bookings will appear here',
/// )
/// ```
class AnimatedEmptyState extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Main title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional action button
  final Widget? actionButton;

  /// Icon size (default: 64)
  final double iconSize;

  /// Icon color (defaults to theme's onSurfaceVariant with 0.5 opacity)
  final Color? iconColor;

  /// Whether to show animation (set false to skip animation)
  final bool animate;

  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionButton,
    this.iconSize = 64,
    this.iconColor,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor =
        iconColor ??
        theme.colorScheme.onSurfaceVariant.withAlpha((0.5 * 255).toInt());

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: effectiveIconColor),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha((0.8 * 255).toInt()),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (actionButton != null) ...[
          const SizedBox(height: 24),
          actionButton!,
        ],
      ],
    );

    // Skip animation if disabled
    if (!animate) {
      return content;
    }

    // Apply fade + scale animation using flutter_animate
    return content
        .animate()
        .fadeIn(
          duration: AnimationTokens.normal,
          curve: AnimationTokens.easeOut,
        )
        .scale(
          duration: AnimationTokens.normal,
          curve: AnimationTokens.fastOutSlowIn,
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
        );
  }
}

/// Staggered animated empty state with delayed animations for each element
///
/// Each element (icon, title, subtitle, button) animates in sequence
/// with configurable delay between them.
///
/// Usage:
/// ```dart
/// StaggeredEmptyState(
///   icon: Icons.notifications_none,
///   title: 'No notifications',
///   subtitle: 'You're all caught up!',
/// )
/// ```
class StaggeredEmptyState extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Main title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional action button
  final Widget? actionButton;

  /// Icon size (default: 64)
  final double iconSize;

  /// Icon color (defaults to theme's onSurfaceVariant with 0.5 opacity)
  final Color? iconColor;

  /// Delay between each element animation (default: 100ms)
  final Duration staggerDelay;

  const StaggeredEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionButton,
    this.iconSize = 64,
    this.iconColor,
    this.staggerDelay = const Duration(milliseconds: 100),
  });

  /// Build animated element with stagger delay
  Widget _buildAnimatedElement(int index, Widget child) {
    return child
        .animate(delay: staggerDelay * index)
        .fadeIn(
          duration: AnimationTokens.fast,
          curve: AnimationTokens.easeOut,
        )
        .slideY(
          duration: AnimationTokens.fast,
          curve: AnimationTokens.easeOut,
          begin: 20,
          end: 0,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor =
        iconColor ??
        theme.colorScheme.onSurfaceVariant.withAlpha((0.5 * 255).toInt());

    int elementIndex = 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAnimatedElement(
          elementIndex++,
          Icon(icon, size: iconSize, color: effectiveIconColor),
        ),
        const SizedBox(height: 16),
        _buildAnimatedElement(
          elementIndex++,
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((0.8 * 255).toInt()),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          _buildAnimatedElement(
            elementIndex++,
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        if (actionButton != null) ...[
          const SizedBox(height: 24),
          _buildAnimatedElement(elementIndex, actionButton!),
        ],
      ],
    );
  }
}
