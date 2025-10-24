import 'package:flutter/material.dart';
import '../../domain/models/calendar_day.dart';
import 'package:intl/intl.dart';

/// Triangle position for split-day visualization
enum TrianglePosition { topLeft, bottomRight }

/// Custom painter for triangles in calendar cells
class TrianglePainter extends CustomPainter {
  final Color color;
  final TrianglePosition position;

  const TrianglePainter({
    required this.color,
    required this.position,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Add 0.5px gap from edges
    const gap = 0.5;

    if (position == TrianglePosition.bottomRight) {
      // Bottom-right triangle (check-in)
      path.moveTo(size.width - gap, size.height - gap); // Bottom-right
      path.lineTo(size.width - gap, size.height / 2); // Middle-right
      path.lineTo(size.width / 2, size.height - gap); // Middle-bottom
      path.close();
    } else {
      // Top-left triangle (check-out)
      path.moveTo(gap, gap); // Top-left
      path.lineTo(size.width / 2, gap); // Middle-top
      path.lineTo(gap, size.height / 2); // Middle-left
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.position != position;
  }
}

/// Builder class for calendar cells with split-day visualization
class CalendarCellBuilder {
  /// Build a calendar cell based on day data
  Widget buildCell(
    BuildContext context,
    DateTime date,
    CalendarDay dayData, {
    VoidCallback? onTap,
    bool isSelected = false,
    bool isToday = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = constraints.maxWidth;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 0.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                // Base container with background color
                _buildBaseContainer(context, dayData, isToday),

                // Split-day triangles (if check-in or check-out)
                if (dayData.status == DayStatus.checkIn)
                  _buildCheckInTriangle(cellSize),

                if (dayData.status == DayStatus.checkOut)
                  _buildCheckOutTriangle(cellSize),

                // Same-day turnover (both triangles)
                if (dayData.status == DayStatus.sameDayTurnover) ...[
                  _buildCheckOutTriangle(cellSize),
                  _buildCheckInTriangle(cellSize),
                ],

                // Date number in center
                Center(
                  child: _buildDateNumber(context, date, dayData, isToday),
                ),

                // Time labels
                if (dayData.checkInTime != null || dayData.checkOutTime != null)
                  _buildTimeLabels(context, dayData),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build base container with background color
  Widget _buildBaseContainer(
    BuildContext context,
    CalendarDay dayData,
    bool isToday,
  ) {
    Color backgroundColor;

    switch (dayData.status) {
      case DayStatus.available:
        backgroundColor = Colors.grey.shade200;
        break;
      case DayStatus.booked:
        backgroundColor = const Color(0xFF64748B); // Blue-gray
        break;
      case DayStatus.checkIn:
      case DayStatus.checkOut:
      case DayStatus.sameDayTurnover:
        backgroundColor = const Color(0xFF9CA3AF); // Gray for split days
        break;
      case DayStatus.blocked:
        backgroundColor = Colors.grey.shade700;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: dayData.status == DayStatus.blocked
          ? Center(
              child: Icon(
                Icons.block,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
            )
          : null,
    );
  }

  /// Build check-in triangle (bottom-right)
  Widget _buildCheckInTriangle(double cellSize) {
    return Positioned.fill(
      child: CustomPaint(
        painter: TrianglePainter(
          color: const Color(0xFFEF4444), // Red
          position: TrianglePosition.bottomRight,
        ),
      ),
    );
  }

  /// Build check-out triangle (top-left)
  Widget _buildCheckOutTriangle(double cellSize) {
    return Positioned.fill(
      child: CustomPaint(
        painter: TrianglePainter(
          color: const Color(0xFFEF4444), // Red
          position: TrianglePosition.topLeft,
        ),
      ),
    );
  }

  /// Build date number
  Widget _buildDateNumber(
    BuildContext context,
    DateTime date,
    CalendarDay dayData,
    bool isToday,
  ) {
    // Text color based on status
    Color textColor;
    if (dayData.status == DayStatus.booked ||
        dayData.status == DayStatus.blocked) {
      textColor = Colors.white;
    } else if (dayData.status == DayStatus.checkIn ||
        dayData.status == DayStatus.checkOut ||
        dayData.status == DayStatus.sameDayTurnover) {
      textColor = Colors.white; // White for split-day cells
    } else {
      textColor = Colors.black87;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: isToday
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            )
          : null,
      child: Text(
        '${date.day}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  /// Build time labels for check-in/check-out
  Widget _buildTimeLabels(BuildContext context, CalendarDay dayData) {
    return Stack(
      children: [
        // Check-out time (top-left)
        if (dayData.checkOutTime != null)
          Positioned(
            top: 2,
            left: 2,
            child: Text(
              _formatTime(dayData.checkOutTime!),
              style: const TextStyle(
                fontSize: 8,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Check-in time (bottom-right)
        if (dayData.checkInTime != null)
          Positioned(
            bottom: 2,
            right: 2,
            child: Text(
              _formatTime(dayData.checkInTime!),
              style: const TextStyle(
                fontSize: 8,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  /// Format time to HH:mm
  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Build same-day turnover cell (both triangles with two times)
  Widget buildSameDayTurnoverCell(
    BuildContext context,
    DateTime date,
    CalendarDay dayData, {
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // Base gray background
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF9CA3AF),
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Top-left triangle (check-out from previous booking)
            Positioned.fill(
              child: CustomPaint(
                painter: TrianglePainter(
                  color: const Color(0xFFEF4444),
                  position: TrianglePosition.topLeft,
                ),
              ),
            ),

            // Bottom-right triangle (check-in for new booking)
            Positioned.fill(
              child: CustomPaint(
                painter: TrianglePainter(
                  color: const Color(0xFFEF4444),
                  position: TrianglePosition.bottomRight,
                ),
              ),
            ),

            // Date in center
            Center(
              child: Text(
                '${date.day}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white, // White text for better contrast
                ),
              ),
            ),

            // Two time labels
            if (dayData.checkOutTime != null)
              Positioned(
                top: 4,
                left: 4,
                child: Text(
                  _formatTime(dayData.checkOutTime!),
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white70,
                  ),
                ),
              ),
            if (dayData.checkInTime != null)
              Positioned(
                bottom: 4,
                right: 4,
                child: Text(
                  _formatTime(dayData.checkInTime!),
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white70,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
