/// Calendar view types
enum CalendarViewType {
  week,
  month,
  year;

  String get label {
    switch (this) {
      case CalendarViewType.week:
        return 'Week';
      case CalendarViewType.month:
        return 'Month';
      case CalendarViewType.year:
        return 'Year';
    }
  }

  /// Check if this view is available on the given screen size
  bool isAvailableForWidth(double width) {
    // Year view only on desktop (>1024px)
    if (this == CalendarViewType.year) {
      return width >= 1024;
    }
    // Week and Month available on all devices
    return true;
  }

  /// Get default view for screen width
  static CalendarViewType getDefaultForWidth(double width) {
    // Desktop: default to year view
    if (width >= 1024) {
      return CalendarViewType.year;
    }
    // Tablet and Mobile: default to month view
    else {
      return CalendarViewType.month;
    }
  }
}
