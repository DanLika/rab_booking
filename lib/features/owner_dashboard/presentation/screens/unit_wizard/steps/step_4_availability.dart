import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../state/unit_wizard_provider.dart';
import '../widgets/wizard_step_container.dart';

/// Step 4: Availability - Year-round toggle, Season dates, Blocked dates
class Step4Availability extends ConsumerStatefulWidget {
  final String? unitId;

  const Step4Availability({super.key, this.unitId});

  @override
  ConsumerState<Step4Availability> createState() => _Step4AvailabilityState();
}

class _Step4AvailabilityState extends ConsumerState<Step4Availability> {
  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(unitWizardNotifierProvider(widget.unitId));
    final theme = Theme.of(context);

    return wizardState.when(
      data: (draft) {
        final availableYearRound = draft.availableYearRound;

        return WizardStepContainer(
          title: 'Dostupnost',
          subtitle: 'Konfigurišite raspoloživost jedinice tokom godine',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Year-round toggle
              SwitchListTile(
                title: Text(
                  'Dostupna Tokom Cijele Godine',
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  'Jedinica je otvorena za rezervacije 365 dana godišnje',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: availableYearRound,
                onChanged: (value) {
                  ref
                      .read(unitWizardNotifierProvider(widget.unitId).notifier)
                      .updateField('availableYearRound', value);
                },
                activeTrackColor: theme.colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Season dates (if not year-round)
              if (!availableYearRound) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sezonske Datume',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Konfiguracija sezonskih datuma biće dostupna nakon kreiranja jedinice.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),
              ],

              // Blocked dates placeholder
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.block,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Blokirani Datumi',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Možete blokirati specifične datume nakon kreiranja jedinice putem kalendara.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
