import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../l10n/widget_translations.dart';

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
  // Layout constants
  static const double _smallScreenBreakpoint = 360;
  static const double _iconSizeSmall = 56.0;
  static const double _iconSizeNormal = 80.0;
  static const double _backgroundOpacity = 0.95;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Color scheme for theming
  final WidgetColorScheme colors;

  /// Callback when user taps "Switch to Month View" button
  final VoidCallback onSwitchToMonthView;

  /// Translations for localization
  final WidgetTranslations translations;

  const RotateDeviceOverlay({
    super.key,
    required this.isDarkMode,
    required this.colors,
    required this.onSwitchToMonthView,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < _smallScreenBreakpoint;
    final iconSize = isSmallScreen ? _iconSizeSmall : _iconSizeNormal;

    return Positioned.fill(
      child: Container(
        color: colors.backgroundPrimary.withValues(alpha: _backgroundOpacity),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.screen_rotation, size: iconSize, color: colors.textPrimary),
                const SizedBox(height: SpacingTokens.l),
                // Bug #51 Fix: Add Semantics for rotate prompt
                Semantics(
                  label: translations.rotateYourDevice,
                  hint: translations.rotateForBestExperience,
                  header: true,
                  child: Column(
                    children: [
                      Text(
                        translations.rotateYourDevice,
                        style: TextStyle(
                          fontSize: TypographyTokens.fontSizeXXL,
                          fontWeight: TypographyTokens.bold,
                          color: colors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: SpacingTokens.m),
                      Text(
                        translations.rotateForBestExperience,
                        style: TextStyle(fontSize: TypographyTokens.fontSizeM, color: colors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SpacingTokens.xl),
                _buildSwitchButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchButton() {
    final backgroundColor = isDarkMode ? ColorTokens.pureWhite : ColorTokens.pureBlack;
    final foregroundColor = isDarkMode ? ColorTokens.pureBlack : ColorTokens.pureWhite;

    // Bug #51 Fix: Add Semantics for button
    return Semantics(
      label: translations.switchToMonthView,
      hint: translations.rotateForBestExperience,
      button: true,
      child: ElevatedButton(
        onPressed: onSwitchToMonthView,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xl, vertical: SpacingTokens.m),
          shape: RoundedRectangleBorder(borderRadius: BorderTokens.circularMedium),
        ),
        child: Text(
          translations.switchToMonthView,
          style: const TextStyle(fontSize: TypographyTokens.fontSizeM, fontWeight: TypographyTokens.semiBold),
        ),
      ),
    );
  }
}
