// Responsive regression for the admin Users list DataTable (P0,
// audit/responsive-overflow-a11y-2026-06-20).
//
// Live repro: the 5-column `DataTable` inside `_UsersTable` overflowed
// horizontally in the 800-1100px window (above the <800 card fallback). It sat
// in a vertical-only SingleChildScrollView with no horizontal escape, so its
// intrinsic content width blew past the viewport and painted the overflow
// stripe. Fix = wrap the DataTable in a horizontal SingleChildScrollView +
// ConstrainedBox(minWidth: card width).
//
// `UsersListScreen` builds an `OwnersListNotifier` that hits Firestore on
// construction, so we pump the offending `_UsersTable` directly via the
// `buildUsersTableForTest` seam across the failure-window widths.

import 'package:bookbed/core/constants/enums.dart';
import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/admin/presentation/screens/users_list_screen.dart';
import 'package:bookbed/shared/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Long names + emails push the 5-column table's intrinsic width past the
  // viewport at 780-1100px — the real-world overflow trigger.
  final owners = List<UserModel>.generate(
    6,
    (i) => UserModel(
      id: 'owner-$i',
      email:
          'very.long.owner.email.address.$i@somelongexampledomain.example.com',
      firstName: 'Maximiliana-Konstantina',
      lastName: 'Đurđevković-Pavličić $i',
      role: UserRole.owner,
      accountType: i.isEven ? AccountType.premium : AccountType.trial,
      createdAt: DateTime(2025, 6, i + 1),
      featureFlags: {},
    ),
  );

  // The audit's failure window (780-1100) plus a wide check (1440) confirming
  // the table fills rather than scrolls when there's room.
  const widths = <double>[780, 900, 1100, 1440];

  for (final w in widths) {
    testWidgets('admin users table — no overflow + h-scrollable @${w}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(w, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: Scaffold(body: buildUsersTableForTest(owners: owners)),
        ),
      );
      await tester.pump();

      // 1) No horizontal overflow at any failure-window width.
      expect(
        tester.takeException(),
        isNull,
        reason: 'users DataTable overflowed at viewport ${w}px',
      );

      // 2) The fix's horizontal escape exists: a horizontally-scrolling
      //    SingleChildScrollView wraps the table. Deterministic guard — absent
      //    pre-fix. (The table also has the outer vertical scroll, so we assert
      //    that *some* SingleChildScrollView is horizontal.)
      final scrollViews = tester.widgetList<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(
        scrollViews.any((s) => s.scrollDirection == Axis.horizontal),
        isTrue,
        reason: 'no horizontal SingleChildScrollView around the table @${w}px',
      );
    });
  }
}
