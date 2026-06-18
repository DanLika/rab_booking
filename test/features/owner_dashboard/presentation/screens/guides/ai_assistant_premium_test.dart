// Responsive + fidelity render harness for the owner AI Assistant premium
// surfaces. Pumps the REAL presentation widgets the live screen renders —
// [buildAiMessageBubble] (user solid + initials avatar, assistant markdown), [AiConversationHeader]
// (brand avatar + title + status + copy/delete), and [AiBrandAvatar] — across
// the full breakpoint range in light + dark, with long-text fixtures that
// stress wrap + ellipsis.
//
//  * Primary assertion: NO overflow at any size (`tester.takeException`).
//  * Chrome: the conversation header shows its title + both action glyphs.
//  * Robustness: [AiBrandAvatar] renders its asset-fail fallback glyph without
//    throwing (assets don't load in the test bundle) — guards the offline path.
//
// Hermetic: these widgets read no providers + no l10n (strings are passed in),
// so no ProviderScope / fonts are needed — the overflow assertion is the gate.

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/owner_dashboard/domain/models/ai_chat.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/guides/ai_assistant_screen.dart';
import 'package:bookbed/features/owner_dashboard/presentation/widgets/guides/ai_assistant_premium_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _noop() {}

const String _longTitle =
    'Kako blokirati datume za održavanje tijekom dugog ljetnog razdoblja — '
    'vrlo dugačak naslov razgovora koji mora elidirati u jednu liniju.';

const String _longBody =
    'Da biste blokirali datume za održavanje, otvorite Mjesečni kalendar, '
    'odaberite raspon dana i označite ih kao nedostupne. '
    'Supercalifragilisticexpialidocious-vrlo-dugacka-rijec-bez-razmaka-za-prelom.';

List<AiChatMessage> _fixture() => <AiChatMessage>[
  AiChatMessage(
    role: 'user',
    content: 'Kako blokirati datume? $_longBody',
    timestamp: DateTime(2026, 6, 16, 10, 42),
  ),
  AiChatMessage(
    role: 'assistant',
    content:
        '**Kratko:** otvorite kalendar.\n\n$_longBody\n\n'
        '- prva stavka popisa\n- druga stavka popisa\n\n'
        '`code-token-vrlo-dugacak-bez-razmaka-koji-testira-prelom`',
    timestamp: DateTime(2026, 6, 16, 10, 43),
  ),
];

const _breakpoints = <({String name, double w, double h})>[
  (name: 'phone', w: 360, h: 740),
  (name: 'phone_large', w: 414, h: 896),
  (name: 'tablet', w: 768, h: 1024),
  (name: 'desktop_1280', w: 1280, h: 900),
  (name: 'desktop_1440', w: 1440, h: 900),
  (name: 'uhd_2560', w: 2560, h: 1440),
];

void main() {
  for (final bp in _breakpoints) {
    for (final dark in const [false, true]) {
      final theme = dark ? 'dark' : 'light';
      testWidgets('AI chat — ${bp.name} $theme — no overflow', (tester) async {
        tester.view.physicalSize = Size(bp.w, bp.h);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: <Widget>[
                    const AiConversationHeader(
                      title: _longTitle,
                      onCopy: _noop,
                      onDelete: _noop,
                      copyTooltip: 'Kopiraj',
                      deleteTooltip: 'Obriši',
                    ),
                    Expanded(
                      child: ListView(
                        children: <Widget>[
                          for (final m in _fixture())
                            buildAiMessageBubble(
                              context,
                              m,
                              typing: false,
                              userName: 'Ivana Marić',
                              userAvatarUrl: null,
                            ),
                          // Streaming variant (no timestamp branch).
                          buildAiMessageBubble(
                            context,
                            AiChatMessage(
                              role: 'assistant',
                              content: '...',
                              timestamp: DateTime(2026, 6, 16, 10, 44),
                            ),
                            isStreaming: true,
                            typing: false,
                            userName: '',
                            userAvatarUrl: null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // PRIMARY — no RenderFlex / layout overflow at this size.
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('AiConversationHeader — title + copy/delete actions render', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: AiConversationHeader(
            title: 'Kratak naslov',
            onCopy: _noop,
            onDelete: _noop,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Kratak naslov'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    // Actions hide when callbacks are null (read-only header).
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: AiConversationHeader(title: 'Bez akcija')),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.copy_rounded), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('AiBrandAvatar — asset-fail fallback renders without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: AiBrandAvatar())),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AiBrandAvatar), findsOneWidget);
  });
}
