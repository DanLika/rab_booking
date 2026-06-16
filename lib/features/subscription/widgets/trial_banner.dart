import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router_owner.dart';
import '../../../core/design/tokens.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/trial_status_provider.dart';

/// Banner widget that shows trial status warnings
///
/// Displays:
/// - Yellow banner when trial is expiring soon (7, 3, 1 days)
/// - Red banner when trial has expired
/// - Nothing when user has active subscription or plenty of trial time
class TrialBanner extends ConsumerWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trialStatusAsync = ref.watch(trialStatusProvider);

    return trialStatusAsync.when(
      data: (trialStatus) {
        if (trialStatus == null) return const SizedBox.shrink();

        // Don't show banner for active subscribers
        if (trialStatus.isActive) return const SizedBox.shrink();

        // Show expired banner
        if (trialStatus.isTrialExpired) {
          return _ExpiredBanner(
            onUpgrade: () => _navigateToSubscription(context),
          );
        }

        // Show warning banner if expiring soon
        if (trialStatus.isExpiringSoon) {
          return _ExpiringBanner(
            daysRemaining: trialStatus.daysRemaining,
            onUpgrade: () => _navigateToSubscription(context),
          );
        }

        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _navigateToSubscription(BuildContext context) {
    context.push(OwnerRoutes.subscription);
  }
}

/// Banner for expiring trial
class _ExpiringBanner extends StatelessWidget {
  final int daysRemaining;
  final VoidCallback onUpgrade;

  const _ExpiringBanner({required this.daysRemaining, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Handoff `--bb-warning(-tint)`; AA amber `--bb-status-pending` for
    // light-tint foregrounds (audit/121).
    final warning = isDark ? BBColor.warningDarkMode : BBColor.warning;
    final fg = isDark ? BBColor.textPrimaryDark : BBColor.statusPending;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // FLAT (gradient retired 2026-06-16): single warning tint, no fade.
        color: warning.withValues(alpha: isDark ? 0.16 : 0.12),
        border: Border(
          bottom: BorderSide(color: warning.withValues(alpha: 0.4)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, color: fg, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                daysRemaining == 1
                    ? 'Probno razdoblje istječe sutra!'
                    : 'Probno razdoblje istječe za $daysRemaining dana',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: onUpgrade,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.warningDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Nadogradi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner for expired trial
class _ExpiredBanner extends StatelessWidget {
  final VoidCallback onUpgrade;

  const _ExpiredBanner({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Handoff `--bb-error(-tint)`, dark lift (audit/121).
    final error = isDark ? BBColor.errorDarkMode : BBColor.error;
    final fg = isDark ? BBColor.textPrimaryDark : AppColors.errorDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // FLAT (gradient retired 2026-06-16): single error tint, no fade.
        color: error.withValues(alpha: isDark ? 0.16 : 0.11),
        border: Border(bottom: BorderSide(color: error.withValues(alpha: 0.4))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: fg, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Probno razdoblje je isteklo. Nadogradite za nastavak.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: onUpgrade,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.errorDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Nadogradi sada'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact trial indicator for app bar or drawer
class TrialIndicator extends ConsumerWidget {
  const TrialIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trialStatusAsync = ref.watch(trialStatusProvider);

    return trialStatusAsync.when(
      data: (trialStatus) {
        if (trialStatus == null) return const SizedBox.shrink();
        if (trialStatus.isActive) return const SizedBox.shrink();

        final isExpired = trialStatus.isTrialExpired;
        final daysRemaining = trialStatus.daysRemaining;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isExpired ? Colors.red.shade100 : Colors.amber.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExpired ? Colors.red.shade300 : Colors.amber.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isExpired
                    ? Icons.warning_amber_rounded
                    : Icons.access_time_rounded,
                size: 14,
                color: isExpired ? Colors.red.shade700 : Colors.amber.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                isExpired ? 'Expired' : '$daysRemaining days',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isExpired
                      ? Colors.red.shade700
                      : Colors.amber.shade700,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
