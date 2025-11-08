import 'package:flutter/material.dart';
import '../../domain/models/widget_config.dart';
import '../../domain/models/widget_settings.dart';
import 'minimalist_theme.dart';

/// Service for generating dynamic themes based on widget configuration
///
/// Priority order (highest to lowest):
/// 1. URL parameters (WidgetConfig) - runtime overrides
/// 2. Firestore settings (WidgetSettings.themeOptions) - persistent settings
/// 3. Default theme (Minimalist)
class DynamicThemeService {
  /// Generate ThemeData based on configuration
  static ThemeData generateTheme({
    required WidgetConfig config,
    WidgetSettings? settings,
    required Brightness brightness,
  }) {
    // Start with base theme (Minimalist as default)
    final ThemeData baseTheme = brightness == Brightness.light
        ? MinimalistTheme.light
        : MinimalistTheme.dark;

    // If there are custom colors from URL or Firestore, create custom theme
    final hasUrlColors = config.primaryColor != null ||
                         config.accentColor != null ||
                         config.backgroundColor != null ||
                         config.textColor != null;

    final hasFirestoreColors = settings?.themeOptions?.primaryColor != null ||
                                settings?.themeOptions?.accentColor != null;

    if (hasUrlColors || hasFirestoreColors) {
      // Get colors with priority: URL > Firestore > Default
      final primaryColor = config.primaryColor ??
                           _parseHexColor(settings?.themeOptions?.primaryColor) ??
                           baseTheme.colorScheme.primary;

      final accentColor = config.accentColor ??
                          _parseHexColor(settings?.themeOptions?.accentColor) ??
                          baseTheme.colorScheme.tertiary;

      final backgroundColor = config.backgroundColor ??
                              baseTheme.colorScheme.surface;

      final textColor = config.textColor ??
                        baseTheme.colorScheme.onSurface;

      // Create custom color scheme
      final customColorScheme = ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: _getContrastColor(primaryColor),
        primaryContainer: primaryColor.withValues(alpha: 0.1),
        onPrimaryContainer: primaryColor,

        secondary: accentColor,
        onSecondary: _getContrastColor(accentColor),
        secondaryContainer: accentColor.withValues(alpha: 0.1),
        onSecondaryContainer: accentColor,

        tertiary: accentColor,
        onTertiary: _getContrastColor(accentColor),
        tertiaryContainer: accentColor.withValues(alpha: 0.1),
        onTertiaryContainer: accentColor,

        error: baseTheme.colorScheme.error,
        onError: baseTheme.colorScheme.onError,
        errorContainer: baseTheme.colorScheme.errorContainer,
        onErrorContainer: baseTheme.colorScheme.onErrorContainer,

        surface: backgroundColor,
        onSurface: textColor,
        surfaceContainerHighest: brightness == Brightness.light
            ? backgroundColor.withValues(alpha: 0.95)
            : _lighten(backgroundColor, 0.05),

        outline: textColor.withValues(alpha: 0.2),
        outlineVariant: textColor.withValues(alpha: 0.1),

        shadow: Colors.black.withValues(alpha: 0.12),
        scrim: Colors.black.withValues(alpha: 0.5),
        inverseSurface: brightness == Brightness.light ? Colors.black : Colors.white,
        onInverseSurface: brightness == Brightness.light ? Colors.white : Colors.black,
        inversePrimary: brightness == Brightness.light ? Colors.white : Colors.black,
      );

      // Return theme with custom color scheme
      return baseTheme.copyWith(
        colorScheme: customColorScheme,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
      );
    }

    // Return default minimalist theme
    return baseTheme;
  }

  /// Get the brightness based on theme mode
  static Brightness getBrightness({
    required String themeMode,
    required BuildContext context,
  }) {
    switch (themeMode.toLowerCase()) {
      case 'light':
        return Brightness.light;
      case 'dark':
        return Brightness.dark;
      case 'system':
      default:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  /// Determine if branding badge should be shown
  static bool shouldShowBranding({
    required WidgetConfig config,
    WidgetSettings? settings,
  }) {
    // URL parameter has priority
    if (!config.showPoweredByBadge) {
      return false;
    }

    // Check Firestore settings
    if (settings?.themeOptions?.showBranding == false) {
      return false;
    }

    // Default: show branding
    return true;
  }

  /// Parse hex color string to Color
  static Color? _parseHexColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;

    try {
      // Remove # if present
      String colorString = hexColor.replaceAll('#', '');

      // Add FF for opacity if not present
      if (colorString.length == 6) {
        colorString = 'FF$colorString';
      }

      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      return null;
    }
  }

  /// Get a contrasting color (white or black) for text on a background
  static Color _getContrastColor(Color background) {
    // Calculate relative luminance
    final luminance = background.computeLuminance();

    // Use white text on dark backgrounds, black text on light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Lighten a color by a percentage (0.0 - 1.0)
  static Color _lighten(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final lightened = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );

    return lightened.toColor();
  }

  /// Get theme name for display
  static String getThemeName({
    required WidgetConfig config,
    WidgetSettings? settings,
  }) {
    if (config.primaryColor != null || config.accentColor != null) {
      return 'Custom';
    }

    if (settings?.themeOptions?.primaryColor != null) {
      return 'Custom (Firestore)';
    }

    return 'Minimalist';
  }
}
