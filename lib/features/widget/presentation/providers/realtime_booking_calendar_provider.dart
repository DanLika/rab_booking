import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/firebase_booking_calendar_repository_v2.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../../../shared/providers/repository_providers.dart';

part 'realtime_booking_calendar_provider.g.dart';

/// Repository provider (V2 with price support)
@riverpod
FirebaseBookingCalendarRepositoryV2 bookingCalendarRepository(
  BookingCalendarRepositoryRef ref,
) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseBookingCalendarRepositoryV2(firestore);
}

/// Realtime calendar data provider for year view
@riverpod
Stream<Map<DateTime, CalendarDateInfo>> realtimeYearCalendar(
  RealtimeYearCalendarRef ref,
  String unitId,
  int year,
) {
  final repository = ref.watch(bookingCalendarRepositoryProvider);
  return repository.watchYearCalendarData(unitId: unitId, year: year);
}

/// Realtime calendar data provider for month view
@riverpod
Stream<Map<DateTime, CalendarDateInfo>> realtimeMonthCalendar(
  RealtimeMonthCalendarRef ref,
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
  CheckDateAvailabilityRef ref, {
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
