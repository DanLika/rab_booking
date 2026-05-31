import 'package:flutter/material.dart';

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
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
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
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<BbInput> createState() => _BbInputState();
}

class _BbInputState extends State<BbInput> {
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocus);
  late final TextEditingController _ctrl =
      widget.controller ??
      TextEditingController(text: widget.initialValue ?? '');
  bool _focused = false;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _charCount = _ctrl.text.length;
    _ctrl.addListener(_onText);
  }

  void _onFocus() => setState(() => _focused = _focusNode.hasFocus);
  void _onText() => setState(() => _charCount = _ctrl.text.length);

  @override
  void dispose() {
    _ctrl.removeListener(_onText);
    if (widget.controller == null) _ctrl.dispose();
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
    final bool hasError = widget.error != null && widget.error!.isNotEmpty;

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
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: BBType.body(context).copyWith(color: c.textPrimary),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
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
        if (widget.error != null ||
            widget.helper != null ||
            widget.charLimit != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.error ?? widget.helper ?? '',
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
