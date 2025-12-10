/// Widget display modes for different client needs
enum WidgetMode {
  /// Calendar only - no booking, just contact info
  /// Use case: Client manages bookings manually via phone/email
  calendarOnly,

  /// Calendar + booking form, but no payment (pending approval)
  /// Use case: Owner wants to approve each booking manually
  bookingPending,

  /// Full booking flow with payment options (Stripe, Bank Transfer)
  /// Use case: Automated booking system with instant confirmation
  bookingInstant;

  /// Get user-friendly display name
  String get displayName => switch (this) {
    WidgetMode.calendarOnly => 'Samo kalendar',
    WidgetMode.bookingPending => 'Rezervacija bez plaćanja',
    WidgetMode.bookingInstant => 'Puna rezervacija sa plaćanjem',
  };

  /// Get description for each mode
  String get description => switch (this) {
    WidgetMode.calendarOnly =>
      'Gosti vide samo dostupnost i kontakt informacije. Rezervacije kreirate ručno.',
    WidgetMode.bookingPending =>
      'Gosti mogu kreirati rezervaciju, ali ona čeka vašu potvrdu. Plaćanje dogovarate privatno.',
    WidgetMode.bookingInstant =>
      'Gosti mogu odmah rezervisati i platiti. Rezervacija se automatski potvrđuje nakon uplate.',
  };

  /// Convert from string (for URL parsing and database)
  static WidgetMode fromString(String value) => switch (value.toLowerCase()) {
    'calendar_only' || 'calendaronly' => WidgetMode.calendarOnly,
    'booking_pending' || 'bookingpending' => WidgetMode.bookingPending,
    'booking_instant' || 'bookinginstant' => WidgetMode.bookingInstant,
    _ => WidgetMode.bookingInstant, // Default to full flow
  };

  /// Convert to string for URL and database
  String toStringValue() => switch (this) {
    WidgetMode.calendarOnly => 'calendar_only',
    WidgetMode.bookingPending => 'booking_pending',
    WidgetMode.bookingInstant => 'booking_instant',
  };
}
