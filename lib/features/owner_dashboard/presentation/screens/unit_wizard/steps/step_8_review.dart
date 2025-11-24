import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../state/unit_wizard_provider.dart';

/// Step 8: Review & Publish - Final review before creating the unit
class Step8Review extends ConsumerWidget {
  final String? unitId;

  const Step8Review({super.key, this.unitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(unitWizardNotifierProvider(unitId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return wizardState.when(
      data: (draft) {
        // Check if all required steps are completed
        final allRequiredCompleted = _validateAllRequiredSteps(draft);

        return Container(
          decoration: BoxDecoration(
            // TIP 1: JEDNOSTAVNI DIJAGONALNI GRADIENT (2 boje, 2 stops)
            // topRight → bottomLeft za body background (matching section cards)
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? const [
                      Color(0xFF2D2D2D), // mediumDarkGray (lighter) - RIGHT
                      Color(0xFF1A1A1A), // veryDarkGray (darker) - LEFT
                    ]
                  : const [
                      Colors.white,      // white (lighter) - RIGHT
                      Color(0xFFF5F5F5), // Light grey (darker) - LEFT
                    ],
              stops: const [0.0, 0.3],
            ),
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

                // Summary Card with all sections
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
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
                        // topRight → bottomLeft za section
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: isDark
                              ? const [
                                  Color(0xFF2D2D2D), // mediumDarkGray (lighter) - RIGHT
                                  Color(0xFF1A1A1A), // veryDarkGray (darker) - LEFT
                                ]
                              : const [
                                  Colors.white,      // white (lighter) - RIGHT
                                  Color(0xFFF5F5F5), // Light grey (darker) - LEFT
                                ],
                          stops: const [0.0, 0.3],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.4),
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
                                    Icons.summarize,
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Sažetak Jedinice',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pregledajte sve unesene informacije',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 20),

                            // Summary sections
                            _buildSummarySection(
                              context,
                              theme,
                              'Osnovne Informacije',
                              Icons.info_outline,
                              [
                                _buildSummaryRow(theme, 'Naziv', draft.name ?? '-'),
                                _buildSummaryRow(theme, 'Slug', draft.slug ?? '-'),
                                if (draft.description != null && draft.description!.isNotEmpty)
                                  _buildSummaryRow(theme, 'Opis', draft.description!),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spaceM),

                            _buildSummarySection(
                              context,
                              theme,
                              'Kapacitet',
                              Icons.people,
                              [
                                _buildSummaryRow(theme, 'Spavaće sobe', draft.bedrooms?.toString() ?? '-'),
                                _buildSummaryRow(theme, 'Kupatila', draft.bathrooms?.toString() ?? '-'),
                                _buildSummaryRow(theme, 'Max gostiju', draft.maxGuests?.toString() ?? '-'),
                                if (draft.areaSqm != null)
                                  _buildSummaryRow(theme, 'Površina', '${draft.areaSqm} m²'),
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
                            ),
                            const SizedBox(height: AppDimensions.spaceM),

                            _buildSummarySection(
                              context,
                              theme,
                              'Dostupnost',
                              Icons.calendar_today,
                              [
                                _buildSummaryRow(
                                  theme,
                                  'Tokom godine',
                                  draft.availableYearRound ? 'Da' : 'Sezonski',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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

  Widget _buildSummaryRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
