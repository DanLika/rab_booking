// Desktop MASTER-DETAIL split regression for the admin Users screen
// (handoff `design_handoff/source/admin-users.jsx` `AdminUsersDesktop` /
// `AUOwnerPanel`).
//
// On wide admin widths the owners table renders on the LEFT and an inline
// detail panel on the RIGHT. Selecting a row populates the panel (no navigation
// away); a close action clears it. Below the split breakpoint the table/card
// list render unchanged (#860 cards, #765 overflow fix). Pumped via the
// `@visibleForTesting` seam with an injected fake panel (no Firebase / Riverpod
// — the real panel is the provider-backed `UserDetailScreen`).

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
    email: 'owner$i@example.com',
    firstName: 'Owner',
    lastName: 'Number $i',
    role: UserRole.owner,
    accountType: i.isEven ? AccountType.premium : AccountType.trial,
    // Distinct day per row so the plain created-at Text is unique-per-row and
    // can be tapped to trigger the DataRow selection (name/email cells are
    // SelectableText and would swallow the tap).
    createdAt: DateTime(2025, 6, i + 1),
  ),
);

String _dateLabel(int i) {
  final d = DateTime(2025, 6, i + 1);
  return '${d.day}.${d.month}.${d.year}';
}

/// Taps row [i] by its (unique) created-at date cell → fires the DataRow
/// `onSelectChanged` wired to the master-detail select callback.
Future<void> _selectRow(WidgetTester tester, int i) async {
  await tester.tap(find.text(_dateLabel(i)));
  await tester.pumpAndSettle();
}

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

Widget _harness(List<UserModel> owners) => buildUsersMasterDetailForTest(
  owners: owners,
  // Fake panel stands in for the provider-backed UserDetailScreen: shows the
  // selected id + a close button wired to the harness callback.
  panelBuilder: (selectedId, onClose) => Column(
    key: const ValueKey('fake_panel'),
    children: [
      Text('PANEL:$selectedId'),
      IconButton(
        key: const ValueKey('fake_panel_close'),
        icon: const Icon(Icons.close),
        onPressed: onClose,
      ),
    ],
  ),
);

void main() {
  group('desktop master-detail split', () {
    testWidgets('starts with placeholder, no panel selected', (tester) async {
      await _pump(tester, _harness(_owners(4)), 1400);

      expect(find.text('Select an owner'), findsOneWidget);
      expect(find.byKey(const ValueKey('fake_panel')), findsNothing);
      expect(find.text('Owner Number 0'), findsOneWidget);
    });

    testWidgets('selecting a row populates the inline panel', (tester) async {
      await _pump(tester, _harness(_owners(4)), 1400);

      await _selectRow(tester, 1);

      expect(find.byKey(const ValueKey('fake_panel')), findsOneWidget);
      expect(find.text('PANEL:owner-1'), findsOneWidget);
      expect(find.text('Select an owner'), findsNothing);
    });

    testWidgets('selecting a different row swaps the panel in place', (
      tester,
    ) async {
      await _pump(tester, _harness(_owners(4)), 1400);

      await _selectRow(tester, 0);
      expect(find.text('PANEL:owner-0'), findsOneWidget);

      await _selectRow(tester, 2);
      expect(find.text('PANEL:owner-2'), findsOneWidget);
      expect(find.text('PANEL:owner-0'), findsNothing);
    });

    testWidgets('close action clears the selection back to placeholder', (
      tester,
    ) async {
      await _pump(tester, _harness(_owners(4)), 1400);

      await _selectRow(tester, 1);
      expect(find.byKey(const ValueKey('fake_panel')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('fake_panel_close')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('fake_panel')), findsNothing);
      expect(find.text('Select an owner'), findsOneWidget);
    });

    testWidgets('no RenderFlex overflow across desktop widths', (tester) async {
      for (final w in <double>[1000, 1100, 1440]) {
        await _pump(tester, _harness(_owners(8)), w);
        expect(tester.takeException(), isNull, reason: 'overflow at ${w}px');
      }
    });

    testWidgets('breakpoint constant is the desktop tier', (tester) async {
      expect(usersListMasterDetailBreakpoint, 1000.0);
    });
  });
}
