import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/design_tokens/animation_tokens.dart';
import '../../l10n/app_localizations.dart';

/// Global error state widget with retry functionality and modern styling.
///
/// Displays an error icon, title, description, and action buttons.
/// Used throughout the app to provide consistent error UI.
class ErrorStateWidget extends StatelessWidget {
  /// The main error message or title.
  final String message;

  /// Detailed description of the error (optional).
  final String? description;

  /// Callback for the primary retry action.
  final VoidCallback? onRetry;

  /// Custom label for the retry button (default: "Try Again").
  final String? actionLabel;

  /// Optional secondary action widget (e.g., "Contact Support").
  final Widget? secondaryAction;

  /// Custom icon (default: Error outline).
  final IconData? icon;

  /// Compact mode for smaller spaces (reduced padding/sizing).
  final bool compact;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.description,
    this.onRetry,
    this.actionLabel,
    this.secondaryAction,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Design tokens
    final iconSize = compact ? 32.0 : 48.0;
    final iconBgSize = compact ? 64.0 : 80.0;
    final padding = compact ? AppDimensions.spaceM : 24.0;

    // Colors
    final errorColor = isDark ? AppColors.errorLight : AppColors.error;
    final bgGradientColors = [
      errorColor.withValues(alpha: 0.1),
      errorColor.withValues(alpha: 0.05),
    ];

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with soft background
            Container(
              width: iconBgSize,
              height: iconBgSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: bgGradientColors,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: iconSize,
                color: errorColor,
              ),
            ).animate().scale(
              duration: AnimationTokens.normal,
              curve: AnimationTokens.fastOutSlowIn,
            ),

            SizedBox(height: compact ? 12 : 24),

            // Title
            Text(
              message,
              textAlign: TextAlign.center,
              style: compact
                  ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                  : theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),

            // Description
            if (description != null) ...[
              SizedBox(height: compact ? 4 : 8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
            ],

            // Actions
            if (onRetry != null || secondaryAction != null) ...[
              SizedBox(height: compact ? 16 : 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (onRetry != null)
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(actionLabel ?? (l10n?.tryAgain ?? 'Try Again')),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 16 : 24,
                          vertical: compact ? 8 : 12,
                        ),
                      ),
                    ),
                  if (secondaryAction != null) secondaryAction!,
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
