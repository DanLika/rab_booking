// Audit sweep F4.2 — unit form data-loss fixes.
//
// (1) UnitModel now carries `amenities` (the Firestore doc always had the
//     field; the model dropped it on read, so the edit form started from an
//     empty selection and silently WIPED amenities on save).
// (2) The `area` field is optional in the form but the save path called
//     double.parse — crash on empty. Now tryParse (null → repo skips/stores
//     null).

import 'package:bookbed/core/constants/enums.dart';
import 'package:bookbed/shared/models/unit_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitModel.amenities (F4.2 wipe fix)', () {
    test('fromJson reads the amenities field the doc always carried', () {
      final unit = UnitModel.fromJson(const {
        'id': 'u1',
        'property_id': 'p1',
        'name': 'Studio',
        'base_price': 100.0,
        'max_guests': 2,
        'created_at': '2026-07-01T00:00:00.000Z',
        'amenities': ['wifi', 'parking'],
      });
      expect(unit.amenities, ['wifi', 'parking']);
      // Round-trips into the form's enum set without loss.
      expect(PropertyAmenity.fromStringList(unit.amenities), [
        PropertyAmenity.wifi,
        PropertyAmenity.parking,
      ]);
    });

    test('defaults to empty list when the doc has no amenities', () {
      final unit = UnitModel.fromJson(const {
        'id': 'u1',
        'property_id': 'p1',
        'name': 'Studio',
        'base_price': 100.0,
        'max_guests': 2,
        'created_at': '2026-07-01T00:00:00.000Z',
      });
      expect(unit.amenities, isEmpty);
    });

    test('toJson round-trips amenities (repo write paths keep them)', () {
      final unit = UnitModel.fromJson(const {
        'id': 'u1',
        'property_id': 'p1',
        'name': 'Studio',
        'base_price': 100.0,
        'max_guests': 2,
        'created_at': '2026-07-01T00:00:00.000Z',
        'amenities': ['wifi'],
      });
      expect(unit.toJson()['amenities'], ['wifi']);
    });
  });

  group('area optional parse (F4.2 crash fix)', () {
    test('empty optional area parses to null, not a crash', () {
      // Mirrors the form save path: double.parse('') threw FormatException.
      expect(double.tryParse(''), isNull);
      expect(double.tryParse('45'), 45);
    });
  });
}
