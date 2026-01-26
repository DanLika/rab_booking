import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

/// Social login button with hover effect and focus state
///
/// Includes Semantics wrapper for screen reader accessibility (A11Y-002).
class SocialLoginButton extends StatefulWidget {
  final IconData? icon;
  final Widget? customIcon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const SocialLoginButton({
    super.key,
    this.icon,
    this.customIcon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  }) : assert(
         icon != null || customIcon != null,
         'Either icon or customIcon must be provided',
       );

  @override
  State<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<SocialLoginButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  // A11Y-002: Visual feedback indicates hover OR focus state (only when enabled)
  bool get _isHighlighted => (_isHovered || _isFocused) && widget.enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // A11Y-002: Semantics wrapper for screen readers
    return Semantics(
      button: true,
      label: widget.label,
      enabled: widget.enabled,
      child: Opacity(
        opacity: widget.enabled ? 1.0 : 0.6,
        child: Focus(
          canRequestFocus: widget.enabled,
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHighlighted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 1.5,
                ),
                color: _isHighlighted
                    ? theme.colorScheme.primary.withAlpha(20)
                    : theme.colorScheme.surfaceContainerHighest.withAlpha(77),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.enabled ? widget.onPressed : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final isNarrow = screenWidth <= 340;

                        final iconWidget = widget.customIcon != null
                            ? widget.customIcon!
                            : Icon(
                                widget.icon,
                                size: 22,
                                color: _isHighlighted
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              );

                        final textWidget = AutoSizeText(
                          widget.label,
                          maxLines: 1,
                          minFontSize: 10,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isHighlighted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        );

                        // Use Column layout on very narrow screens
                        if (isNarrow) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              iconWidget,
                              const SizedBox(height: 4),
                              textWidget,
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            iconWidget,
                            const SizedBox(width: 8),
                            textWidget,
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Google "G" Icon using image asset with circular white background
class GoogleBrandIcon extends StatelessWidget {
  final double size;

  const GoogleBrandIcon({super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/google_icon.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

/// Apple logo icon with circular white background
class AppleBrandIcon extends StatelessWidget {
  final double size;

  const AppleBrandIcon({super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/apple_icon.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
