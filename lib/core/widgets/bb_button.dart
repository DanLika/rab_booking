import 'package:flutter/material.dart';

import '../design/tokens.dart';

enum BBButtonVariant { primary, secondary, tertiary, destructive }

enum BBButtonSize { sm, md, lg }

/// BookBed button.
///
/// - primary: filled brand + [BBShadow.purple]
/// - secondary: outlined
/// - tertiary: text only (no background)
/// - destructive: filled coral (#FF6B6B)
///
/// Always ≥48px tall in [md]/[lg]; [sm] is 40 (use only for inline contexts
/// where 48 is impossible). Loading state locks width (no jump-cut).
class BBButton extends StatelessWidget {
  const BBButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = BBButtonVariant.primary,
    this.size = BBButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.fullWidth = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final BBButtonVariant variant;
  final BBButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool fullWidth;
  final bool loading;

  bool get _disabled => onPressed == null || loading;

  double get _height {
    switch (size) {
      case BBButtonSize.sm:
        return 40;
      case BBButtonSize.md:
        return 48;
      case BBButtonSize.lg:
        return 56;
    }
  }

  EdgeInsetsGeometry get _padding {
    switch (size) {
      case BBButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: BBSpace.sm);
      case BBButtonSize.md:
      case BBButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: BBSpace.md);
    }
  }

  TextStyle _labelStyle(BuildContext context, Color color) {
    final TextStyle base = size == BBButtonSize.sm
        ? BBType.caption(context)
        : BBType.label(context);
    return base.copyWith(color: color, fontWeight: FontWeight.w600);
  }

  ({Color bg, Color fg, Color? border, List<BoxShadow> shadow}) _palette(
    BuildContext context,
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
    switch (variant) {
      case BBButtonVariant.primary:
        return (
          bg: c.primary,
          fg: Colors.white,
          border: null,
          shadow: BBShadow.purple,
        );
      case BBButtonVariant.secondary:
        return (
          bg: c.surface,
          fg: c.primary,
          border: c.primary,
          shadow: const <BoxShadow>[],
        );
      case BBButtonVariant.tertiary:
        return (
          bg: Colors.transparent,
          fg: c.primary,
          border: null,
          shadow: const <BoxShadow>[],
        );
      case BBButtonVariant.destructive:
        return (
          bg: c.error,
          fg: Colors.white,
          border: null,
          shadow: const <BoxShadow>[],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final ({Color bg, Color fg, Color? border, List<BoxShadow> shadow}) p =
        _palette(context, c);

    final Widget content;
    if (loading) {
      content = SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(p.fg),
        ),
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leadingIcon != null) ...<Widget>[
            Icon(leadingIcon, size: 18, color: p.fg),
            const SizedBox(width: BBSpace.xs),
          ],
          Text(label, style: _labelStyle(context, p.fg)),
          if (trailingIcon != null) ...<Widget>[
            const SizedBox(width: BBSpace.xs),
            Icon(trailingIcon, size: 18, color: p.fg),
          ],
        ],
      );
    }

    final Widget body = AnimatedContainer(
      duration: BBMotion.adapt(context, BBMotion.fast),
      curve: BBMotion.curve,
      height: _height,
      padding: _padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BBRadius.smAll,
        boxShadow: p.shadow,
        border: p.border != null
            ? Border.all(color: p.border!, width: 1.5)
            : null,
      ),
      child: content,
    );

    final Widget tappable = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _disabled ? null : onPressed,
        borderRadius: BBRadius.smAll,
        // Match button shape so ripple is contained.
        child: body,
      ),
    );

    return Semantics(
      button: true,
      enabled: !_disabled,
      label: label,
      child: fullWidth
          ? SizedBox(width: double.infinity, child: tappable)
          : tappable,
    );
  }
}
