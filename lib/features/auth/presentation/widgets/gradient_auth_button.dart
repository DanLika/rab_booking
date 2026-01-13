import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../../../../l10n/app_localizations.dart';

/// Premium gradient button for auth screens with animations
///
/// Uses flutter_animate for shimmer effect during loading state.
/// Includes Semantics wrapper for screen reader accessibility (A11Y-002).
class GradientAuthButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const GradientAuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<GradientAuthButton> createState() => _GradientAuthButtonState();
}

class _GradientAuthButtonState extends State<GradientAuthButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.onPressed == null && !widget.isLoading;

    Widget buttonContent = Container(
      height: 48,
      decoration: BoxDecoration(
        // Disabled state: gray background, no gradient
        color: isDisabled
            ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
            : null,
        gradient: isDisabled
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.75),
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        // Disabled state: no shadow
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withAlpha(
                    (0.25 * 255).toInt(),
                  ),
                  blurRadius: _isHovered ? 16 : 10,
                  offset: Offset(0, _isHovered ? 6 : 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
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
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: isDisabled
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.38,
                                )
                              : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: AutoSizeText(
                          widget.text,
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDisabled
                                ? theme.colorScheme.onSurface.withValues(
                                    alpha: 0.38,
                                  )
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
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

    final l10n = AppLocalizations.of(context);

    // A11Y-002: Semantics wrapper for screen readers
    return Semantics(
      button: true,
      label: widget.isLoading ? l10n.loading : widget.text,
      enabled: !widget.isLoading && widget.onPressed != null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(
            0.0,
            _isHovered ? -4.0 : 0.0,
            0.0,
          ),
          child: buttonContent,
        ),
      ),
    );
  }
}
