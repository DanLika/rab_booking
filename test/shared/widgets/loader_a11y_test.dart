import 'package:bookbed/features/owner_dashboard/presentation/widgets/bookings/premium_loading_indicator.dart';
import 'package:bookbed/shared/widgets/universal_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audit sweep F2.11 — loader family a11y barrier.
void main() {
  testWidgets('UniversalLoader announces one live-region node', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: UniversalLoader(debounceDuration: Duration.zero)),
      ),
    );
    await tester.pump();
    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel('Učitavanje'),
    );
    expect(node.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
    // flutter_animate delay timers outlive disposal — advance the fake
    // clock so the binding's timersPending invariant passes.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('UniversalLoader message folds into the label', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UniversalLoader(
            message: 'Prijava u toku',
            debounceDuration: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Prijava u toku'), findsOneWidget);
    handle.dispose();
    // flutter_animate delay timers outlive disposal — advance the fake
    // clock so the binding's timersPending invariant passes.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('PremiumLoadingIndicator is one labeled node (dots merged)', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PremiumLoadingIndicator())),
    );
    await tester.pump();
    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel('Učitavanje…'),
    );
    expect(node.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
    // flutter_animate delay timers outlive disposal — advance the fake
    // clock so the binding's timersPending invariant passes.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('PremiumLoadingIndicator honors reduced motion (static dots)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: Scaffold(body: PremiumLoadingIndicator())),
      ),
    );
    await tester.pump();
    // No Animate wrappers in the tree when reduced.
    expect(find.byType(PremiumLoadingIndicator), findsOneWidget);
    await tester.pump(
      const Duration(seconds: 2),
    ); // would throw on pending timers if animating
  });
}
