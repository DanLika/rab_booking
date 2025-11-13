import 'package:flutter/material.dart';
import 'year_grid_calendar_widget.dart';
import 'month_calendar_widget.dart';

/// Responsive calendar that automatically switches between views based on screen size
/// - Phone/Tablet (<1024px width): Month view
/// - Desktop (>=1024px): Year view (grid layout)
class ResponsiveCalendarWidget extends StatelessWidget {
  final String propertyId;
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;
  final int? initialYear;

  const ResponsiveCalendarWidget({
    super.key,
    required this.propertyId,
    required this.unitId,
    this.onRangeSelected,
    this.initialYear,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Desktop: Year view (12 months × 31 days grid)
        if (width >= 1024) {
          return YearGridCalendarWidget(
            unitId: unitId,
            onRangeSelected: onRangeSelected,
            initialYear: initialYear,
          );
        }

        // Phone/Tablet: Month view
        else {
          return MonthCalendarWidget(
            propertyId: propertyId,
            unitId: unitId,
            onRangeSelected: onRangeSelected,
          );
        }
      },
    );
  }
}

/// Breakpoint constants for consistent sizing
class CalendarBreakpoints {
  static const double desktopMin = 1024;

  static bool isDesktop(double width) => width >= desktopMin;
  static bool isMobile(double width) => width < desktopMin;
}
