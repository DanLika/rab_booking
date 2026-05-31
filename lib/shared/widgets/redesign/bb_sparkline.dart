import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// Trend chart (handoff [BBSparkline]).
///
/// Renders a smooth path + tinted area under the line and a final-point dot.
/// Color defaults to brand primary with 16% alpha fill.
class BbSparkline extends StatelessWidget {
  const BbSparkline({
    super.key,
    required this.data,
    this.width = 280,
    this.height = 64,
    this.color,
    this.fillColor,
    this.showDot = true,
    this.strokeWidth = 2,
  });

  final List<double> data;
  final double width;
  final double height;
  final Color? color;
  final Color? fillColor;
  final bool showDot;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(width: width, height: height);
    final BBColorSet c = BBColor.of(context);
    final Color line = color ?? c.primary;
    final Color fill = fillColor ?? c.primary.withValues(alpha: 0.16);
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          data: data,
          line: line,
          fill: fill,
          showDot: showDot,
          strokeWidth: strokeWidth,
          dotBg: c.surface,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.line,
    required this.fill,
    required this.showDot,
    required this.strokeWidth,
    required this.dotBg,
  });

  final List<double> data;
  final Color line;
  final Color fill;
  final bool showDot;
  final double strokeWidth;
  final Color dotBg;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const double pad = 6;
    final double w = size.width - pad * 2;
    final double h = size.height - pad * 2;
    double minV = data.first, maxV = data.first;
    for (final double v in data) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final double range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final List<Offset> pts = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final double x = pad + (data.length == 1 ? 0 : i / (data.length - 1) * w);
      final double y = pad + (1 - (data[i] - minV) / range) * h;
      pts.add(Offset(x, y));
    }
    final Path linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      linePath.lineTo(pts[i].dx, pts[i].dy);
    }
    final Path area = Path.from(linePath)
      ..lineTo(pts.last.dx, size.height - pad)
      ..lineTo(pts.first.dx, size.height - pad)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = line
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (showDot) {
      canvas.drawCircle(pts.last, 4, Paint()..color = line);
      canvas.drawCircle(
        pts.last,
        4,
        Paint()
          ..color = dotBg
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.data != data ||
      old.line != line ||
      old.fill != fill ||
      old.showDot != showDot ||
      old.strokeWidth != strokeWidth;
}
