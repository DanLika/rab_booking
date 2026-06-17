import 'package:bookbed/core/design/bb_redesign_tokens.dart';
import 'package:bookbed/core/design/tokens.dart';
import 'package:bookbed/shared/widgets/redesign/bb_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scaffold(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

Widget _scaffoldWithTheme(ThemeData theme, Widget child) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

Color _bbCardInnerColor(WidgetTester tester) {
  final Container card = tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(BbCard),
          matching: find.byType(Container),
        ),
      )
      .firstWhere(
        (Container c) => c.padding == const EdgeInsets.all(20),
        orElse: () => throw StateError('Padded BbCard container not found'),
      );
  final BoxDecoration deco = card.decoration! as BoxDecoration;
  return deco.color!;
}

void main() {
  group('BbCard (Phase 1.5a)', () {
    testWidgets('renders child', (WidgetTester tester) async {
      await tester.pumpWidget(_scaffold(const BbCard(child: Text('hello'))));
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('padded=true default applies 20px EdgeInsets to inner', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_scaffold(const BbCard(child: Text('padded'))));
      // Default padded → EdgeInsets.all(20). Find any Container under BbCard
      // whose padding equals that.
      final Iterable<Container> containers = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(BbCard),
              matching: find.byType(Container),
            ),
          )
          .where((Container c) => c.padding == const EdgeInsets.all(20));
      expect(
        containers,
        isNotEmpty,
        reason: 'default padded BbCard should wrap child in 20px padding',
      );
    });

    testWidgets('padded=false drops inner padding to zero', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(const BbCard(padded: false, child: Text('flush'))),
      );
      final Iterable<Container> containers = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(BbCard),
              matching: find.byType(Container),
            ),
          )
          .where((Container c) => c.padding == EdgeInsets.zero);
      expect(containers, isNotEmpty);
    });

    testWidgets('hoverable card always renders AnimatedContainer (lift host)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          BbCard(hoverable: true, onTap: () {}, child: const Text('hover')),
        ),
      );
      // AnimatedContainer is the lift host; present regardless of platform.
      expect(
        find.descendant(
          of: find.byType(BbCard),
          matching: find.byType(AnimatedContainer),
        ),
        findsOneWidget,
      );
    });

    testWidgets('interactive card wires InkWell.onTap + MouseRegion', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _scaffold(
          BbCard(
            hoverable: true,
            onTap: () => taps++,
            child: const Text('tap'),
          ),
        ),
      );
      await tester.tap(find.byType(BbCard));
      await tester.pump();
      expect(taps, 1);
      expect(
        find.descendant(
          of: find.byType(BbCard),
          matching: find.byType(MouseRegion),
        ),
        findsWidgets,
      );
    });

    testWidgets('non-interactive card omits InkWell/MouseRegion wrap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_scaffold(const BbCard(child: Text('static'))));
      // Source path: `if (!_isInteractive) return lifted;` — no MouseRegion
      // added on top of the inner content when onTap is null.
      expect(
        find.descendant(
          of: find.byType(BbCard),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    testWidgets('accentLeft variant wraps inner in a Stack (accent bar)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffold(
          const BbCard(
            variant: BbCardVariant.accentLeft,
            child: Text('accent'),
          ),
        ),
      );
      // The accent-left branch composes Stack( inner, Positioned(accent bar) ).
      expect(
        find.descendant(of: find.byType(BbCard), matching: find.byType(Stack)),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: find.byType(BbCard),
          matching: find.byType(Positioned),
        ),
        findsOneWidget,
      );
    });
  });

  group('BbCard surface resolution (admin/owner discrimination)', () {
    testWidgets('owner dark context (no BbAdminDarkTokens extension) renders '
        'BBColor.dark.surface (#1E1E1E — widened audit/127 dark-depth, cards '
        'lift above the #141414 panel)', (WidgetTester tester) async {
      await tester.pumpWidget(
        _scaffoldWithTheme(
          ThemeData.dark(useMaterial3: true),
          const BbCard(child: Text('owner-dark')),
        ),
      );
      expect(_bbCardInnerColor(tester), BBColor.surfaceDark);
      expect(_bbCardInnerColor(tester), const Color(0xFF1E1E1E));
    });

    testWidgets(
      'owner light context (no BbAdminDarkTokens extension) renders '
      'BBColor.light.surface (#FFFFFF) — extension absence keeps owner path',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _scaffoldWithTheme(
            ThemeData.light(useMaterial3: true),
            const BbCard(child: Text('owner-light')),
          ),
        );
        expect(_bbCardInnerColor(tester), BBColor.surfaceLight);
      },
    );

    testWidgets('admin context (BbAdminDarkTokens extension wired) renders '
        'BbAdminDarkTokens.preset.panelBg (#2A2342)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaffoldWithTheme(
          ThemeData.dark(useMaterial3: true).copyWith(
            extensions: const <ThemeExtension<dynamic>>[
              BbAdminDarkTokens.preset,
            ],
          ),
          const BbCard(child: Text('admin-dark')),
        ),
      );
      expect(_bbCardInnerColor(tester), BbAdminDarkTokens.preset.panelBg);
      expect(_bbCardInnerColor(tester), const Color(0xFF2A2342));
    });
  });
}
