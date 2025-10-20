import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/marketing_content_models.dart';
import '../providers/marketing_content_providers.dart';

/// Premium Popular Destinations Section
/// Features:
/// - Glassmorphic design
/// - Premium header with gradient icon
/// - Scroll indicators with fade effect
/// - Hover effects on cards
/// - Staggered entrance animations
class PopularDestinationsSectionPremium extends ConsumerStatefulWidget {
  const PopularDestinationsSectionPremium({
    this.title = 'Popular Destinations',
    this.subtitle,
    this.onDestinationTapped,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Function(DestinationData)? onDestinationTapped;

  @override
  ConsumerState<PopularDestinationsSectionPremium> createState() =>
      _PopularDestinationsSectionPremiumState();
}

class _PopularDestinationsSectionPremiumState
    extends ConsumerState<PopularDestinationsSectionPremium> {
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
      _showRightIndicator = _scrollController.offset <
          _scrollController.position.maxScrollExtent - 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinationsAsync = ref.watch(popularDestinationsProvider);

    return destinationsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => _buildContent(context, defaultDestinations),
      data: (destinations) {
        if (destinations.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildContent(context, destinations);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<DestinationData> destinations) {
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
                  AppColors.secondary.withValues(alpha: 0.02),
                  AppColors.surfaceLight.withValues(alpha: 0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 0 : AppDimensions.radiusXL),
        border: isMobile
            ? null
            : Border.all(
                color: AppColors.secondary.withValues(alpha: 0.1),
                width: 1,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium header
          Padding(
            padding: EdgeInsets.all(isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL),
            child: _buildPremiumHeader(context, isMobile, destinations.length),
          ),

          // Destinations horizontal list with fade indicators
          SizedBox(
            height: _getCardHeight(context),
            child: Stack(
              children: [
                // Destination cards
                ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL,
                  ),
                  itemCount: destinations.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: _getCardWidth(context),
                      margin: EdgeInsets.only(
                        right: index == destinations.length - 1
                            ? 0
                            : AppDimensions.spaceL,
                      ),
                      child: _PremiumDestinationCard(
                        destination: destinations[index],
                        index: index,
                        onTap: () => widget.onDestinationTapped?.call(destinations[index]),
                      ),
                    );
                  },
                ),

                // Left fade indicator
                if (_showLeftIndicator)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: _buildFadeIndicator(isLeft: true),
                  ).animate().fadeIn(duration: 300.ms),

                // Right fade indicator
                if (_showRightIndicator)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: _buildFadeIndicator(isLeft: false),
                  ).animate().fadeIn(duration: 300.ms),
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
  }

  Widget _buildPremiumHeader(BuildContext context, bool isMobile, int count) {
    return Row(
      children: [
        // Premium icon with gradient
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceS),
          decoration: BoxDecoration(
            gradient: AppColors.secondaryGradient,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.explore,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),

        // Title and subtitle
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
                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceS,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary.withValues(alpha: 0.2),
                          AppColors.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
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
          color: AppColors.secondary,
          size: 32,
        ),
      ),
    );
  }

  double _getCardWidth(BuildContext context) {
    if (context.isDesktop) return 320;
    if (context.isTablet) return 280;
    return MediaQuery.of(context).size.width * 0.8;
  }

  double _getCardHeight(BuildContext context) {
    if (context.isDesktop) return 420;
    if (context.isTablet) return 380;
    return 340;
  }
}

/// Premium Destination Card with Hover Effects
class _PremiumDestinationCard extends StatefulWidget {
  final DestinationData destination;
  final int index;
  final VoidCallback? onTap;

  const _PremiumDestinationCard({
    required this.destination,
    required this.index,
    this.onTap,
  });

  @override
  State<_PremiumDestinationCard> createState() => _PremiumDestinationCardState();
}

class _PremiumDestinationCardState extends State<_PremiumDestinationCard> {
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
                    ? AppColors.secondary.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: _isHovered ? 24 : 12,
                offset: Offset(0, _isHovered ? 12 : 6),
              ),
            ],
          ),
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Positioned.fill(
                    child: PremiumImage(
                      imageUrl: widget.destination.imageUrl,
                      fit: BoxFit.cover,
                      enableOverlay: true,
                      overlayGradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Content
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Destination name
                          Text(
                            widget.destination.name,
                            style: AppTypography.h3.copyWith(
                              color: Colors.white,
                              fontWeight: AppTypography.weightBold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppDimensions.spaceXXS),

                          // Country
                          Text(
                            widget.destination.country,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),

                          if (widget.destination.propertyCount != null) ...[
                            const SizedBox(height: AppDimensions.spaceS),

                            // Property count badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.spaceS,
                                vertical: AppDimensions.spaceXXS,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.radiusFull),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${widget.destination.propertyCount} properties',
                                style: AppTypography.small.copyWith(
                                  color: Colors.white,
                                  fontWeight: AppTypography.weightMedium,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 100))
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}
