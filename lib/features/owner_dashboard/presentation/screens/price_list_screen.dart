import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/unit_model.dart';
import '../providers/owner_calendar_provider.dart';
import '../widgets/owner_app_drawer.dart';
import '../widgets/price_list_calendar_widget.dart';

/// Price List Screen - displays year-grid calendar for price management
class PriceListScreen extends ConsumerStatefulWidget {
  const PriceListScreen({super.key});

  @override
  ConsumerState<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends ConsumerState<PriceListScreen> {
  UnitModel? _selectedUnit;

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(allOwnerUnitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cjenovnik'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'price-list'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: unitsAsync.when(
          data: (units) {
            if (units.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with background
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.meeting_room_outlined,
                          size: 70,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceL),
                      // Title
                      Text(
                        'Nemate dodane jedinice',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceL),
                        child: Text(
                          'Dodajte jedinicu kako biste mogli upravljati cijenama za vaše smještajne objekte.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Auto-select first unit if none selected
            if (_selectedUnit == null || !units.contains(_selectedUnit)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedUnit = units.first;
                  });
                }
              });
            }

            if (_selectedUnit == null) {
              return const SizedBox.shrink();
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final theme = Theme.of(context);
                final isDesktop = constraints.maxWidth >= 1200;

                // Unit selector card widget
                final selectorCard = Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.dividerColor.withAlpha((0.3 * 255).toInt()),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with premium icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
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
                          value: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Jedinica',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.meeting_room_outlined),
                          ),
                          items: units.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit.name),
                            );
                          }).toList(),
                          onChanged: (unit) {
                            if (unit != null) {
                              setState(() {
                                _selectedUnit = unit;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );

                if (isDesktop) {
                  // Desktop: Row layout (Selector 320px | Calendar flex)
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 320,
                        child: selectorCard,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PriceListCalendarWidget(unit: _selectedUnit!),
                      ),
                    ],
                  );
                } else {
                  // Tablet/Mobile: Column layout (existing)
                  return Column(
                    children: [
                      selectorCard,
                      const SizedBox(height: 16),
                      Expanded(
                        child: PriceListCalendarWidget(unit: _selectedUnit!),
                      ),
                    ],
                  );
                }
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: AppDimensions.iconSizeXL,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppDimensions.spaceS),
                  Text(
                    'Greška pri učitavanju jedinica',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.spaceXS),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
