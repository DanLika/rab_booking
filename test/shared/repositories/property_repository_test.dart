import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/repositories/property_repository.dart';
import 'package:bookbed/core/constants/enums.dart';

void main() {
  group('PropertyFilters', () {
    group('constructor', () {
      test('creates with default (null) values', () {
        const filters = PropertyFilters();

        expect(filters.location, isNull);
        expect(filters.minPrice, isNull);
        expect(filters.maxPrice, isNull);
        expect(filters.amenities, isNull);
        expect(filters.minGuests, isNull);
        expect(filters.minRating, isNull);
        expect(filters.ownerId, isNull);
      });

      test('creates with custom values', () {
        const amenities = [PropertyAmenity.wifi, PropertyAmenity.pool];
        const filters = PropertyFilters(
          location: 'Split',
          minPrice: 50.0,
          maxPrice: 200.0,
          amenities: amenities,
          minGuests: 4,
          minRating: 4.5,
          ownerId: 'owner123',
        );

        expect(filters.location, 'Split');
        expect(filters.minPrice, 50.0);
        expect(filters.maxPrice, 200.0);
        expect(filters.amenities, amenities);
        expect(filters.minGuests, 4);
        expect(filters.minRating, 4.5);
        expect(filters.ownerId, 'owner123');
      });
    });

    group('hasFilters', () {
      test('returns false when no filters are set', () {
        const filters = PropertyFilters();
        expect(filters.hasFilters, false);
      });

      test('returns true when location is set', () {
        const filters = PropertyFilters(location: 'Zagreb');
        expect(filters.hasFilters, true);
      });

      test('returns true when minPrice is set', () {
        const filters = PropertyFilters(minPrice: 100.0);
        expect(filters.hasFilters, true);
      });

      test('returns true when maxPrice is set', () {
        const filters = PropertyFilters(maxPrice: 300.0);
        expect(filters.hasFilters, true);
      });

      test('returns true when amenities are set', () {
        const filters = PropertyFilters(amenities: [PropertyAmenity.wifi]);
        expect(filters.hasFilters, true);
      });

      test('returns true when minGuests is set', () {
        const filters = PropertyFilters(minGuests: 2);
        expect(filters.hasFilters, true);
      });

      test('returns true when minRating is set', () {
        const filters = PropertyFilters(minRating: 4.0);
        expect(filters.hasFilters, true);
      });

      test('returns true when ownerId is set', () {
        const filters = PropertyFilters(ownerId: 'owner-1');
        expect(filters.hasFilters, true);
      });

      test('returns true when multiple filters are set', () {
        const filters = PropertyFilters(
          location: 'Split',
          minGuests: 4,
          minPrice: 50.0,
        );
        expect(filters.hasFilters, true);
      });
    });
  });
}
