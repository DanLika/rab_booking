import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookbed/core/design_tokens/design_tokens.dart';
import 'package:bookbed/features/widget/presentation/providers/language_provider.dart';
import 'package:bookbed/features/widget/presentation/widgets/calendar/calendar_combined_header_widget.dart';

/// Seam test for the guest-widget language control cosmetic restyle
/// (design/widget-language-icon-restyle): the trigger renders a globe
/// (Icons.language) + uppercase 2-letter code chip — NOT a flag emoji —
/// while keeping the PopupMenu behaviour, 4 language options, current-selection
/// check, and languageProvider wiring untouched.
Widget _harness({required String lang}) {
  return ProviderScope(
    overrides: [languageProvider.overrideWith((ref) => lang)],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: buildWidgetLanguageSwitcherForTest(colors: ColorTokens.light),
        ),
      ),
    ),
  );
}

const _flags = ['🇭🇷', '🇬🇧', '🇩🇪', '🇮🇹', '🌐'];

void main() {
  group('widget language switcher — globe icon + code chip trigger', () {
    testWidgets('renders globe icon and uppercase code, no flag on trigger', (
      tester,
    ) async {
      for (final entry in {
        'hr': 'HR',
        'en': 'EN',
        'de': 'DE',
        'it': 'IT',
      }.entries) {
        // Fresh tree per language so the new ProviderScope override takes
        // (a reused same-type scope caches the StateProvider state).
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(_harness(lang: entry.key));
        await tester.pumpAndSettle();

        // Globe icon present on trigger.
        expect(find.byIcon(Icons.language), findsOneWidget);
        // Dropdown affordance kept.
        expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
        // Uppercase 2-letter code shown for the current language.
        expect(find.text(entry.value), findsOneWidget);

        // No flag emoji anywhere on the collapsed trigger.
        for (final flag in _flags) {
          expect(
            find.textContaining(flag),
            findsNothing,
            reason: 'trigger must not show flag $flag for ${entry.key}',
          );
        }
      }
    });

    testWidgets('popup still lists all 4 languages with current selected', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(lang: 'en'));
      await tester.pumpAndSettle();

      // Open the popup.
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // All 4 language names present.
      for (final name in ['Hrvatski', 'English', 'Deutsch', 'Italiano']) {
        expect(find.text(name), findsOneWidget);
      }

      // Current selection (EN) shows the check icon in the menu.
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
