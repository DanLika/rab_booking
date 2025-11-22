import 'package:flutter/material.dart';

/// Wizard Progress Bar - shows current step and completion status
/// Displays 8 steps with visual indicators for completed, current, and pending
class WizardProgressBar extends StatelessWidget {
  final int currentStep; // 1-8
  final int totalSteps; // Always 8
  final Map<int, bool> completedSteps; // {1: true, 2: true, ...}
  final Set<int> optionalSteps; // {5, 7} - shows "optional" badge
  final Set<int> requiredSteps; // {1,2,3,4,6,8} - shows "*" indicator
  final Function(int)? onStepTap; // Optional - jump to step

  const WizardProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 8,
    this.completedSteps = const {},
    this.optionalSteps = const {5, 7},
    this.requiredSteps = const {1, 2, 3, 4, 6, 8},
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return _buildCompactProgressBar(theme, isDark);
    } else {
      return _buildFullProgressBar(theme, isDark);
    }
  }

  /// Full progress bar for desktop/tablet (shows all 8 steps)
  Widget _buildFullProgressBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
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
  Widget _buildCompactProgressBar(ThemeData theme, bool isDark) {
    final completedCount = completedSteps.values.where((v) => v).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
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
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
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

  /// Step indicator (circle with number/checkmark)
  Widget _buildStepIndicator(int step, ThemeData theme, bool isDark) {
    final isCompleted = completedSteps[step] == true;
    final isCurrent = step == currentStep;
    final isOptional = optionalSteps.contains(step);
    final isRequired = requiredSteps.contains(step);

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isCompleted) {
      // Completed - green
      backgroundColor = theme.colorScheme.tertiary;
      borderColor = theme.colorScheme.tertiary;
      textColor = Colors.white;
    } else if (isCurrent) {
      // Current - primary gradient
      backgroundColor = theme.colorScheme.primary;
      borderColor = theme.colorScheme.primary;
      textColor = Colors.white;
    } else {
      // Pending - gray
      backgroundColor = Colors.transparent;
      borderColor = theme.colorScheme.outline;
      textColor = theme.colorScheme.onSurfaceVariant;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle with number/checkmark
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
                  ? Icon(
                      Icons.check,
                      size: 20,
                      color: textColor,
                    )
                  : Text(
                      '$step',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Required/Optional badge
        if (isOptional)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Optional',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else if (isRequired && !isCompleted)
          Text(
            '*',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          )
        else
          const SizedBox(height: 16), // Spacing placeholder
      ],
    );
  }

  /// Connector line between steps
  Widget _buildConnector(int step, ThemeData theme, bool isDark) {
    final isCompleted = completedSteps[step] == true;

    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [theme.colorScheme.tertiary, theme.colorScheme.tertiary]
              : [
                  theme.colorScheme.outline.withValues(alpha: 0.3),
                  theme.colorScheme.outline.withValues(alpha: 0.3),
                ],
        ),
      ),
    );
  }
}
