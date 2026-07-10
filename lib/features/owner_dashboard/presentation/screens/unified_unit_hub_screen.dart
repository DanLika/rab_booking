import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../core/utils/platform_scroll_physics.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/additional_service_model.dart';
import '../../../../shared/repositories/firebase/firebase_additional_services_repository.dart';
import '../providers/owner_properties_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../../shared/widgets/animations/animated_empty_state.dart';
import '../../../../shared/widgets/smart_tooltip.dart';
import 'unit_pricing_screen.dart';
import 'widget_settings_screen.dart';
import 'widget_advanced_settings_screen.dart';
import '../widgets/units/unit_hub_empty_state.dart';
import '../widgets/units/units_premium_header.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

/// Master panel width for desktop sidebar + mobile/tablet endDrawer
const double _kMasterPanelWidth = 280.0;

// Master-panel fidelity consts (handoff units.jsx PropertyTree / UnitTreeItem).
const double _kMasterBadgeSize = 32.0; // header apartment tint badge
const double _kMasterBadgeRadius = 10.0;
const double _kMasterRowRadius = 12.0; // --bb-radius-sm
const double _kMasterSelectedBar = 3.0; // selected unit left accent

/// Breakpoint for desktop layout (CLAUDE.md: Desktop ≥1200px). At/above this
/// the master panel is a persistent sidebar; below it lives in the endDrawer.
const double _kDesktopBreakpoint = 1200.0;

/// Breakpoint for tablet layout (between mobile and desktop)
const double _kTabletBreakpoint = 800.0;

/// Breakpoint for mobile layout
const double _kMobileBreakpoint = 600.0;

/// Available status color (handoff `--bb-success`, dark lift in dark mode)
Color _availableColor(ThemeData theme) => theme.brightness == Brightness.dark
    ? BBColor.successDarkMode
    : BBColor.success;

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
    // BUG FIX: Guard against empty properties list (race condition)
    // If properties haven't loaded yet, skip auto-selection - will be triggered
    // again when properties load via the properties listener
    if (properties.isEmpty) return;

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

    // Watch both providers to trigger rebuilds when data arrives
    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final properties = propertiesAsync.valueOrNull ?? [];
    final unitsAsync = ref.watch(ownerUnitsProvider);

    // Listen for units changes and handle side effects (auto-selection, sync)
    ref.listen<AsyncValue<List<UnitModel>>>(ownerUnitsProvider, (
      previous,
      next,
    ) {
      next.whenData((units) => _handleUnitsChanged(units, properties));
    });

    // Also listen for properties changes to handle race condition
    // If properties load AFTER units, we need to trigger auto-selection
    ref.listen<AsyncValue<List<PropertyModel>>>(ownerPropertiesProvider, (
      previous,
      next,
    ) {
      final units = ref.read(ownerUnitsProvider).valueOrNull ?? [];
      next.whenData((props) => _handleUnitsChanged(units, props));
    });

    // BUG FIX: Fallback auto-selection when providers already have data.
    // ref.listen only fires on VALUE CHANGES after registration. If both
    // providers already have cached data (not disposed between navigations),
    // listeners never fire and _selectedUnit stays null.
    if (_selectedUnit == null) {
      final units = unitsAsync.valueOrNull ?? [];
      if (units.isNotEmpty && properties.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedUnit == null) {
            _handleUnitsChanged(units, properties);
          }
        });
      }
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      // Single premium app bar across breakpoints. Previously mobile rendered
      // a brand-purple `AppBar` with white text + a tinted "list" action
      // button — that hero bar did not exist in the handoff (`screens/06-owner.png`
      // has a clean panel header). Switching to `CommonAppBar` matches Pregled
      // / Rezervacije / Profil chrome and theme-adapts in dark mode.
      appBar: CommonAppBar(
        title: isDesktop
            ? l10n.unitHubTitle
            : (_selectedUnit?.name ?? l10n.unitHubTitle),
        leadingIcon: Icons.menu,
        onLeadingIconTap: (_) => _scaffoldKey.currentState?.openDrawer(),
        actions: isDesktop
            ? null
            : <Widget>[
                SmartTooltip(
                  message: l10n.unitHubShowAllUnits,
                  child: IconButton(
                    icon: const Icon(Icons.list),
                    tooltip: l10n.unitHubShowAllUnits,
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                ),
              ],
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
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: Column(
          children: [
            UnitsPremiumHeader(title: l10n.unitHubTitle),
            Expanded(
              child: isDesktop
                  ? _buildDesktopLayout(theme, isDark, screenWidth)
                  : _buildMobileLayout(theme, isDark),
            ),
          ],
        ),
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
    final bb = BBColor.of(context);
    final propertyCount = propertiesAsync.asData?.value.length ?? 0;
    final unitCount = ref.watch(ownerUnitsProvider).asData?.value.length ?? 0;

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
                  // Handoff: 32px primary-tint badge around apartment icon.
                  Container(
                    width: _kMasterBadgeSize,
                    height: _kMasterBadgeSize,
                    decoration: BoxDecoration(
                      color: bb.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(_kMasterBadgeRadius),
                    ),
                    child: Icon(Icons.apartment, color: bb.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.unitHubPropertiesAndUnits,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l10n.unitHubPropertiesUnitsSubtitle(
                            propertyCount,
                            unitCount,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: bb.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
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
                  theme.colorScheme.primary,
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
                    const SizedBox(height: 8),
                    Text(
                      'Molimo osvježite aplikaciju ili pokušajte ponovno.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.invalidate(ownerPropertiesProvider);
                        ref.invalidate(ownerUnitsProvider);
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l10n.tryAgain),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
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
    return const UnitHubEmptyState();
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
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      ),
      error: (error, stack) {
        final l10n = AppLocalizations.of(context);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.unitHubError(error.toString()),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(ownerUnitsProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.tryAgain),
                ),
              ],
            ),
          ),
        );
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
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                vertical: 32.0,
                horizontal: 24.0,
              ),
              child: AnimatedEmptyState(
                icon: Icons.search_off,
                title: l10n.unitHubNoResults,
                iconColor: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
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

  /// Property section with expandable units.
  ///
  /// Handoff units.jsx `PropertyTree`: the property header is a FLAT toggle row
  /// (`[chevron][domain icon][name (flex:1)][count][actions]`), NOT an
  /// `ExpansionTile`. The old ExpansionTile packed the name into a fixed `title`
  /// slot competing with a `trailing` 3-icon action cluster, so a long name had
  /// no room and wrapped (band-aided with ellipsis in iter 6/#850). Restructured
  /// to a real `Row` where the name gets true `Expanded` priority and the action
  /// cluster is fixed-width trailing — the name shrinks/ellipsizes cleanly, no
  /// vertical wrap at any width. Expand/collapse, actions, and selection wiring
  /// are unchanged.
  Widget _buildPropertySection(
    ThemeData theme,
    bool isDark, {
    required PropertyModel property,
    required List<UnitModel> units,
    VoidCallback? onUnitSelected,
  }) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        // Handoff PropertyTree: property groups are flat rows inside the panel
        // card, not individually-elevated cards. Keep a hairline border for
        // grouping without the heavy shadow.
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(_kMasterRowRadius),
        border: Border.all(color: context.gradients.sectionBorder),
      ),
      child: _PropertyTreeSection(
        header: (expanded, onToggle) => PropertyTreeHeader(
          theme: theme,
          propertyName: property.name,
          canDelete: units.isEmpty,
          expanded: expanded,
          onToggle: onToggle,
          editTooltip: l10n.unitHubEditProperty,
          addTooltip: l10n.unitHubAddUnit,
          deleteTooltip: units.isEmpty
              ? l10n.unitHubDeleteProperty
              : l10n.unitHubDeleteAllUnitsFirst,
          // Handoff PropertyTree count = bare tnum number (not "N jedinica"): the
          // verbose label crushed the Expanded name to ~22px on the narrow mobile
          // panel (edit/delete/add cluster already claims 84px). Total is in the
          // panel subtitle; units are listed directly below.
          unitsCountLabel: '${units.length}',
          onEdit: () => context.push(
            OwnerRoutes.propertyEdit.replaceAll(':id', property.id),
          ),
          onDelete: () =>
              _confirmDeleteProperty(context, property, units.length),
          onAdd: () => context.push(
            '${OwnerRoutes.unitWizard}?propertyId=${property.id}',
          ),
        ),
        children: [
          if (units.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    BbButton(
                      label: l10n.unitHubAdd,
                      size: BbButtonSize.sm,
                      onPressed: () {
                        context.push(
                          '${OwnerRoutes.unitWizard}?propertyId=${property.id}',
                        );
                      },
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
    );
  }

  /// Confirm and delete a property
  Future<void> _confirmDeleteProperty(
    BuildContext dialogContext,
    PropertyModel property,
    int unitCount,
  ) async {
    final l10n = AppLocalizations.of(dialogContext);

    // Check if property has units - cannot delete
    if (unitCount > 0) {
      if (!dialogContext.mounted) return;
      await showDialog<void>(
        context: dialogContext,
        builder: (ctx) => BbDialog(
          title: l10n.unitHubCannotDelete,
          body: l10n.unitHubCannotDeleteDesc(property.name, unitCount),
          primary: BbDialogAction(
            label: l10n.unitHubUnderstand,
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => BbDialog(
        title: l10n.unitHubDeletePropertyTitle,
        body: l10n.unitHubDeletePropertyConfirm(property.name),
        destructive: true,
        secondary: BbDialogAction(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        primary: BbDialogAction(
          label: l10n.delete,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ),
    );

    if (confirmed == true && mounted) {
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
      }
    }
  }

  /// Confirm and delete a unit
  Future<void> _confirmDeleteUnit(
    BuildContext dialogContext,
    UnitModel unit,
  ) async {
    final l10n = AppLocalizations.of(dialogContext);

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => BbDialog(
        title: l10n.unitHubDeleteUnitTitle,
        body: l10n.unitHubDeleteUnitConfirm(unit.name),
        destructive: true,
        secondary: BbDialogAction(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        primary: BbDialogAction(
          label: l10n.delete,
          onPressed: () => Navigator.pop(ctx, true),
        ),
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
    final bb = BBColor.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        // Handoff UnitTreeItem: selected = primary-tint bg + 3px left accent;
        // unselected = flat/transparent (no card border/shadow).
        color: isSelected
            ? bb.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(_kMasterRowRadius),
        border: Border(
          left: BorderSide(
            color: isSelected ? bb.primary : Colors.transparent,
            width: _kMasterSelectedBar,
          ),
        ),
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
        borderRadius: BorderRadius.circular(_kMasterRowRadius),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Unit name + status + actions
              Row(
                children: [
                  // Handoff: leading bed icon (primary when selected).
                  Icon(
                    Icons.bed_rounded,
                    size: 15,
                    color: isSelected ? bb.primary : bb.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      unit.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isSelected ? bb.primary : bb.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Handoff: status as uppercase micro-label (success / tertiary),
                  // no pill chrome.
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        (unit.isAvailable
                                ? l10n.unitHubAvailable
                                : l10n.unitHubUnavailable)
                            .toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: unit.isAvailable
                              ? _availableColor(theme)
                              : bb.textTertiary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.4,
                        ),
                      );
                    },
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
              // Handoff meta row indent aligns under the unit name (past the
              // 15px bed icon + 8px gap).
              Padding(
                padding: const EdgeInsets.only(left: 23),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Property name
                    Text(
                      property.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: bb.textTertiary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Max guests + price
                    Row(
                      children: [
                        Icon(
                          Icons.group_rounded,
                          size: 15,
                          color: bb.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${unit.maxGuests}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: bb.textTertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.euro_rounded,
                          size: 15,
                          color: bb.textTertiary,
                        ),
                        const SizedBox(width: 2),
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return Text(
                              '${unit.pricePerNight.toStringAsFixed(0)}${l10n.unitHubPerNight}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: bb.textTertiary,
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

    final l10n = AppLocalizations.of(context);
    final unit = _selectedUnit!;
    final BBColorSet c = BBColor.of(context);

    // Informacije card — handoff units.jsx: Naziv / URL slug / Opis / Status badge
    final informacijeCard = BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _osnovnoCardHeader(c, icon: 'info', title: l10n.unitHubInfoSection),
          _kvRow(c, l10n.unitHubName, value: unit.name),
          _kvRow(
            c,
            l10n.unitHubSlug,
            value: unit.slug,
            placeholder: l10n.notSet,
          ),
          if (unit.description != null && unit.description!.isNotEmpty)
            _kvRow(
              c,
              l10n.unitHubDescription,
              value: unit.description,
              stack: true,
            ),
          _kvRow(
            c,
            l10n.unitHubStatus,
            isLast: true,
            child: BbStatusBadge(
              status: unit.isAvailable
                  ? BbBookingStatus.confirmed
                  : BbBookingStatus.cancelled,
              label: unit.isAvailable
                  ? l10n.unitHubStatusAvailable
                  : l10n.unitHubStatusUnavailable,
              size: BbStatusBadgeSize.sm,
            ),
          ),
        ],
      ),
    );

    // Kapacitet card
    final kapacitetCard = BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _osnovnoCardHeader(
            c,
            icon: 'hotel',
            title: l10n.unitHubCapacitySection,
          ),
          _kvRow(c, l10n.unitHubBedrooms, value: '${unit.bedrooms}'),
          _kvRow(c, l10n.unitHubBathrooms, value: '${unit.bathrooms}'),
          _kvRow(
            c,
            l10n.unitHubMaxGuests,
            value: '${unit.maxGuests}',
            isLast: unit.areaSqm == null,
          ),
          if (unit.areaSqm != null)
            _kvRow(
              c,
              l10n.unitHubArea,
              value: '${unit.areaSqm!.toStringAsFixed(0)} m²',
              isLast: true,
            ),
        ],
      ),
    );

    return ListView(
      // Web performance: Use ClampingScrollPhysics to prevent elastic overscroll jank
      physics: PlatformScrollPhysics.adaptive,
      padding: EdgeInsets.all(context.horizontalPadding),
      children: [
        // Gallery (desktop only, when the unit carries photos) — handoff cover + 2×2
        if (isDesktop && unit.images.isNotEmpty) ...[
          _buildUnitGallery(c, unit.images),
          const SizedBox(height: 20),
        ],

        // Header: title + subtitle, Kopiraj (duplicate) + Uredi (edit)
        _buildOsnovnoHeader(theme, c, l10n, unit, isMobile),
        const SizedBox(height: 20),

        // 2-col cards: Informacije + Kapacitet (stack on mobile)
        if (isDesktop || isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: informacijeCard),
              const SizedBox(width: 16),
              Expanded(child: kapacitetCard),
            ],
          )
        else ...[
          informacijeCard,
          const SizedBox(height: 16),
          kapacitetCard,
        ],
        const SizedBox(height: 16),

        // Cijena card: PriceTile grid + extra fees + Cjenovnik cross-reference banner
        _buildCijenaCard(c, l10n, unit),
        const SizedBox(height: 16),

        // Additional services (loaded from Firestore)
        _buildServicesCard(),
      ],
    );
  }

  Widget _buildServicesCard() {
    if (_selectedProperty == null || _selectedUnit == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final BBColorSet c = BBColor.of(context);
    final repo = ref.read(additionalServicesRepositoryProvider);

    return FutureBuilder<List<AdditionalServiceModel>>(
      // Key ensures rebuild when unit changes
      key: ValueKey('services_${_selectedUnit!.id}'),
      future: repo.fetchByUnit(
        propertyId: _selectedProperty!.id,
        unitId: _selectedUnit!.id,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final services = snapshot.data!;
        return BbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _osnovnoCardHeader(
                c,
                icon: 'room_service',
                title: l10n.additionalServicesTitle,
              ),
              for (int i = 0; i < services.length; i++)
                _kvRow(
                  c,
                  services[i].name,
                  value: services[i].formattedPrice,
                  isLast: i == services.length - 1,
                ),
            ],
          ),
        );
      },
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

  // ── Osnovno-tab handoff primitives (units.jsx) ──────────────────────────
  // Header: unit name + subtitle, Kopiraj (duplicate) + Uredi (edit).
  Widget _buildOsnovnoHeader(
    ThemeData theme,
    BBColorSet c,
    AppLocalizations l10n,
    UnitModel unit,
    bool isMobile,
  ) {
    final BbButtonSize size = isMobile ? BbButtonSize.sm : BbButtonSize.md;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                unit.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                l10n.unitHubBasicDataSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: c.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        BbButton(
          label: l10n.unitHubCopy,
          iconLeft: 'content_copy',
          variant: BbButtonVariant.secondary,
          size: size,
          onPressed: () {
            context.push(
              '${OwnerRoutes.unitWizard}?propertyId=${unit.propertyId}&duplicateFromId=${unit.id}',
            );
          },
        ),
        const SizedBox(width: 8),
        BbButton(
          label: l10n.unitHubEdit,
          iconLeft: 'edit',
          size: size,
          onPressed: () {
            context.push(OwnerRoutes.unitWizardEdit.replaceAll(':id', unit.id));
          },
        ),
      ],
    );
  }

  // Gallery (desktop): cover (2fr) + 2×2 tile grid (1fr). Read-only display of
  // unit.images; empty slots render a neutral placeholder.
  Widget _buildUnitGallery(BBColorSet c, List<String> images) {
    String? at(int i) => i < images.length ? images[i] : null;
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: _galleryTile(c, at(0), 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _galleryTile(c, at(1), 14)),
                      const SizedBox(width: 8),
                      Expanded(child: _galleryTile(c, at(2), 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _galleryTile(c, at(3), 14)),
                      const SizedBox(width: 8),
                      Expanded(child: _galleryTile(c, at(4), 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _galleryTile(BBColorSet c, String? url, double radius) {
    final Widget placeholder = DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: BbIcon(name: 'image', size: 22, color: c.textTertiary),
      ),
    );
    if (url == null || url.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (ctx, child, progress) =>
            progress == null ? child : placeholder,
      ),
    );
  }

  // Card header: 32px primary-tint icon badge + title (handoff CardHeader).
  Widget _osnovnoCardHeader(
    BBColorSet c, {
    required String icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: BbIcon(name: icon, size: 18, color: c.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Key/value row (handoff KeyValueRow). `stack` = full-width label-over-value
  // (used for prose like the description); otherwise label left / value right.
  Widget _kvRow(
    BBColorSet c,
    String label, {
    String? value,
    String? placeholder,
    Widget? child,
    bool isLast = false,
    bool stack = false,
  }) {
    final Widget labelWidget = Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: c.textTertiary,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );

    final Widget valueWidget =
        child ??
        ((value != null && value.isNotEmpty)
            ? Text(
                value,
                textAlign: stack ? TextAlign.start : TextAlign.end,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: c.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: stack ? 6 : 3,
              )
            : Text(
                placeholder ?? '',
                textAlign: stack ? TextAlign.start : TextAlign.end,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: c.textTertiary,
                ),
              ));

    final Widget content = stack
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              labelWidget,
              const SizedBox(height: 4),
              SizedBox(width: double.infinity, child: valueWidget),
            ],
          )
        : Row(
            children: [
              Expanded(flex: 4, child: labelWidget),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: valueWidget,
                ),
              ),
            ],
          );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
      child: content,
    );
  }

  // Cijena card: emphasized PriceTile grid + extra-fee rows + Cjenovnik banner.
  Widget _buildCijenaCard(BBColorSet c, AppLocalizations l10n, UnitModel unit) {
    final List<Widget> tiles = <Widget>[
      _priceTile(
        c,
        l10n.unitHubPricePerNight,
        '€${unit.pricePerNight.toStringAsFixed(0)}',
        emphasis: true,
      ),
      if (unit.weekendBasePrice != null)
        _priceTile(
          c,
          l10n.unitWizardStep3WeekendPrice,
          '€${unit.weekendBasePrice!.toStringAsFixed(0)}',
        ),
      _priceTile(c, l10n.unitHubMinNights, '${unit.minStayNights}'),
      if (unit.maxStayNights != null)
        _priceTile(c, l10n.unitWizardStep3MaxStay, '${unit.maxStayNights}'),
    ];

    // Extra fees the model carries but the handoff tiles omit — kept as rows.
    final List<(String, String)> extras = <(String, String)>[
      if (unit.maxTotalCapacity != null &&
          unit.maxTotalCapacity! > unit.maxGuests)
        (
          l10n.unitWizardStep5ExtraBeds,
          '${unit.maxTotalCapacity! - unit.maxGuests}',
        ),
      if (unit.extraBedFee != null)
        (
          l10n.unitWizardStep5ExtraBedFee,
          '€${unit.extraBedFee!.toStringAsFixed(0)}',
        ),
      if (unit.petFee != null)
        (l10n.unitWizardStep5PetFee, '€${unit.petFee!.toStringAsFixed(0)}'),
    ];

    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _osnovnoCardHeader(c, icon: 'euro', title: l10n.unitHubPriceSection),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (ctx, cons) {
              final double w = cons.maxWidth;
              final int cols = w >= 520 ? 4 : (w >= 340 ? 3 : 2);
              final int useCols = tiles.length < cols ? tiles.length : cols;
              const double gap = 12;
              final double tileW = (w - (useCols - 1) * gap) / useCols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: tiles
                    .map((t) => SizedBox(width: tileW, child: t))
                    .toList(),
              );
            },
          ),
          if (extras.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (int i = 0; i < extras.length; i++)
              _kvRow(
                c,
                extras[i].$1,
                value: extras[i].$2,
                isLast: i == extras.length - 1,
              ),
          ],
          const SizedBox(height: 14),
          _buildCjenovnikHint(c, l10n),
        ],
      ),
    );
  }

  Widget _priceTile(
    BBColorSet c,
    String label,
    String value, {
    bool emphasis = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: emphasis ? c.primary.withValues(alpha: 0.10) : c.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: emphasis
            ? Border.all(color: c.primary.withValues(alpha: 0.25))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: c.textTertiary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: emphasis ? c.primary : c.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  // Cross-reference banner — tappable, jumps to the Cjenovnik tab (index 1).
  // Local tab switch only; never reads/writes the FROZEN Cjenovnik content.
  Widget _buildCjenovnikHint(BBColorSet c, AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _tabController.animateTo(1),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              BbIcon(name: 'info', size: 16, color: c.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.unitHubAdvancedPricingHint,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: c.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BbIcon(name: 'chevron_right', size: 18, color: c.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PROPERTY TREE (handoff units.jsx PropertyTree flat-row layout)
// ============================================================================

/// Collapsible property group. Owns expand/collapse state (default expanded,
/// matching the old `ExpansionTile(initiallyExpanded: true)`) and renders the
/// flat [PropertyTreeHeader] toggle row above its animated children.
class _PropertyTreeSection extends StatefulWidget {
  const _PropertyTreeSection({required this.header, required this.children});

  /// Builds the header given the current expanded state + a toggle callback.
  final Widget Function(bool expanded, VoidCallback onToggle) header;
  final List<Widget> children;

  @override
  State<_PropertyTreeSection> createState() => _PropertyTreeSectionState();
}

class _PropertyTreeSectionState extends State<_PropertyTreeSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.header(_expanded, () => setState(() => _expanded = !_expanded)),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          firstCurve: Curves.easeInOut,
          secondCurve: Curves.easeInOut,
          sizeCurve: Curves.easeInOut,
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.children,
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Flat property-header row per handoff units.jsx `PropertyTree`.
///
/// `[chevron][domain icon][name (Expanded)][count][edit][delete][add]`. The
/// name gets true `Expanded` priority so it shrinks/ellipsizes cleanly instead
/// of wrapping vertically under the fixed-width trailing action cluster — this
/// is the structural fix for the wrap bug band-aided with ellipsis in
/// iter 6/#850. Tapping anywhere on the name/chevron region toggles expand.
@visibleForTesting
class PropertyTreeHeader extends StatelessWidget {
  const PropertyTreeHeader({
    super.key,
    required this.theme,
    required this.propertyName,
    required this.canDelete,
    required this.expanded,
    required this.onToggle,
    required this.editTooltip,
    required this.deleteTooltip,
    required this.addTooltip,
    required this.unitsCountLabel,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final ThemeData theme;
  final String propertyName;
  final bool canDelete;
  final bool expanded;
  final VoidCallback onToggle;
  final String editTooltip;
  final String deleteTooltip;
  final String addTooltip;
  final String unitsCountLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Row(
      children: [
        // Toggle region: chevron + domain icon + name. Expanded so the name
        // owns all slack width and never competes with the action cluster.
        Expanded(
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(_kMasterRowRadius),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: expanded ? 0 : -0.25,
                    child: Icon(
                      Icons.expand_more,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.domain, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      propertyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Handoff count badge (bb-tnum). Fixed intrinsic width.
                  Text(
                    unitsCountLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Fixed-width action cluster — never steals width from the name.
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: onEdit,
                  tooltip: editTooltip,
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
                    color: canDelete
                        ? cs.error
                        : cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  onPressed: onDelete,
                  tooltip: deleteTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  onPressed: onAdd,
                  tooltip: addTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
