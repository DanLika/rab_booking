import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../core/utils/platform_scroll_physics.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/models/property_model.dart';
import '../providers/owner_properties_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/animations/animated_empty_state.dart';
import 'unit_pricing_screen.dart';
import 'widget_settings_screen.dart';
import 'widget_advanced_settings_screen.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

/// Master panel width for desktop layout
const double _kMasterPanelWidth = 320.0;

/// Breakpoint for desktop layout (consistent with CLAUDE.md: Desktop ≥1200px)
const double _kDesktopBreakpoint =
    900.0; // Using 900 for this screen per existing behavior

/// Breakpoint for tablet layout (between mobile and desktop)
const double _kTabletBreakpoint = 800.0;

/// Breakpoint for mobile layout
const double _kMobileBreakpoint = 600.0;

/// Available status color
const Color _kAvailableColor = Color(0xFF66BB6A);

/// Unavailable status color
const Color _kUnavailableColor = Color(0xFFEF5350);

// ============================================================================

/// Unified Unit Hub - Centralno mjesto za sve unit operacije
/// Master-Detail layout sa tab navigacijom
class UnifiedUnitHubScreen extends ConsumerStatefulWidget {
  final String? initialUnitId;
  final String? initialPropertyId;
  final int initialTabIndex;
  final String? initialPropertyFilter;

  const UnifiedUnitHubScreen({
    super.key,
    this.initialUnitId,
    this.initialPropertyId,
    this.initialTabIndex = 0,
    this.initialPropertyFilter,
  });

  @override
  ConsumerState<UnifiedUnitHubScreen> createState() =>
      _UnifiedUnitHubScreenState();
}

class _UnifiedUnitHubScreenState extends ConsumerState<UnifiedUnitHubScreen>
    with SingleTickerProviderStateMixin {
  UnitModel? _selectedUnit;
  PropertyModel? _selectedProperty;
  late TabController _tabController;

  // GlobalKey for Scaffold to avoid context issues
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Deletion loading state
  bool _isDeleting = false;

  // Deletion loading state
  bool _isDeleting = false;

  // Vertical tabs with icon above text (compact design)
  List<Widget> _buildTabs(AppLocalizations l10n) {
    return [
      _buildTab(Icons.description_outlined, l10n.unitHubTabBasicInfo),
      _buildTab(Icons.payments_outlined, l10n.unitHubTabPricing),
      _buildTab(Icons.code, l10n.unitHubTabWidget),
      _buildTab(Icons.tune, l10n.unitHubTabAdvanced),
    ];
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      icon: Icon(icon, size: 22),
      text: label,
      height: 72, // Explicit height for vertical layout
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4, // 4 tabs: Basic Info, Pricing, Widget, Advanced
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Handle units data changes - auto-select first unit or sync selected unit
  /// OPTIMIZED: Accepts properties list to avoid N+1 query pattern
  void _handleUnitsChanged(
    List<UnitModel> units,
    List<PropertyModel> properties,
  ) {
    if (units.isNotEmpty && _selectedUnit == null) {
      // Auto-select first unit when none is selected
      final firstUnit = units.first;
      // OPTIMIZED: Find property from cached list instead of fetching
      final property = properties.firstWhere(
        (p) => p.id == firstUnit.propertyId,
        orElse: () => properties.first,
      );
      if (mounted) {
        setState(() {
          _selectedUnit = firstUnit;
          _selectedProperty = property;
        });
      }
    } else if (_selectedUnit != null) {
      // Update selected unit with fresh data from stream
      final updatedUnit = units.firstWhere(
        (u) => u.id == _selectedUnit!.id,
        orElse: () => _selectedUnit!,
      );
      // Only update if data actually changed
      if (updatedUnit != _selectedUnit && mounted) {
        setState(() {
          _selectedUnit = updatedUnit;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _kDesktopBreakpoint;

    // OPTIMIZED: Watch properties for use in units change handler
    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final properties = propertiesAsync.valueOrNull ?? [];

    // Listen for units changes and handle side effects (auto-selection, sync)
    ref.listen<AsyncValue<List<UnitModel>>>(ownerUnitsProvider, (
      previous,
      next,
    ) {
      next.whenData((units) => _handleUnitsChanged(units, properties));
    });

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: isDesktop
          ? CommonAppBar(
              title: l10n.unitHubTitle,
              leadingIcon: Icons.menu,
              onLeadingIconTap: (_) => _scaffoldKey.currentState?.openDrawer(),
            )
          : AppBar(
              title: Text(
                _selectedUnit?.name ?? l10n.unitHubTitle,
                style: const TextStyle(color: Colors.white),
              ),
              centerTitle: false,
              leadingWidth:
                  72, // Increased from default 56 to add more left padding
              leading: Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                ), // Additional left padding
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.list, color: Colors.white),
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  tooltip: l10n.unitHubShowAllUnits,
                ),
              ],
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: GradientTokens.brandPrimary,
                ),
              ),
            ),
      drawer: const OwnerAppDrawer(currentRoute: 'unit-hub'),
      // EndDrawer for mobile/tablet - shows master panel
      endDrawer: !isDesktop
          ? Drawer(
              width: _kMasterPanelWidth,
              child: Container(
                decoration: BoxDecoration(
                  gradient: context.gradients.sectionBackground,
                ),
                child: SafeArea(
                  bottom: false, // List handles its own bottom padding (80px)
                  child: Builder(
                    builder: (drawerContext) => _buildMasterPanel(
                      theme,
                      isDark,
                      onUnitSelected: () {
                        // Check if drawer context is still valid before popping
                        if (drawerContext.mounted) {
                          Navigator.of(drawerContext).pop();
                        }
                      },
                      isEndDrawer: true, // Mark as endDrawer for styling
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          Container(
            decoration:
                BoxDecoration(gradient: context.gradients.pageBackground),
            child: isDesktop
                ? _buildDesktopLayout(theme, isDark, screenWidth)
                : _buildMobileLayout(theme, isDark),
          ),
          if (_isDeleting)
            const LoadingOverlay(message: 'Deleting property...'),
        ],
      ),
    );
  }

  /// Desktop layout - Master-Detail sa split view
  /// Master panel je DESNO, Detail panel LIJEVO
  Widget _buildDesktopLayout(ThemeData theme, bool isDark, double screenWidth) {
    return Row(
      children: [
        // Detail panel (left) - Tab content
        Expanded(child: _buildDetailPanel(theme, isDark, screenWidth)),

        // Master panel (right) - Units list
        Container(
          width: _kMasterPanelWidth,
          decoration: BoxDecoration(
            gradient: context.gradients.sectionBackground,
            border: Border(
              left: BorderSide(
                color: context.gradients.sectionBorder,
                width: 1.5,
              ),
            ),
          ),
          child: _buildMasterPanel(theme, isDark),
        ),
      ],
    );
  }

  /// Mobile/Tablet layout - Full screen tabs
  /// EndDrawer pokazuje master panel sa listom jedinica
  Widget _buildMobileLayout(ThemeData theme, bool isDark) {
    // Samo prikaži detail panel - master panel je u endDrawer-u
    final screenWidth = MediaQuery.of(context).size.width;
    return _buildDetailPanel(theme, isDark, screenWidth);
  }

  /// Master panel - Properties and Units list (hierarchical view)
  Widget _buildMasterPanel(
    ThemeData theme,
    bool isDark, {
    VoidCallback? onUnitSelected,
    bool isEndDrawer = false,
  }) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // Header
        Container(
          padding: isEndDrawer
              ? const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16,
                ) // SafeArea handles top padding for endDrawer
              : const EdgeInsets.fromLTRB(
                  16,
                  36,
                  16,
                  16,
                ), // Increased top padding for desktop sidebar
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.home_work_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.unitHubPropertiesAndUnits,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Add Property button
                  IconButton(
                    icon: const Icon(Icons.add_business, size: 22),
                    onPressed: () {
                      context.push(OwnerRoutes.propertyNew);
                    },
                    tooltip: l10n.unitHubAddProperty,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search bar
              TextField(
                controller: _searchController,
                decoration:
                    InputDecorationHelper.buildDecoration(
                      labelText: l10n.unitHubSearch,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      context: context,
                    ).copyWith(
                      hintText: l10n.unitHubSearch,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: _searchController.clear,
                            )
                          : null,
                      isDense: true,
                    ),
              ),
            ],
          ),
        ),

        // Properties and Units list (hierarchical)
        Expanded(
          child: propertiesAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.unitHubLoadingError,
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            data: (properties) {
              if (properties.isEmpty) {
                return _buildEmptyPropertiesState(theme, isDark);
              }
              return _buildPropertiesWithUnits(
                theme,
                isDark,
                properties,
                onUnitSelected: onUnitSelected,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Empty state when no properties exist
  Widget _buildEmptyPropertiesState(ThemeData theme, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_business,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.unitHubNoProperties,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.unitHubNoPropertiesDesc,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: GradientTokens.brandPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.push(OwnerRoutes.propertyNew);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_business,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.unitHubCreateProperty,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Properties with their units - hierarchical view
  Widget _buildPropertiesWithUnits(
    ThemeData theme,
    bool isDark,
    List<PropertyModel> properties, {
    VoidCallback? onUnitSelected,
  }) {
    final unitsAsync = ref.watch(ownerUnitsProvider);

    return unitsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      error: (error, stack) {
        final l10n = AppLocalizations.of(context);
        return Center(child: Text(l10n.unitHubError(error.toString())));
      },
      data: (allUnits) {
        // Group units by property
        final unitsByProperty = <String, List<UnitModel>>{};
        for (final unit in allUnits) {
          unitsByProperty.putIfAbsent(unit.propertyId, () => []);
          unitsByProperty[unit.propertyId]!.add(unit);
        }

        // Filter properties by search query
        final filteredProperties = properties.where((property) {
          if (_searchQuery.isEmpty) return true;

          // Match property name
          if (property.name.toLowerCase().contains(_searchQuery)) return true;

          // Match any unit in this property
          final propertyUnits = unitsByProperty[property.id] ?? [];
          return propertyUnits.any(
            (unit) =>
                unit.name.toLowerCase().contains(_searchQuery) ||
                (unit.description?.toLowerCase().contains(_searchQuery) ??
                    false),
          );
        }).toList();

        if (filteredProperties.isEmpty) {
          final l10n = AppLocalizations.of(context);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.unitHubNoResults,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            80,
          ), // Increased bottom padding for last unit visibility
          itemCount: filteredProperties.length,
          itemBuilder: (context, index) {
            final property = filteredProperties[index];
            final propertyUnits = (unitsByProperty[property.id] ?? [])
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              ); // Ascending A-Z sort

            // Filter units by search
            final filteredUnits =
                (_searchQuery.isEmpty
                      ? propertyUnits
                      : propertyUnits
                            .where(
                              (unit) =>
                                  unit.name.toLowerCase().contains(
                                    _searchQuery,
                                  ) ||
                                  (unit.description?.toLowerCase().contains(
                                        _searchQuery,
                                      ) ??
                                      false),
                            )
                            .toList())
                  ..sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  ); // Ascending A-Z sort

            return _buildPropertySection(
              theme,
              isDark,
              property: property,
              units: filteredUnits,
              onUnitSelected: onUnitSelected,
            );
          },
        );
      },
    );
  }

  /// Property section with expandable units
  Widget _buildPropertySection(
    ThemeData theme,
    bool isDark, {
    required PropertyModel property,
    required List<UnitModel> units,
    VoidCallback? onUnitSelected,
  }) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.gradients.sectionBorder, width: 1.5),
        boxShadow: AppShadows.getElevation(2, isDark: isDark),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          iconColor: theme.colorScheme.primary,
          collapsedIconColor: theme.colorScheme.primary,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ), // Consistent sidebar padding
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.apartment,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            property.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            l10n.unitHubUnitsCount(units.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Horizontal row of action buttons (more compact)
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: () {
                    context.push(
                      OwnerRoutes.propertyEdit.replaceAll(':id', property.id),
                    );
                  },
                  tooltip: l10n.unitHubEditProperty,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: units.isEmpty
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                  ),
                  onPressed: () =>
                      _confirmDeleteProperty(context, property, units.length),
                  tooltip: units.isEmpty
                      ? l10n.unitHubDeleteProperty
                      : l10n.unitHubDeleteAllUnitsFirst,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  onPressed: () {
                    context.push(
                      '${OwnerRoutes.unitWizard}?propertyId=${property.id}',
                    );
                  },
                  tooltip: l10n.unitHubAddUnit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, size: 20),
            ],
          ),
          children: [
            if (units.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.unitHubNoUnitsInProperty,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: GradientTokens.brandPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              context.push(
                                '${OwnerRoutes.unitWizard}?propertyId=${property.id}',
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                l10n.unitHubAdd,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildReorderableUnitList(
                theme,
                isDark,
                units: units,
                property: property,
                onUnitSelected: onUnitSelected,
              ),
          ],
        ),
      ),
    );
  }

  /// Confirm and delete a property
  Future<void> _confirmDeleteProperty(
    BuildContext dialogContext,
    PropertyModel property,
    int unitCount,
  ) async {
    final theme = Theme.of(dialogContext);
    final l10n = AppLocalizations.of(dialogContext);

    // Check if property has units - cannot delete
    if (unitCount > 0) {
      if (!dialogContext.mounted) return;
      await showDialog<void>(
        context: dialogContext,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.unitHubCannotDelete),
          content: Text(l10n.unitHubCannotDeleteDesc(property.name, unitCount)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.unitHubUnderstand),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unitHubDeletePropertyTitle),
        content: Text(l10n.unitHubDeletePropertyConfirm(property.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await ref
            .read(ownerPropertiesRepositoryProvider)
            .deleteProperty(property.id);

        // Invalidate providers to refresh UI
        ref.invalidate(ownerPropertiesProvider);
        ref.invalidate(ownerUnitsProvider);

        // Reset selection if deleted property's unit was selected
        if (_selectedProperty?.id == property.id) {
          setState(() {
            _selectedUnit = null;
            _selectedProperty = null;
          });
        }

        if (mounted) {
          final l10nCtx = AppLocalizations.of(context);
          // ignore: use_build_context_synchronously - State.context is safe after mounted check
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10nCtx.unitHubPropertyDeleted(property.name),
          );
        }
      } catch (e) {
        if (mounted) {
          final l10nCtx = AppLocalizations.of(context);
          // ignore: use_build_context_synchronously - State.context is safe after mounted check
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            l10nCtx.unitHubDeleteError(e.toString()),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  /// Confirm and delete a unit
  Future<void> _confirmDeleteUnit(
    BuildContext dialogContext,
    UnitModel unit,
  ) async {
    final theme = Theme.of(dialogContext);
    final l10n = AppLocalizations.of(dialogContext);

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unitHubDeleteUnitTitle),
        content: Text(l10n.unitHubDeleteUnitConfirm(unit.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(ownerPropertiesRepositoryProvider)
            .deleteUnit(unit.propertyId, unit.id);

        // Invalidate providers to refresh UI
        ref.invalidate(ownerUnitsProvider);

        // Reset selection if deleted unit was selected
        if (_selectedUnit?.id == unit.id) {
          setState(() {
            _selectedUnit = null;
            _selectedProperty = null;
          });
        }

        if (mounted) {
          final l10nCtx = AppLocalizations.of(context);
          // ignore: use_build_context_synchronously - State.context is safe after mounted check
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10nCtx.unitHubUnitDeleted(unit.name),
          );
        }
      } catch (e) {
        if (mounted) {
          final l10nCtx = AppLocalizations.of(context);
          // ignore: use_build_context_synchronously - State.context is safe after mounted check
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            l10nCtx.unitHubDeleteError(e.toString()),
          );
        }
      }
    }
  }

  /// Unit list (simple, no drag and drop)
  Widget _buildReorderableUnitList(
    ThemeData theme,
    bool isDark, {
    required List<UnitModel> units,
    required PropertyModel property,
    VoidCallback? onUnitSelected,
  }) {
    // Sort units by sortOrder
    final sortedUnits = List<UnitModel>.from(units)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Column(
      children: sortedUnits.map((unit) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildUnitListTile(
            theme,
            isDark,
            unit: unit,
            property:
                property, // OPTIMIZED: Pass full property to avoid N+1 query
            isSelected: _selectedUnit?.id == unit.id,
            onUnitSelected: onUnitSelected,
          ),
        );
      }).toList(),
    );
  }

  /// Unit list tile (simple, no drag handle)
  Widget _buildUnitListTile(
    ThemeData theme,
    bool isDark, {
    required UnitModel unit,
    required PropertyModel
    property, // OPTIMIZED: Accept full property instead of just name
    required bool isSelected,
    VoidCallback? onUnitSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withAlpha((0.2 * 255).toInt())
            : context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : context.gradients.sectionBorder,
          width: isSelected ? 2 : 1.5,
        ),
        boxShadow: AppShadows.getElevation(1, isDark: isDark),
      ),
      child: InkWell(
        onTap: () {
          // OPTIMIZED: Use passed property directly - eliminates N+1 query pattern
          setState(() {
            _selectedUnit = unit;
            _selectedProperty = property;
          });
          onUnitSelected?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Unit name + status + actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      unit.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: unit.isAvailable
                          ? _kAvailableColor.withAlpha((0.2 * 255).toInt())
                          : _kUnavailableColor.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Text(
                          unit.isAvailable
                              ? l10n.unitHubAvailable
                              : l10n.unitHubUnavailable,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: unit.isAvailable
                                ? _kAvailableColor
                                : _kUnavailableColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Duplicate button
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return IconButton(
                          onPressed: () {
                            context.push(
                              '${OwnerRoutes.unitWizard}?propertyId=${unit.propertyId}&duplicateFromId=${unit.id}',
                            );
                          },
                          icon: Icon(
                            Icons.copy_outlined,
                            size: 15,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withAlpha(
                                    (0.7 * 255).toInt(),
                                  ),
                          ),
                          tooltip: l10n.unitHubEditUnit,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Delete button
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return IconButton(
                          onPressed: () => _confirmDeleteUnit(context, unit),
                          icon: Icon(
                            Icons.delete_outline,
                            size: 15,
                            color: theme.colorScheme.error.withAlpha(
                              (0.8 * 255).toInt(),
                            ),
                          ),
                          tooltip: l10n.unitHubDeleteUnit,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // Property name
              Text(
                property.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onSurface.withAlpha(
                          (0.7 * 255).toInt(),
                        )
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              // Max guests + price
              Row(
                children: [
                  Icon(
                    Icons.people_rounded,
                    size: 18,
                    color: isSelected
                        ? theme.colorScheme.primary.withAlpha(
                            (0.8 * 255).toInt(),
                          )
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${unit.maxGuests}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.euro_rounded,
                    size: 18,
                    color: isSelected
                        ? theme.colorScheme.primary.withAlpha(
                            (0.8 * 255).toInt(),
                          )
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        '${unit.pricePerNight.toStringAsFixed(0)}${l10n.unitHubPerNight}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Detail panel - Tab navigation + content
  Widget _buildDetailPanel(ThemeData theme, bool isDark, double screenWidth) {
    if (_selectedUnit == null) {
      return _buildEmptyState(theme, isDark);
    }

    return Column(
      children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: context.borderColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return TabBar(
                controller: _tabController,
                tabs: _buildTabs(l10n),
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                // Responsive padding: smaller for mobile, larger for desktop
                labelPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth < _kMobileBreakpoint ? 8 : 20,
                ),
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
                // Theme-aware divider color (lighter for light theme, darker for dark theme)
                dividerColor: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.1),
                indicator: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBasicInfoTab(theme, isDark),
              _buildPricingTab(theme, isDark),
              _buildWidgetTab(theme, isDark),
              _buildAdvancedTab(theme, isDark),
            ],
          ),
        ),
      ],
    );
  }

  /// Empty state - no unit selected
  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedEmptyState(
            icon: Icons.home_work_outlined,
            title: l10n.unitHubSelectUnit,
            subtitle: l10n.unitHubSelectUnitDesc,
            iconSize: 80,
            iconColor: theme.colorScheme.onSurfaceVariant.withValues(
              alpha: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // Tab content builders
  Widget _buildBasicInfoTab(ThemeData theme, bool isDark) {
    if (_selectedUnit == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _kDesktopBreakpoint;
    final isTablet =
        screenWidth >= _kTabletBreakpoint && screenWidth < _kDesktopBreakpoint;
    final isMobile = screenWidth < _kMobileBreakpoint;

    // Build individual cards as widgets for flex layout
    final l10n = AppLocalizations.of(context);

    // Check if unit has photos
    final hasPhotos = _selectedUnit!.images.isNotEmpty;

    // Capacity section - compact, fixed height
    final kapacitetCard = _buildInfoCard(
      theme,
      title: l10n.unitHubCapacitySection,
      icon: Icons.people_outline,
      isMobile: isMobile,
      children: [
        _buildDetailRow(
          theme,
          l10n.unitHubBedrooms,
          '${_selectedUnit!.bedrooms}',
        ),
        _buildDetailRow(
          theme,
          l10n.unitHubBathrooms,
          '${_selectedUnit!.bathrooms}',
        ),
        _buildDetailRow(
          theme,
          l10n.unitHubMaxGuests,
          '${_selectedUnit!.maxGuests}',
        ),
        if (_selectedUnit!.areaSqm != null)
          _buildDetailRow(
            theme,
            l10n.unitHubArea,
            '${_selectedUnit!.areaSqm!.toStringAsFixed(0)} m²',
          ),
      ],
    );

    // Price section - compact, fixed height
    final cijenaCard = _buildInfoCard(
      theme,
      title: l10n.unitHubPriceSection,
      icon: Icons.euro_outlined,
      isMobile: isMobile,
      children: [
        _buildDetailRow(
          theme,
          l10n.unitHubPricePerNight,
          '€${_selectedUnit!.pricePerNight.toStringAsFixed(0)}',
          valueColor: theme.colorScheme.primary,
        ),
        _buildDetailRow(
          theme,
          l10n.unitHubMinNights,
          '${_selectedUnit!.minStayNights}',
        ),
      ],
    );

    // Information section - can have long description
    final informacijeCard = _buildInfoCard(
      theme,
      title: l10n.unitHubInfoSection,
      icon: Icons.info_outline,
      isMobile: isMobile,
      children: [
        _buildDetailRow(theme, l10n.unitHubName, _selectedUnit!.name),
        _buildDetailRow(theme, l10n.unitHubSlug, _selectedUnit!.slug ?? 'N/A'),
        if (_selectedUnit!.description != null)
          _buildDetailRow(
            theme,
            l10n.unitHubDescription,
            _selectedUnit!.description!,
          ),
        _buildDetailRow(
          theme,
          l10n.unitHubStatus,
          _selectedUnit!.isAvailable
              ? l10n.unitHubStatusAvailable
              : l10n.unitHubStatusUnavailable,
          valueColor: _selectedUnit!.isAvailable
              ? _kAvailableColor
              : _kUnavailableColor,
        ),
      ],
    );

    // Photos section - only build if photos exist
    Widget? photosCard;
    if (hasPhotos) {
      photosCard = _buildInfoCard(
        theme,
        title: l10n.unitHubPhotosSection,
        icon: Icons.photo_library_outlined,
        isMobile: isMobile,
        children: _buildImageGridContent(
          theme,
          imageSize: isDesktop ? 80 : 100,
          l10n: l10n,
        ),
      );
    }

    return ListView(
      // Web performance: Use ClampingScrollPhysics to prevent elastic overscroll jank
      physics: PlatformScrollPhysics.adaptive,
      padding: EdgeInsets.all(context.horizontalPadding),
      children: [
        // Header with Edit Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.unitHubBasicData,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            // Gradient button using brand gradient
            Container(
              decoration: BoxDecoration(
                gradient: GradientTokens.brandPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.push(
                      OwnerRoutes.unitWizardEdit.replaceAll(
                        ':id',
                        _selectedUnit!.id,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          l10n.unitHubEdit,
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
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Unit Details Cards - Layout based on screen size
        // Order: Information → Capacity → Pricing → Photos (matches Unit Wizard flow)
        if (isDesktop) ...[
          // Desktop: Row 1: Information (Basic Info) + Capacity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: informacijeCard),
              const SizedBox(width: 14),
              Expanded(child: kapacitetCard),
            ],
          ),
          const SizedBox(height: 14),
          // Desktop: Row 2: Pricing + Photos (or full-width if no photos)
          if (hasPhotos)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cijenaCard),
                const SizedBox(width: 14),
                Expanded(child: photosCard!),
              ],
            )
          else
            cijenaCard,
        ] else if (isTablet) ...[
          // Tablet (800-900px): Information + Capacity side by side, then stacked
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: informacijeCard),
              const SizedBox(width: 14),
              Expanded(child: kapacitetCard),
            ],
          ),
          const SizedBox(height: 14),
          cijenaCard,
          if (hasPhotos) ...[const SizedBox(height: 14), photosCard!],
        ] else ...[
          // Mobile (<800px): All stacked in wizard order
          informacijeCard,
          const SizedBox(height: 14),
          kapacitetCard,
          const SizedBox(height: 14),
          cijenaCard,
          if (hasPhotos) ...[const SizedBox(height: 14), photosCard!],
        ],
      ],
    );
  }

  Widget _buildPricingTab(ThemeData theme, bool isDark) {
    if (_selectedUnit == null) return const SizedBox.shrink();

    // Embed UnitPricingScreen content WITHOUT app bar
    // Key forces widget recreation when unit changes
    return UnitPricingScreen(
      key: ValueKey('pricing_${_selectedUnit!.id}'),
      unit: _selectedUnit,
      showAppBar: false, // Hide app bar when embedded in tabs
    );
  }

  Widget _buildWidgetTab(ThemeData theme, bool isDark) {
    if (_selectedUnit == null || _selectedProperty == null) {
      return const SizedBox.shrink();
    }

    // Embed WidgetSettingsScreen content WITHOUT app bar
    // Key forces widget recreation when unit changes
    return WidgetSettingsScreen(
      key: ValueKey('widget_${_selectedUnit!.id}'),
      propertyId: _selectedProperty!.id,
      unitId: _selectedUnit!.id,
      showAppBar: false, // Hide app bar when embedded in tabs
    );
  }

  Widget _buildAdvancedTab(ThemeData theme, bool isDark) {
    if (_selectedUnit == null || _selectedProperty == null) {
      return const SizedBox.shrink();
    }

    // Embed WidgetAdvancedSettingsScreen content WITHOUT app bar
    // Key forces widget recreation when unit changes
    return WidgetAdvancedSettingsScreen(
      key: ValueKey('advanced_${_selectedUnit!.id}'),
      propertyId: _selectedProperty!.id,
      unitId: _selectedUnit!.id,
      showAppBar: false, // Hide app bar when embedded in tabs
    );
  }

  // Helper methods for Tab 1
  Widget _buildInfoCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isMobile,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.getElevation(1, isDark: isDark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: context.gradients.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.gradients.sectionBorder,
                width: 1.5,
              ),
            ),
            padding: EdgeInsets.all(isMobile ? 14.0 : 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with accent border
                Row(
                  children: [
                    // Larger, more prominent icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(
                          (0.15 * 255).toInt(),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title with accent border
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
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
                const SizedBox(height: 18),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: valueColor ?? theme.colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the image grid for unit photos
  /// [imageSize] - Size of each image thumbnail (desktop: 80, mobile: 100)
  List<Widget> _buildImageGridContent(
    ThemeData theme, {
    required double imageSize,
    required AppLocalizations l10n,
  }) {
    if (_selectedUnit == null) return [];

    final images = _selectedUnit!.images;
    if (images.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 32,
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(
                    (0.4 * 255).toInt(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.unitHubNoPhotos,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(
                      (0.6 * 255).toInt(),
                    ),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: images.take(6).map((imageUrl) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: imageSize,
                  height: imageSize,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
      if (images.length > 6)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            l10n.unitHubMorePhotos(images.length - 6),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
    ];
  }
}
