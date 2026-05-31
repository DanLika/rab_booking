import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import 'bb_icon.dart';
import 'bb_spinner.dart';

/// Variants matching handoff [BBButton] (primitives.jsx).
enum BbButtonVariant {
  primary,
  secondary,
  tertiary,
  destructive,
  destructiveSoft,
  success,
  onGradient,
  onGradientSolid,
}

enum BbButtonSize { sm, md, lg }

/// Premium console button (handoff [BBButton]).
///
/// - primary: filled brand + `--bb-shadow-purple-sm`
/// - secondary: white surface + border
/// - tertiary: text only
/// - destructive: filled error
/// - destructive-soft: error-tint + error text
/// - success: filled success
/// - on-gradient / on-gradient-solid: for hero/dark surfaces
class BbButton extends StatefulWidget {
  const BbButton({
    super.key,
    this.label,
    this.iconLeft,
    this.iconRight,
    this.onPressed,
    this.variant = BbButtonVariant.primary,
    this.size = BbButtonSize.md,
    this.fullWidth = false,
    this.loading = false,
    this.disabled = false,
    this.active = false,
    this.asIcon = false,
    this.semanticLabel,
  });

  final String? label;
  final String? iconLeft;
  final String? iconRight;
  final VoidCallback? onPressed;
  final BbButtonVariant variant;
  final BbButtonSize size;
  final bool fullWidth;
  final bool loading;
  final bool disabled;
  final bool active;
  final bool asIcon;
  final String? semanticLabel;

  @override
  State<BbButton> createState() => _BbButtonState();
}

class _BbButtonState extends State<BbButton> {
  bool _hover = false;

  bool get _disabled =>
      widget.disabled || widget.loading || widget.onPressed == null;

  double get _height {
    switch (widget.size) {
      case BbButtonSize.sm:
        return 36;
      case BbButtonSize.md:
        return 44;
      case BbButtonSize.lg:
        return 52;
    }
  }

  double get _hPad {
    switch (widget.size) {
      case BbButtonSize.sm:
        return 12;
      case BbButtonSize.md:
        return 16;
      case BbButtonSize.lg:
        return 20;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case BbButtonSize.sm:
        return 13;
      case BbButtonSize.md:
        return 14;
      case BbButtonSize.lg:
        return 15;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case BbButtonSize.sm:
        return 16;
      case BbButtonSize.md:
        return 18;
      case BbButtonSize.lg:
        return 20;
    }
  }

  ({Color bg, Color fg, Color? border, List<BoxShadow> shadow}) _palette(
    BBColorSet c,
  ) {
    if (_disabled) {
      return (
        bg: c.surfaceVariant,
        fg: c.textTertiary,
        border: null,
        shadow: const <BoxShadow>[],
      );
    }
    switch (widget.variant) {
      case BbButtonVariant.primary:
        return (
          bg: _hover ? c.primaryDark : c.primary,
          fg: Colors.white,
          border: null,
          shadow: _hover ? BBShadow.purple : BBShadow.purpleSm,
        );
      case BbButtonVariant.secondary:
        return (
          bg: _hover ? c.surfaceVariant : c.surface,
          fg: c.textPrimary,
          border: c.border,
          shadow: const <BoxShadow>[],
        );
      case BbButtonVariant.tertiary:
        return (
          bg: _hover ? c.primary.withValues(alpha: 0.08) : Colors.transparent,
          fg: c.primary,
          border: null,
          shadow: const <BoxShadow>[],
        );
      case BbButtonVariant.destructive:
        return (
          bg: c.error,
          fg: Colors.white,
          border: null,
          shadow: const <BoxShadow>[],
        );
      case BbButtonVariant.destructiveSoft:
        return (
          bg: c.error.withValues(alpha: 0.10),
          fg: c.error,
          border: null,
          shadow: const <BoxShadow>[],
        );
      case BbButtonVariant.success:
        return (
          bg: c.success,
          fg: Colors.white,
          border: null,
          shadow: const <BoxShadow>[],
        );
      case BbButtonVariant.onGradient:
        return (
          bg: const Color(0x29FFFFFF),
          fg: Colors.white,
          border: const Color(0x38FFFFFF),
          shadow: const <BoxShadow>[],
        );
      case BbButtonVariant.onGradientSolid:
        return (
          bg: Colors.white,
          fg: c.primary,
          border: null,
          shadow: const <BoxShadow>[],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final ({Color bg, Color fg, Color? border, List<BoxShadow> shadow}) p =
        _palette(c);

    final double w = widget.asIcon ? _height : 0;
    final EdgeInsets padding = widget.asIcon
        ? EdgeInsets.zero
        : EdgeInsets.symmetric(horizontal: _hPad);

    Widget content;
    if (widget.loading) {
      content = BbSpinner(size: _iconSize, color: p.fg);
    } else {
      final List<Widget> kids = <Widget>[];
      if (widget.iconLeft != null) {
        kids.add(BbIcon(name: widget.iconLeft!, size: _iconSize, color: p.fg));
      }
      if (widget.label != null && !widget.asIcon) {
        if (widget.iconLeft != null) kids.add(const SizedBox(width: 8));
        kids.add(
          Text(
            widget.label!,
            style: TextStyle(
              color: p.fg,
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.07,
              height: 1,
            ),
          ),
        );
      }
      if (widget.iconRight != null) {
        if (kids.isNotEmpty) kids.add(const SizedBox(width: 8));
        kids.add(BbIcon(name: widget.iconRight!, size: _iconSize, color: p.fg));
      }
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: kids,
      );
    }

    final Widget body = AnimatedContainer(
      duration: BBMotion.adapt(context, BBMotion.fast),
      curve: BBMotion.curve,
      height: _height,
      width: widget.asIcon ? w : (widget.fullWidth ? double.infinity : null),
      constraints: BoxConstraints(minWidth: _height),
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BBRadius.smAll,
        boxShadow: p.shadow,
        border: p.border != null ? Border.all(color: p.border!) : null,
      ),
      child: content,
    );

    final Widget tappable = Opacity(
      opacity: _disabled ? 0.45 : 1,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: _disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _disabled ? null : widget.onPressed,
            borderRadius: BBRadius.smAll,
            child: body,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: !_disabled,
      label: widget.semanticLabel ?? widget.label,
      child: tappable,
    );
  }
}
