import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/models/property_model.dart';

/// Map view widget for displaying properties on OpenStreetMap
class MapViewWidget extends StatefulWidget {
  const MapViewWidget({
    required this.properties,
    this.onPropertyTap,
    this.initialCenter,
    this.initialZoom = 13.0,
    super.key,
  });

  final List<PropertyModel> properties;
  final Function(PropertyModel)? onPropertyTap;
  final LatLng? initialCenter;
  final double initialZoom;

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  final MapController _mapController = MapController();
  PropertyModel? _selectedProperty;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Get center point from properties with coordinates
  LatLng get _center {
    if (widget.initialCenter != null) {
      return widget.initialCenter!;
    }

    // Filter properties with coordinates
    final propertiesWithCoords = widget.properties
        .where((p) => p.hasCoordinates)
        .toList();

    if (propertiesWithCoords.isEmpty) {
      // Default to island Rab, Croatia
      return const LatLng(44.7598, 14.7603);
    }

    // Calculate center from all properties
    double avgLat = 0;
    double avgLng = 0;

    for (final property in propertiesWithCoords) {
      avgLat += property.latitude!;
      avgLng += property.longitude!;
    }

    avgLat /= propertiesWithCoords.length;
    avgLng /= propertiesWithCoords.length;

    return LatLng(avgLat, avgLng);
  }

  /// Build marker for a property
  Marker _buildPropertyMarker(PropertyModel property) {
    final isSelected = _selectedProperty?.id == property.id;

    return Marker(
      point: LatLng(property.latitude!, property.longitude!),
      width: isSelected ? 80 : 60,
      height: isSelected ? 80 : 60,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedProperty = property;
          });

          // Move map to marker
          _mapController.move(
            LatLng(property.latitude!, property.longitude!),
            _mapController.camera.zoom,
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Marker pin
            Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home,
                      color: Colors.white,
                      size: isSelected ? 24 : 20,
                    ),
                    if (isSelected)
                      Text(
                        '€${property.pricePerNight?.toInt() ?? 0}',
                        style: AppTypography.small.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build property info card (shown when marker is tapped)
  Widget _buildPropertyInfoCard() {
    if (_selectedProperty == null) return const SizedBox.shrink();

    final property = _selectedProperty!;

    return Positioned(
      bottom: AppDimensions.spaceL,
      left: AppDimensions.spaceM,
      right: AppDimensions.spaceM,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: InkWell(
          onTap: () {
            if (widget.onPropertyTap != null) {
              widget.onPropertyTap!(property);
            } else {
              context.push('/property/${property.id}');
            }
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property image
                if (property.coverImage != null || property.images.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    child: Image.network(
                      property.coverImage ?? property.images.first,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: AppColors.surfaceLight,
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),

                const SizedBox(width: AppDimensions.spaceM),

                // Property info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.spaceXS),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: AppDimensions.spaceXXS),
                          Expanded(
                            child: Text(
                              property.location,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceXS),
                      Row(
                        children: [
                          if (property.rating > 0) ...[
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: AppDimensions.spaceXXS),
                            Text(
                              property.rating.toStringAsFixed(1),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceS),
                          ],
                          Text(
                            '€${property.pricePerNight?.toInt() ?? 0}/night',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close button
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedProperty = null;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter properties with coordinates
    final propertiesWithCoords = widget.properties
        .where((p) => p.hasCoordinates)
        .toList();

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: widget.initialZoom,
            minZoom: 8.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // OpenStreetMap tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.rabbooking.app',
              tileProvider: NetworkTileProvider(),
            ),

            // Property markers
            if (propertiesWithCoords.isNotEmpty)
              MarkerLayer(
                markers: propertiesWithCoords
                    .map((property) => _buildPropertyMarker(property))
                    .toList(),
              ),
          ],
        ),

        // Map controls (top right)
        Positioned(
          top: AppDimensions.spaceM,
          right: AppDimensions.spaceM,
          child: Column(
            children: [
              // Zoom in
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                onPressed: () {
                  final zoom = _mapController.camera.zoom + 1;
                  _mapController.move(_mapController.camera.center, zoom);
                },
                backgroundColor: Colors.white,
                child: Icon(Icons.add, color: Colors.grey[800]),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              // Zoom out
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                onPressed: () {
                  final zoom = _mapController.camera.zoom - 1;
                  _mapController.move(_mapController.camera.center, zoom);
                },
                backgroundColor: Colors.white,
                child: Icon(Icons.remove, color: Colors.grey[800]),
              ),
              const SizedBox(height: AppDimensions.spaceS),
              // Center on properties
              FloatingActionButton.small(
                heroTag: 'center',
                onPressed: () {
                  _mapController.move(_center, widget.initialZoom);
                },
                backgroundColor: Colors.white,
                child: Icon(Icons.my_location, color: Colors.grey[800]),
              ),
            ],
          ),
        ),

        // Property info card (bottom)
        _buildPropertyInfoCard(),

        // No properties overlay
        if (propertiesWithCoords.isEmpty)
          Center(
            child: Card(
              margin: const EdgeInsets.all(AppDimensions.spaceXL),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_off,
                      size: 64,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    Text(
                      'No properties with location data',
                      style: AppTypography.h3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    Text(
                      'Properties need latitude and longitude coordinates to be displayed on the map',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
