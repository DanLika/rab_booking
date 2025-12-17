import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/utils/nullable.dart';

void main() {
  group('Nullable', () {
    test('holds a non-null value', () {
      const nullable = Nullable('hello');

      expect(nullable.value, 'hello');
    });

    test('holds a null value', () {
      const nullable = Nullable<String>(null);

      expect(nullable.value, isNull);
    });

    test('Nullable.nil() creates null wrapper', () {
      const nullable = Nullable<String>.nil();

      expect(nullable.value, isNull);
    });

    test('works with different types', () {
      const stringNullable = Nullable('test');
      const intNullable = Nullable(42);
      const nullIntNullable = Nullable<int>(null);

      expect(stringNullable.value, 'test');
      expect(intNullable.value, 42);
      expect(nullIntNullable.value, isNull);
    });

    test('demonstrates copyWith pattern with non-null update', () {
      const currentValue = 'original';
      const update = Nullable('updated');

      // Simulating: ownerId: ownerId != null ? ownerId.value : this.ownerId
      final result = update.value;

      expect(result, 'updated');
      expect(result, isNot(currentValue));
    });

    test('demonstrates copyWith pattern with explicit null', () {
      const update = Nullable<String>(null);

      // When Nullable is provided but contains null, we explicitly set null
      final result = update.value;

      expect(result, isNull);
    });

    test('demonstrates copyWith pattern keeping existing value', () {
      const currentValue = 'original';

      // When copyWith parameter is not provided (null), keep existing
      // This simulates: ownerId != null ? ownerId.value : this.ownerId
      // where ownerId parameter is null
      String? resolveValue(Nullable<String>? nullable, String? existing) {
        return nullable != null ? nullable.value : existing;
      }

      final result = resolveValue(null, currentValue);

      expect(result, 'original');
    });
  });
}
