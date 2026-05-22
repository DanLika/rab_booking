/// Source classification for an [AvailabilityWindow].
///
/// Mirrors the discriminator returned by the `getUnitAvailability` Cloud
/// Function (`functions/src/availability.ts`).
enum AvailabilityWindowSource {
  /// Live BookBed booking (status pending or confirmed).
  booking,

  /// Manually blocked day (daily_prices.available == false).
  manualBlock,

  /// External iCal-imported block (Airbnb, Booking.com, ...).
  icalExternal;

  static AvailabilityWindowSource fromWire(String value) {
    switch (value) {
      case 'booking':
        return AvailabilityWindowSource.booking;
      case 'manual_block':
        return AvailabilityWindowSource.manualBlock;
      case 'ical_external':
        return AvailabilityWindowSource.icalExternal;
    }
    return AvailabilityWindowSource.booking;
  }
}

/// PII-stripped availability window served by the
/// `getUnitAvailability` callable.
class AvailabilityWindow {
  final DateTime start;
  final DateTime end;
  final AvailabilityWindowSource source;

  /// Set only for [AvailabilityWindowSource.icalExternal] — the iCal
  /// platform name (e.g. "Airbnb"). Always null for booking/manual_block.
  final String? platform;

  const AvailabilityWindow({
    required this.start,
    required this.end,
    required this.source,
    this.platform,
  });

  factory AvailabilityWindow.fromJson(Map<String, dynamic> json) {
    return AvailabilityWindow(
      start: DateTime.parse(json['start'] as String).toUtc(),
      end: DateTime.parse(json['end'] as String).toUtc(),
      source: AvailabilityWindowSource.fromWire(json['source'] as String),
      platform: json['platform'] as String?,
    );
  }
}
