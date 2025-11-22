import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../state/unit_wizard_provider.dart';
import '../widgets/wizard_step_container.dart';

/// Step 8: Review & Publish - Final review before creating the unit
class Step8Review extends ConsumerWidget {
  final String? unitId;

  const Step8Review({super.key, this.unitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(unitWizardNotifierProvider(unitId));
    final theme = Theme.of(context);

    return wizardState.when(
      data: (draft) {
        // Check if all required steps are completed
        final allRequiredCompleted = _validateAllRequiredSteps(draft);

        return WizardStepContainer(
          title: 'Pregled i Objava',
          subtitle: 'Pregledajte sve informacije prije objave jedinice',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Validation Warning (if incomplete)
              if (!allRequiredCompleted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: theme.colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Molimo popunite sve obavezne korake prije objave',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),
              ],

              // Summary sections
              _buildSummarySection(
                context,
                theme,
                'Osnovne Informacije',
                Icons.info_outline,
                [
                  _buildSummaryRow('Naziv', draft.name ?? '-'),
                  _buildSummaryRow('Slug', draft.slug ?? '-'),
                  if (draft.description != null && draft.description!.isNotEmpty)
                    _buildSummaryRow('Opis', draft.description!),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceM),

              _buildSummarySection(
                context,
                theme,
                'Kapacitet',
                Icons.people,
                [
                  _buildSummaryRow('Spavaće sobe', draft.bedrooms?.toString() ?? '-'),
                  _buildSummaryRow('Kupatila', draft.bathrooms?.toString() ?? '-'),
                  _buildSummaryRow('Max gostiju', draft.maxGuests?.toString() ?? '-'),
                  if (draft.areaSqm != null)
                    _buildSummaryRow('Površina', '${draft.areaSqm} m²'),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceM),

              _buildSummarySection(
                context,
                theme,
                'Cene',
                Icons.euro,
                [
                  _buildSummaryRow(
                    'Cena po noći',
                    draft.pricePerNight != null ? '€${draft.pricePerNight}' : '-',
                  ),
                  _buildSummaryRow(
                    'Min. boravak',
                    draft.minStayNights != null ? '${draft.minStayNights} noći' : '-',
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceM),

              _buildSummarySection(
                context,
                theme,
                'Dostupnost',
                Icons.calendar_today,
                [
                  _buildSummaryRow(
                    'Tokom godine',
                    draft.availableYearRound ? 'Da' : 'Sezonski',
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Success info card
              if (allRequiredCompleted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: theme.colorScheme.tertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sve obavezne informacije su popunjene. Kliknite "Publish" za objavljivanje jedinice.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  bool _validateAllRequiredSteps(dynamic draft) {
    return draft.name != null &&
        draft.name!.isNotEmpty &&
        draft.slug != null &&
        draft.slug!.isNotEmpty &&
        draft.bedrooms != null &&
        draft.bathrooms != null &&
        draft.maxGuests != null &&
        draft.pricePerNight != null &&
        draft.minStayNights != null;
  }

  Widget _buildSummarySection(
    BuildContext context,
    ThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
