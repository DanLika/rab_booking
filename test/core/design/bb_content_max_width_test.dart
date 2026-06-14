import 'package:bookbed/core/design/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the content-clamp primitive used by the owner-screen
/// edge-to-edge fix (fix/content-maxwidth-clamp): below the cap the content
/// fills the viewport (phone/small tablet), at/above the cap it is clamped and
/// horizontally centered (tablet-landscape + desktop web — the band the
/// fixed-width goldens missed).
void main() {
  const childKey = ValueKey('clamped-child');

  Future<Size> pumpAt(
    WidgetTester tester,
    double width, {
    double maxWidth = 1100,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: BBContentMaxWidth(
          maxWidth: maxWidth,
          child: const SizedBox.expand(key: childKey),
        ),
      ),
    );
    return tester.getSize(find.byKey(childKey));
  }

  group('BBContentMaxWidth (owner content clamp)', () {
    testWidgets('768 tablet-portrait fills width (below 1100 cap)', (
      tester,
    ) async {
      expect((await pumpAt(tester, 768)).width, 768);
    });

    testWidgets('1024 tablet-landscape fills width (below 1100 cap)', (
      tester,
    ) async {
      expect((await pumpAt(tester, 1024)).width, 1024);
    });

    testWidgets('1440 desktop is clamped to the 1100 cap', (tester) async {
      expect((await pumpAt(tester, 1440)).width, 1100);
    });

    testWidgets('1440 desktop clamped content is centered, not edge-to-edge', (
      tester,
    ) async {
      await pumpAt(tester, 1440);
      final left = tester.getTopLeft(find.byKey(childKey)).dx;
      // (1440 - 1100) / 2 = 170px gutter on each side.
      expect(left, closeTo(170, 0.5));
    });

    testWidgets('1000 cap (ical/stripe forms) engages + centers at 1024', (
      tester,
    ) async {
      final size = await pumpAt(tester, 1024, maxWidth: 1000);
      expect(size.width, 1000);
      final left = tester.getTopLeft(find.byKey(childKey)).dx;
      expect(left, closeTo(12, 0.5)); // (1024 - 1000) / 2
    });
  });
}
