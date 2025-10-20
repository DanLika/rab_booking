import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/property_model.dart';
import '../../data/repositories/similar_properties_repository.dart';
import './property_details_provider.dart';

part 'similar_properties_provider.g.dart';

/// Provider for similar properties based on current property
@riverpod
Future<List<PropertyModel>> similarProperties(
  Ref ref,
  String propertyId,
) async {
  // Get current property details
  final property = await ref.watch(propertyDetailsProvider(propertyId).future);

  if (property == null) {
    return [];
  }

  // Get units to determine price
  final units = await ref.watch(propertyUnitsProvider(propertyId).future);

  if (units.isEmpty) {
    return [];
  }

  // Find minimum price from units
  final minPrice = units
      .map((u) => u.pricePerNight)
      .reduce((a, b) => a < b ? a : b);

  // Fetch similar properties
  final repository = ref.watch(similarPropertiesRepositoryProvider);

  return repository.getSimilarPropertiesWithFallback(
    propertyId: propertyId,
    location: property.location,
    propertyType: property.propertyType.name, // Convert enum to string
    basePrice: minPrice,
    limit: 6,
  );
}
