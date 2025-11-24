import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../state/unit_wizard_provider.dart';

/// Step 2: Capacity & Space - Bedrooms, Bathrooms, Max Guests, Area
class Step2Capacity extends ConsumerStatefulWidget {
  final String? unitId;

  const Step2Capacity({super.key, this.unitId});

  @override
  ConsumerState<Step2Capacity> createState() => _Step2CapacityState();
}

class _Step2CapacityState extends ConsumerState<Step2Capacity> {
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _maxGuestsController = TextEditingController();
  final _areaSqmController = TextEditingController();

  bool _isInitialized = false;

  @override
  void dispose() {
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _maxGuestsController.dispose();
    _areaSqmController.dispose();
    super.dispose();
  }

  void _loadData(dynamic draft) {
    if (_isInitialized) return;

    _bedroomsController.text = draft.bedrooms?.toString() ?? '';
    _bathroomsController.text = draft.bathrooms?.toString() ?? '';
    _maxGuestsController.text = draft.maxGuests?.toString() ?? '';
    _areaSqmController.text = draft.areaSqm?.toString() ?? '';
    _isInitialized = true;

    // Add listeners
    _bedroomsController.addListener(_onBedroomsChanged);
    _bathroomsController.addListener(_onBathroomsChanged);
    _maxGuestsController.addListener(_onMaxGuestsChanged);
    _areaSqmController.addListener(_onAreaChanged);
  }

  void _onBedroomsChanged() {
    final value = int.tryParse(_bedroomsController.text);
    ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('bedrooms', value);
  }

  void _onBathroomsChanged() {
    final value = int.tryParse(_bathroomsController.text);
    ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('bathrooms', value);
  }

  void _onMaxGuestsChanged() {
    final value = int.tryParse(_maxGuestsController.text);
    ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('maxGuests', value);
  }

  void _onAreaChanged() {
    final value = double.tryParse(_areaSqmController.text);
    ref.read(unitWizardNotifierProvider(widget.unitId).notifier).updateField('areaSqm', value);
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

        return Container(
          decoration: BoxDecoration(
            // TIP 1: JEDNOSTAVNI DIJAGONALNI GRADIENT (2 boje, 2 stops)
            // topLeft → bottomRight za body
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF1A1A1A), // veryDarkGray
                      Color(0xFF2D2D2D), // mediumDarkGray
                    ]
                  : const [
                      Color(0xFFF5F5F5), // Light grey
                      Colors.white,      // white
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
                  'Kapacitet i Prostor',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Unesite tehničke karakteristike smještajne jedinice',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Capacity Info Card - matching Step 1 styling
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
                                  Color(0xFF1A1A1A), // veryDarkGray
                                  Color(0xFF2D2D2D), // mediumDarkGray
                                ]
                              : const [
                                  Color(0xFFF5F5F5), // Light grey
                                  Colors.white,      // white
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
                                    Icons.home_work,
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Kapacitet Jedinice',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tehničke specifikacije smještaja',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 20),

                            // Bedrooms & Bathrooms Row
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _bedroomsController,
                                    decoration: InputDecorationHelper.buildDecoration(
                                      context,
                                      labelText: 'Spavaće Sobe *',
                                      hintText: '1',
                                      prefixIcon: const Icon(Icons.bed),
                                      isMobile: isMobile,
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Obavezno';
                                      }
                                      final number = int.tryParse(value);
                                      if (number == null || number < 0) {
                                        return 'Neispravan broj';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.spaceM),
                                Expanded(
                                  child: TextFormField(
                                    controller: _bathroomsController,
                                    decoration: InputDecorationHelper.buildDecoration(
                                      context,
                                      labelText: 'Kupatila *',
                                      hintText: '1',
                                      prefixIcon: const Icon(Icons.bathroom),
                                      isMobile: isMobile,
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Obavezno';
                                      }
                                      final number = int.tryParse(value);
                                      if (number == null || number < 0) {
                                        return 'Neispravan broj';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spaceM),

                            // Max Guests & Area Row
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _maxGuestsController,
                                    decoration: InputDecorationHelper.buildDecoration(
                                      context,
                                      labelText: 'Maksimalno Gostiju *',
                                      hintText: '2',
                                      prefixIcon: const Icon(Icons.people),
                                      isMobile: isMobile,
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Obavezno';
                                      }
                                      final number = int.tryParse(value);
                                      if (number == null || number < 1) {
                                        return 'Minimalno 1 gost';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.spaceM),
                                Expanded(
                                  child: TextFormField(
                                    controller: _areaSqmController,
                                    decoration: InputDecorationHelper.buildDecoration(
                                      context,
                                      labelText: 'Površina (m²)',
                                      hintText: '50',
                                      prefixIcon: const Icon(Icons.square_foot),
                                      isMobile: isMobile,
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                  ),
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

                // Info Card - Responsive width
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
                      Icon(
                        Icons.lightbulb_outline,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ove informacije pomažu gostima da odaberu odgovarajući smještaj',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
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
