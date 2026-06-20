// Golden: owner AI Assistant conversation surface.
//
// Renders the REAL `AiConversationHeader` (brand avatar + title + copy/delete)
// and a user→assistant exchange via `buildAiMessageBubble` (solid user bubble +
// initials avatar, assistant markdown). No providers / l10n — strings passed in.

import 'package:bookbed/features/owner_dashboard/presentation/screens/guides/ai_assistant_screen.dart';
import 'package:bookbed/features/owner_dashboard/presentation/widgets/guides/ai_assistant_premium_header.dart';
import 'package:flutter/material.dart';

import '../../helpers/golden_fixtures.dart';
import '../../helpers/golden_harness.dart';

void _noop() {}

void main() {
  goldenSurface(
    'ai_conversation',
    build: (context, v) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AiConversationHeader(
          title: 'Kako blokirati datume za održavanje u srpnju?',
          onCopy: _noop,
          onDelete: _noop,
          copyTooltip: 'Kopiraj',
          deleteTooltip: 'Obriši',
        ),
        for (final m in aiChatFixture())
          buildAiMessageBubble(
            context,
            m,
            typing: false,
            userName: 'Ivana Marić',
            userAvatarUrl: null,
          ),
      ],
    ),
  );
}
