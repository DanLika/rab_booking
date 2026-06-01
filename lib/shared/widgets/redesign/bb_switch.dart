import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// Premium toggle switch (handoff `ToggleSwitch` — `ical.jsx:194`).
///
/// - 36×20 track, 16px circular thumb (Phase 1.3 spec; deliberately
///   tightened from handoff 40×24 + 18px thumb to harmonize with the
///   smaller `BbInput sm` height)
/// - ON: `c.primary` track + white thumb on the right
/// - OFF: `c.surfaceVariant` track + `c.textTertiary` thumb on the left
/// - Animated thumb slide via `AnimatedAlign` ([BBMotion.base], reduced-motion
///   aware via [BBMotion.adapt])
/// - 45% opacity + tap-disabled when [onChanged] is `null`
/// - Tap target extends across the entire label row (min 44px height per a11y)
///
/// **Form integration:** none. Toggles aren't typically Form-validated;
/// the analog is a `Form.didChange` callback if cross-field coordination
/// is needed (out of scope for this primitive). For multi-choice radio
/// validation use `BbRadioGroup`.
class BbSwitch extends StatelessWidget {
  const BbSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.subtitle,
    this.semanticLabel,
  });

  /// Current value. `true` = ON.
  final bool value;

  /// Tap handler. Passing `null` disables the control.
  final ValueChanged<bool>? onChanged;

  /// Inline label rendered left of the switch (settings-row convention).
  final String? label;

  /// Secondary text rendered below [label].
  final String? subtitle;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final bool disabled = onChanged == null;

    final Color trackColor = value ? c.primary : c.surfaceVariant;
    final Color thumbColor = value ? Colors.white : c.textTertiary;

    final Widget switchVisual = AnimatedContainer(
      duration: BBMotion.adapt(context, BBMotion.base),
      curve: BBMotion.curve,
      width: 36,
      height: 20,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: const BorderRadius.all(Radius.circular(BBRadius.full)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: AnimatedAlign(
          duration: BBMotion.adapt(context, BBMotion.base),
          curve: BBMotion.curve,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: thumbColor,
              shape: BoxShape.circle,
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x29000000), // ~16% black — handoff JSX
                  offset: Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final Widget row = InkWell(
      onTap: disabled ? null : () => onChanged!(!value),
      borderRadius: BBRadius.smAll,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpace.xxs,
            vertical: BBSpace.xs,
          ),
          child: Row(
            children: <Widget>[
              if (label != null || subtitle != null) ...<Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (label != null)
                        Text(
                          label!,
                          style: BBType.label(
                            context,
                          ).copyWith(color: c.textPrimary),
                        ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: BBType.caption(
                            context,
                          ).copyWith(color: c.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: BBSpace.xs),
              ],
              switchVisual,
            ],
          ),
        ),
      ),
    );

    return Semantics(
      label: semanticLabel ?? label,
      toggled: value,
      enabled: !disabled,
      child: Opacity(opacity: disabled ? 0.45 : 1.0, child: row),
    );
  }
}
