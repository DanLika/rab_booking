import 'package:bookbed/shared/widgets/redesign/bb_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scaffold(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

void main() {
  group('BbSkeleton (Phase 1.5a)', () {
    testWidgets('default path renders animated shimmer (AnimatedBuilder)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(const BbSkeleton(width: 120, height: 14)),
      );
      // Non-reduced motion: build() emits AnimatedBuilder bound to the
      // 1400ms controller for the shimmer sweep.
      expect(
        find.descendant(
          of: find.byType(BbSkeleton),
          matching: find.byType(AnimatedBuilder),
        ),
        findsOneWidget,
      );
      // Pump once more to allow shimmer tick — must not throw.
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets(
      'reduced-motion path renders static box (no AnimatedBuilder, no shimmer)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _scaffold(
            const BbSkeleton(width: 120, height: 14),
            reduceMotion: true,
          ),
        );
        // BBMotion.reduced(context) == true → early-return Container, no
        // AnimatedBuilder/gradient ticking.
        expect(
          find.descendant(
            of: find.byType(BbSkeleton),
            matching: find.byType(AnimatedBuilder),
          ),
          findsNothing,
          reason:
              'reduced-motion BbSkeleton must NOT mount an AnimatedBuilder '
              '(static box only — see lib/core/design/tokens.dart BBMotion.reduced)',
        );
        // Static Container should still render at requested size.
        expect(find.byType(BbSkeleton), findsOneWidget);
      },
    );

    testWidgets('honors width/height props on static branch', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          const BbSkeleton(width: 80, height: 24, radius: 4),
          reduceMotion: true,
        ),
      );
      final RenderBox box =
          tester.renderObject(find.byType(BbSkeleton)) as RenderBox;
      expect(box.size.width, 80);
      expect(box.size.height, 24);
    });

    testWidgets('null width takes available space (loose constraints)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(const SizedBox(width: 200, child: BbSkeleton(height: 12))),
      );
      // Should pump without throwing under default (animated) branch.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(BbSkeleton), findsOneWidget);
    });
  });
}
