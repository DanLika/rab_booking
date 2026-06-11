// F-T3-Notif-01 regression (Site 2 — premium header pending card):
// `_RezPendingCardState._run` (private widget inside
// `bookings_premium_header.dart`) bundles approve/reject CF call with
// a best-effort `windowedBookingsNotifierProvider.notifier.refresh()`.
// Pre-fix, refresh() throwing surfaced
// `notificationApproveError` / `notificationRejectError` toasts even
// though the booking was already confirmed/cancelled server-side.
//
// Why structural rather than full integration:
//   `_RezPendingCard` is file-private; its parent `_RezPendingQueue`
//   is also private; the only public entry (`BookingsPremiumHeader`)
//   reads `unifiedDashboardNotifierProvider` AND
//   `windowedBookingsNotifierProvider`, both Riverpod codegen
//   notifiers whose `build()` paths trigger Firestore queries on
//   construction. A clean fake requires subclassing the generated
//   `_$WindowedBookingsNotifier` + overriding multiple methods +
//   constructing synthetic `OwnerBooking` fixtures — large surface,
//   easy to drift, and would in practice retest Riverpod's own
//   override plumbing rather than the fix.
//
// What this catches: the inner try/catch around the best-effort
// `refresh()` is the load-bearing line. If a future edit collapses
// it back into the outer try/catch, the regression returns. This
// test reads the source file and asserts both (a) the inner-try
// wrapper exists around the refresh() call and (b) the catch logs
// + does NOT rethrow.
//
// Site 1 has full behavioural coverage in
// `notifications_screen_approve_decouple_test.dart` — the two
// together cover the F-T3-Notif-01 class on both surfaces.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bookings_premium_header — F-T3-Notif-01 decouple shape', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/owner_dashboard/presentation/widgets/bookings/bookings_premium_header.dart',
      ).readAsStringSync();
    });

    test('inner try wraps windowedBookingsNotifier.refresh() call', () {
      // The fix: an inner `try { ... refresh() ... } catch (e) { ... }`
      // block must enclose the refresh() call so the outer catch only
      // fires on real approve/reject CF failure.
      //
      // Regex tolerates whitespace + arbitrary formatting between
      // `try {`, the refresh await, and the inner catch.
      final pattern = RegExp(
        r'try\s*\{\s*'
        r'await\s+ref\.read\(\s*windowedBookingsNotifierProvider\.notifier\s*\)\s*\.refresh\(\s*\)\s*;\s*'
        r'\}\s*'
        r'catch\s*\(',
        multiLine: true,
      );
      expect(
        pattern.hasMatch(source),
        isTrue,
        reason:
            'F-T3-Notif-01 regression: refresh() must be wrapped in its '
            'own inner try/catch so a best-effort failure does NOT '
            'poison the approve/reject success toast. '
            'See `_RezPendingCardState._run`.',
      );
    });

    test('inner catch logs + swallows (no rethrow)', () {
      // The inner catch must NOT rethrow — that would defeat the
      // decouple. Look for the debugPrint log + absence of
      // `rethrow` inside the inner block.
      expect(
        source.contains(
          'debugPrint(\n'
          "          '[premium-header] "
          "post-action refresh best-effort failed: \$e',",
        ),
        isTrue,
        reason: 'Inner catch must log via debugPrint for diagnostics.',
      );

      // Pull the inner try-catch substring and confirm no `rethrow`.
      final inner = RegExp(
        r'try\s*\{[\s\S]*?refresh\(\)[\s\S]*?\}\s*catch\s*\([^)]*\)\s*\{([\s\S]*?)\}',
      ).firstMatch(source);
      expect(
        inner,
        isNotNull,
        reason: 'Inner try/catch block must be matchable.',
      );
      expect(
        inner!.group(1),
        isNot(contains('rethrow')),
        reason: 'Best-effort failure must be swallowed, not re-raised.',
      );
    });

    test('outer try/catch still present (error path preserved)', () {
      // The outer catch is what fires `notificationApproveError` /
      // `notificationRejectError`. Must remain for the real-CF-failure
      // case.
      expect(
        source.contains('notificationApproveError'),
        isTrue,
        reason: 'Outer error toast for approve must still exist.',
      );
      expect(
        source.contains('notificationRejectError'),
        isTrue,
        reason: 'Outer error toast for reject must still exist.',
      );
    });
  });
}
