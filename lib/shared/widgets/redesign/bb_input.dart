import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/bb_redesign_tokens.dart';
import '../../../core/design/tokens.dart';
import 'bb_icon.dart';

enum BbInputSize { sm, md, lg }

/// Premium text field (handoff [BBInput]).
///
/// - leading/trailing icon
/// - error + helper text
/// - char counter (`charLimit`)
/// - size: sm 40 / md 48 / lg 56
///
/// **Form integration (Phase 1.1):** Pass [validator] (and optional
/// [autovalidateMode]) to wire this input into a [Form] ancestor.
/// `_formKey.currentState!.validate()` will then trigger validation
/// correctly. The existing [error] parameter remains for manual error
/// control outside Form contexts; if both are set, [error] takes precedence
/// (explicit override wins).
///
/// Implementation: when [validator] is non-null the widget wraps its
/// chrome in a [FormField<String>] (zero overhead when no validator is
/// supplied — the inner widget stays a plain [TextField]). The validator
/// receives the live controller text so server-side `controller.text = …`
/// writes are validated correctly.
///
/// **Trailing slots:** [iconRight] takes a Material Symbol *name* (string)
/// and renders a static decorative icon. For stateful interactive trailing
/// content (password visibility toggle, clipboard button, etc.) use
/// [trailingAction] which accepts a [Widget].
///
/// **Keyboard + autofill (audit sweep F2.1):** [textInputAction] controls the
/// IME action key (`next`/`done`/`search`), [focusNode] accepts an external
/// node so forms can chain focus programmatically, [autofillHints] wires the
/// field into platform autofill / password managers (wrap multi-field forms
/// in an [AutofillGroup]), [autofocus] and [textCapitalization] forward
/// directly to the inner [TextField]. All additive — defaults preserve the
/// previous behavior. Backported from the retired `BBInput` prototype.
class BbInput extends StatefulWidget {
  const BbInput({
    super.key,
    this.label,
    this.controller,
    this.initialValue,
    this.placeholder,
    this.iconLeft,
    this.iconRight,
    this.trailingAction,
    this.obscureText = false,
    this.error,
    this.helper,
    this.disabled = false,
    this.charLimit,
    this.size = BbInputSize.md,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.autofillHints,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onFieldSubmitted,
    this.validator,
    this.autovalidateMode,
  });

  final String? label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? placeholder;
  final String? iconLeft;
  final String? iconRight;
  final Widget? trailingAction;
  final bool obscureText;
  final String? error;
  final String? helper;
  final bool disabled;
  final int? charLimit;
  final BbInputSize size;

  /// IME action key (e.g. [TextInputAction.next] to advance a form chain,
  /// [TextInputAction.done] on the last field). Forwarded to [TextField].
  final TextInputAction? textInputAction;

  /// External focus node. When supplied the caller owns its lifecycle (this
  /// widget only attaches/detaches its focus listener); when null an internal
  /// node is created and disposed as before.
  final FocusNode? focusNode;

  /// Platform autofill hints (e.g. `[AutofillHints.email]`,
  /// `[AutofillHints.password]`). Enables password-manager integration.
  final Iterable<String>? autofillHints;

  /// Autofocus this field on mount. Forwarded to [TextField].
  final bool autofocus;

  /// Capitalization behavior (e.g. [TextCapitalization.words] for name
  /// fields). Forwarded to [TextField].
  final TextCapitalization textCapitalization;

  /// Visible line count. `1` (default) keeps the fixed [size]-driven height;
  /// `> 1` switches the field to a multiline area (minHeight = [size] height,
  /// grows with content, icon top-aligned). [charLimit] is hard-enforced via
  /// `TextField.maxLength` (built-in counter suppressed — the chrome renders
  /// its own `x/limit` counter).
  final int maxLines;
  final TextInputType? keyboardType;

  /// Optional input formatters forwarded to the inner [TextField]
  /// (e.g. `FilteringTextInputFormatter.digitsOnly` for numeric fields).
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Form-aware submit callback. Fires when the user submits the field
  /// (e.g. presses "done" on a soft keyboard). Use instead of (or in
  /// addition to) [onSubmitted] when the input lives inside a [Form].
  final ValueChanged<String>? onFieldSubmitted;

  /// Validator wired into an internal [FormField<String>]. When non-null,
  /// `Form.of(context).validate()` will invoke this and any returned error
  /// string is rendered in the existing helper-text slot (unless [error]
  /// is also set, in which case [error] wins).
  final FormFieldValidator<String>? validator;

  /// Optional autovalidate mode forwarded to the internal [FormField].
  /// Defaults to `null` (Flutter falls back to [AutovalidateMode.disabled]).
  final AutovalidateMode? autovalidateMode;

  @override
  State<BbInput> createState() => _BbInputState();
}

class _BbInputState extends State<BbInput> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  late TextEditingController _ctrl;
  bool _ownsCtrl = false;
  bool _focused = false;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _initFocusNode();
    _initController();
  }

  void _initFocusNode() {
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocus);
  }

  void _initController() {
    _ownsCtrl = widget.controller == null;
    _ctrl =
        widget.controller ??
        TextEditingController(text: widget.initialValue ?? '');
    _charCount = _ctrl.text.length;
    // Perf: the counter is only rendered when charLimit is set — don't
    // rebuild the whole field on every keystroke otherwise.
    if (widget.charLimit != null) _ctrl.addListener(_onText);
  }

  @override
  void didUpdateWidget(BbInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-attach when the parent swaps in a different node/controller —
    // `late final` init would silently keep tracking the stale instance.
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocus);
      if (_ownsFocusNode) _focusNode.dispose();
      _initFocusNode();
      _focused = _focusNode.hasFocus;
    }
    if (oldWidget.controller != widget.controller) {
      _ctrl.removeListener(_onText);
      if (_ownsCtrl) _ctrl.dispose();
      _initController();
    } else if (oldWidget.charLimit != widget.charLimit) {
      _ctrl.removeListener(_onText);
      if (widget.charLimit != null) {
        _charCount = _ctrl.text.length;
        _ctrl.addListener(_onText);
      }
    }
  }

  void _onFocus() => setState(() => _focused = _focusNode.hasFocus);
  void _onText() => setState(() => _charCount = _ctrl.text.length);

  @override
  void dispose() {
    _ctrl.removeListener(_onText);
    if (_ownsCtrl) _ctrl.dispose();
    _focusNode.removeListener(_onFocus);
    if (_ownsFocusNode) _focusNode.dispose();
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
    // for plain inputs, preserves backward compat for PR #611 callers
    // and any caller that just wants a styled TextField.
    if (widget.validator != null) {
      return FormField<String>(
        initialValue: _ctrl.text,
        autovalidateMode: widget.autovalidateMode,
        // Validate against the live controller text rather than the
        // FormField's cached `state.value` — callers may write
        // `controller.text = …` programmatically (server-side error clear,
        // password fill, etc.) without routing through `didChange`.
        validator: (_) => widget.validator!.call(_ctrl.text),
        builder: (FormFieldState<String> state) {
          return _buildChrome(
            context,
            c,
            rd,
            validatorError: state.errorText,
            onChangedInner: (String v) {
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
    required ValueChanged<String>? onChangedInner,
  }) {
    // Error precedence: explicit `widget.error` always wins over validator
    // output. This lets callers force a server-side error message
    // regardless of client-side validator state.
    final String? effectiveError = widget.error ?? validatorError;
    final bool hasError = effectiveError != null && effectiveError.isNotEmpty;

    final Color borderColor = hasError
        ? c.error
        : _focused
        ? c.primary
        : c.border;
    final double borderWidth = hasError || _focused ? 2 : 1;

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
        Container(
          height: widget.maxLines > 1 ? null : _height,
          constraints: widget.maxLines > 1
              ? BoxConstraints(minHeight: _height)
              : null,
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: widget.maxLines > 1 ? 10 : 0,
          ),
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
            crossAxisAlignment: widget.maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: <Widget>[
              if (widget.iconLeft != null) ...<Widget>[
                BbIcon(name: widget.iconLeft!, size: 18, color: c.textTertiary),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  enabled: !widget.disabled,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  textCapitalization: widget.textCapitalization,
                  autofocus: widget.autofocus,
                  autofillHints: widget.autofillHints,
                  maxLines: widget.maxLines,
                  maxLength: widget.charLimit,
                  inputFormatters: widget.inputFormatters,
                  onChanged: onChangedInner,
                  onSubmitted: (String v) {
                    widget.onSubmitted?.call(v);
                    widget.onFieldSubmitted?.call(v);
                  },
                  style: BBType.body(context).copyWith(color: c.textPrimary),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                    hintText: widget.placeholder,
                    hintStyle: BBType.body(
                      context,
                    ).copyWith(color: c.textTertiary),
                  ),
                ),
              ),
              if (widget.iconRight != null) ...<Widget>[
                const SizedBox(width: 10),
                BbIcon(
                  name: widget.iconRight!,
                  size: 18,
                  color: c.textTertiary,
                ),
              ],
              if (widget.trailingAction != null) ...<Widget>[
                const SizedBox(width: 8),
                widget.trailingAction!,
              ],
            ],
          ),
        ),
        if (effectiveError != null ||
            widget.helper != null ||
            widget.charLimit != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    effectiveError ?? widget.helper ?? '',
                    style: BBType.caption(
                      context,
                    ).copyWith(color: hasError ? c.error : c.textTertiary),
                  ),
                ),
                if (widget.charLimit != null)
                  Text(
                    '$_charCount/${widget.charLimit}',
                    style: BBType.caption(context).copyWith(
                      color: c.textTertiary,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
