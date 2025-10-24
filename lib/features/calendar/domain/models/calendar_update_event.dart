import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_update_event.freezed.dart';
part 'calendar_update_event.g.dart';

/// Type of calendar update
enum CalendarUpdateType {
  booking,
  availability,
}

/// Action performed on calendar data
enum CalendarUpdateAction {
  insert,
  update,
  delete,
}

/// Real-time calendar update event
@freezed
class CalendarUpdateEvent with _$CalendarUpdateEvent {
  const factory CalendarUpdateEvent({
    required CalendarUpdateType type,
    required CalendarUpdateAction action,
    required Map<String, dynamic> data,
    required DateTime timestamp,
    String? unitId,
    String? bookingId,
  }) = _CalendarUpdateEvent;

  factory CalendarUpdateEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarUpdateEventFromJson(json);

  /// Create from Supabase realtime payload
  factory CalendarUpdateEvent.fromRealtimePayload({
    required CalendarUpdateType type,
    required String eventType,
    required Map<String, dynamic>? newRecord,
    required Map<String, dynamic>? oldRecord,
  }) {
    final action = _mapEventType(eventType);
    final data = newRecord ?? oldRecord ?? {};

    return CalendarUpdateEvent(
      type: type,
      action: action,
      data: data,
      timestamp: DateTime.now(),
      unitId: data['unit_id'] as String?,
      bookingId: data['id'] as String?,
    );
  }

  static CalendarUpdateAction _mapEventType(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'INSERT':
        return CalendarUpdateAction.insert;
      case 'UPDATE':
        return CalendarUpdateAction.update;
      case 'DELETE':
        return CalendarUpdateAction.delete;
      default:
        return CalendarUpdateAction.update;
    }
  }
}
