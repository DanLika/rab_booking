import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// BookBed avatar — photo with initials fallback.
///
/// Composes from BB tokens. Tap target meets 48px when [size]=lg; smaller
/// sizes are inert badges (no tap target required).
enum BBAvatarSize { sm, md, lg }

class BBAvatar extends StatelessWidget {
  const BBAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = BBAvatarSize.md,
    this.color,
  });

  /// Source for initials when [imageUrl] is null or fails. First letter of
  /// first + last whitespace-separated token. "Ana Marković" → "AM".
  final String? name;
  final String? imageUrl;
  final BBAvatarSize size;
  final Color? color;

  double get _diameter {
    switch (size) {
      case BBAvatarSize.sm:
        return 24;
      case BBAvatarSize.md:
        return 40;
      case BBAvatarSize.lg:
        return 56;
    }
  }

  String _initials() {
    final String n = (name ?? '').trim();
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
    final BBColorSet c = BBColor.of(context);
    final Color bg = color ?? c.primaryLight;
    final double d = _diameter;

    final Widget fallback = Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        _initials(),
        style: BBType.label(context).copyWith(
          fontSize: d * 0.4,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: SizedBox(
        width: d,
        height: d,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext ctx, Object err, StackTrace? st) =>
              fallback,
          loadingBuilder:
              (BuildContext ctx, Widget child, ImageChunkEvent? progress) {
                if (progress == null) return child;
                return fallback;
              },
        ),
      ),
    );
  }
}
