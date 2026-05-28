import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Card primitive. Surfaces content with optional header/body/footer slots.
/// - resting / hoverable (web hover lifts +translateY-2px + shadow→md)
/// - selected (2px primary border)
/// - disabled (50% opacity)
class BBCard extends StatefulWidget {
  const BBCard({
    super.key,
    this.header,
    required this.body,
    this.footer,
    this.onTap,
    this.selected = false,
    this.disabled = false,
    this.padding = const EdgeInsets.all(BBSpace.md),
  });

  final Widget? header;
  final Widget body;
  final Widget? footer;
  final VoidCallback? onTap;
  final bool selected;
  final bool disabled;
  final EdgeInsetsGeometry padding;

  @override
  State<BBCard> createState() => _BBCardState();
}

class _BBCardState extends State<BBCard> {
  bool _hover = false;

  bool get _isInteractive => widget.onTap != null && !widget.disabled;

  bool get _isHoverable {
    if (!_isInteractive) return false;
    // Hover lift is a desktop/web affordance only.
    return kIsWeb;
  }

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final bool elevated = _hover && _isHoverable;
    final Color border = widget.selected ? c.primary : c.border;
    final double borderWidth = widget.selected ? 2 : 1;

    final Widget inner = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BBRadius.mdAll,
        border: Border.all(color: border, width: borderWidth),
        boxShadow: elevated
            ? BBShadow.elevated(context)
            : BBShadow.resting(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.header != null) ...<Widget>[
            widget.header!,
            const SizedBox(height: BBSpace.sm),
          ],
          widget.body,
          if (widget.footer != null) ...<Widget>[
            const SizedBox(height: BBSpace.sm),
            widget.footer!,
          ],
        ],
      ),
    );

    final Widget lifted = AnimatedContainer(
      duration: BBMotion.adapt(context, BBMotion.fast),
      curve: BBMotion.curve,
      transform: elevated
          ? (Matrix4.identity()..translateByDouble(0.0, -2.0, 0.0, 1.0))
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      child: inner,
    );

    final Widget opacityShell = Opacity(
      opacity: widget.disabled ? 0.5 : 1.0,
      child: lifted,
    );

    if (!_isInteractive) return opacityShell;

    return MouseRegion(
      onEnter: (PointerEnterEvent _) => setState(() => _hover = true),
      onExit: (PointerExitEvent _) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BBRadius.mdAll,
          child: opacityShell,
        ),
      ),
    );
  }
}
