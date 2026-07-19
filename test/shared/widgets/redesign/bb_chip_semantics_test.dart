import 'package:bookbed/shared/widgets/redesign/bb_chip.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audit sweep F2.3 — BbChip semantics + tap-target floor.
///
/// The raw chip announced NOTHING (A11y 0/4 ROOT — every filter/tab row
/// inherited the hole). Each assertion here fails on the pre-F2.3 widget.
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[child],
      ),
    ),
  );

  testWidgets('announces button role + label + selected state', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(BbChip(label: 'Potvrđeno', selected: true, onTap: () {})),
    );
    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel('Potvrđeno'),
    );
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    handle.dispose();
  });

  testWidgets('unselected chip announces selected=false', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(host(BbChip(label: 'Sve', onTap: () {})));
    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel('Sve'),
    );
    expect(node.flagsCollection.isSelected, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('count is folded into the semantic label', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(BbChip(label: 'Na čekanju', count: 5, onTap: () {})),
    );
    expect(find.bySemanticsLabel('Na čekanju, 5'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('tap box is >=44 tall for sm and md', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(BbChip(label: 'Mali', size: BbChipSize.sm, onTap: () {})),
    );
    expect(
      tester.getSize(find.byType(BbChip)).height,
      greaterThanOrEqualTo(44),
    );

    await tester.pumpWidget(host(BbChip(label: 'Srednji', onTap: () {})));
    expect(
      tester.getSize(find.byType(BbChip)).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('tap on the slack area outside the visual pill fires', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      host(BbChip(label: 'Mali', size: BbChipSize.sm, onTap: () => taps++)),
    );
    final Rect box = tester.getRect(find.byType(BbChip));
    // sm pill = 32px centered in 44px box → 6px slack top/bottom.
    await tester.tapAt(Offset(box.center.dx, box.top + 2));
    expect(taps, 1);
  });

  testWidgets('visual pill height is unchanged (32 sm / 40 md)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(BbChip(label: 'Mali', size: BbChipSize.sm, onTap: () {})),
    );
    // The pill is the first Container descendant of the chip.
    final Size sm = tester.getSize(
      find
          .descendant(of: find.byType(BbChip), matching: find.byType(Container))
          .first,
    );
    expect(sm.height, 32);

    await tester.pumpWidget(host(BbChip(label: 'Srednji', onTap: () {})));
    final Size md = tester.getSize(
      find
          .descendant(of: find.byType(BbChip), matching: find.byType(Container))
          .first,
    );
    expect(md.height, 40);
  });
}
