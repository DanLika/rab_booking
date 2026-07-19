// Audit sweep F4.10 + F4.11 — dialog/card interaction wiring.
//
// F4.10: TaxLegalDisclaimerCard used one-shot `initiallyExpanded`, so the
// tile stayed open after the owner disabled the master toggle. Now driven
// by an ExpansibleController from didUpdateWidget.
//
// F4.11: bookings filters — Clear applied the reset but left the dialog
// open (Apply closes → inconsistent, reads as a no-op). Clear-date
// IconButton had BoxConstraints() = 18px tap target; restored 48px floor.

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/owner_dashboard/presentation/providers/owner_calendar_provider.dart';
import 'package:bookbed/features/owner_dashboard/presentation/widgets/advanced_settings/tax_legal_disclaimer_card.dart';
import 'package:bookbed/features/owner_dashboard/presentation/widgets/bookings/bookings_filters_dialog.dart';
import 'package:bookbed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _l10nApp(Widget home) {
  return MaterialApp(
    locale: const Locale('en'),
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

class _TaxCardHost extends StatefulWidget {
  const _TaxCardHost();
  @override
  State<_TaxCardHost> createState() => _TaxCardHostState();
}

class _TaxCardHostState extends State<_TaxCardHost> {
  bool enabled = true;
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: TaxLegalDisclaimerCard(
          taxLegalEnabled: enabled,
          useDefaultText: true,
          customDisclaimerController: controller,
          onEnabledChanged: (v) => setState(() => enabled = v),
          onUseDefaultChanged: (_) {},
          onPreview: () {},
        ),
      ),
    );
  }
}

void main() {
  testWidgets('F4.10: tile collapses when the master toggle turns off', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_l10nApp(const _TaxCardHost()));
    await tester.pumpAndSettle();
    // Enabled → expanded: the radio options are visible.
    expect(find.byType(RadioListTile<bool>), findsWidgets);

    final Finder toggle = find.byType(Switch, skipOffstage: false);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    // Disabled → the controller collapses the tile.
    expect(find.byType(RadioListTile<bool>), findsNothing);

    // No lock-out: the header still expands manually, exposing the (off)
    // switch so the owner can re-enable.
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    expect(toggle, findsOneWidget);
    expect(tester.widget<Switch>(toggle).value, isFalse);
  });

  testWidgets('F4.11: Clear closes the filters dialog like Apply does', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownerPropertiesCalendarProvider.overrideWith((ref) async => []),
        ],
        child: _l10nApp(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const BookingsFiltersDialog(),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(BookingsFiltersDialog), findsOneWidget);

    await tester.tap(find.text('Clear filters', skipOffstage: false));
    await tester.pumpAndSettle();
    expect(find.byType(BookingsFiltersDialog), findsNothing);
  });
}
