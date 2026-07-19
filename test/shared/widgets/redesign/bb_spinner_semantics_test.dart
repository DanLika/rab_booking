import 'package:bookbed/shared/widgets/redesign/bb_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audit sweep F2.8 — BbSpinner decorative-by-default semantics.
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('default spinner is excluded from the semantics tree', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const BbSpinner()));
    expect(
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
    handle.dispose();
  });

  testWidgets('semanticsLabel announces as a live region', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const BbSpinner(semanticsLabel: 'Učitavanje')),
    );
    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel('Učitavanje'),
    );
    expect(node.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });
}
