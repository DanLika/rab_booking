import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/models/unit_model.dart';

void main() {
  group('UnitModel', () {
    UnitModel createUnit({
      String id = 'unit-123',
      String propertyId = 'prop-456',
      String? ownerId = 'owner-789',
      String name = 'Apartment A1',
      String? slug,
      String? description,
      double pricePerNight = 100.0,
      double? weekendBasePrice,
      List<int>? weekendDays,
      String? currency = 'EUR',
      int maxGuests = 4,
      int? maxTotalCapacity,
      double? extraBedFee,
      double? petFee,
      int bedrooms = 2,
      int bathrooms = 1,
      double? areaSqm,
      List<String> images = const [],
      bool isAvailable = true,
      int minStayNights = 1,
      int? maxStayNights,
      int sortOrder = 0,
    }) {
      return UnitModel(
        id: id,
        propertyId: propertyId,
        ownerId: ownerId,
        name: name,
        slug: slug,
        description: description,
        pricePerNight: pricePerNight,
        weekendBasePrice: weekendBasePrice,
        weekendDays: weekendDays,
        currency: currency,
        maxGuests: maxGuests,
        maxTotalCapacity: maxTotalCapacity,
        extraBedFee: extraBedFee,
        petFee: petFee,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        areaSqm: areaSqm,
        images: images,
        isAvailable: isAvailable,
        minStayNights: minStayNights,
        maxStayNights: maxStayNights,
        sortOrder: sortOrder,
        createdAt: DateTime.utc(2025),
      );
    }

    group('price formatting', () {
      test('formattedPrice returns euro symbol with price', () {
        final unit = createUnit(pricePerNight: 120.0);
        expect(unit.formattedPrice, '€120');
      });

      test('formattedPrice truncates decimals', () {
        final unit = createUnit(pricePerNight: 99.99);
        expect(unit.formattedPrice, '€100');
      });

      test('pricePerNightLabel includes per night', () {
        final unit = createUnit(pricePerNight: 120.0);
        expect(unit.pricePerNightLabel, '€120/night');
      });
    });

    group('calculateTotalPrice', () {
      test('multiplies price by nights', () {
        final unit = createUnit();
        expect(unit.calculateTotalPrice(3), 300.0);
      });

      test('returns 0 for 0 nights', () {
        final unit = createUnit();
        expect(unit.calculateTotalPrice(0), 0.0);
      });

      test('getFormattedTotalPrice formats correctly', () {
        final unit = createUnit(pricePerNight: 75.0);
        expect(unit.getFormattedTotalPrice(4), '€300');
      });
    });

    group('capacity', () {
      test('effectiveMaxCapacity returns maxGuests when no extra beds', () {
        final unit = createUnit();
        expect(unit.effectiveMaxCapacity, 4);
      });

      test('effectiveMaxCapacity returns maxTotalCapacity when set', () {
        final unit = createUnit(maxTotalCapacity: 6);
        expect(unit.effectiveMaxCapacity, 6);
      });

      test('canAccommodate returns true when within capacity', () {
        final unit = createUnit();
        expect(unit.canAccommodate(4), isTrue);
        expect(unit.canAccommodate(3), isTrue);
        expect(unit.canAccommodate(1), isTrue);
      });

      test('canAccommodate returns false when over capacity', () {
        final unit = createUnit();
        expect(unit.canAccommodate(5), isFalse);
      });

      test('canAccommodate uses total capacity with extra beds', () {
        final unit = createUnit(maxTotalCapacity: 6, extraBedFee: 20.0);
        expect(unit.canAccommodate(5), isTrue);
        expect(unit.canAccommodate(6), isTrue);
        expect(unit.canAccommodate(7), isFalse);
      });
    });

    group('extra beds and pets', () {
      test('hasExtraBeds true when all conditions met', () {
        final unit = createUnit(maxTotalCapacity: 6, extraBedFee: 20.0);
        expect(unit.hasExtraBeds, isTrue);
      });

      test('hasExtraBeds false when no maxTotalCapacity', () {
        final unit = createUnit(extraBedFee: 20.0);
        expect(unit.hasExtraBeds, isFalse);
      });

      test('hasExtraBeds false when maxTotalCapacity equals maxGuests', () {
        final unit = createUnit(maxTotalCapacity: 4, extraBedFee: 20.0);
        expect(unit.hasExtraBeds, isFalse);
      });

      test('hasExtraBeds false when no extraBedFee', () {
        final unit = createUnit(maxTotalCapacity: 6);
        expect(unit.hasExtraBeds, isFalse);
      });

      test('allowsPets true when petFee is set', () {
        final unit = createUnit(petFee: 10.0);
        expect(unit.allowsPets, isTrue);
      });

      test('allowsPets false when petFee is null', () {
        final unit = createUnit();
        expect(unit.allowsPets, isFalse);
      });
    });

    group('stay validation', () {
      test('meetsMinimumStay returns true when nights >= min', () {
        final unit = createUnit(minStayNights: 3);
        expect(unit.meetsMinimumStay(3), isTrue);
        expect(unit.meetsMinimumStay(5), isTrue);
      });

      test('meetsMinimumStay returns false when nights < min', () {
        final unit = createUnit(minStayNights: 3);
        expect(unit.meetsMinimumStay(2), isFalse);
        expect(unit.meetsMinimumStay(1), isFalse);
      });

      test('isBookingValid returns true when all conditions met', () {
        final unit = createUnit(minStayNights: 2);
        expect(unit.isBookingValid(3, 4), isTrue);
      });

      test('isBookingValid returns false when not available', () {
        final unit = createUnit(isAvailable: false);
        expect(unit.isBookingValid(3, 2), isFalse);
      });

      test('isBookingValid returns false when below min stay', () {
        final unit = createUnit(minStayNights: 3);
        expect(unit.isBookingValid(2, 2), isFalse);
      });

      test('isBookingValid returns false when over capacity', () {
        final unit = createUnit();
        expect(unit.isBookingValid(3, 5), isFalse);
      });
    });

    group('labels', () {
      test('guestCapacityLabel singular', () {
        final unit = createUnit(maxGuests: 1);
        expect(unit.guestCapacityLabel, '1 guest');
      });

      test('guestCapacityLabel plural', () {
        final unit = createUnit();
        expect(unit.guestCapacityLabel, '4 guests');
      });

      test('bedroomLabel singular', () {
        final unit = createUnit(bedrooms: 1);
        expect(unit.bedroomLabel, '1 bedroom');
      });

      test('bedroomLabel plural', () {
        final unit = createUnit(bedrooms: 3);
        expect(unit.bedroomLabel, '3 bedrooms');
      });

      test('bathroomLabel singular', () {
        final unit = createUnit();
        expect(unit.bathroomLabel, '1 bathroom');
      });

      test('bathroomLabel plural', () {
        final unit = createUnit(bathrooms: 2);
        expect(unit.bathroomLabel, '2 bathrooms');
      });

      test('summary combines all labels', () {
        final unit = createUnit();
        expect(unit.summary, '2 bedrooms • 1 bathroom • 4 guests');
      });
    });

    group('images', () {
      test('hasImages returns true with images', () {
        final unit = createUnit(images: ['img1.jpg']);
        expect(unit.hasImages, isTrue);
      });

      test('hasImages returns false with empty list', () {
        final unit = createUnit();
        expect(unit.hasImages, isFalse);
      });

      test('primaryImage returns first image', () {
        final unit = createUnit(images: ['img1.jpg', 'img2.jpg']);
        expect(unit.primaryImage, 'img1.jpg');
      });

      test('primaryImage returns null when no images', () {
        final unit = createUnit();
        expect(unit.primaryImage, isNull);
      });
    });
  });
}
