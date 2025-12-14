import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Custom animated logo icon for auth screens
/// Combines house + key with gradient and pulse animation
class AuthLogoIcon extends StatefulWidget {
  final double size;
  final bool isWhite;

  /// If true, uses minimalistic black/white colors (for preloader)
  /// If false, uses brand purple colors (for login/register pages)
  final bool useMinimalistic;

  const AuthLogoIcon({super.key, this.size = 100, this.isWhite = false, this.useMinimalistic = false});

  @override
  State<AuthLogoIcon> createState() => _AuthLogoIconState();
}

class _AuthLogoIconState extends State<AuthLogoIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Determine logo color based on mode
    final Color logoColor;
    if (widget.useMinimalistic) {
      // Minimalistic: Use black in light mode, white in dark mode (for preloader)
      logoColor = widget.isWhite ? Colors.white : (isDarkMode ? Colors.white : Colors.black);
    } else {
      // Colorized: Use brand purple colors (for login/register pages)
      logoColor = widget.isWhite ? Colors.white : (isDarkMode ? AppColors.primaryLight : AppColors.primary);
    }

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
                  color: logoColor.withAlpha(((_glowAnimation.value * 255 * 0.25).toInt())),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _LogoPainter(
                isWhite: widget.isWhite,
                isDarkMode: isDarkMode,
                useMinimalistic: widget.useMinimalistic,
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
  final bool isDarkMode;
  final bool useMinimalistic;

  _LogoPainter({this.isWhite = false, required this.isDarkMode, this.useMinimalistic = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Defensive check: ensure size is valid before painting
    if (!size.width.isFinite || !size.height.isFinite || size.width <= 0 || size.height <= 0) {
      return; // Skip painting if size is invalid
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Determine logo color based on mode
    final Color logoColor;
    if (useMinimalistic) {
      // Minimalistic: Use black in light mode, white in dark mode (for preloader)
      logoColor = isWhite ? Colors.white : (isDarkMode ? Colors.white : Colors.black);
    } else {
      // Colorized: Use brand purple colors (for login/register pages)
      logoColor = isWhite ? Colors.white : (isDarkMode ? AppColors.primaryLight : AppColors.primary);
    }

    // Outer circle badge
    final circlePaint = Paint()
      ..color = logoColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, circlePaint);

    // Wave elements (representing sea/destination)
    _drawWaves(canvas, size, logoColor);

    // Villa roof silhouette (representing accommodation)
    _drawVillaRoof(canvas, size, logoColor);
  }

  void _drawWaves(Canvas canvas, Size size, Color logoColor) {
    final wavePaint = Paint()
      ..color = logoColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Three flowing wave lines (bottom third of badge)
    final baseY = size.height * 0.65;

    // Wave 1 (bottom)
    final wave1 = Path();
    wave1.moveTo(size.width * 0.25, baseY + 10);
    wave1.quadraticBezierTo(size.width * 0.37, baseY + 5, size.width * 0.5, baseY + 10);
    wave1.quadraticBezierTo(size.width * 0.63, baseY + 15, size.width * 0.75, baseY + 10);
    canvas.drawPath(wave1, wavePaint);

    // Wave 2 (middle)
    final wave2 = Path();
    wave2.moveTo(size.width * 0.25, baseY - 5);
    wave2.quadraticBezierTo(size.width * 0.37, baseY - 10, size.width * 0.5, baseY - 5);
    wave2.quadraticBezierTo(size.width * 0.63, baseY, size.width * 0.75, baseY - 5);
    canvas.drawPath(wave2, wavePaint);

    // Wave 3 (top)
    final wave3 = Path();
    wave3.moveTo(size.width * 0.25, baseY - 20);
    wave3.quadraticBezierTo(size.width * 0.37, baseY - 25, size.width * 0.5, baseY - 20);
    wave3.quadraticBezierTo(size.width * 0.63, baseY - 15, size.width * 0.75, baseY - 20);
    canvas.drawPath(wave3, wavePaint);
  }

  void _drawVillaRoof(Canvas canvas, Size size, Color logoColor) {
    final roofPaint = Paint()
      ..color = logoColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = logoColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

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
      ..color = logoColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

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
