// import 'package:rab_booking/features/property/domain/models/property.dart';
// import 'package:rab_booking/features/booking/domain/models/user_booking.dart';
// import 'package:rab_booking/features/booking/domain/models/booking_status.dart';

/// Builder pattern for creating test Property objects
/// TODO: Uncomment when Property model is available
/*
class PropertyBuilder {
  String _id = 'test-property-1';
  String _name = 'Test Villa';
  String _location = 'Rab';
  String _description = 'Beautiful test villa';
  double _pricePerNight = 100.0;
  int _maxGuests = 4;
  List<String> _imageUrls = ['https://example.com/image.jpg'];
  String _ownerId = 'test-owner-1';

  PropertyBuilder withId(String id) {
    _id = id;
    return this;
  }

  PropertyBuilder withName(String name) {
    _name = name;
    return this;
  }

  PropertyBuilder withLocation(String location) {
    _location = location;
    return this;
  }

  PropertyBuilder withDescription(String description) {
    _description = description;
    return this;
  }

  PropertyBuilder withPrice(double price) {
    _pricePerNight = price;
    return this;
  }

  PropertyBuilder withMaxGuests(int maxGuests) {
    _maxGuests = maxGuests;
    return this;
  }

  PropertyBuilder withImages(List<String> images) {
    _imageUrls = images;
    return this;
  }

  PropertyBuilder withOwnerId(String ownerId) {
    _ownerId = ownerId;
    return this;
  }

  Property build() {
    return Property(
      id: _id,
      name: _name,
      location: _location,
      description: _description,
      pricePerNight: _pricePerNight,
      maxGuests: _maxGuests,
      imageUrls: _imageUrls,
      ownerId: _ownerId,
      createdAt: DateTime.now(),
    );
  }
}

/// Builder pattern for creating test UserBooking objects
class BookingBuilder {
  String _id = 'test-booking-1';
  String _propertyId = 'test-property-1';
  String _propertyName = 'Test Villa';
  String _userId = 'test-user-1';
  DateTime _checkIn = DateTime(2025, 6, 1);
  DateTime _checkOut = DateTime(2025, 6, 5);
  int _guests = 2;
  double _totalPrice = 400.0;
  BookingStatus _status = BookingStatus.confirmed;
  String? _imageUrl = 'https://example.com/image.jpg';

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

  BookingBuilder withUserId(String userId) {
    _userId = userId;
    return this;
  }

  BookingBuilder withCheckIn(DateTime checkIn) {
    _checkIn = checkIn;
    return this;
  }

  BookingBuilder withCheckOut(DateTime checkOut) {
    _checkOut = checkOut;
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

  BookingBuilder withImageUrl(String? imageUrl) {
    _imageUrl = imageUrl;
    return this;
  }

  UserBooking build() {
    return UserBooking(
      id: _id,
      propertyId: _propertyId,
      propertyName: _propertyName,
      userId: _userId,
      checkIn: _checkIn,
      checkOut: _checkOut,
      guests: _guests,
      totalPrice: _totalPrice,
      status: _status,
      imageUrl: _imageUrl,
      createdAt: DateTime.now(),
    );
  }
}

// Convenience functions
Property createMockProperty({
  String id = 'test-1',
  String name = 'Test Villa',
  double price = 100.0,
}) {
  return PropertyBuilder()
      .withId(id)
      .withName(name)
      .withPrice(price)
      .build();
}

UserBooking createMockBooking({
  String id = 'test-booking-1',
  BookingStatus status = BookingStatus.confirmed,
}) {
  return BookingBuilder()
      .withId(id)
      .withStatus(status)
      .build();
}
*/

// Placeholder - uncomment builders when models are available
