import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/owner_app_drawer.dart';
import '../widgets/property_card_owner.dart';
import '../providers/owner_properties_provider.dart';
import 'property_form_screen.dart';
import 'units_management_screen.dart';
import '../../../../shared/providers/repository_providers.dart';

/// Properties list screen (Moji Objekti)
class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moji Objekti'),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'properties'),
      body: propertiesAsync.when(
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
              itemCount: properties.length + 1,
              itemBuilder: (context, index) {
                if (index == properties.length) {
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
      await ref.read(ownerPropertiesRepositoryProvider).updateProperty(
        propertyId: propertyId,
        isActive: isActive,
      );
      ref.invalidate(ownerPropertiesProvider);
    } catch (e) {
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
