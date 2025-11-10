import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../widgets/price_list_calendar_widget.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/widgets/common_gradient_app_bar.dart';
import '../providers/owner_calendar_provider.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Screen for managing unit pricing (base price and bulk month pricing)
/// Can be accessed from drawer (no unit selected) or from unit management (specific unit)
class UnitPricingScreen extends ConsumerStatefulWidget {
  final UnitModel? unit;

  const UnitPricingScreen({super.key, this.unit});

  @override
  ConsumerState<UnitPricingScreen> createState() => _UnitPricingScreenState();
}

class _UnitPricingScreenState extends ConsumerState<UnitPricingScreen> {
  final _basePriceController = TextEditingController();
  bool _isUpdatingBasePrice = false;
  UnitModel? _selectedUnit;

  @override
  void initState() {
    super.initState();
    // If unit is provided directly, use it
    if (widget.unit != null) {
      _selectedUnit = widget.unit;
      _basePriceController.text = widget.unit!.pricePerNight.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    super.dispose();
  }

  void _updateSelectedUnit(UnitModel unit) {
    setState(() {
      _selectedUnit = unit;
      _basePriceController.text = unit.pricePerNight.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // If unit was not provided, load all units and allow selection
    if (widget.unit == null) {
      final unitsAsync = ref.watch(allOwnerUnitsProvider);

      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: unitsAsync.when(
            data: (units) {
              if (units.isEmpty) {
                return _buildEmptyState();
              }

              // Auto-select first unit if none selected
              if (_selectedUnit == null || !units.contains(_selectedUnit)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _updateSelectedUnit(units.first);
                  }
                });
              }

              if (_selectedUnit == null) {
                return const SizedBox.shrink();
              }

              return _buildMainContent(
                isMobile: isMobile,
                units: units,
                showUnitSelector: true,
              );
            },
            loading: _buildLoadingState,
            error: (error, stack) => _buildErrorState(error),
          ),
        ),
      );
    }

    // Unit was provided (accessed from unit management)
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: _buildMainContent(
          isMobile: isMobile,
          units: null,
          showUnitSelector: false,
        ),
      ),
    );
  }

  Widget _buildMainContent({
    required bool isMobile,
    required List<UnitModel>? units,
    required bool showUnitSelector,
  }) {
    if (_selectedUnit == null) return const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        // Gradient header
        CommonGradientAppBar(
          title: 'Cjenovnik',
          leadingIcon: Icons.arrow_back,
          onLeadingIconTap: (context) => Navigator.of(context).pop(),
        ),

        // Unit selector (only when accessed from drawer)
        if (showUnitSelector && units != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 16 : 20,
                isMobile ? 16 : 24,
                isMobile ? 8 : 12,
              ),
              child: _buildUnitSelector(units, isMobile),
            ),
          ),

        // Base price section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 16 : 20,
              isMobile ? 16 : 24,
              isMobile ? 8 : 12,
            ),
            child: _buildBasePriceSection(isMobile),
          ),
        ),

        // Calendar section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 8 : 12,
              isMobile ? 16 : 24,
              isMobile ? 16 : 20,
            ),
            child: PriceListCalendarWidget(unit: _selectedUnit!),
          ),
        ),

        // Bottom spacing
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  Widget _buildUnitSelector(List<UnitModel> units, bool isMobile) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withAlpha((0.3 * 255).toInt()),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(
                      (0.1 * 255).toInt(),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.home_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Odaberi jedinicu',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Dropdown
            DropdownButtonFormField<UnitModel>(
              initialValue: _selectedUnit,
              decoration: InputDecoration(
                labelText: 'Jedinica',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.meeting_room_outlined),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(
                  (0.3 * 255).toInt(),
                ),
              ),
              items: units.map((unit) {
                return DropdownMenuItem(value: unit, child: Text(unit.name));
              }).toList(),
              onChanged: (unit) {
                if (unit != null) {
                  _updateSelectedUnit(unit);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        CommonGradientAppBar(
          title: 'Cjenovnik',
          leadingIcon: Icons.arrow_back,
          onLeadingIconTap: (context) => Navigator.of(context).pop(),
        ),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withAlpha(
                        (0.1 * 255).toInt(),
                      ),
                    ),
                    child: Icon(
                      Icons.meeting_room_outlined,
                      size: 70,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceL),
                  Text(
                    'Nemate dodane jedinice',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceS),
                  Text(
                    'Dodajte jedinicu kako biste mogli upravljati cijenama za vaše smještajne objekte.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.textColorSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        CommonGradientAppBar(
          title: 'Cjenovnik',
          leadingIcon: Icons.arrow_back,
          onLeadingIconTap: (context) => Navigator.of(context).pop(),
        ),
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        CommonGradientAppBar(
          title: 'Cjenovnik',
          leadingIcon: Icons.arrow_back,
          onLeadingIconTap: (context) => Navigator.of(context).pop(),
        ),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: AppDimensions.spaceM),
                  Text(
                    'Greška pri učitavanju jedinica',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXS),
                  Text(
                    error.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.textColorSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasePriceSection(bool isMobile) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0.5,
      shadowColor: theme.colorScheme.shadow.withAlpha((0.05 * 255).toInt()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha((0.1 * 255).toInt()),
          width: 0.5,
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
                    Icons.euro_outlined,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Osnovna Cijena',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ovo je default cijena po noćenju koja se koristi kada nema posebnih cijena.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.textColorSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Price input and save button - Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                // Use responsive breakpoint considering card padding and margins
                // Mobile/Small tablets: < 500px → Column (vertical stacking)
                // Desktop/Large tablets: >= 500px → Row (horizontal layout)
                final isVerySmall = constraints.maxWidth < 500;

                if (isVerySmall) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _basePriceController,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Cijena po noći (€)',
                          labelStyle: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          prefixText: '€ ',
                          prefixIcon: const Icon(Icons.euro_outlined, size: 20),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withAlpha((0.5 * 255).toInt()),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withAlpha(
                                (0.3 * 255).toInt(),
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withAlpha(
                                (0.25 * 255).toInt(),
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _isUpdatingBasePrice
                            ? null
                            : _updateBasePrice,
                        icon: _isUpdatingBasePrice
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Sačuvaj Cijenu'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _basePriceController,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Cijena po noći (€)',
                          labelStyle: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          prefixText: '€ ',
                          prefixIcon: const Icon(Icons.euro_outlined, size: 20),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withAlpha((0.5 * 255).toInt()),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withAlpha(
                                (0.3 * 255).toInt(),
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withAlpha(
                                (0.25 * 255).toInt(),
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isUpdatingBasePrice
                            ? null
                            : _updateBasePrice,
                        icon: _isUpdatingBasePrice
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Sačuvaj'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBasePrice() async {
    if (_selectedUnit == null) return;

    final priceText = _basePriceController.text.trim();
    if (priceText.isEmpty) {
      ErrorDisplayUtils.showWarningSnackBar(context, 'Unesite cijenu');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ErrorDisplayUtils.showWarningSnackBar(
        context,
        'Cijena mora biti veća od 0',
      );
      return;
    }

    setState(() => _isUpdatingBasePrice = true);

    try {
      final repository = ref.read(ownerPropertiesRepositoryProvider);
      await repository.updateUnit(
        propertyId: _selectedUnit!.propertyId,
        unitId: _selectedUnit!.id,
        basePrice: price,
      );

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Osnovna cijena uspješno ažurirana',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri ažuriranju cijene',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingBasePrice = false);
      }
    }
  }
}
