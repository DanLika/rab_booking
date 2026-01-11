import 'package:flutter/material.dart';
import '../../../../core/theme/gradient_extensions.dart';

/// Premium input field with glow effect for auth screens
class PremiumInputField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  const PremiumInputField({
    super.key,
    required this.controller,
    required this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.focusNode,
    this.autofillHints,
  });

  @override
  State<PremiumInputField> createState() => _PremiumInputFieldState();
}

class _PremiumInputFieldState extends State<PremiumInputField> {
  static const _borderRadius = BorderRadius.all(Radius.circular(12));
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradients = context.gradients;
    final primaryColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurfaceVariant;
    final defaultBorder = BorderSide(
      color: gradients.sectionBorder.withAlpha(128),
    );

    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: _borderRadius,
          boxShadow: _isFocused
              ? [BoxShadow(color: primaryColor.withAlpha(77), blurRadius: 20)]
              : const [],
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          maxLines: widget.maxLines,
          autofillHints: widget.autofillHints,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: widget.labelText,
            labelStyle: TextStyle(
              color: _isFocused ? primaryColor : inactiveColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused ? primaryColor : inactiveColor,
                    size: 20,
                  )
                : null,
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: gradients.inputFillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: _borderRadius,
              borderSide: defaultBorder,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: _borderRadius,
              borderSide: defaultBorder,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: _borderRadius,
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: _borderRadius,
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: _borderRadius,
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
            ),
            // Allow multi-line error messages (e.g., password validation rules)
            errorMaxLines: 3,
          ),
        ),
      ),
    );
  }
}
