import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/theme/gradient_extensions.dart';
import '../state/unit_wizard_provider.dart';

/// Step 5: Review & Publish - Final review before creating the unit
class Step5Review extends ConsumerWidget {
  final String? unitId;

  const Step5Review({super.key, this.unitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Osnovne Informacije',
          Icons.info_outline,
          [
            _buildSummaryRow(theme, 'Naziv', draft.name ?? '-'),
            _buildSummaryRow(theme, 'Slug', draft.slug ?? '-'),
            if (draft.description != null && draft.description!.isNotEmpty)
              _buildSummaryRow(theme, 'Opis', draft.description!),
          ],
        );

        final capacityCard = _buildSummaryCard(
          context,
          theme,
          isMobile,
          'Kapacitet',
          Icons.people,
          [
            _buildSummaryRow(theme, 'Spavaće sobe', draft.bedrooms?.toString() ?? '-'),
            _buildSummaryRow(theme, 'Kupatila', draft.bathrooms?.toString() ?? '-'),
            _buildSummaryRow(theme, 'Max gostiju', draft.maxGuests?.toString() ?? '-'),
            if (draft.areaSqm != null)
              _buildSummaryRow(theme, 'Površina', '${draft.areaSqm} m²'),
          ],
        );

        final pricingCard = _buildSummaryCard(
          context,
          theme,
          isMobile,
          'Cijene',
          Icons.euro,
          [
            _buildSummaryRow(
              theme,
              'Cena po noći',
              draft.pricePerNight != null ? '€${draft.pricePerNight}' : '-',
            ),
            _buildSummaryRow(
              theme,
              'Min. boravak',
              draft.minStayNights != null ? '${draft.minStayNights} noći' : '-',
            ),
          ],
        );

        final availabilityCard = _buildSummaryCard(
          context,
          theme,
          isMobile,
          'Dostupnost',
          Icons.calendar_today,
          [
            _buildSummaryRow(
              theme,
              'Tokom godine',
              draft.availableYearRound ? 'Da' : 'Sezonski',
            ),
          ],
        );

        // Horizontal gradient (left → right) - matches footer gradient for seamless transition
        return Container(
          decoration: BoxDecoration(
            gradient: context.gradients.pageBackground,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Pregled i Objava',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Pregledajte sve informacije prije objave jedinice',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Validation Warning (if incomplete) - responsive width
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
                ] else ...[
                  // Mobile/Tablet: stacked layout
                  basicInfoCard,
                  const SizedBox(height: 16),
                  pricingCard,
                  const SizedBox(height: 16),
                  capacityCard,
                  const SizedBox(height: 16),
                  availabilityCard,
                ],
                const SizedBox(height: AppDimensions.spaceL),

                // Success info card - responsive width
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
            gradient: context.gradients.sectionBackground,
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
                        color: theme.colorScheme.primary.withAlpha(
                          (0.12 * 255).toInt(),
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
