import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_details_provider.dart';
import '../widgets/image_gallery_widget.dart';
import '../widgets/property_info_section.dart';
import '../widgets/units_section.dart';
import '../widgets/booking_widget.dart';
import '../widgets/reviews_section.dart';
import '../widgets/location_map.dart';
import '../widgets/host_info.dart';
import '../../domain/models/property_unit.dart';

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
                    onPressed: () {
                      // TODO: Implement share
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      // TODO: Implement favorite
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
      floatingActionButton: isMobile && _selectedUnit != null
          ? FloatingActionButton.extended(
              onPressed: () => _showBookingBottomSheet(context),
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
          PropertyInfoSection(property: property),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

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
                  _showBookingBottomSheet(context);
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
          const HostInfo(),

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
                PropertyInfoSection(property: property),

                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 48),

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
                const HostInfo(),
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
                return _buildStickyBookingWidget();
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBookingWidget() {
    if (_selectedUnit == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        children: [
          BookingWidget(unit: _selectedUnit!),
        ],
      ),
    );
  }

  void _showBookingBottomSheet(BuildContext context) {
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
                  child: BookingWidget(unit: _selectedUnit!),
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
              onPressed: () => Navigator.of(context).pop(),
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
