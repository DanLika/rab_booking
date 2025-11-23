import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_color_extensions.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/models/property_model.dart';
import '../providers/owner_properties_provider.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
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

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedPropertyFilter; // null = all properties

  final List<Tab> _tabs = const [
    Tab(text: 'Osnovni Podaci', icon: Icon(Icons.info_outline)),
    Tab(text: 'Cjenovnik', icon: Icon(Icons.euro_outlined)),
    Tab(text: 'Widget', icon: Icon(Icons.widgets_outlined)),
    Tab(text: 'Napredne Postavke', icon: Icon(Icons.settings_outlined)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Initialize property filter from parameter
    if (widget.initialPropertyFilter != null) {
      _selectedPropertyFilter = widget.initialPropertyFilter;
    }
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
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.authSecondary],
                  ),
                ),
              ),
            ),
      drawer: const OwnerAppDrawer(currentRoute: 'units'),
      // EndDrawer for mobile/tablet - shows master panel
      endDrawer: !isDesktop
          ? Drawer(
              width: 320,
              child: Builder(
                builder: (context) => _buildMasterPanel(
                  theme,
                  isDark,
                  onUnitSelected: () => Navigator.of(context).pop(),
                ),
              ),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.veryDarkGray,
                    theme.colorScheme.veryDarkGray.withAlpha((0.85 * 255).toInt()),
                    theme.colorScheme.mediumDarkGray.withAlpha((0.7 * 255).toInt()),
                    theme.colorScheme.mediumDarkGray.withAlpha((0.85 * 255).toInt()),
                    theme.colorScheme.mediumDarkGray,
                  ]
                : [
                    theme.colorScheme.veryLightGray,
                    theme.colorScheme.veryLightGray.withAlpha((0.85 * 255).toInt()),
                    Colors.white.withAlpha((0.7 * 255).toInt()),
                    Colors.white.withAlpha((0.85 * 255).toInt()),
                    Colors.white,
                  ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: isDesktop
            ? _buildDesktopLayout(theme, isDark)
            : _buildMobileLayout(theme, isDark),
      ),
    );
  }

  /// Desktop layout - Master-Detail sa split view
  /// Master panel je DESNO, Detail panel LIJEVO
  Widget _buildDesktopLayout(ThemeData theme, bool isDark) {
    return Row(
      children: [
        // Detail panel (left) - Tab content
        Expanded(child: _buildDetailPanel(theme, isDark)),

        // Master panel (right) - Units list
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerHighest,
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
    return _buildDetailPanel(theme, isDark);
  }

  /// Master panel - Units list (all properties)
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
                      'Sve Jedinice',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      context.push(OwnerRoutes.unitWizard);
                    },
                    tooltip: 'Dodaj novu jedinicu',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pretraži jedinice...',
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
              const SizedBox(height: 8),

              // Property filter dropdown
              propertiesAsync.when(
                data: (properties) {
                  if (properties.isEmpty) return const SizedBox.shrink();

                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedPropertyFilter,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.filter_list, size: 20),
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
                    items: [
                      const DropdownMenuItem<String?>(
                        child: Text('Svi objekti'),
                      ),
                      ...properties.map((property) {
                        return DropdownMenuItem<String?>(
                          value: property.id,
                          child: Text(property.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPropertyFilter = value;
                      });
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        // Units list
        Expanded(
          child: _buildUnitsListView(
            theme,
            isDark,
            onUnitSelected: onUnitSelected,
          ),
        ),
      ],
    );
  }

  /// Units list view - fetches and displays all units
  Widget _buildUnitsListView(
    ThemeData theme,
    bool isDark, {
    VoidCallback? onUnitSelected,
  }) {
    final unitsAsync = ref.watch(ownerUnitsProvider);
    final propertiesAsync = ref.watch(ownerPropertiesProvider);

    return unitsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: PropertyListSkeleton(),
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
                'Greška pri učitavanju jedinica',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (units) {
        // Apply filters
        final filteredUnits = units.where((unit) {
          // Search filter
          if (_searchQuery.isNotEmpty) {
            final matchesSearch =
                unit.name.toLowerCase().contains(_searchQuery) ||
                (unit.description?.toLowerCase().contains(_searchQuery) ??
                    false);
            if (!matchesSearch) return false;
          }

          // Property filter
          if (_selectedPropertyFilter != null) {
            if (unit.propertyId != _selectedPropertyFilter) return false;
          }

          return true;
        }).toList();

        if (filteredUnits.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty || _selectedPropertyFilter != null
                        ? Icons.search_off
                        : Icons.home_work_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty || _selectedPropertyFilter != null
                        ? 'Nema rezultata'
                        : 'Nema smještajnih jedinica',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty || _selectedPropertyFilter != null
                        ? 'Pokušajte promijeniti filter'
                        : 'Dodajte prvu jedinicu da biste počeli',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Build properties map for quick lookup
        final propertiesMap = <String, PropertyModel>{};
        propertiesAsync.whenData((properties) {
          for (final property in properties) {
            propertiesMap[property.id] = property;
          }
        });

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredUnits.length,
          itemBuilder: (context, index) {
            final unit = filteredUnits[index];
            final property = propertiesMap[unit.propertyId];
            final isSelected = _selectedUnit?.id == unit.id;

            return _buildUnitListTile(
              theme,
              isDark,
              unit: unit,
              propertyName: property?.name ?? 'Unknown Property',
              isSelected: isSelected,
              onUnitSelected: onUnitSelected,
            );
          },
        );
      },
    );
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
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
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
                          ? AppColors.success.withAlpha((0.2 * 255).toInt())
                          : AppColors.error.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      unit.isAvailable ? 'Dostupan' : 'Nedostupan',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: unit.isAvailable
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
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
  Widget _buildDetailPanel(ThemeData theme, bool isDark) {
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
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: _tabs,
            isScrollable: true,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header with Edit Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Osnovni Podaci',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                context.push(
                  OwnerRoutes.unitWizardEdit.replaceAll(
                    ':id',
                    _selectedUnit!.id,
                  ),
                );
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Uredi'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Unit Details Cards
        _buildInfoCard(
          theme,
          title: 'Informacije',
          icon: Icons.info_outline,
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
        ),
        const SizedBox(height: 16),

        _buildInfoCard(
          theme,
          title: 'Kapacitet',
          icon: Icons.people_outline,
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
        ),
        const SizedBox(height: 16),

        _buildInfoCard(
          theme,
          title: 'Cijena',
          icon: Icons.euro_outlined,
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
        ),

        // Images Section
        if (_selectedUnit!.images.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInfoCard(
            theme,
            title: 'Fotografije',
            icon: Icons.photo_library_outlined,
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
    );
  }

  Widget _buildTab2_Pricing(ThemeData theme, bool isDark) {
    if (_selectedUnit == null) return const SizedBox.shrink();

    // Embed UnitPricingScreen content WITHOUT app bar
    return UnitPricingScreen(
      unit: _selectedUnit,
      showAppBar: false, // Hide app bar when embedded in tabs
    );
  }

  Widget _buildTab3_Widget(ThemeData theme, bool isDark) {
    if (_selectedUnit == null || _selectedProperty == null) {
      return const SizedBox.shrink();
    }

    // Embed WidgetSettingsScreen content WITHOUT app bar
    return WidgetSettingsScreen(
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
    return WidgetAdvancedSettingsScreen(
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
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.authSecondary],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
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
