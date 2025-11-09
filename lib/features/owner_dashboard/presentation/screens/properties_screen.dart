import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/owner_app_drawer.dart';
import '../widgets/property_card_owner.dart';
import '../providers/owner_properties_provider.dart';
import 'property_form_screen.dart';
import 'units_management_screen.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Properties list screen (Moji Objekti)
class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CommonAppBar(
        title: 'Moji Objekti',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'properties'),
      body: Stack(
        children: [
          // Content
          propertiesAsync.when(
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive grid columns based on screen width
                    int crossAxisCount;
                    if (constraints.maxWidth >= 1200) {
                      crossAxisCount = 3; // Desktop: 3 columns
                    } else if (constraints.maxWidth >= 600) {
                      crossAxisCount = 2; // Tablet: 2 columns
                    } else {
                      crossAxisCount = 1; // Mobile: 1 column
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.only(
                        top: AppDimensions.spaceM,
                        left: AppDimensions.spaceM,
                        right: AppDimensions.spaceM,
                        bottom: 80,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: AppDimensions.spaceM,
                        mainAxisSpacing: AppDimensions.spaceM,
                        mainAxisExtent: constraints.maxWidth >= 600
                            ? 400
                            : 450,
                      ),
                      itemCount: properties.length + 1,
                      itemBuilder: (context, index) {
                        if (index == properties.length) {
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusM,
                              ),
                              side: BorderSide(
                                color: const Color(
                                  0xFF6B4CE6,
                                ).withAlpha((0.3 * 255).toInt()),
                                width: 2,
                                strokeAlign: BorderSide.strokeAlignInside,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _navigateToAddProperty(context),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusM,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF6B4CE6),
                                          Color(0xFF4A90E2),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add_business,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Dodaj Novi Objekt',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6B4CE6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final property = properties[index];
                        return PropertyCardOwner(
                          property: property,
                          onTap: () =>
                              _navigateToUnitsManagement(context, property.id),
                          onEdit: () =>
                              _navigateToEditProperty(context, property),
                          onDelete: () =>
                              _confirmDelete(context, ref, property.id),
                          onTogglePublished: (isActive) =>
                              _togglePublished(ref, property.id, isActive),
                        );
                      },
                    );
                  },
                ),
              );
            },
            loading: () => SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6B4CE6), Color(0xFF4A90E2)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Učitavanje...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            error: (error, stack) => SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceM),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withAlpha((0.1 * 255).toInt()),
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
                      const Text(
                        'Greška pri učitavanju',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                      Text(
                        '$error',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface
                              .withAlpha((0.7 * 255).toInt()),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.spaceL),
                      GradientButton(
                        text: 'Pokušaj ponovo',
                        onPressed: () =>
                            ref.invalidate(ownerPropertiesProvider),
                        icon: Icons.refresh,
                        height: 48,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddProperty(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PropertyFormScreen()));
  }

  void _navigateToEditProperty(BuildContext context, property) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PropertyFormScreen(property: property)),
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
      await ref
          .read(ownerPropertiesRepositoryProvider)
          .updateProperty(propertyId: propertyId, isActive: isActive);
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Obriši nekretninu'),
        content: const Text(
          'Jeste li sigurni da želite obrisati ovu nekretninu? '
          'Ova akcija se ne može poništiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
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
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            'Nekretnina uspješno obrisana',
          );
        }
      } catch (e) {
        if (context.mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: 'Greška pri brisanju nekretnine',
          );
        }
      }
    }
  }
}

/// Empty properties state - ENHANCED with better UX
class _EmptyPropertiesState extends StatelessWidget {
  const _EmptyPropertiesState({required this.onAddProperty});

  final VoidCallback onAddProperty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Enhanced icon with gradient background circle
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6B4CE6).withAlpha((0.1 * 255).toInt()),
                      const Color(0xFF4A90E2).withAlpha((0.1 * 255).toInt()),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.villa_outlined,
                  size: 80,
                  color: Color(0xFF6B4CE6),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Main title
              Text(
                'Nemate dodanih nekretnina',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceS),

              // Description
              Text(
                'Dodajte prvu nekretninu i počnite primati rezervacije od gostiju',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.6 * 255).toInt(),
                  ),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              const SizedBox(height: AppDimensions.spaceS),

              // Steps hint with gradient
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceS),
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceL,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6B4CE6).withAlpha((0.05 * 255).toInt()),
                      const Color(0xFF4A90E2).withAlpha((0.05 * 255).toInt()),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(
                    color: const Color(
                      0xFF6B4CE6,
                    ).withAlpha((0.3 * 255).toInt()),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Color(0xFF6B4CE6),
                    ),
                    SizedBox(width: AppDimensions.spaceXS),
                    Flexible(
                      child: Text(
                        'Dodajte detalje nekretnine, jedinice i cijene',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B4CE6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXL),

              // Modern gradient button
              GradientButton(
                text: 'Dodaj Prvu Nekretninu',
                onPressed: onAddProperty,
                icon: Icons.add_business,
                height: 56,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
