import 'package:flutter/material.dart';

import '../../../core/design/bb_redesign_tokens.dart';
import '../../../core/design/tokens.dart';
import 'bb_icon.dart';

/// Premium checkbox (handoff `Checkbox` helper — `dialogs.jsx:90`).
///
/// - 20×20 box, [BBRadius.xs] corners
/// - Filled `c.primary` when checked, transparent + `c.border` when unchecked
/// - Optional [label] + [subtitle] right of the box
/// - 45% opacity + tap-disabled when [onChanged] is `null`
/// - Focus halo via `BbRedesignTokens.focusRingColor`
/// - Tap target extends across the entire label row (min 44px height per a11y)
///
/// **Form integration (Phase 1.3 — mirrors `BbInput` #616):** pass [validator]
/// (and optional [autovalidateMode]) to wire this checkbox into a [Form]
/// ancestor. `_formKey.currentState!.validate()` will then trigger validation
/// correctly. The existing [error] parameter remains for manual error control
/// outside Form contexts; if both are set, [error] takes precedence (explicit
/// override wins — same convention as [BbInput]).
///
/// Implementation: when [validator] is non-null the widget wraps its chrome in
/// a [FormField<bool>] (zero overhead when no validator is supplied — the inner
/// widget stays a plain [StatefulWidget]). The validator runs against the live
/// `widget.value` so programmatic value writes are validated correctly.
///
/// **Error display:** the validator's error string renders as a helper line
/// below the checkbox row, matching the [BbInput] convention. A `Tooltip`-on-
/// icon variant was considered but rejected — it's invisible to touch users.
class BbCheckbox extends StatefulWidget {
  const BbCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.subtitle,
    this.validator,
    this.autovalidateMode,
    this.error,
    this.semanticLabel,
  });

  /// Current value. `true` = checked.
  final bool value;

  /// Tap handler. Passing `null` disables the control (45% opacity + no ripple).
  final ValueChanged<bool>? onChanged;

  /// Inline label rendered right of the box.
  final String? label;

  /// Secondary text rendered below [label].
  final String? subtitle;

  /// Validator wired into an internal [FormField<bool>]. When non-null,
  /// `Form.of(context).validate()` will invoke this and any returned error
  /// string is rendered as a helper line below the checkbox row (unless
  /// [error] is also set, in which case [error] wins).
  final FormFieldValidator<bool>? validator;

  /// Optional autovalidate mode forwarded to the internal [FormField].
  final AutovalidateMode? autovalidateMode;

  /// Explicit error override. Takes precedence over [validator] output.
  final String? error;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  @override
  State<BbCheckbox> createState() => _BbCheckboxState();
}

class _BbCheckboxState extends State<BbCheckbox> {
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

    // Only wrap in FormField when a validator is supplied — zero overhead
    // for plain checkboxes, mirrors the BbInput #616 pattern exactly.
    if (widget.validator != null) {
      return FormField<bool>(
        initialValue: widget.value,
        autovalidateMode: widget.autovalidateMode,
        // Validate against the live widget.value (controlled component) so
        // parent state changes are reflected even without routing through
        // didChange — same pattern as BbInput's live-controller read.
        validator: (_) => widget.validator!.call(widget.value),
        builder: (FormFieldState<bool> state) {
          return _buildChrome(
            context,
            c,
            rd,
            validatorError: state.errorText,
            onTapInner: () {
              final bool next = !widget.value;
              state.didChange(next);
              widget.onChanged?.call(next);
            },
          );
        },
      );
    }

    return _buildChrome(
      context,
      c,
      rd,
      validatorError: null,
      onTapInner: () => widget.onChanged?.call(!widget.value),
    );
  }

  Widget _buildChrome(
    BuildContext context,
    BBColorSet c,
    BbRedesignTokens rd, {
    required String? validatorError,
    required VoidCallback onTapInner,
  }) {
    final bool disabled = widget.onChanged == null;

    // Error precedence: explicit widget.error always wins over validator
    // output. Lets callers force a server-side error message regardless of
    // client-side validator state. Same convention as BbInput.
    final String? effectiveError = widget.error ?? validatorError;
    final bool hasError = effectiveError != null && effectiveError.isNotEmpty;

    final bool checked = widget.value;
    final Color boxBorder = hasError
        ? c.error
        : checked
        ? c.primary
        : c.border;
    final Color boxFill = checked ? c.primary : Colors.transparent;

    final Widget row = InkWell(
      onTap: disabled ? null : onTapInner,
      focusNode: _focusNode,
      borderRadius: BBRadius.smAll,
      child: ConstrainedBox(
        // minWidth 44: the label-less box collapsed to ~28px wide — the ROOT
        // of the register-screen 22×22 tap-target finding (audit F2.7).
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpace.xxs,
            vertical: BBSpace.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 20×20 box — handoff `dialogs.jsx:98-106`
              AnimatedContainer(
                duration: BBMotion.adapt(context, BBMotion.fast),
                curve: BBMotion.curve,
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: boxFill,
                  borderRadius: BBRadius.xsAll,
                  border: Border.all(color: boxBorder, width: 1.5),
                  boxShadow: _focused && !disabled
                      ? <BoxShadow>[
                          BoxShadow(color: rd.focusRingColor, spreadRadius: 3),
                        ]
                      : null,
                ),
                child: AnimatedOpacity(
                  duration: BBMotion.adapt(context, BBMotion.fast),
                  opacity: checked ? 1.0 : 0.0,
                  child: BbIcon(
                    name: 'check',
                    size: 14,
                    color: c.onPrimary,
                    weight: 600,
                  ),
                ),
              ),
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

    // One merged node (audit F2.7): subtitle folded into the announced label
    // — a T&C checkbox previously never read its subtitle; excludeSemantics
    // kills the label/subtitle double-read. Error text stays a SIBLING so it
    // is still announced. Opacity sits OUTSIDE Semantics (visual dim must
    // not wrap the a11y node).
    final String? mergedLabel =
        widget.semanticLabel ??
        <String>[
          if (widget.label != null) widget.label!,
          if (widget.subtitle != null) widget.subtitle!,
        ].join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Opacity(
          opacity: disabled ? 0.45 : 1.0,
          child: Semantics(
            label: mergedLabel,
            checked: checked,
            enabled: !disabled,
            excludeSemantics: true,
            child: row,
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: BBSpace.xxs),
            child: Text(
              effectiveError,
              style: BBType.caption(context).copyWith(color: c.error),
            ),
          ),
      ],
    );
  }
}
