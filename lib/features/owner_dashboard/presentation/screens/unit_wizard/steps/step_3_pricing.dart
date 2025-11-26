import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/theme/gradient_extensions.dart';
import '../state/unit_wizard_provider.dart';

/// Step 3: Pricing & Availability - Price per night, Min stay, Year-round toggle
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
  void initState() {
    super.initState();
    // Add listeners in initState - they will be active for all user input
    _priceController.addListener(_onPriceChanged);
    _minStayController.addListener(_onMinStayChanged);
  }

  @override
  void dispose() {
    // Remove listeners before disposing controllers
    _priceController.removeListener(_onPriceChanged);
    _minStayController.removeListener(_onMinStayChanged);
    _priceController.dispose();
    _minStayController.dispose();
    super.dispose();
  }

  void _loadData(dynamic draft) {
    if (_isInitialized) return;

    // Remove listeners temporarily to avoid triggering provider updates during build
    _priceController.removeListener(_onPriceChanged);
    _minStayController.removeListener(_onMinStayChanged);

    // Set initial values
    _priceController.text = draft.pricePerNight?.toString() ?? '';
    _minStayController.text = draft.minStayNights?.toString() ?? '';
    _isInitialized = true;

    // Re-attach listeners after setting initial values
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return wizardState.when(
      data: (draft) {
        _loadData(draft);

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
                  'Cena i Dostupnost',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Postavite cenu, minimalan boravak i dostupnost',
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

                            // Responsive layout for Price and Min Stay fields
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Use same breakpoint as Step 1 (500px)
                                final isVerySmall = constraints.maxWidth < 500;

                                if (isVerySmall) {
                                  // Column layout for small screens
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Price per night
                                      TextFormField(
                                        controller: _priceController,
                                        decoration: InputDecorationHelper.buildDecoration(
                                          labelText: 'Cena po Noći (€) *',
                                          hintText: '50',
                                          helperText: 'Osnovna cena za jednu noć',
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
                                  );
                                }

                                // Row layout for larger screens - use Expanded for maximum space
                                return Row(
                                  children: [
                                    // Price per night - flexible width
                                    Expanded(
                                      child: TextFormField(
                                        controller: _priceController,
                                        decoration: InputDecorationHelper.buildDecoration(
                                          labelText: 'Cena po Noći (€) *',
                                          hintText: '50',
                                          helperText: 'Osnovna cena za jednu noć',
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
                                    ),
                                    const SizedBox(width: 16),
                                    // Min stay nights - flexible width
                                    Expanded(
                                      child: TextFormField(
                                        controller: _minStayController,
                                        decoration: InputDecorationHelper.buildDecoration(
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
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),

                // Availability Card - Year-round toggle
                Container(
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
                                    Icons.calendar_today,
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Dostupnost',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Postavite kada je jedinica dostupna za rezervacije',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 20),

                            // Year-round toggle
                            ListTile(
                              contentPadding: EdgeInsets.zero,
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
                              trailing: Switch(
                                value: draft.availableYearRound,
                                onChanged: (value) {
                                  ref
                                      .read(unitWizardNotifierProvider(widget.unitId).notifier)
                                      .updateField('availableYearRound', value);
                                },
                                thumbColor: WidgetStateProperty.all(Colors.transparent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),
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
