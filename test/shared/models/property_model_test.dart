import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/models/property_model.dart';
import 'package:bookbed/core/constants/enums.dart';

void main() {
  group('PropertyModel', () {
    PropertyModel createProperty({
      String id = 'prop-123',
      String name = 'Villa Marija',
      String description = 'Beautiful villa',
      String location = 'Rab, Croatia',
      String? subdomain,
      String? coverImage,
      List<String> images = const [],
      double? pricePerNight,
      int? maxGuests,
      int? bedrooms,
      int? bathrooms,
      double rating = 0.0,
      List<PropertyAmenity> amenities = const [],
      bool isActive = true,
    }) {
      return PropertyModel(
        id: id,
        name: name,
        description: description,
        location: location,
        subdomain: subdomain,
        coverImage: coverImage,
        images: images,
        pricePerNight: pricePerNight,
        maxGuests: maxGuests,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        rating: rating,
        amenities: amenities,
        isActive: isActive,
        createdAt: DateTime.utc(2025, 1),
      );
    }

    group('primaryImage', () {
      test('returns coverImage when set', () {
        final property = createProperty(
          coverImage: 'cover.jpg',
          images: ['img1.jpg', 'img2.jpg'],
        );
        expect(property.primaryImage, 'cover.jpg');
      });

      test('returns first image when no cover', () {
        final property = createProperty(images: ['img1.jpg', 'img2.jpg']);
        expect(property.primaryImage, 'img1.jpg');
      });

      test('returns null when no images', () {
        final property = createProperty();
        expect(property.primaryImage, isNull);
      });

      test('returns null for empty coverImage', () {
        final property = createProperty(coverImage: '');
        expect(property.primaryImage, isNull);
      });
    });

    group('hasImages', () {
      test('returns true with coverImage', () {
        final property = createProperty(coverImage: 'cover.jpg');
        expect(property.hasImages, isTrue);
      });

      test('returns true with images list', () {
        final property = createProperty(images: ['img1.jpg']);
        expect(property.hasImages, isTrue);
      });

      test('returns false with no images', () {
        final property = createProperty();
        expect(property.hasImages, isFalse);
      });
    });

    group('rating', () {
      test('formattedRating formats to 1 decimal', () {
        final property = createProperty(rating: 4.567);
        expect(property.formattedRating, '4.6');
      });

      test('hasGoodRating true for >= 4.0', () {
        expect(createProperty(rating: 4.0).hasGoodRating, isTrue);
        expect(createProperty(rating: 4.5).hasGoodRating, isTrue);
        expect(createProperty(rating: 5.0).hasGoodRating, isTrue);
      });

      test('hasGoodRating false for < 4.0', () {
        expect(createProperty(rating: 3.9).hasGoodRating, isFalse);
        expect(createProperty().hasGoodRating, isFalse);
      });
    });

    group('amenities', () {
      test('amenityCount returns correct count', () {
        final property = createProperty(
          amenities: [
            PropertyAmenity.wifi,
            PropertyAmenity.pool,
            PropertyAmenity.parking,
          ],
        );
        expect(property.amenityCount, 3);
      });

      test('hasAmenity returns true for existing amenity', () {
        final property = createProperty(amenities: [PropertyAmenity.wifi]);
        expect(property.hasAmenity(PropertyAmenity.wifi), isTrue);
      });

      test('hasAmenity returns false for missing amenity', () {
        final property = createProperty(amenities: [PropertyAmenity.wifi]);
        expect(property.hasAmenity(PropertyAmenity.pool), isFalse);
      });

      test('essentialAmenities filters correctly', () {
        final property = createProperty(
          amenities: [
            PropertyAmenity.wifi,
            PropertyAmenity.pool,
            PropertyAmenity.parking,
            PropertyAmenity.bbq,
          ],
        );
        final essential = property.essentialAmenities;
        expect(essential, contains(PropertyAmenity.wifi));
        expect(essential, contains(PropertyAmenity.parking));
        expect(essential, isNot(contains(PropertyAmenity.pool)));
        expect(essential, isNot(contains(PropertyAmenity.bbq)));
      });
    });

    group('pricing', () {
      test('formattedPrice with price', () {
        final property = createProperty(pricePerNight: 120.0);
        expect(property.formattedPrice, '€120');
      });

      test('formattedPrice without price', () {
        final property = createProperty();
        expect(property.formattedPrice, 'Cijena na upit');
      });

      test('formattedPricePerNight with price', () {
        final property = createProperty(pricePerNight: 120.0);
        expect(property.formattedPricePerNight, '€120/noć');
      });
    });

    group('subdomain', () {
      test('hasSubdomain returns true when set', () {
        final property = createProperty(subdomain: 'jasko-rab');
        expect(property.hasSubdomain, isTrue);
      });

      test('hasSubdomain returns false when null', () {
        final property = createProperty();
        expect(property.hasSubdomain, isFalse);
      });

      test('hasSubdomain returns false when empty', () {
        final property = createProperty(subdomain: '');
        expect(property.hasSubdomain, isFalse);
      });

      test('getSubdomainTestUrl returns URL with subdomain', () {
        final property = createProperty(subdomain: 'jasko-rab');
        expect(
          property.getSubdomainTestUrl('https://view.bookbed.io'),
          'https://view.bookbed.io?subdomain=jasko-rab',
        );
      });

      test('getSubdomainTestUrl returns null without subdomain', () {
        final property = createProperty();
        expect(property.getSubdomainTestUrl('https://view.bookbed.io'), isNull);
      });
    });

    group('hasCompleteInfo', () {
      test('returns true when all info present', () {
        final property = createProperty(
          maxGuests: 6,
          bedrooms: 3,
          bathrooms: 2,
        );
        expect(property.hasCompleteInfo, isTrue);
      });

      test('returns false when maxGuests missing', () {
        final property = createProperty(bedrooms: 3, bathrooms: 2);
        expect(property.hasCompleteInfo, isFalse);
      });

      test('returns false when bedrooms missing', () {
        final property = createProperty(maxGuests: 6, bathrooms: 2);
        expect(property.hasCompleteInfo, isFalse);
      });

      test('returns false when bathrooms missing', () {
        final property = createProperty(maxGuests: 6, bedrooms: 3);
        expect(property.hasCompleteInfo, isFalse);
      });
    });
  });
}
