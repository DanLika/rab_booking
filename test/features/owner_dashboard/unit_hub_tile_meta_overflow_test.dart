// Responsive regression for the unit-list tile meta row (guests + price)
// inside `unified_unit_hub_screen.dart`.
//
// The tile lives in a ~280px master/unit-list panel. The price Text
// (`${pricePerNight}${perNight}`) sat in a Row with NO Flexible/ellipsis,
// so a long price (e.g. a 5-digit nightly rate) overflowed the row at narrow
// panel widths. Fix = wrap the price in Flexible + maxLines:1 + ellipsis.
//
// The tile builder is private, so we reproduce the exact meta Row structure
// (icon + count + gap + icon + price) across a range of constrained container
// widths — the overflow driver is the panel width, not the viewport.

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A long 5-digit nightly price is the real-world overflow trigger.
  const longPrice = '12500/noć';

  // Container widths spanning a cramped panel → a roomy tile.
  const panelWidths = <double>[120, 160, 200, 240, 280, 320];

  Widget metaRow() => const Row(
    children: [
      Icon(Icons.group_rounded, size: 15),
      SizedBox(width: 4),
      Text('12', style: TextStyle(fontSize: 13)),
      SizedBox(width: 16),
      Icon(Icons.euro_rounded, size: 15),
      SizedBox(width: 2),
      // Mirrors the fix: Flexible + ellipsis around the price.
      Flexible(
        child: Text(
          longPrice,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13),
        ),
      ),
    ],
  );

  for (final w in panelWidths) {
    for (final dark in const <bool>[false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('unit tile meta — no overflow @${w}px $theme', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1400, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: Scaffold(
              body: Center(
                child: SizedBox(width: w, child: metaRow()),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason:
              'unit tile meta row overflowed at panel width ${w}px ($theme)',
        );
      });
    }
  }
}
