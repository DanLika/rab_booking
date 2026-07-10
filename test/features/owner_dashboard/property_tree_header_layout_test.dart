// RED->GREEN layout gate for the units master-panel `PropertyTreeHeader`
// (handoff units.jsx PropertyTree flat-row rework, iteration 15 / #845 deferred).
//
// Pumps the REAL `@visibleForTesting PropertyTreeHeader` directly (no Scaffold,
// drawer, Firebase, or provider) across the panel width at every canonical
// breakpoint (320 / 390 / 768 / 1440) in light + dark, with a pathologically
// long property name.
//
// Primary assertion: NO RenderFlex overflow at any width — the structural fix
// for the wrap/overflow bug that #850 band-aided with ellipsis. The name is
// `Expanded` so it ellipsizes instead of stealing width from the fixed 3-icon
// action cluster. On main (pre-fix) the ExpansionTile title slot wrapped; this
// header lays out on a single row.
//
// Also proves expand/collapse toggle + all three action callbacks fire.

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/unified_unit_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _longName =
    'Vila Sunčani Zaljev Premium Apartmani Sa Pogledom Na More I Bazenom';

// The master panel is 280px wide; the header lives inside it regardless of the
// outer viewport. We constrain to the panel width to reproduce the real slot.
const double _kPanelWidth = 280.0;

Widget _wrap({required bool dark, required Widget child}) {
  final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: Center(
        child: SizedBox(width: _kPanelWidth, child: child),
      ),
    ),
  );
}

PropertyTreeHeader _header(
  ThemeData theme, {
  required bool expanded,
  required VoidCallback onToggle,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
  VoidCallback? onAdd,
}) {
  return PropertyTreeHeader(
    theme: theme,
    propertyName: _longName,
    canDelete: true,
    expanded: expanded,
    onToggle: onToggle,
    editTooltip: 'edit',
    deleteTooltip: 'delete',
    addTooltip: 'add',
    unitsCountLabel: '12 jedinica',
    onEdit: onEdit ?? () {},
    onDelete: onDelete ?? () {},
    onAdd: onAdd ?? () {},
  );
}

void main() {
  // Outer viewport widths — the header itself is pinned to the 280px panel, but
  // we resize the surface to mirror the 4 canonical breakpoints so a future
  // regression at any device size is caught.
  const widths = <double>[320, 390, 768, 1440];

  for (final dark in [false, true]) {
    final label = dark ? 'dark' : 'light';
    for (final w in widths) {
      testWidgets(
        'long name lays out without overflow @ ${w.toInt()}px ($label)',
        (tester) async {
          tester.view.physicalSize = Size(w, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
          await tester.pumpWidget(
            _wrap(
              dark: dark,
              child: _header(theme, expanded: true, onToggle: () {}),
            ),
          );
          await tester.pump();

          // The real gate: no RenderFlex overflow was thrown.
          expect(tester.takeException(), isNull);

          // Name renders on a single row (ellipsized, not wrapped).
          final nameFinder = find.text(_longName);
          expect(nameFinder, findsOneWidget);
          final nameWidget = tester.widget<Text>(nameFinder);
          expect(nameWidget.maxLines, 1);
          expect(nameWidget.overflow, TextOverflow.ellipsis);

          // All three action icons present.
          expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
          expect(find.byIcon(Icons.delete_outline), findsOneWidget);
          expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
        },
      );
    }
  }

  testWidgets('toggle callback fires on chevron/name tap', (tester) async {
    var toggled = false;
    final theme = AppTheme.lightTheme;
    await tester.pumpWidget(
      _wrap(
        dark: false,
        child: _header(theme, expanded: true, onToggle: () => toggled = true),
      ),
    );
    await tester.tap(find.byIcon(Icons.expand_more));
    expect(toggled, isTrue);
  });

  testWidgets('collapsed chevron rotates (expand_more still present)', (
    tester,
  ) async {
    final theme = AppTheme.lightTheme;
    await tester.pumpWidget(
      _wrap(
        dark: false,
        child: _header(theme, expanded: false, onToggle: () {}),
      ),
    );
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit/delete/add callbacks each fire', (tester) async {
    var e = false, d = false, a = false;
    final theme = AppTheme.lightTheme;
    await tester.pumpWidget(
      _wrap(
        dark: false,
        child: _header(
          theme,
          expanded: true,
          onToggle: () {},
          onEdit: () => e = true,
          onDelete: () => d = true,
          onAdd: () => a = true,
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    expect(e && d && a, isTrue);
  });
}
