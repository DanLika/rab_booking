import 'package:flutter/material.dart';

/// Minimalist line art icons for auth background
/// Includes houses, hotels, apartments, and keys

class LineArtIcon extends StatelessWidget {
  final LineArtIconType type;
  final double size;
  final Color color;
  final double strokeWidth;

  const LineArtIcon({
    super.key,
    required this.type,
    this.size = 20,
    this.color = const Color(0xFF2C2C2C),
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LineArtPainter(
          type: type,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

enum LineArtIconType {
  house,
  villa,
  hotel,
  apartment,
  building,
  key,
  keyCard,
  doorKey,
}

class _LineArtPainter extends CustomPainter {
  final LineArtIconType type;
  final Color color;
  final double strokeWidth;

  _LineArtPainter({
    required this.type,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (type) {
      case LineArtIconType.house:
        _drawHouse(canvas, size, paint);
      case LineArtIconType.villa:
        _drawVilla(canvas, size, paint);
      case LineArtIconType.hotel:
        _drawHotel(canvas, size, paint);
      case LineArtIconType.apartment:
        _drawApartment(canvas, size, paint);
      case LineArtIconType.building:
        _drawBuilding(canvas, size, paint);
      case LineArtIconType.key:
        _drawKey(canvas, size, paint);
      case LineArtIconType.keyCard:
        _drawKeyCard(canvas, size, paint);
      case LineArtIconType.doorKey:
        _drawDoorKey(canvas, size, paint);
    }
  }

  void _drawHouse(Canvas canvas, Size size, Paint paint) {
    final path = Path();

    // Roof
    path.moveTo(size.width * 0.5, size.height * 0.1);
    path.lineTo(size.width * 0.9, size.height * 0.45);
    path.lineTo(size.width * 0.1, size.height * 0.45);
    path.close();

    // House body
    path.moveTo(size.width * 0.2, size.height * 0.45);
    path.lineTo(size.width * 0.2, size.height * 0.9);
    path.lineTo(size.width * 0.8, size.height * 0.9);
    path.lineTo(size.width * 0.8, size.height * 0.45);

    // Door
    path.moveTo(size.width * 0.4, size.height * 0.9);
    path.lineTo(size.width * 0.4, size.height * 0.65);
    path.lineTo(size.width * 0.6, size.height * 0.65);
    path.lineTo(size.width * 0.6, size.height * 0.9);

    canvas.drawPath(path, paint);
  }

  void _drawVilla(Canvas canvas, Size size, Paint paint) {
    final path = Path();

    // Main roof
    path.moveTo(size.width * 0.5, size.height * 0.05);
    path.lineTo(size.width * 0.95, size.height * 0.4);
    path.lineTo(size.width * 0.05, size.height * 0.4);
    path.close();

    // Left wing
    path.moveTo(size.width * 0.15, size.height * 0.4);
    path.lineTo(size.width * 0.15, size.height * 0.75);
    path.lineTo(size.width * 0.45, size.height * 0.75);
    path.lineTo(size.width * 0.45, size.height * 0.4);

    // Right wing
    path.moveTo(size.width * 0.55, size.height * 0.4);
    path.lineTo(size.width * 0.55, size.height * 0.75);
    path.lineTo(size.width * 0.85, size.height * 0.75);
    path.lineTo(size.width * 0.85, size.height * 0.4);

    // Base
    path.moveTo(size.width * 0.1, size.height * 0.75);
    path.lineTo(size.width * 0.1, size.height * 0.95);
    path.lineTo(size.width * 0.9, size.height * 0.95);
    path.lineTo(size.width * 0.9, size.height * 0.75);

    canvas.drawPath(path, paint);
  }

  void _drawHotel(Canvas canvas, Size size, Paint paint) {
    final path = Path();

    // Building outline
    path.moveTo(size.width * 0.2, size.height * 0.1);
    path.lineTo(size.width * 0.8, size.height * 0.1);
    path.lineTo(size.width * 0.8, size.height * 0.9);
    path.lineTo(size.width * 0.2, size.height * 0.9);
    path.close();

    // Windows (3 floors, 2 windows each)
    for (int floor = 0; floor < 3; floor++) {
      for (int window = 0; window < 2; window++) {
        final x = size.width * (0.3 + window * 0.25);
        final y = size.height * (0.25 + floor * 0.2);
        path.addRect(
          Rect.fromLTWH(x, y, size.width * 0.15, size.height * 0.12),
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawApartment(Canvas canvas, Size size, Paint paint) {
    final path = Path();

    // Building
    path.moveTo(size.width * 0.15, size.height * 0.2);
    path.lineTo(size.width * 0.85, size.height * 0.2);
    path.lineTo(size.width * 0.85, size.height * 0.95);
    path.lineTo(size.width * 0.15, size.height * 0.95);
    path.close();

    // Balcony
    path.moveTo(size.width * 0.3, size.height * 0.5);
    path.lineTo(size.width * 0.3, size.height * 0.65);
    path.lineTo(size.width * 0.7, size.height * 0.65);
    path.lineTo(size.width * 0.7, size.height * 0.5);

    // Windows
    path.addRect(
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.3,
        size.width * 0.3,
        size.height * 0.15,
      ),
    );

    canvas.drawPath(path, paint);
  }

  void _drawBuilding(Canvas canvas, Size size, Paint paint) {
    final path = Path();

    // Main building
    path.moveTo(size.width * 0.25, size.height * 0.15);
    path.lineTo(size.width * 0.75, size.height * 0.15);
    path.lineTo(size.width * 0.75, size.height * 0.9);
    path.lineTo(size.width * 0.25, size.height * 0.9);
    path.close();

    // Grid of windows
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 2; col++) {
        final x = size.width * (0.32 + col * 0.2);
        final y = size.height * (0.25 + row * 0.15);
        path.addRect(
          Rect.fromLTWH(x, y, size.width * 0.12, size.height * 0.08),
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawKey(Canvas canvas, Size size, Paint paint) {
    final path = Path();

    // Key head (circle)
    path.addOval(
      Rect.fromCircle(
        center: Offset(size.width * 0.25, size.height * 0.5),
        radius: size.width * 0.15,
      ),
    );

    // Key shaft
    path.moveTo(size.width * 0.4, size.height * 0.5);
    path.lineTo(size.width * 0.85, size.height * 0.5);

    // Key teeth
    path.moveTo(size.width * 0.7, size.height * 0.5);
    path.lineTo(size.width * 0.7, size.height * 0.65);
    path.moveTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width * 0.8, size.height * 0.7);

    canvas.drawPath(path, paint);
  }

  void _drawKeyCard(Canvas canvas, Size size, Paint paint) {
    final path = Path();

    // Card outline
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.15,
        size.height * 0.25,
        size.width * 0.7,
        size.height * 0.5,
      ),
      Radius.circular(size.width * 0.05),
    );
    path.addRRect(rrect);

    // Magnetic stripe
    path.addRect(
      Rect.fromLTWH(
        size.width * 0.15,
        size.height * 0.35,
        size.width * 0.7,
        size.height * 0.1,
      ),
    );

    // Chip
    path.addRect(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.55,
        size.width * 0.15,
        size.height * 0.12,
      ),
    );

    canvas.drawPath(path, paint);
  }

  void _drawDoorKey(Canvas canvas, Size size, Paint paint) {
    final path = Path();

    // Key head (rounded rectangle)
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.1,
          size.height * 0.3,
          size.width * 0.25,
          size.height * 0.4,
        ),
        Radius.circular(size.width * 0.05),
      ),
    );

    // Hole in head
    path.addOval(
      Rect.fromCircle(
        center: Offset(size.width * 0.225, size.height * 0.5),
        radius: size.width * 0.05,
      ),
    );

    // Key shaft
    path.moveTo(size.width * 0.35, size.height * 0.5);
    path.lineTo(size.width * 0.75, size.height * 0.5);

    // Key teeth (zigzag)
    path.moveTo(size.width * 0.75, size.height * 0.45);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width * 0.75, size.height * 0.55);
    path.lineTo(size.width * 0.85, size.height * 0.6);
    path.lineTo(size.width * 0.9, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LineArtPainter oldDelegate) => false;
}
