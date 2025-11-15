import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Empty state widget for calendar
/// Shows when no bookings are available
class CalendarEmptyState extends StatelessWidget {
  final String? message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final bool isFiltered;

  const CalendarEmptyState({
    super.key,
    this.message,
    this.actionLabel,
    this.onActionPressed,
    this.isFiltered = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFiltered ? Icons.filter_list_off : Icons.event_busy,
                  size: 64,
                  color: AppColors.primary.withAlpha((0.5 * 255).toInt()),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                isFiltered ? 'Nema rezultata' : 'Nema rezervacija',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color?.withAlpha((0.7 * 255).toInt()),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                message ??
                    (isFiltered
                        ? 'Pokušajte promijeniti filtere ili odabrati drugi datum'
                        : 'Još nema rezervacija za ovaj period'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withAlpha((0.6 * 255).toInt()),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Action button
              if (onActionPressed != null)
                ElevatedButton.icon(
                  onPressed: onActionPressed,
                  icon: Icon(
                    isFiltered ? Icons.clear_all : Icons.add,
                    size: 20,
                  ),
                  label: Text(
                    actionLabel ??
                        (isFiltered ? 'Očisti filtere' : 'Dodaj rezervaciju'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state for calendar - compact version for smaller spaces
class CalendarEmptyStateCompact extends StatelessWidget {
  final String message;
  final IconData icon;

  const CalendarEmptyStateCompact({
    super.key,
    required this.message,
    this.icon = Icons.event_busy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.textTheme.bodyLarge?.color?.withAlpha((0.3 * 255).toInt()),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyLarge?.color?.withAlpha((0.5 * 255).toInt()),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
