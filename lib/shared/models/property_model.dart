import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/enums.dart';

part 'property_model.freezed.dart';
part 'property_model.g.dart';

/// Property model representing a vacation rental property
@freezed
class PropertyModel with _$PropertyModel {
  const factory PropertyModel({
    /// Property ID (UUID)
    required String id,

    /// Owner user ID
    @JsonKey(name: 'owner_id') required String ownerId,

    /// Property name/title
    required String name,

    /// Detailed description
    required String description,

    /// Property type (villa, apartment, studio, etc.)
    @JsonKey(name: 'property_type')
    @Default(PropertyType.apartment)
    PropertyType propertyType,

    /// Location (city, address, etc.)
    required String location,

    /// Street address
    String? address,

    /// Latitude coordinate
    double? latitude,

    /// Longitude coordinate
    double? longitude,

    /// List of amenities
    @Default([]) List<PropertyAmenity> amenities,

    /// List of image URLs
    @Default([]) List<String> images,

    /// Main cover image URL
    @JsonKey(name: 'cover_image') String? coverImage,

    /// Average rating (0-5)
    @Default(0.0) double rating,

    /// Number of reviews
    @JsonKey(name: 'review_count') @Default(0) int reviewCount,

    /// Number of units (apartments/rooms) in this property
    @JsonKey(name: 'units_count') @Default(0) int unitsCount,

    /// Property creation timestamp
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Last update timestamp
    @JsonKey(name: 'updated_at') DateTime? updatedAt,

    /// Is property active/published
    @JsonKey(name: 'is_active') @Default(true) bool isActive,

    /// Price per night in EUR
    @JsonKey(name: 'base_price') double? pricePerNight,

    /// Maximum number of guests
    @JsonKey(name: 'max_guests') int? maxGuests,

    /// Number of bedrooms
    int? bedrooms,

    /// Number of bathrooms
    int? bathrooms,
  }) = _PropertyModel;

  const PropertyModel._();

  /// Create from JSON
  factory PropertyModel.fromJson(Map<String, dynamic> json) =>
      _$PropertyModelFromJson(json);

  /// Get primary image (cover or first image)
  String? get primaryImage {
    if (coverImage != null && coverImage!.isNotEmpty) {
      return coverImage;
    }
    return images.isNotEmpty ? images.first : null;
  }

  /// Check if property has images
  bool get hasImages => images.isNotEmpty || coverImage != null;

  /// Check if property has location coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Get formatted rating (e.g., "4.5")
  String get formattedRating => rating.toStringAsFixed(1);

  /// Check if property has good rating (>= 4.0)
  bool get hasGoodRating => rating >= 4.0;

  /// Get amenity count
  int get amenityCount => amenities.length;

  /// Check if property has specific amenity
  bool hasAmenity(PropertyAmenity amenity) => amenities.contains(amenity);

  /// Get essential amenities
  List<PropertyAmenity> get essentialAmenities {
    return amenities.where((a) => a.isEssential).toList();
  }

  /// Get location display name (can be enhanced with parsing)
  String get locationDisplay => location;

  /// Get formatted price (e.g., "€120")
  String get formattedPrice {
    if (pricePerNight == null) return 'Cijena na upit';
    return '€${pricePerNight!.toStringAsFixed(0)}';
  }

  /// Get formatted price with "/noć" suffix
  String get formattedPricePerNight {
    if (pricePerNight == null) return 'Cijena na upit';
    return '€${pricePerNight!.toStringAsFixed(0)}/noć';
  }

  /// Check if property has complete info (for quick info display)
  bool get hasCompleteInfo => maxGuests != null && bedrooms != null && bathrooms != null;
}
