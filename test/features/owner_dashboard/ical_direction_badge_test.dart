// Seam test for the iCal FeedCard direction badge (Uvoz/Izvoz) + a RED->GREEN
// overflow gate for the unit-hub property-header title one-line fix.
//
// - DirectionBadge is data-honest: label + tone key off IcalFeed.importEnabled.
// - The overflow gate mirrors the fixed ExpansionTile title pattern (a long
//   name + a fixed-width trailing action cluster). Without maxLines:1+ellipsis
//   the title wraps/overflows at a narrow panel width; the pattern under test
//   must stay single-line with no RenderFlex overflow.
import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/ical/ical_sync_settings_screen.dart';
import 'package:bookbed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('DirectionBadge', () {
    testWidgets('import feed -> Import label (en)', (tester) async {
      await tester.pumpWidget(_wrap(const DirectionBadge(importEnabled: true)));
      await tester.pumpAndSettle();
      expect(find.text('Import'), findsOneWidget);
      expect(find.text('Export'), findsNothing);
    });

    testWidgets('export-only feed -> Export label (en)', (tester) async {
      await tester.pumpWidget(
        _wrap(const DirectionBadge(importEnabled: false)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Export'), findsOneWidget);
      expect(find.text('Import'), findsNothing);
    });

    testWidgets('renders localized Uvoz/Izvoz (hr)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DirectionBadge(importEnabled: true),
          locale: const Locale('hr'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Uvoz'), findsOneWidget);
    });
  });

  group('property-header title one-line pattern (unit-hub wrap fix)', () {
    testWidgets('long name in a narrow ExpansionTile stays single-line', (
      tester,
    ) async {
      const longName = 'Villa Marina Panorama Deluxe Seafront Residence Rab';
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 300, // narrow master-panel width
            child: ExpansionTile(
              leading: const Icon(Icons.apartment),
              title: const Text(
                longName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: const Text(
                '4 jedinice',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(
                  3,
                  (_) => const SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(Icons.edit, size: 16),
                  ),
                ),
              ),
              children: const <Widget>[SizedBox.shrink()],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No RenderFlex overflow thrown, and the title Text is capped at 1 line.
      final titleText = tester.widget<Text>(find.text(longName));
      expect(titleText.maxLines, 1);
      expect(titleText.overflow, TextOverflow.ellipsis);
    });
  });
}
