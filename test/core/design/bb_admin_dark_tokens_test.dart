import 'package:bookbed/core/design/bb_redesign_tokens.dart';
import 'package:bookbed/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BbAdminDarkTokens (Phase 1.7)', () {
    test('preset carries handoff-verbatim shellBg #1E1A33', () {
      expect(BbAdminDarkTokens.preset.shellBg, const Color(0xFF1E1A33));
    });

    test('preset on-dark contrast tokens', () {
      const BbAdminDarkTokens p = BbAdminDarkTokens.preset;
      expect(p.textPrimary, const Color(0xFFFFFFFF));
      expect(p.textSecondary, const Color(0xB8FFFFFF));
      expect(p.textTertiary, const Color(0x80FFFFFF));
      expect(p.divider, const Color(0x14FFFFFF));
      expect(p.adminBadgeFg, const Color(0xFFC9BBFF));
    });

    test('preset nav active glow is non-empty purple', () {
      expect(BbAdminDarkTokens.preset.navActiveGlow, hasLength(greaterThan(0)));
      expect(
        BbAdminDarkTokens.preset.navActiveGlow.first.color,
        const Color(0x668B6FFF),
      );
    });

    testWidgets('of(context) falls back to preset when not wired into theme', (
      WidgetTester tester,
    ) async {
      late BbAdminDarkTokens resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (BuildContext ctx) {
              resolved = BbAdminDarkTokens.of(ctx);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(identical(resolved, BbAdminDarkTokens.preset), isTrue);
    });

    testWidgets(
      'of(context) returns wired instance when admin shell registers one',
      (WidgetTester tester) async {
        const BbAdminDarkTokens override = BbAdminDarkTokens(
          shellBg: Color(0xFF111111),
          panelBg: Color(0xFF222222),
          divider: Color(0x14FFFFFF),
          textPrimary: Color(0xFFFFFFFF),
          textSecondary: Color(0xB8FFFFFF),
          textTertiary: Color(0x66FFFFFF),
          navTileIdleBg: Color(0x0FFFFFFF),
          navTileActiveBg: Color(0x14FFFFFF),
          navTileActiveBorder: Color(0x1AFFFFFF),
          navIconActiveGradient: LinearGradient(
            colors: <Color>[Color(0xFF6B4CE6), Color(0xFF8B6FFF)],
          ),
          navActiveGlow: <BoxShadow>[
            BoxShadow(color: Color(0x668B6FFF), blurRadius: 12),
          ],
          adminBadgeBg: Color(0x478B6FFF),
          adminBadgeFg: Color(0xFFC9BBFF),
          profileSecondaryText: Color(0x80FFFFFF),
        );

        late BbAdminDarkTokens resolved;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(
              extensions: const <ThemeExtension<dynamic>>[override],
            ),
            home: Builder(
              builder: (BuildContext ctx) {
                resolved = BbAdminDarkTokens.of(ctx);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(resolved.shellBg, const Color(0xFF111111));
      },
    );

    test('copyWith overrides only the given field', () {
      final BbAdminDarkTokens patched = BbAdminDarkTokens.preset.copyWith(
        shellBg: const Color(0xFF010203),
      );
      expect(patched.shellBg, const Color(0xFF010203));
      // Other fields unchanged.
      expect(patched.panelBg, BbAdminDarkTokens.preset.panelBg);
      expect(patched.textPrimary, BbAdminDarkTokens.preset.textPrimary);
      expect(patched.navActiveGlow, BbAdminDarkTokens.preset.navActiveGlow);
    });

    test('lerp at t=0 returns this; t=1 returns other; mid does not throw', () {
      const BbAdminDarkTokens a = BbAdminDarkTokens.preset;
      final BbAdminDarkTokens b = a.copyWith(shellBg: const Color(0xFF000000));
      final BbAdminDarkTokens at0 = a.lerp(b, 0.0);
      final BbAdminDarkTokens at1 = a.lerp(b, 1.0);
      expect(at0.shellBg, const Color(0xFF1E1A33));
      expect(at1.shellBg, const Color(0xFF000000));
      // Mid-lerp must return a finite color (no null deref).
      final BbAdminDarkTokens mid = a.lerp(b, 0.5);
      expect(mid.shellBg, isNotNull);
      expect(mid.navActiveGlow, hasLength(greaterThan(0)));
    });

    test('lerp against non-BbAdminDarkTokens returns this unchanged', () {
      const BbAdminDarkTokens a = BbAdminDarkTokens.preset;
      // ignore: avoid_redundant_argument_values
      final BbAdminDarkTokens result = a.lerp(null, 0.5);
      expect(identical(result, a), isTrue);
    });

    testWidgets(
      'AppTheme.darkTheme (owner) does NOT register BbAdminDarkTokens — '
      'isolation guard',
      (WidgetTester tester) async {
        late ThemeData captured;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Builder(
              builder: (BuildContext ctx) {
                captured = Theme.of(ctx);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(
          captured.extension<BbAdminDarkTokens>(),
          isNull,
          reason:
              'Phase 1.7 must not wire adminDark into owner darkTheme — '
              'admin shell consumes BbAdminDarkTokens.preset directly.',
        );
        // BbRedesignTokens.dark (owner dark) must still be present.
        expect(captured.extension<BbRedesignTokens>(), isNotNull);
      },
    );

    testWidgets(
      'AppTheme.lightTheme (owner) does NOT register BbAdminDarkTokens — '
      'isolation guard',
      (WidgetTester tester) async {
        late ThemeData captured;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (BuildContext ctx) {
                captured = Theme.of(ctx);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(
          captured.extension<BbAdminDarkTokens>(),
          isNull,
          reason:
              'Phase 1.7 must not wire adminDark into owner lightTheme — '
              'would recolor every migrated owner screen.',
        );
        // BbRedesignTokens.light (owner light) must still be present.
        expect(captured.extension<BbRedesignTokens>(), isNotNull);
      },
    );
  });
}
