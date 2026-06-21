import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/l10n/widget_translations.dart';
import 'package:bookbed/features/widget/presentation/providers/language_provider.dart';
import 'package:bookbed/features/widget/presentation/widgets/popup_blocked_dialog.dart';

/// l10n coverage for [PopupBlockedDialog] — the dialog a guest sees mid-checkout
/// when the browser blocks the Stripe payment popup. Proves every user-visible
/// literal resolves through [WidgetTranslations] (System B) in all four
/// supported languages (HR/EN/DE/IT), and that no English literal leaks into a
/// non-English locale.
///
/// The dialog is not yet wired into the live checkout flow (booking_widget_screen
/// is FROZEN; wiring lands on a separate branch), so we pump the widget directly.
void main() {
  // Generous surface so the dialog's content column never vertically overflows
  // the default 800x600 test viewport (the DE body wraps to several lines).
  void useLargeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget harness(String lang) {
    return ProviderScope(
      overrides: [languageProvider.overrideWith((ref) => lang)],
      child: MaterialApp(
        home: Scaffold(
          body: PopupBlockedDialog(
            checkoutUrl: 'https://checkout.stripe.com/c/pay/test_session',
            onRetry: () {},
          ),
        ),
      ),
    );
  }

  group('renders localized strings', () {
    for (final lang in WidgetTranslations.supportedLanguages) {
      testWidgets('all visible strings resolve for "$lang"', (tester) async {
        useLargeSurface(tester);
        await tester.pumpWidget(harness(lang));
        final tr = WidgetTranslations.forLanguage(lang);

        expect(find.text(tr.popupBlockedTitle), findsOneWidget);
        expect(find.text(tr.popupBlockedBody), findsOneWidget);
        expect(find.text(tr.popupOpenPayment), findsOneWidget);
        expect(find.text(tr.popupOpenPaymentDesc), findsOneWidget);
        expect(find.text(tr.popupCopyLink), findsOneWidget);
        expect(find.text(tr.popupCopyLinkDesc), findsOneWidget);
        // onRetry != null → the "Try Again" option renders.
        expect(find.text(tr.popupTryAgain), findsOneWidget);
        expect(find.text(tr.popupTryAgainDesc), findsOneWidget);
        expect(find.text(tr.popupCancel), findsOneWidget);
      });
    }
  });

  group('no English literal leaks into non-English locales', () {
    const englishLiterals = <String>[
      'Popup Blocked',
      'Open Payment Page',
      'Opens Stripe Checkout in a new tab',
      'Copy Payment Link',
      'Copy link to share or open manually',
      'Try Again',
      'Allow popups and try opening again',
      'Cancel',
    ];

    for (final lang in <String>['hr', 'de', 'it']) {
      testWidgets('"$lang" shows no English literal', (tester) async {
        useLargeSurface(tester);
        await tester.pumpWidget(harness(lang));
        for (final literal in englishLiterals) {
          expect(
            find.text(literal),
            findsNothing,
            reason: 'English literal "$literal" leaked into "$lang"',
          );
        }
      });
    }
  });

  group('WidgetTranslations popup keys are complete', () {
    final accessors = <String, String Function(WidgetTranslations)>{
      'popupBlockedTitle': (t) => t.popupBlockedTitle,
      'popupBlockedBody': (t) => t.popupBlockedBody,
      'popupOpenPayment': (t) => t.popupOpenPayment,
      'popupOpenPaymentDesc': (t) => t.popupOpenPaymentDesc,
      'popupCopyLink': (t) => t.popupCopyLink,
      'popupCopyLinkDesc': (t) => t.popupCopyLinkDesc,
      'popupTryAgain': (t) => t.popupTryAgain,
      'popupTryAgainDesc': (t) => t.popupTryAgainDesc,
      'popupCancel': (t) => t.popupCancel,
      'popupLinkCopied': (t) => t.popupLinkCopied,
      'popupCopyFailed': (t) => t.popupCopyFailed,
    };

    test('every key is non-empty in all 4 languages', () {
      for (final lang in WidgetTranslations.supportedLanguages) {
        final tr = WidgetTranslations.forLanguage(lang);
        accessors.forEach((name, accessor) {
          expect(
            accessor(tr).trim(),
            isNotEmpty,
            reason: 'Key "$name" is empty for "$lang"',
          );
        });
      }
    });

    // The two snackbar strings can't be reached by the render test without
    // interaction; assert here they are genuinely translated (not EN fallback),
    // alongside the title as a high-signal sentinel.
    test('HR/DE/IT differ from EN for title + snackbar keys', () {
      final en = WidgetTranslations.forLanguage('en');
      final sentinels = <String Function(WidgetTranslations)>[
        (t) => t.popupBlockedTitle,
        (t) => t.popupLinkCopied,
        (t) => t.popupCopyFailed,
      ];
      for (final lang in <String>['hr', 'de', 'it']) {
        final tr = WidgetTranslations.forLanguage(lang);
        for (final accessor in sentinels) {
          expect(
            accessor(tr),
            isNot(equals(accessor(en))),
            reason: '"$lang" value matches EN (untranslated)',
          );
        }
      }
    });
  });
}
