import 'package:flutter/material.dart';

import '../../../core/design/bb_redesign_tokens.dart';
import '../../../core/design/tokens.dart';
import 'bb_icon.dart';
import 'bb_input.dart' show BbInputSize;

/// Single value+label+optional-icon menu entry for [BbDropdown].
///
/// The [icon] is a Material Symbol *name* (string), looked up via
/// [BbIcon]. It renders inside the menu item (and inside the closed
/// trigger row when this item is currently selected). For a decorative
/// leading icon on the trigger row itself, use [BbDropdown.iconLeft].
@immutable
class BbDropdownItem<T> {
  const BbDropdownItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final String? icon;
}

/// Premium dropdown / select (handoff parity with [BbInput]).
///
/// Matches [BbInput] chrome 1-to-1: label above, bordered surface row
/// with optional left icon, helper / error below. Size enum [BbInputSize]
/// is shared (sm 40 / md 48 / lg 56).
///
/// **Form integration (mirrors `BbInput` #616):** pass [validator] (and
/// optional [autovalidateMode]) to wire this dropdown into a [Form]
/// ancestor. `_formKey.currentState!.validate()` will then trigger
/// validation correctly. The existing [error] parameter remains for
/// manual error control outside Form contexts; if both are set, [error]
/// takes precedence (explicit override wins — same convention as
/// [BbInput] / [BbCheckbox]).
///
/// Implementation: when [validator] is non-null the widget wraps its
/// chrome in a [FormField<T>] (zero overhead when no validator is
/// supplied — the inner widget stays a plain [DropdownButton<T>]). The
/// validator runs against the live [value] so programmatic value writes
/// (controlled component pattern) are validated correctly.
///
/// **Why `DropdownButton` not `DropdownButtonFormField`:** the latter is
/// *always* a [FormField], which conflicts with the conditional-wrap
/// convention used by every other Bb* form primitive (BbInput,
/// BbCheckbox, BbRadioGroup). Using [DropdownButton] inside the custom
/// chrome lets us match the convention and reuse the helper-line / error
/// border path.
///
/// **Menu surface:** [DropdownButton.dropdownColor] is set to
/// `BbRedesignTokens.panelBg`. The menu corner radius is controlled by
/// the surrounding `ThemeData.popupMenuTheme`, not per-instance — a
/// known Flutter limitation we accept rather than fight. Switching to
/// the M3 `DropdownMenu` widget would be a different API and out of
/// scope for this PR.
class BbDropdown<T> extends StatefulWidget {
  const BbDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.placeholder,
    this.iconLeft,
    this.helper,
    this.error,
    this.size = BbInputSize.md,
    this.disabled = false,
    this.tabular = false,
    this.validator,
    this.autovalidateMode,
  });

  /// Current selection. `null` means no item is chosen and [placeholder]
  /// is rendered in its place.
  final T? value;

  /// Available menu entries. Each maps to a [DropdownMenuItem<T>].
  final List<BbDropdownItem<T>> items;

  /// Selection callback. Passing `null` (or [disabled] `true`) renders
  /// the control greyed out and inert.
  final ValueChanged<T?>? onChanged;

  /// Field label rendered above the row (label-style).
  final String? label;

  /// Hint shown when [value] is `null`.
  final String? placeholder;

  /// Decorative leading icon on the trigger row — Material Symbol name
  /// (string), looked up via [BbIcon]. Mirrors [BbInput.iconLeft].
  final String? iconLeft;

  /// Caption below the row when no error is active.
  final String? helper;

  /// Explicit error override. Takes precedence over [validator] output.
  final String? error;

  /// Row height. Shares [BbInputSize] (sm 40 / md 48 / lg 56) with
  /// [BbInput] so dropdown + text inputs align on the same form row.
  final BbInputSize size;

  /// Forces the trigger label + menu items to use tabular-figure
  /// numerals. Opt-in when the field carries primarily numeric content
  /// (year, currency code, etc.).
  final bool tabular;

  /// Disables the control regardless of [onChanged]. Mirrors
  /// [BbInput.disabled].
  final bool disabled;

  /// Validator wired into an internal [FormField<T>]. When non-null,
  /// `Form.of(context).validate()` will invoke this; any returned error
  /// string is rendered in the helper-text slot (unless [error] is set,
  /// in which case [error] wins).
  final FormFieldValidator<T>? validator;

  /// Optional autovalidate mode forwarded to the internal [FormField].
  final AutovalidateMode? autovalidateMode;

  @override
  State<BbDropdown<T>> createState() => _BbDropdownState<T>();
}

class _BbDropdownState<T> extends State<BbDropdown<T>> {
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocus);
  bool _focused = false;

  void _onFocus() => setState(() => _focused = _focusNode.hasFocus);

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    _focusNode.dispose();
    super.dispose();
  }

  double get _height {
    switch (widget.size) {
      case BbInputSize.sm:
        return 40;
      case BbInputSize.md:
        return 48;
      case BbInputSize.lg:
        return 56;
    }
  }

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final BbRedesignTokens rd = BbRedesignTokens.of(context);

    // Only wrap in FormField when a validator is supplied — zero overhead
    // for plain dropdowns, mirrors the BbInput #616 pattern exactly.
    if (widget.validator != null) {
      return FormField<T>(
        initialValue: widget.value,
        autovalidateMode: widget.autovalidateMode,
        // Validate against the live widget.value (controlled component)
        // so parent state changes are reflected without routing through
        // didChange — same pattern as BbInput's live-controller read.
        validator: (_) => widget.validator!.call(widget.value),
        builder: (FormFieldState<T> state) {
          return _buildChrome(
            context,
            c,
            rd,
            validatorError: state.errorText,
            onChangedInner: (T? v) {
              state.didChange(v);
              widget.onChanged?.call(v);
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
      onChangedInner: widget.onChanged,
    );
  }

  Widget _buildChrome(
    BuildContext context,
    BBColorSet c,
    BbRedesignTokens rd, {
    required String? validatorError,
    required ValueChanged<T?>? onChangedInner,
  }) {
    // Error precedence: explicit widget.error always wins over validator
    // output. Lets callers force a server-side error message regardless
    // of client-side validator state. Same convention as BbInput.
    final String? effectiveError = widget.error ?? validatorError;
    final bool hasError = effectiveError != null && effectiveError.isNotEmpty;

    final bool disabled = widget.disabled || onChangedInner == null;

    final Color borderColor = hasError
        ? c.error
        : _focused
        ? c.primary
        : c.border;
    final double borderWidth = hasError || _focused ? 2 : 1;

    final TextStyle baseStyle = BBType.body(
      context,
    ).copyWith(color: c.textPrimary);
    final TextStyle effectiveStyle = widget.tabular
        ? baseStyle.copyWith(
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          )
        : baseStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          Text(
            widget.label!,
            style: BBType.label(context).copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 6),
        ],
        Opacity(
          opacity: disabled ? 0.45 : 1.0,
          child: Container(
            height: _height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BBRadius.smAll,
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: _focused && !hasError
                  ? <BoxShadow>[
                      BoxShadow(color: rd.focusRingColor, spreadRadius: 3),
                    ]
                  : null,
            ),
            child: Row(
              children: <Widget>[
                if (widget.iconLeft != null) ...<Widget>[
                  BbIcon(
                    name: widget.iconLeft!,
                    size: 18,
                    color: c.textTertiary,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<T>(
                      value: widget.value,
                      focusNode: _focusNode,
                      isExpanded: true,
                      isDense: true,
                      // Trigger-row icon (caret). Use the same tertiary
                      // tint as iconLeft for visual consistency.
                      icon: BbIcon(
                        name: 'keyboard_arrow_down',
                        color: c.textTertiary,
                      ),
                      // Hint shown when value == null.
                      hint: widget.placeholder == null
                          ? null
                          : Text(
                              widget.placeholder!,
                              style: effectiveStyle.copyWith(
                                color: c.textTertiary,
                              ),
                            ),
                      style: effectiveStyle,
                      dropdownColor: rd.panelBg,
                      borderRadius: BBRadius.smAll,
                      // null onChanged greys the widget natively — keep
                      // the outer Opacity for the iconLeft/chrome that
                      // DropdownButton doesn't own.
                      onChanged: disabled ? null : onChangedInner,
                      items: widget.items
                          .map(
                            (BbDropdownItem<T> item) => DropdownMenuItem<T>(
                              value: item.value,
                              child: Row(
                                children: <Widget>[
                                  if (item.icon != null) ...<Widget>[
                                    BbIcon(
                                      name: item.icon!,
                                      size: 18,
                                      color: c.textTertiary,
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: effectiveStyle,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (effectiveError != null || widget.helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              effectiveError ?? widget.helper ?? '',
              style: BBType.caption(
                context,
              ).copyWith(color: hasError ? c.error : c.textTertiary),
            ),
          ),
      ],
    );
  }
}
