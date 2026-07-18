// Audit sweep F4.3 + F4.4 — dead affordances wired.
//
// F4.3 (subscription): "Zadrži besplatno" had onPressed: () {} — now
// declines the upsell by leaving the screen. The link-styled "Usporedi
// sve značajke" TextSpan (no recognizer, no target surface) was removed.
//
// F4.4 (booking confirmation): the reference-pill copy button was a bare
// Material with no onTap — now wired to Clipboard with a 44px tap box
// (visual 28px pill unchanged). Resend row floored to 44px.

import 'dart:async';

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/subscription/screens/subscription_screen.dart';
import 'package:bookbed/features/widget/presentation/screens/booking_confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });
  testWidgets('F4.4: copy button writes the reference to the clipboard', (
    WidgetTester tester,
  ) async {
    final List<MethodCall> calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        calls.add(call);
        return null;
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: BookingConfirmationScreen(
            bookingReference: 'BB-2026-0042',
            guestEmail: 'gost@example.com',
            guestName: 'Iva Gost',
            checkIn: DateTime(2026, 8, 10),
            checkOut: DateTime(2026, 8, 14),
            totalPrice: 480,
            nights: 4,
            guests: 2,
            propertyName: 'Vila Test',
            paymentMethod: 'bank_transfer',
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));

    final Finder copy = find.descendant(
      of: find.bySemanticsLabel(RegExp('.*')),
      matching: find.byType(InkWell),
    );
    expect(copy, findsWidgets);

    // Locate the copy InkWell via the pill's reference text sibling.
    final Finder pillInk = find.descendant(
      of: find.ancestor(
        of: find.text('#BB-2026-0042'),
        matching: find.byType(Row),
      ),
      matching: find.byType(InkWell),
    );
    expect(pillInk, findsOneWidget);
    expect(tester.getSize(pillInk).height, greaterThanOrEqualTo(44));

    await tester.tap(pillInk, warnIfMissed: false);
    await tester.pump();

    final MethodCall setData = calls.firstWhere(
      (MethodCall c) => c.method == 'Clipboard.setData',
    );
    expect((setData.arguments as Map)['text'], 'BB-2026-0042');

    // Flush any lingering entrance-animation timers.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('F4.3: Zadrži besplatno leaves the subscription screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: Text('start'))),
      ),
    );
    final NavigatorState nav = tester.state(find.byType(Navigator));
    unawaited(
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(body: buildFreeInlineForTest()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder keepFree = find.text('Zadrži besplatno');
    expect(keepFree, findsOneWidget);
    await tester.tap(keepFree);
    await tester.pumpAndSettle();

    // The route was popped — declining the upsell leaves the screen.
    expect(find.text('start'), findsOneWidget);
    expect(keepFree, findsNothing);
  });

  testWidgets('F4.3: dead comparison link removed from foot-note', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: buildFootNoteForTest()),
      ),
    );
    expect(
      find.textContaining('Usporedi sve značajke', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('Sigurno plaćanje', findRichText: true),
      findsOneWidget,
    );
  });
}
