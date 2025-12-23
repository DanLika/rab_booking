import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/design_tokens/gradient_tokens.dart';

/// Reusable premium gradient button with animations
///
/// Uses flutter_animate for shimmer effect during loading state.
/// Uses GradientTokens.brandPrimary for consistent branding across themes.
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final List<Color>? gradientColors;
  final BorderRadius? borderRadius;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 56,
    this.width,
    this.padding,
    this.gradientColors,
    this.borderRadius,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final gradientColors =
        widget.gradientColors ??
        [GradientTokens.brandPrimaryStart, GradientTokens.brandPrimaryEnd];

    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);

    Widget buttonContent = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withAlpha((0.3 * 255).toInt()),
            blurRadius: _isHovered ? 25 : 15,
            offset: Offset(0, _isHovered ? 8 : 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: borderRadius,
          child: Padding(
            padding:
                widget.padding ?? const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    // Apply shimmer effect when loading
    if (widget.isLoading) {
      buttonContent = buttonContent
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: const Duration(milliseconds: 1500),
            color: Colors.white.withAlpha((0.3 * 255).toInt()),
          );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        child: buttonContent,
      ),
    );
  }
}
