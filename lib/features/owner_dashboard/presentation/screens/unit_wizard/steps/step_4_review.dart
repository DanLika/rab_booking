import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/theme/gradient_extensions.dart';
import '../../../../../../shared/models/additional_service_model.dart';
import '../../../../../../shared/repositories/firebase/firebase_additional_services_repository.dart';
import '../state/unit_wizard_provider.dart';

/// Step 4: Review & Publish - Final review before creating the unit
class Step4Review extends ConsumerWidget {
  final String? unitId;

  const Step4Review({super.key, this.unitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final wizardState = ref.watch(unitWizardNotifierProvider(unitId));
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDesktop = screenWidth >= 900;

    return wizardState.when(
      data: (draft) {
        // Check if all required steps are completed
        final allRequiredCompleted = _validateAllRequiredSteps(draft);

        // Build the 4 summary cards
        final basicInfoCard = _buildSummaryCard(
          context,
          theme,
          isMobile,
          l10n.unitWizardStep5BasicInfo,
          Icons.info_outline,
          [
            _buildSummaryRow(
              theme,
              l10n.unitWizardStep5Name,
              draft.name ?? '-',
            ),
            _buildSummaryRow(
              theme,
              l10n.unitWizardStep5Slug,
              draft.slug ?? '-',
            ),
            if (draft.description != null && draft.description!.isNotEmpty)
              _buildSummaryRow(
                theme,
                l10n.unitWizardStep5Description,
                draft.description!,
              ),
          ],
        );

        final capacityCard = _buildSummaryCard(
          context,
          theme,
          isMobile,
          l10n.unitWizardStep5Capacity,
          Icons.people,
          [
            _buildSummaryRow(
              theme,
              l10n.unitWizardStep5Bedrooms,
              draft.bedrooms?.toString() ?? '-',
            ),
            _buildSummaryRow(
              theme,
              l10n.unitWizardStep5Bathrooms,
              draft.bathrooms?.toString() ?? '-',
            ),
            _buildSummaryRow(
              theme,
              l10n.unitWizardStep5MaxGuests,
              draft.maxGuests?.toString() ?? '-',
            ),
            if (draft.areaSqm != null)
              _buildSummaryRow(
                theme,
                l10n.unitWizardStep5Area,
                '${draft.areaSqm} m²',
              ),
            if (draft.maxTotalCapacity != null &&
                draft.maxGuests != null &&
                draft.maxTotalCapacity! > draft.maxGuests!)
              _buildSummaryRow(
                theme,
                l10n.unitWizardStep5ExtraBeds,
                '${draft.maxTotalCapacity! - draft.maxGuests!}',
              ),
            if (draft.extraBedFee != null)
              _buildSummaryRow(
                theme,
                l10n.unitWizardStep5ExtraBedFee,
                '€${draft.extraBedFee}/night',
              ),
            if (draft.maxPets != null)
              _buildSummaryRow(
                theme,
                l10n.unitWizardStep5MaxPets,
                '${draft.maxPets}',
              ),
            if (draft.petFee != null)
              _buildSummaryRow(
                theme,
                l10n.unitWizardStep5PetFee,
                '€${draft.petFee}/night',
              ),
          ],
        );

        final pricingCard = _buildSummaryCard(
          context,
          theme,
          isMobile,
          l10n.unitWizardStep5Pricing,
          Icons.euro,
          [
            _buildSummaryRow(
              theme,
              l10n.unitWizardStep5PricePerNight,
              draft.pricePerNight != null ? '€${draft.pricePerNight}' : '-',
            ),
            _buildSummaryRow(
              theme,
              l10n.unitWizardStep5MinStay,
              draft.minStayNights != null
                  ? l10n.unitWizardStep5MinStayNights(draft.minStayNights!)
                  : '-',
            ),
          ],
        );

        final availabilityCard = _buildSummaryCard(
          context,
          theme,
          isMobile,
          l10n.unitWizardStep5AvailabilityCard,
          Icons.calendar_today,
          [
            _buildSummaryRow(
              theme,
              l10n.unitWizardStep5YearRound,
              draft.availableYearRound
                  ? l10n.unitWizardStep5YearRoundYes
                  : l10n.unitWizardStep5YearRoundSeasonal,
            ),
          ],
        );

        // Services card - loaded from Firestore if unitId exists
        final servicesCard = unitId != null
            ? _buildServicesCard(
                context,
                ref,
                theme,
                isMobile,
                l10n,
                draft.propertyId,
              )
            : null;

        // Horizontal gradient (left → right) - matches footer gradient for seamless transition
        return Container(
          decoration: BoxDecoration(gradient: context.gradients.pageBackground),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  l10n.unitWizardStep5Title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  l10n.unitWizardStep5Subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Validation Warning (if incomplete) - responsive width (24px radius to match sections)
                if (!allRequiredCompleted) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(24),
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
                            l10n.unitWizardStep5IncompleteWarning,
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

                // Summary Cards - 2x2 grid on desktop, stacked on mobile
                if (isDesktop) ...[
                  // First row: Osnovne Informacije + Cijene
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: basicInfoCard),
                      const SizedBox(width: 16),
                      Expanded(child: pricingCard),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Second row: Kapacitet + Dostupnost
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: capacityCard),
                      const SizedBox(width: 16),
                      Expanded(child: availabilityCard),
                    ],
                  ),
                  if (servicesCard != null) ...[
                    const SizedBox(height: 16),
                    servicesCard,
                  ],
                ] else ...[
                  // Mobile/Tablet: stacked layout
                  basicInfoCard,
                  const SizedBox(height: 16),
                  pricingCard,
                  const SizedBox(height: 16),
                  capacityCard,
                  const SizedBox(height: 16),
                  availabilityCard,
                  if (servicesCard != null) ...[
                    const SizedBox(height: 16),
                    servicesCard,
                  ],
                ],
                const SizedBox(height: AppDimensions.spaceL),

                // Success info card - responsive width (24px radius to match sections)
                if (allRequiredCompleted) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.tertiary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.unitWizardStep5ReadyMessage,
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
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
    );
  }

  Widget _buildServicesCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isMobile,
    AppLocalizations l10n,
    String? propertyId,
  ) {
    if (propertyId == null || unitId == null) return const SizedBox.shrink();

    final repo = ref.read(additionalServicesRepositoryProvider);
    return FutureBuilder<List<AdditionalServiceModel>>(
      future: repo.fetchByUnit(propertyId: propertyId, unitId: unitId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final services = snapshot.data!;
        return _buildSummaryCard(
          context,
          theme,
          isMobile,
          l10n.additionalServicesTitle,
          Icons.room_service,
          services
              .map((s) => _buildSummaryRow(theme, s.name, s.formattedPrice))
              .toList(),
        );
      },
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

  /// Build a summary card with consistent styling matching input fields
  Widget _buildSummaryCard(
    BuildContext context,
    ThemeData theme,
    bool isMobile,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            // TIP 1: JEDNOSTAVNI DIJAGONALNI GRADIENT (2 boje, 2 stops)
            // Section cards: topRight → bottomLeft (tamniji desno 30%, svjetliji lijevo 70%)
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.gradients.sectionBorder,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon - Minimalist
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Content rows
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
