// Guards the popup-blocked dialog against overflowing a phone screen.
//
// This dialog is what a guest sees when the browser blocks the Stripe checkout
// popup — routine on mobile Safari — so it is a mobile-first surface. Its content
// used to be a hard `SizedBox(width: 400)`, but an AlertDialog only gets the
// viewport minus its inset padding (40dp a side): at 390px that leaves ~310px,
// so the content overflowed horizontally on exactly the devices that hit this
// path most.
//
// The dialog is pumped through `showDialog` so it receives real dialog
// constraints — rendering it straight into a Scaffold body would only prove
// something about an unconstrained layout, not about what the guest sees.

import 'package:bookbed/features/widget/presentation/widgets/popup_blocked_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _showDialogAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PopupBlockedDialog(
                  checkoutUrl: 'https://checkout.stripe.com/c/pay/cs_test_123',
                  onRetry: () {},
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('PopupBlockedDialog — fits the viewport', () {
    for (final device in const <({String name, Size size})>[
      (name: 'narrowest phone', size: Size(320, 720)),
      (name: 'common phone', size: Size(390, 844)),
      (name: 'large phone', size: Size(430, 932)),
      (name: 'tablet', size: Size(768, 1024)),
      (name: 'desktop', size: Size(1440, 900)),
    ]) {
      final w = device.size.width.toInt();
      testWidgets('lays out clean @ ${w}px (${device.name})', (tester) async {
        await _showDialogAt(tester, device.size);

        expect(find.byType(PopupBlockedDialog), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason:
              'dialog overflowed at ${w}px — its content width must be clamped '
              'to the viewport minus the dialog inset',
        );
      });
    }

    testWidgets('content box never exceeds the phone width', (tester) async {
      const width = 390.0;
      await _showDialogAt(tester, const Size(width, 844));

      final box = tester.getSize(
        find
            .descendant(
              of: find.byType(PopupBlockedDialog),
              matching: find.byType(SizedBox),
            )
            .first,
      );

      expect(
        box.width,
        lessThanOrEqualTo(width),
        reason: 'content box is wider than the phone it renders on',
      );
    });
  });
}
