import 'package:flutter/material.dart';

/// Custom animated logo icon for auth screens
/// Combines house + key with gradient and pulse animation
class AuthLogoIcon extends StatefulWidget {
  final double size;
  final bool isWhite;

  const AuthLogoIcon({
    super.key,
    this.size = 100,
    this.isWhite = false,
  });

  @override
  State<AuthLogoIcon> createState() => _AuthLogoIconState();
}

class _AuthLogoIconState extends State<AuthLogoIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.isWhite
                      ? Colors.white.withAlpha(((_glowAnimation.value * 255 * 0.3).toInt()))
                      : theme.colorScheme.primary.withAlpha(((_glowAnimation.value * 255 * 0.25).toInt())),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _LogoPainter(
                isWhite: widget.isWhite,
                primaryColor: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LogoPainter extends CustomPainter {
  final bool isWhite;
  final Color primaryColor;

  _LogoPainter({
    this.isWhite = false,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Defensive check: ensure size is valid before painting
    if (!size.width.isFinite || !size.height.isFinite || 
        size.width <= 0 || size.height <= 0) {
      return; // Skip painting if size is invalid
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Gradient or white shader (theme-aware purple-fade)
    // Defensive check: ensure size is valid before creating shader
    Shader? shader;
    if (!isWhite) {
      try {
        final rect = Rect.fromLTWH(0, 0, size.width, size.height);
        // Ensure rect is valid (width and height are positive and finite)
        if (rect.width > 0 && rect.height > 0 && 
            rect.width.isFinite && rect.height.isFinite) {
          shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              primaryColor.withValues(alpha: 0.7),
            ],
          ).createShader(rect);
        }
      } catch (e) {
        // If shader creation fails, continue without shader
        shader = null;
      }
    }

    // Outer circle badge
    final circlePaint = Paint()
      ..color = isWhite ? Colors.white : primaryColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // If not white, add gradient shader
    if (!isWhite && shader != null) {
      circlePaint.shader = shader;
    }

    canvas.drawCircle(center, radius, circlePaint);

    // Wave elements (representing sea/destination)
    _drawWaves(canvas, size, shader);

    // Villa roof silhouette (representing accommodation)
    _drawVillaRoof(canvas, size, shader);
  }

  void _drawWaves(Canvas canvas, Size size, Shader? shader) {
    final wavePaint = Paint()
      ..color = isWhite ? Colors.white : primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Apply gradient shader if not white
    if (!isWhite && shader != null) {
      wavePaint.shader = shader;
    }

    // Three flowing wave lines (bottom third of badge)
    final baseY = size.height * 0.65;

    // Wave 1 (bottom)
    final wave1 = Path();
    wave1.moveTo(size.width * 0.25, baseY + 10);
    wave1.quadraticBezierTo(
      size.width * 0.37, baseY + 5,
      size.width * 0.5, baseY + 10,
    );
    wave1.quadraticBezierTo(
      size.width * 0.63, baseY + 15,
      size.width * 0.75, baseY + 10,
    );
    canvas.drawPath(wave1, wavePaint);

    // Wave 2 (middle)
    final wave2 = Path();
    wave2.moveTo(size.width * 0.25, baseY - 5);
    wave2.quadraticBezierTo(
      size.width * 0.37, baseY - 10,
      size.width * 0.5, baseY - 5,
    );
    wave2.quadraticBezierTo(
      size.width * 0.63, baseY,
      size.width * 0.75, baseY - 5,
    );
    canvas.drawPath(wave2, wavePaint);

    // Wave 3 (top)
    final wave3 = Path();
    wave3.moveTo(size.width * 0.25, baseY - 20);
    wave3.quadraticBezierTo(
      size.width * 0.37, baseY - 25,
      size.width * 0.5, baseY - 20,
    );
    wave3.quadraticBezierTo(
      size.width * 0.63, baseY - 15,
      size.width * 0.75, baseY - 20,
    );
    canvas.drawPath(wave3, wavePaint);
  }

  void _drawVillaRoof(Canvas canvas, Size size, Shader? shader) {
    final roofPaint = Paint()
      ..color = isWhite ? Colors.white : primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Apply gradient shader if not white
    if (!isWhite && shader != null) {
      roofPaint.shader = shader;
    }

    final fillPaint = Paint()
      ..color = isWhite
          ? Colors.white.withValues(alpha: 0.2)
          : primaryColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Apply gradient shader for fill if not white
    if (!isWhite && shader != null) {
      fillPaint.shader = shader;
    }

    // Modern geometric villa roof (top third of badge)
    final roofPath = Path();

    // Main roof triangle
    roofPath.moveTo(size.width * 0.5, size.height * 0.28); // Peak
    roofPath.lineTo(size.width * 0.7, size.height * 0.42); // Right
    roofPath.lineTo(size.width * 0.3, size.height * 0.42); // Left
    roofPath.close();

    // Fill with subtle gradient
    canvas.drawPath(roofPath, fillPaint);
    canvas.drawPath(roofPath, roofPaint);

    // Simple villa structure lines
    final structurePaint = Paint()
      ..color = isWhite ? Colors.white : primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Apply gradient shader if not white
    if (!isWhite && shader != null) {
      structurePaint.shader = shader;
    }

    // Two vertical lines suggesting building
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.42),
      Offset(size.width * 0.4, size.height * 0.52),
      structurePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.42),
      Offset(size.width * 0.6, size.height * 0.52),
      structurePaint,
    );

    // Horizontal base line
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.52),
      Offset(size.width * 0.7, size.height * 0.52),
      structurePaint,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}
