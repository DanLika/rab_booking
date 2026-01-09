import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _navigateToSubscription(BuildContext context) {
    // TODO: Navigate to subscription screen when implemented
    // context.push('/subscription');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription screen coming soon!')),
    );
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade100, Colors.amber.shade50],
        ),
        border: Border(bottom: BorderSide(color: Colors.amber.shade300)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: Colors.amber.shade800,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                daysRemaining == 1
                    ? 'Your trial ends tomorrow!'
                    : 'Your trial ends in $daysRemaining days',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: onUpgrade,
              style: TextButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Upgrade'),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade100, Colors.red.shade50],
        ),
        border: Border(bottom: BorderSide(color: Colors.red.shade300)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade800,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your trial has expired. Upgrade to continue.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: onUpgrade,
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Upgrade Now'),
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
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
