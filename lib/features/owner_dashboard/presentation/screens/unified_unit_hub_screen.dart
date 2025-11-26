import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/models/property_model.dart';
import '../providers/owner_properties_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import 'unit_pricing_screen.dart';
import 'widget_settings_screen.dart';
import 'widget_advanced_settings_screen.dart';

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
  List<Widget> _buildTabs() {
    return [
      _buildTab(Icons.description_outlined, 'Osnovni Podaci'),
      _buildTab(Icons.payments_outlined, 'Cjenovnik'),
      _buildTab(Icons.code, 'Widget'),
      _buildTab(Icons.tune, 'Napredne Postavke'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    // Auto-select first unit when units are loaded
    final unitsAsync = ref.watch(ownerUnitsProvider);
    unitsAsync.whenData((units) {
      if (units.isNotEmpty && _selectedUnit == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted && _selectedUnit == null) {
            final firstUnit = units.first;
            final property = await ref.read(
              propertyByIdProvider(firstUnit.propertyId).future,
            );
            if (mounted) {
              setState(() {
                _selectedUnit = firstUnit;
                _selectedProperty = property;
              });
            }
          }
        });
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      appBar: isDesktop
          ? CommonAppBar(
              title: 'Smještajne Jedinice',
              leadingIcon: Icons.menu,
              onLeadingIconTap: (_) => _scaffoldKey.currentState?.openDrawer(),
            )
          : AppBar(
              title: Text(
                _selectedUnit?.name ?? 'Smještajne Jedinice',
                style: const TextStyle(color: Colors.white),
              ),
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.list, color: Colors.white),
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  tooltip: 'Prikaži sve jedinice',
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
              width: 320,
              child: Container(
                decoration: BoxDecoration(
                  gradient: context.gradients.sectionBackground,
                ),
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
                  ),
                ),
              ),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: context.gradients.pageBackground,
        ),
        child: isDesktop
            ? _buildDesktopLayout(theme, isDark, screenWidth)
            : _buildMobileLayout(theme, isDark),
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
          width: 320,
          decoration: BoxDecoration(
            gradient: context.gradients.sectionBackground,
            border: Border(
              left: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
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
  }) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
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
                      'Objekti i Jedinice',
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
                    tooltip: 'Dodaj novi objekt',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pretraži...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: _searchController.clear,
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                      'Greška pri učitavanju',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_business,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nemate objekata',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kreirajte prvi objekt da biste mogli dodavati smještajne jedinice',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_business, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Kreiraj Objekt',
                          style: TextStyle(
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
      error: (error, stack) => Center(
        child: Text('Greška: $error'),
      ),
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
          return propertyUnits.any((unit) =>
              unit.name.toLowerCase().contains(_searchQuery) ||
              (unit.description?.toLowerCase().contains(_searchQuery) ?? false));
        }).toList();

        if (filteredProperties.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nema rezultata',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16), // Consistent sidebar padding
          itemCount: filteredProperties.length,
          itemBuilder: (context, index) {
            final property = filteredProperties[index];
            final propertyUnits = unitsByProperty[property.id] ?? [];

            // Filter units by search
            final filteredUnits = _searchQuery.isEmpty
                ? propertyUnits
                : propertyUnits.where((unit) =>
                    unit.name.toLowerCase().contains(_searchQuery) ||
                    (unit.description?.toLowerCase().contains(_searchQuery) ?? false)).toList();

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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.gradients.sectionBorder,
          width: 1.5,
        ),
        boxShadow: AppShadows.getElevation(1, isDark: isDark),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Consistent sidebar padding
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
            '${units.length} ${units.length == 1 ? 'jedinica' : 'jedinica'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add unit to this property
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () {
                  // TODO: Pass propertyId to wizard when supported
                  context.push(OwnerRoutes.unitWizard);
                },
                tooltip: 'Dodaj jedinicu',
                visualDensity: VisualDensity.compact,
              ),
              const Icon(Icons.expand_more),
            ],
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
                          'Nema jedinica u ovom objektu',
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
                              context.push(OwnerRoutes.unitWizard);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                'Dodaj',
                                style: TextStyle(
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
              ...units.map((unit) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildUnitListTile(
                  theme,
                  isDark,
                  unit: unit,
                  propertyName: property.name,
                  isSelected: _selectedUnit?.id == unit.id,
                  onUnitSelected: onUnitSelected,
                ),
              )),
          ],
        ),
      ),
    );
  }

  /// Confirm and delete a unit
  Future<void> _confirmDeleteUnit(BuildContext context, UnitModel unit) async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši jedinicu'),
        content: Text(
          'Jeste li sigurni da želite obrisati "${unit.name}"?\n\n'
          'Ova akcija se ne može poništiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši'),
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
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            'Jedinica "${unit.name}" je uspješno obrisana',
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            'Greška pri brisanju: $e',
          );
        }
      }
    }
  }

  /// Unit list tile - single unit in master panel
  Widget _buildUnitListTile(
    ThemeData theme,
    bool isDark, {
    required UnitModel unit,
    required String propertyName,
    required bool isSelected,
    VoidCallback? onUnitSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: isSelected ? null : context.gradients.sectionBackground,
        color: isSelected ? theme.colorScheme.primaryContainer : null,
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
        onTap: () async {
          // Fetch property details for selected unit
          final property = await ref.read(
            propertyByIdProvider(unit.propertyId).future,
          );
          if (mounted) {
            setState(() {
              _selectedUnit = unit;
              _selectedProperty = property;
            });
            onUnitSelected?.call();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unit name + status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      unit.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? (isDark ? Colors.white : theme.colorScheme.onPrimaryContainer)
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: unit.isAvailable
                          ? const Color(0xFF66BB6A).withAlpha((0.2 * 255).toInt()) // Same as Confirmed badge
                          : AppColors.error.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      unit.isAvailable ? 'Dostupan' : 'Nedostupan',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? Colors.white // White text when unit is selected
                            : (unit.isAvailable
                                ? const Color(0xFF66BB6A) // Green for available
                                : AppColors.error), // Red for unavailable
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Delete button
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      onPressed: () => _confirmDeleteUnit(context, unit),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.7)
                            : theme.colorScheme.error,
                      ),
                      tooltip: 'Obriši jedinicu',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Property name
              Text(
                propertyName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? (isDark ? Colors.white.withOpacity(0.7) : theme.colorScheme.onPrimaryContainer.withOpacity(0.7))
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 8),

              // Max guests + price
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: isSelected
                        ? (isDark ? Colors.white.withOpacity(0.7) : theme.colorScheme.onPrimaryContainer.withOpacity(0.7))
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${unit.maxGuests}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? (isDark ? Colors.white.withOpacity(0.7) : theme.colorScheme.onPrimaryContainer.withOpacity(0.7))
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.euro_outlined,
                    size: 16,
                    color: isSelected
                        ? (isDark ? Colors.white.withOpacity(0.7) : theme.colorScheme.onPrimaryContainer.withOpacity(0.7))
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${unit.pricePerNight.toStringAsFixed(0)}/noć',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? (isDark ? Colors.white.withOpacity(0.7) : theme.colorScheme.onPrimaryContainer.withOpacity(0.7))
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
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
                color: context.borderColor.withOpacity(0.5),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: _buildTabs(),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            // Tab bar left padding: smaller for mobile
            padding: EdgeInsets.only(
              left: screenWidth < 600 ? 4 : 16,
            ),
            // Responsive padding: smaller for mobile, larger for desktop
            labelPadding: EdgeInsets.symmetric(
              horizontal: screenWidth < 600 ? 8 : 20,
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
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.1),
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 3,
                ),
              ),
            ),
          ),
        ),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTab1_BasicInfo(theme, isDark),
              _buildTab2_Pricing(theme, isDark),
              _buildTab3_Widget(theme, isDark),
              _buildTab4_Advanced(theme, isDark),
            ],
          ),
        ),
      ],
    );
  }

  /// Empty state - no unit selected
  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.home_work_outlined,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Izaberite jedinicu',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Odaberite jedinicu iz liste da vidite detalje',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Tab content builders
  Widget _buildTab1_BasicInfo(ThemeData theme, bool isDark) {
    if (_selectedUnit == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isMobile = screenWidth < 600;

    // Build individual cards as widgets for flex layout
    final informacijeCard = _buildInfoCard(
      theme,
      title: 'Informacije',
      icon: Icons.info_outline,
      isMobile: isMobile,
      children: [
        _buildDetailRow(theme, 'Naziv', _selectedUnit!.name),
        _buildDetailRow(theme, 'Slug', _selectedUnit!.slug ?? 'N/A'),
        if (_selectedUnit!.description != null)
          _buildDetailRow(theme, 'Opis', _selectedUnit!.description!),
        _buildDetailRow(
          theme,
          'Status',
          _selectedUnit!.isAvailable ? 'Dostupan' : 'Nedostupan',
          valueColor: _selectedUnit!.isAvailable
              ? AppColors.success
              : AppColors.error,
        ),
      ],
    );

    final kapacitetCard = _buildInfoCard(
      theme,
      title: 'Kapacitet',
      icon: Icons.people_outline,
      isMobile: isMobile,
      children: [
        _buildDetailRow(
          theme,
          'Spavaće sobe',
          '${_selectedUnit!.bedrooms}',
        ),
        _buildDetailRow(theme, 'Kupaonice', '${_selectedUnit!.bathrooms}'),
        _buildDetailRow(
          theme,
          'Max gostiju',
          '${_selectedUnit!.maxGuests}',
        ),
        if (_selectedUnit!.areaSqm != null)
          _buildDetailRow(
            theme,
            'Površina',
            '${_selectedUnit!.areaSqm!.toStringAsFixed(0)} m²',
          ),
      ],
    );

    final cijenaCard = _buildInfoCard(
      theme,
      title: 'Cijena',
      icon: Icons.euro_outlined,
      isMobile: isMobile,
      children: [
        _buildDetailRow(
          theme,
          'Cijena po noći',
          '€${_selectedUnit!.pricePerNight.toStringAsFixed(0)}',
          valueColor: theme.colorScheme.primary,
        ),
        _buildDetailRow(
          theme,
          'Min noći',
          '${_selectedUnit!.minStayNights}',
        ),
      ],
    );

    return ListView(
      padding: EdgeInsets.all(context.horizontalPadding),
      children: [
        // Header with Edit Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Osnovni Podaci',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 20,
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
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Uredi',
                          style: TextStyle(
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

        // Unit Details Cards - Flex layout on desktop
        if (isDesktop) ...[
          // Row 1: Informacije and Kapacitet side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: informacijeCard),
              const SizedBox(width: 16),
              Expanded(child: kapacitetCard),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: Cijena and Fotografije side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cijenaCard),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  theme,
                  title: 'Fotografije',
                  icon: Icons.photo_library_outlined,
                  isMobile: isMobile,
                  children: [
                    if (_selectedUnit!.images.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedUnit!.images.take(6).map((imageUrl) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
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
                      if (_selectedUnit!.images.length > 6)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '+${_selectedUnit!.images.length - 6} više',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ] else
                      Text(
                        'Nema fotografija',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          // Stacked layout for mobile/tablet
          informacijeCard,
          const SizedBox(height: 16),
          kapacitetCard,
          const SizedBox(height: 16),
          cijenaCard,
          // Images Section for mobile
          if (_selectedUnit!.images.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              theme,
              title: 'Fotografije',
              icon: Icons.photo_library_outlined,
              isMobile: isMobile,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedUnit!.images.take(6).map((imageUrl) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
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
                if (_selectedUnit!.images.length > 6)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+${_selectedUnit!.images.length - 6} više',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildTab2_Pricing(ThemeData theme, bool isDark) {
    if (_selectedUnit == null) return const SizedBox.shrink();

    // Embed UnitPricingScreen content WITHOUT app bar
    // Key forces widget recreation when unit changes
    return UnitPricingScreen(
      key: ValueKey('pricing_${_selectedUnit!.id}'),
      unit: _selectedUnit,
      showAppBar: false, // Hide app bar when embedded in tabs
    );
  }

  Widget _buildTab3_Widget(ThemeData theme, bool isDark) {
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

  Widget _buildTab4_Advanced(ThemeData theme, bool isDark) {
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(1, isDark: isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: context.gradients.sectionBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.gradients.sectionBorder,
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      icon,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
