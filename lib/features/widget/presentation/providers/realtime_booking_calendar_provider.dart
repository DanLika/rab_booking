import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/firebase_booking_calendar_repository.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../../../shared/providers/repository_providers.dart';

part 'realtime_booking_calendar_provider.g.dart';

/// Convert DateTime key to String key (yyyy-MM-dd format)
String _dateToKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

/// Repository provider (V2 with price support)
@riverpod
FirebaseBookingCalendarRepository bookingCalendarRepository(
  Ref ref,
) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseBookingCalendarRepository(firestore);
}

/// Realtime calendar data provider for year view.
/// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
@riverpod
Stream<Map<String, CalendarDateInfo>> realtimeYearCalendar(
  Ref ref,
  String propertyId,
  String unitId,
  int year,
) {
  final repository = ref.watch(bookingCalendarRepositoryProvider);
  return repository.watchYearCalendarData(
    propertyId: propertyId,
    unitId: unitId,
    year: year,
  ).map(
    (dateTimeMap) => dateTimeMap.map(
      (date, info) => MapEntry(_dateToKey(date), info),
    ),
  );
}

/// Realtime calendar data provider for month view.
/// Returns Map with String keys (yyyy-MM-dd format) to CalendarDateInfo.
@riverpod
Stream<Map<String, CalendarDateInfo>> realtimeMonthCalendar(
  Ref ref,
  String propertyId,
  String unitId,
  int year,
  int month,
) {
  final repository = ref.watch(bookingCalendarRepositoryProvider);
  return repository
      .watchCalendarData(
        propertyId: propertyId,
        unitId: unitId,
        year: year,
        month: month,
      )
      .map(
        (dateTimeMap) => dateTimeMap.map(
          (date, info) => MapEntry(_dateToKey(date), info),
        ),
      );
}

/// Check date availability
@riverpod
Future<bool> checkDateAvailability(
  Ref ref, {
  required String unitId,
  required DateTime checkIn,
  required DateTime checkOut,
}) {
  final repository = ref.watch(bookingCalendarRepositoryProvider);
  return repository.checkAvailability(
    unitId: unitId,
    checkIn: checkIn,
    checkOut: checkOut,
  );
}
