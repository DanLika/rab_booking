import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/haptic_service.dart';

/// Primary button widget with loading and disabled states
///
/// Example usage:
/// ```dart
/// PrimaryButton(
///   text: 'Submit',
///   onPressed: () async {
///     await submitForm();
///   },
///   isLoading: isSubmitting,
/// )
/// ```
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    super.key,
  });

  /// Button text label
  final String text;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Show loading indicator
  final bool isLoading;

  /// Optional icon to display before text
  final IconData? icon;

  /// Whether button should take full width
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    // Wrap onPressed with haptic feedback
    final wrappedOnPressed = (isLoading || onPressed == null)
        ? null
        : () async {
            await HapticService.buttonPress();
            onPressed!();
          };

    final button = icon != null
        ? FilledButton.icon(
            onPressed: wrappedOnPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon),
            label: Text(text),
            style: FilledButton.styleFrom(
              // Use design system padding (24px horizontal, 12px vertical for 48px height)
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceM,
                vertical: 12,
              ),
              minimumSize: const Size(0, AppDimensions.buttonHeight),
              animationDuration: const Duration(milliseconds: 100),
            ),
          )
        : FilledButton(
            onPressed: wrappedOnPressed,
            style: FilledButton.styleFrom(
              // Use design system padding (24px horizontal, 12px vertical for 48px height)
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceM,
                vertical: 12,
              ),
              minimumSize: const Size(0, AppDimensions.buttonHeight),
              animationDuration: const Duration(milliseconds: 100),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(text),
          );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
