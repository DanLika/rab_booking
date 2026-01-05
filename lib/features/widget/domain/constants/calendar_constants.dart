/// Calendar-specific constants for gap detection and display logic.
///
/// For general booking/pricing constants, see [WidgetConstants].
abstract final class CalendarConstants {
  /// Number of months to load before current month for gap detection.
  static const int monthsBeforeForGapDetection = 1;

  /// Number of months to load after current month for gap detection.
  static const int monthsAfterForGapDetection = 1;
}
