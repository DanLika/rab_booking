/// Calendar view mode for owner dashboard
///
/// Defines the three available calendar views:
/// - week: 7-day grid view (Monday-Sunday)
/// - month: 28-31 day grid view
/// - timeline: Gantt-style timeline view with booking blocks
enum CalendarViewMode {
  week,
  month,
  timeline;

  String get displayName {
    switch (this) {
      case CalendarViewMode.week:
        return 'Week';
      case CalendarViewMode.month:
        return 'Month';
      case CalendarViewMode.timeline:
        return 'Timeline';
    }
  }

  String get routePath {
    switch (this) {
      case CalendarViewMode.week:
        return '/calendar/week';
      case CalendarViewMode.month:
        return '/calendar/month';
      case CalendarViewMode.timeline:
        return '/calendar/timeline';
    }
  }

  /// SharedPreferences key for persistence
  static const String prefsKey = 'owner_calendar_view_mode';

  /// Parse from string (for SharedPreferences)
  static CalendarViewMode fromString(String? value) {
    switch (value) {
      case 'week':
        return CalendarViewMode.week;
      case 'month':
        return CalendarViewMode.month;
      case 'timeline':
        return CalendarViewMode.timeline;
      default:
        return CalendarViewMode.week; // Default
    }
  }
}
