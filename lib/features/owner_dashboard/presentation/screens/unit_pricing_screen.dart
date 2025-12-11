import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../widgets/price_list_calendar_widget.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/owner_properties_provider.dart';

/// Screen for managing unit pricing (base price and bulk month pricing)
/// Can be accessed from drawer (no unit selected) or from unit management (specific unit)
class UnitPricingScreen extends ConsumerStatefulWidget {
  final UnitModel? unit;
  final bool showAppBar;

  const UnitPricingScreen({super.key, this.unit, this.showAppBar = true});

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
    final l10n = AppLocalizations.of(context);
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
              l10n: l10n,
            );
          }

          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: CommonAppBar(
              title: l10n.unitPricingTitle,
              leadingIcon: Icons.arrow_back,
              onLeadingIconTap: (context) => Navigator.of(context).pop(),
            ),
            body: _buildMainContent(
              isMobile: isMobile,
              units: units,
              showUnitSelector: true,
              l10n: l10n,
            ),
          );
        },
        loading: () => _buildLoadingState(l10n),
        error: (error, stack) => _buildErrorState(error, l10n),
      );
    }

    // Unit was provided (accessed from unit management)
    // When showAppBar is false, return only content (for embedding in tabs)
    if (!widget.showAppBar) {
      return _buildMainContent(
        isMobile: isMobile,
        units: null,
        showUnitSelector: false,
        l10n: l10n,
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CommonAppBar(
        title: l10n.unitPricingTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: _buildMainContent(
        isMobile: isMobile,
        units: null,
        showUnitSelector: false,
        l10n: l10n,
      ),
    );
  }

  Widget _buildMainContent({
    required bool isMobile,
    required List<UnitModel>? units,
    required bool showUnitSelector,
    required AppLocalizations l10n,
  }) {
    if (_selectedUnit == null) return const SizedBox.shrink();

    final padding = context.horizontalPadding;
    final gap = isMobile ? 8.0 : 16.0;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Unit selector (only when accessed from drawer)
          if (showUnitSelector && units != null)
            Padding(
              padding: EdgeInsets.fromLTRB(padding, padding, padding, gap),
              child: _buildUnitSelector(units, isMobile, l10n),
            ),

          // Base price section
          Padding(
            padding: EdgeInsets.fromLTRB(padding, padding, padding, gap),
            child: _buildBasePriceSection(isMobile, l10n),
          ),

          // Calendar section
          Padding(
            padding: EdgeInsets.fromLTRB(padding, gap, padding, padding),
            child: PriceListCalendarWidget(unit: _selectedUnit!),
          ),

          // Bottom spacing
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUnitSelector(
    List<UnitModel> units,
    bool isMobile,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final cardPadding = context.horizontalPadding;

    return Card(
      elevation: 0.5,
      shadowColor: theme.colorScheme.shadow.withAlpha((0.05 * 255).toInt()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.gradients.sectionBorder, width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.gradients.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
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
                      l10n.unitPricingSelectUnit,
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
                dropdownColor: InputDecorationHelper.getDropdownColor(context),
                hint: Text(l10n.unitPricingSelectUnitHint), // Shown when null
                decoration: InputDecorationHelper.buildDecoration(
                  labelText: l10n.unitPricingUnit,
                  prefixIcon: const Icon(Icons.meeting_room_outlined),
                  context: context,
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CommonAppBar(
        title: l10n.unitPricingTitle,
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
                l10n.unitPricingNoUnits,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                l10n.unitPricingNoUnitsDesc,
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

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CommonAppBar(
        title: l10n.unitPricingTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(Object error, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CommonAppBar(
        title: l10n.unitPricingTitle,
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
                l10n.unitPricingLoadError,
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

  Widget _buildBasePriceSection(bool isMobile, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final sectionPadding = context.horizontalPadding;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(
          1,
          isDark: theme.brightness == Brightness.dark,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.gradients.sectionBorder,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(sectionPadding),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.unitPricingBasePrice,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 40,
                            decoration: BoxDecoration(
                              gradient: GradientTokens.brandPrimary,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.unitPricingBasePriceDesc,
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
                    final priceInput = _buildPriceTextField(theme, l10n);
                    final saveButton = _buildSaveButton(
                      theme,
                      isVerySmall,
                      l10n,
                    );

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
                        SizedBox(
                          width: 250,
                          child: priceInput,
                        ), // Match month dropdown width
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

  Widget _buildPriceTextField(ThemeData theme, AppLocalizations l10n) {
    return TextField(
      controller: _basePriceController,
      decoration: InputDecorationHelper.buildDecoration(
        labelText: l10n.unitPricingPricePerNight,
        prefixIcon: const Icon(Icons.euro_outlined),
        context: context,
      ).copyWith(prefixText: '€ '),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _buildSaveButton(
    ThemeData theme,
    bool isVerySmall,
    AppLocalizations l10n,
  ) {
    // Use brand gradient for consistent button styling
    return Container(
      decoration: BoxDecoration(
        gradient: GradientTokens.brandPrimary,
        borderRadius: BorderRadius.circular(12), // Consistent with inputs
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isUpdatingBasePrice ? null : _updateBasePrice,
          borderRadius: BorderRadius.circular(12), // Consistent with inputs
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10, // Reduced from 20 (width -20px)
              vertical: isVerySmall
                  ? 13
                  : 15, // Reduced from 14/16 (height -3px)
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
                  isVerySmall
                      ? l10n.unitPricingSavePrice
                      : l10n.unitPricingSave,
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

    final l10n = AppLocalizations.of(context);
    final priceText = _basePriceController.text.trim();
    if (priceText.isEmpty) {
      ErrorDisplayUtils.showWarningSnackBar(
        context,
        l10n.unitPricingEnterPrice,
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ErrorDisplayUtils.showWarningSnackBar(
        context,
        l10n.unitPricingPriceGreaterThanZero,
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

      // Update local state immediately for responsive UI
      _selectedUnit = _selectedUnit!.copyWith(pricePerNight: price);

      // Invalidate BOTH unit providers to refresh data across app
      // - allOwnerUnitsProvider: used by calendar, timeline
      // - ownerUnitsProvider: used by unified_unit_hub_screen (stream-based)
      ref.invalidate(allOwnerUnitsProvider);
      ref.invalidate(ownerUnitsProvider);

      if (mounted) {
        // Try to show success message, but don't crash if no Scaffold available
        try {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10n.unitPricingSuccessUpdate,
          );
        } catch (scaffoldError) {
          // Embedded in tab without Scaffold - silently succeed
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.unitPricingErrorUpdate,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingBasePrice = false);
      }
    }
  }
}
