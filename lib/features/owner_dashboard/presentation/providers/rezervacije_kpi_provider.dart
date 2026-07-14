import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../shared/providers/widget_repository_providers.dart'
    show firestoreProvider;
import 'owner_bookings_provider.dart' show ownerUnitIdsProvider;

part 'rezervacije_kpi_provider.g.dart';

/// KPI numbers for the Rezervacije premium header.
///
/// The strip previously reused [UnifiedDashboardNotifier], whose window is the
/// Pregled date-range preset (default: LAST 7 days, backward-looking on
/// check_in). Under "Potvrđeno (mj.)" / "Zarada (mj.)" labels that produced
/// lies: a booking confirmed today with a check-in later this month showed 0,
/// and "Nadolazeći — sljedećih 7 dana" was actually a 14-day window. These
/// values are computed for exactly the windows the labels claim:
/// - confirmedThisMonth / revenueThisMonth: status confirmed|completed with
///   check_in inside the CURRENT CALENDAR MONTH (past and future alike);
/// - upcoming7Days: status confirmed|pending with check_in in [now, now+7d).
class RezKpi {
  final int confirmedThisMonth;
  final double revenueThisMonth;
  final int upcoming7Days;

  /// Count of ALL bookings awaiting the owner's response (status == pending),
  /// regardless of check-in date. NOT the windowed/priority-queue preview,
  /// which caps at 4 — the "Na čekanju" tile must show the true total.
  final int pendingTotal;

  const RezKpi({
    required this.confirmedThisMonth,
    required this.revenueThisMonth,
    required this.upcoming7Days,
    required this.pendingTotal,
  });

  static const zero = RezKpi(
    confirmedThisMonth: 0,
    revenueThisMonth: 0,
    upcoming7Days: 0,
    pendingTotal: 0,
  );
}

/// Pure classifier so the window logic is unit-testable without Firestore.
/// [bookings] entries need `status` (String), `check_in` (DateTime) and
/// `total_price` (num, optional). [pendingTotal] is the all-time pending
/// count (computed separately from an aggregation), passed through verbatim.
RezKpi computeRezKpi(
  List<Map<String, dynamic>> bookings,
  DateTime now, {
  int pendingTotal = 0,
}) {
  final monthStart = DateTime(now.year, now.month);
  final nextMonthStart = DateTime(now.year, now.month + 1);
  final upcomingEnd = now.add(const Duration(days: 7));

  var confirmedThisMonth = 0;
  var revenueThisMonth = 0.0;
  var upcoming7Days = 0;

  for (final b in bookings) {
    final status = b['status'] as String?;
    final checkIn = b['check_in'] as DateTime?;
    if (status == null || checkIn == null) continue;

    final inMonth =
        !checkIn.isBefore(monthStart) && checkIn.isBefore(nextMonthStart);
    if (inMonth && (status == 'confirmed' || status == 'completed')) {
      confirmedThisMonth++;
      revenueThisMonth += (b['total_price'] as num?)?.toDouble() ?? 0.0;
    }

    final inUpcoming = !checkIn.isBefore(now) && checkIn.isBefore(upcomingEnd);
    if (inUpcoming && (status == 'confirmed' || status == 'pending')) {
      upcoming7Days++;
    }
  }

  return RezKpi(
    confirmedThisMonth: confirmedThisMonth,
    revenueThisMonth: revenueThisMonth,
    upcoming7Days: upcoming7Days,
    pendingTotal: pendingTotal,
  );
}

@riverpod
Future<RezKpi> rezervacijeKpi(Ref ref) async {
  final authState = ref.watch(enhancedAuthProvider);
  final userId = authState.userModel?.id;
  if (userId == null) return RezKpi.zero;

  try {
    final unitIds = await ref.watch(ownerUnitIdsProvider.future);
    if (unitIds.isEmpty) return RezKpi.zero;

    final firestore = ref.read(firestoreProvider);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonthStart = DateTime(now.year, now.month + 1);
    final upcomingEnd = now.add(const Duration(days: 7));

    // One superset fetch covering both windows; computeRezKpi classifies.
    final windowStart = monthStart.isBefore(now) ? monthStart : now;
    final windowEnd = nextMonthStart.isAfter(upcomingEnd)
        ? nextMonthStart
        : upcomingEnd;

    final docs = <Map<String, dynamic>>[];
    // owner_id + status + check_in range — same composite the unified
    // dashboard's upcoming-check-ins query already relies on.
    for (final status in ['confirmed', 'completed', 'pending']) {
      try {
        final snapshot = await firestore
            .collectionGroup('bookings')
            .where('owner_id', isEqualTo: userId)
            .where('status', isEqualTo: status)
            .where(
              'check_in',
              isGreaterThanOrEqualTo: Timestamp.fromDate(windowStart),
            )
            .where('check_in', isLessThan: Timestamp.fromDate(windowEnd))
            .get();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (!unitIds.contains(data['unit_id'])) continue;
          docs.add({
            'status': data['status'],
            'check_in': (data['check_in'] as Timestamp?)?.toDate(),
            'total_price': data['total_price'],
          });
        }
      } catch (e, st) {
        await LoggingService.logError(
          'RezKpi: failed to query $status bookings',
          e,
          st,
        );
        // Graceful degradation: skip this status, keep the rest.
      }
    }

    // "Na čekanju" tile = ALL pending bookings awaiting the owner's response,
    // regardless of check-in date. The priority-queue preview caps at 4 and
    // the windowed list caps at 20/50, so neither can feed an honest count.
    // Pending sets are small (they need action), so a filtered get() is cheap
    // and lets us apply the same unit-ownership filter as the rest.
    var pendingTotal = 0;
    try {
      final pendingSnap = await firestore
          .collectionGroup('bookings')
          .where('owner_id', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      for (final doc in pendingSnap.docs) {
        if (unitIds.contains(doc.data()['unit_id'])) pendingTotal++;
      }
    } catch (e, st) {
      await LoggingService.logError('RezKpi: failed to count pending', e, st);
      // Graceful degradation: leave pendingTotal at 0.
    }

    return computeRezKpi(docs, now, pendingTotal: pendingTotal);
  } catch (e, st) {
    await LoggingService.logError('RezKpi: failed to compute', e, st);
    return RezKpi.zero;
  }
}
