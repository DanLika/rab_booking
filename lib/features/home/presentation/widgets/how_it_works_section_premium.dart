import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/marketing_content_models.dart';
import '../providers/marketing_content_providers.dart';

/// Premium How It Works Section
/// Features:
/// - Glassmorphic background
/// - Premium header with gradient icon
/// - Enhanced step cards with number badges
/// - Hover effects
/// - Staggered animations
/// - Connection arrows (desktop)
class HowItWorksSectionPremium extends ConsumerWidget {
  const HowItWorksSectionPremium({
    this.title = 'How It Works',
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(howItWorksStepsProvider);

    return stepsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => _buildContent(context, defaultSteps),
      data: (steps) {
        if (steps.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildContent(context, steps);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<HowItWorksStep> steps) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

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
                  AppColors.surfaceVariantLight.withValues(alpha: 0.8),
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
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL),
        child: Column(
          children: [
            // Premium header
            _buildPremiumHeader(context, isMobile),

            SizedBox(
              height: isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL,
            ),

            // Steps layout
            if (isMobile)
              _buildMobileLayout(steps)
            else if (isTablet)
              _buildTabletLayout(steps, context)
            else
              _buildDesktopLayout(steps),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, curve: Curves.easeOut)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildPremiumHeader(BuildContext context, bool isMobile) {
    return Column(
      children: [
        // Premium icon
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),

        // Title
        Text(
          title,
          style: (isMobile ? AppTypography.h2 : AppTypography.h1).copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),

        // Subtitle
        if (subtitle != null) ...[
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            subtitle!,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(List<HowItWorksStep> steps) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return Column(
          children: [
            _PremiumStepCard(
              step: step,
              stepNumber: index + 1,
              index: index,
            ),
            if (index < steps.length - 1) const SizedBox(height: AppDimensions.spaceL),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTabletLayout(List<HowItWorksStep> steps, BuildContext context) {
    return Wrap(
      spacing: AppDimensions.spaceL,
      runSpacing: AppDimensions.spaceL,
      alignment: WrapAlignment.center,
      children: steps.asMap().entries.map((entry) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - AppDimensions.spaceL * 5) / 2,
          child: _PremiumStepCard(
            step: entry.value,
            stepNumber: entry.key + 1,
            index: entry.key,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopLayout(List<HowItWorksStep> steps) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: _PremiumStepCard(
                  step: step,
                  stepNumber: index + 1,
                  index: index,
                ),
              ),
              if (index < steps.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceM,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: AppColors.primary.withValues(alpha: 0.5),
                    size: AppDimensions.iconL,
                  ),
                )
                    .animate(delay: Duration(milliseconds: (index + 1) * 150))
                    .fadeIn(duration: 600.ms)
                    .slideX(begin: -0.5, end: 0),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Premium Step Card with Hover Effects
class _PremiumStepCard extends StatefulWidget {
  final HowItWorksStep step;
  final int stepNumber;
  final int index;

  const _PremiumStepCard({
    required this.step,
    required this.stepNumber,
    required this.index,
  });

  @override
  State<_PremiumStepCard> createState() => _PremiumStepCardState();
}

class _PremiumStepCardState extends State<_PremiumStepCard> {
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
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.borderLight.withValues(alpha: 0.3),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceXL),
            child: Column(
              children: [
                // Step number badge with icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Gradient circle background
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.glowPrimary,
                      ),
                      child: Center(
                        child: Icon(
                          widget.step.icon,
                          color: Colors.white,
                          size: AppDimensions.iconL,
                        ),
                      ),
                    ),
                    // Step number badge
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${widget.stepNumber}',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spaceL),

                // Step title
                Text(
                  widget.step.title,
                  style: AppTypography.h3.copyWith(
                    fontWeight: AppTypography.weightBold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.spaceS),

                // Step description
                Text(
                  widget.step.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 150))
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}
