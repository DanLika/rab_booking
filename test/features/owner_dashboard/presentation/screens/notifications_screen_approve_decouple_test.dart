// F-T3-Notif-01 regression: best-effort writes inside
// `_runBookingAction` must NOT poison the success toast when the
// success-critical CF (approve / reject) already committed.
//
// Both sites have a single try/catch around (a) the CF call and
// (b) a best-effort follow-up. Pre-fix, a stale notification doc
// causing `markAsRead` to throw surfaced a misleading
// "Failed to approve booking." toast even after the booking flipped
// pending→confirmed (proven on bookbed-dev: KPI POTVRĐENO 1→2,
// ZARADA €650→€1040 with error toast displayed).
//
// Fix: inner try/catch around the best-effort step, log + swallow.
// Outer catch fires only on real CF failure.

import 'package:bookbed/features/owner_dashboard/domain/models/notification_model.dart';
import 'package:bookbed/features/owner_dashboard/presentation/providers/notifications_provider.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/notifications_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_helpers.dart';

class _RecordingActions implements NotificationActions {
  _RecordingActions({
    this.throwOnMarkAsRead = false,
    this.throwOnApprove = false,
    this.throwOnReject = false,
  });

  final bool throwOnMarkAsRead;
  final bool throwOnApprove;
  final bool throwOnReject;

  bool approveCalled = false;
  bool rejectCalled = false;
  bool markAsReadCalled = false;

  @override
  Future<void> approveBooking(String bookingId) async {
    approveCalled = true;
    if (throwOnApprove) {
      throw Exception('CF approveBooking failed (simulated).');
    }
  }

  @override
  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    rejectCalled = true;
    if (throwOnReject) {
      throw Exception('CF rejectBooking failed (simulated).');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    markAsReadCalled = true;
    if (throwOnMarkAsRead) {
      throw Exception('Stale notification: markAsRead failed (simulated).');
    }
  }

  // All other methods are unused by `_runBookingAction`. Silently no-op so
  // an accidental call doesn't crash the test, but mark them with a clear
  // sentinel so future failures surface.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future<void>.value();
  }
}

NotificationModel _pendingNotif({bool isRead = false}) {
  return NotificationModel(
    id: 'notif-1',
    ownerId: 'test-uid',
    type: NotificationType.bookingCreated,
    title: 'New booking request',
    message: 'Guest wants to book.',
    timestamp: DateTime.utc(2026, 6, 7, 12),
    isRead: isRead,
    bookingId: 'booking-abc',
  );
}

Future<void> _pumpScreenWith({
  required WidgetTester tester,
  required _RecordingActions actions,
  NotificationModel? notification,
}) async {
  await tester.pumpWidget(
    createTestWidget(
      withL10n: true,
      overrides: [
        notificationsStreamProvider.overrideWith(
          (ref) => Stream.value([notification ?? _pendingNotif()]),
        ),
        notificationActionsProvider.overrideWith((ref) => actions),
      ],
      child: const NotificationsScreen(),
    ),
  );
  // Drain the StreamProvider tick + RefreshIndicator setup.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  allowOverflow(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationsScreen — F-T3-Notif-01 decouple', () {
    testWidgets(
      'approve succeeds + markAsRead throws → SUCCESS toast (not error)',
      (tester) async {
        final actions = _RecordingActions(throwOnMarkAsRead: true);
        await _pumpScreenWith(tester: tester, actions: actions);

        final approveBtn = find.text('Approve');
        expect(approveBtn, findsOneWidget);
        await tester.tap(approveBtn);
        await tester.pump();
        // Resolve the approve future + the inner-caught markAsRead future +
        // the snackbar insertion frame.
        await tester.pump(const Duration(milliseconds: 200));

        expect(actions.approveCalled, isTrue);
        expect(actions.markAsReadCalled, isTrue);
        expect(find.text('Booking approved.'), findsOneWidget);
        expect(find.text('Failed to approve booking.'), findsNothing);
      },
    );

    testWidgets(
      'reject succeeds + markAsRead throws → SUCCESS toast (not error)',
      (tester) async {
        final actions = _RecordingActions(throwOnMarkAsRead: true);
        await _pumpScreenWith(tester: tester, actions: actions);

        final rejectBtn = find.text('Reject');
        expect(rejectBtn, findsOneWidget);
        await tester.tap(rejectBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(actions.rejectCalled, isTrue);
        expect(actions.markAsReadCalled, isTrue);
        expect(find.text('Booking rejected.'), findsOneWidget);
        expect(find.text('Failed to reject booking.'), findsNothing);
      },
    );

    testWidgets('approve CF throws → ERROR toast (markAsRead not called)', (
      tester,
    ) async {
      final actions = _RecordingActions(throwOnApprove: true);
      await _pumpScreenWith(tester: tester, actions: actions);

      final approveBtn = find.text('Approve');
      await tester.tap(approveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(actions.approveCalled, isTrue);
      expect(
        actions.markAsReadCalled,
        isFalse,
        reason: 'markAsRead must NOT run when approve CF fails.',
      );
      expect(find.text('Failed to approve booking.'), findsOneWidget);
      expect(find.text('Booking approved.'), findsNothing);
    });

    testWidgets('reject CF throws → ERROR toast (markAsRead not called)', (
      tester,
    ) async {
      final actions = _RecordingActions(throwOnReject: true);
      await _pumpScreenWith(tester: tester, actions: actions);

      final rejectBtn = find.text('Reject');
      await tester.tap(rejectBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(actions.rejectCalled, isTrue);
      expect(
        actions.markAsReadCalled,
        isFalse,
        reason: 'markAsRead must NOT run when reject CF fails.',
      );
      expect(find.text('Failed to reject booking.'), findsOneWidget);
      expect(find.text('Booking rejected.'), findsNothing);
    });

    testWidgets('already-read notif: markAsRead skipped, success toast', (
      tester,
    ) async {
      final actions = _RecordingActions(throwOnMarkAsRead: true);
      await _pumpScreenWith(
        tester: tester,
        actions: actions,
        notification: _pendingNotif(isRead: true),
      );

      final approveBtn = find.text('Approve');
      await tester.tap(approveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(actions.approveCalled, isTrue);
      expect(
        actions.markAsReadCalled,
        isFalse,
        reason: 'isRead=true short-circuits markAsRead branch.',
      );
      expect(find.text('Booking approved.'), findsOneWidget);
    });
  });
}
