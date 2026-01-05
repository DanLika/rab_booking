import 'package:flutter/material.dart';

/// Centralized calendar cell background colors
/// Ensures consistent styling across timeline and week/month calendar views
class CalendarCellColors {
  CalendarCellColors._();

  // ============================================================================
  // DARK THEME COLORS
  // ============================================================================

  /// Weekend cell background (dark theme)
  static const Color weekendDark = Color(0xFF2A2535);

  /// Regular day cell background (dark theme)
  static const Color regularDark = Color(0xFF1E1E28);

  /// Summary bar background (dark theme)
  static const Color summaryBadgeDark = Color(0xFF2D2D3A);

  // ============================================================================
  // LIGHT THEME COLORS
  // ============================================================================

  /// Weekend cell background (light theme)
  static const Color weekendLight = Color(0xFFF8F5FC);

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
    double todayAlpha = 0.12,
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

  /// Get today highlight color with custom alpha
  static Color getTodayHighlight(BuildContext context, {double alpha = 0.12}) {
    return Theme.of(
      context,
    ).colorScheme.primary.withAlpha((alpha * 255).toInt());
  }
}
