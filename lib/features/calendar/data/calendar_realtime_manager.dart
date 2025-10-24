import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/calendar_update_event.dart';

/// Manages real-time subscriptions for calendar data
///
/// Provides a centralized way to subscribe to calendar changes
/// and emit structured events for UI updates.
class CalendarRealtimeManager {
  final SupabaseClient _supabase;
  RealtimeChannel? _bookingsChannel;
  RealtimeChannel? _availabilityChannel;

  final StreamController<CalendarUpdateEvent> _updatesController =
      StreamController<CalendarUpdateEvent>.broadcast();

  /// Stream of calendar update events
  Stream<CalendarUpdateEvent> get updates => _updatesController.stream;

  CalendarRealtimeManager(this._supabase);

  /// Subscribe to calendar changes for a specific unit
  ///
  /// This creates two separate channels:
  /// - One for bookings table changes
  /// - One for calendar_availability table changes
  ///
  /// Both channels filter by unit_id to only receive relevant updates.
  void subscribeToUnit(String unitId) {
    // Unsubscribe from previous channels
    unsubscribe();

    // Subscribe to bookings changes
    _bookingsChannel = _supabase
        .channel('bookings:unit_$unitId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'unit_id',
            value: unitId,
          ),
          callback: (payload) {
            _handleBookingChange(payload);
          },
        )
        .subscribe();

    // Subscribe to availability changes
    _availabilityChannel = _supabase
        .channel('availability:unit_$unitId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'calendar_availability',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'unit_id',
            value: unitId,
          ),
          callback: (payload) {
            _handleAvailabilityChange(payload);
          },
        )
        .subscribe();
  }

  /// Handle booking table changes
  void _handleBookingChange(PostgresChangePayload payload) {
    final event = CalendarUpdateEvent.fromRealtimePayload(
      type: CalendarUpdateType.booking,
      eventType: payload.eventType.name,
      newRecord: payload.newRecord,
      oldRecord: payload.oldRecord,
    );
    _updatesController.add(event);
  }

  /// Handle availability table changes
  void _handleAvailabilityChange(PostgresChangePayload payload) {
    final event = CalendarUpdateEvent.fromRealtimePayload(
      type: CalendarUpdateType.availability,
      eventType: payload.eventType.name,
      newRecord: payload.newRecord,
      oldRecord: payload.oldRecord,
    );
    _updatesController.add(event);
  }

  /// Unsubscribe from all channels
  void unsubscribe() {
    _bookingsChannel?.unsubscribe();
    _availabilityChannel?.unsubscribe();
    _bookingsChannel = null;
    _availabilityChannel = null;
  }

  /// Dispose manager and close streams
  void dispose() {
    unsubscribe();
    _updatesController.close();
  }

  /// Check if currently subscribed
  bool get isSubscribed =>
      _bookingsChannel != null || _availabilityChannel != null;
}
