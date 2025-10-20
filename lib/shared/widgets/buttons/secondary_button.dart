import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';

/// Secondary outlined button widget with hover effects
///
/// Example usage:
/// ```dart
/// SecondaryButton(
///   text: 'Cancel',
///   onPressed: () {
///     Navigator.pop(context);
///   },
/// )
/// ```
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.text,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    super.key,
  });

  /// Button text label
  final String text;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Optional icon to display before text
  final IconData? icon;

  /// Whether button should take full width
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(text),
            style: OutlinedButton.styleFrom(
              // Use design system padding (24px horizontal, 12px vertical for 48px height)
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceM,
                vertical: 12,
              ),
              minimumSize: const Size(0, AppDimensions.buttonHeight),
            ),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              // Use design system padding (24px horizontal, 12px vertical for 48px height)
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceM,
                vertical: 12,
              ),
              minimumSize: const Size(0, AppDimensions.buttonHeight),
            ),
            child: Text(text),
          );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
