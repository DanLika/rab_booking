import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_color_extensions.dart';
import '../../../../core/theme/app_shadows.dart';
import '../widgets/price_list_calendar_widget.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../providers/owner_calendar_provider.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Screen for managing unit pricing (base price and bulk month pricing)
/// Can be accessed from drawer (no unit selected) or from unit management (specific unit)
class UnitPricingScreen extends ConsumerStatefulWidget {
  final UnitModel? unit;
  final bool showAppBar;

  const UnitPricingScreen({
    super.key,
    this.unit,
    this.showAppBar = true,
  });

  @override
  ConsumerState<UnitPricingScreen> createState() => _UnitPricingScreenState();
}

class _UnitPricingScreenState extends ConsumerState<UnitPricingScreen> {
  final _basePriceController = TextEditingController();
  bool _isUpdatingBasePrice = false;
  UnitModel? _selectedUnit;
  bool _hasScheduledAutoSelect = false; // Flag to prevent multiple callbacks

  @override
  void initState() {
    super.initState();
    // If unit is provided directly, use it
    if (widget.unit != null) {
      _selectedUnit = widget.unit;
      // Safe handling of pricePerNight to prevent crashes
      final price = widget.unit!.pricePerNight;
      _basePriceController.text = _formatPrice(price);
    }
  }

  /// Safely format price with validation
  /// Returns '0' for null, NaN, infinity, or negative values
  String _formatPrice(double? price) {
    if (price == null || price.isNaN || price.isInfinite || price < 0) {
      return '0';
    }
    return price.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    super.dispose();
  }

  void _updateSelectedUnit(UnitModel unit) {
    setState(() {
      _selectedUnit = unit;
      // Safe handling of pricePerNight to prevent crashes
      _basePriceController.text = _formatPrice(unit.pricePerNight);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // If unit was not provided, load all units and allow selection
    if (widget.unit == null) {
      final unitsAsync = ref.watch(allOwnerUnitsProvider);

      return unitsAsync.when(
        data: (units) {
          if (units.isEmpty) {
            return _buildEmptyState();
          }

          // Auto-select first unit if none selected
          // Use flag to prevent adding multiple callbacks on rebuild
          if ((_selectedUnit == null || !units.contains(_selectedUnit)) &&
              !_hasScheduledAutoSelect) {
            _hasScheduledAutoSelect = true; // Set flag BEFORE adding callback
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _updateSelectedUnit(units.first);
                // Reset flag after selection completes
                _hasScheduledAutoSelect = false;
              }
            });
          }

          if (_selectedUnit == null) {
            return const SizedBox.shrink();
          }

          // When showAppBar is false, return only content (for embedding in tabs)
          if (!widget.showAppBar) {
            return _buildMainContent(
              isMobile: isMobile,
              units: units,
              showUnitSelector: true,
            );
          }

          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: CommonAppBar(
              title: 'Cjenovnik',
              leadingIcon: Icons.arrow_back,
              onLeadingIconTap: (context) => Navigator.of(context).pop(),
            ),
            body: _buildMainContent(
              isMobile: isMobile,
              units: units,
              showUnitSelector: true,
            ),
          );
        },
        loading: _buildLoadingState,
        error: (error, stack) => _buildErrorState(error),
      );
    }

    // Unit was provided (accessed from unit management)
    // When showAppBar is false, return only content (for embedding in tabs)
    if (!widget.showAppBar) {
      return _buildMainContent(
        isMobile: isMobile,
        units: null,
        showUnitSelector: false,
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBar(
        title: 'Cjenovnik',
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: _buildMainContent(
        isMobile: isMobile,
        units: null,
        showUnitSelector: false,
      ),
    );
  }

  Widget _buildMainContent({
    required bool isMobile,
    required List<UnitModel>? units,
    required bool showUnitSelector,
  }) {
    if (_selectedUnit == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Unit selector (only when accessed from drawer)
          if (showUnitSelector && units != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 16 : 20,
                isMobile ? 16 : 24,
                isMobile ? 8 : 12,
              ),
              child: _buildUnitSelector(units, isMobile),
            ),

          // Base price section
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 16 : 20,
              isMobile ? 16 : 24,
              isMobile ? 8 : 12,
            ),
            child: _buildBasePriceSection(isMobile),
          ),

          // Calendar section
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 8 : 12,
              isMobile ? 16 : 24,
              isMobile ? 16 : 20,
            ),
            child: PriceListCalendarWidget(unit: _selectedUnit!),
          ),

          // Bottom spacing
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUnitSelector(List<UnitModel> units, bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark
                ? [
                    Theme.of(context).colorScheme.veryDarkGray, // #1A1A1A
                    Theme.of(context).colorScheme.mediumDarkGray, // #2D2D2D
                  ]
                : [
                    const Color(0xFFF5F5F5), // Light grey
                    Colors.white, // #FFFFFF
                  ],
            stops: const [0.0, 0.3],
          ),
          borderRadius: BorderRadius.circular(12),
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
              // Safe: null initialValue is acceptable, shows hint until selection
              initialValue: _selectedUnit,
              hint: const Text('Izaberite jedinicu'), // Shown when null
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
        ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CommonAppBar(
        title: 'Cjenovnik',
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: Center(
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
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CommonAppBar(
        title: 'Cjenovnik',
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(Object error) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CommonAppBar(
        title: 'Cjenovnik',
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: Center(
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
    );
  }

  Widget _buildBasePriceSection(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(3, isDark: isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? [
                      Theme.of(context).colorScheme.veryDarkGray, // #1A1A1A
                      Theme.of(context).colorScheme.mediumDarkGray, // #2D2D2D
                    ]
                  : [
                      const Color(0xFFF5F5F5), // Light grey (replaces F8F9FA)
                      Colors.white, // #FFFFFF
                    ],
              stops: const [0.0, 0.3],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.borderColor.withOpacity(0.4),
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

                // Extract common TextField widget
                final priceInput = _buildPriceTextField(theme);
                final saveButton = _buildSaveButton(theme, isVerySmall);

                if (isVerySmall) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      priceInput,
                      const SizedBox(height: 12),
                      saveButton,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 100, child: priceInput),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 180, // Same width as Bulk Edit buttons
                      child: saveButton,
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
    );
  }

  Widget _buildPriceTextField(ThemeData theme) {
    return TextField(
      controller: _basePriceController,
      decoration: InputDecoration(
        labelText: 'Cijena po noći (€)',
        prefixText: '€ ',
        prefixIcon: const Icon(Icons.euro_outlined),
        // Match dropdown styling: exact same decoration
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }

  Widget _buildSaveButton(ThemeData theme, bool isVerySmall) {
    // Use gradient button like app bar (Purple → Blue)
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6B4CE6), // Purple (same as app bar)
            Color(0xFF4A90E2), // Blue (same as app bar)
          ],
        ),
        borderRadius: BorderRadius.circular(10), // Same as input field
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isUpdatingBasePrice ? null : _updateBasePrice,
          borderRadius: BorderRadius.circular(10), // Same as input field
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10, // Reduced from 20 (width -20px)
              vertical: isVerySmall ? 13 : 15, // Reduced from 14/16 (height -3px)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center, // Center the content
              children: [
                _isUpdatingBasePrice
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check, // Modern check icon
                        size: 18,
                        color: Colors.white,
                      ),
                const SizedBox(width: 8),
                Text(
                  isVerySmall ? 'Sačuvaj Cijenu' : 'Sačuvaj',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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

      // Invalidate unit provider to refresh data across app
      ref.invalidate(allOwnerUnitsProvider);

      if (mounted) {
        // Try to show success message, but don't crash if no Scaffold available
        try {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            'Osnovna cijena uspješno ažurirana',
          );
        } catch (scaffoldError) {
          // Embedded in tab without Scaffold - silently succeed
          debugPrint('[PRICING] Price updated successfully (embedded mode)');
        }
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
