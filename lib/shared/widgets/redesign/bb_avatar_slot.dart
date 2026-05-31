import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// User-fillable circular photo slot (handoff [BBAvatarSlot]).
///
/// Web prototype used `<image-slot>` custom element for drag-and-drop fill;
/// Flutter port exposes a tap callback consumers wire to `image_picker` or
/// similar. When [imageUrl] is null shows the placeholder label.
class BbAvatarSlot extends StatelessWidget {
  const BbAvatarSlot({
    super.key,
    this.id = 'bb-owner-avatar',
    this.size = 80,
    this.placeholder = 'Foto',
    this.imageUrl,
    this.ring = false,
    this.ringColor = const Color(0x40FFFFFF),
    this.onTap,
  });

  final String id;
  final double size;
  final String placeholder;
  final String? imageUrl;
  final bool ring;
  final Color ringColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final BoxDecoration deco = BoxDecoration(
      shape: BoxShape.circle,
      color: c.surfaceVariant,
      image: (imageUrl != null && imageUrl!.isNotEmpty)
          ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
          : null,
      border: Border.all(color: c.border),
      boxShadow: ring
          ? <BoxShadow>[BoxShadow(color: ringColor, spreadRadius: 3)]
          : null,
    );

    final Widget core = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: deco,
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? Text(
              placeholder,
              style: BBType.caption(
                context,
              ).copyWith(color: c.textTertiary, fontWeight: FontWeight.w500),
            )
          : null,
    );

    if (onTap == null) return core;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: core,
      ),
    );
  }
}
