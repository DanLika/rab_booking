/// Test data builders for creating mock objects in tests.
///
/// Provides convenient factory functions and builder classes
/// for creating PropertyModel and UserBooking instances with default values.
library;

import 'package:rab_booking/shared/models/property_model.dart';
import 'package:rab_booking/features/booking/domain/models/user_booking.dart';
import 'package:rab_booking/features/booking/domain/models/booking_status.dart';
import 'package:rab_booking/core/constants/enums.dart';

/// Helper function to create a mock PropertyModel with optional overrides
PropertyModel createMockProperty({
  String? id,
  String? ownerId,
  String? name,
  String? description,
  PropertyType? propertyType,
  String? location,
  String? address,
  List<PropertyAmenity>? amenities,
  List<String>? images,
  String? coverImage,
  double? rating,
  int? reviewCount,
  DateTime? createdAt,
  bool? isActive,
  double? pricePerNight,
  int? maxGuests,
  int? bedrooms,
  int? bathrooms,
}) {
  return PropertyModel(
    id: id ?? 'test-property-1',
    ownerId: ownerId ?? 'test-owner-1',
    name: name ?? 'Test Villa Mediteran',
    description: description ?? 'Beautiful test villa with sea view. Perfect for families.',
    propertyType: propertyType ?? PropertyType.villa,
    location: location ?? 'Rab, Croatia',
    address: address,
    amenities: amenities ?? [PropertyAmenity.wifi, PropertyAmenity.parking, PropertyAmenity.pool],
    images: images ?? ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
    coverImage: coverImage ?? 'https://example.com/cover.jpg',
    rating: rating ?? 4.8,
    reviewCount: reviewCount ?? 24,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
    isActive: isActive ?? true,
    pricePerNight: pricePerNight ?? 150.0,
    maxGuests: maxGuests ?? 6,
    bedrooms: bedrooms ?? 3,
    bathrooms: bathrooms ?? 2,
  );
}

/// Helper function to create a mock UserBooking with optional overrides
UserBooking createMockBooking({
  String? id,
  String? propertyId,
  String? propertyName,
  String? propertyImage,
  String? propertyLocation,
  DateTime? checkInDate,
  DateTime? checkOutDate,
  int? guests,
  double? totalPrice,
  BookingStatus? status,
  DateTime? bookingDate,
  String? cancellationReason,
  DateTime? cancellationDate,
}) {
  return UserBooking(
    id: id ?? 'test-booking-1',
    propertyId: propertyId ?? 'test-property-1',
    propertyName: propertyName ?? 'Test Villa Mediteran',
    propertyImage: propertyImage ?? 'https://example.com/image.jpg',
    propertyLocation: propertyLocation ?? 'Rab, Croatia',
    checkInDate: checkInDate ?? DateTime(2025, 6, 1),
    checkOutDate: checkOutDate ?? DateTime(2025, 6, 5),
    guests: guests ?? 4,
    totalPrice: totalPrice ?? 600.0,
    status: status ?? BookingStatus.confirmed,
    bookingDate: bookingDate ?? DateTime(2025, 5, 1),
    cancellationReason: cancellationReason,
    cancellationDate: cancellationDate,
  );
}

/// Builder pattern for creating test PropertyModel objects with fluent API
class PropertyBuilder {
  String _id = 'test-property-1';
  String _ownerId = 'test-owner-1';
  String _name = 'Test Villa';
  String _description = 'Beautiful test villa';
  PropertyType _propertyType = PropertyType.villa;
  String _location = 'Rab, Croatia';
  String? _address;
  List<PropertyAmenity> _amenities = [PropertyAmenity.wifi, PropertyAmenity.parking];
  List<String> _images = ['https://example.com/image.jpg'];
  String? _coverImage = 'https://example.com/cover.jpg';
  double _rating = 4.5;
  int _reviewCount = 10;
  DateTime _createdAt = DateTime(2024, 1, 1);
  bool _isActive = true;
  double? _pricePerNight = 100.0;
  int? _maxGuests = 4;
  int? _bedrooms = 2;
  int? _bathrooms = 1;

  PropertyBuilder withId(String id) {
    _id = id;
    return this;
  }

  PropertyBuilder withOwnerId(String ownerId) {
    _ownerId = ownerId;
    return this;
  }

  PropertyBuilder withName(String name) {
    _name = name;
    return this;
  }

  PropertyBuilder withDescription(String description) {
    _description = description;
    return this;
  }

  PropertyBuilder withPropertyType(PropertyType propertyType) {
    _propertyType = propertyType;
    return this;
  }

  PropertyBuilder withLocation(String location) {
    _location = location;
    return this;
  }

  PropertyBuilder withAddress(String address) {
    _address = address;
    return this;
  }

  PropertyBuilder withAmenities(List<PropertyAmenity> amenities) {
    _amenities = amenities;
    return this;
  }

  PropertyBuilder withImages(List<String> images) {
    _images = images;
    return this;
  }

  PropertyBuilder withCoverImage(String coverImage) {
    _coverImage = coverImage;
    return this;
  }

  PropertyBuilder withRating(double rating) {
    _rating = rating;
    return this;
  }

  PropertyBuilder withReviewCount(int reviewCount) {
    _reviewCount = reviewCount;
    return this;
  }

  PropertyBuilder withCreatedAt(DateTime createdAt) {
    _createdAt = createdAt;
    return this;
  }

  PropertyBuilder withIsActive(bool isActive) {
    _isActive = isActive;
    return this;
  }

  PropertyBuilder withPrice(double pricePerNight) {
    _pricePerNight = pricePerNight;
    return this;
  }

  PropertyBuilder withMaxGuests(int maxGuests) {
    _maxGuests = maxGuests;
    return this;
  }

  PropertyBuilder withBedrooms(int bedrooms) {
    _bedrooms = bedrooms;
    return this;
  }

  PropertyBuilder withBathrooms(int bathrooms) {
    _bathrooms = bathrooms;
    return this;
  }

  PropertyModel build() {
    return PropertyModel(
      id: _id,
      ownerId: _ownerId,
      name: _name,
      description: _description,
      propertyType: _propertyType,
      location: _location,
      address: _address,
      amenities: _amenities,
      images: _images,
      coverImage: _coverImage,
      rating: _rating,
      reviewCount: _reviewCount,
      createdAt: _createdAt,
      isActive: _isActive,
      pricePerNight: _pricePerNight,
      maxGuests: _maxGuests,
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
    );
  }
}

/// Builder pattern for creating test UserBooking objects with fluent API
class BookingBuilder {
  String _id = 'test-booking-1';
  String _propertyId = 'test-property-1';
  String _propertyName = 'Test Villa';
  String _propertyImage = 'https://example.com/image.jpg';
  String _propertyLocation = 'Rab, Croatia';
  DateTime _checkInDate = DateTime(2025, 6, 1);
  DateTime _checkOutDate = DateTime(2025, 6, 5);
  int _guests = 2;
  double _totalPrice = 400.0;
  BookingStatus _status = BookingStatus.confirmed;
  DateTime _bookingDate = DateTime(2025, 5, 1);
  String? _cancellationReason;
  DateTime? _cancellationDate;

  BookingBuilder withId(String id) {
    _id = id;
    return this;
  }

  BookingBuilder withPropertyId(String propertyId) {
    _propertyId = propertyId;
    return this;
  }

  BookingBuilder withPropertyName(String propertyName) {
    _propertyName = propertyName;
    return this;
  }

  BookingBuilder withPropertyImage(String propertyImage) {
    _propertyImage = propertyImage;
    return this;
  }

  BookingBuilder withPropertyLocation(String propertyLocation) {
    _propertyLocation = propertyLocation;
    return this;
  }

  BookingBuilder withCheckInDate(DateTime checkInDate) {
    _checkInDate = checkInDate;
    return this;
  }

  BookingBuilder withCheckOutDate(DateTime checkOutDate) {
    _checkOutDate = checkOutDate;
    return this;
  }

  BookingBuilder withGuests(int guests) {
    _guests = guests;
    return this;
  }

  BookingBuilder withTotalPrice(double totalPrice) {
    _totalPrice = totalPrice;
    return this;
  }

  BookingBuilder withStatus(BookingStatus status) {
    _status = status;
    return this;
  }

  BookingBuilder withBookingDate(DateTime bookingDate) {
    _bookingDate = bookingDate;
    return this;
  }

  BookingBuilder withCancellationReason(String cancellationReason) {
    _cancellationReason = cancellationReason;
    return this;
  }

  BookingBuilder withCancellationDate(DateTime cancellationDate) {
    _cancellationDate = cancellationDate;
    return this;
  }

  UserBooking build() {
    return UserBooking(
      id: _id,
      propertyId: _propertyId,
      propertyName: _propertyName,
      propertyImage: _propertyImage,
      propertyLocation: _propertyLocation,
      checkInDate: _checkInDate,
      checkOutDate: _checkOutDate,
      guests: _guests,
      totalPrice: _totalPrice,
      status: _status,
      bookingDate: _bookingDate,
      cancellationReason: _cancellationReason,
      cancellationDate: _cancellationDate,
    );
  }
}

/// Predefined test properties for common test scenarios
class TestProperties {
  /// Luxury villa with all amenities
  static PropertyModel luxuryVilla() => createMockProperty(
        id: 'villa-luxury-1',
        name: 'Luxury Villa Azure',
        propertyType: PropertyType.villa,
        pricePerNight: 500.0,
        maxGuests: 10,
        bedrooms: 5,
        bathrooms: 4,
        rating: 5.0,
        reviewCount: 100,
        amenities: [
          PropertyAmenity.wifi,
          PropertyAmenity.parking,
          PropertyAmenity.pool,
          PropertyAmenity.seaView,
          PropertyAmenity.gym,
          PropertyAmenity.hotTub,
        ],
      );

  /// Budget-friendly apartment
  static PropertyModel budgetApartment() => createMockProperty(
        id: 'apt-budget-1',
        name: 'Cozy Studio Apartment',
        propertyType: PropertyType.apartment,
        pricePerNight: 50.0,
        maxGuests: 2,
        bedrooms: 1,
        bathrooms: 1,
        rating: 4.2,
        reviewCount: 15,
        amenities: [PropertyAmenity.wifi, PropertyAmenity.airConditioning],
      );

  /// Inactive/unpublished property
  static PropertyModel inactiveProperty() => createMockProperty(
        id: 'property-inactive-1',
        name: 'Under Renovation House',
        isActive: false,
        pricePerNight: 0.0,
      );
}

/// Predefined test bookings for common test scenarios
class TestBookings {
  /// Confirmed upcoming booking
  static UserBooking confirmedBooking() => createMockBooking(
        id: 'booking-confirmed-1',
        status: BookingStatus.confirmed,
        checkInDate: DateTime.now().add(const Duration(days: 7)),
        checkOutDate: DateTime.now().add(const Duration(days: 10)),
      );

  /// Pending booking awaiting payment
  static UserBooking pendingBooking() => createMockBooking(
        id: 'booking-pending-1',
        status: BookingStatus.pending,
        checkInDate: DateTime.now().add(const Duration(days: 14)),
        checkOutDate: DateTime.now().add(const Duration(days: 17)),
      );

  /// Cancelled booking
  static UserBooking cancelledBooking() => createMockBooking(
        id: 'booking-cancelled-1',
        status: BookingStatus.cancelled,
        cancellationReason: 'Changed travel plans',
        cancellationDate: DateTime.now().subtract(const Duration(days: 2)),
      );

  /// Completed past booking
  static UserBooking completedBooking() => createMockBooking(
        id: 'booking-completed-1',
        status: BookingStatus.completed,
        checkInDate: DateTime.now().subtract(const Duration(days: 10)),
        checkOutDate: DateTime.now().subtract(const Duration(days: 7)),
      );
}
