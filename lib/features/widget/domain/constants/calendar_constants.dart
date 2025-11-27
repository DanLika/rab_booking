/// Constants for calendar-related functionality
///
/// Centralizes magic numbers and default values used across calendar providers
/// to ensure consistency and easier maintenance.
class CalendarConstants {
  CalendarConstants._(); // Private constructor - static access only

  // ============================================
  // Weekend Configuration
  // ============================================

  /// Default weekend days (ISO weekday: Monday=1, Sunday=7)
  /// Saturday (6) and Sunday (7) are default weekend days
  static const List<int> defaultWeekendDays = [6, 7];

  // ============================================
  // Pricing Defaults
  // ============================================

  /// Fallback base price when unit price is not available
  /// Used only as last resort - units should always have pricePerNight set
  static const double fallbackBasePrice = 100.0;

  // ============================================
  // Stay Duration
  // ============================================

  /// Default minimum stay nights when not specified
  static const int defaultMinNights = 1;

  /// Default maximum stay nights when not specified (null = no limit)
  static const int? defaultMaxNights = null;

  // ============================================
  // iCal Sync
  // ============================================

  /// Minutes after which iCal sync is considered stale
  /// Used to warn users about potential double-booking during sync delays
  static const int staleSyncThresholdMinutes = 30;

  /// Display text for feeds that have never been synced
  static const String neverSyncedText = 'External calendars have never been synced';

  // ============================================
  // Calendar Display
  // ============================================

  /// Number of months to load before current month for gap detection
  static const int monthsBeforeForGapDetection = 1;

  /// Number of months to load after current month for gap detection
  static const int monthsAfterForGapDetection = 1;
}
