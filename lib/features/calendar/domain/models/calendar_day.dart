import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_day.freezed.dart';
part 'calendar_day.g.dart';

/// Represents the status of a single day in the calendar
enum DayStatus {
  available,       // Fully available (gray)
  booked,          // Fully booked (blue-gray)
  checkIn,         // Check-in day (bottom-right red triangle)
  checkOut,        // Check-out day (top-left red triangle)
  sameDayTurnover, // Check-out AND check-in same day (both triangles)
  blocked,         // Blocked by owner (dark gray with X)
}

/// Represents a single day in the calendar with its booking status
@freezed
class CalendarDay with _$CalendarDay {
  const factory CalendarDay({
    required DateTime date,
    required DayStatus status,
    String? bookingId,
    DateTime? checkInTime,  // e.g., 15:00
    DateTime? checkOutTime, // e.g., 10:00
    double? price,  // Daily price for this date
  }) = _CalendarDay;

  factory CalendarDay.fromJson(Map<String, dynamic> json) =>
      _$CalendarDayFromJson(json);
}

/// Calendar availability block (owner-blocked dates)
@freezed
class CalendarAvailability with _$CalendarAvailability {
  const factory CalendarAvailability({
    required String id,
    required String unitId,
    required String ownerId,
    required DateTime blockedFrom,
    required DateTime blockedTo,
    @Default('maintenance') String reason,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CalendarAvailability;

  factory CalendarAvailability.fromJson(Map<String, dynamic> json) =>
      _$CalendarAvailabilityFromJson(json);
}

/// Calendar settings for a specific unit
@freezed
class CalendarSettings with _$CalendarSettings {
  const factory CalendarSettings({
    required String id,
    required String unitId,
    @Default('15:00:00') String checkInTime,
    @Default('10:00:00') String checkOutTime,
    @Default(1) int minNights,
    @Default(365) int maxNights,
    @Default(1) int minAdvanceDays,
    @Default(365) int maxAdvanceDays,
    @Default(true) bool allowSameDayTurnover,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CalendarSettings;

  factory CalendarSettings.fromJson(Map<String, dynamic> json) =>
      _$CalendarSettingsFromJson(json);
}

/// Response from get_calendar_data() function
@freezed
class CalendarDataResponse with _$CalendarDataResponse {
  const factory CalendarDataResponse({
    required DateTime date,
    required String status, // 'available', 'booked', 'check_in', 'check_out', 'blocked'
    String? bookingId,
    String? checkInTime,
    String? checkOutTime,
  }) = _CalendarDataResponse;

  factory CalendarDataResponse.fromJson(Map<String, dynamic> json) =>
      _$CalendarDataResponseFromJson(json);
}

/// Calendar state with selection and loading status
@freezed
class CalendarState with _$CalendarState {
  const factory CalendarState({
    required List<CalendarDay> days,
    @JsonKey(includeFromJson: false, includeToJson: false)
    DateTimeRange? selectedRange,
    @Default(false) bool isLoading,
    String? error,
  }) = _CalendarState;

  factory CalendarState.fromJson(Map<String, dynamic> json) =>
      _$CalendarStateFromJson(json);
}

/// Date time range for selection
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({
    required this.start,
    required this.end,
  });

  int get days => end.difference(start).inDays + 1;
}

/// Extension to convert database status string to DayStatus enum
extension DayStatusExtension on String {
  DayStatus toDayStatus() {
    switch (toLowerCase()) {
      case 'available':
        return DayStatus.available;
      case 'booked':
        return DayStatus.booked;
      case 'check_in':
        return DayStatus.checkIn;
      case 'check_out':
        return DayStatus.checkOut;
      case 'same_day_turnover':
        return DayStatus.sameDayTurnover;
      case 'blocked':
        return DayStatus.blocked;
      default:
        return DayStatus.available;
    }
  }
}
