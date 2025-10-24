import 'package:flutter/material.dart';
import '../../domain/models/calendar_day.dart';

/// Custom painter for split-day calendar cells
/// Draws triangles for check-in (bottom-right) and check-out (top-left) days
class SplitDayPainter extends CustomPainter {
  final DayStatus status;
  final bool isSelected;
  final bool isToday;

  SplitDayPainter({
    required this.status,
    this.isSelected = false,
    this.isToday = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    switch (status) {
      case DayStatus.available:
        _paintAvailable(canvas, size, paint);
        break;
      case DayStatus.booked:
        _paintBooked(canvas, size, paint);
        break;
      case DayStatus.checkIn:
        _paintCheckIn(canvas, size, paint);
        break;
      case DayStatus.checkOut:
        _paintCheckOut(canvas, size, paint);
        break;
      case DayStatus.sameDayTurnover:
        _paintSameDayTurnover(canvas, size, paint);
        break;
      case DayStatus.blocked:
        _paintBlocked(canvas, size, paint);
        break;
    }

    // Draw selection indicator
    if (isSelected) {
      _paintSelection(canvas, size);
    }

    // Draw today indicator
    if (isToday) {
      _paintTodayIndicator(canvas, size);
    }
  }

  /// Paint available day (gray background)
  void _paintAvailable(Canvas canvas, Size size, Paint paint) {
    paint.color = const Color(0xFF9CA3AF); // Gray
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  /// Paint fully booked day (blue-gray background)
  void _paintBooked(Canvas canvas, Size size, Paint paint) {
    paint.color = const Color(0xFF64748B); // Blue-Gray
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  /// Paint check-in day (gray background + bottom-right red triangle)
  void _paintCheckIn(Canvas canvas, Size size, Paint paint) {
    // Gray background
    paint.color = const Color(0xFF9CA3AF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Bottom-right red triangle (EXACTLY per specification)
    // Vertices: (cellWidth, cellHeight), (cellWidth, cellHeight/2), (cellWidth/2, cellHeight)
    paint.color = const Color(0xFFEF4444); // Red
    final path = Path()
      ..moveTo(size.width, size.height)          // Bottom-right corner
      ..lineTo(size.width, size.height / 2)      // Middle-right
      ..lineTo(size.width / 2, size.height)      // Middle-bottom
      ..close();

    canvas.drawPath(path, paint);

    // 0.5px transparent gap (diagonal line from top-left to bottom-right of triangle)
    final gapPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width / 2, size.height),  // Start: middle-bottom
      Offset(size.width, size.height / 2),  // End: middle-right
      gapPaint,
    );
  }

  /// Paint check-out day (gray background + top-left red triangle)
  void _paintCheckOut(Canvas canvas, Size size, Paint paint) {
    // Gray background
    paint.color = const Color(0xFF9CA3AF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Top-left red triangle (EXACTLY per specification)
    // Vertices: (0, 0), (cellWidth/2, 0), (0, cellHeight/2)
    paint.color = const Color(0xFFEF4444); // Red
    final path = Path()
      ..moveTo(0, 0)                    // Top-left corner
      ..lineTo(size.width / 2, 0)       // Middle-top
      ..lineTo(0, size.height / 2)      // Middle-left
      ..close();

    canvas.drawPath(path, paint);

    // 0.5px transparent gap (diagonal line from top-left to bottom-right of triangle)
    final gapPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height / 2),       // Start: middle-left
      Offset(size.width / 2, 0),        // End: middle-top
      gapPaint,
    );
  }

  /// Paint same-day turnover (gray background + BOTH triangles)
  /// Check-out in morning (top-left) + Check-in in evening (bottom-right)
  void _paintSameDayTurnover(Canvas canvas, Size size, Paint paint) {
    // Gray background
    paint.color = const Color(0xFF9CA3AF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Top-left red triangle (check-out - guest leaves at 10:00 AM)
    paint.color = const Color(0xFFEF4444); // Red
    final checkOutPath = Path()
      ..moveTo(0, 0)                    // Top-left corner
      ..lineTo(size.width / 2, 0)       // Middle-top
      ..lineTo(0, size.height / 2)      // Middle-left
      ..close();
    canvas.drawPath(checkOutPath, paint);

    // Bottom-right red triangle (check-in - guest arrives at 15:00 PM)
    final checkInPath = Path()
      ..moveTo(size.width, size.height)          // Bottom-right corner
      ..lineTo(size.width, size.height / 2)      // Middle-right
      ..lineTo(size.width / 2, size.height)      // Middle-bottom
      ..close();
    canvas.drawPath(checkInPath, paint);

    // 0.5px transparent gap (diagonal line separating the two triangles)
    final gapPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Diagonal line from top-left triangle edge to bottom-right triangle edge
    canvas.drawLine(
      Offset(0, size.height / 2),       // Middle-left (end of check-out triangle)
      Offset(size.width, size.height / 2), // Middle-right (start of check-in triangle)
      gapPaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),        // Middle-top (end of check-out triangle)
      Offset(size.width / 2, size.height), // Middle-bottom (start of check-in triangle)
      gapPaint,
    );
  }

  /// Paint blocked day (dark gray + X pattern)
  void _paintBlocked(Canvas canvas, Size size, Paint paint) {
    // Dark gray background
    paint.color = const Color(0xFF4B5563);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw X pattern
    final xPaint = Paint()
      ..color = const Color(0xFFEF4444).withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Diagonal line from top-left to bottom-right
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, size.height),
      xPaint,
    );

    // Diagonal line from top-right to bottom-left
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      xPaint,
    );
  }

  /// Paint selection border (blue outline)
  void _paintSelection(Canvas canvas, Size size) {
    final selectionPaint = Paint()
      ..color = const Color(0xFF3B82F6) // Blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      selectionPaint,
    );
  }

  /// Paint today indicator (small dot at bottom)
  void _paintTodayIndicator(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFF3B82F6) // Blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height - 4),
      3,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SplitDayPainter oldDelegate) {
    return oldDelegate.status != status ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isToday != isToday;
  }
}

/// Widget wrapper for split-day calendar cell with animations
class SplitDayCell extends StatefulWidget {
  final DateTime date;
  final DayStatus status;
  final bool isSelected;
  final bool isToday;
  final VoidCallback? onTap;
  final String? checkInTime;
  final String? checkOutTime;
  final bool isNewBooking; // For real-time pulse animation

  const SplitDayCell({
    super.key,
    required this.date,
    required this.status,
    this.isSelected = false,
    this.isToday = false,
    this.onTap,
    this.checkInTime,
    this.checkOutTime,
    this.isNewBooking = false,
  });

  @override
  State<SplitDayCell> createState() => _SplitDayCellState();
}

class _SplitDayCellState extends State<SplitDayCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Get responsive cell size and border radius
    final cellSize = _getCellSize(context);
    final borderRadius = _getBorderRadius(context);
    final fontSize = _getFontSize(context);
    final timeSize = _getTimeSize(context);

    // Desktop hover detection
    final isDesktop = MediaQuery.of(context).size.width > 1024;

    return MouseRegion(
      onEnter: isDesktop ? (_) => setState(() => _isHovered = true) : null,
      onExit: isDesktop ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          margin: EdgeInsets.all(_getGap(context)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: SizedBox(
              width: cellSize,
              height: cellSize,
              child: _buildCellContent(fontSize, timeSize),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(double fontSize, double timeSize) {
    // Real-time pulse animation for new bookings
    if (widget.isNewBooking) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        tween: Tween(begin: 1.0, end: 1.2),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: _buildCellStack(fontSize, timeSize),
      );
    }

    // Selection animation
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: widget.isSelected ? 1.0 : 0.95,
      child: _buildCellStack(fontSize, timeSize),
    );
  }

  Widget _buildCellStack(double fontSize, double timeSize) {
    return Stack(
      children: [
        // Custom painted background
        Positioned.fill(
          child: CustomPaint(
            painter: SplitDayPainter(
              status: widget.status,
              isSelected: widget.isSelected,
              isToday: widget.isToday,
            ),
          ),
        ),

        // Day number
        Center(
          child: Text(
            '${widget.date.day}',
            style: TextStyle(
              color: _getTextColor(),
              fontSize: fontSize,
              fontWeight: widget.isToday ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),

        // Check-in time label (bottom-right)
        if ((widget.status == DayStatus.checkIn || widget.status == DayStatus.sameDayTurnover) &&
            widget.checkInTime != null)
          Positioned(
            bottom: 2,
            right: 2,
            child: Text(
              widget.checkInTime!,
              style: TextStyle(
                color: Colors.white,
                fontSize: timeSize,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

        // Check-out time label (top-left)
        if ((widget.status == DayStatus.checkOut || widget.status == DayStatus.sameDayTurnover) &&
            widget.checkOutTime != null)
          Positioned(
            top: 2,
            left: 2,
            child: Text(
              widget.checkOutTime!,
              style: TextStyle(
                color: Colors.white,
                fontSize: timeSize,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  /// Get responsive cell size based on screen width
  /// Desktop (>1024px): 80px
  /// Tablet (768-1024px): 60px
  /// Mobile (<768px): 44px
  double _getCellSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 768) return 44; // Mobile
    if (width < 1024) return 60; // Tablet
    return 80; // Desktop
  }

  /// Get responsive border radius
  /// Desktop: 8px, Tablet: 6px, Mobile: 4px
  double _getBorderRadius(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 768) return 4;
    if (width < 1024) return 6;
    return 8;
  }

  /// Get responsive gap between cells
  /// Desktop: 4px, Tablet: 3px, Mobile: 2px
  double _getGap(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 768) return 2;
    if (width < 1024) return 3;
    return 4;
  }

  /// Get responsive font size for day numbers
  /// Desktop: 18px, Mobile: 14px
  double _getFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 768) return 14;
    return 18;
  }

  /// Get responsive font size for time labels
  /// Desktop: 10px, Mobile: 8px
  double _getTimeSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 768) return 8;
    return 10;
  }

  Color _getTextColor() {
    switch (widget.status) {
      case DayStatus.available:
        return Colors.white;
      case DayStatus.booked:
      case DayStatus.blocked:
        return Colors.white70;
      case DayStatus.checkIn:
      case DayStatus.checkOut:
      case DayStatus.sameDayTurnover:
        return Colors.white; // White for better contrast with red triangles
    }
  }
}
