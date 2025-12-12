import 'package:flutter/material.dart';
import '../../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/responsive_helper.dart';

/// Skeleton loader for year calendar widget.
///
/// Displays an animated placeholder that mimics the actual year calendar structure:
/// - Header row: "Month" label + 31 day number columns
/// - 12 month rows: month name label + 31 day cells
///
/// Uses the same responsive cell sizing as the real calendar:
/// - Cell size calculated from available width (14px to 40px)
/// - Month label column width: 60px
class YearCalendarSkeleton extends StatefulWidget {
  const YearCalendarSkeleton({super.key});

  @override
  State<YearCalendarSkeleton> createState() => _YearCalendarSkeletonState();
}

class _YearCalendarSkeletonState extends State<YearCalendarSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.4,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = isDesktop ? SpacingTokens.l : SpacingTokens.m;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Defensive check: ensure constraints are bounded and finite
              final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth != double.infinity
                  ? constraints.maxWidth
                  : 1200.0; // Fallback to reasonable default
              // Calculate cell size same as real calendar
              final availableWidth = (maxWidth - (padding * 2)).clamp(300.0, maxWidth);
              final cellSize = ResponsiveHelper.getYearCellSizeForWidth(
                availableWidth,
              );
              final calendarWidth =
                  ConstraintTokens.monthLabelWidth + (31 * cellSize);

              return Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: padding,
                    right: padding,
                    bottom: padding,
                  ),
                  child: SizedBox(
                    width: calendarWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header row skeleton
                        _buildHeaderRowSkeleton(cellSize, isDark),
                        const SizedBox(height: SpacingTokens.s),
                        // 12 month rows skeleton
                        ...List.generate(
                          12,
                          (index) =>
                              _buildMonthRowSkeleton(cellSize, isDark, index),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeaderRowSkeleton(double cellSize, bool isDark) {
    return Row(
      children: [
        // "Month" label skeleton
        Container(
          width: ConstraintTokens.monthLabelWidth,
          height: cellSize,
          decoration: BoxDecoration(
            color: isDark
                ? SkeletonColors.darkPrimary
                : SkeletonColors.lightPrimary,
            border: Border.all(
              color: isDark
                  ? SkeletonColors.darkBorder
                  : SkeletonColors.lightBorder,
              width: 0.5,
            ),
            borderRadius: BorderTokens.onlyTopLeft(BorderTokens.radiusSubtle),
          ),
          child: Center(
            child: Container(
              width: 36,
              height: 10,
              decoration: BoxDecoration(
                color: isDark
                    ? SkeletonColors.darkSecondary
                    : SkeletonColors.lightSecondary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        // Day number header cells (1-31)
        ...List.generate(31, (dayIndex) {
          return Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: isDark
                  ? SkeletonColors.darkPrimary
                  : SkeletonColors.lightPrimary,
              border: Border.all(
                color: isDark
                    ? SkeletonColors.darkBorder
                    : SkeletonColors.lightBorder,
                width: 0.5,
              ),
              borderRadius: dayIndex == 30
                  ? BorderTokens.onlyTopRight(BorderTokens.radiusSubtle)
                  : BorderRadius.zero,
            ),
            child: Center(
              child: Container(
                width: cellSize * 0.5,
                height: cellSize * 0.35,
                decoration: BoxDecoration(
                  color: isDark
                      ? SkeletonColors.darkSecondary
                      : SkeletonColors.lightSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthRowSkeleton(double cellSize, bool isDark, int monthIndex) {
    return Row(
      children: [
        // Month name label skeleton
        Container(
          width: ConstraintTokens.monthLabelWidth,
          height: cellSize,
          decoration: BoxDecoration(
            color: isDark
                ? SkeletonColors.darkPrimary
                : SkeletonColors.lightPrimary,
            border: Border.all(
              color: isDark
                  ? SkeletonColors.darkBorder
                  : SkeletonColors.lightBorder,
              width: 0.5,
            ),
            borderRadius: monthIndex == 11
                ? BorderTokens.onlyBottomLeft(BorderTokens.radiusSubtle)
                : BorderRadius.zero,
          ),
          child: Center(
            child: Container(
              width: 28,
              height: 10,
              decoration: BoxDecoration(
                color: isDark
                    ? SkeletonColors.darkSecondary
                    : SkeletonColors.lightSecondary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        // Day cells (31 per row)
        ...List.generate(31, (dayIndex) {
          // Days 29, 30, 31 don't exist in all months - show them "empty"
          final isEmptyDay = _isEmptyDay(monthIndex, dayIndex);

          return Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: isEmptyDay
                  ? (isDark
                        ? SkeletonColors.darkCardBackground
                        : SkeletonColors.lightCardBackground)
                  : (isDark
                        ? SkeletonColors.darkPrimary
                        : SkeletonColors.lightPrimary),
              border: Border.all(
                color: isDark
                    ? SkeletonColors.darkBorder
                    : SkeletonColors.lightBorder,
                width: 0.5,
              ),
              borderRadius: (monthIndex == 11 && dayIndex == 30)
                  ? BorderTokens.onlyBottomRight(BorderTokens.radiusSubtle)
                  : BorderRadius.zero,
            ),
          );
        }),
      ],
    );
  }

  /// Check if this day doesn't exist in this month (Feb 29-31, Apr 31, etc.)
  bool _isEmptyDay(int monthIndex, int dayIndex) {
    final month = monthIndex + 1; // 1-indexed month
    final day = dayIndex + 1; // 1-indexed day

    // Days that don't exist in shorter months
    if (month == 2 && day > 28) {
      return true; // Feb (ignore leap years for skeleton)
    }
    if ([4, 6, 9, 11].contains(month) && day > 30) return true; // 30-day months

    return false;
  }
}
