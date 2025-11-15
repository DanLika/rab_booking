import 'package:flutter/material.dart';

/// Skeleton loader for calendar
/// Shows animated placeholders while loading data
class CalendarSkeletonLoader extends StatefulWidget {
  final int unitCount;
  final int dayCount;

  const CalendarSkeletonLoader({
    super.key,
    this.unitCount = 5,
    this.dayCount = 7,
  });

  @override
  State<CalendarSkeletonLoader> createState() => _CalendarSkeletonLoaderState();
}

class _CalendarSkeletonLoaderState extends State<CalendarSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header skeleton
              _buildHeaderSkeleton(context),

              const SizedBox(height: 16),

              // Calendar grid skeleton
              Expanded(child: _buildGridSkeleton(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSkeleton(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // Left controls
          const _SkeletonBox(width: 120, height: 36, borderRadius: 8),
          const Spacer(),
          // Right controls
          Row(
            children: List.generate(
              3,
              (index) => const Padding(
                padding: EdgeInsets.only(left: 8),
                child: _SkeletonBox(width: 40, height: 40, borderRadius: 20),
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
          widget.unitCount,
          (unitIndex) => _buildUnitRowSkeleton(context, unitIndex),
        ),
      ),
    );
  }

  Widget _buildUnitRowSkeleton(BuildContext context, int unitIndex) {
    final theme = Theme.of(context);

    return Container(
      height: 80,
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
          // Unit name
          Container(
            width: 120,
            padding: const EdgeInsets.all(12),
            child: const _SkeletonBox(width: 100, height: 20),
          ),

          // Booking blocks placeholders
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 12),
                ...List.generate(
                  _getRandomBlockCount(unitIndex),
                  (blockIndex) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _SkeletonBox(
                      width: _getRandomBlockWidth(unitIndex, blockIndex),
                      height: 56,
                    ),
                  ),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha((0.1 * 255).toInt())
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
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
            'Učitavanje...',
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
