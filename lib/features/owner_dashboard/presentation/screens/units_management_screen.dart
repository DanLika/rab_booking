import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import 'unit_form_screen.dart';
import 'unit_pricing_screen.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Units management screen for a property
class UnitsManagementScreen extends ConsumerStatefulWidget {
  const UnitsManagementScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  ConsumerState<UnitsManagementScreen> createState() =>
      _UnitsManagementScreenState();
}

class _UnitsManagementScreenState extends ConsumerState<UnitsManagementScreen> {
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
      final units = await repository.getPropertyUnits(
        widget.propertyId,
      ); // Changed from getUnits
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
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.colorScheme.surface,
      appBar: CommonAppBar(
        title: 'Upravljanje Jedinicama',
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: Stack(
        children: [
          // Content
          _buildBody(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withAlpha((0.08 * 255).toInt()),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: GradientButton(
            text: 'Dodaj Novu Jedinicu',
            onPressed: _navigateToAddUnit,
            icon: Icons.add,
            width: double.infinity,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Učitavanje...',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.errorColor.withAlpha((0.1 * 255).toInt()),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: context.errorColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Greška: $_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  text: 'Pokušaj ponovo',
                  onPressed: _loadUnits,
                  icon: Icons.refresh,
                  height: 48,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_units == null || _units!.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadUnits,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate number of columns based on screen width
          int crossAxisCount;
          double topPadding;
          double horizontalPadding;

          if (constraints.maxWidth >= 1200) {
            // Desktop: 3 columns
            crossAxisCount = 3;
            topPadding = 24;
            horizontalPadding = 24;
          } else if (constraints.maxWidth >= 800) {
            // Tablet landscape: 2 columns
            crossAxisCount = 2;
            topPadding = 20;
            horizontalPadding = 20;
          } else if (constraints.maxWidth >= 600) {
            // Tablet portrait: 2 columns
            crossAxisCount = 2;
            topPadding = 20;
            horizontalPadding = 16;
          } else {
            // Mobile: 1 column
            crossAxisCount = 1;
            topPadding = 16;
            horizontalPadding = 16;
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: topPadding,
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: 16,
            ),
            child: Wrap(
              spacing: 16, // Horizontal spacing between cards
              runSpacing: 16, // Vertical spacing between rows
              children: _units!.map((unit) {
                // Calculate card width based on screen width & columns
                final cardWidth = _calculateCardWidth(
                  constraints.maxWidth,
                  crossAxisCount,
                  horizontalPadding,
                );

                return SizedBox(
                  width: cardWidth,
                  child: _UnitCard(
                    unit: unit,
                    onEdit: () => _navigateToEditUnit(unit),
                    onDelete: () => _confirmDeleteUnit(unit.id),
                    onManagePricing: () => _navigateToManagePricing(unit),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  double _calculateCardWidth(
    double screenWidth,
    int columns,
    double horizontalPadding,
  ) {
    // Available width = screen - left padding - right padding
    final availableWidth = screenWidth - (horizontalPadding * 2);

    // Spacing between columns = (columns - 1) × 16px
    final totalSpacing = (columns - 1) * 16.0;

    // Card width = (available - spacing) / columns
    return (availableWidth - totalSpacing) / columns;
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withAlpha(
                    (0.08 * 255).toInt(),
                  ),
                ),
                child: Icon(
                  Icons.apartment,
                  size: 70,
                  color: theme.colorScheme.primary,
                ),
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
              GradientButton(
                text: 'Dodaj Prvu Jedinicu',
                onPressed: _navigateToAddUnit,
                icon: Icons.add,
              ),
            ],
          ),
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
            builder: (_) =>
                UnitFormScreen(propertyId: widget.propertyId, unit: unit),
          ),
        )
        .then((_) => _loadUnits());
  }

  void _navigateToManagePricing(UnitModel unit) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => UnitPricingScreen(unit: unit)));
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
        await ref
            .read(ownerPropertiesRepositoryProvider)
            .deleteUnit(widget.propertyId, unitId);
        unawaited(_loadUnits());
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
      margin: EdgeInsets.zero, // Remove margin - GridView handles spacing
      elevation: 0.5,
      shadowColor: theme.colorScheme.shadow.withAlpha((0.05 * 255).toInt()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha((0.1 * 255).toInt()),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                    // Price - Minimalist
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(
                          (0.1 * 255).toInt(),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '€${unit.pricePerNight.toStringAsFixed(0)}/noć',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Status Badge - Minimalist
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: unit.isAvailable
                            ? context.successColor
                            : theme.colorScheme.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      unit.isAvailable ? 'Dostupno' : 'Nedostupno',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: unit.isAvailable
                            ? context.successColor
                            : theme.colorScheme.onSurface.withAlpha(
                                (0.6 * 255).toInt(),
                              ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Unit details
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildDetail(
                  context,
                  icon: Icons.bed,
                  label:
                      '${unit.bedrooms} ${unit.bedrooms == 1 ? 'soba' : 'sobe'}',
                ),
                _buildDetail(
                  context,
                  icon: Icons.bathroom,
                  label:
                      '${unit.bathrooms} ${unit.bathrooms == 1 ? 'kupaonica' : 'kupaonice'}',
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
              const SizedBox(height: 10),
              Text(
                unit.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textColorSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Actions - Compact grid-friendly layout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pricing button
                Expanded(
                  child: Tooltip(
                    message: 'Upravljaj cijenama',
                    child: Builder(
                      builder: (context) => OutlinedButton(
                        onPressed: onManagePricing,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.successColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(
                            color: context.successColor.withAlpha(
                              (0.4 * 255).toInt(),
                            ),
                          ),
                        ),
                        child: const Icon(Icons.euro_symbol, size: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit button
                Expanded(
                  child: Tooltip(
                    message: 'Uredi jedinicu',
                    child: OutlinedButton(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withAlpha(
                            (0.3 * 255).toInt(),
                          ),
                        ),
                      ),
                      child: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                Expanded(
                  child: Tooltip(
                    message: 'Obriši jedinicu',
                    child: OutlinedButton(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: theme.colorScheme.error.withAlpha(
                            (0.4 * 255).toInt(),
                          ),
                        ),
                      ),
                      child: const Icon(Icons.delete_outline, size: 18),
                    ),
                  ),
                ),
              ],
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
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary.withAlpha((0.7 * 255).toInt()),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.textColorSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
