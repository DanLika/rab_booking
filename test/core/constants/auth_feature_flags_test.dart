import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/constants/auth_feature_flags.dart';

void main() {
  group('AuthFeatureFlags', () {
    test('isAppleSignInEnabled should be true', () {
      expect(AuthFeatureFlags.isAppleSignInEnabled, isTrue);
    });
  });
}
