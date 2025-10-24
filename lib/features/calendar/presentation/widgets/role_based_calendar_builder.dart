import 'package:flutter/material.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/calendar_permissions.dart';
import 'calendar_cell_builder.dart';

/// Role-based calendar cell builder
/// Renders different calendar views based on user permissions
class RoleBasedCalendarBuilder {
  final CalendarPermissions permissions;
  final CalendarCellBuilder cellBuilder;

  RoleBasedCalendarBuilder({
    required this.permissions,
  }) : cellBuilder = CalendarCellBuilder();

  /// Build cell based on user role and permissions
  Widget buildCell(
    BuildContext context,
    DateTime date,
    CalendarDay dayData, {
    VoidCallback? onTap,
    bool isSelected = false,
    bool isToday = false,
  }) {
    if (permissions.isGuest) {
      return _buildGuestCell(
        context,
        date,
        dayData,
        onTap: onTap,
        isSelected: isSelected,
        isToday: isToday,
      );
    } else {
      return _buildOwnerCell(
        context,
        date,
        dayData,
        onTap: onTap,
        isSelected: isSelected,
        isToday: isToday,
      );
    }
  }

  /// Build cell for guest users
  /// Guests see simplified view with only availability status
  Widget _buildGuestCell(
    BuildContext context,
    DateTime date,
    CalendarDay dayData, {
    VoidCallback? onTap,
    bool isSelected = false,
    bool isToday = false,
  }) {
    final isSelectable = permissions.canSelectDate(dayData);

    return GestureDetector(
      onTap: isSelectable ? onTap : null,
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
            // Background based on availability
            _buildGuestBackground(dayData),

            // Date number
            Center(
              child: _buildDateNumber(
                context,
                date,
                dayData,
                isToday,
                isSelectable,
              ),
            ),

            // Availability indicator
            if (!isSelectable)
              Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  Icons.block,
                  size: 12,
                  color: Colors.red.shade300,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build cell for owner users
  /// Owners see full details with times, booking IDs, etc.
  Widget _buildOwnerCell(
    BuildContext context,
    DateTime date,
    CalendarDay dayData, {
    VoidCallback? onTap,
    bool isSelected = false,
    bool isToday = false,
  }) {
    // Use the full calendar cell builder
    return cellBuilder.buildCell(
      context,
      date,
      dayData,
      onTap: onTap,
      isSelected: isSelected,
      isToday: isToday,
    );
  }

  /// Build background for guest view
  Widget _buildGuestBackground(CalendarDay dayData) {
    Color backgroundColor;

    switch (dayData.status) {
      case DayStatus.available:
        backgroundColor = const Color(0xFFE8F5E9); // Light green
        break;
      case DayStatus.booked:
      case DayStatus.checkIn:
      case DayStatus.checkOut:
      case DayStatus.sameDayTurnover:
        backgroundColor = Colors.grey.shade300; // Gray (not available)
        break;
      case DayStatus.blocked:
        backgroundColor = Colors.grey.shade400; // Darker gray
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// Build date number with appropriate styling
  Widget _buildDateNumber(
    BuildContext context,
    DateTime date,
    CalendarDay dayData,
    bool isToday,
    bool isSelectable,
  ) {
    Color textColor;

    if (permissions.isGuest) {
      // Guest view: Simple color scheme
      textColor = isSelectable ? Colors.green.shade800 : Colors.grey.shade600;
    } else {
      // Owner view: Full color scheme
      if (dayData.status == DayStatus.booked ||
          dayData.status == DayStatus.blocked) {
        textColor = Colors.white;
      } else if (dayData.status == DayStatus.checkIn ||
          dayData.status == DayStatus.checkOut ||
          dayData.status == DayStatus.sameDayTurnover) {
        textColor = Colors.white;
      } else {
        textColor = Colors.black87;
      }
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

  /// Build legend based on role
  Widget buildLegend(BuildContext context) {
    if (permissions.isGuest) {
      return _buildGuestLegend(context);
    } else {
      return _buildOwnerLegend(context);
    }
  }

  /// Build simplified legend for guests
  Widget _buildGuestLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(
          color: const Color(0xFFE8F5E9),
          textColor: Colors.green.shade800,
          label: 'Available',
        ),
        _LegendItem(
          color: Colors.grey.shade300,
          textColor: Colors.grey.shade600,
          label: 'Not Available',
        ),
      ],
    );
  }

  /// Build full legend for owners
  Widget _buildOwnerLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(
          color: Colors.grey.shade200,
          textColor: Colors.black87,
          label: 'Available',
        ),
        _LegendItem(
          color: const Color(0xFF64748B),
          textColor: Colors.white,
          label: 'Booked',
        ),
        _LegendItem(
          color: const Color(0xFFEF4444),
          label: 'Check-in',
          isTriangle: true,
          trianglePosition: TrianglePosition.bottomRight,
        ),
        _LegendItem(
          color: const Color(0xFFEF4444),
          label: 'Check-out',
          isTriangle: true,
          trianglePosition: TrianglePosition.topLeft,
        ),
        _LegendItem(
          color: const Color(0xFFEF4444),
          label: 'Same-day turnover',
          isTwoTriangles: true,
        ),
        _LegendItem(
          color: Colors.grey.shade700,
          textColor: Colors.white,
          label: 'Blocked',
        ),
      ],
    );
  }
}

/// Legend item widget
class _LegendItem extends StatelessWidget {
  final Color color;
  final Color? textColor;
  final String label;
  final bool isTriangle;
  final bool isTwoTriangles;
  final TrianglePosition? trianglePosition;

  const _LegendItem({
    required this.color,
    required this.label,
    this.textColor,
    this.isTriangle = false,
    this.isTwoTriangles = false,
    this.trianglePosition,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color indicator
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isTriangle || isTwoTriangles
                ? const Color(0xFF9CA3AF)
                : color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400, width: 0.5),
          ),
          child: isTriangle
              ? CustomPaint(
                  painter: TrianglePainter(
                    color: color,
                    position: trianglePosition!,
                  ),
                )
              : isTwoTriangles
                  ? Stack(
                      children: [
                        CustomPaint(
                          painter: TrianglePainter(
                            color: color,
                            position: TrianglePosition.topLeft,
                          ),
                        ),
                        CustomPaint(
                          painter: TrianglePainter(
                            color: color,
                            position: TrianglePosition.bottomRight,
                          ),
                        ),
                      ],
                    )
                  : null,
        ),
        const SizedBox(width: 8),

        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// Permission-aware calendar header
class PermissionAwareCalendarHeader extends StatelessWidget {
  final CalendarPermissions permissions;
  final DateTime focusedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback? onBlockDates;
  final VoidCallback? onSettings;

  const PermissionAwareCalendarHeader({
    Key? key,
    required this.permissions,
    required this.focusedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onBlockDates,
    this.onSettings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Month navigation
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPreviousMonth,
            ),
            Text(
              _formatMonth(focusedMonth),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNextMonth,
            ),
          ],
        ),

        // Owner/admin actions
        if (permissions.hasElevatedPermissions)
          Row(
            children: [
              if (permissions.canBlockDates() && onBlockDates != null)
                IconButton(
                  icon: const Icon(Icons.block),
                  tooltip: 'Block Dates',
                  onPressed: onBlockDates,
                ),
              if (permissions.canModifySettings() && onSettings != null)
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Calendar Settings',
                  onPressed: onSettings,
                ),
            ],
          ),
      ],
    );
  }

  String _formatMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
