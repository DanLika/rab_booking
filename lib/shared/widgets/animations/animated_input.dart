import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Animated text field with floating label and border glow
/// Features: Label floats up on focus, border glows, smooth transitions
class AnimatedTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int? maxLines;
  final bool enabled;
  final Color? focusColor;
  final Color? borderColor;

  const AnimatedTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
    this.focusColor,
    this.borderColor,
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _labelAnimation;
  late Animation<double> _borderAnimation;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _labelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _borderAnimation = Tween<double>(
      begin: 1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _focusNode.addListener(_onFocusChange);
    widget.controller?.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller?.removeListener(_onTextChange);
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _controller.forward();
    } else if (!_hasText) {
      _controller.reverse();
    }
  }

  void _onTextChange() {
    final hasText = (widget.controller?.text.isNotEmpty ?? false);
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
      if (_hasText && !_isFocused) {
        _controller.forward();
      } else if (!_hasText && !_isFocused) {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final focusColor = widget.focusColor ?? AppColors.authPrimary;
    final borderColor =
        widget.borderColor ??
        (isDark ? AppColors.borderDark : AppColors.borderLight);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floating label
            if (widget.label != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppDimensions.spaceS,
                  bottom: AppDimensions.spaceXS,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 12 + (2 * (1 - _labelAnimation.value)),
                    color: _isFocused
                        ? focusColor
                        : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Text(widget.label!),
                ),
              ),

            // Text field with glow
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: focusColor.withOpacity(0.2),
                          blurRadius: 8 * _borderAnimation.value,
                        ),
                      ]
                    : null,
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                obscureText: widget.obscureText,
                validator: widget.validator,
                onChanged: widget.onChanged,
                onFieldSubmitted: widget.onSubmitted,
                maxLines: widget.maxLines,
                enabled: widget.enabled,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: widget.suffixIcon,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: BorderSide(
                      color: focusColor,
                      width: _borderAnimation.value,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Search field with animated search icon and clear button
class AnimatedSearchField extends StatefulWidget {
  final String? hint;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;

  const AnimatedSearchField({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  State<AnimatedSearchField> createState() => _AnimatedSearchFieldState();
}

class _AnimatedSearchFieldState extends State<AnimatedSearchField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconRotation;
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _iconRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    widget.controller?.addListener(_onTextChange);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChange);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.forward();
    } else if (!_hasText) {
      _controller.reverse();
    }
  }

  void _onTextChange() {
    final hasText = (widget.controller?.text.isNotEmpty ?? false);
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleClear() {
    widget.controller?.clear();
    widget.onClear?.call();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hint ?? 'Search...',
        prefixIcon: AnimatedBuilder(
          animation: _iconRotation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _iconRotation.value * 3.14159 * 2,
              child: const Icon(Icons.search),
            );
          },
        ),
        suffixIcon: _hasText
            ? IconButton(icon: const Icon(Icons.clear), onPressed: _handleClear)
            : null,
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceL,
          vertical: AppDimensions.spaceM,
        ),
      ),
    );
  }
}

/// Animated textarea with character counter
class AnimatedTextArea extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const AnimatedTextArea({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.maxLength,
    this.minLines = 3,
    this.maxLines = 6,
    this.validator,
    this.onChanged,
  });

  @override
  State<AnimatedTextArea> createState() => _AnimatedTextAreaState();
}

class _AnimatedTextAreaState extends State<AnimatedTextArea> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller?.addListener(_onTextChange);
    _currentLength = widget.controller?.text.length ?? 0;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller?.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChange() {
    setState(() {
      _currentLength = widget.controller?.text.length ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final focusColor = AppColors.authPrimary;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppDimensions.spaceS,
              bottom: AppDimensions.spaceXS,
            ),
            child: Text(
              widget.label!,
              style: TextStyle(
                fontSize: 12,
                color: _isFocused
                    ? focusColor
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),

        // Text area
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: focusColor.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            validator: widget.validator,
            onChanged: widget.onChanged,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) {
                  return null; // Hide default counter
                },
            decoration: InputDecoration(
              hintText: widget.hint,
              filled: true,
              fillColor: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: BorderSide(color: focusColor, width: 2),
              ),
            ),
          ),
        ),

        // Character counter
        if (widget.maxLength != null)
          Padding(
            padding: const EdgeInsets.only(
              top: AppDimensions.spaceXS,
              right: AppDimensions.spaceS,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$_currentLength / ${widget.maxLength}',
                style: TextStyle(
                  fontSize: 12,
                  color: _currentLength > widget.maxLength!
                      ? AppColors.error
                      : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
