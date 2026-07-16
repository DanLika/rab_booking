// Gate-fix regression guard for the owner booking-detail action panel.
//
// When the Rezervacije ledger went lean (read-only rows), the per-row
// approve/reject/complete/cancel buttons were removed. Confirmed-booking
// complete/cancel were re-homed to the detail screen so the capability is not
// stranded. This test pins the gating (`detailActionVisibility`, the single
// source of truth that `_BDStatusActionsState.build` consumes) so a future
// edit can't silently drop an action:
//
//   * confirmed & past      → "Označi kao završenu" (complete), NOT "Otkaži"
//   * confirmed & upcoming  → "Otkaži rezervaciju" (cancel),   NOT "Završi"
//   * confirmed & in-progress (checked in, not yet checked out)
//                           → neither (correct — can't cancel mid-stay nor
//                             complete before check-out) but msg/edit remain
//   * pending               → approve/reject present (regression guard)
//
// Pure-function unit test: needs only a BookingModel (status + dates), no
// Riverpod/Firebase/widget pump.

import 'package:bookbed/core/constants/enums.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/owner_booking_detail_screen.dart';
import 'package:bookbed/shared/models/booking_model.dart';
import 'package:flutter_test/flutter_test.dart';

BookingModel _booking({
  required BookingStatus status,
  required int checkInOffsetDays,
  required int checkOutOffsetDays,
}) {
  final DateTime now = DateTime.now();
  return BookingModel(
    id: 'test-booking',
    unitId: 'test-unit',
    checkIn: now.add(Duration(days: checkInOffsetDays)),
    checkOut: now.add(Duration(days: checkOutOffsetDays)),
    status: status,
    createdAt: now.subtract(const Duration(days: 1)),
  );
}

void main() {
  group('detailActionVisibility — gate-fix regression guard', () {
    test('confirmed & past → complete present, cancel absent', () {
      final vis = detailActionVisibility(
        _booking(
          status: BookingStatus.confirmed,
          checkInOffsetDays: -5,
          checkOutOffsetDays: -2,
        ),
      );
      expect(vis.complete, isTrue, reason: '"Označi kao završenu" must show');
      expect(
        vis.cancel,
        isFalse,
        reason: '"Otkaži" must NOT show on past stay',
      );
      expect(vis.approveReject, isFalse);
      expect(vis.edit, isTrue);
    });

    // THE BITE: the in-stay window fell through BOTH gates — `complete`
    // required isPast, `cancel` required isUpcoming — so a guest currently
    // staying left the owner with NO action: no early departure, no no-show.
    // The function's own docstring claimed it guaranteed the opposite.
    test('confirmed & IN-STAY → both complete and cancel present', () {
      final vis = detailActionVisibility(
        _booking(
          status: BookingStatus.confirmed,
          checkInOffsetDays: -2,
          checkOutOffsetDays: 3,
        ),
      );
      expect(
        vis.complete,
        isTrue,
        reason: 'early departure: the stay has started, owner can close it',
      );
      expect(
        vis.cancel,
        isTrue,
        reason: 'no-show: the stay has not finished, owner can cancel it',
      );
      expect(vis.approveReject, isFalse);
      expect(vis.edit, isTrue);
    });

    // Boundary: check-in is TODAY — the first moment the old gate stranded it
    // (isUpcoming flips false at midnight, isPast is still false).
    test('confirmed & check-in today → not stranded', () {
      final vis = detailActionVisibility(
        _booking(
          status: BookingStatus.confirmed,
          checkInOffsetDays: 0,
          checkOutOffsetDays: 4,
        ),
      );
      expect(
        vis.complete || vis.cancel,
        isTrue,
        reason: 'a confirmed booking must never be action-stranded',
      );
    });

    test('confirmed & upcoming → cancel present, complete absent', () {
      final vis = detailActionVisibility(
        _booking(
          status: BookingStatus.confirmed,
          checkInOffsetDays: 5,
          checkOutOffsetDays: 8,
        ),
      );
      expect(vis.cancel, isTrue, reason: '"Otkaži rezervaciju" must show');
      expect(vis.complete, isFalse, reason: '"Završi" must NOT show pre-stay');
      expect(vis.approveReject, isFalse);
      expect(vis.edit, isTrue);
    });

    // REVERSED 2026-07-16 on an explicit operator decision. This cell used to
    // assert `complete: false, cancel: false` mid-stay, reasoning "not
    // stranded: Poruka + Uredi remain available". That reading of "stranded"
    // was actions-exist, not lifecycle-actions-exist — and it left an owner
    // with no way to handle an early departure or a no-show. Same scenario,
    // now pinning the decided behaviour.
    test(
      'confirmed & in-progress → complete AND cancel offered (was: neither)',
      () {
        final vis = detailActionVisibility(
          _booking(
            status: BookingStatus.confirmed,
            checkInOffsetDays: -2,
            checkOutOffsetDays: 2,
          ),
        );
        expect(vis.complete, isTrue, reason: 'early departure');
        expect(vis.cancel, isTrue, reason: 'no-show');
        expect(vis.approveReject, isFalse);
        expect(vis.edit, isTrue);
      },
    );

    test('pending → approve/reject present (regression guard)', () {
      final vis = detailActionVisibility(
        _booking(
          status: BookingStatus.pending,
          checkInOffsetDays: 5,
          checkOutOffsetDays: 8,
        ),
      );
      expect(vis.approveReject, isTrue);
      expect(vis.complete, isFalse);
      expect(vis.cancel, isFalse);
    });

    test(
      'every confirmed state keeps at least edit/msg (no action-stranding)',
      () {
        for (final (int ci, int co) in const <(int, int)>[
          (-5, -2), // past
          (5, 8), // upcoming
          (-2, 2), // in-progress
        ]) {
          final vis = detailActionVisibility(
            _booking(
              status: BookingStatus.confirmed,
              checkInOffsetDays: ci,
              checkOutOffsetDays: co,
            ),
          );
          expect(vis.edit, isTrue);
        }
      },
    );
  });
}
