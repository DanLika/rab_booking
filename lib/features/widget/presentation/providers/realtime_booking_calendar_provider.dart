import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/repositories/firebase_booking_calendar_repository.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../domain/repositories/i_booking_calendar_repository.dart';
import '../../../../shared/providers/widget_repository_providers.dart';
import 'widget_visibility_provider.dart';

part 'realtime_booking_calendar_provider.g.dart';

/// Debounce duration for calendar streams to reduce rapid UI updates
/// PERFORMANCE: Reduced from 150ms to 50ms for faster initial load.
/// Still prevents UI thrashing from rapid booking changes while minimizing perceived latency.
const _calendarDebounceMs = 50;

/// Convert DateTime key to String key (yyyy-MM-dd format)
///
/// Normalizes date to UTC before formatting to ensure consistent keys
/// regardless of timezone. Repository returns UTC DateTime objects, so
/// we must format them as UTC to avoid timezone offset issues.
String _dateToKey(DateTime date) {
  // Normalize to UTC by extracting year/month/day components
  // This ensures we format the correct day regardless of timezone
  final utcDate = DateTime.utc(date.year, date.month, date.day);
  return DateFormat('yyyy-MM-dd').format(utcDate);
}

/// Repository provider (V2 with price support)
/// Returns interface type for better testability and flexibility
@riverpod
IBookingCalendarRepository bookingCalendarRepository(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseBookingCalendarRepository(firestore);
}

/// Realtime calendar data provider for year view.
/// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
///
/// OPTIMIZED:
/// - Uses debounce to reduce rapid UI updates when multiple
///   booking changes occur in quick succession.
/// - Auto-dispose (no `keepAlive: true`): when the consumer (Year or Month
///   widget) stops watching, the underlying `getUnitAvailability` CF poll
///   loop in `FirebaseAvailabilityRepository.streamAvailability` cancels.
///   The previous `keepAlive: true` design hoarded one poll loop per
///   `(propertyId, unitId, year, minNights, …)` tuple — paginating months
///   left every prior tuple polling indefinitely.
/// - Pauses on hidden tab: gated on [widgetVisibilityProvider]. When the
///   browser fires `document.visibilitychange` to hidden, this returns
///   `Stream.empty()`, the CF poll cancels, and the calendar UI freezes on
///   its last paint. On resume, the real stream re-subscribes and
///   `streamAvailability` issues an immediate first poll.
/// - Accepts settings parameters to eliminate redundant widgetSettings fetch.
@riverpod
Stream<Map<String, CalendarDateInfo>> realtimeYearCalendar(
  Ref ref,
  String propertyId,
  String unitId,
  int year,
  int minNights,
  int minDaysAdvance,
  int maxDaysAdvance,
) {
  final visible = ref.watch(widgetVisibilityProvider);
  if (!visible) {
    // Pause: close the stream so upstream CF poll cancels.
    // Riverpod keeps the prior `AsyncValue.data(snapshot)` visible to
    // the calendar widget.
    return const Stream<Map<String, CalendarDateInfo>>.empty();
  }
  final repository = ref.watch(bookingCalendarRepositoryProvider);
  return repository
      .watchYearCalendarDataOptimized(
        propertyId: propertyId,
        unitId: unitId,
        year: year,
        minNights: minNights,
        minDaysAdvance: minDaysAdvance,
        maxDaysAdvance: maxDaysAdvance,
      )
      .debounceTime(const Duration(milliseconds: _calendarDebounceMs))
      .map(
        (dateTimeMap) =>
            dateTimeMap.map((date, info) => MapEntry(_dateToKey(date), info)),
      );
}

/// Realtime calendar data provider for month view.
/// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
///
/// OPTIMIZED:
/// - Uses debounce to reduce rapid UI updates when multiple
///   booking changes occur in quick succession.
/// - Auto-dispose (no `keepAlive: true`): see year-view docstring above for
///   the rationale and the [widgetVisibilityProvider] pause behaviour.
/// - Accepts settings parameters to eliminate redundant widgetSettings fetch.
@riverpod
Stream<Map<String, CalendarDateInfo>> realtimeMonthCalendar(
  Ref ref,
  String propertyId,
  String unitId,
  int year,
  int month,
  int minNights,
  int minDaysAdvance,
  int maxDaysAdvance,
) {
  final visible = ref.watch(widgetVisibilityProvider);
  if (!visible) {
    return const Stream<Map<String, CalendarDateInfo>>.empty();
  }
  final repository = ref.watch(bookingCalendarRepositoryProvider);
  return repository
      .watchCalendarDataOptimized(
        propertyId: propertyId,
        unitId: unitId,
        year: year,
        month: month,
        minNights: minNights,
        minDaysAdvance: minDaysAdvance,
        maxDaysAdvance: maxDaysAdvance,
      )
      .debounceTime(const Duration(milliseconds: _calendarDebounceMs))
      .map(
        (dateTimeMap) =>
            dateTimeMap.map((date, info) => MapEntry(_dateToKey(date), info)),
      );
}

/// Check date availability
///
/// [propertyId] is required so the iCal-check leg can call the
/// `getUnitAvailability` CF (SF-023 lockdown).
@riverpod
Future<bool> checkDateAvailability(
  Ref ref, {
  required String propertyId,
  required String unitId,
  required DateTime checkIn,
  required DateTime checkOut,
}) {
  final repository = ref.watch(bookingCalendarRepositoryProvider);
  return repository.checkAvailability(
    propertyId: propertyId,
    unitId: unitId,
    checkIn: checkIn,
    checkOut: checkOut,
  );
}
