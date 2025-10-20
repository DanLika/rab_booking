import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../search/presentation/providers/recently_viewed_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

/// Premium Recently Viewed Properties Section
/// Features:
/// - Glassmorphic design
/// - Smooth scroll animations
/// - Hover effects
/// - Badge with count
/// - Fade-out scroll indicators
class RecentlyViewedSectionPremium extends ConsumerStatefulWidget {
  const RecentlyViewedSectionPremium({
    this.title = 'Recently Viewed',
    this.subtitle = 'Properties you have viewed recently',
    this.maxProperties = 10,
    super.key,
  });

  final String title;
  final String subtitle;
  final int maxProperties;

  @override
  ConsumerState<RecentlyViewedSectionPremium> createState() => _RecentlyViewedSectionPremiumState();
}

class _RecentlyViewedSectionPremiumState extends ConsumerState<RecentlyViewedSectionPremium> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftIndicator = false;
  bool _showRightIndicator = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollIndicators);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollIndicators);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollIndicators() {
    setState(() {
      _showLeftIndicator = _scrollController.offset > 10;
      _showRightIndicator = _scrollController.offset < _scrollController.position.maxScrollExtent - 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoggedIn = authState.user != null;

    if (!isLoggedIn) {
      return const SizedBox.shrink();
    }

    final recentlyViewedAsync = ref.watch(recentlyViewedPropertiesProvider);

    return recentlyViewedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (properties) {
        if (properties.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayProperties = properties.take(widget.maxProperties).toList();
        final isMobile = context.isMobile;

        return Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(
            horizontal: isMobile ? 0 : AppDimensions.spaceXL,
            vertical: AppDimensions.spaceXL,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      AppColors.surfaceVariantDark.withValues(alpha: 0.3),
                      AppColors.surfaceDark.withValues(alpha: 0.5),
                    ]
                  : [
                      AppColors.primary.withValues(alpha: 0.02),
                      AppColors.surfaceLight.withValues(alpha: 0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(isMobile ? 0 : AppDimensions.radiusXL),
            border: isMobile
                ? null
                : Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Section Header
              Padding(
                padding: EdgeInsets.all(isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL),
                child: _buildPremiumHeader(context, isMobile, displayProperties.length),
              ),

              // Horizontal Property List with Fade Indicators
              SizedBox(
                height: isMobile ? 380 : 400,
                child: Stack(
                  children: [
                    // Property Cards
                    ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL,
                      ),
                      itemCount: displayProperties.length,
                      itemBuilder: (context, index) {
                        final property = displayProperties[index];

                        return Container(
                          width: isMobile ? 280 : 320,
                          margin: EdgeInsets.only(
                            right: index == displayProperties.length - 1 ? 0 : AppDimensions.spaceL,
                          ),
                          child: _PremiumPropertyCard(
                            property: property,
                            index: index,
                          ),
                        );
                      },
                    ),

                    // Left Fade Indicator
                    if (_showLeftIndicator)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: _buildFadeIndicator(isLeft: true),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms),

                    // Right Fade Indicator
                    if (_showRightIndicator)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: _buildFadeIndicator(isLeft: false),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceL),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms, curve: Curves.easeOut)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildPremiumHeader(BuildContext context, bool isMobile, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title + Badge
        Expanded(
          child: Row(
            children: [
              // Premium Icon
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceS),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              // Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: (isMobile ? AppTypography.h3 : AppTypography.h2).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceS),
                        // Count Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceS,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.2),
                                AppColors.primary.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$count',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Premium Clear Button
        _buildPremiumClearButton(context),
      ],
    );
  }

  Widget _buildPremiumClearButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showClearDialog(context),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceM,
            vertical: AppDimensions.spaceS,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.textSecondaryLight.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppDimensions.spaceXS),
              Text(
                'Clear',
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showClearDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceS),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: const Icon(Icons.warning_amber, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            const Text('Clear History'),
          ],
        ),
        content: const Text(
          'Are you sure you want to clear your viewing history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          PremiumButton.primary(
            label: 'Clear History',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(recentlyViewedNotifierProvider.notifier).clearHistory();
    }
  }

  Widget _buildFadeIndicator({required bool isLeft}) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  AppColors.surfaceDark,
                  AppColors.surfaceDark.withValues(alpha: 0),
                ]
              : [
                  Colors.white,
                  Colors.white.withValues(alpha: 0),
                ],
        ),
      ),
      child: Center(
        child: Icon(
          isLeft ? Icons.chevron_left : Icons.chevron_right,
          color: AppColors.primary,
          size: 32,
        ),
      ),
    );
  }
}

/// Premium Property Card with Hover Effects
class _PremiumPropertyCard extends StatefulWidget {
  final dynamic property;
  final int index;

  const _PremiumPropertyCard({
    required this.property,
    required this.index,
  });

  @override
  State<_PremiumPropertyCard> createState() => _PremiumPropertyCardState();
}

class _PremiumPropertyCardState extends State<_PremiumPropertyCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -8.0 : 0.0)
          ..scale(_isHovered ? 1.02 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: _isHovered ? 24 : 12,
                offset: Offset(0, _isHovered ? 12 : 6),
              ),
            ],
          ),
          child: PropertyCard(property: widget.property),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 100))
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}
