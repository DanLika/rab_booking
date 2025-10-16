import 'package:json_annotation/json_annotation.dart';

/// User roles in the system
@JsonEnum(valueField: 'value')
enum UserRole {
  /// Guest user - can browse and book properties
  guest('guest'),

  /// Property owner - can list and manage properties
  owner('owner'),

  /// Admin user - full system access
  admin('admin');

  const UserRole(this.value);

  final String value;

  /// Get display name for the role
  String get displayName {
    switch (this) {
      case UserRole.guest:
        return 'Guest';
      case UserRole.owner:
        return 'Property Owner';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  /// Check if user has admin privileges
  bool get isAdmin => this == UserRole.admin;

  /// Check if user can manage properties
  bool get canManageProperties => this == UserRole.owner || this == UserRole.admin;

  /// Parse from string value
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.guest,
    );
  }
}

/// Booking status lifecycle
@JsonEnum(valueField: 'value')
enum BookingStatus {
  /// Booking created, awaiting payment confirmation
  pending('pending'),

  /// Payment received, booking confirmed
  confirmed('confirmed'),

  /// Booking cancelled by guest or owner
  cancelled('cancelled'),

  /// Stay completed, booking archived
  completed('completed');

  const BookingStatus(this.value);

  final String value;

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending Payment';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }

  /// Check if booking can be cancelled
  bool get canBeCancelled => this == BookingStatus.pending || this == BookingStatus.confirmed;

  /// Check if booking is active
  bool get isActive => this == BookingStatus.confirmed;

  /// Check if booking is finalized (cannot be modified)
  bool get isFinalized => this == BookingStatus.cancelled || this == BookingStatus.completed;

  /// Parse from string value
  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

/// Property amenities for filtering and display
@JsonEnum(valueField: 'value')
enum PropertyAmenity {
  /// WiFi internet connection
  wifi('wifi'),

  /// Parking space available
  parking('parking'),

  /// Swimming pool
  pool('pool'),

  /// Air conditioning
  airConditioning('air_conditioning'),

  /// Heating system
  heating('heating'),

  /// Full kitchen
  kitchen('kitchen'),

  /// Washing machine
  washingMachine('washing_machine'),

  /// TV
  tv('tv'),

  /// Balcony or terrace
  balcony('balcony'),

  /// Sea view
  seaView('sea_view'),

  /// Pet friendly
  petFriendly('pet_friendly'),

  /// BBQ grill
  bbq('bbq'),

  /// Outdoor furniture
  outdoorFurniture('outdoor_furniture'),

  /// Beach access
  beachAccess('beach_access'),

  /// Fireplace
  fireplace('fireplace'),

  /// Gym/fitness center
  gym('gym'),

  /// Hot tub/jacuzzi
  hotTub('hot_tub'),

  /// Sauna
  sauna('sauna'),

  /// Bicycle rental
  bicycleRental('bicycle_rental'),

  /// Boat mooring
  boatMooring('boat_mooring');

  const PropertyAmenity(this.value);

  final String value;

  /// Get display name for the amenity
  String get displayName {
    switch (this) {
      case PropertyAmenity.wifi:
        return 'WiFi';
      case PropertyAmenity.parking:
        return 'Parking';
      case PropertyAmenity.pool:
        return 'Swimming Pool';
      case PropertyAmenity.airConditioning:
        return 'Air Conditioning';
      case PropertyAmenity.heating:
        return 'Heating';
      case PropertyAmenity.kitchen:
        return 'Kitchen';
      case PropertyAmenity.washingMachine:
        return 'Washing Machine';
      case PropertyAmenity.tv:
        return 'TV';
      case PropertyAmenity.balcony:
        return 'Balcony/Terrace';
      case PropertyAmenity.seaView:
        return 'Sea View';
      case PropertyAmenity.petFriendly:
        return 'Pet Friendly';
      case PropertyAmenity.bbq:
        return 'BBQ Grill';
      case PropertyAmenity.outdoorFurniture:
        return 'Outdoor Furniture';
      case PropertyAmenity.beachAccess:
        return 'Beach Access';
      case PropertyAmenity.fireplace:
        return 'Fireplace';
      case PropertyAmenity.gym:
        return 'Gym';
      case PropertyAmenity.hotTub:
        return 'Hot Tub';
      case PropertyAmenity.sauna:
        return 'Sauna';
      case PropertyAmenity.bicycleRental:
        return 'Bicycle Rental';
      case PropertyAmenity.boatMooring:
        return 'Boat Mooring';
    }
  }

  /// Get icon name for the amenity (Material Icons)
  String get iconName {
    switch (this) {
      case PropertyAmenity.wifi:
        return 'wifi';
      case PropertyAmenity.parking:
        return 'local_parking';
      case PropertyAmenity.pool:
        return 'pool';
      case PropertyAmenity.airConditioning:
        return 'ac_unit';
      case PropertyAmenity.heating:
        return 'whatshot';
      case PropertyAmenity.kitchen:
        return 'kitchen';
      case PropertyAmenity.washingMachine:
        return 'local_laundry_service';
      case PropertyAmenity.tv:
        return 'tv';
      case PropertyAmenity.balcony:
        return 'balcony';
      case PropertyAmenity.seaView:
        return 'beach_access';
      case PropertyAmenity.petFriendly:
        return 'pets';
      case PropertyAmenity.bbq:
        return 'outdoor_grill';
      case PropertyAmenity.outdoorFurniture:
        return 'deck';
      case PropertyAmenity.beachAccess:
        return 'beach_access';
      case PropertyAmenity.fireplace:
        return 'fireplace';
      case PropertyAmenity.gym:
        return 'fitness_center';
      case PropertyAmenity.hotTub:
        return 'hot_tub';
      case PropertyAmenity.sauna:
        return 'spa';
      case PropertyAmenity.bicycleRental:
        return 'pedal_bike';
      case PropertyAmenity.boatMooring:
        return 'sailing';
    }
  }

  /// Check if amenity is essential (commonly expected)
  bool get isEssential {
    return this == PropertyAmenity.wifi ||
        this == PropertyAmenity.parking ||
        this == PropertyAmenity.airConditioning ||
        this == PropertyAmenity.kitchen;
  }

  /// Parse from string value
  static PropertyAmenity fromString(String value) {
    return PropertyAmenity.values.firstWhere(
      (amenity) => amenity.value == value,
      orElse: () => PropertyAmenity.wifi,
    );
  }

  /// Parse list from string list
  static List<PropertyAmenity> fromStringList(List<String> values) {
    return values.map((v) => fromString(v)).toList();
  }

  /// Convert list to string list
  static List<String> toStringList(List<PropertyAmenity> amenities) {
    return amenities.map((a) => a.value).toList();
  }
}
