/// Calendar view types
enum CalendarViewType {
  month,
  year;

  /// Minimum width required for desktop/year view
  static const double desktopMinWidth = 1024;

  String get label => switch (this) {
    CalendarViewType.month => 'Month',
    CalendarViewType.year => 'Year',
  };

  /// Check if this view is available on the given screen size
  bool isAvailableForWidth(double width) =>
      this == CalendarViewType.month || width >= desktopMinWidth;

  /// Get default view for screen width
  static CalendarViewType getDefaultForWidth(double width) =>
      width >= desktopMinWidth ? CalendarViewType.year : CalendarViewType.month;
}
