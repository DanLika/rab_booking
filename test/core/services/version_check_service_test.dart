import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/models/app_config.dart';

void main() {
  group('AppConfig', () {
    test('defaultConfig has safe defaults', () {
      final config = AppConfig.defaultConfig();
      expect(config.minRequiredVersion, '1.0.0');
      expect(config.latestVersion, '1.0.0');
      expect(config.forceUpdateEnabled, isFalse);
      expect(config.updateMessage, isNull);
      expect(config.storeUrl, isNull);
    });

    test('fromJson parses all fields', () {
      final json = {
        'minRequiredVersion': '1.0.3',
        'latestVersion': '1.0.5',
        'forceUpdateEnabled': true,
        'updateMessage': 'Please update',
        'storeUrl':
            'https://play.google.com/store/apps/details?id=io.bookbed.app',
      };
      final config = AppConfig.fromJson(json);
      expect(config.minRequiredVersion, '1.0.3');
      expect(config.latestVersion, '1.0.5');
      expect(config.forceUpdateEnabled, isTrue);
      expect(config.updateMessage, 'Please update');
      expect(config.storeUrl, contains('play.google.com'));
    });

    test('fromJson uses defaults for optional fields', () {
      final json = {'minRequiredVersion': '1.0.0', 'latestVersion': '1.0.0'};
      final config = AppConfig.fromJson(json);
      expect(config.forceUpdateEnabled, isTrue);
      expect(config.updateMessage, isNull);
      expect(config.storeUrl, isNull);
    });

    test('toJson serializes correctly', () {
      const config = AppConfig(
        minRequiredVersion: '2.0.0',
        latestVersion: '2.1.0',
        forceUpdateEnabled: true,
        updateMessage: 'Update now',
        storeUrl: 'https://example.com',
      );
      final json = config.toJson();
      expect(json['minRequiredVersion'], '2.0.0');
      expect(json['latestVersion'], '2.1.0');
      expect(json['forceUpdateEnabled'], isTrue);
      expect(json['updateMessage'], 'Update now');
      expect(json['storeUrl'], 'https://example.com');
    });

    test('copyWith creates modified copy', () {
      final original = AppConfig.defaultConfig();
      final modified = original.copyWith(
        minRequiredVersion: '2.0.0',
        forceUpdateEnabled: true,
      );
      expect(modified.minRequiredVersion, '2.0.0');
      expect(modified.forceUpdateEnabled, isTrue);
      expect(modified.latestVersion, '1.0.0'); // unchanged
    });
  });

  group('UpdateStatus', () {
    test('has all expected values', () {
      expect(UpdateStatus.values.length, 3);
      expect(UpdateStatus.values, contains(UpdateStatus.upToDate));
      expect(UpdateStatus.values, contains(UpdateStatus.optionalUpdate));
      expect(UpdateStatus.values, contains(UpdateStatus.forceUpdate));
    });
  });
}
