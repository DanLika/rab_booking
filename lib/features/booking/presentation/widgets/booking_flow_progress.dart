import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../providers/booking_flow_notifier.dart';

/// Premium booking flow progress indicator with icons
/// Features: Step indicators with icons, labels, progress bar, responsive layout, animations
class BookingFlowProgress extends StatelessWidget {
  /// Current booking step
  final BookingStep currentStep;

  /// Show labels below steps
  final bool showLabels;

  /// Compact mode (smaller, for mobile)
  final bool compact;

  /// Show step icons instead of numbers
  final bool showIcons;

  const BookingFlowProgress({
    super.key,
    required this.currentStep,
    this.showLabels = true,
    this.compact = false,
    this.showIcons = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCompact = compact || context.isMobile;
    final allSteps = BookingStep.values;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: effectiveCompact ? AppDimensions.spaceM : AppDimensions.spaceL,
        horizontal: context.horizontalPadding,
      ),
      child: effectiveCompact
          ? _buildCompactProgress(context, allSteps)
          : _buildFullProgress(context, allSteps),
    );
  }

  Widget _buildFullProgress(BuildContext context, List<BookingStep> allSteps) {
    final currentStepIndex = currentStep.index;

    return Row(
      children: List.generate(allSteps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          return Expanded(
            child: _buildConnector(stepIndex < currentStepIndex),
          );
        } else {
          // Step indicator
          final stepIndex = index ~/ 2;
          final step = allSteps[stepIndex];
          return _buildStepIndicator(
            context,
            stepIndex,
            step,
            currentStepIndex,
            showLabels,
          );
        }
      }),
    );
  }

  Widget _buildCompactProgress(BuildContext context, List<BookingStep> allSteps) {
    final currentStepIndex = currentStep.index;

    return Column(
      children: [
        // Progress bar with gradient
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  tween: Tween<double>(
                    begin: 0,
                    end: (currentStepIndex + 1) / allSteps.length,
                  ),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceVariantLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.spaceS),

        // Current step label with icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              currentStep.icon,
              size: AppDimensions.iconS,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppDimensions.spaceXS),
            Text(
              'Korak ${currentStepIndex + 1} od ${allSteps.length}: ${currentStep.label}',
              style: AppTypography.small.copyWith(
                fontWeight: AppTypography.weightMedium,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator(
    BuildContext context,
    int stepIndex,
    BookingStep step,
    int currentStepIndex,
    bool showLabel,
  ) {
    final isCompleted = stepIndex < currentStepIndex;
    final isCurrent = stepIndex == currentStepIndex;
    final isUpcoming = stepIndex > currentStepIndex;

    return AnimatedScale(
      scale: isCurrent ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isCompleted || isCurrent
                  ? AppColors.primaryGradient
                  : null,
              color: isUpcoming ? AppColors.surfaceVariantLight : null,
              shape: BoxShape.circle,
              border: isUpcoming
                  ? Border.all(
                      color: AppColors.borderLight,
                      width: 2,
                    )
                  : null,
              boxShadow: isCurrent ? AppShadows.glowPrimary : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: AppDimensions.iconM,
                    )
                  : showIcons
                      ? Icon(
                          step.icon,
                          color: isCurrent
                              ? Colors.white
                              : AppColors.textSecondaryLight,
                          size: AppDimensions.iconM,
                        )
                      : Text(
                          '${stepIndex + 1}',
                          style: AppTypography.bodyLarge.copyWith(
                            color: isCurrent
                                ? Colors.white
                                : AppColors.textSecondaryLight,
                            fontWeight: AppTypography.weightBold,
                          ),
                        ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: AppDimensions.spaceXS),
            SizedBox(
              width: 80,
              child: Text(
                step.label,
                style: AppTypography.small.copyWith(
                  color: isCurrent
                      ? AppColors.primary
                      : AppColors.textSecondaryLight,
                  fontWeight: isCurrent
                      ? AppTypography.weightSemibold
                      : AppTypography.weightRegular,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnector(bool isCompleted) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXS),
      decoration: BoxDecoration(
        gradient: isCompleted ? AppColors.primaryGradient : null,
        color: !isCompleted ? AppColors.borderLight : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
    );
  }
}
