import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../providers/owner_properties_provider.dart';
import '../widgets/property_card_owner.dart';
import '../widgets/owner_calendar_widget.dart';
import '../../data/owner_properties_repository.dart';
import 'property_form_screen.dart';
import 'units_management_screen.dart';
import 'owner_bookings_screen.dart';
import 'dashboard_overview_tab.dart';

/// Owner dashboard screen with tabs
class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.goToNotifications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.goToProfile();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pregled', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Moji Objekti', icon: Icon(Icons.home_outlined)),
            Tab(text: 'Kalendar', icon: Icon(Icons.calendar_month)),
            Tab(text: 'Rezervacije', icon: Icon(Icons.book_online)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DashboardOverviewTab(),
          _PropertiesListTab(),
          _MasterCalendarTab(),
          _BookingsListTab(),
        ],
      ),
    );
  }
}

/// Properties list tab
class _PropertiesListTab extends ConsumerWidget {
  const _PropertiesListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);

    return propertiesAsync.when(
      data: (properties) {
        if (properties.isEmpty) {
          return _EmptyPropertiesState(
            onAddProperty: () => _navigateToAddProperty(context),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ownerPropertiesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length + 1, // +1 for add button at bottom
            itemBuilder: (context, index) {
              if (index == properties.length) {
                // Add property button at bottom
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToAddProperty(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj Novi Objekt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                );
              }

              final property = properties[index];
              return PropertyCardOwner(
                property: property,
                onTap: () => _navigateToUnitsManagement(context, property.id),
                onEdit: () => _navigateToEditProperty(context, property),
                onDelete: () => _confirmDelete(context, ref, property.id),
                onTogglePublished: (isActive) =>
                    _togglePublished(ref, property.id, isActive),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Greška: $error'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(ownerPropertiesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddProperty(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PropertyFormScreen(),
      ),
    );
  }

  void _navigateToEditProperty(BuildContext context, property) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PropertyFormScreen(property: property),
      ),
    );
  }

  void _navigateToUnitsManagement(BuildContext context, String propertyId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnitsManagementScreen(propertyId: propertyId),
      ),
    );
  }

  Future<void> _togglePublished(
    WidgetRef ref,
    String propertyId,
    bool isActive,
  ) async {
    try {
      // Update property active status
      await ref.read(ownerPropertiesRepositoryProvider).updateProperty(
        propertyId: propertyId,
        isActive: isActive,
      );

      // Refresh the properties list
      ref.invalidate(ownerPropertiesProvider);
    } catch (e) {
      // Error handling is done in the UI layer (PropertyCardOwner)
      rethrow;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String propertyId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši nekretninu'),
        content: const Text(
          'Jeste li sigurni da želite obrisati ovu nekretninu? '
          'Ova akcija se ne može poništiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // await ref
        //     .read(ownerPropertiesRepositoryProvider)
        //     .deleteProperty(propertyId);
        ref.invalidate(ownerPropertiesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nekretnina uspješno obrisana')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Greška: $e')),
          );
        }
      }
    }
  }
}

/// Empty properties state
class _EmptyPropertiesState extends StatelessWidget {
  const _EmptyPropertiesState({required this.onAddProperty});

  final VoidCallback onAddProperty;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.villa, size: 120, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'Nemate dodanih nekretnina',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Dodajte prvu nekretninu i počnite primati rezervacije',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAddProperty,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj Prvu Nekretninu'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Master calendar tab
class _MasterCalendarTab extends ConsumerWidget {
  const _MasterCalendarTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const OwnerCalendarWidget();
  }
}

/// Bookings list tab
class _BookingsListTab extends ConsumerWidget {
  const _BookingsListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const OwnerBookingsScreen();
  }
}
