// Regression: the admin Users list must never strand owners behind an
// active filter.
//
// Filtering/search is CLIENT-SIDE over the rows loaded so far (20/page), but
// the status-tab badges are REAL server-side `.count()` aggregates over the
// whole `users` collection. The historical gate
//   `showLoadMore = notifier.hasMore && !_hasActiveFilters`
// hid the ONLY control that pulls further Firestore pages precisely when a
// filter was active — so a tab could truthfully badge "Suspended 1" while the
// table rendered "No users found" and offered no way forward.
//
// Live-reproduced on bookbed-dev (31 owners, the single suspended owner being
// the oldest row => page 2+): tab "Suspended 1" => "No users found", no
// "Load more" button in the a11y tree. Search for a real owner's email on a
// later page likewise returned "No users found".
//
// Pure seam — no Firebase.

// NOTE ON COVERAGE: the `shouldShowLoadMore` seam below went green while the
// SCREEN still dead-ended, because `build` early-returned `_EmptyState` before
// ever consulting it ([[seam-test-proves-fn-not-wiring]]). The widget group
// pins that call site: the empty state itself must carry the Load-more escape
// hatch and must not claim a flat "No users found" while pages remain.

import 'package:bookbed/features/admin/presentation/screens/users_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpEmpty(
  WidgetTester tester, {
  required bool hasMore,
  VoidCallback? onLoadMore,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: emptyStateForTest(hasMore: hasMore, onLoadMore: onLoadMore),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('shouldShowLoadMore', () {
    // THE BITE: fails under the old `hasMore && !hasActiveFilters` gate.
    test('offers Load more while a filter is active and more pages exist', () {
      expect(
        shouldShowLoadMore(hasMore: true, hasActiveFilters: true),
        isTrue,
        reason:
            'A filter must not hide Load more: matches may live on a later '
            'Firestore page, and this is the only control that fetches them.',
      );
    });

    test('offers Load more with no filters and more pages exist', () {
      expect(
        shouldShowLoadMore(hasMore: true, hasActiveFilters: false),
        isTrue,
      );
    });

    test('hides Load more once the cursor is exhausted, filtered or not', () {
      expect(
        shouldShowLoadMore(hasMore: false, hasActiveFilters: true),
        isFalse,
      );
      expect(
        shouldShowLoadMore(hasMore: false, hasActiveFilters: false),
        isFalse,
      );
    });

    test('visibility tracks hasMore alone — filters never suppress it', () {
      for (final filtered in [true, false]) {
        expect(
          shouldShowLoadMore(hasMore: true, hasActiveFilters: filtered),
          isTrue,
        );
      }
    });
  });

  group('empty state (the call site the seam alone did not prove)', () {
    // THE BITE: the old `_EmptyState` was a const flat "No users found" with
    // no action, so a filter matching zero LOADED rows stranded the admin.
    testWidgets('offers Load more when pages remain', (tester) async {
      var loadMoreCalls = 0;
      await _pumpEmpty(
        tester,
        hasMore: true,
        onLoadMore: () => loadMoreCalls++,
      );

      expect(
        find.text('No users found'),
        findsNothing,
        reason:
            'Claiming a flat "No users found" is false while unloaded pages '
            'may still hold matches.',
      );
      expect(find.text('Load more'), findsOneWidget);

      await tester.tap(find.text('Load more'));
      await tester.pump();
      expect(loadMoreCalls, 1, reason: 'Load more must fetch the next page.');
    });

    testWidgets('reports a plain empty result once exhausted', (tester) async {
      await _pumpEmpty(tester, hasMore: false);
      expect(find.text('No users found'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
    });
  });
}
