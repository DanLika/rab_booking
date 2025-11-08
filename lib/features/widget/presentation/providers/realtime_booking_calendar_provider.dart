import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/firebase_booking_calendar_repository.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../../../shared/providers/repository_providers.dart';

part 'realtime_booking_calendar_provider.g.dart';

/// Repository provider (V2 with price support)
@riverpod
FirebaseBookingCalendarRepository bookingCalendarRepository(
  Ref ref,
) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseBookingCalendarRepository(firestore);
}

/// Realtime calendar data provider for year view
@riverpod
Stream<Map<DateTime, CalendarDateInfo>> realtimeYearCalendar(
  Ref ref,
  String unitId,
  int year,
) {
  final repository = ref.watch(bookingCalendarRepositoryProvider);
  return repository.watchYearCalendarData(unitId: unitId, year: year);
}

/// Realtime calendar data provider for month view
@riverpod
Stream<Map<DateTime, CalendarDateInfo>> realtimeMonthCalendar(
  Ref ref,
  String unitId,
  int year,
  int month,
) {
  final repository = ref.watch(bookingCalendarRepositoryProvider);
  return repository.watchCalendarData(
    unitId: unitId,
    year: year,
    month: month,
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
