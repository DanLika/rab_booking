import 'package:bookbed/shared/widgets/redesign/bb_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sidebar is 260px wide and tall; give it a generous surface so descendants
/// don't overflow the test viewport.
Widget _scaffold(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 360, height: 900, child: child)),
  );
}

const List<BbSidebarGroup> _groups = <BbSidebarGroup>[
  BbSidebarGroup(
    label: 'Glavno',
    items: <BbSidebarItem>[
      BbSidebarItem(id: 'home', icon: 'home', label: 'Dashboard'),
      BbSidebarItem(
        id: 'bookings',
        icon: 'event',
        label: 'Rezervacije',
        badge: 3,
        children: <BbSidebarSubItem>[
          BbSidebarSubItem(id: 'bookings/upcoming', label: 'Nadolazeće'),
          BbSidebarSubItem(id: 'bookings/past', label: 'Prošle'),
        ],
      ),
    ],
  ),
  BbSidebarGroup(
    label: 'Upravljanje',
    items: <BbSidebarItem>[
      BbSidebarItem(id: 'units', icon: 'apartment', label: 'Smještaji'),
    ],
  ),
];

void main() {
  group('BbSidebar (Phase 1.5a)', () {
    testWidgets('renders group labels (uppercased) + item labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(const BbSidebar(groups: _groups, activeRoute: 'home')),
      );
      // Group labels rendered uppercased per _NavGroupLabel.
      expect(find.text('GLAVNO'), findsOneWidget);
      expect(find.text('UPRAVLJANJE'), findsOneWidget);
      // Item labels at their original case.
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Rezervacije'), findsOneWidget);
      expect(find.text('Smještaji'), findsOneWidget);
    });

    testWidgets('badge renders as text when badge > 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(const BbSidebar(groups: _groups, activeRoute: 'home')),
      );
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('onNavigate fires with item id on tap', (
      WidgetTester tester,
    ) async {
      final List<String> taps = <String>[];
      await tester.pumpWidget(
        _scaffold(
          BbSidebar(groups: _groups, activeRoute: 'home', onNavigate: taps.add),
        ),
      );
      await tester.tap(find.text('Smještaji'));
      await tester.pump();
      expect(taps, contains('units'));
    });

    testWidgets('expandable item mounts AnimatedRotation for chevron', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(const BbSidebar(groups: _groups, activeRoute: 'home')),
      );
      // Source: _SidebarItem.build adds AnimatedRotation only when expandable.
      // Our `bookings` item has children → exactly one AnimatedRotation.
      expect(find.byType(AnimatedRotation), findsOneWidget);
    });

    testWidgets(
      'active expandable item reveals child sub-items (rotation gate)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _scaffold(const BbSidebar(groups: _groups, activeRoute: 'bookings')),
        );
        // When active && expandable, children render below.
        expect(find.text('Nadolazeće'), findsOneWidget);
        expect(find.text('Prošle'), findsOneWidget);
      },
    );

    testWidgets('inactive expandable item hides children', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(const BbSidebar(groups: _groups, activeRoute: 'home')),
      );
      // bookings is not active → sub-items not mounted.
      expect(find.text('Nadolazeće'), findsNothing);
      expect(find.text('Prošle'), findsNothing);
    });

    testWidgets('user row renders when user supplied', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          const BbSidebar(
            groups: _groups,
            activeRoute: 'home',
            user: BbSidebarUser(name: 'Ana', email: 'ana@example.com'),
          ),
        ),
      );
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('ana@example.com'), findsOneWidget);
    });

    testWidgets('search affordance shows hint + ⌘K chip', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(const BbSidebar(groups: _groups, activeRoute: 'home')),
      );
      expect(find.text('Pretraži…'), findsOneWidget);
      expect(find.text('⌘K'), findsOneWidget);
    });
  });
}
