import 'package:flutter/material.dart';

import '../../../../../core/design/tokens.dart';

// ── AI header metrics — off-8px-grid primitives sourced from
// `design_handoff/source/ai-assistant.jsx` (icon tile 36/r10, status dot 8).
// Token-first elsewhere; these cover the handoff's off-scale values so the
// header carries 0 raw literals.
const double _kBrandIcon = 36; // handoff 36×36 icon container
const double _kIconTileRadius =
    10; // handoff icon-tile radius (xs6 < 10 < sm12)
const double _kIconInset = 4; // image inset inside the tile
const double _kStatusDot = 8; // online status dot
const double _k12 = 12; // handoff 12px gap/pad (off the BBSpace 8px scale)
// Aligned with the screen's _kDesktopBp so the header folds COHERENTLY with the
// layout at 768 (audit/132 R1: tablet → mobile, no distinct tablet tier).
const double _kDesktopBp = 1200;
const double _kTitleFontCompact = 24; // hero H1 below desktop
const double _kTitleFontDesktop = 30; // hero H1 at desktop
const double _kHeaderActionIcon = 18; // copy/delete glyph (conversation header)

/// Brand icon-avatar tile — primary-tint rounded square housing the assistant
/// glyph. Mirrors the `ai-assistant.jsx` 36×36 icon container (radius 10,
/// `primary` tint bg). Shared by the conversation header + chat-list avatars.
/// Falls back to an `auto_awesome` glyph when the bundled illustration can't
/// load (offline / asset-fail) so the tile never collapses.
class AiBrandAvatar extends StatelessWidget {
  const AiBrandAvatar({super.key, this.size = _kBrandIcon});

  final double size;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(_kIconTileRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_kIconInset),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kIconTileRadius - _kIconInset),
          child: Image.asset(
            'assets/images/assistant_illustration.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Icon(Icons.auto_awesome, size: size * 0.58, color: c.primary),
          ),
        ),
      ),
    );
  }
}

/// Premium landing/hero header for the AI Assistant screen (audit/117 §B4,
/// mirrors `ai-assistant.jsx` empty-hero top region). Eyebrow chip "BOOKBED AI"
/// + display H1 + status dot. Used above the chat list (mobile + desktop split).
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
    final bool isCompact = MediaQuery.sizeOf(context).width < _kDesktopBp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'BOOKBED AI',
          style: BBType.eyebrow(context).copyWith(color: c.primary),
        ),
        const SizedBox(height: BBSpace.xxs),
        Text(
          title,
          style: BBType.h1(context).copyWith(
            fontSize: isCompact ? _kTitleFontCompact : _kTitleFontDesktop,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: BBSpace.xs),
        _StatusRow(online: online, subtitle: subtitle),
      ],
    );
  }
}

/// Slim per-conversation header (mirrors `ai-assistant.jsx` chat header,
/// lines 94-120): brand icon avatar + chat title + "BookBed AI · aktivan"
/// status + optional copy/delete actions, divided by a 1px bottom border.
/// Mounted above the message list so the active chat carries its own title
/// (`CommonAppBar` passes `showTitle: false` to avoid a double-header).
class AiConversationHeader extends StatelessWidget {
  const AiConversationHeader({
    super.key,
    required this.title,
    this.subtitle = 'BookBed AI · trenutno aktivan',
    this.online = true,
    this.onCopy,
    this.onDelete,
    this.copyTooltip,
    this.deleteTooltip,
  });

  final String title;
  final String subtitle;
  final bool online;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final String? copyTooltip;
  final String? deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final bool isCompact = MediaQuery.sizeOf(context).width < _kDesktopBp;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? BBSpace.sm : BBSpace.md,
        vertical: _k12,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: <Widget>[
          const AiBrandAvatar(),
          const SizedBox(width: _k12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BBType.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: BBSpace.xxs),
                _StatusRow(online: online, subtitle: subtitle),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: _kHeaderActionIcon),
              color: c.textTertiary,
              tooltip: copyTooltip,
              visualDensity: VisualDensity.compact,
            ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: _kHeaderActionIcon),
              color: c.textTertiary,
              tooltip: deleteTooltip,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

/// Green status dot + subtitle row shared by both headers.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.online, required this.subtitle});

  final bool online;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: _kStatusDot,
          height: _kStatusDot,
          decoration: BoxDecoration(
            color: online ? c.success : c.textTertiary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: BBSpace.xs),
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
    );
  }
}
