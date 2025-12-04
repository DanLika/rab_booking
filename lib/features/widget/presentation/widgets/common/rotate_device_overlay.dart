import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';

/// Overlay prompting user to rotate device to landscape mode.
///
/// Displayed when year calendar view is active but device is in portrait mode.
/// Provides option to switch to month view instead.
///
/// Usage:
/// ```dart
/// if (_shouldShowRotateOverlay()) {
///   RotateDeviceOverlay(
///     isDarkMode: isDarkMode,
///     colors: colors,
///     onSwitchToMonthView: () {
///       ref.read(calendarViewProvider.notifier).state = CalendarViewType.month;
///     },
///   ),
/// }
/// ```
class RotateDeviceOverlay extends StatelessWidget {
  /// Whether dark mode is active
  final bool isDarkMode;

  /// Color scheme for theming
  final WidgetColorScheme colors;

  /// Callback when user taps "Switch to Month View" button
  final VoidCallback onSwitchToMonthView;

  const RotateDeviceOverlay({
    super.key,
    required this.isDarkMode,
    required this.colors,
    required this.onSwitchToMonthView,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive icon size: smaller on very small screens
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth < 360 ? 56.0 : 80.0;

    return Positioned.fill(
      child: Container(
        color: colors.backgroundPrimary.withValues(alpha: 0.95),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.screen_rotation,
                  size: iconSize,
                  color: colors.textPrimary,
                ),
                const SizedBox(height: SpacingTokens.l),
                Text(
                  'Rotate Your Device',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeXXL,
                    fontWeight: TypographyTokens.bold,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacingTokens.m),
                Text(
                  'For the best year view experience, please rotate your device to landscape mode.',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeM,
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacingTokens.xl),
                ElevatedButton(
                  onPressed: onSwitchToMonthView,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? ColorTokens.pureWhite
                        : ColorTokens.pureBlack,
                    foregroundColor: isDarkMode
                        ? ColorTokens.pureBlack
                        : ColorTokens.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.xl,
                      vertical: SpacingTokens.m,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderTokens.circularMedium,
                    ),
                  ),
                  child: const Text(
                    'Switch to Month View',
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeM,
                      fontWeight: TypographyTokens.semiBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
