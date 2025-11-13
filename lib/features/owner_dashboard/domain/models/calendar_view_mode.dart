/// Calendar view mode for owner dashboard
///
/// Defines the two available calendar views:
/// - week: 7-day grid view (Monday-Sunday)
/// - timeline: Gantt-style timeline view with booking blocks
enum CalendarViewMode {
  week,
  timeline;

  String get displayName {
    switch (this) {
      case CalendarViewMode.week:
        return 'Tjedni prikaz';
      case CalendarViewMode.timeline:
        return 'Gantt prikaz';
    }
  }

  String get routePath {
    switch (this) {
      case CalendarViewMode.week:
        return '/calendar/week';
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
      case 'timeline':
        return CalendarViewMode.timeline;
      default:
        return CalendarViewMode.week; // Default
    }
  }
}
