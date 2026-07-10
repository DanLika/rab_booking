// Responsive regression for the iCal feed-row title Row inside
// `ical_sync_settings_screen.dart`.
//
// The title Row packs: Flexible(platform name) + DirectionBadge + status dot +
// status label. The name was Flexible but the trailing status label was NOT,
// so at very narrow widths (a long-named platform + long status label) the row
// could overflow. Fix = wrap the status label in Flexible + ellipsis too.
//
// The row is built inline in a private ListTile title, so we reproduce its
// structure (Flexible name + fixed badge + dot + Flexible label) across a range
// of constrained widths.

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const longName = 'Booking.com Extranet Sinkronizacija (Vila Marina)';
  const longStatus = 'Privremeno pauzirano';

  const rowWidths = <double>[120, 160, 200, 240, 280, 320, 360];

  Widget titleRow() => Row(
    children: [
      const Flexible(
        child: Text(
          longName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        color: Colors.grey,
        child: const Text('Uvoz'),
      ),
      const SizedBox(width: 8),
      Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      const Flexible(
        child: Text(longStatus, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );

  for (final w in rowWidths) {
    testWidgets('ical feed-row title — no overflow @${w}px', (tester) async {
      tester.view.physicalSize = const Size(1400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(width: w, child: titleRow()),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'ical feed-row title overflowed at width ${w}px',
      );
    });
  }
}
