import 'package:freezed_annotation/freezed_annotation.dart';

part 'additional_service_model.freezed.dart';
part 'additional_service_model.g.dart';

/// Additional Service model (parking, breakfast, etc.)
@freezed
class AdditionalServiceModel with _$AdditionalServiceModel {
  const factory AdditionalServiceModel({
    /// Service ID (UUID)
    required String id,

    /// Owner ID (nullable for backwards compatibility with legacy services)
    @JsonKey(name: 'owner_id') String? ownerId,

    /// Service name
    required String name,

    /// Service description
    String? description,

    /// Service name (English)
    @JsonKey(name: 'name_en') String? nameEn,

    /// Service description (English)
    @JsonKey(name: 'description_en') String? descriptionEn,

    /// Service type
    @JsonKey(name: 'service_type') required String serviceType,

    /// Price
    required double price,

    /// Currency (default: EUR)
    @Default('EUR') String currency,

    /// Pricing unit (per_booking, per_night, per_person, per_item)
    @JsonKey(name: 'pricing_unit') @Default('per_booking') String pricingUnit,

    /// Is service available
    @JsonKey(name: 'is_available') @Default(true) bool isAvailable,

    /// Maximum quantity (null = unlimited)
    @JsonKey(name: 'max_quantity') int? maxQuantity,

    /// Unit ID (null = available for all units)
    @JsonKey(name: 'unit_id') String? unitId,

    /// Property ID (null = available for all properties)
    @JsonKey(name: 'property_id') String? propertyId,

    /// Sort order for display
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,

    /// Icon name (Material icon)
    @JsonKey(name: 'icon_name') String? iconName,

    /// Image URL
    @JsonKey(name: 'image_url') String? imageUrl,

    /// Created at timestamp
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Updated at timestamp
    @JsonKey(name: 'updated_at') DateTime? updatedAt,

    /// Soft delete timestamp
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  }) = _AdditionalServiceModel;

  const AdditionalServiceModel._();

  /// Create from JSON
  factory AdditionalServiceModel.fromJson(Map<String, dynamic> json) =>
      _$AdditionalServiceModelFromJson(json);

  /// Get service type display name
  String get serviceTypeDisplayName {
    switch (serviceType) {
      case 'parking':
        return 'Parking';
      case 'breakfast':
        return 'Breakfast';
      case 'late_checkin':
        return 'Late Check-in';
      case 'early_checkout':
        return 'Early Check-out';
      case 'cleaning':
        return 'Cleaning';
      case 'baby_cot':
        return 'Baby Cot';
      case 'pet_fee':
        return 'Pet Fee';
      case 'transfer':
        return 'Airport Transfer';
      default:
        return 'Other';
    }
  }

  /// Get pricing unit display name
  String get pricingUnitDisplayName {
    switch (pricingUnit) {
      case 'per_booking':
        return 'per booking';
      case 'per_night':
        return 'per night';
      case 'per_person':
        return 'per person';
      case 'per_item':
        return 'per item';
      default:
        return '';
    }
  }

  /// Get formatted price
  String get formattedPrice {
    return '€${price.toStringAsFixed(2)} $pricingUnitDisplayName';
  }

  /// Calculate total price for booking
  double calculateTotalPrice({
    int quantity = 1,
    int nights = 1,
    int guests = 1,
  }) {
    double multiplier = 1;

    switch (pricingUnit) {
      case 'per_booking':
        multiplier = 1;
        break;
      case 'per_night':
        multiplier = nights.toDouble();
        break;
      case 'per_person':
        multiplier = guests.toDouble();
        break;
      case 'per_item':
        multiplier = quantity.toDouble();
        break;
    }

    return price * multiplier * quantity;
  }

  /// Get formatted total price for booking
  String getFormattedTotalPrice({
    int quantity = 1,
    int nights = 1,
    int guests = 1,
  }) {
    final total = calculateTotalPrice(
      quantity: quantity,
      nights: nights,
      guests: guests,
    );
    return '€${total.toStringAsFixed(2)}';
  }

  /// Check if quantity is available
  bool isQuantityAvailable(int quantity) {
    if (maxQuantity == null) return true; // Unlimited
    return quantity <= maxQuantity!;
  }

  /// Get default icon name if not set
  String get defaultIconName {
    if (iconName != null && iconName!.isNotEmpty) return iconName!;

    switch (serviceType) {
      case 'parking':
        return 'local_parking';
      case 'breakfast':
        return 'restaurant';
      case 'late_checkin':
        return 'access_time';
      case 'early_checkout':
        return 'exit_to_app';
      case 'cleaning':
        return 'cleaning_services';
      case 'baby_cot':
        return 'child_care';
      case 'pet_fee':
        return 'pets';
      case 'transfer':
        return 'local_taxi';
      default:
        return 'add_circle';
    }
  }
}
