import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../l10n/app_localizations.dart';
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
  final _weekendPriceController = TextEditingController();
  final _minStayController = TextEditingController();
  final _maxStayController = TextEditingController();

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Add listeners in initState - they will be active for all user input
    _priceController.addListener(_onPriceChanged);
    _weekendPriceController.addListener(_onWeekendPriceChanged);
    _minStayController.addListener(_onMinStayChanged);
    _maxStayController.addListener(_onMaxStayChanged);
  }

  @override
  void dispose() {
    // Remove listeners before disposing controllers
    _priceController.removeListener(_onPriceChanged);
    _weekendPriceController.removeListener(_onWeekendPriceChanged);
    _minStayController.removeListener(_onMinStayChanged);
    _maxStayController.removeListener(_onMaxStayChanged);
    _priceController.dispose();
    _weekendPriceController.dispose();
    _minStayController.dispose();
    _maxStayController.dispose();
    super.dispose();
  }

  void _loadData(dynamic draft) {
    if (_isInitialized) return;

    // Remove listeners temporarily to avoid triggering provider updates during build
    _priceController.removeListener(_onPriceChanged);
    _weekendPriceController.removeListener(_onWeekendPriceChanged);
    _minStayController.removeListener(_onMinStayChanged);
    _maxStayController.removeListener(_onMaxStayChanged);

    // Set initial values
    _priceController.text = draft.pricePerNight?.toString() ?? '';
    _weekendPriceController.text = draft.weekendBasePrice?.toString() ?? '';
    _minStayController.text = draft.minStayNights?.toString() ?? '';
    _maxStayController.text = draft.maxStayNights?.toString() ?? '';
    _isInitialized = true;

    // Re-attach listeners after setting initial values
    _priceController.addListener(_onPriceChanged);
    _weekendPriceController.addListener(_onWeekendPriceChanged);
    _minStayController.addListener(_onMinStayChanged);
    _maxStayController.addListener(_onMaxStayChanged);
  }

  void _onPriceChanged() {
    final value = double.tryParse(_priceController.text);
    ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('pricePerNight', value);
  }

  void _onWeekendPriceChanged() {
    final value = double.tryParse(_weekendPriceController.text);
    ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('weekendBasePrice', value);
  }

  void _onMinStayChanged() {
    final value = int.tryParse(_minStayController.text);
    ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('minStayNights', value);
  }

  void _onMaxStayChanged() {
    final value = int.tryParse(_maxStayController.text);
    ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('maxStayNights', value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wizardState = ref.watch(unitWizardNotifierProvider(widget.unitId));
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return wizardState.when(
      data: (draft) {
        _loadData(draft);

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
                  l10n.unitWizardStep3Title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  l10n.unitWizardStep3Subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                        color: context.gradients.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.gradients.sectionBorder, width: 1.5),
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
                                    color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.euro, color: theme.colorScheme.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.unitWizardStep3PriceInfo,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.unitWizardStep3PriceInfoDesc,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                                          labelText: l10n.unitWizardStep3PricePerNight,
                                          hintText: l10n.unitWizardStep3PricePerNightHint,
                                          helperText: l10n.unitWizardStep3PricePerNightHelper,
                                          prefixIcon: const Icon(Icons.euro),
                                          isMobile: isMobile,
                                          context: context,
                                        ),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return l10n.unitWizardStep3PriceRequired;
                                          }
                                          final number = double.tryParse(value);
                                          if (number == null || number <= 0) {
                                            return l10n.unitWizardStep3PriceInvalid;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppDimensions.spaceM),
                                      // Weekend price (optional)
                                      TextFormField(
                                        controller: _weekendPriceController,
                                        decoration: InputDecorationHelper.buildDecoration(
                                          labelText: l10n.unitWizardStep3WeekendPrice,
                                          hintText: l10n.unitWizardStep3WeekendPriceHint,
                                          helperText: l10n.unitWizardStep3WeekendPriceHelper,
                                          prefixIcon: const Icon(Icons.weekend),
                                          isMobile: isMobile,
                                          context: context,
                                        ),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return null; // Weekend price is optional
                                          }
                                          final number = double.tryParse(value);
                                          if (number == null || number <= 0) {
                                            return l10n.unitWizardStep3PriceInvalid;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppDimensions.spaceM),
                                      // Min stay nights
                                      TextFormField(
                                        controller: _minStayController,
                                        decoration: InputDecorationHelper.buildDecoration(
                                          labelText: l10n.unitWizardStep3MinStay,
                                          hintText: l10n.unitWizardStep3MinStayHint,
                                          helperText: l10n.unitWizardStep3MinStayHelper,
                                          prefixIcon: const Icon(Icons.calendar_today),
                                          isMobile: isMobile,
                                          context: context,
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return l10n.unitWizardStep3MinStayRequired;
                                          }
                                          final number = int.tryParse(value);
                                          if (number == null || number < 1) {
                                            return l10n.unitWizardStep3MinStayMin;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppDimensions.spaceM),
                                      // Max stay nights (optional)
                                      TextFormField(
                                        controller: _maxStayController,
                                        decoration: InputDecorationHelper.buildDecoration(
                                          labelText: l10n.unitWizardStep3MaxStay,
                                          hintText: l10n.unitWizardStep3MaxStayHint,
                                          helperText: l10n.unitWizardStep3MaxStayHelper,
                                          prefixIcon: const Icon(Icons.date_range),
                                          isMobile: isMobile,
                                          context: context,
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return null; // Max stay is optional
                                          }
                                          final number = int.tryParse(value);
                                          if (number == null || number < 1) {
                                            return l10n.unitWizardStep3MaxStayInvalid;
                                          }
                                          // Check that max >= min
                                          final minStay = int.tryParse(_minStayController.text) ?? 1;
                                          if (number < minStay) {
                                            return l10n.unitWizardStep3MaxStayMinError(minStay);
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  );
                                }

                                // Row layout for larger screens - use Expanded for maximum space
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Price per night - flexible width
                                        Expanded(
                                          child: TextFormField(
                                            controller: _priceController,
                                            decoration: InputDecorationHelper.buildDecoration(
                                              labelText: l10n.unitWizardStep3PricePerNight,
                                              hintText: l10n.unitWizardStep3PricePerNightHint,
                                              helperText: l10n.unitWizardStep3PricePerNightHelper,
                                              prefixIcon: const Icon(Icons.euro),
                                              isMobile: isMobile,
                                              context: context,
                                            ),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                            ],
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return l10n.unitWizardStep3PriceRequired;
                                              }
                                              final number = double.tryParse(value);
                                              if (number == null || number <= 0) {
                                                return l10n.unitWizardStep3PriceInvalid;
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Weekend price (optional) - flexible width
                                        Expanded(
                                          child: TextFormField(
                                            controller: _weekendPriceController,
                                            decoration: InputDecorationHelper.buildDecoration(
                                              labelText: l10n.unitWizardStep3WeekendPrice,
                                              hintText: l10n.unitWizardStep3WeekendPriceHint,
                                              helperText: l10n.unitWizardStep3WeekendPriceHelper,
                                              prefixIcon: const Icon(Icons.weekend),
                                              isMobile: isMobile,
                                              context: context,
                                            ),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                            ],
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return null; // Weekend price is optional
                                              }
                                              final number = double.tryParse(value);
                                              if (number == null || number <= 0) {
                                                return l10n.unitWizardStep3PriceInvalid;
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppDimensions.spaceM),
                                    // Min/Max stay nights - side by side on desktop
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _minStayController,
                                            decoration: InputDecorationHelper.buildDecoration(
                                              labelText: l10n.unitWizardStep3MinStay,
                                              hintText: l10n.unitWizardStep3MinStayHint,
                                              helperText: l10n.unitWizardStep3MinStayHelper,
                                              prefixIcon: const Icon(Icons.calendar_today),
                                              isMobile: isMobile,
                                              context: context,
                                            ),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return l10n.unitWizardStep3MinStayRequired;
                                              }
                                              final number = int.tryParse(value);
                                              if (number == null || number < 1) {
                                                return l10n.unitWizardStep3MinStayMin;
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _maxStayController,
                                            decoration: InputDecorationHelper.buildDecoration(
                                              labelText: l10n.unitWizardStep3MaxStay,
                                              hintText: l10n.unitWizardStep3MaxStayHint,
                                              helperText: l10n.unitWizardStep3MaxStayHelper,
                                              prefixIcon: const Icon(Icons.date_range),
                                              isMobile: isMobile,
                                              context: context,
                                            ),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return null; // Max stay is optional
                                              }
                                              final number = int.tryParse(value);
                                              if (number == null || number < 1) {
                                                return l10n.unitWizardStep3MaxStayInvalid;
                                              }
                                              // Check that max >= min
                                              final minStay = int.tryParse(_minStayController.text) ?? 1;
                                              if (number < minStay) {
                                                return l10n.unitWizardStep3MaxStayMinError(minStay);
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
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
                        color: context.gradients.cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.gradients.sectionBorder, width: 1.5),
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
                                    color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.unitWizardStep3Availability,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.unitWizardStep3AvailabilityDesc,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 20),

                            // Year-round toggle
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.unitWizardStep3YearRound, style: theme.textTheme.titleMedium),
                              subtitle: Text(
                                l10n.unitWizardStep3YearRoundDesc,
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                              trailing: Switch(
                                value: draft.availableYearRound,
                                onChanged: (value) {
                                  ref
                                      .read(unitWizardNotifierProvider(widget.unitId).notifier)
                                      .updateField('availableYearRound', value);
                                },
                                activeThumbColor: theme.colorScheme.primary,
                                activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),

                // Info card about advanced pricing options in Cjenovnik tab
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withAlpha((0.3 * 255).toInt()),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.secondary.withAlpha((0.3 * 255).toInt())),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, color: theme.colorScheme.secondary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.unitWizardStep3AdvancedTitle,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.unitWizardStep3AdvancedDesc,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
