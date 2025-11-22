import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../state/unit_wizard_provider.dart';
import '../widgets/wizard_step_container.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return wizardState.when(
      data: (draft) {
        _loadData(draft);

        return WizardStepContainer(
          title: 'Cene i Pravila',
          subtitle: 'Postavite osnovnu cenu i minimalan broj noći',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: AppDimensions.spaceL),

              // Seasonal pricing placeholder
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
                          Icons.calendar_month,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sezonske Cene',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
