import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/utils/timestamp_converter.dart';

part 'unit_model.freezed.dart';
part 'unit_model.g.dart';

/// Unit model representing a bookable unit within a property
@freezed
class UnitModel with _$UnitModel {
  const factory UnitModel({
    /// Unit ID (UUID)
    required String id,

    /// Parent property ID
    @JsonKey(name: 'property_id') required String propertyId,

    /// Owner user ID (for Firestore security rules)
    /// Made nullable for backwards compatibility with legacy units
    @JsonKey(name: 'owner_id') String? ownerId,

    /// Unit name/title (e.g., "Apartment A1", "Studio 2")
    required String name,

    /// URL-friendly slug (e.g., "apartment-a1")
    String? slug,

    /// Unit description
    String? description,

    /// Price per night in EUR (base price for weekdays)
    @JsonKey(name: 'base_price') required double pricePerNight,

    /// Weekend base price in EUR (optional, for Fri-Sat nights by default)
    @JsonKey(name: 'weekend_base_price') double? weekendBasePrice,

    /// Days considered as weekend (1=Mon...7=Sun, default: [5,6] = Fri-Sat nights)
    @JsonKey(name: 'weekend_days') List<int>? weekendDays,

    /// Currency code (default: EUR)
    @Default('EUR') String? currency,

    /// Maximum number of guests
    @JsonKey(name: 'max_guests') required int maxGuests,

    /// Number of bedrooms
    @Default(1) int bedrooms,

    /// Number of bathrooms
    @Default(1) int bathrooms,

    /// Floor area in square meters
    @JsonKey(name: 'area_sqm') double? areaSqm,

    /// List of unit-specific image URLs
    @Default([]) List<String> images,

    /// Is unit available for booking
    @JsonKey(name: 'is_available') @Default(true) bool isAvailable,

    /// Minimum stay in nights
    @JsonKey(name: 'min_stay_nights') @Default(1) int minStayNights,

    /// Maximum stay in nights (null = unlimited)
    @JsonKey(name: 'max_stay_nights') int? maxStayNights,

    /// Sort order for display (lower = first, null = end of list)
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,

    /// Unit creation timestamp
    @JsonKey(name: 'created_at')
    @TimestampConverter()
    required DateTime createdAt,

    /// Last update timestamp
    @JsonKey(name: 'updated_at')
    @NullableTimestampConverter()
    DateTime? updatedAt,

    /// Soft delete timestamp
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  }) = _UnitModel;

  const UnitModel._();

  /// Create from JSON
  factory UnitModel.fromJson(Map<String, dynamic> json) =>
      _$UnitModelFromJson(json);

  /// Get formatted price (e.g., "€120")
  String get formattedPrice => '€${pricePerNight.toStringAsFixed(0)}';

  /// Get price with per night label
  String get pricePerNightLabel => '$formattedPrice/night';

  /// Calculate total price for number of nights
  double calculateTotalPrice(int nights) {
    return pricePerNight * nights;
  }

  /// Get formatted total price for nights
  String getFormattedTotalPrice(int nights) {
    final total = calculateTotalPrice(nights);
    return '€${total.toStringAsFixed(0)}';
  }

  /// Check if unit can accommodate guests
  bool canAccommodate(int guestCount) => guestCount <= maxGuests;

  /// Check if stay duration meets minimum requirement
  bool meetsMinimumStay(int nights) => nights >= minStayNights;

  /// Check if booking is valid for this unit
  bool isBookingValid(int nights, int guestCount) {
    return isAvailable &&
        meetsMinimumStay(nights) &&
        canAccommodate(guestCount);
  }

  /// Get guest capacity label
  String get guestCapacityLabel {
    return maxGuests == 1 ? '1 guest' : '$maxGuests guests';
  }

  /// Get bedroom label
  String get bedroomLabel {
    return bedrooms == 1 ? '1 bedroom' : '$bedrooms bedrooms';
  }

  /// Get bathroom label
  String get bathroomLabel {
    return bathrooms == 1 ? '1 bathroom' : '$bathrooms bathrooms';
  }

  /// Get unit summary (e.g., "2 bedrooms • 1 bathroom • 4 guests")
  String get summary {
    return '$bedroomLabel • $bathroomLabel • $guestCapacityLabel';
  }

  /// Check if unit has images
  bool get hasImages => images.isNotEmpty;

  /// Get primary image
  String? get primaryImage => images.isNotEmpty ? images.first : null;
}
