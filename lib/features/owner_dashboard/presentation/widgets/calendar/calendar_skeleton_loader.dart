import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../l10n/app_localizations.dart';

/// Skeleton loader for calendar with shimmer effect
/// Shows placeholder rows to fill the page while loading
class CalendarSkeletonLoader extends StatelessWidget {
  final int unitCount;
  final int dayCount;

  const CalendarSkeletonLoader({
    super.key,
    this.unitCount = 9, // Default to 9 rows to fill the page
    this.dayCount = 7,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header skeleton
        _buildHeaderSkeleton(context),

        const SizedBox(height: 16),

        // Calendar grid skeleton
        Expanded(child: _buildGridSkeleton(context)),
      ],
    );
  }

  Widget _buildHeaderSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // Left controls - responsive width
          _SkeletonBox(width: isMobile ? 80 : 120, height: 36, borderRadius: 8),
          const Spacer(),
          // Right controls - fewer on mobile
          Row(
            children: List.generate(
              isMobile ? 1 : 3,
              (index) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _SkeletonBox(
                  width: isMobile ? 32 : 40,
                  height: isMobile ? 32 : 40,
                  borderRadius: isMobile ? 16 : 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridSkeleton(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(
          unitCount,
          (unitIndex) => _buildUnitRowSkeleton(context, unitIndex),
        ),
      ),
    );
  }

  Widget _buildUnitRowSkeleton(BuildContext context, int unitIndex) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final unitColumnWidth = isMobile ? 100.0 : 120.0;

    return Container(
      height: isMobile ? 60 : 80,
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withAlpha((0.3 * 255).toInt()),
          ),
        ),
      ),
      child: Row(
        children: [
          // Unit name - responsive width
          Container(
            width: unitColumnWidth,
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            child: _SkeletonBox(width: unitColumnWidth - 20, height: 20),
          ),

          // Booking blocks placeholders - clipped to prevent overflow
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  ...List.generate(
                    _getRandomBlockCount(unitIndex),
                    (blockIndex) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _SkeletonBox(
                        width: _getRandomBlockWidth(unitIndex, blockIndex),
                        height: isMobile ? 40 : 56,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getRandomBlockCount(int unitIndex) {
    // Pseudo-random based on unit index for variety
    return (unitIndex % 3) + 1;
  }

  double _getRandomBlockWidth(int unitIndex, int blockIndex) {
    // Pseudo-random widths for variety
    final base = 80.0;
    final variation = ((unitIndex + blockIndex) % 5) * 40.0;
    return base + variation;
  }
}

/// Skeleton box widget with shimmer effect
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  // Consistent skeleton colors (matching SkeletonColors design system)
  static const Color _darkBase = Color(0xFF2D2D3A);
  static const Color _darkHighlight = Color(0xFF3D3D4A);
  static const Color _lightBase = Color(0xFFE8E8F0);
  static const Color _lightHighlight = Color(0xFFF5F5FA);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? _darkBase : _lightBase,
      highlightColor: isDark ? _darkHighlight : _lightHighlight,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? _darkBase : _lightBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Compact skeleton loader for smaller components
class CalendarSkeletonCompact extends StatelessWidget {
  const CalendarSkeletonCompact({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                isDark
                    ? Colors.white.withAlpha((0.5 * 255).toInt())
                    : Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.ownerCalendarLoading,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withAlpha(
                (0.5 * 255).toInt(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
