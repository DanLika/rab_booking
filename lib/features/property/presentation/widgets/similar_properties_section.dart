import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/widgets/property_card.dart';
import '../providers/similar_properties_provider.dart';

/// Similar properties section widget
class SimilarPropertiesSection extends ConsumerWidget {
  const SimilarPropertiesSection({
    required this.propertyId,
    super.key,
  });

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarPropertiesAsync = ref.watch(similarPropertiesProvider(propertyId));

    return similarPropertiesAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(), // Hide on error
      data: (properties) {
        // Don't show section if no similar properties found
        if (properties.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Slični smještaji',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Istražite druge opcije u istoj lokaciji',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.textColorSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Horizontal scrollable list of properties
              SizedBox(
                height: 320,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];

                    return Container(
                      width: 280,
                      margin: EdgeInsets.only(
                        right: index < properties.length - 1 ? 16 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to property details
                          context.go('/property/${property.id}');
                        },
                        child: PropertyCard(property: property),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
