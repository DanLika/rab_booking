// Responsive layout + numbered-pagination regression for the admin Users list
// (handoff `design_handoff/source/admin-users.jsx`).
//
// GAP 2 — below the compact-card breakpoint the squeezed DataTable is replaced
// by handoff-style owner cards (`_UsersList` / `AUMobileCard`); at/above it the
// DataTable renders (keeping the #765 horizontal-scroll overflow fix).
//
// GAP 1 — numbered pagination (`_UsersPagination` / `AUPagination`) renders
// prev / 1 2 3 … / next over the loaded+filtered rows and fires a page-change
// callback. Both are pumped via `@visibleForTesting` seams (no Firebase).

import 'package:bookbed/core/constants/enums.dart';
import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/admin/presentation/screens/users_list_screen.dart';
import 'package:bookbed/shared/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<UserModel> _owners(int n) => List<UserModel>.generate(
  n,
  (i) => UserModel(
    id: 'owner-$i',
    email: 'very.long.owner.email.address.$i@somelongexampledomain.example.com',
    firstName: 'Maximiliana-Konstantina',
    lastName: 'Đurđevković-Pavličić $i',
    role: UserRole.owner,
    accountType: i.isEven ? AccountType.premium : AccountType.trial,
    createdAt: DateTime(2025, 6, (i % 27) + 1),
  ),
);

Future<void> _pump(WidgetTester tester, Widget child, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('GAP 2 — compact card vs table layout', () {
    for (final w in <double>[390, 599]) {
      testWidgets('mobile card list renders w/o overflow @${w}px', (
        tester,
      ) async {
        await _pump(tester, buildUsersCardListForTest(owners: _owners(6)), w);
        // Card list uses BbCard, not DataTable.
        expect(find.byType(DataTable), findsNothing);
        expect(find.byType(ListView), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('table (not cards) renders at the >=600 boundary', (
      tester,
    ) async {
      await _pump(tester, buildUsersTableForTest(owners: _owners(6)), 640);
      expect(find.byType(DataTable), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('breakpoint is 600 (handoff mobile) and page size is 8', () {
      expect(usersListMobileBreakpoint, 600.0);
      expect(usersListRowsPerPage, 8);
    });
  });

  group('GAP 1 — numbered pagination', () {
    testWidgets('renders prev / numbered / next + range label', (tester) async {
      await _pump(
        tester,
        buildUsersPaginationForTest(
          page: 0,
          pageCount: 25,
          totalRows: 200,
          onPageChanged: (_) {},
        ),
        900,
      );
      // Range label reflects the REAL loaded total (data honesty).
      expect(find.text('Showing 1–8 of 200'), findsOneWidget);
      // First + last + ellipsis (long run collapses).
      expect(find.byKey(const ValueKey('users_page_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('users_page_25')), findsOneWidget);
      expect(find.text('…'), findsWidgets);
      expect(find.bySemanticsLabel('Previous page'), findsOneWidget);
      expect(find.bySemanticsLabel('Next page'), findsOneWidget);
    });

    testWidgets('tapping a page number fires page-change callback', (
      tester,
    ) async {
      int? changed;
      await _pump(
        tester,
        buildUsersPaginationForTest(
          page: 0,
          pageCount: 5,
          totalRows: 40,
          onPageChanged: (p) => changed = p,
        ),
        900,
      );
      await tester.tap(find.byKey(const ValueKey('users_page_3')));
      await tester.pump();
      expect(changed, 2); // 0-based page index for page "3"
    });

    testWidgets('short runs (<=7 pages) show every page, no ellipsis', (
      tester,
    ) async {
      await _pump(
        tester,
        buildUsersPaginationForTest(
          page: 1,
          pageCount: 3,
          totalRows: 20,
          onPageChanged: (_) {},
        ),
        900,
      );
      expect(find.byKey(const ValueKey('users_page_2')), findsOneWidget);
      expect(find.text('…'), findsNothing);
      expect(find.text('Showing 9–16 of 20'), findsOneWidget);
    });
  });
}
