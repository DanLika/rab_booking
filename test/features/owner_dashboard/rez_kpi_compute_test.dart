import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/owner_dashboard/presentation/providers/rezervacije_kpi_provider.dart';

Map<String, dynamic> b(String status, DateTime checkIn, [num? price]) => {
  'status': status,
  'check_in': checkIn,
  'total_price': price,
};

void main() {
  // Fixed "now": 2026-07-13 12:00.
  final now = DateTime(2026, 7, 13, 12);

  group('computeRezKpi', () {
    test('confirmed booking later this month counts as monthly (the bug)', () {
      // Regression: dashboard last-7-days window read this as 0.
      final kpi = computeRezKpi([
        b('confirmed', DateTime(2026, 7, 20), 750),
      ], now);
      expect(kpi.confirmedThisMonth, 1);
      expect(kpi.revenueThisMonth, 750);
    });

    test('month window: first day in, next-month first day out', () {
      final kpi = computeRezKpi([
        b('confirmed', DateTime(2026, 7), 100),
        b('confirmed', DateTime(2026, 8), 999),
        b('confirmed', DateTime(2026, 6, 30), 999),
      ], now);
      expect(kpi.confirmedThisMonth, 1);
      expect(kpi.revenueThisMonth, 100);
    });

    test('completed counts toward month; pending and cancelled do not', () {
      final kpi = computeRezKpi([
        b('completed', DateTime(2026, 7, 5), 200),
        b('pending', DateTime(2026, 7, 21), 300),
        b('cancelled', DateTime(2026, 7, 22), 400),
      ], now);
      expect(kpi.confirmedThisMonth, 1);
      expect(kpi.revenueThisMonth, 200);
    });

    test('upcoming7: confirmed and pending inside 7 days, not at day 8', () {
      final kpi = computeRezKpi([
        b('confirmed', DateTime(2026, 7, 14)),
        b('pending', DateTime(2026, 7, 19)),
        b('confirmed', DateTime(2026, 7, 21)), // day 8 — out
        b('cancelled', DateTime(2026, 7, 15)), // wrong status — out
      ], now);
      expect(kpi.upcoming7Days, 2);
    });

    test('upcoming7 excludes past check-ins even within the month', () {
      final kpi = computeRezKpi([b('confirmed', DateTime(2026, 7, 10))], now);
      expect(kpi.confirmedThisMonth, 1);
      expect(kpi.upcoming7Days, 0);
    });

    test('null total_price sums as 0; missing fields skipped', () {
      final kpi = computeRezKpi([
        b('confirmed', DateTime(2026, 7, 20)),
        {'status': 'confirmed'}, // no check_in
        {'check_in': DateTime(2026, 7, 20)}, // no status
      ], now);
      expect(kpi.confirmedThisMonth, 1);
      expect(kpi.revenueThisMonth, 0);
    });

    test(
      'pendingTotal passes through verbatim (not derived from windowed docs)',
      () {
        // The tile total is an all-time aggregation injected separately; it is
        // independent of how many pending docs are in the windowed [bookings].
        final kpi = computeRezKpi(
          [b('pending', DateTime(2026, 7, 21), 300)],
          now,
          pendingTotal: 17,
        );
        expect(kpi.pendingTotal, 17);
        // windowed pending still only feeds upcoming7Days, not the tile count.
        expect(kpi.upcoming7Days, 0); // Jul 21 is >7d from Jul 13
      },
    );

    test('pendingTotal defaults to 0 when omitted', () {
      final kpi = computeRezKpi([
        b('confirmed', DateTime(2026, 7, 20), 750),
      ], now);
      expect(kpi.pendingTotal, 0);
    });
  });
}
