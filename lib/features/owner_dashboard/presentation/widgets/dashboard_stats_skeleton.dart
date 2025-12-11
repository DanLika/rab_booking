import 'package:flutter/material.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';

/// Dashboard stats cards skeleton loader
///
/// DEPRECATED: This skeleton loader is no longer used.
/// Dashboard now uses SkeletonLoader.analyticsMetricCards() for consistency
/// with Analytics and Report pages (4 cards instead of 6).
///
/// Displays 4 shimmer cards with stagger animation
/// Mimics the exact layout of real dashboard stat cards
class DashboardStatsSkeleton extends StatelessWidget {
  const DashboardStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Wrap(
      spacing: isMobile ? 12.0 : 16.0,
      runSpacing: isMobile ? 12.0 : 16.0,
      alignment: WrapAlignment.center,
      children: [
        _buildSkeletonCard(context, 0, isMobile, isTablet),
        _buildSkeletonCard(context, 100, isMobile, isTablet),
        _buildSkeletonCard(context, 200, isMobile, isTablet),
        _buildSkeletonCard(context, 300, isMobile, isTablet),
      ],
    );
  }

  Widget _buildSkeletonCard(BuildContext context, int animationDelay, bool isMobile, bool isTablet) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // EXACT same width calculation as real cards
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = isMobile ? 12.0 : 16.0;

    double cardWidth;
    if (isMobile) {
      // Mobile: 2 cards per row
      cardWidth = (screenWidth - (spacing * 3 + 32)) / 2;
    } else if (isTablet) {
      // Tablet: 3 cards per row
      cardWidth = (screenWidth - (spacing * 4 + 48)) / 3;
    } else {
      // Desktop: fixed width
      cardWidth = 280.0;
    }

    final cardHeight = isMobile ? 160.0 : 180.0;

    // Use consistent skeleton colors (matching SkeletonColors design system)
    final bgColor = isDark ? const Color(0xFF2D2D3A) : const Color(0xFFE8E8F0);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + animationDelay ~/ 2),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 10 * (1 - value)), child: child),
        );
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon circle placeholder
            SkeletonLoader(
              width: isMobile ? 44 : 48,
              height: isMobile ? 44 : 48,
              borderRadius: 24, // Circular
            ),

            const SizedBox(height: 12),

            // Title bar
            SkeletonLoader(width: cardWidth * 0.7, height: 14),

            const SizedBox(height: 8),

            // Value bar (larger, bold visual)
            SkeletonLoader(width: cardWidth * 0.5, height: 20),
          ],
        ),
      ),
    );
  }
}
