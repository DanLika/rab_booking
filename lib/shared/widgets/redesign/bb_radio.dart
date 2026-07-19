import 'package:flutter/material.dart';

import '../../../core/design/bb_redesign_tokens.dart';
import '../../../core/design/tokens.dart';

/// Premium radio control — parallels [BbCheckbox] for single-choice groups.
///
/// - 20×20 outer circle, 8px inner dot when selected
/// - Selected: `c.primary` outer border + filled inner dot
/// - Unselected: transparent outer + border `c.border` 1.5px
/// - 45% opacity + tap-disabled when [onChanged] is `null`
/// - Focus halo via `BbRedesignTokens.focusRingColor`
/// - Tap target extends across the entire label row (min 44px height per a11y)
///
/// **Group integration:** use [BbRadioGroup] for ergonomic multi-option
/// rendering + optional Form validation. Standalone [BbRadio] is fine when
/// you need finer layout control — just pass the same [groupValue] to every
/// option and route every [onChanged] back to the same setter.
class BbRadio<T> extends StatefulWidget {
  const BbRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.label,
    this.subtitle,
    this.semanticLabel,
  });

  /// This option's value.
  final T value;

  /// Currently-selected value in the group. `value == groupValue` means
  /// this option is selected.
  final T? groupValue;

  /// Tap handler. Receives this option's [value]. Passing `null` disables
  /// the control (45% opacity + no ripple).
  final ValueChanged<T>? onChanged;

  /// Inline label rendered right of the dot.
  final String? label;

  /// Secondary text rendered below [label].
  final String? subtitle;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  @override
  State<BbRadio<T>> createState() => _BbRadioState<T>();
}

class _BbRadioState<T> extends State<BbRadio<T>> {
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocus);
  bool _focused = false;

  void _onFocus() => setState(() => _focused = _focusNode.hasFocus);

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final BbRedesignTokens rd = BbRedesignTokens.of(context);
    final bool disabled = widget.onChanged == null;
    final bool selected = widget.value == widget.groupValue;

    final Color outerBorder = selected ? c.primary : c.border;

    final Widget dot = AnimatedContainer(
      duration: BBMotion.adapt(context, BBMotion.fast),
      curve: BBMotion.curve,
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: outerBorder, width: 1.5),
        boxShadow: _focused && !disabled
            ? <BoxShadow>[BoxShadow(color: rd.focusRingColor, spreadRadius: 3)]
            : null,
      ),
      child: Center(
        child: AnimatedScale(
          duration: BBMotion.adapt(context, BBMotion.fast),
          curve: BBMotion.curve,
          scale: selected ? 1.0 : 0.0,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
          ),
        ),
      ),
    );

    final Widget row = InkWell(
      onTap: disabled ? null : () => widget.onChanged!(widget.value),
      focusNode: _focusNode,
      borderRadius: BBRadius.smAll,
      child: ConstrainedBox(
        // minWidth 48: the label-less dot collapsed to ~24px (audit F2.7).
        constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpace.xxs,
            vertical: BBSpace.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              dot,
              if (widget.label != null || widget.subtitle != null) ...<Widget>[
                const SizedBox(width: BBSpace.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (widget.label != null)
                        Text(
                          widget.label!,
                          style: BBType.label(
                            context,
                          ).copyWith(color: c.textPrimary),
                        ),
                      if (widget.subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: BBType.caption(
                            context,
                          ).copyWith(color: c.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Radio contract (audit F2.7): `checked` + `inMutuallyExclusiveGroup`
    // are what TalkBack/VoiceOver need to announce a radio button — the old
    // `selected:` read as a generic selectable tile. Opacity moved OUTSIDE
    // Semantics; subtitle folded into the label; excludeSemantics kills the
    // double-read.
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: Semantics(
        label:
            widget.semanticLabel ??
            <String>[
              if (widget.label != null) widget.label!,
              if (widget.subtitle != null) widget.subtitle!,
            ].join(', '),
        checked: selected,
        inMutuallyExclusiveGroup: true,
        enabled: !disabled,
        excludeSemantics: true,
        child: row,
      ),
    );
  }
}

/// One option in a [BbRadioGroup]. Use the named-record positional form to
/// keep the call-site terse:
/// ```dart
/// BbRadioGroup<Lang>(
///   value: selected,
///   onChanged: (v) => setState(() => selected = v),
///   options: const <BbRadioOption<Lang>>[
///     (value: Lang.hr, label: 'Hrvatski'),
///     (value: Lang.en, label: 'English', subtitle: 'Beta'),
///   ],
/// )
/// ```
typedef BbRadioOption<T> = ({T value, String label, String? subtitle});

/// Single-choice radio group with optional Form integration.
///
/// Each option renders as a [BbRadio<T>]. The group manages selection by
/// passing [value] as `groupValue` to every option and routing every
/// `onChanged` back to the caller via [onChanged].
///
/// **Form integration (Phase 1.3 — mirrors `BbInput` #616):** pass [validator]
/// (and optional [autovalidateMode]) to wire this group into a [Form]
/// ancestor. `_formKey.currentState!.validate()` will then trigger validation.
/// Error text renders as a helper line below the last option, matching the
/// [BbInput] / [BbCheckbox] convention.
class BbRadioGroup<T> extends StatelessWidget {
  const BbRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.validator,
    this.autovalidateMode,
  });

  /// Currently-selected value, or `null` if no option selected.
  final T? value;

  /// Tap handler. Receives the newly-selected option's value. Passing `null`
  /// disables every option in the group.
  final ValueChanged<T>? onChanged;

  /// Options to render top-to-bottom.
  final List<BbRadioOption<T>> options;

  /// Validator wired into an internal [FormField<T>]. When non-null,
  /// `Form.of(context).validate()` will invoke this and any returned error
  /// string is rendered as a helper line below the group.
  final FormFieldValidator<T>? validator;

  /// Optional autovalidate mode forwarded to the internal [FormField].
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);

    Widget buildOptions(T? currentValue, ValueChanged<T>? onTap) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final BbRadioOption<T> option in options)
            BbRadio<T>(
              value: option.value,
              groupValue: currentValue,
              onChanged: onTap,
              label: option.label,
              subtitle: option.subtitle,
            ),
        ],
      );
    }

    // Only wrap in FormField when a validator is supplied — zero overhead
    // for plain groups, mirrors the BbInput #616 pattern exactly.
    if (validator != null) {
      return FormField<T>(
        initialValue: value,
        autovalidateMode: autovalidateMode,
        // Prefer the FormField's own accumulated value — validating the
        // outer prop raced parent rebuilds (audit F2.7).
        validator: (T? stateVal) => validator!.call(stateVal ?? value),
        builder: (FormFieldState<T> state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              buildOptions(value, (T v) {
                state.didChange(v);
                onChanged?.call(v);
              }),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: BBSpace.xxs),
                  child: Text(
                    state.errorText!,
                    style: BBType.caption(context).copyWith(color: c.error),
                  ),
                ),
            ],
          );
        },
      );
    }

    return buildOptions(value, onChanged);
  }
}
