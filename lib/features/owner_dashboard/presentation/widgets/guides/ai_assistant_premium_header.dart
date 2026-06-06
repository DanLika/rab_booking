import 'package:flutter/material.dart';

import '../../../../../core/design/tokens.dart';

/// Premium header for AI Assistant screen (audit/117 §B4, mirrors
/// `ai-assistant.jsx` consent + chat surface top regions). Eyebrow chip
/// "BOOKBED AI" + display H1 + status dot.
class AiAssistantPremiumHeader extends StatelessWidget {
  const AiAssistantPremiumHeader({
    super.key,
    required this.title,
    this.subtitle = 'BookBed AI · trenutno aktivan',
    this.online = true,
  });

  final String title;
  final String subtitle;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final bool isMobile = MediaQuery.sizeOf(context).width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'BOOKBED AI',
          style: BBType.eyebrow(context).copyWith(color: c.primary),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: BBType.h1(context).copyWith(
            fontSize: isMobile ? 24 : 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: online ? c.success : c.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                subtitle,
                style: BBType.caption(
                  context,
                ).copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
