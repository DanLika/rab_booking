import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../../../../core/utils/responsive_breakpoints.dart';
import '../../../../core/utils/accessibility_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../providers/property_details_provider.dart';
import '../widgets/property_info_section.dart';
import '../widgets/units_section.dart';
import '../widgets/location_map.dart';
import '../widgets/host_info.dart';
import '../widgets/reviews_section.dart';
import '../widgets/similar_properties_section.dart';
import '../widgets/amenities_section.dart';
import '../../domain/models/property_unit.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../search/presentation/providers/recently_viewed_provider.dart';
import '../../../../shared/widgets/widgets.dart';

/// REDESIGNED Property Details Screen - Modern, Clean, Professional
/// Features:
/// - Hero image gallery with immersive view
/// - Sticky booking card (desktop/tablet)
/// - Persistent booking FAB (mobile)
/// - Modern card-based layout
/// - Smooth animations
/// - Prominent CTAs
class PropertyDetailsScreenRedesigned extends ConsumerStatefulWidget {
  const PropertyDetailsScreenRedesigned({
    required this.propertyId,
    super.key,
  });

  final String propertyId;

  @override
  ConsumerState<PropertyDetailsScreenRedesigned> createState() =>
      _PropertyDetailsScreenRedesignedState();
}

class _PropertyDetailsScreenRedesignedState
    extends ConsumerState<PropertyDetailsScreenRedesigned>
    with SingleTickerProviderStateMixin {
  PropertyUnit? _selectedUnit;
  dynamic _currentProperty;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  bool _showFAB = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    // Show FAB after scrolling past hero image
    if (_scrollController.offset > 400 && !_showFAB) {
      setState(() => _showFAB = true);
      _fabAnimationController.forward();
    } else if (_scrollController.offset <= 400 && _showFAB) {
      setState(() => _showFAB = false);
      _fabAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyDetailsProvider(widget.propertyId));
    final unitsAsync = ref.watch(propertyUnitsProvider(widget.propertyId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(propertyAsync),
      body: propertyAsync.when(
        data: (property) {
          if (property == null) {
            return _buildNotFoundState();
          }

          // Track view
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_currentProperty != property) {
              setState(() => _currentProperty = property);
              ref
                  .read(recentlyViewedNotifierProvider.notifier)
                  .addView(widget.propertyId);
            }
          });

          return _buildPropertyContent(property, unitsAsync);
        },
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
      floatingActionButton: _buildFloatingBookingButton(unitsAsync),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Modern glass-morphism app bar
  PreferredSizeWidget _buildModernAppBar(AsyncValue<dynamic> propertyAsync) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        // Share button
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.black87),
            onPressed: () async {
              final property = propertyAsync.value;
              if (property != null) {
                final url = 'https://rabbooking.com/property/${widget.propertyId}';
                await Share.share('${property.name}\n${property.location}\n\n$url');
              }
            },
          ),
        ),
        // Favorite button
        Consumer(
          builder: (context, ref, child) {
            final favoritesNotifier = ref.watch(favoritesNotifierProvider);
            final isFavorite = favoritesNotifier.maybeWhen(
              data: (favorites) => favorites.contains(widget.propertyId),
              orElse: () => false,
            );

            return Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.black87,
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
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPropertyContent(
    dynamic property,
    AsyncValue<List<PropertyUnit>> unitsAsync,
  ) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Hero Image Gallery
        _buildHeroImageGallery(property),

        // Main Content
        SliverToBoxAdapter(
          child: context.isDesktopDevice
              ? _buildDesktopLayout(property, unitsAsync)
              : _buildMobileLayout(property, unitsAsync),
        ),

        // Footer
        const SliverToBoxAdapter(child: AppFooter()),
      ],
    );
  }

  /// Immersive hero image gallery
  Widget _buildHeroImageGallery(dynamic property) {
    final images = property.images as List<dynamic>;
    final coverImage = property.coverImage as String?;
    final displayImages = [
      if (coverImage != null) coverImage,
      ...images.where((img) => img != coverImage),
    ].take(5).cast<String>().toList();

    return SliverToBoxAdapter(
      child: SizedBox(
        height: context.isMobileDevice ? 300 : 500,
        child: displayImages.isEmpty
            ? _buildPlaceholderImage()
            : Stack(
                children: [
                  // Main image
                  Positioned.fill(
                    child: Hero(
                      tag: 'property_${widget.propertyId}',
                      child: CachedNetworkImage(
                        imageUrl: displayImages.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SkeletonLoader(
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        errorWidget: (context, url, error) =>
                            _buildPlaceholderImage(),
                      ),
                    ),
                  ),

                  // Gradient overlay for text readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Image gallery button
                  if (displayImages.length > 1)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 4,
                        child: InkWell(
                          onTap: () => _showImageGallery(displayImages),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_library, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Pogledaj sve slike (${displayImages.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.surfaceVariantLight,
      child: const Center(
        child: Icon(
          Icons.villa_outlined,
          size: 80,
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  void _showImageGallery(List<String> images) {
    // TODO: Implement full-screen image gallery with swipe
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Image Gallery - ${images.length} photos'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    dynamic property,
    AsyncValue<List<PropertyUnit>> unitsAsync,
  ) {
    return Container(
      color: AppColors.backgroundLight,
      padding: EdgeInsets.all(context.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppDimensions.spaceM),

          // Property Header Card
          _buildPropertyHeaderCard(property, unitsAsync),

          SizedBox(height: AppDimensions.spaceM),

          // Quick Info Cards
          _buildQuickInfoCards(property),

          SizedBox(height: AppDimensions.spaceL),

          // Description Card
          _buildDescriptionCard(property),

          SizedBox(height: AppDimensions.spaceM),

          // Amenities Card
          if (property.amenities.isNotEmpty) ...[
            _buildAmenitiesCard(property),
            SizedBox(height: AppDimensions.spaceM),
          ],

          // Units/Rooms Card
          unitsAsync.when(
            data: (units) {
              if (units.isEmpty) return const SizedBox.shrink();

              // Auto-select first unit
              if (_selectedUnit == null && units.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() => _selectedUnit = units.first);
                });
              }

              return _buildUnitsCard(units, property);
            },
            loading: () => const SkeletonLoader(
              width: double.infinity,
              height: 200,
              borderRadius: 16,
            ),
            error: (error, stack) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Reviews Card
          _buildReviewsCard(property),

          const SizedBox(height: 24),

          // Location Card
          _buildLocationCard(property),

          const SizedBox(height: 24),

          // Host Card
          _buildHostCard(property),

          const SizedBox(height: 24),

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
    return Container(
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column - Main Content (65%)
          Expanded(
            flex: 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Header
                _buildPropertyHeaderCard(property, unitsAsync),

                const SizedBox(height: 32),

                // Quick Info
                _buildQuickInfoCards(property),

                const SizedBox(height: 32),

                // Description
                _buildDescriptionCard(property),

                const SizedBox(height: 32),

                // Amenities
                if (property.amenities.isNotEmpty) ...[
                  _buildAmenitiesCard(property),
                  const SizedBox(height: 32),
                ],

                // Reviews
                _buildReviewsCard(property),

                const SizedBox(height: 32),

                // Location
                _buildLocationCard(property),

                const SizedBox(height: 32),

                // Host
                _buildHostCard(property),

                const SizedBox(height: 32),

                // Similar Properties
                SimilarPropertiesSection(propertyId: widget.propertyId),
              ],
            ),
          ),

          const SizedBox(width: 40),

          // Right Column - Sticky Booking Card (35%)
          SizedBox(
            width: 420,
            child: unitsAsync.when(
              data: (units) {
                if (units.isEmpty) return const SizedBox.shrink();

                // Auto-select first unit
                if (_selectedUnit == null && units.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() => _selectedUnit = units.first);
                  });
                }

                return Column(
                  children: [
                    // Sticky Booking Card
                    _buildStickyBookingCard(property, units),

                    // Units list below
                    if (units.length > 1) ...[
                      const SizedBox(height: 24),
                      _buildUnitsCard(units, property),
                    ],
                  ],
                );
              },
              loading: () => const SkeletonLoader(
                width: double.infinity,
                height: 400,
                borderRadius: 20,
              ),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  /// Modern property header card
  Widget _buildPropertyHeaderCard(
    dynamic property,
    AsyncValue<List<PropertyUnit>> unitsAsync,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property name
            Semantics(
              header: true,
              child: Text(
                property.name,
                style: TextStyle(
                  fontSize: context.isMobileDevice ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                  height: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    property.location,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Rating & Reviews
            if (property.rating != null && property.rating > 0)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          property.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${property.reviewCount ?? 0} recenzija',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Quick info cards (guests, bedrooms, etc.)
  Widget _buildQuickInfoCards(dynamic property) {
    // This would use data from property or units
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.people_outline,
            label: 'Gostiju',
            value: '2-6', // From units
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.bed_outlined,
            label: 'Spavaće sobe',
            value: '2-3',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.bathroom_outlined,
            label: 'Kupatila',
            value: '2',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(dynamic property) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'O smještaju',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              property.description ?? 'Nema opisa.',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondaryLight,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesCard(dynamic property) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PremiumAmenitiesSection(
          amenities: property.amenities,
          title: 'Sadržaji',
          displayStyle: AmenitiesDisplayStyle.grid,
          expandable: true,
          initialDisplayCount: 8,
        ),
      ),
    );
  }

  Widget _buildUnitsCard(List<PropertyUnit> units, dynamic property) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: UnitsSection(
          units: units,
          onSelectUnit: (unit) {
            setState(() => _selectedUnit = unit);
            if (context.isMobileDevice) {
              _showBookingBottomSheet(property);
            }
          },
        ),
      ),
    );
  }

  Widget _buildReviewsCard(dynamic property) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ReviewsSection(
          propertyId: property.id,
          propertyName: property.name,
          rating: property.rating,
          reviewCount: property.reviewCount,
        ),
      ),
    );
  }

  Widget _buildLocationCard(dynamic property) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LocationMap(
          latitude: property.latitude,
          longitude: property.longitude,
          location: property.location,
        ),
      ),
    );
  }

  Widget _buildHostCard(dynamic property) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: HostInfo(
          ownerId: property.ownerId,
          propertyId: property.id,
          propertyName: property.name,
        ),
      ),
    );
  }

  /// PROMINENT Sticky Booking Card for Desktop
  Widget _buildStickyBookingCard(dynamic property, List<PropertyUnit> units) {
    if (_selectedUnit == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '€${_selectedUnit!.pricePerNight.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '/ noć',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // CTA Button
          Semantics(
            label: 'Rezerviraj smještaj sada',
            hint: 'Dvostruki dodir za početak procesa rezervacije',
            button: true,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startBooking(property),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 48), // AAA touch target
                ),
                child: const Text(
                  'Rezerviraj Sada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Secondary info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriceDetail('${_selectedUnit!.pricePerNight.toStringAsFixed(0)}€ × 1 noć', '${_selectedUnit!.pricePerNight.toStringAsFixed(0)}€'),
                const SizedBox(height: 8),
                _buildPriceDetail('Naknada za čišćenje', '50€'),
                const SizedBox(height: 8),
                _buildPriceDetail('Naknada za uslugu', '${(_selectedUnit!.pricePerNight * 0.1).toStringAsFixed(0)}€'),
                const Divider(height: 24),
                _buildPriceDetail(
                  'Ukupno',
                  '${(_selectedUnit!.pricePerNight * 1.1 + 50).toStringAsFixed(0)}€',
                  isBold: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Disclaimer
          const Text(
            'Nećete biti naplaćeni još uvijek',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDetail(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondaryLight,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textPrimaryLight,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Floating Action Button for Mobile - ALWAYS VISIBLE
  Widget? _buildFloatingBookingButton(AsyncValue<List<PropertyUnit>> unitsAsync) {
    if (!context.isMobileDevice || _selectedUnit == null) {
      return null;
    }

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOut,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width - 32,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showBookingBottomSheet(_currentProperty),
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Rezerviraj',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '€${_selectedUnit!.pricePerNight.toStringAsFixed(0)}/noć',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startBooking(dynamic property) {
    if (_selectedUnit == null) return;

    // Navigate directly to booking screen
    context.push(
      '/booking/${_selectedUnit!.id}',
      extra: {
        'property': property,
        'unit': _selectedUnit,
      },
    );
  }

  void _showBookingBottomSheet(dynamic property) {
    if (_selectedUnit == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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

              // Booking content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Odaberite datume',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Price summary
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cijena po noći',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              '€${_selectedUnit!.pricePerNight.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _startBooking(property);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Nastavi na rezervaciju',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Hero skeleton
              SizedBox(
                height: context.isMobileDevice ? 300 : 500,
                child: const SkeletonLoader(width: double.infinity),
              ),

              // Content skeleton
              Padding(
                padding: EdgeInsets.all(context.horizontalPadding),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    const SkeletonLoader(width: double.infinity, height: 120),
                    const SizedBox(height: 24),
                    Row(
                      children: List.generate(
                        3,
                        (i) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
                            child: const SkeletonLoader(
                              width: double.infinity,
                              height: 100,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
            const Text(
              'Smještaj nije pronađen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.pop(),
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
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              'Greška: $error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () =>
                  ref.invalidate(propertyDetailsProvider(widget.propertyId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}
