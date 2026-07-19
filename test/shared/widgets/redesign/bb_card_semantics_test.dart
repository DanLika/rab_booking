import 'package:bookbed/shared/widgets/redesign/bb_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audit sweep F2.6 — BbCard semantics API (double-read ROOT).
void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets(
    'excludeSemantics collapses a mirrored child label into ONE node',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          BbCard(
            semanticLabel: 'Notifikacije',
            excludeSemantics: true,
            onTap: () {},
            child: const Text('Notifikacije'), // mirrors the label
          ),
        ),
      );
      // Pre-F2.6 this produced two stops ("Notifikacije" twice).
      expect(find.bySemanticsLabel('Notifikacije'), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets('default keeps previous behavior (child still traversed)', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        BbCard(
          semanticLabel: 'Kartica',
          onTap: () {},
          child: const Text('Sadržaj'),
        ),
      ),
    );
    // Merged node carries BOTH strings ("Kartica\nSadržaj") — this IS the
    // double-read the excludeSemantics param exists to fix; the default
    // must keep it for backward compat.
    final String label = tester.getSemantics(find.byType(BbCard)).label;
    expect(label, contains('Kartica'));
    expect(label, contains('Sadržaj'));
    handle.dispose();
  });

  testWidgets('non-interactive card with a label announces as container', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const BbCard(semanticLabel: 'Sažetak rezervacije', child: Text('...')),
      ),
    );
    expect(
      tester.getSemantics(find.byType(BbCard)).label,
      contains('Sažetak rezervacije'),
    );
    handle.dispose();
  });

  testWidgets('tap still fires with excludeSemantics', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      host(
        BbCard(
          semanticLabel: 'Otvori',
          excludeSemantics: true,
          onTap: () => taps++,
          child: const Text('Otvori'),
        ),
      ),
    );
    await tester.tap(find.byType(BbCard));
    expect(taps, 1);
  });
}
