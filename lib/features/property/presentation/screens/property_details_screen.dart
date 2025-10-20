import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../providers/property_details_provider.dart';
import '../widgets/image_gallery_widget.dart';
import '../widgets/property_info_section.dart';
import '../widgets/units_section.dart';
import '../widgets/location_map.dart';
import '../widgets/host_info.dart';
import '../widgets/reviews_section.dart';
import '../widgets/booking_widget.dart';
import '../widgets/similar_properties_section.dart';
import '../widgets/amenities_section.dart';
import '../../domain/models/property_unit.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../search/presentation/providers/recently_viewed_provider.dart';
import '../../../../shared/widgets/widgets.dart';

/// Property details screen with responsive layout
class PropertyDetailsScreen extends ConsumerStatefulWidget {
  const PropertyDetailsScreen({
    required this.propertyId,
    super.key,
  });

  final String propertyId;

  @override
  ConsumerState<PropertyDetailsScreen> createState() =>
      _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState
    extends ConsumerState<PropertyDetailsScreen> {
  PropertyUnit? _selectedUnit;
  dynamic _currentProperty;

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyDetailsProvider(widget.propertyId));
    final unitsAsync = ref.watch(propertyUnitsProvider(widget.propertyId));

    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1200;

    return Scaffold(
      body: propertyAsync.when(
        data: (property) {
          if (property == null) {
            return _buildNotFoundState();
          }

          // Store property for FAB access and track view
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_currentProperty != property) {
              setState(() => _currentProperty = property);

              // Track this property view in recently viewed
              ref
                  .read(recentlyViewedNotifierProvider.notifier)
                  .addView(widget.propertyId);
            }
          });

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: true,
                title: Text(
                  property.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () async {
                      final propertyUrl = 'https://rabbooking.com/property/${widget.propertyId}';
                      final shareText = '${property.name}\n${property.location}\n\n$propertyUrl';

                      await Share.share(
                        shareText,
                        subject: property.name,
                      );
                    },
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final favoritesNotifier = ref.watch(favoritesNotifierProvider);
                      final isFavorite = favoritesNotifier.maybeWhen(
                        data: (favorites) => favorites.contains(widget.propertyId),
                        orElse: () => false,
                      );

                      return IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: () async {
                          try {
                            await ref
                                .read(favoritesNotifierProvider.notifier)
                                .toggleFavorite(widget.propertyId);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Greška: $e')),
                              );
                            }
                          }
                        },
                        tooltip: isFavorite ? 'Ukloni iz omiljenih' : 'Dodaj u omiljene',
                      );
                    },
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Gallery
                    ImageGalleryWidget(
                      images: property.images,
                      coverImage: property.coverImage,
                    ),

                    // Main Content
                    isMobile || isTablet
                        ? _buildMobileLayout(property, unitsAsync)
                        : _buildDesktopLayout(property, unitsAsync),

                    // Footer
                    const AppFooter(),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),

      // Floating Action Button (mobile only)
      floatingActionButton: isMobile && _selectedUnit != null && _currentProperty != null
          ? FloatingActionButton.extended(
              onPressed: () => _showBookingBottomSheet(context, _currentProperty),
              icon: const Icon(Icons.calendar_today),
              label: Text(
                  'Rezerviraj - €${_selectedUnit!.pricePerNight.toStringAsFixed(0)}'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMobileLayout(
    dynamic property,
    AsyncValue<List<PropertyUnit>> unitsAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Info
          unitsAsync.when(
            data: (units) => PropertyInfoSection(
              property: property,
              units: units,
            ),
            loading: () => PropertyInfoSection(property: property),
            error: (_, stackTrace) => PropertyInfoSection(property: property),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // Amenities
          if (property.amenities.isNotEmpty) ...[
            PremiumAmenitiesSection(
              amenities: property.amenities,
              title: 'Sadržaji',
              displayStyle: AmenitiesDisplayStyle.grid,
              expandable: true,
              initialDisplayCount: 8,
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
          ],

          // Units
          unitsAsync.when(
            data: (units) {
              if (units.isEmpty) return const SizedBox.shrink();

              // Auto-select first unit
              if (_selectedUnit == null && units.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() => _selectedUnit = units.first);
                });
              }

              return UnitsSection(
                units: units,
                onSelectUnit: (unit) {
                  setState(() => _selectedUnit = unit);
                  _showBookingBottomSheet(context, property);
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Greška: $error'),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // Reviews
          ReviewsSection(
            propertyId: property.id,
            propertyName: property.name,
            rating: property.rating,
            reviewCount: property.reviewCount,
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // Location
          LocationMap(
            latitude: property.latitude,
            longitude: property.longitude,
            location: property.location,
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // Host Info
          HostInfo(
            ownerId: property.ownerId,
            propertyId: property.id,
            propertyName: property.name,
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // Similar Properties
          SimilarPropertiesSection(propertyId: widget.propertyId),

          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    dynamic property,
    AsyncValue<List<PropertyUnit>> unitsAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column (Content) - 70%
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Info
                unitsAsync.when(
                  data: (units) => PropertyInfoSection(
                    property: property,
                    units: units,
                  ),
                  loading: () => PropertyInfoSection(property: property),
                  error: (_, stackTrace) => PropertyInfoSection(property: property),
                ),

                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 48),

                // Amenities
                if (property.amenities.isNotEmpty) ...[
                  PremiumAmenitiesSection(
                    amenities: property.amenities,
                    title: 'Sadržaji',
                    displayStyle: AmenitiesDisplayStyle.grid,
                    expandable: true,
                    initialDisplayCount: 12,
                  ),
                  const SizedBox(height: 48),
                  const Divider(),
                  const SizedBox(height: 48),
                ],

                // Units
                unitsAsync.when(
                  data: (units) {
                    if (units.isEmpty) return const SizedBox.shrink();

                    // Auto-select first unit
                    if (_selectedUnit == null && units.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() => _selectedUnit = units.first);
                      });
                    }

                    return UnitsSection(
                      units: units,
                      onSelectUnit: (unit) {
                        setState(() => _selectedUnit = unit);
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Greška: $error'),
                ),

                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 48),

                // Reviews
                ReviewsSection(
                  propertyId: property.id,
                  propertyName: property.name,
                  rating: property.rating,
                  reviewCount: property.reviewCount,
                ),

                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 48),

                // Location
                LocationMap(
                  latitude: property.latitude,
                  longitude: property.longitude,
                  location: property.location,
                ),

                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 48),

                // Host Info
                HostInfo(
                  ownerId: property.ownerId,
                  propertyId: property.id,
                  propertyName: property.name,
                ),

                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 48),

                // Similar Properties
                SimilarPropertiesSection(propertyId: widget.propertyId),
              ],
            ),
          ),

          const SizedBox(width: 80),

          // Right Column (Booking Widget) - 30%
          SizedBox(
            width: 380,
            child: unitsAsync.when(
              data: (units) {
                if (_selectedUnit == null || units.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildStickyBookingWidget(property);
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBookingWidget(dynamic property) {
    if (_selectedUnit == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        children: [
          BookingWidget(
            property: property,
            unit: _selectedUnit!,
          ),
        ],
      ),
    );
  }

  void _showBookingBottomSheet(BuildContext context, dynamic property) {
    if (_selectedUnit == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Booking Widget
              Expanded(
                child: SingleChildScrollView(
                  child: BookingWidget(
                    property: property,
                    unit: _selectedUnit!,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Smještaj nije pronađen',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ovaj smještaj možda više nije dostupan.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                if (context.canGoBack()) {
                  context.pop();
                } else {
                  context.go(Routes.home);
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Natrag'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Greška prilikom učitavanja',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(propertyDetailsProvider(widget.propertyId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}
