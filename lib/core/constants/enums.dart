import 'package:flutter/material.dart';
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
    return UserRole.values.firstWhere((role) => role.value == value, orElse: () => UserRole.guest);
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
  boatMooring('boat_mooring'),

  /// Restaurant on-site
  restaurant('restaurant');

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
      case PropertyAmenity.restaurant:
        return 'Restaurant';
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
      case PropertyAmenity.restaurant:
        return 'restaurant';
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
    return PropertyAmenity.values.firstWhere((amenity) => amenity.value == value, orElse: () => PropertyAmenity.wifi);
  }

  /// Parse list from string list
  static List<PropertyAmenity> fromStringList(List<String> values) {
    return values.map(fromString).toList();
  }

  /// Convert list to string list
  static List<String> toStringList(List<PropertyAmenity> amenities) {
    return amenities.map((a) => a.value).toList();
  }
}

/// Property types for classification
@JsonEnum(valueField: 'value')
enum PropertyType {
  /// Villa - standalone house with luxury amenities
  villa('villa'),

  /// Apartment - unit within a building
  apartment('apartment'),

  /// Studio - compact living space
  studio('studio'),

  /// House - traditional family home
  house('house'),

  /// Room - single room rental
  room('room');

  const PropertyType(this.value);

  final String value;

  /// Get display name for the property type
  String get displayName {
    switch (this) {
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.house:
        return 'House';
      case PropertyType.room:
        return 'Room';
    }
  }

  /// Get Croatian display name
  String get displayNameHR {
    switch (this) {
      case PropertyType.villa:
        return 'Vila';
      case PropertyType.apartment:
        return 'Apartman';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.house:
        return 'Kuća';
      case PropertyType.room:
        return 'Soba';
    }
  }

  /// Parse from string value
  static PropertyType fromString(String value) {
    return PropertyType.values.firstWhere((type) => type.value == value, orElse: () => PropertyType.apartment);
  }
}

/// Booking status
@JsonEnum(valueField: 'value')
enum BookingStatus {
  /// Awaiting owner approval (for bookingPending mode or requireOwnerApproval=true)
  /// These dates ARE blocked on calendar until owner approves or rejects
  pending('pending'),

  /// Booking confirmed and paid (or approved for non-payment modes)
  confirmed('confirmed'),

  /// Booking was cancelled (by guest, owner, or system)
  cancelled('cancelled'),

  /// Booking completed (guest checked out)
  completed('completed');

  const BookingStatus(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending Approval';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }

  /// Get color for booking status
  /// Note: On calendar, pending uses RED with diagonal pattern (same as booked)
  /// This color is used in owner dashboard badges
  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return const Color(0xFFFFA726); // Orange - for dashboard badge
      case BookingStatus.confirmed:
        return const Color(0xFF4CAF50); // Green (softer, less saturated)
      case BookingStatus.cancelled:
        return const Color(0xFFEF5350); // Red
      case BookingStatus.completed:
        return const Color(0xFF42A5F5); // Blue
    }
  }

  /// Check if booking can be cancelled
  bool get canBeCancelled {
    return this == BookingStatus.pending || this == BookingStatus.confirmed;
  }

  /// Check if booking is active (currently in use or confirmed)
  bool get isActive {
    return this == BookingStatus.confirmed;
  }

  /// Check if booking blocks calendar dates
  /// pending BLOCKS dates (waiting for owner approval)
  /// confirmed BLOCKS dates
  /// completed BLOCKS dates (historical)
  /// cancelled does NOT block dates
  bool get blocksCalendarDates {
    return this != BookingStatus.cancelled;
  }

  /// Check if booking is in final state (cannot be modified)
  bool get isFinal {
    return this == BookingStatus.completed || this == BookingStatus.cancelled;
  }

  /// Check if booking needs owner action (approval)
  /// Used in owner dashboard to show bookings that need attention
  bool get needsOwnerAction {
    return this == BookingStatus.pending;
  }

  /// Check if booking is pending approval
  bool get isPending {
    return this == BookingStatus.pending;
  }

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere((status) => status.value == value, orElse: () => BookingStatus.pending);
  }
}
