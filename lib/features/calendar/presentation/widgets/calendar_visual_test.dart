import 'package:flutter/material.dart';
import '../../domain/models/calendar_day.dart';
import 'split_day_painter.dart';

/// Visual test widget to demonstrate all calendar cell states
/// Use this to verify split-day visualization works correctly
class CalendarVisualTest extends StatelessWidget {
  const CalendarVisualTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Cell Visual Test'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Split-Day Visualization Test',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'All calendar cell states with responsive breakpoints',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),

            // Desktop size (80px)
            _buildSizeSection(
              context,
              title: 'Desktop (80x80px)',
              cellSize: 80,
              borderRadius: 8,
              fontSize: 18,
              timeSize: 10,
            ),

            const SizedBox(height: 48),

            // Tablet size (60px)
            _buildSizeSection(
              context,
              title: 'Tablet (60x60px)',
              cellSize: 60,
              borderRadius: 6,
              fontSize: 16,
              timeSize: 9,
            ),

            const SizedBox(height: 48),

            // Mobile size (44px)
            _buildSizeSection(
              context,
              title: 'Mobile (44x44px)',
              cellSize: 44,
              borderRadius: 4,
              fontSize: 14,
              timeSize: 8,
            ),

            const SizedBox(height: 48),

            // Color specifications
            _buildColorSpecs(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeSection(
    BuildContext context, {
    required String title,
    required double cellSize,
    required double borderRadius,
    required double fontSize,
    required double timeSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildCellDemo(
              context,
              label: 'Available',
              status: DayStatus.available,
              cellSize: cellSize,
              borderRadius: borderRadius,
              fontSize: fontSize,
              timeSize: timeSize,
              date: 15,
            ),
            _buildCellDemo(
              context,
              label: 'Booked',
              status: DayStatus.booked,
              cellSize: cellSize,
              borderRadius: borderRadius,
              fontSize: fontSize,
              timeSize: timeSize,
              date: 16,
            ),
            _buildCellDemo(
              context,
              label: 'Check-in',
              status: DayStatus.checkIn,
              cellSize: cellSize,
              borderRadius: borderRadius,
              fontSize: fontSize,
              timeSize: timeSize,
              date: 17,
              checkInTime: '15:00',
            ),
            _buildCellDemo(
              context,
              label: 'Check-out',
              status: DayStatus.checkOut,
              cellSize: cellSize,
              borderRadius: borderRadius,
              fontSize: fontSize,
              timeSize: timeSize,
              date: 18,
              checkOutTime: '10:00',
            ),
            _buildCellDemo(
              context,
              label: 'Same-day turnover',
              status: DayStatus.sameDayTurnover,
              cellSize: cellSize,
              borderRadius: borderRadius,
              fontSize: fontSize,
              timeSize: timeSize,
              date: 19,
              checkInTime: '15:00',
              checkOutTime: '10:00',
            ),
            _buildCellDemo(
              context,
              label: 'Blocked',
              status: DayStatus.blocked,
              cellSize: cellSize,
              borderRadius: borderRadius,
              fontSize: fontSize,
              timeSize: timeSize,
              date: 20,
            ),
            _buildCellDemo(
              context,
              label: 'Selected',
              status: DayStatus.available,
              cellSize: cellSize,
              borderRadius: borderRadius,
              fontSize: fontSize,
              timeSize: timeSize,
              date: 21,
              isSelected: true,
            ),
            _buildCellDemo(
              context,
              label: 'Today',
              status: DayStatus.available,
              cellSize: cellSize,
              borderRadius: borderRadius,
              fontSize: fontSize,
              timeSize: timeSize,
              date: 22,
              isToday: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCellDemo(
    BuildContext context, {
    required String label,
    required DayStatus status,
    required double cellSize,
    required double borderRadius,
    required double fontSize,
    required double timeSize,
    required int date,
    String? checkInTime,
    String? checkOutTime,
    bool isSelected = false,
    bool isToday = false,
  }) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            width: cellSize,
            height: cellSize,
            child: Stack(
              children: [
                // Custom painted background
                Positioned.fill(
                  child: CustomPaint(
                    painter: SplitDayPainter(
                      status: status,
                      isSelected: isSelected,
                      isToday: isToday,
                    ),
                  ),
                ),

                // Day number
                Center(
                  child: Text(
                    '$date',
                    style: TextStyle(
                      color: _getTextColor(status),
                      fontSize: fontSize,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),

                // Check-in time label (bottom-right)
                if (checkInTime != null)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Text(
                      checkInTime,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: timeSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                // Check-out time label (top-left)
                if (checkOutTime != null)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Text(
                      checkOutTime,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: timeSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: cellSize,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 10,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Color _getTextColor(DayStatus status) {
    switch (status) {
      case DayStatus.available:
        return Colors.white;
      case DayStatus.booked:
      case DayStatus.blocked:
        return Colors.white70;
      case DayStatus.checkIn:
      case DayStatus.checkOut:
      case DayStatus.sameDayTurnover:
        return Colors.white;
    }
  }

  Widget _buildColorSpecs(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color Specifications',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(color: Colors.grey[300]!),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(2),
          },
          children: [
            _buildTableRow('State', 'Color Name', 'Hex', isHeader: true),
            _buildTableRow('Available', 'Gray', '#9CA3AF',
                color: const Color(0xFF9CA3AF)),
            _buildTableRow('Booked', 'Blue-Gray', '#64748B',
                color: const Color(0xFF64748B)),
            _buildTableRow('Check-in/out', 'Red', '#EF4444',
                color: const Color(0xFFEF4444)),
            _buildTableRow('Blocked', 'Dark Gray', '#4B5563',
                color: const Color(0xFF4B5563)),
            _buildTableRow('Selected', 'Primary Blue', '#3B82F6',
                color: const Color(0xFF3B82F6)),
            _buildTableRow('Today', 'Accent Yellow', '#F59E0B',
                color: const Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Implementation Notes',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildNote('• Split-day cells use CustomPainter with Path objects'),
              _buildNote('• 0.5px transparent gap between triangles (antialiasing)'),
              _buildNote('• Check-out triangle: top-left (guest leaves morning)'),
              _buildNote('• Check-in triangle: bottom-right (guest arrives evening)'),
              _buildNote('• Same-day turnover: both triangles on same day'),
              _buildNote('• Responsive: 44px (mobile), 60px (tablet), 80px (desktop)'),
              _buildNote('• Hover animation: 1.05x scale on desktop'),
              _buildNote('• Real-time pulse: elastic animation on new bookings'),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String col1, String col2, String col3,
      {Color? color, bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? Colors.grey[200] : null,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            col1,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (color != null) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                col2,
                style: TextStyle(
                  fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            col3,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}
