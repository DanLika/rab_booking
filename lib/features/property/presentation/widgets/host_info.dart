import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../providers/host_info_provider.dart';
import 'contact_host_dialog.dart';

/// Host info widget with dynamic data from Supabase
class HostInfo extends ConsumerWidget {
  const HostInfo({
    required this.ownerId,
    required this.propertyId,
    required this.propertyName,
    super.key,
  });

  final String ownerId;
  final String propertyId;
  final String propertyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hostInfoAsync = ref.watch(hostInfoProvider(ownerId));

    return hostInfoAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.surfaceVariantColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.surfaceVariantColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Text(
          'Greška pri učitavanju informacija o domaćinu',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textColorSecondary,
              ),
        ),
      ),
      data: (hostStats) {
        final user = hostStats.user;
        final hostName = user.fullName;
        final memberSince = user.createdAt.year;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.surfaceVariantColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vaš domaćin',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(context).primaryColor,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.initials,
                            style: TextStyle(
                              color: context.textColorInverted,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 16),

                  // Host info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              hostName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (hostStats.isSuperhost) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Superhost',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Član od $memberSince.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.textColorSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(color: context.dividerColor),
              const SizedBox(height: 20),

              // Host stats
              Row(
                children: [
                  Expanded(
                    child: _HostStat(
                      icon: Icons.reviews_outlined,
                      value: hostStats.reviewCount.toString(),
                      label: 'Recenzija',
                    ),
                  ),
                  Expanded(
                    child: _HostStat(
                      icon: Icons.star_outline,
                      value: hostStats.reviewCount > 0
                          ? hostStats.averageRating.toStringAsFixed(1)
                          : 'N/A',
                      label: 'Ocjena',
                    ),
                  ),
                  Expanded(
                    child: _HostStat(
                      icon: Icons.home_outlined,
                      value: hostStats.propertyCount.toString(),
                      label: 'Smještaji',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Contact button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ContactHostDialog(
                        hostId: ownerId,
                        hostName: hostName,
                        propertyId: propertyId,
                        propertyName: propertyName,
                      ),
                    );
                  },
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Kontaktiraj domaćina'),
                ),
              ),

              const SizedBox(height: 16),

              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.security,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Radi zaštite vaših plaćanja, nikada ne prenosite novac ili komunicirajte izvan aplikacije.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HostStat extends StatelessWidget {
  const _HostStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: context.iconColorSecondary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.textColorSecondary,
              ),
        ),
      ],
    );
  }
}
