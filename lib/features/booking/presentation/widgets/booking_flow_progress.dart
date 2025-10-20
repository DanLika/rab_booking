import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Premium booking flow progress indicator
/// Features: Step indicators, labels, progress bar, responsive layout
class BookingFlowProgress extends StatelessWidget {
  /// Current step index (0-based)
  final int currentStep;

  /// List of step labels
  final List<String> steps;

  /// Show labels below steps
  final bool showLabels;

  /// Compact mode (smaller, for mobile)
  final bool compact;

  const BookingFlowProgress({
    super.key,
    required this.currentStep,
    required this.steps,
    this.showLabels = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCompact = compact || context.isMobile;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: effectiveCompact ? AppDimensions.spaceM : AppDimensions.spaceL,
        horizontal: context.horizontalPadding,
      ),
      child: effectiveCompact
          ? _buildCompactProgress(context)
          : _buildFullProgress(context),
    );
  }

  Widget _buildFullProgress(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          return Expanded(
            child: _buildConnector(stepIndex < currentStep),
          );
        } else {
          // Step indicator
          final stepIndex = index ~/ 2;
          return _buildStepIndicator(
            stepIndex,
            steps[stepIndex],
            showLabels,
          );
        }
      }),
    );
  }

  Widget _buildCompactProgress(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                child: LinearProgressIndicator(
                  value: (currentStep + 1) / steps.length,
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceVariantLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.spaceS),

        // Current step label
        Text(
          'Step ${currentStep + 1} of ${steps.length}: ${steps[currentStep]}',
          style: AppTypography.small.copyWith(
            fontWeight: AppTypography.weightMedium,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int stepIndex, String label, bool showLabel) {
    final isCompleted = stepIndex < currentStep;
    final isCurrent = stepIndex == currentStep;
    final isUpcoming = stepIndex > currentStep;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
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
                    Icons.check,
                    color: Colors.white,
                    size: AppDimensions.iconM,
                  )
                : Text(
                    '${stepIndex + 1}',
                    style: AppTypography.bodyLarge.copyWith(
                      color: isCurrent || isCompleted
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
              label,
              style: AppTypography.small.copyWith(
                color: isCurrent
                    ? AppColors.primary
                    : AppColors.textSecondaryLight,
                fontWeight:
                    isCurrent ? AppTypography.weightSemibold : AppTypography.weightRegular,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConnector(bool isCompleted) {
    return Container(
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

/// Booking flow steps enum
enum BookingStep {
  confirmation,
  guestDetails,
  payment,
  review,
}

extension BookingStepExtension on BookingStep {
  String get label {
    switch (this) {
      case BookingStep.confirmation:
        return 'Confirmation';
      case BookingStep.guestDetails:
        return 'Guest Details';
      case BookingStep.payment:
        return 'Payment';
      case BookingStep.review:
        return 'Review';
    }
  }

  int get index {
    switch (this) {
      case BookingStep.confirmation:
        return 0;
      case BookingStep.guestDetails:
        return 1;
      case BookingStep.payment:
        return 2;
      case BookingStep.review:
        return 3;
    }
  }
}
