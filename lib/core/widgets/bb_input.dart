import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/tokens.dart';

/// Stack: label (above) + field + helper/error (below).
///
/// Generalized from `premium_input_field.dart`. States: default / focus
/// (2px primary border) / error (2px coral border + message) / disabled.
/// Always ≥48 tall. Inline validation: pass [errorText] non-null to flip
/// to error state; null otherwise.
class BBInput extends StatefulWidget {
  const BBInput({
    super.key,
    this.label,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.hintText,
    this.leadingIcon,
    this.trailingIcon,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.showObscureToggle = false,
    this.maxLength,
    this.showCounter = false,
    this.enabled = true,
    this.autofocus = false,
    this.minLines,
    this.maxLines = 1,
    this.focusNode,
  });

  final String? label;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool showObscureToggle;
  final int? maxLength;
  final bool showCounter;
  final bool enabled;
  final bool autofocus;
  final int? minLines;
  final int? maxLines;
  final FocusNode? focusNode;

  @override
  State<BBInput> createState() => _BBInputState();
}

class _BBInputState extends State<BBInput> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _ownsFocus = false;
  bool _ownsController = false;
  bool _focused = false;
  bool _obscured = false;
  int _length = 0;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _ownsFocus = true;
    } else {
      _focusNode = widget.focusNode!;
    }
    if (widget.controller == null) {
      _controller = TextEditingController(text: widget.initialValue);
      _ownsController = true;
    } else {
      _controller = widget.controller!;
    }
    _focusNode.addListener(_handleFocusChange);
    _length = _controller.text.length;
    _obscured = widget.obscureText;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocus) _focusNode.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final bool hasError = widget.errorText != null;
    final bool disabled = !widget.enabled;

    final Color borderColor;
    final double borderWidth;
    if (hasError) {
      borderColor = c.error;
      borderWidth = 2;
    } else if (_focused) {
      borderColor = c.primary;
      borderWidth = 2;
    } else {
      borderColor = c.border;
      borderWidth = 1;
    }

    final Color fillColor = disabled ? c.surfaceVariant : c.surface;

    final Widget? trailing = (() {
      if (widget.showObscureToggle) {
        return IconButton(
          icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
          color: c.textSecondary,
          onPressed: disabled
              ? null
              : () => setState(() => _obscured = !_obscured),
          tooltip: _obscured ? 'Prikaži' : 'Sakrij',
        );
      }
      if (widget.trailingIcon != null) {
        return Icon(widget.trailingIcon, color: c.textSecondary, size: 20);
      }
      return null;
    })();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          Text(widget.label!, style: BBType.label(context)),
          const SizedBox(height: BBSpace.xs),
        ],
        AnimatedContainer(
          duration: BBMotion.adapt(context, BBMotion.fast),
          curve: BBMotion.curve,
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BBRadius.smAll,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: BBSpace.sm,
          ),
          child: Row(
            children: <Widget>[
              if (widget.leadingIcon != null) ...<Widget>[
                Icon(widget.leadingIcon, color: c.textSecondary, size: 20),
                const SizedBox(width: BBSpace.xs),
              ],
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !disabled,
                  obscureText: _obscured,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  inputFormatters: widget.inputFormatters,
                  autofocus: widget.autofocus,
                  minLines: widget.minLines,
                  maxLines: widget.obscureText ? 1 : widget.maxLines,
                  maxLength: widget.maxLength,
                  onChanged: (String v) {
                    setState(() => _length = v.length);
                    widget.onChanged?.call(v);
                  },
                  onSubmitted: widget.onSubmitted,
                  style: BBType.body(context),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: BBSpace.sm - 2,
                    ),
                    hintText: widget.hintText,
                    hintStyle: BBType.body(
                      context,
                    ).copyWith(color: c.textTertiary),
                    counterText:
                        '', // suppress default counter; we render below
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
        if (hasError ||
            widget.helperText != null ||
            widget.showCounter) ...<Widget>[
          const SizedBox(height: BBSpace.xs),
          Row(
            children: <Widget>[
              if (hasError)
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: BBType.caption(context).copyWith(color: c.error),
                  ),
                )
              else if (widget.helperText != null)
                Expanded(
                  child: Text(
                    widget.helperText!,
                    style: BBType.caption(context),
                  ),
                )
              else
                const Spacer(),
              if (widget.showCounter && widget.maxLength != null)
                Text(
                  '$_length / ${widget.maxLength}',
                  style: BBType.caption(context).copyWith(
                    color: c.textTertiary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
