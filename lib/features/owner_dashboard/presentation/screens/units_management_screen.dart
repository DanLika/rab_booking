import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import 'unit_form_screen.dart';
import 'unit_pricing_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';

/// Units management screen for a property
class UnitsManagementScreen extends ConsumerStatefulWidget {
  const UnitsManagementScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  ConsumerState<UnitsManagementScreen> createState() =>
      _UnitsManagementScreenState();
}

class _UnitsManagementScreenState
    extends ConsumerState<UnitsManagementScreen> {
  List<UnitModel>? _units;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(ownerPropertiesRepositoryProvider);
      final units = await repository.getPropertyUnits(widget.propertyId); // Changed from getUnits
      setState(() {
        _units = units;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upravljanje Jedinicama'),
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withAlpha((0.1 * 255).toInt()),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: FilledButton.icon(
            onPressed: _navigateToAddUnit,
            icon: const Icon(Icons.add, size: 24),
            label: const Text(
              'Dodaj Novu Jedinicu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Greška: $_error'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadUnits,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }

    if (_units == null || _units!.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadUnits,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _units!.length,
        itemBuilder: (context, index) {
          final unit = _units![index];
          return _UnitCard(
            unit: unit,
            onEdit: () => _navigateToEditUnit(unit),
            onDelete: () => _confirmDeleteUnit(unit.id),
            onManagePricing: () => _navigateToManagePricing(unit),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apartment,
              size: 120,
              color: theme.colorScheme.onSurface.withAlpha((0.3 * 255).toInt()),
            ),
            const SizedBox(height: 24),
            Text(
              'Nema dodanih jedinica',
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Dodajte prvu jedinicu (apartman, sobu, studio) za ovu nekretninu',
              style: theme.textTheme.bodyLarge?.copyWith(
                    color: context.textColorSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _navigateToAddUnit,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj Prvu Jedinicu'),
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

  void _navigateToAddUnit() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => UnitFormScreen(propertyId: widget.propertyId),
          ),
        )
        .then((_) => _loadUnits());
  }

  void _navigateToEditUnit(UnitModel unit) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => UnitFormScreen(
              propertyId: widget.propertyId,
              unit: unit,
            ),
          ),
        )
        .then((_) => _loadUnits());
  }

  void _navigateToManagePricing(UnitModel unit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnitPricingScreen(unit: unit),
      ),
    );
  }

  Future<void> _confirmDeleteUnit(String unitId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši jedinicu'),
        content: const Text(
          'Jeste li sigurni da želite obrisati ovu jedinicu? '
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
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(ownerPropertiesRepositoryProvider).deleteUnit(widget.propertyId, unitId);
        _loadUnits();
        if (mounted) {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            'Jedinica uspješno obrisana',
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: 'Greška pri brisanju jedinice',
          );
        }
      }
    }
  }
}

/// Unit card widget
class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.onEdit,
    required this.onDelete,
    required this.onManagePricing,
  });

  final UnitModel unit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManagePricing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unit name and status
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        unit.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Price
                    Text(
                      '€${unit.pricePerNight.toStringAsFixed(0)}/noć',
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: unit.isAvailable
                        ? const Color(0xFF10B981).withAlpha((0.1 * 255).toInt())
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    unit.isAvailable ? 'Dostupno' : 'Nedostupno',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: unit.isAvailable
                              ? const Color(0xFF10B981)
                              : theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Unit details
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildDetail(
                  context,
                  icon: Icons.bed,
                  label: '${unit.bedrooms} ${unit.bedrooms == 1 ? 'soba' : 'sobe'}',
                ),
                _buildDetail(
                  context,
                  icon: Icons.bathroom,
                  label: '${unit.bathrooms} ${unit.bathrooms == 1 ? 'kupaonica' : 'kupaonice'}',
                ),
                _buildDetail(
                  context,
                  icon: Icons.person,
                  label: 'Do ${unit.maxGuests} gostiju',
                ),
                if (unit.areaSqm != null)
                  _buildDetail(
                    context,
                    icon: Icons.aspect_ratio,
                    label: '${unit.areaSqm}m²',
                  ),
              ],
            ),

            if (unit.description != null && unit.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                unit.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.textColorSecondary,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Actions - Responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 400;

                if (isMobile) {
                  // Stack buttons vertically on small screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onManagePricing,
                        icon: const Icon(Icons.euro_symbol),
                        label: const Text('Upravljaj Cijenama'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit),
                              label: const Text('Uredi'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onDelete,
                              icon: const Icon(Icons.delete),
                              label: const Text('Obriši'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                // Horizontal layout for wider screens
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: onManagePricing,
                      icon: const Icon(Icons.euro_symbol),
                      label: const Text('Cijene'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                      ),
                    ),
                    Row(
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
                            foregroundColor: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.textColorSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.textColorSecondary,
              ),
        ),
      ],
    );
  }
}
