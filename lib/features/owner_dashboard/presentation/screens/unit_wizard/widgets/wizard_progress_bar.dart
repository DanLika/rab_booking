import 'package:flutter/material.dart';

import '../../../../../../core/theme/gradient_extensions.dart';

/// Wizard Progress Bar - shows current step and completion status
/// Displays 5 steps with icons, labels, and visual indicators
class WizardProgressBar extends StatelessWidget {
  final int currentStep; // 1-5
  final int totalSteps; // Always 5
  final Map<int, bool> completedSteps; // {1: true, 2: true, ...}
  final Set<int> optionalSteps; // {4} - Photos step is optional
  final Set<int> requiredSteps; // {1,2,3,5} - required steps
  final Function(int)? onStepTap; // Optional - jump to step

  // Green color from Confirmed badge (#66BB6A)
  static const Color _completedColor = Color(0xFF66BB6A);

  // Step icons mapping
  static const Map<int, IconData> _stepIcons = {
    1: Icons.info_outline,           // Info/Basic
    2: Icons.people_outline,         // Capacity
    3: Icons.euro,                   // Pricing + Availability
    4: Icons.photo_library_outlined, // Photos
    5: Icons.check_circle_outline,   // Review
  };

  // Step labels mapping (single word)
  static const Map<int, String> _stepLabels = {
    1: 'Info',
    2: 'Kapacitet',
    3: 'Cena',
    4: 'Fotografije',
    5: 'Pregled',
  };

  const WizardProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
    this.completedSteps = const {},
    this.optionalSteps = const {4},
    this.requiredSteps = const {1, 2, 3, 5},
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return _buildCompactProgressBar(context, theme, isDark);
    } else {
      return _buildFullProgressBar(context, theme, isDark);
    }
  }

  /// Full progress bar for desktop/tablet (shows all 8 steps)
  Widget _buildFullProgressBar(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: context.gradients.pageBackground,
        // Border removed for seamless gradient flow with content below
      ),
      child: Row(
        children: [
          for (int i = 1; i <= totalSteps; i++) ...[
            _buildStepIndicator(i, theme, isDark),
            if (i < totalSteps)
              Expanded(
                child: _buildConnector(i, theme, isDark),
              ),
          ],
        ],
      ),
    );
  }

  /// Compact progress bar for mobile (shows "Step X of 8")
  Widget _buildCompactProgressBar(BuildContext context, ThemeData theme, bool isDark) {
    final completedCount = completedSteps.values.where((v) => v).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: context.gradients.pageBackground,
        // Border removed for seamless gradient flow with content below
      ),
      child: Row(
        children: [
          // Current step indicator
          Text(
            'Step $currentStep of $totalSteps',
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
              valueColor: const AlwaysStoppedAnimation(_completedColor), // Green
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
  Widget _buildStepIndicator(int step, ThemeData theme, bool isDark) {
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
    final stepLabel = _stepLabels[step] ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle with icon/checkmark
        InkWell(
          onTap: onStepTap != null ? () => onStepTap!(step) : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 20,
                      color: Colors.white,
                    )
                  : Icon(
                      stepIcon,
                      size: 20,
                      color: iconColor,
                    ),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Step label (single word)
        Text(
          stepLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCompleted || isCurrent ? FontWeight.w600 : FontWeight.w400,
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
              '(opcionalno)',
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
