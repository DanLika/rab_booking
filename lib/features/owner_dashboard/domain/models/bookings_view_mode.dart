/// Bookings list view mode for owner dashboard
///
/// Defines the two available bookings list views:
/// - card: Card-based list view (mobile-friendly)
/// - table: Table-based list view (desktop-optimized)
enum BookingsViewMode {
  card,
  table;

  String get displayName {
    switch (this) {
      case BookingsViewMode.card:
        return 'Card View';
      case BookingsViewMode.table:
        return 'Table View';
    }
  }

  /// SharedPreferences key for persistence
  static const String prefsKey = 'owner_bookings_view_mode';

  /// Parse from string (for SharedPreferences)
  static BookingsViewMode fromString(String? value) {
    switch (value) {
      case 'card':
        return BookingsViewMode.card;
      case 'table':
        return BookingsViewMode.table;
      default:
        // Default based on screen size (handled in provider)
        return BookingsViewMode.card;
    }
  }
}
