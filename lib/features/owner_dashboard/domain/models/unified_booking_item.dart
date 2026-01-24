import '../../../../shared/models/booking_model.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import 'ical_feed.dart';

/// Unified wrapper for displaying both regular bookings and imported reservations
/// in a single sorted list.
///
/// This enables the "All" filter to show both types together, sorted by creation date.
sealed class UnifiedBookingItem {
  /// Check-in date
  DateTime get checkIn;

  /// Check-out date
  DateTime get checkOut;

  /// Creation date for sorting (newest created first)
  DateTime get createdAt;

  /// Unique identifier
  String get id;

  /// Guest name for display
  String get guestName;

  /// Source identifier (widget, manual, booking_com, airbnb, etc.)
  String get source;

  /// Whether this is an imported/external reservation
  bool get isImported;
}

/// Regular booking created in BookBed
class RegularBookingItem implements UnifiedBookingItem {
  final OwnerBooking ownerBooking;

  const RegularBookingItem(this.ownerBooking);

  BookingModel get booking => ownerBooking.booking;

  @override
  DateTime get checkIn => booking.checkIn;

  @override
  DateTime get checkOut => booking.checkOut;

  @override
  DateTime get createdAt => booking.createdAt;

  @override
  String get id => booking.id;

  @override
  String get guestName => booking.guestName ?? 'Unknown Guest';

  @override
  String get source => booking.source ?? 'direct';

  @override
  bool get isImported => booking.isExternalBooking;
}

/// Imported reservation from iCal (Booking.com, Airbnb, etc.)
class ImportedBookingItem implements UnifiedBookingItem {
  final IcalEvent event;

  const ImportedBookingItem(this.event);

  @override
  DateTime get checkIn => event.startDate;

  @override
  DateTime get checkOut => event.endDate;

  @override
  DateTime get createdAt => event.createdAt;

  @override
  String get id => 'ical_${event.id}';

  @override
  String get guestName =>
      event.guestName.isNotEmpty ? event.guestName : 'Unknown Guest';

  @override
  String get source => event.source;

  @override
  bool get isImported => true;
}
