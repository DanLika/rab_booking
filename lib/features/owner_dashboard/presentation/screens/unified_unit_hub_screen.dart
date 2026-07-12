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

part 'unified_unit_hub_master_panel.dart';
part 'unified_unit_hub_osnovno.dart';

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

/// Osnovno-tab vertical rhythm between major cards (gallery / header /
/// info+capacity / price / services). Minimalist: uniform generous
/// breathing room on the 8px scale (was a 20/16 mix).
const double _kOsnovnoSectionGap = BBSpace.md; // 24

/// 12px gap (off the 8px scale, but the deliberate handoff value between the
/// price grid and its extras/hint rows). Named local const because BBSpace.xs2
/// is deprecated-on-use.
const double _kPriceExtrasGap = 12;

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

/// Shared mutable state for `_UnifiedUnitHubScreenState` and its concern
/// mixins (`_MasterPanelMixin`, `_OsnovnoTabMixin`). Split into `part`
/// files on 2026-07-11 — every method moved VERBATIM; runtime class
/// unchanged. FROZEN pricing-tab embed stays in the core file.
abstract class _UnifiedUnitHubScreenStateBase
    extends ConsumerState<UnifiedUnitHubScreen>
    with SingleTickerProviderStateMixin {
  UnitModel? _selectedUnit;
  PropertyModel? _selectedProperty;
  late TabController _tabController;

  // GlobalKey for Scaffold to avoid context issues
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
}

class _UnifiedUnitHubScreenState extends _UnifiedUnitHubScreenStateBase
    with _MasterPanelMixin, _OsnovnoTabMixin {
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
}
