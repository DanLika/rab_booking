import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookbed/features/widget/presentation/providers/widget_settings_provider.dart';

void main() {
  group('widgetSettingsOrDefaultProvider - defensive checks', () {
    test('throws ArgumentError when unitId is empty', () async {
      final container = ProviderContainer();

      expect(
        () async => await container.read(
          widgetSettingsOrDefaultProvider(('property123', '')).future,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'unitId and propertyId must not be empty',
          ),
        ),
      );

      container.dispose();
    });

    test('throws ArgumentError when propertyId is empty', () async {
      final container = ProviderContainer();

      expect(
        () async => await container.read(
          widgetSettingsOrDefaultProvider(('', 'unit123')).future,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'unitId and propertyId must not be empty',
          ),
        ),
      );

      container.dispose();
    });

    test(
      'throws ArgumentError when both unitId and propertyId are empty',
      () async {
        final container = ProviderContainer();

        expect(
          () async => await container.read(
            widgetSettingsOrDefaultProvider(('', '')).future,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'unitId and propertyId must not be empty',
            ),
          ),
        );

        container.dispose();
      },
    );
  });
}
