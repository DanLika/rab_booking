import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/responsive_helper.dart';

/// Skeleton loader for month calendar widget.
///
/// Displays an animated placeholder that mimics the actual month calendar structure:
/// - 7-column weekday header row
/// - 5-week day grid (35 cells)
///
/// Uses flutter_animate for pulse opacity animation.
/// Uses the same responsive constraints as the real calendar:
/// - Desktop (>=1024px): maxWidth 650px
/// - Mobile/Tablet: maxWidth 600px
class MonthCalendarSkeleton extends StatelessWidget {
  const MonthCalendarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = ResponsiveHelper.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Match real calendar constraints
    final maxWidth = isDesktop ? 650.0 : 600.0;
    final horizontalPadding = isDesktop ? SpacingTokens.l : SpacingTokens.m;
    final cellGap = SpacingTokens.calendarCellGap(context);
    final aspectRatio = isMobile ? 1.0 : 0.95;

    return Center(
          child: Padding(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: isDesktop ? SpacingTokens.m : SpacingTokens.s,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Weekday headers skeleton
                  _buildWeekdayHeadersSkeleton(isDark),
                  const SizedBox(height: SpacingTokens.s),
                  // Calendar grid skeleton (5 weeks)
                  _buildGridSkeleton(isDark, cellGap, aspectRatio),
                ],
              ),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(
          duration: const Duration(milliseconds: 1500),
          begin: 0.4,
          end: 0.8,
          curve: Curves.easeInOut,
        );
  }

  Widget _buildWeekdayHeadersSkeleton(bool isDark) {
    return Row(
      children: List.generate(7, (index) {
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
            margin: EdgeInsets.only(right: index < 6 ? 2 : 0),
            decoration: BoxDecoration(
              color: isDark
                  ? SkeletonColors.darkPrimary
                  : SkeletonColors.lightPrimary,
              borderRadius: BorderTokens.circularSubtle,
            ),
            child: Center(
              child: Container(
                width: 24,
                height: 12,
                decoration: BoxDecoration(
                  color: isDark
                      ? SkeletonColors.darkSecondary
                      : SkeletonColors.lightSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGridSkeleton(bool isDark, double cellGap, double aspectRatio) {
    // 5 weeks (35 cells) is the typical month display
    const weeksCount = 5;
    const daysPerWeek = 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: daysPerWeek,
        mainAxisSpacing: cellGap,
        crossAxisSpacing: cellGap,
        childAspectRatio: aspectRatio,
      ),
      itemCount: weeksCount * daysPerWeek,
      itemBuilder: (context, index) => _buildDayCellSkeleton(isDark, index),
    );
  }

  Widget _buildDayCellSkeleton(bool isDark, int index) {
    // Simulate empty cells like a typical month that starts mid-week
    // First 3 cells are "previous month", cells after day 28+ vary by month
    // Using average values for skeleton visual consistency
    const emptyStartCells = 3; // Simulates month starting on Thursday
    const totalDays = 28; // Minimum days in any month (February)
    final isEmpty =
        index < emptyStartCells || index >= emptyStartCells + totalDays;

    return Container(
      decoration: BoxDecoration(
        color: isEmpty
            ? (isDark
                  ? SkeletonColors.darkCardBackground
                  : SkeletonColors.lightCardBackground)
            : (isDark
                  ? SkeletonColors.darkPrimary
                  : SkeletonColors.lightPrimary),
        borderRadius: BorderTokens.circularSubtle,
        border: Border.all(
          color: isDark
              ? SkeletonColors.darkBorder
              : SkeletonColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: isEmpty
          ? null
          : Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 16,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark
                        ? SkeletonColors.darkSecondary
                        : SkeletonColors.lightSecondary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
    );
  }
}
