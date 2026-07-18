// Audit sweep F4.6 + F4.13 (+ F4.5 verified-closed) — shared widgets.
//
// F4.6: smart_tooltip force-cast `as EdgeInsets` threw a TypeError when an
// EdgeInsetsDirectional was passed. Container takes EdgeInsetsGeometry, and
// the geometry math now resolves instead of casting.
//
// F4.13: the Google "G" had no white disc, so the mark disappeared on dark
// surfaces (brand violation). Now CircleAvatar(backgroundColor: white).
//
// F4.5 note: LogoutTile itself has no confirm, but its ONLY live caller
// (profile_screen:484) already wraps onLogout in a BbDialog confirm with a
// `confirmed != true` guard — verified closed, no change.

import 'package:bookbed/shared/widgets/smart_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookbed/features/auth/presentation/widgets/social_login_button.dart';

void main() {
  testWidgets('F4.6: directional insets no longer throw', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SmartTooltip(
              message: 'Pomoć',
              padding: EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
              margin: EdgeInsetsDirectional.all(6),
              child: Icon(Icons.info_outline),
            ),
          ),
        ),
      ),
    );
    // Long-press shows the tooltip — this is where the old cast threw.
    await tester.longPress(find.byType(Icon));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Pomoć'), findsOneWidget);
    // Let the auto-dismiss timer drain.
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('F4.13: Google G sits on a white disc', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF1E1E1E),
          body: Center(child: GoogleBrandIcon()),
        ),
      ),
    );
    await tester.pump();
    final CircleAvatar disc = tester.widget<CircleAvatar>(
      find.byType(CircleAvatar),
    );
    expect(disc.backgroundColor, Colors.white);
  });
}
