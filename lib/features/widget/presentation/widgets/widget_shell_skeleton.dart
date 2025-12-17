import 'package:flutter/material.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Full-page skeleton shell for the booking widget.
///
/// Shows immediately while data providers are loading, giving users
/// instant visual feedback. This is the "shell" that renders before
/// any Firestore data is fetched.
///
/// ## Structure
/// - Header skeleton (logo/branding area)
/// - Calendar skeleton (main content)
/// - Info card skeleton (optional bottom area)
///
/// ## Usage
/// Use this in BookingWidgetScreen's loading state:
/// ```dart
/// if (calendarStatus.isLoading) {
///   return const WidgetShellSkeleton();
/// }
/// ```
class WidgetShellSkeleton extends StatelessWidget {
  const WidgetShellSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? SkeletonColors.darkCardBackground
        : SkeletonColors.lightCardBackground;

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header skeleton (branding area)
            _buildHeaderSkeleton(isDark),

            const SizedBox(height: AppDimensions.spaceM),

            // Main content - Calendar skeleton
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
                child: CalendarSkeleton(),
              ),
            ),

            const SizedBox(height: AppDimensions.spaceM),

            // Footer info skeleton
            _buildFooterSkeleton(isDark),

            const SizedBox(height: AppDimensions.spaceM),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      child: const Row(
        children: [
          // Logo/branding skeleton
          SkeletonLoader(
            width: 40,
            height: 40,
            borderRadius: AppDimensions.radiusS,
          ),
          SizedBox(width: AppDimensions.spaceS),
          // Property name skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 150, height: 18, borderRadius: 4),
                SizedBox(height: 4),
                SkeletonLoader(width: 100, height: 14, borderRadius: 4),
              ],
            ),
          ),
          // Theme toggle skeleton
          SkeletonLoader(width: 36, height: 36, borderRadius: 18),
        ],
      ),
    );
  }

  Widget _buildFooterSkeleton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        decoration: BoxDecoration(
          color: isDark
              ? SkeletonColors.darkHeader
              : SkeletonColors.lightHeader,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: isDark
                ? SkeletonColors.darkBorder
                : SkeletonColors.lightBorder,
          ),
        ),
        child: const Row(
          children: [
            SkeletonLoader(width: 24, height: 24, borderRadius: 12),
            SizedBox(width: AppDimensions.spaceS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: double.infinity, height: 14, borderRadius: 4),
                  SizedBox(height: 4),
                  SkeletonLoader(width: 200, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
