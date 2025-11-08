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
  String get displayName {
    switch (this) {
      case WidgetMode.calendarOnly:
        return 'Samo kalendar';
      case WidgetMode.bookingPending:
        return 'Rezervacija bez plaćanja';
      case WidgetMode.bookingInstant:
        return 'Puna rezervacija sa plaćanjem';
    }
  }

  /// Get description for each mode
  String get description {
    switch (this) {
      case WidgetMode.calendarOnly:
        return 'Gosti vide samo dostupnost i kontakt informacije. Rezervacije kreirate ručno.';
      case WidgetMode.bookingPending:
        return 'Gosti mogu kreirati rezervaciju, ali ona čeka vašu potvrdu. Plaćanje dogovarate privatno.';
      case WidgetMode.bookingInstant:
        return 'Gosti mogu odmah rezervisati i platiti. Rezervacija se automatski potvrđuje nakon uplate.';
    }
  }

  /// Convert from string (for URL parsing and database)
  static WidgetMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'calendar_only':
      case 'calendaronly':
        return WidgetMode.calendarOnly;
      case 'booking_pending':
      case 'bookingpending':
        return WidgetMode.bookingPending;
      case 'booking_instant':
      case 'bookinginstant':
        return WidgetMode.bookingInstant;
      default:
        return WidgetMode.bookingInstant; // Default to full flow
    }
  }

  /// Convert to string for URL and database
  String toStringValue() {
    switch (this) {
      case WidgetMode.calendarOnly:
        return 'calendar_only';
      case WidgetMode.bookingPending:
        return 'booking_pending';
      case WidgetMode.bookingInstant:
        return 'booking_instant';
    }
  }
}
