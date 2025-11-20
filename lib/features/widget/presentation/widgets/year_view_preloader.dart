import 'package:flutter/material.dart';

/// Custom preloader for year view calendar
/// Shows pulsing logo with circular loading indicator
/// Black/white theme (no bright colors) for professional look
class YearViewPreloader extends StatefulWidget {
  final int year;

  const YearViewPreloader({
    super.key,
    required this.year,
  });

  @override
  State<YearViewPreloader> createState() => _YearViewPreloaderState();
}

class _YearViewPreloaderState extends State<YearViewPreloader>
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

    // Subtle pulse animation (1.0 to 1.05)
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Glow animation for subtle shadow effect
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulsing logo with circular loading indicator
          Stack(
            alignment: Alignment.center,
            children: [
              // Circular loading indicator (rotating around logo)
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black.withOpacity(0.7),
                  backgroundColor: Colors.black.withOpacity(0.1),
                ),
              ),

              // Pulsing logo in center
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Subtle shadow glow
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: _glowAnimation.value * 0.2,
                            ),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _BlackLogoPainter(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Loading message
          Text(
            'Loading calendar for ${widget.year}...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 8),

          // Subtle hint text
          Text(
            'Please wait',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.5),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for black logo (villa + waves)
/// Same design as AuthLogoIcon but in pure black
class _BlackLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Black outer circle badge
    final circlePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, circlePaint);

    // Draw waves (bottom third)
    _drawWaves(canvas, size);

    // Draw villa roof (top third)
    _drawVillaRoof(canvas, size);
  }

  void _drawWaves(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Three flowing wave lines (bottom third of badge)
    final baseY = size.height * 0.65;

    // Wave 1 (bottom)
    final wave1 = Path();
    wave1.moveTo(size.width * 0.25, baseY + 10);
    wave1.quadraticBezierTo(
      size.width * 0.37,
      baseY + 5,
      size.width * 0.5,
      baseY + 10,
    );
    wave1.quadraticBezierTo(
      size.width * 0.63,
      baseY + 15,
      size.width * 0.75,
      baseY + 10,
    );
    canvas.drawPath(wave1, wavePaint);

    // Wave 2 (middle)
    final wave2 = Path();
    wave2.moveTo(size.width * 0.25, baseY - 5);
    wave2.quadraticBezierTo(
      size.width * 0.37,
      baseY - 10,
      size.width * 0.5,
      baseY - 5,
    );
    wave2.quadraticBezierTo(
      size.width * 0.63,
      baseY,
      size.width * 0.75,
      baseY - 5,
    );
    canvas.drawPath(wave2, wavePaint);

    // Wave 3 (top)
    final wave3 = Path();
    wave3.moveTo(size.width * 0.25, baseY - 20);
    wave3.quadraticBezierTo(
      size.width * 0.37,
      baseY - 25,
      size.width * 0.5,
      baseY - 20,
    );
    wave3.quadraticBezierTo(
      size.width * 0.63,
      baseY - 15,
      size.width * 0.75,
      baseY - 20,
    );
    canvas.drawPath(wave3, wavePaint);
  }

  void _drawVillaRoof(Canvas canvas, Size size) {
    final roofPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Modern geometric villa roof (top third of badge)
    final roofPath = Path();

    // Main roof triangle
    roofPath.moveTo(size.width * 0.5, size.height * 0.28); // Peak
    roofPath.lineTo(size.width * 0.7, size.height * 0.42); // Right
    roofPath.lineTo(size.width * 0.3, size.height * 0.42); // Left
    roofPath.close();

    // Fill with subtle black gradient
    canvas.drawPath(roofPath, fillPaint);
    canvas.drawPath(roofPath, roofPaint);

    // Simple villa structure lines
    final structurePaint = Paint()
      ..color = Colors.black
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
  bool shouldRepaint(_BlackLogoPainter oldDelegate) => false;
}
