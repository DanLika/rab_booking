import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed_app/shared/models/user_model.dart';
import 'package:bookbed_app/core/constants/enums.dart';

void main() {
  group('UserModel Tests', () {
    final baseUser = UserModel(
      id: '123',
      email: 'test@example.com',
      firstName: 'John',
      lastName: 'Doe',
      role: UserRole.owner,
      createdAt: DateTime.now(),
    );

    test('fullName returns correct concatenation', () {
      expect(baseUser.fullName, 'John Doe');
    });

    test('initials returns correct first letters', () {
      expect(baseUser.initials, 'JD');
    });

    test('initials handles empty names', () {
      final user = baseUser.copyWith(firstName: '', lastName: '');
      expect(user.initials, '');
    });

    test('hasCompletedProfile returns true when fields are filled', () {
      expect(baseUser.hasCompletedProfile, isTrue);
    });

    test('hasCompletedProfile returns false when name is missing', () {
      final user = baseUser.copyWith(firstName: '');
      expect(user.hasCompletedProfile, isFalse);
    });

    test('isOwner returns true for owner', () {
      expect(baseUser.isOwner, isTrue);
    });

    test('isOwner returns true for admin', () {
      final user = baseUser.copyWith(role: UserRole.admin);
      expect(user.isOwner, isTrue);
    });

    test('isAdmin returns true for admin', () {
      final user = baseUser.copyWith(role: UserRole.admin);
      expect(user.isAdmin, isTrue);
    });

    test('hasStripeConnected returns true when accountId is present', () {
      final user = baseUser.copyWith(stripeAccountId: 'acct_123');
      expect(user.hasStripeConnected, isTrue);
    });

    test('needsOnboarding returns true when owner and not completed', () {
      final user = baseUser.copyWith(
        role: UserRole.owner,
        onboardingCompleted: false,
      );
      expect(user.needsOnboarding, isTrue);
    });
  });
}
