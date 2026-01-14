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

/// Google "G" Icon with proper brand colors
class GoogleBrandIcon extends StatelessWidget {
  final double size;

  const GoogleBrandIcon({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.45;
    final innerRadius = size.width * 0.30;
    final strokeWidth = outerRadius - innerRadius;
    final arcRadius = (outerRadius + innerRadius) / 2;
    final arcRect = Rect.fromCircle(center: center, radius: arcRadius);

    // Blue arc (top-right quadrant)
    canvas.drawArc(
      arcRect,
      -1.5708, // -π/2
      1.5708, // π/2
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt,
    );

    // Green arc
    canvas.drawArc(
      arcRect,
      0.0,
      1.1,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Yellow arc
    canvas.drawArc(
      arcRect,
      1.5708, // π/2
      1.5708,
      false,
      Paint()
        ..color = const Color(0xFFFBBC04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Red arc
    canvas.drawArc(
      arcRect,
      3.1416, // π
      1.37,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Blue bar (horizontal)
    final barWidth = outerRadius * 0.85;
    final barHeight = strokeWidth * 0.6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + barWidth / 4, center.dy),
          width: barWidth,
          height: barHeight,
        ),
        Radius.circular(barHeight / 2),
      ),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Apple logo icon that adapts to theme
class AppleBrandIcon extends StatelessWidget {
  final double size;

  const AppleBrandIcon({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppleLogoPainter(color: theme.colorScheme.onSurface),
      ),
    );
  }
}

class _AppleLogoPainter extends CustomPainter {
  final Color color;

  const _AppleLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 24;
    final centerX = size.width / 2;
    final centerY = size.height / 2 + scale;

    // Apple body
    final path = Path()
      ..moveTo(centerX, centerY - 7 * scale)
      ..cubicTo(
        centerX + 6 * scale,
        centerY - 7 * scale,
        centerX + 8 * scale,
        centerY - 4 * scale,
        centerX + 8 * scale,
        centerY + 2 * scale,
      )
      ..cubicTo(
        centerX + 8 * scale,
        centerY + 6 * scale,
        centerX + 5 * scale,
        centerY + 8 * scale,
        centerX,
        centerY + 8 * scale,
      )
      ..cubicTo(
        centerX - 5 * scale,
        centerY + 8 * scale,
        centerX - 8 * scale,
        centerY + 6 * scale,
        centerX - 8 * scale,
        centerY + 2 * scale,
      )
      ..cubicTo(
        centerX - 8 * scale,
        centerY - 4 * scale,
        centerX - 6 * scale,
        centerY - 7 * scale,
        centerX,
        centerY - 7 * scale,
      )
      ..close();

    // Bite cutout
    final bitePath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(centerX + 5 * scale, centerY - 3 * scale),
          radius: 2.5 * scale,
        ),
      );

    final applePath = Path.combine(PathOperation.difference, path, bitePath);
    canvas.drawPath(applePath, paint);

    // Leaf
    final leafPath = Path()
      ..moveTo(centerX + scale, centerY - 7 * scale)
      ..cubicTo(
        centerX + 2 * scale,
        centerY - 9 * scale,
        centerX + 4 * scale,
        centerY - 10 * scale,
        centerX + 5 * scale,
        centerY - 10 * scale,
      )
      ..cubicTo(
        centerX + 4 * scale,
        centerY - 9.5 * scale,
        centerX + 3 * scale,
        centerY - 8.5 * scale,
        centerX + scale,
        centerY - 7 * scale,
      )
      ..close();

    canvas.drawPath(leafPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
