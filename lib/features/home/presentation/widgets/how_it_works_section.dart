import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/marketing_content_models.dart';
import '../providers/marketing_content_providers.dart';

/// How It Works section for home screen
/// Features: Step-by-step guide cards with icons and descriptions
/// Data is fetched from Supabase with fallback to defaults
class HowItWorksSection extends ConsumerWidget {
  /// Section title
  final String title;

  /// Section subtitle
  final String? subtitle;

  const HowItWorksSection({
    super.key,
    this.title = 'How It Works',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(howItWorksStepsProvider);

    return stepsAsync.when(
      data: (steps) => _buildContent(context, steps),
      loading: () => _buildLoading(context),
      error: (error, stack) => _buildContent(context, defaultSteps), // Fallback on error
    );
  }

  Widget _buildContent(BuildContext context, List<HowItWorksStep> steps) {
    if (steps.isEmpty) {
      return const SizedBox.shrink(); // Hide section if no steps
    }

    final effectiveSteps = steps;

    return Container(
      width: double.infinity,
      color: context.isMobile
          ? null
          : (Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariantLight),
      padding: EdgeInsets.symmetric(
        vertical: context.sectionSpacing,
      ),
      child: MaxWidthContainer(
        maxWidth: AppDimensions.containerXL,
        padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
        child: Column(
          children: [
            // Section header
            _buildHeader(context),

            SizedBox(height: context.isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL),

            // Steps grid
            ResponsiveBuilder(
              mobile: (context, constraints) => _buildMobileLayout(effectiveSteps),
              tablet: (context, constraints) => _buildTabletLayout(effectiveSteps, context),
              desktop: (context, constraints) => _buildDesktopLayout(effectiveSteps),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: context.isMobile ? AppTypography.h2 : AppTypography.h1,
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            subtitle!,
            style: AppTypography.bodyLarge.copyWith(
              color: context.textColorSecondary,
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
            StepCard(step: step, stepNumber: index + 1),
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
      children: steps.asMap().entries.map((entry) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - AppDimensions.spaceL * 3) / 2,
          child: StepCard(step: entry.value, stepNumber: entry.key + 1),
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
                child: StepCard(step: step, stepNumber: index + 1),
              ),
              if (index < steps.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
                  child: Icon(
                    Icons.arrow_forward,
                    color: AppColors.primary,
                    size: AppDimensions.iconL,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: context.sectionSpacing,
        horizontal: context.horizontalPadding,
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Step card widget
class StepCard extends StatelessWidget {
  final HowItWorksStep step;
  final int stepNumber;

  const StepCard({
    super.key,
    required this.step,
    required this.stepNumber,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard.elevated(
      elevation: 1,
      enableHover: true,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Column(
          children: [
            // Step number badge
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glowPrimary,
              ),
              child: Center(
                child: Icon(
                  step.icon,
                  color: context.textColorInverted,
                  size: AppDimensions.iconL,
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.spaceM),

            // Step title
            Text(
              step.title,
              style: AppTypography.h3.copyWith(
                fontWeight: AppTypography.weightBold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimensions.spaceS),

            // Step description
            Text(
              step.description,
              style: AppTypography.bodyMedium.copyWith(
                color: context.textColorSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
