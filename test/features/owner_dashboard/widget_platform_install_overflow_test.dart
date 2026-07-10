// RED->GREEN gate for the WidgetPlatformInstallSection platform-tab row.
// On the ~300px unit-hub panel the 3 chips (HTML/WordPress/Wix) overflowed a
// plain Row by ~9px (device-caught, Samsung A52s). The row is now a horizontal
// SingleChildScrollView (same pattern as the Rezervacije filter tabs, #857).

import 'package:bookbed/features/owner_dashboard/presentation/widgets/widget_platform_install_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  for (final w in <double>[280, 301, 320, 390]) {
    testWidgets('platform tabs lay out without overflow @ ${w.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(w, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          child: SizedBox(
            width: w,
            child: const SingleChildScrollView(
              child: WidgetPlatformInstallSection(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }
}
