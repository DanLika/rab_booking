import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/units_provider.dart';
import '../../domain/models/unit.dart';

class UnitsListScreen extends ConsumerWidget {
  final String propertyId;
  final String propertyName;

  const UnitsListScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsNotifierProvider(propertyId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smještajne jedinice'),
            Text(
              propertyName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(unitsNotifierProvider(propertyId).notifier).refresh();
            },
            tooltip: 'Osvježi',
          ),
        ],
      ),
      body: unitsAsync.when(
        data: (units) {
          if (units.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(unitsNotifierProvider(propertyId).notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: units.length,
              itemBuilder: (context, index) {
                return _UnitCard(
                  unit: units[index],
                  propertyId: propertyId,
                  onTap: () {
                    // TODO: Navigate to Unit Calendar
                    context.push('/units/${units[index].id}/calendar');
                  },
                  onEdit: () {
                    context.push(
                      '/properties/$propertyId/units/${units[index].id}/edit',
                    );
                  },
                  onDelete: () => _showDeleteDialog(
                    context,
                    ref,
                    units[index],
                  ),
                  onToggleActive: (isActive) async {
                    try {
                      await ref
                          .read(unitsNotifierProvider(propertyId).notifier)
                          .toggleActive(units[index].id, isActive);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isActive
                                  ? 'Jedinica aktivirana'
                                  : 'Jedinica deaktivirana',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Greška: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
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
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Greška: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(unitsNotifierProvider(propertyId).notifier)
                      .refresh();
                },
                child: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/properties/$propertyId/units/add');
        },
        icon: const Icon(Icons.add),
        label: const Text('Dodaj jedinicu'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bed_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Nema smještajnih jedinica',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodajte apartmane ili sobe za ovaj objekat',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/properties/$propertyId/units/add');
            },
            icon: const Icon(Icons.add),
            label: const Text('Dodaj prvu jedinicu'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Unit unit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši jedinicu?'),
        content: Text(
          'Da li ste sigurni da želite obrisati "${unit.name}"?\n\n'
          'Ova akcija će također obrisati sve rezervacije za ovu jedinicu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(unitsNotifierProvider(propertyId).notifier)
            .deleteUnit(unit.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jedinica obrisana'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _UnitCard extends StatelessWidget {
  final Unit unit;
  final String propertyId;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggleActive;

  const _UnitCard({
    required this.unit,
    required this.propertyId,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (unit.images.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  unit.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 48),
                  ),
                ),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.bed, size: 48),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          unit.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      // Active Switch
                      Switch(
                        value: unit.isActive,
                        onChanged: onToggleActive,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Info Row
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.people,
                        label: '${unit.maxGuests} gostiju',
                      ),
                      if (unit.bedrooms != null)
                        _InfoChip(
                          icon: Icons.bed,
                          label: '${unit.bedrooms} spavaće sobe',
                        ),
                      if (unit.bathrooms != null)
                        _InfoChip(
                          icon: Icons.bathroom,
                          label: '${unit.bathrooms} kupatila',
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Price
                  Text(
                    '${unit.basePrice.toStringAsFixed(0)}€ / noć',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Uredi'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        label: const Text('Obriši'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
