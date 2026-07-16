// Regression: a filtered page that matches nothing must not dead-end the list.
//
// Property and date filters are applied CLIENT-SIDE over each page —
// Firestore cannot express them beside `orderBy('created_at')` (an inequality
// must match the first orderBy). So a page can filter to zero rows while
// matches wait on a later page.
//
// The bug: `getOwnerBookingsPaginated` answered that case with
//   `return const PaginatedBookingsResult(bookings: [], hasMore: false);`
// throwing away a LIVE cursor. An owner with two properties, filtering by the
// one whose bookings sit past the page boundary, saw "no bookings" for a
// property that has them — and `hasMore: false` told the UI that was the whole
// truth, so the scroll-driven pager never asked for page 2.
//
// This drives the REAL repository against fake_cloud_firestore. Reverting the
// src change fails it.
//
// SCOPE: the cells here stop at the cursor contract — the point the bug lives.
// Asserting the enriched rows on page 2 would need full PropertyModel /
// UnitModel seed shape (`_enrichBookingsWithRelatedData` casts several fields
// unconditionally), which tests the enrich path, not this fix.

import 'package:bookbed/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart';
import 'package:bookbed/core/constants/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

/// `_enrichBookingsWithRelatedData` reads `_auth.currentUser?.uid` rather than
/// the `ownerId` it was handed, and bails to `[]` when it is null — so the
/// signed-in user must be stubbed even though the query itself takes ownerId.
class _MockUser extends Mock implements User {}

/// Injected so the constructor does not reach for a live
/// `FirebaseFunctions.instanceFor` (needs Firebase init). Unused by the paging
/// path under test.
class _MockFunctions extends Mock implements FirebaseFunctions {}

const _ownerId = 'owner-1';
const _propA = 'propA';
const _propB = 'propB';

void main() {
  late FakeFirebaseFirestore db;
  late FirebaseOwnerBookingsRepository repo;

  /// 25 confirmed bookings, newest first by created_at:
  /// rows 0-21 on property A, rows 22-24 on property B. With limit=20, every
  /// propB booking sits past the first page.
  Future<void> seed() async {
    for (var i = 0; i < 25; i++) {
      final onA = i < 22;
      final propertyId = onA ? _propA : _propB;
      final unitId = onA ? 'unitA' : 'unitB';
      await db
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .doc(unitId)
          .collection('bookings')
          .doc('bk-$i')
          .set({
            'owner_id': _ownerId,
            'property_id': propertyId,
            'unit_id': unitId,
            'status': 'confirmed',
            // Descending created_at => bk-0 is newest and lands on page 1.
            'created_at': Timestamp.fromDate(
              DateTime(2026, 1, 1).add(Duration(days: 25 - i)),
            ),
            'check_in': Timestamp.fromDate(DateTime(2026, 8, 1)),
            'check_out': Timestamp.fromDate(DateTime(2026, 8, 5)),
            'guest_name': 'Guest $i',
            'guest_email': 'g$i@example.com',
            'total_price': 100,
          });
    }
    // Property docs must carry owner_id — enrich resolves units through the
    // owner's properties. Units must exist because the property filter maps
    // propertyId -> unit IDs through the subcollection.
    for (final e in [(_propA, 'unitA'), (_propB, 'unitB')]) {
      await db.collection('properties').doc(e.$1).set({
        'owner_id': _ownerId,
        'name': e.$1,
      });
      await db
          .collection('properties')
          .doc(e.$1)
          .collection('units')
          .doc(e.$2)
          .set({'name': e.$2, 'max_guests': 2, 'property_id': e.$1});
    }
  }

  setUp(() async {
    db = FakeFirebaseFirestore();
    final user = _MockUser();
    when(() => user.uid).thenReturn(_ownerId);
    final auth = _MockAuth();
    when(() => auth.currentUser).thenReturn(user);
    repo = FirebaseOwnerBookingsRepository(
      db,
      auth,
      functions: _MockFunctions(),
    );
    await seed();
  });

  test(
    'filtering by a property whose rows are all past page 1 keeps the cursor live',
    () async {
      final page1 = await repo.getOwnerBookingsPaginated(
        ownerId: _ownerId,
        unitIds: const ['unitA', 'unitB'],
        propertyId: _propB,
        status: BookingStatus.confirmed,
        limit: 20,
      );

      // Page 1 is rows 0-19 — all property A, so the filter drops every one.
      expect(page1.bookings, isEmpty);

      // THE BITE: the old code returned hasMore:false here and stranded propB's
      // three bookings behind a list that said "that's everything".
      expect(
        page1.hasMore,
        isTrue,
        reason: 'rows 20-24 are unread — the cursor must survive an empty page',
      );
      expect(
        page1.lastDocument,
        isNotNull,
        reason: 'the caller needs the cursor to page on',
      );
    },
  );

  test(
    'a property with genuinely no bookings terminates instead of spinning',
    () async {
      final page = await repo.getOwnerBookingsPaginated(
        ownerId: _ownerId,
        unitIds: const ['unitA', 'unitB'],
        propertyId: 'propZ',
        status: BookingStatus.confirmed,
        limit: 20,
      );
      // propZ resolves to zero units → short-circuits before the query.
      expect(page.bookings, isEmpty);
      expect(
        page.hasMore,
        isFalse,
        reason: 'the fill loop must stop, not spin',
      );
    },
  );
}
