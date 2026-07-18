import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/design/bb_redesign_tokens.dart';
import '../../../core/design/tokens.dart';

enum BbCardVariant { defaultStyle, flat, accentLeft }

enum BbCardAccentTone { primary, tertiary, success, error, info }

/// Floating surface (handoff [BBCard]).
///
/// - padded toggle
/// - selected (primary border)
/// - hoverable (web translate-up + shadow lift)
/// - variant accent-left (4px colored left bar)
///
/// **A11y (audit sweep F2.6):** pass [excludeSemantics] = true when
/// [semanticLabel] mirrors text already rendered inside the card — without
/// it screen readers announce the label AND traverse into the child,
/// reading the same string twice (notifications double-read finding).
/// Non-interactive cards with a [semanticLabel] now announce as a container
/// (previously they were semantically invisible).
class BbCard extends StatefulWidget {
  const BbCard({
    super.key,
    required this.child,
    this.padded = true,
    this.padding,
    this.selected = false,
    this.hoverable = false,
    this.variant = BbCardVariant.defaultStyle,
    this.accentTone = BbCardAccentTone.tertiary,
    this.onTap,
    this.semanticLabel,
    this.excludeSemantics = false,
  });

  final Widget child;
  final bool padded;
  final EdgeInsetsGeometry? padding;
  final bool selected;
  final bool hoverable;
  final BbCardVariant variant;
  final BbCardAccentTone accentTone;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Collapse the child subtree into the single [semanticLabel] node.
  /// Default `false` preserves previous behavior for all call sites.
  final bool excludeSemantics;

  @override
  State<BbCard> createState() => _BbCardState();
}

class _BbCardState extends State<BbCard> {
  // Cached transforms — per-build Matrix4 allocation flagged in the audit.
  static final Matrix4 _identity = Matrix4.identity();
  static final Matrix4 _liftTransform = Matrix4.identity()
    ..translateByDouble(0, -2, 0, 1);

  bool _hover = false;

  Color _accent(BBColorSet c) {
    switch (widget.accentTone) {
      case BbCardAccentTone.primary:
        return c.primary;
      case BbCardAccentTone.tertiary:
        return c.tertiary;
      case BbCardAccentTone.success:
        return c.success;
      case BbCardAccentTone.error:
        return c.error;
      case BbCardAccentTone.info:
        return c.info;
    }
  }

  bool get _isInteractive => widget.onTap != null;
  bool get _liftEnabled => widget.hoverable && _isInteractive && kIsWeb;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final BbAdminDarkTokens? admin = Theme.of(
      context,
    ).extension<BbAdminDarkTokens>();
    final Color cardSurface = admin?.panelBg ?? c.surface;
    final bool elevated = _hover && _liftEnabled;
    final EdgeInsetsGeometry padding =
        widget.padding ??
        (widget.padded ? const EdgeInsets.all(20) : EdgeInsets.zero);

    final Color borderColor = widget.selected ? c.primary : c.border;
    final double borderWidth = widget.selected ? 2 : 1;

    Widget inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BBRadius.mdAll,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: widget.variant == BbCardVariant.flat
            ? const <BoxShadow>[]
            : (elevated ? BBShadow.elevated(context) : BBShadow.cardElevated),
      ),
      child: widget.child,
    );

    if (widget.variant == BbCardVariant.accentLeft) {
      inner = Stack(
        children: <Widget>[
          inner,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: _accent(c),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(BBRadius.md),
                  bottomLeft: Radius.circular(BBRadius.md),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final Widget lifted = AnimatedContainer(
      duration: BBMotion.adapt(context, BBMotion.fast),
      curve: BBMotion.curve,
      transform: elevated ? _liftTransform : _identity,
      transformAlignment: Alignment.center,
      child: inner,
    );

    if (!_isInteractive) {
      // Content cards were semantically invisible — announce the boundary
      // when the caller supplies a label (audit F2.6).
      if (widget.semanticLabel != null) {
        return Semantics(
          container: true,
          label: widget.semanticLabel,
          excludeSemantics: widget.excludeSemantics,
          child: lifted,
        );
      }
      return lifted;
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: widget.excludeSemantics,
      child: MouseRegion(
        onEnter: (PointerEnterEvent _) => setState(() => _hover = true),
        onExit: (PointerExitEvent _) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BBRadius.mdAll,
            child: lifted,
          ),
        ),
      ),
    );
  }
}
