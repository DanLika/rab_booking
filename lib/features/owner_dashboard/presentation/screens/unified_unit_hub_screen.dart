import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/models/property_model.dart';
import '../providers/owner_properties_provider.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Unified Unit Hub - Centralno mjesto za sve unit operacije
/// Master-Detail layout sa tab navigacijom
class UnifiedUnitHubScreen extends ConsumerStatefulWidget {
  final String? initialUnitId;
  final int initialTabIndex;

  const UnifiedUnitHubScreen({
    super.key,
    this.initialUnitId,
    this.initialTabIndex = 0,
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Smještajne Jedinice',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'units'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withOpacity(0.95),
                  ]
                : [
                    const Color(0xFFFAF8F3),
                    Colors.white,
                  ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: isDesktop
            ? _buildDesktopLayout(theme, isDark)
            : _buildMobileLayout(theme, isDark),
      ),
    );
  }

  /// Desktop layout - Master-Detail sa split view
  Widget _buildDesktopLayout(ThemeData theme, bool isDark) {
    return Row(
      children: [
        // Master panel (left) - Units list
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerHighest,
            border: Border(
              right: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: _buildMasterPanel(theme, isDark),
        ),

        // Detail panel (right) - Tab content
        Expanded(
          child: _buildDetailPanel(theme, isDark),
        ),
      ],
    );
  }

  /// Mobile/Tablet layout - Full screen tabs
  Widget _buildMobileLayout(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Selected unit header
        if (_selectedUnit != null) _buildSelectedUnitHeader(theme, isDark),

        // Tab navigation
        Expanded(
          child: _buildDetailPanel(theme, isDark),
        ),
      ],
    );
  }

  /// Master panel - Units list (all properties)
  Widget _buildMasterPanel(ThemeData theme, bool isDark) {
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
          child: Row(
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
                  // TODO: Navigate to create new unit
                },
                tooltip: 'Dodaj novu jedinicu',
              ),
            ],
          ),
        ),

        // Units list
        Expanded(
          child: _buildUnitsListView(theme, isDark),
        ),
      ],
    );
  }

  /// Units list view - fetches and displays all units
  Widget _buildUnitsListView(ThemeData theme, bool isDark) {
    final unitsAsync = ref.watch(ownerUnitsProvider);
    final propertiesAsync = ref.watch(ownerPropertiesProvider);

    return unitsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
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
        if (units.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home_work_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nema smještajnih jedinica',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dodajte prvu jedinicu da biste počeli',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
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
          itemCount: units.length,
          itemBuilder: (context, index) {
            final unit = units[index];
            final property = propertiesMap[unit.propertyId];
            final isSelected = _selectedUnit?.id == unit.id;

            return _buildUnitListTile(
              theme,
              isDark,
              unit: unit,
              propertyName: property?.name ?? 'Unknown Property',
              isSelected: isSelected,
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
          final property = await ref.read(propertyByIdProvider(unit.propertyId).future);
          if (mounted) {
            setState(() {
              _selectedUnit = unit;
              _selectedProperty = property;
            });
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
                            ? theme.colorScheme.onPrimaryContainer
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
                        color: unit.isAvailable ? AppColors.success : AppColors.error,
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
                      ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7)
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
                        ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${unit.maxGuests}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.euro_outlined,
                    size: 16,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${unit.pricePerNight.toStringAsFixed(0)}/noć',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7)
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

  /// Selected unit header (for mobile/tablet)
  Widget _buildSelectedUnitHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              // TODO: Show units list modal
            },
            tooltip: 'Prikaži sve jedinice',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedUnit?.name ?? 'Izaberi jedinicu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                if (_selectedProperty != null)
                  Text(
                    _selectedProperty!.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
            color: theme.colorScheme.surface,
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
    return Center(
      child: Text(
        'Tab 1: Osnovni Podaci\n(Unit Form Screen)',
        style: theme.textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTab2_Pricing(ThemeData theme, bool isDark) {
    return Center(
      child: Text(
        'Tab 2: Cjenovnik\n(Price Calendar)',
        style: theme.textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTab3_Widget(ThemeData theme, bool isDark) {
    return Center(
      child: Text(
        'Tab 3: Widget Settings',
        style: theme.textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTab4_Advanced(ThemeData theme, bool isDark) {
    return Center(
      child: Text(
        'Tab 4: Napredne Postavke',
        style: theme.textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
