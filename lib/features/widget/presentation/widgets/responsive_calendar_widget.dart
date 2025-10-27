import 'package:flutter/material.dart';
import 'year_grid_calendar_widget.dart';
import 'month_calendar_widget.dart';
import 'week_calendar_widget.dart';

/// Responsive calendar that automatically switches between views based on screen size
/// - Phone portrait (<430px width): Week view (vertical list)
/// - Tablet/Phone landscape (430-1024px): Month view (supports horizontal orientation)
/// - Desktop (>1024px): Year view (grid layout)
class ResponsiveCalendarWidget extends StatelessWidget {
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;
  final int? initialYear;

  const ResponsiveCalendarWidget({
    super.key,
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

        // Tablet/Phone landscape: Month view
        else if (width >= 430) {
          return MonthCalendarWidget(
            unitId: unitId,
            onRangeSelected: onRangeSelected,
          );
        }

        // Phone portrait: Week view (vertical list)
        else {
          return WeekCalendarWidget(
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
  static const double phonePortraitMax = 430;
  static const double tabletMax = 1024;

  static bool isPhonePortrait(double width) => width < phonePortraitMax;
  static bool isTablet(double width) => width >= phonePortraitMax && width < tabletMax;
  static bool isDesktop(double width) => width >= tabletMax;
}
