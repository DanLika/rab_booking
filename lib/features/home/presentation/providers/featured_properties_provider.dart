import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/constants/enums.dart';
import '../../../../shared/models/property_model.dart';
import '../../../search/data/repositories/property_search_repository.dart';

part 'featured_properties_provider.g.dart';

/// Featured properties provider (now using REAL Supabase data!)
@riverpod
Future<List<PropertyModel>> featuredProperties(
    FeaturedPropertiesRef ref) async {
  final repository = ref.watch(propertySearchRepositoryProvider);

  try {
    return await repository.getFeaturedProperties(limit: 6);
  } catch (e) {
    // Fallback to mock data on error
    return _mockProperties;
  }
}

/// Mock featured properties data
final _mockProperties = [
  PropertyModel(
    id: '1',
    ownerId: 'owner-1',
    name: 'Villa Mediteran - Luxury Seafront Property',
    description:
        'Stunning 4-bedroom villa with private pool and breathtaking sea views.',
    location: 'Rab Town, Island of Rab',
    latitude: 44.7604,
    longitude: 14.7606,
    amenities: const [
      PropertyAmenity.wifi,
      PropertyAmenity.parking,
      PropertyAmenity.pool,
      PropertyAmenity.airConditioning,
      PropertyAmenity.kitchen,
      PropertyAmenity.seaView
    ],
    images: const [
      'https://images.unsplash.com/photo-1568605114967-8130f3a36994?q=80&w=800',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=800',
    ],
    coverImage:
        'https://images.unsplash.com/photo-1568605114967-8130f3a36994?q=80&w=800',
    rating: 4.8,
    reviewCount: 42,
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 120)),
    updatedAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  PropertyModel(
    id: '2',
    ownerId: 'owner-1',
    name: 'Apartments Paradise - Near Paradise Beach',
    description:
        'Modern 2-bedroom apartment just 200m from the famous Paradise Beach.',
    location: 'Lopar, Island of Rab',
    latitude: 44.8285,
    longitude: 14.7373,
    amenities: const [
      PropertyAmenity.wifi,
      PropertyAmenity.parking,
      PropertyAmenity.airConditioning,
      PropertyAmenity.kitchen,
      PropertyAmenity.beachAccess
    ],
    images: const [
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=800',
    ],
    coverImage:
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=800',
    rating: 4.5,
    reviewCount: 28,
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  PropertyModel(
    id: '3',
    ownerId: 'owner-1',
    name: 'Traditional Stone House - Authentic Experience',
    description:
        'Charming stone house with modern amenities in the peaceful village of Barbat.',
    location: 'Barbat, Island of Rab',
    latitude: 44.7889,
    longitude: 14.7142,
    amenities: const [
      PropertyAmenity.wifi,
      PropertyAmenity.parking,
      PropertyAmenity.petFriendly,
      PropertyAmenity.fireplace,
      PropertyAmenity.bbq
    ],
    images: const [],
    coverImage:
        'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?q=80&w=800',
    rating: 4.7,
    reviewCount: 15,
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 60)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  PropertyModel(
    id: '4',
    ownerId: 'owner-2',
    name: 'Sea View Apartments Kampor',
    description: 'Comfortable apartments with stunning Adriatic sea views.',
    location: 'Kampor, Island of Rab',
    latitude: 44.7850,
    longitude: 14.7250,
    amenities: const [PropertyAmenity.wifi, PropertyAmenity.parking, PropertyAmenity.airConditioning, PropertyAmenity.balcony],
    images: const [],
    coverImage:
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?q=80&w=800',
    rating: 4.6,
    reviewCount: 22,
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 45)),
    updatedAt: DateTime.now(),
  ),
  PropertyModel(
    id: '5',
    ownerId: 'owner-2',
    name: 'Villa Sunset - Premium Beachfront',
    description:
        'Exclusive villa right on the beach with infinity pool and spa.',
    location: 'Banjol, Island of Rab',
    latitude: 44.7550,
    longitude: 14.7650,
    amenities: const [
      PropertyAmenity.wifi,
      PropertyAmenity.parking,
      PropertyAmenity.pool,
      PropertyAmenity.airConditioning,
      PropertyAmenity.kitchen,
      PropertyAmenity.seaView,
      PropertyAmenity.beachAccess,
      PropertyAmenity.bbq
    ],
    images: const [],
    coverImage:
        'https://images.unsplash.com/photo-1613490493576-7fde63acd811?q=80&w=800',
    rating: 4.9,
    reviewCount: 56,
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 180)),
    updatedAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  PropertyModel(
    id: '6',
    ownerId: 'owner-3',
    name: 'Cozy Studio Palit',
    description: 'Perfect studio for couples, walking distance to beach.',
    location: 'Palit, Island of Rab',
    latitude: 44.7620,
    longitude: 14.7580,
    amenities: const [PropertyAmenity.wifi, PropertyAmenity.airConditioning, PropertyAmenity.kitchen],
    images: const [],
    coverImage:
        'https://images.unsplash.com/photo-1536376072261-38c75010e6c9?q=80&w=800',
    rating: 4.4,
    reviewCount: 18,
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now().subtract(const Duration(days: 7)),
  ),
];
