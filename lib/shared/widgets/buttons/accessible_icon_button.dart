import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// IconButton with guaranteed 48x48 minimum touch target for accessibility
///
/// Meets WCAG 2.1 Level AAA requirements for touch target size
///
/// Example usage:
/// ```dart
/// AccessibleIconButton(
///   icon: Icons.favorite,
///   onPressed: () => toggleFavorite(),
///   tooltip: 'Add to favorites',
/// )
/// ```
class AccessibleIconButton extends StatelessWidget {
  const AccessibleIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconSize = 24.0,
    this.color,
    this.splashRadius,
    this.padding,
    super.key,
  });

  /// Icon to display
  final IconData icon;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Tooltip text for accessibility
  final String? tooltip;

  /// Size of the icon (default 24)
  final double iconSize;

  /// Icon color
  final Color? color;

  /// Splash radius
  final double? splashRadius;

  /// Custom padding
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 48,
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!();
              },
        tooltip: tooltip,
        iconSize: iconSize,
        color: color,
        splashRadius: splashRadius,
        padding: padding ?? const EdgeInsets.all(8.0),
      ),
    );
  }
}
