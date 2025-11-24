import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../state/unit_wizard_provider.dart';

/// Step 3: Pricing - Price per night, Min stay, Seasonal pricing
class Step3Pricing extends ConsumerStatefulWidget {
  final String? unitId;

  const Step3Pricing({super.key, this.unitId});

  @override
  ConsumerState<Step3Pricing> createState() => _Step3PricingState();
}

class _Step3PricingState extends ConsumerState<Step3Pricing> {
  final _priceController = TextEditingController();
  final _minStayController = TextEditingController();

  bool _isInitialized = false;

  @override
  void dispose() {
    _priceController.dispose();
    _minStayController.dispose();
    super.dispose();
  }

  void _loadData(dynamic draft) {
    if (_isInitialized) return;

    _priceController.text = draft.pricePerNight?.toString() ?? '';
    _minStayController.text = draft.minStayNights?.toString() ?? '';
    _isInitialized = true;

    // Add listeners
    _priceController.addListener(_onPriceChanged);
    _minStayController.addListener(_onMinStayChanged);
  }

  void _onPriceChanged() {
    final value = double.tryParse(_priceController.text);
    ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('pricePerNight', value);
  }

  void _onMinStayChanged() {
    final value = int.tryParse(_minStayController.text);
    ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('minStayNights', value);
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(unitWizardNotifierProvider(widget.unitId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return wizardState.when(
      data: (draft) {
        _loadData(draft);

        // TIP 1: JEDNOSTAVNI DIJAGONALNI GRADIENT (2 boje, 2 stops)
        // topRight → bottomLeft za body background (matching section cards)
        return Container(
          decoration: BoxDecoration(
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
                  'Cene i Pravila',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Postavite osnovnu cenu i minimalan broj noći',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Pricing Info Card - matching Step 1 & 2 styling
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
                                    Icons.euro,
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Informacije o Cijeni',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Osnovna cijena i pravila rezervacije',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 20),

                            // Price per night
                            TextFormField(
                              controller: _priceController,
                              decoration: InputDecorationHelper.buildDecoration(
                                context,
                                labelText: 'Cena po Noći (€) *',
                                hintText: '50',
                                prefixIcon: const Icon(Icons.euro),
                                isMobile: isMobile,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Cena je obavezna';
                                }
                                final number = double.tryParse(value);
                                if (number == null || number <= 0) {
                                  return 'Unesite ispravnu cenu';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppDimensions.spaceM),

                            // Min stay nights
                            TextFormField(
                              controller: _minStayController,
                              decoration: InputDecorationHelper.buildDecoration(
                                context,
                                labelText: 'Minimalan Boravak (noći) *',
                                hintText: '1',
                                helperText: 'Najmanje noći za rezervaciju',
                                prefixIcon: const Icon(Icons.calendar_today),
                                isMobile: isMobile,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Minimalan boravak je obavezan';
                                }
                                final number = int.tryParse(value);
                                if (number == null || number < 1) {
                                  return 'Minimum je 1 noć';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),

                // Seasonal pricing placeholder - responsive width
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sezonske Cene',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Napredna konfiguracija sezonskih cena biće dostupna nakon kreiranja jedinice.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
}
