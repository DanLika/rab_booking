import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// Avatar sizes per handoff (xs/sm/md/lg/xl = 28/36/44/56/80).
enum BbAvatarSize { xs, sm, md, lg, xl }

/// Tone presets (matches `primitives.jsx` `BBAvatar` `tone` prop).
enum BbAvatarTone { primary, success, info, tertiary, neutral, onGradient }

/// Avatar with initials fallback + tone palette + optional ring (handoff [BBAvatar]).
class BbAvatar extends StatelessWidget {
  const BbAvatar({
    super.key,
    this.name = '',
    this.imageUrl,
    this.size = BbAvatarSize.md,
    this.tone = BbAvatarTone.primary,
    this.ring = false,
  });

  final String name;
  final String? imageUrl;
  final BbAvatarSize size;
  final BbAvatarTone tone;
  final bool ring;

  double get _diameter {
    switch (size) {
      case BbAvatarSize.xs:
        return 28;
      case BbAvatarSize.sm:
        return 36;
      case BbAvatarSize.md:
        return 44;
      case BbAvatarSize.lg:
        return 56;
      case BbAvatarSize.xl:
        return 80;
    }
  }

  ({Color bg, Color fg}) _palette(BBColorSet c) {
    switch (tone) {
      case BbAvatarTone.primary:
        return (bg: c.primary.withValues(alpha: 0.10), fg: c.primary);
      case BbAvatarTone.success:
        return (bg: c.success.withValues(alpha: 0.16), fg: c.success);
      case BbAvatarTone.info:
        return (bg: c.info.withValues(alpha: 0.12), fg: c.info);
      case BbAvatarTone.tertiary:
        return (bg: c.tertiary.withValues(alpha: 0.16), fg: c.tertiary);
      case BbAvatarTone.neutral:
        return (bg: c.surfaceVariant, fg: c.textSecondary);
      case BbAvatarTone.onGradient:
        return (bg: const Color(0x2EFFFFFF), fg: Colors.white);
    }
  }

  String _initials() {
    final String n = name.trim();
    if (n.isEmpty) return '?';
    final List<String> parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final double d = _diameter;
    final ({Color bg, Color fg}) p = _palette(BBColor.of(context));

    final Widget fallback = Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.bg, shape: BoxShape.circle),
      child: Text(
        _initials(),
        style: TextStyle(
          color: p.fg,
          fontWeight: FontWeight.w600,
          fontSize: d * 0.4,
          height: 1,
        ),
      ),
    );

    final Widget core = (imageUrl == null || imageUrl!.isEmpty)
        ? fallback
        : ClipOval(
            child: SizedBox(
              width: d,
              height: d,
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (_, Widget child, ImageChunkEvent? p) =>
                    p == null ? child : fallback,
              ),
            ),
          );

    if (!ring) return core;
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(color: Color(0x33FFFFFF), spreadRadius: 3),
        ],
      ),
      child: core,
    );
  }
}
