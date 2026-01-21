import 'package:flutter/material.dart';

import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../core/theme/gradient_extensions.dart';

/// Wizard Progress Bar - shows current step and completion status
/// Displays 4 steps with icons, labels, and visual indicators
class WizardProgressBar extends StatelessWidget {
  final int currentStep; // 1-4
  final int totalSteps; // Always 4
  final Map<int, bool> completedSteps; // {1: true, 2: true, ...}
  final Set<int> optionalSteps; // Empty - all steps required
  final Set<int> requiredSteps; // {1,2,3,4} - all steps required
  final Function(int)? onStepTap; // Optional - jump to step

  // Green color from Confirmed badge (#66BB6A)
  static const Color _completedColor = Color(0xFF66BB6A);

  // Step icons mapping
  static const Map<int, IconData> _stepIcons = {
    1: Icons.info_outline, // Info/Basic
    2: Icons.people_outline, // Capacity
    3: Icons.euro, // Pricing + Availability
    4: Icons.check_circle_outline, // Review
  };

  // Step labels mapping - returns localized labels
  static Map<int, String> _getStepLabels(AppLocalizations l10n) => {
    1: l10n.unitWizardProgressInfo,
    2: l10n.unitWizardProgressCapacity,
    3: l10n.unitWizardProgressPrice,
    4: l10n.unitWizardProgressReview,
  };

  const WizardProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
    this.completedSteps = const {},
    this.optionalSteps = const {},
    this.requiredSteps = const {1, 2, 3, 4},
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return _buildCompactProgressBar(context, theme, isDark, l10n);
    } else {
      return _buildFullProgressBar(context, theme, isDark, l10n);
    }
  }

  /// Full progress bar for desktop/tablet (shows all 5 steps)
  Widget _buildFullProgressBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        gradient: context.gradients.pageBackground,
        // Border removed for seamless gradient flow with content below
      ),
      child: Row(
        children: [
          for (int i = 1; i <= totalSteps; i++) ...[
            _buildStepIndicator(i, theme, isDark, l10n),
            if (i < totalSteps)
              Expanded(child: _buildConnector(i, theme, isDark)),
          ],
        ],
      ),
    );
  }

  /// Compact progress bar for mobile (shows "Step X of 5")
  Widget _buildCompactProgressBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final completedCount = completedSteps.values.where((v) => v).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: context.gradients.pageBackground,
        // Border removed for seamless gradient flow with content below
      ),
      child: Row(
        children: [
          // Current step indicator
          Text(
            l10n.unitWizardProgressStepOf(currentStep, totalSteps),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),

          // Progress indicator
          Expanded(
            child: LinearProgressIndicator(
              value: completedCount / totalSteps,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(
                _completedColor,
              ), // Green
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
          ),

          const SizedBox(width: 12),

          // Completion percentage
          Text(
            '${((completedCount / totalSteps) * 100).toInt()}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Step indicator (circle with icon/checkmark + label)
  Widget _buildStepIndicator(
    int step,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final isCompleted = completedSteps[step] == true;
    final isCurrent = step == currentStep;
    final isOptional = optionalSteps.contains(step);

    Color backgroundColor;
    Color borderColor;
    Color iconColor;

    if (isCompleted) {
      // Completed - green (#66BB6A from Confirmed badge)
      backgroundColor = _completedColor;
      borderColor = _completedColor;
      iconColor = Colors.white;
    } else if (isCurrent) {
      // Current - primary (purple)
      backgroundColor = theme.colorScheme.primary;
      borderColor = theme.colorScheme.primary;
      iconColor = Colors.white;
    } else {
      // Pending - gray outline
      backgroundColor = Colors.transparent;
      borderColor = theme.colorScheme.outline;
      iconColor = theme.colorScheme.onSurfaceVariant;
    }

    final stepIcon = _stepIcons[step] ?? Icons.circle;
    final stepLabels = _getStepLabels(l10n);
    final stepLabel = stepLabels[step] ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle with icon/checkmark
        InkWell(
          onTap: onStepTap != null ? () => onStepTap!(step) : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : Icon(stepIcon, size: 18, color: iconColor),
            ),
          ),
        ),

        const SizedBox(height: 2),

        // Step label (single word)
        Text(
          stepLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCompleted || isCurrent
                ? FontWeight.w600
                : FontWeight.w400,
            color: isCompleted
                ? _completedColor
                : isCurrent
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),

        // Optional badge (only for optional steps that are not completed)
        if (isOptional && !isCompleted)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l10n.unitWizardProgressOptional,
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  /// Connector line between steps
  Widget _buildConnector(int step, ThemeData theme, bool isDark) {
    final isCompleted = completedSteps[step] == true;

    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isCompleted
          ? _completedColor // Green for completed
          : theme.colorScheme.outline.withValues(alpha: 0.3),
    );
  }
}
