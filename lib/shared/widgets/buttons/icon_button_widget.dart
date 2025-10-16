import 'package:flutter/material.dart';

/// Circular icon button with tooltip
///
/// Example usage:
/// ```dart
/// IconButtonWidget(
///   icon: Icons.favorite,
///   tooltip: 'Add to favorites',
///   onPressed: () {
///     toggleFavorite();
///   },
/// )
/// ```
class IconButtonWidget extends StatelessWidget {
  const IconButtonWidget({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size = 48.0,
    super.key,
  });

  /// Icon to display
  final IconData icon;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Tooltip text
  final String? tooltip;

  /// Background color
  final Color? backgroundColor;

  /// Icon color
  final Color? iconColor;

  /// Button size
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: iconColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
        iconSize: size * 0.5,
      ),
    );

    return tooltip != null
        ? Tooltip(
            message: tooltip!,
            child: button,
          )
        : button;
  }
}
