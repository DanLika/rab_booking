import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// Error state widget for calendar
/// Shows when an error occurs while loading data
class CalendarErrorState extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool isCompact;

  const CalendarErrorState({super.key, this.errorMessage, this.onRetry, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (isCompact) {
      return _buildCompactError(context, theme, l10n);
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.red.withAlpha((0.1 * 255).toInt()), shape: BoxShape.circle),
                child: Icon(Icons.error_outline, size: 64, color: Colors.red.withAlpha((0.7 * 255).toInt())),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                l10n.calendarErrorTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color?.withAlpha((0.8 * 255).toInt()),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Error message
              Text(
                errorMessage ?? l10n.calendarErrorDefault,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withAlpha((0.6 * 255).toInt()),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Retry button
                  if (onRetry != null)
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: Text(l10n.calendarErrorRetry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Secondary action (if needed)
                  OutlinedButton.icon(
                    onPressed: () {
                      // Could open support dialog or navigate to help
                    },
                    icon: const Icon(Icons.help_outline, size: 20),
                    label: Text(l10n.calendarErrorHelp),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactError(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.withAlpha((0.6 * 255).toInt())),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? l10n.calendarErrorCompact,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyLarge?.color?.withAlpha((0.7 * 255).toInt()),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.calendarErrorRetry),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline error banner for smaller errors
class CalendarErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const CalendarErrorBanner({super.key, required this.message, this.onDismiss, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withAlpha((0.3 * 255).toInt())),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.calendarErrorBannerTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(message, style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: l10n.calendarErrorRetry,
              color: Colors.red.shade700,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              tooltip: l10n.calendarErrorClose,
              color: Colors.red.shade700,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }
}
