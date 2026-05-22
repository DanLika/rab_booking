import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../domain/repositories/i_booking_calendar_repository.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../helpers/availability_checker.dart';
import '../helpers/booking_price_calculator.dart';
import '../models/availability_window.dart';
import '../../utils/date_key_generator.dart';
import 'firebase_availability_repository.dart';

/// Firebase repository for booking calendar with realtime updates and prices.
///
/// ## Refactoring Notes (Phase 3)
/// This repository delegates to extracted helper classes:
/// - [AvailabilityChecker] - Availability checking logic
/// - [BookingPriceCalculator] - Price calculation with hierarchy
/// - [CalendarDataBuilder] - Extracted helper class, available for future use
///
/// The public API remains unchanged for backward compatibility.
/// Calendar building remains inline (optimized with Bug #71 fixes).
class FirebaseBookingCalendarRepository implements IBookingCalendarRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAvailabilityRepository _availabilityRepo;

  /// Helper for availability checking (lazy initialized).
  late final AvailabilityChecker _availabilityChecker;

  /// Helper for price calculation (lazy initialized).
  late final BookingPriceCalculator _priceCalculator;

  FirebaseBookingCalendarRepository(
    this._firestore, {
    FirebaseAvailabilityRepository? availabilityRepository,
  }) : _availabilityRepo =
           availabilityRepository ?? FirebaseAvailabilityRepository() {
    _availabilityChecker = AvailabilityChecker(
      _firestore,
      availabilityRepository: _availabilityRepo,
    );
    _priceCalculator = BookingPriceCalculator(
      firestore: _firestore,
      availabilityChecker: _availabilityChecker,
    );
  }

  /// Stream blocked-event windows via the `getUnitAvailability` CF (SF-023 +
  /// T11c). Replaces the prior public-read `collectionGroup('bookings')` AND
  /// `collectionGroup('ical_events')` `.snapshots()` — both rules were
  /// tightened to deny anonymous reads. The CF runs the equivalent
  /// server-side queries via Admin SDK and strips PII.
  ///
  /// Emits a record `(bookings, icalEvents)` so the existing
  /// `_buildCalendarMap` / `_buildYearCalendarMap` consumers (which still
  /// expect a `List<BookingModel>` for gap-blocking and a
  /// `List<Map<String,dynamic>>` for iCal projections) stay structurally
  /// untouched.
  ///
  /// Booking windows are synthesized into `BookingModel` with
  /// `status: BookingStatus.confirmed` — the CF intentionally strips
  /// `status` for privacy, so the widget can no longer differentiate
  /// pending vs confirmed (T11c accepted trade-off, see
  /// `audit/06-availability-cf-design.md`).
  ///
  /// `manual_block` windows are intentionally dropped here; the existing
  /// `daily_prices` subcollection stream still serves the `available:false`
  /// blocking surface (and carries the per-day price the calendar needs).
  Stream<({List<BookingModel> bookings, List<Map<String, dynamic>> icalEvents})>
  _streamBlockedEvents({
    required String propertyId,
    required String unitId,
    required DateTime start,
    required DateTime end,
  }) {
    return _availabilityRepo
        .streamAvailability(
          propertyId: propertyId,
          unitId: unitId,
          start: start,
          end: end,
        )
        .map((windows) {
          final bookings = <BookingModel>[];
          final icalEvents = <Map<String, dynamic>>[];
          for (final w in windows) {
            switch (w.source) {
              case AvailabilityWindowSource.booking:
                bookings.add(_synthesizeBookingFromWindow(w, unitId));
              case AvailabilityWindowSource.icalExternal:
                icalEvents.add(<String, dynamic>{
                  'start_date': w.start,
                  'end_date': w.end,
                  'source': w.platform ?? 'ical',
                  'guest_name': 'External Booking',
                });
              case AvailabilityWindowSource.manualBlock:
                // daily_prices stream already covers manual blocks.
                break;
            }
          }
          return (bookings: bookings, icalEvents: icalEvents);
        });
  }

  /// Build a minimal `BookingModel` from a CF-supplied availability window.
  /// PII intentionally absent — `guest_*`, `total_price`, payment fields
  /// never leave the Cloud Function (`functions/src/availability.ts`).
  BookingModel _synthesizeBookingFromWindow(
    AvailabilityWindow window,
    String unitId,
  ) {
    final syntheticId =
        'cf-${window.start.toIso8601String()}-${window.end.toIso8601String()}';
    return BookingModel(
      id: syntheticId,
      unitId: unitId,
      checkIn: window.start,
      checkOut: window.end,
      status: BookingStatus.confirmed,
      createdAt: window.start,
    );
  }

  /// Get year-view calendar data with realtime updates and prices
  @override
  Stream<Map<DateTime, CalendarDateInfo>> watchYearCalendarData({
    required String propertyId,
    required String unitId,
    required int year,
  }) {
    // Bug #65 Fix: Use UTC for DST-safe date handling
    final startDate = DateTime.utc(year);
    final endDate = DateTime.utc(year, 12, 31, 23, 59, 59);

    // T11c (2026-05-22): bookings + iCal blocks now BOTH come from the
    // `getUnitAvailability` CF — the public `collectionGroup('bookings')`
    // `.snapshots()` was removed alongside the rule-tightening that closed
    // clause 1. The CF polls every 30s (see FirebaseAvailabilityRepository
    // `_defaultPollInterval`); realtime `.snapshots()` is intentionally
    // sacrificed for the security boundary.
    final blockedEventsStream = _streamBlockedEvents(
      propertyId: propertyId,
      unitId: unitId,
      start: startDate,
      end: endDate,
    );

    // Stream prices (NEW STRUCTURE: subcollection path)
    final pricesStream = _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection('daily_prices')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots();

    // Stream widget settings to get minNights
    // FIXED: Use correct subcollection path: properties/{propertyId}/widget_settings/{unitId}
    final widgetSettingsStream = _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('widget_settings')
        .doc(unitId)
        .snapshots();

    // Combine all three streams (bookings + iCal now fused into one CF stream)
    return Rx.combineLatest3(
      blockedEventsStream,
      pricesStream,
      widgetSettingsStream,
      (blockedEvents, pricesSnapshot, widgetSettingsSnapshot) {
        // Synthesized bookings carry only start/end/status=confirmed (PII
        // stripped server-side). SF-014 PII-exposure surface is closed at
        // the CF layer now — no in-process secure parser needed.
        final bookings = blockedEvents.bookings
            .where(
              (booking) => !_normalizeToUtcMidnight(
                booking.checkOut,
              ).isBefore(startDate),
            )
            .toList();
        final icalEvents = blockedEvents.icalEvents;

        // Parse prices
        final Map<String, DailyPriceModel> priceMap = {};
        for (final doc in pricesSnapshot.docs) {
          final data = doc.data();
          // Skip documents without valid date or unit_id field
          // FIXED: Also check if date is a valid Timestamp
          if (data['date'] == null ||
              data['date'] is! Timestamp ||
              data['unit_id'] == null) {
            continue;
          }

          try {
            final price = DailyPriceModel.fromJson({...data, 'id': doc.id});
            final key = DateKeyGenerator.fromDate(price.date);
            priceMap[key] = price;
          } catch (e, stackTrace) {
            LoggingService.logError(
              'Error parsing daily price - doc: ${doc.reference.path}',
              e,
              stackTrace,
            );
          }
        }

        // Parse widget settings to get booking restrictions
        int minNights = 1; // Default
        int minDaysAdvance = 0; // Default
        int maxDaysAdvance = 365; // Default
        if (widgetSettingsSnapshot.exists) {
          final settingsData = widgetSettingsSnapshot.data();
          minNights = settingsData?['min_nights'] ?? 1;
          minDaysAdvance = settingsData?['min_days_advance'] ?? 0;
          maxDaysAdvance = settingsData?['max_days_advance'] ?? 365;
        }

        // Build calendar with both bookings and iCal events
        return _buildYearCalendarMap(
          bookings,
          priceMap,
          year,
          minNights,
          icalEvents,
          minDaysAdvance,
          maxDaysAdvance,
        );
      },
    ).onErrorReturnWith((error, stackTrace) {
      // Log error but don't crash the UI
      LoggingService.logError(
        '[CalendarRepo] Year calendar stream error',
        error,
        stackTrace,
      );
      // Return empty calendar - UI will show available dates
      // This prevents crashes on network errors or permission issues
      return <DateTime, CalendarDateInfo>{};
    });
  }

  /// Get month-view calendar data with realtime updates and prices
  /// UPDATED: Now includes iCal events (Booking.com, Airbnb, etc.)
  @override
  Stream<Map<DateTime, CalendarDateInfo>> watchCalendarData({
    required String propertyId,
    required String unitId,
    required int year,
    required int month,
  }) {
    // Bug #65 Fix: Use UTC for DST-safe date handling
    final startDate = DateTime.utc(year, month);
    final endDate = DateTime.utc(year, month + 1, 0, 23, 59, 59);

    // T11c (2026-05-22): single CF stream now feeds both bookings AND iCal
    // events. See _streamBlockedEvents docstring for the trade-off rationale.
    final blockedEventsStream = _streamBlockedEvents(
      propertyId: propertyId,
      unitId: unitId,
      start: startDate,
      end: endDate,
    );

    // Stream prices (NEW STRUCTURE: subcollection path)
    final pricesStream = _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection('daily_prices')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots();

    // Stream widget settings to get minNights
    // FIXED: Use correct subcollection path: properties/{propertyId}/widget_settings/{unitId}
    final widgetSettingsStream = _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('widget_settings')
        .doc(unitId)
        .snapshots();

    // Combine all three streams (bookings + iCal fused at CF layer)
    return Rx.combineLatest3(
      blockedEventsStream,
      pricesStream,
      widgetSettingsStream,
      (blockedEvents, pricesSnapshot, widgetSettingsSnapshot) {
        final bookings = blockedEvents.bookings
            .where(
              (booking) => !_normalizeToUtcMidnight(
                booking.checkOut,
              ).isBefore(startDate),
            )
            .toList();
        final icalEvents = blockedEvents.icalEvents;

        // Parse prices
        final Map<String, DailyPriceModel> priceMap = {};
        for (final doc in pricesSnapshot.docs) {
          final data = doc.data();
          // Skip documents without valid date or unit_id field
          // FIXED: Also check if date is a valid Timestamp
          if (data['date'] == null ||
              data['date'] is! Timestamp ||
              data['unit_id'] == null) {
            continue;
          }

          try {
            final price = DailyPriceModel.fromJson({...data, 'id': doc.id});
            final key = DateKeyGenerator.fromDate(price.date);
            priceMap[key] = price;
          } catch (e, stackTrace) {
            LoggingService.logError(
              'Error parsing daily price - doc: ${doc.reference.path}',
              e,
              stackTrace,
            );
          }
        }

        // Parse widget settings to get booking restrictions
        int minNights = 1; // Default
        int minDaysAdvance = 0; // Default
        int maxDaysAdvance = 365; // Default
        if (widgetSettingsSnapshot.exists) {
          final settingsData = widgetSettingsSnapshot.data();
          minNights = settingsData?['min_nights'] ?? 1;
          minDaysAdvance = settingsData?['min_days_advance'] ?? 0;
          maxDaysAdvance = settingsData?['max_days_advance'] ?? 365;
        }

        // Build calendar with bookings AND iCal events
        return _buildCalendarMap(
          bookings,
          priceMap,
          year,
          month,
          minNights,
          icalEvents,
          minDaysAdvance,
          maxDaysAdvance,
        );
      },
    ).onErrorReturnWith((error, stackTrace) {
      // Log error but don't crash the UI
      LoggingService.logError(
        '[CalendarRepo] Month calendar stream error',
        error,
        stackTrace,
      );
      // Return empty calendar - UI will show available dates
      // This prevents crashes on network errors or permission issues
      return <DateTime, CalendarDateInfo>{};
    });
  }

  /// OPTIMIZED: Year calendar with settings passed as parameters.
  ///
  /// This eliminates the widgetSettingsStream since settings are already
  /// available from widgetContextProvider (cached with keepAlive: true).
  ///
  /// Stream reduction: 4 → 3 streams (bookings, prices, iCal)
  @override
  Stream<Map<DateTime, CalendarDateInfo>> watchYearCalendarDataOptimized({
    required String propertyId,
    required String unitId,
    required int year,
    required int minNights,
    int minDaysAdvance = 0,
    int maxDaysAdvance = 365,
  }) {
    // Bug #65 Fix: Use UTC for DST-safe date handling
    final startDate = DateTime.utc(year);
    final endDate = DateTime.utc(year, 12, 31, 23, 59, 59);

    // T11c (2026-05-22): bookings + iCal fused into single CF stream.
    final blockedEventsStream = _streamBlockedEvents(
      propertyId: propertyId,
      unitId: unitId,
      start: startDate,
      end: endDate,
    );

    // Stream prices (NEW STRUCTURE: subcollection path)
    final pricesStream = _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection('daily_prices')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots();

    // Combine 2 streams (T11c fused bookings+iCal; settings come from caller)
    return Rx.combineLatest2(blockedEventsStream, pricesStream, (
      blockedEvents,
      pricesSnapshot,
    ) {
      final bookings = blockedEvents.bookings
          .where(
            (booking) =>
                !_normalizeToUtcMidnight(booking.checkOut).isBefore(startDate),
          )
          .toList();
      final icalEvents = blockedEvents.icalEvents;

      // Parse prices
      final Map<String, DailyPriceModel> priceMap = {};
      for (final doc in pricesSnapshot.docs) {
        final data = doc.data();
        if (data['date'] == null ||
            data['date'] is! Timestamp ||
            data['unit_id'] == null) {
          continue;
        }

        try {
          final price = DailyPriceModel.fromJson({...data, 'id': doc.id});
          final key = DateKeyGenerator.fromDate(price.date);
          priceMap[key] = price;
        } catch (e, stackTrace) {
          LoggingService.logError(
            'Error parsing daily price - doc: ${doc.reference.path}',
            e,
            stackTrace,
          );
        }
      }

      // Build calendar using passed settings (no fetch needed!)
      return _buildYearCalendarMap(
        bookings,
        priceMap,
        year,
        minNights,
        icalEvents,
        minDaysAdvance,
        maxDaysAdvance,
      );
    }).onErrorReturnWith((error, stackTrace) {
      LoggingService.logError(
        '[CalendarRepo] Year calendar optimized stream error',
        error,
        stackTrace,
      );
      return <DateTime, CalendarDateInfo>{};
    });
  }

  /// OPTIMIZED: Month calendar with settings passed as parameters.
  ///
  /// This eliminates the widgetSettingsStream since settings are already
  /// available from widgetContextProvider (cached with keepAlive: true).
  ///
  /// Stream reduction: 4 → 3 streams (bookings, prices, iCal)
  @override
  Stream<Map<DateTime, CalendarDateInfo>> watchCalendarDataOptimized({
    required String propertyId,
    required String unitId,
    required int year,
    required int month,
    required int minNights,
    int minDaysAdvance = 0,
    int maxDaysAdvance = 365,
  }) {
    // Bug #65 Fix: Use UTC for DST-safe date handling
    final startDate = DateTime.utc(year, month);
    final endDate = DateTime.utc(year, month + 1, 0, 23, 59, 59);

    // T11c (2026-05-22): bookings + iCal fused into single CF stream.
    final blockedEventsStream = _streamBlockedEvents(
      propertyId: propertyId,
      unitId: unitId,
      start: startDate,
      end: endDate,
    );

    // Stream prices (NEW STRUCTURE: subcollection path)
    final pricesStream = _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(unitId)
        .collection('daily_prices')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots();

    // Combine 2 streams (T11c fused bookings+iCal; settings come from caller)
    return Rx.combineLatest2(blockedEventsStream, pricesStream, (
      blockedEvents,
      pricesSnapshot,
    ) {
      final bookings = blockedEvents.bookings
          .where(
            (booking) =>
                !_normalizeToUtcMidnight(booking.checkOut).isBefore(startDate),
          )
          .toList();
      final icalEvents = blockedEvents.icalEvents;

      // Parse prices
      final Map<String, DailyPriceModel> priceMap = {};
      for (final doc in pricesSnapshot.docs) {
        final data = doc.data();
        if (data['date'] == null ||
            data['date'] is! Timestamp ||
            data['unit_id'] == null) {
          continue;
        }

        try {
          final price = DailyPriceModel.fromJson({...data, 'id': doc.id});
          final key = DateKeyGenerator.fromDate(price.date);
          priceMap[key] = price;
        } catch (e, stackTrace) {
          LoggingService.logError(
            'Error parsing daily price - doc: ${doc.reference.path}',
            e,
            stackTrace,
          );
        }
      }

      // Build calendar using passed settings (no fetch needed!)
      return _buildCalendarMap(
        bookings,
        priceMap,
        year,
        month,
        minNights,
        icalEvents,
        minDaysAdvance,
        maxDaysAdvance,
      );
    }).onErrorReturnWith((error, stackTrace) {
      LoggingService.logError(
        '[CalendarRepo] Month calendar optimized stream error',
        error,
        stackTrace,
      );
      return <DateTime, CalendarDateInfo>{};
    });
  }

  /// Build calendar map for a specific month
  /// UPDATED: Now includes iCal events
  Map<DateTime, CalendarDateInfo> _buildCalendarMap(
    List<BookingModel> bookings,
    Map<String, DailyPriceModel> priceMap,
    int year,
    int month,
    int minNights, [
    List<Map<String, dynamic>>? icalEvents,
    int defaultMinDaysAdvance = 0,
    int defaultMaxDaysAdvance = 365,
  ]) {
    final Map<DateTime, CalendarDateInfo> calendar = {};
    final daysInMonth = DateTime.utc(year, month + 1, 0).day;

    // Initialize all days as available with prices
    // Check available field from daily_prices - if false, mark as blocked
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime.utc(year, month, day);
      final priceKey = DateKeyGenerator.fromDate(date);
      final priceModel = priceMap[priceKey];

      // Bug fix: Check available field - if explicitly false, day is blocked
      final isBlocked = priceModel?.available == false;
      calendar[date] = CalendarDateInfo(
        date: date,
        status: isBlocked ? DateStatus.blocked : DateStatus.available,
        price: priceModel?.price,
        // Include restriction fields from daily_prices
        blockCheckIn: priceModel?.blockCheckIn ?? false,
        blockCheckOut: priceModel?.blockCheckOut ?? false,
        // Use per-day value if set, otherwise fallback to global default
        minDaysAdvance: priceModel?.minDaysAdvance ?? defaultMinDaysAdvance,
        maxDaysAdvance: priceModel?.maxDaysAdvance ?? defaultMaxDaysAdvance,
        minNightsOnArrival: priceModel?.minNightsOnArrival,
        maxNightsOnArrival: priceModel?.maxNightsOnArrival,
      );
    }

    // Mark booked dates
    // Bug #71 Fix: Optimize for long-term bookings by calculating date range intersection
    final monthStart = DateTime.utc(year, month);
    final monthEnd = DateTime.utc(year, month, daysInMonth);

    for (final booking in bookings) {
      final checkIn = DateTime.utc(
        booking.checkIn.year,
        booking.checkIn.month,
        booking.checkIn.day,
      );
      final checkOut = DateTime.utc(
        booking.checkOut.year,
        booking.checkOut.month,
        booking.checkOut.day,
      );

      // Calculate intersection of booking range with current month
      // This avoids iterating through days outside the current month
      final rangeStart = checkIn.isAfter(monthStart) ? checkIn : monthStart;
      final rangeEnd = checkOut.isBefore(monthEnd) ? checkOut : monthEnd;

      // Only iterate if booking overlaps with current month
      if (!rangeStart.isAfter(rangeEnd)) {
        DateTime current = rangeStart;
        // NOTE: Checkout day is included in the loop (isAtSameMomentAs) for visual display.
        // This shows checkout day with partialCheckOut status in the calendar.
        // However, checkout day does NOT block new check-ins (turnover day is supported),
        // and is NOT included in price calculation or night count.
        while (current.isBefore(rangeEnd) ||
            current.isAtSameMomentAs(rangeEnd)) {
          final isCheckIn = current.isAtSameMomentAs(checkIn);
          final isCheckOut = current.isAtSameMomentAs(checkOut);

          // Check if booking is pending to show pending indicator
          final isPending = booking.status == BookingStatus.pending;

          // FIX: Pending bookings should still show split days with pending indicator
          // Use partialCheckIn/partialCheckOut status and mark isPendingBooking = true
          DateStatus status;
          if (isCheckIn && isCheckOut) {
            status = DateStatus.booked;
          } else if (isCheckIn) {
            status = DateStatus.partialCheckIn;
          } else if (isCheckOut) {
            status = DateStatus.partialCheckOut;
          } else {
            status = DateStatus.booked;
          }

          // Check for turnover day (partialBoth) - another booking on same day
          final existingInfo = calendar[current];
          bool isCheckOutPending = false;
          bool isCheckInPending = false;

          if (existingInfo != null) {
            // Bug fix: Handle all booked statuses for turnover detection
            // A day can be overwritten by a booking that spans through it (status=booked)
            // or already be a partialBoth from two previous bookings
            if (existingInfo.status == DateStatus.partialCheckIn ||
                existingInfo.status == DateStatus.partialCheckOut ||
                existingInfo.status == DateStatus.booked ||
                existingInfo.status == DateStatus.partialBoth) {
              // This is a turnover day (or day with existing booking)
              if (isCheckIn || isCheckOut) {
                status = DateStatus.partialBoth;
                // Track which half is pending
                if (isCheckOut) {
                  isCheckOutPending = isPending;
                  // Inherit check-in pending status from existing
                  isCheckInPending =
                      existingInfo.isCheckInPending ||
                      (existingInfo.status == DateStatus.partialCheckIn &&
                          existingInfo.isPendingBooking);
                } else if (isCheckIn) {
                  isCheckInPending = isPending;
                  // Inherit check-out pending status from existing
                  isCheckOutPending =
                      existingInfo.isCheckOutPending ||
                      (existingInfo.status == DateStatus.partialCheckOut &&
                          existingInfo.isPendingBooking);
                }
              }
              // If current booking spans through (not check-in/out), keep existing status
              // unless it's more restrictive (booked wins over partial)
            }
          }

          // BUG-008 FIX: Preserve price AND restrictions when updating status
          // Use copyWith to avoid overwriting restrictions from daily_prices
          final priceKey = DateKeyGenerator.fromDate(current);
          final infoToUpdate =
              existingInfo ??
              CalendarDateInfo(
                date: current,
                status: DateStatus.available,
                price: priceMap[priceKey]?.price,
              );
          calendar[current] = infoToUpdate.copyWith(
            status: status,
            isPendingBooking: isPending,
            isCheckOutPending: isCheckOutPending,
            isCheckInPending: isCheckInPending,
          );

          current = current.add(const Duration(days: 1));
        }
      }
    }

    // Mark booked dates from iCal events (Booking.com, Airbnb, etc.)
    // Bug #71 Fix: Same optimization as bookings
    // FIX: iCal events should also show split days (check-in/check-out)
    if (icalEvents != null) {
      for (final event in icalEvents) {
        // Bug #65 Fix: Use UTC for DST-safe date handling (consistent with calendar keys)
        final checkIn = DateTime.utc(
          event['start_date'].year,
          event['start_date'].month,
          event['start_date'].day,
        );
        final checkOut = DateTime.utc(
          event['end_date'].year,
          event['end_date'].month,
          event['end_date'].day,
        );

        // Calculate intersection of event range with current month
        final rangeStart = checkIn.isAfter(monthStart) ? checkIn : monthStart;
        final rangeEnd = checkOut.isBefore(monthEnd) ? checkOut : monthEnd;

        // Only iterate if event overlaps with current month
        if (!rangeStart.isAfter(rangeEnd)) {
          DateTime current = rangeStart;
          // NOTE: Checkout day is included in the loop (isAtSameMomentAs) for visual display.
          // This shows checkout day with partialCheckOut status in the calendar.
          // However, checkout day does NOT block new check-ins (turnover day is supported),
          // and is NOT included in price calculation or night count.
          while (current.isBefore(rangeEnd) ||
              current.isAtSameMomentAs(rangeEnd)) {
            final isCheckIn = current.isAtSameMomentAs(checkIn);
            final isCheckOut = current.isAtSameMomentAs(checkOut);

            // FIX: Apply same check-in/check-out logic as regular bookings
            DateStatus status;
            if (isCheckIn && isCheckOut) {
              status = DateStatus.booked;
            } else if (isCheckIn) {
              status = DateStatus.partialCheckIn;
            } else if (isCheckOut) {
              status = DateStatus.partialCheckOut;
            } else {
              status = DateStatus.booked;
            }

            // Check for turnover day (partialBoth) - another booking on same day
            final existingInfo = calendar[current];
            bool isCheckOutPending = false;
            bool isCheckInPending = false;

            if (existingInfo != null) {
              // Bug fix: Handle all booked statuses for turnover detection
              if (existingInfo.status == DateStatus.partialCheckIn ||
                  existingInfo.status == DateStatus.partialCheckOut ||
                  existingInfo.status == DateStatus.booked ||
                  existingInfo.status == DateStatus.partialBoth) {
                // This is a turnover day (or day with existing booking)
                if (isCheckIn || isCheckOut) {
                  status = DateStatus.partialBoth;
                  // iCal events are not pending, so inherit from existing
                  if (isCheckOut) {
                    isCheckInPending =
                        existingInfo.isCheckInPending ||
                        (existingInfo.status == DateStatus.partialCheckIn &&
                            existingInfo.isPendingBooking);
                  } else if (isCheckIn) {
                    isCheckOutPending =
                        existingInfo.isCheckOutPending ||
                        (existingInfo.status == DateStatus.partialCheckOut &&
                            existingInfo.isPendingBooking);
                  }
                }
              }
            }

            // BUG-008 FIX: Preserve price AND restrictions when updating status
            // Use copyWith to avoid overwriting restrictions from daily_prices
            final priceKey = DateKeyGenerator.fromDate(current);
            final infoToUpdate =
                existingInfo ??
                CalendarDateInfo(
                  date: current,
                  status: DateStatus.available,
                  price: priceMap[priceKey]?.price,
                );
            calendar[current] = infoToUpdate.copyWith(
              status: status,
              isCheckOutPending: isCheckOutPending,
              isCheckInPending: isCheckInPending,
            );

            current = current.add(const Duration(days: 1));
          }
        }

        LoggingService.log(
          '📅 iCal Event blocked (month view): ${event['source']} from $checkIn to $checkOut',
          tag: 'iCAL_SYNC',
        );
      }
    }

    // Apply gap blocking based on minimum nights requirement
    _applyMinNightsGapBlocking(calendar, bookings, priceMap, minNights);

    // Mark past dates as disabled or pastReservation
    _markPastDates(calendar);

    return calendar;
  }

  /// Build calendar map for entire year
  Map<DateTime, CalendarDateInfo> _buildYearCalendarMap(
    List<BookingModel> bookings,
    Map<String, DailyPriceModel> priceMap,
    int year,
    int minNights, [
    List<Map<String, dynamic>>? icalEvents,
    int defaultMinDaysAdvance = 0,
    int defaultMaxDaysAdvance = 365,
  ]) {
    final Map<DateTime, CalendarDateInfo> calendar = {};

    // Initialize all days in year as available with prices
    // Bug #65 Fix: Use UTC for DST-safe date handling (consistent with month view)
    // Check available field from daily_prices - if false, mark as blocked
    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime.utc(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime.utc(year, month, day);
        final priceKey = DateKeyGenerator.fromDate(date);
        final priceModel = priceMap[priceKey];

        // Bug fix: Check available field - if explicitly false, day is blocked
        final isBlocked = priceModel?.available == false;
        calendar[date] = CalendarDateInfo(
          date: date,
          status: isBlocked ? DateStatus.blocked : DateStatus.available,
          price: priceModel?.price,
          // Include restriction fields from daily_prices
          blockCheckIn: priceModel?.blockCheckIn ?? false,
          blockCheckOut: priceModel?.blockCheckOut ?? false,
          // Use per-day value if set, otherwise fallback to global default
          minDaysAdvance: priceModel?.minDaysAdvance ?? defaultMinDaysAdvance,
          maxDaysAdvance: priceModel?.maxDaysAdvance ?? defaultMaxDaysAdvance,
          minNightsOnArrival: priceModel?.minNightsOnArrival,
          maxNightsOnArrival: priceModel?.maxNightsOnArrival,
        );
      }
    }

    // Mark booked dates from regular bookings
    // Bug #71 Fix: Optimize for long-term bookings by calculating date range intersection
    final yearStart = DateTime.utc(year);
    final yearEnd = DateTime.utc(year, 12, 31);

    for (final booking in bookings) {
      // Bug #65 Fix: Use UTC for DST-safe date handling
      final checkIn = DateTime.utc(
        booking.checkIn.year,
        booking.checkIn.month,
        booking.checkIn.day,
      );
      final checkOut = DateTime.utc(
        booking.checkOut.year,
        booking.checkOut.month,
        booking.checkOut.day,
      );

      // Calculate intersection of booking range with current year
      final rangeStart = checkIn.isAfter(yearStart) ? checkIn : yearStart;
      final rangeEnd = checkOut.isBefore(yearEnd) ? checkOut : yearEnd;

      // Only iterate if booking overlaps with current year
      if (!rangeStart.isAfter(rangeEnd)) {
        DateTime current = rangeStart;
        // NOTE: Checkout day is included in the loop (isAtSameMomentAs) for visual display.
        // This shows checkout day with partialCheckOut status in the calendar.
        // However, checkout day does NOT block new check-ins (turnover day is supported),
        // and is NOT included in price calculation or night count.
        while (current.isBefore(rangeEnd) ||
            current.isAtSameMomentAs(rangeEnd)) {
          final isCheckIn = current.isAtSameMomentAs(checkIn);
          final isCheckOut = current.isAtSameMomentAs(checkOut);

          // Check if booking is pending to show pending indicator
          final isPending = booking.status == BookingStatus.pending;

          // FIX: Pending bookings should still show split days with pending indicator
          // Use partialCheckIn/partialCheckOut status and mark isPendingBooking = true
          DateStatus status;
          if (isCheckIn && isCheckOut) {
            status = DateStatus.booked;
          } else if (isCheckIn) {
            status = DateStatus.partialCheckIn;
          } else if (isCheckOut) {
            status = DateStatus.partialCheckOut;
          } else {
            status = DateStatus.booked;
          }

          // Check for turnover day (partialBoth) - another booking on same day
          final existingInfo = calendar[current];
          bool isCheckOutPending = false;
          bool isCheckInPending = false;

          if (existingInfo != null) {
            // Bug fix: Handle all booked statuses for turnover detection
            // A day can be overwritten by a booking that spans through it (status=booked)
            // or already be a partialBoth from two previous bookings
            if (existingInfo.status == DateStatus.partialCheckIn ||
                existingInfo.status == DateStatus.partialCheckOut ||
                existingInfo.status == DateStatus.booked ||
                existingInfo.status == DateStatus.partialBoth) {
              // This is a turnover day (or day with existing booking)
              if (isCheckIn || isCheckOut) {
                status = DateStatus.partialBoth;
                // Track which half is pending
                if (isCheckOut) {
                  isCheckOutPending = isPending;
                  // Inherit check-in pending status from existing
                  isCheckInPending =
                      existingInfo.isCheckInPending ||
                      (existingInfo.status == DateStatus.partialCheckIn &&
                          existingInfo.isPendingBooking);
                } else if (isCheckIn) {
                  isCheckInPending = isPending;
                  // Inherit check-out pending status from existing
                  isCheckOutPending =
                      existingInfo.isCheckOutPending ||
                      (existingInfo.status == DateStatus.partialCheckOut &&
                          existingInfo.isPendingBooking);
                }
              }
              // If current booking spans through (not check-in/out), keep existing status
              // unless it's more restrictive (booked wins over partial)
            }
          }

          // BUG-008 FIX: Preserve price AND restrictions when updating status
          // Use copyWith to avoid overwriting restrictions from daily_prices
          final priceKey = DateKeyGenerator.fromDate(current);
          final infoToUpdate =
              existingInfo ??
              CalendarDateInfo(
                date: current,
                status: DateStatus.available,
                price: priceMap[priceKey]?.price,
              );
          calendar[current] = infoToUpdate.copyWith(
            status: status,
            isPendingBooking: isPending,
            isCheckOutPending: isCheckOutPending,
            isCheckInPending: isCheckInPending,
          );

          current = current.add(const Duration(days: 1));
        }
      }
    }

    // Mark booked dates from iCal events (Booking.com, Airbnb, etc.)
    // Bug #71 Fix: Same optimization as bookings
    // FIX: iCal events should also show split days (check-in/check-out)
    if (icalEvents != null) {
      for (final event in icalEvents) {
        // Bug #65 Fix: Use UTC for DST-safe date handling
        final checkIn = DateTime.utc(
          event['start_date'].year,
          event['start_date'].month,
          event['start_date'].day,
        );
        final checkOut = DateTime.utc(
          event['end_date'].year,
          event['end_date'].month,
          event['end_date'].day,
        );

        // Calculate intersection of event range with current year
        final rangeStart = checkIn.isAfter(yearStart) ? checkIn : yearStart;
        final rangeEnd = checkOut.isBefore(yearEnd) ? checkOut : yearEnd;

        // Only iterate if event overlaps with current year
        if (!rangeStart.isAfter(rangeEnd)) {
          DateTime current = rangeStart;
          // NOTE: Checkout day is included in the loop (isAtSameMomentAs) for visual display.
          // This shows checkout day with partialCheckOut status in the calendar.
          // However, checkout day does NOT block new check-ins (turnover day is supported),
          // and is NOT included in price calculation or night count.
          while (current.isBefore(rangeEnd) ||
              current.isAtSameMomentAs(rangeEnd)) {
            final isCheckIn = current.isAtSameMomentAs(checkIn);
            final isCheckOut = current.isAtSameMomentAs(checkOut);

            // FIX: Apply same check-in/check-out logic as regular bookings
            DateStatus status;
            if (isCheckIn && isCheckOut) {
              status = DateStatus.booked;
            } else if (isCheckIn) {
              status = DateStatus.partialCheckIn;
            } else if (isCheckOut) {
              status = DateStatus.partialCheckOut;
            } else {
              status = DateStatus.booked;
            }

            // Check for turnover day (partialBoth) - another booking on same day
            final existingInfo = calendar[current];
            bool isCheckOutPending = false;
            bool isCheckInPending = false;

            if (existingInfo != null) {
              // Bug fix: Handle all booked statuses for turnover detection
              if (existingInfo.status == DateStatus.partialCheckIn ||
                  existingInfo.status == DateStatus.partialCheckOut ||
                  existingInfo.status == DateStatus.booked ||
                  existingInfo.status == DateStatus.partialBoth) {
                // This is a turnover day (or day with existing booking)
                if (isCheckIn || isCheckOut) {
                  status = DateStatus.partialBoth;
                  // iCal events are not pending, so inherit from existing
                  if (isCheckOut) {
                    isCheckInPending =
                        existingInfo.isCheckInPending ||
                        (existingInfo.status == DateStatus.partialCheckIn &&
                            existingInfo.isPendingBooking);
                  } else if (isCheckIn) {
                    isCheckOutPending =
                        existingInfo.isCheckOutPending ||
                        (existingInfo.status == DateStatus.partialCheckOut &&
                            existingInfo.isPendingBooking);
                  }
                }
              }
            }

            // BUG-008 FIX: Preserve price AND restrictions when updating status
            // Use copyWith to avoid overwriting restrictions from daily_prices
            final priceKey = DateKeyGenerator.fromDate(current);
            final infoToUpdate =
                existingInfo ??
                CalendarDateInfo(
                  date: current,
                  status: DateStatus.available,
                  price: priceMap[priceKey]?.price,
                );
            calendar[current] = infoToUpdate.copyWith(
              status: status,
              isCheckOutPending: isCheckOutPending,
              isCheckInPending: isCheckInPending,
            );

            current = current.add(const Duration(days: 1));
          }
        }

        LoggingService.log(
          '📅 iCal Event blocked: ${event['source']} from $checkIn to $checkOut',
          tag: 'iCAL_SYNC',
        );
      }
    }

    // Apply gap blocking based on minimum nights requirement
    _applyMinNightsGapBlocking(calendar, bookings, priceMap, minNights);

    // Mark past dates as disabled or pastReservation
    _markPastDates(calendar);

    return calendar;
  }

  /// Mark past dates appropriately
  /// - Past available dates → disabled (cannot be selected)
  /// - Past booked/partialCheckIn/partialCheckOut/partialBoth dates → pastReservation
  /// - Past blocked dates → keep as blocked (already not selectable)
  void _markPastDates(Map<DateTime, CalendarDateInfo> calendar) {
    // Bug #3 Fix: Use UTC consistently for date comparison
    // All calendar dates are in UTC, so today must also be in UTC
    final nowUtc = DateTime.now().toUtc();
    final today = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);

    final datesToUpdate = <DateTime, CalendarDateInfo>{};

    for (final entry in calendar.entries) {
      final date = entry.key;
      final info = entry.value;

      // Only process dates before today
      if (date.isBefore(today)) {
        switch (info.status) {
          case DateStatus.available:
            // Past available → disabled
            datesToUpdate[date] = info.copyWith(status: DateStatus.disabled);

          case DateStatus.booked:
          case DateStatus.partialCheckIn:
          case DateStatus.partialCheckOut:
          case DateStatus.partialBoth:
            // Past booked → pastReservation
            datesToUpdate[date] = info.copyWith(
              status: DateStatus.pastReservation,
            );

          case DateStatus.pending:
            // Past pending → pastReservation (shouldn't happen, but handle it)
            datesToUpdate[date] = info.copyWith(
              status: DateStatus.pastReservation,
            );

          case DateStatus.blocked:
          case DateStatus.disabled:
          case DateStatus.pastReservation:
            // Already correct status, no change needed
            break;
        }
      }
    }

    // Apply updates
    calendar.addAll(datesToUpdate);
  }

  /// Apply gap blocking based on minimum nights requirement
  /// If gap between two bookings is less than minNights, block that gap
  void _applyMinNightsGapBlocking(
    Map<DateTime, CalendarDateInfo> calendar,
    List<BookingModel> bookings,
    Map<String, DailyPriceModel> priceMap,
    int defaultMinNights,
  ) {
    // Sort bookings by check-in date
    final sortedBookings = List<BookingModel>.from(bookings)
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

    // Check gaps between consecutive bookings
    for (int i = 0; i < sortedBookings.length - 1; i++) {
      final currentBooking = sortedBookings[i];
      final nextBooking = sortedBookings[i + 1];

      // Bug #65 Fix: Use UTC for consistent map key lookup
      final checkOutCurrent = DateTime.utc(
        currentBooking.checkOut.year,
        currentBooking.checkOut.month,
        currentBooking.checkOut.day,
      );
      final checkInNext = DateTime.utc(
        nextBooking.checkIn.year,
        nextBooking.checkIn.month,
        nextBooking.checkIn.day,
      );

      // Calculate gap in days (from checkout day to checkin day of next booking)
      final gapStart = checkOutCurrent;
      final gapEnd = checkInNext;
      final gapDays = gapEnd.difference(gapStart).inDays;

      // Get minNights from first day of gap (or use default)
      final priceKey = DateKeyGenerator.fromDate(gapStart);
      final priceModel = priceMap[priceKey];
      final minNights = priceModel?.minNightsOnArrival ?? defaultMinNights;

      // If gap is less than minNights, block all days in the gap
      if (gapDays > 0 && gapDays < minNights) {
        DateTime current = gapStart;
        while (current.isBefore(gapEnd)) {
          // Only block if it exists in calendar and is available
          final existingInfo = calendar[current];
          if (existingInfo != null &&
              existingInfo.status == DateStatus.available) {
            calendar[current] = CalendarDateInfo(
              date: current,
              status: DateStatus.blocked,
              price: existingInfo.price,
            );
          }
          current = current.add(const Duration(days: 1));
        }
      }
    }
  }

  /// Check if date range is available for booking.
  ///
  /// Checks regular bookings, iCal events (Booking.com, Airbnb), and blocked dates.
  /// Delegates to [AvailabilityChecker] for the actual logic.
  @override
  Future<bool> checkAvailability({
    required String propertyId,
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    return _availabilityChecker.isAvailable(
      propertyId: propertyId,
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    );
  }

  /// Normalize a DateTime to UTC midnight for consistent date comparison.
  ///
  /// TIMEZONE FIX: Firestore stores dates as midnight local time (UTC+1/+2 for Europe/Zagreb).
  /// When converted to Dart DateTime, these appear as 22:00/23:00 PREVIOUS day in UTC.
  /// Example: "Jul 1, 00:00 UTC+2" → "Jun 30, 22:00 UTC"
  /// This causes date comparisons to fail when comparing with pure UTC dates.
  ///
  /// This helper extracts the calendar date (year, month, day) and creates
  /// a new DateTime at UTC midnight, ensuring consistent comparisons.
  DateTime _normalizeToUtcMidnight(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Check availability with detailed result.
  ///
  /// Returns [AvailabilityCheckResult] with conflict information if not available.
  Future<AvailabilityCheckResult> checkAvailabilityDetailed({
    required String propertyId,
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    return _availabilityChecker.check(
      propertyId: propertyId,
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    );
  }

  /// Calculate total price for date range.
  ///
  /// Uses price hierarchy: custom daily_price > weekendBasePrice (from unit) > basePrice.
  /// Delegates to [BookingPriceCalculator] for the actual calculation.
  ///
  /// [basePrice] - Unit's base price per night (required for fallback when no daily_price)
  /// [weekendBasePrice] - Unit's weekend base price (optional, for Sat-Sun by default)
  /// [weekendDays] - optional custom weekend days (1=Mon...7=Sun). Default: [6,7]
  ///
  /// Throws [DatesNotAvailableException] if dates are not available.
  @override
  Future<double> calculateBookingPrice({
    required String propertyId,
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required double basePrice,
    double? weekendBasePrice,
    List<int>? weekendDays,
  }) async {
    final result = await _priceCalculator.calculate(
      propertyId: propertyId,
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
      basePrice: basePrice,
      weekendBasePrice: weekendBasePrice,
      weekendDays: weekendDays,
    );
    return result.totalPrice;
  }

  /// Calculate booking price with detailed breakdown.
  ///
  /// Returns [PriceCalculationResult] with per-night breakdown.
  Future<PriceCalculationResult> calculateBookingPriceDetailed({
    required String propertyId,
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required double basePrice,
    double? weekendBasePrice,
    List<int>? weekendDays,
  }) {
    return _priceCalculator.calculate(
      propertyId: propertyId,
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
      basePrice: basePrice,
      weekendBasePrice: weekendBasePrice,
      weekendDays: weekendDays,
    );
  }
}
