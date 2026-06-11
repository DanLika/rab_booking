import 'package:flutter/material.dart';

/// Centralized calendar cell background colors
/// Ensures consistent styling across timeline and week/month calendar views
class CalendarCellColors {
  CalendarCellColors._();

  // ============================================================================
  // DARK THEME COLORS
  // ============================================================================

  /// Weekend cell background (dark theme) — handoff golden tint
  /// rgba(255,184,77,.05) composited over the regular dark cell.
  static const Color weekendDark = Color(0xFF29262A);

  /// Regular day cell background (dark theme)
  static const Color regularDark = Color(0xFF1E1E28);

  /// Summary bar background (dark theme)
  static const Color summaryBadgeDark = Color(0xFF2D2D3A);

  // ============================================================================
  // LIGHT THEME COLORS
  // ============================================================================

  /// Weekend cell background (light theme) — handoff golden tint
  /// rgba(255,184,77,.05) composited over white.
  static const Color weekendLight = Color(0xFFFFFBF6);

  /// Regular day cell background (light theme)
  static const Color regularLight = Colors.white;

  /// Summary bar background (light theme)
  static const Color summaryBadgeLight = Color(0xFFF0F0F5);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get cell background color based on day type and theme
  static Color getCellBackground({
    required BuildContext context,
    required bool isToday,
    required bool isWeekend,
    // Handoff primary-tint-bg: 6% light / 8% dark when not overridden.
    double? todayAlpha,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    if (isToday) {
      final alpha = todayAlpha ?? (isDark ? 0.08 : 0.06);
      return primary.withAlpha((alpha * 255).toInt());
    }

    if (isWeekend) {
      return isDark ? weekendDark : weekendLight;
    }

    return isDark ? regularDark : regularLight;
  }

  /// Get summary cell background color based on day type
  static Color getSummaryCellBackground({
    required BuildContext context,
    required bool isToday,
    required bool isWeekend,
    double todayAlpha = 0.18,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    if (isToday) {
      return primary.withAlpha((todayAlpha * 255).toInt());
    }

    if (isWeekend) {
      return isDark ? weekendDark : weekendLight;
    }

    return isDark ? regularDark : regularLight;
  }

  /// Get summary badge background color
  static Color getSummaryBadgeBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? summaryBadgeDark : summaryBadgeLight;
  }

  /// Get today highlight color with custom alpha (handoff default:
  /// primary-tint-bg 6% light / 8% dark).
  static Color getTodayHighlight(BuildContext context, {double? alpha}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final a = alpha ?? (isDark ? 0.08 : 0.06);
    return Theme.of(context).colorScheme.primary.withAlpha((a * 255).toInt());
  }
}
