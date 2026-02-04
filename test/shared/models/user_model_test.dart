import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/models/user_model.dart';
import 'package:bookbed/core/constants/enums.dart';

void main() {
  group('UserModel', () {
    UserModel createUser({
      String id = 'user-123',
      String email = 'test@example.com',
      String firstName = 'John',
      String lastName = 'Doe',
      UserRole role = UserRole.owner,
      AccountType accountType = AccountType.trial,
      AccountType? adminOverrideAccountType,
      bool emailVerified = true,
      bool onboardingCompleted = true,
      String? stripeAccountId,
      String? employeeOf,
      bool profileCompleted = true,
      Map<String, bool> featureFlags = const {},
    }) {
      return UserModel(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        accountType: accountType,
        adminOverrideAccountType: adminOverrideAccountType,
        emailVerified: emailVerified,
        onboardingCompleted: onboardingCompleted,
        stripeAccountId: stripeAccountId,
        employeeOf: employeeOf,
        profileCompleted: profileCompleted,
        featureFlags: featureFlags,
      );
    }

    group('fullName', () {
      test('combines first and last name', () {
        final user = createUser();
        expect(user.fullName, 'John Doe');
      });

      test('handles empty first name', () {
        final user = createUser(firstName: '');
        expect(user.fullName, ' Doe');
      });
    });

    group('initials', () {
      test('returns uppercase initials', () {
        final user = createUser();
        expect(user.initials, 'JD');
      });

      test('handles lowercase names', () {
        final user = createUser(firstName: 'john', lastName: 'doe');
        expect(user.initials, 'JD');
      });

      test('handles empty first name', () {
        final user = createUser(firstName: '');
        expect(user.initials, 'D');
      });

      test('handles empty last name', () {
        final user = createUser(lastName: '');
        expect(user.initials, 'J');
      });
    });

    group('hasCompletedProfile', () {
      test('returns true when all fields are filled', () {
        final user = createUser();
        expect(user.hasCompletedProfile, isTrue);
      });

      test('returns false when firstName is empty', () {
        final user = createUser(firstName: '');
        expect(user.hasCompletedProfile, isFalse);
      });

      test('returns false when lastName is empty', () {
        final user = createUser(lastName: '');
        expect(user.hasCompletedProfile, isFalse);
      });

      test('returns false when email is empty', () {
        final user = createUser(email: '');
        expect(user.hasCompletedProfile, isFalse);
      });
    });

    group('role checks', () {
      test('isOwner returns true for owner role', () {
        final user = createUser();
        expect(user.isOwner, isTrue);
      });

      test('isOwner returns true for admin role', () {
        final user = createUser(role: UserRole.admin);
        expect(user.isOwner, isTrue);
      });

      test('isOwner returns false for guest role', () {
        final user = createUser(role: UserRole.guest);
        expect(user.isOwner, isFalse);
      });

      test('isAdmin returns true for admin role', () {
        final user = createUser(role: UserRole.admin);
        expect(user.isAdmin, isTrue);
      });

      test('isAdmin returns false for owner role', () {
        final user = createUser();
        expect(user.isAdmin, isFalse);
      });

      test('isEmployee returns true when employeeOf is set', () {
        final user = createUser(employeeOf: 'owner-456');
        expect(user.isEmployee, isTrue);
      });

      test('isEmployee returns false when employeeOf is null', () {
        final user = createUser();
        expect(user.isEmployee, isFalse);
      });
    });

    group('stripe', () {
      test('hasStripeConnected returns true with account ID', () {
        final user = createUser(stripeAccountId: 'acct_123');
        expect(user.hasStripeConnected, isTrue);
      });

      test('hasStripeConnected returns false with null', () {
        final user = createUser();
        expect(user.hasStripeConnected, isFalse);
      });

      test('hasStripeConnected returns false with empty string', () {
        final user = createUser(stripeAccountId: '');
        expect(user.hasStripeConnected, isFalse);
      });
    });

    group('onboarding', () {
      test('needsOnboarding returns true for owner without onboarding', () {
        final user = createUser(onboardingCompleted: false);
        expect(user.needsOnboarding, isTrue);
      });

      test('needsOnboarding returns false for owner with onboarding', () {
        final user = createUser();
        expect(user.needsOnboarding, isFalse);
      });

      test('needsOnboarding returns false for guest', () {
        final user = createUser(
          role: UserRole.guest,
          onboardingCompleted: false,
        );
        expect(user.needsOnboarding, isFalse);
      });
    });

    group('account type and premium access', () {
      test('effectiveAccountType returns accountType when no override', () {
        final user = createUser();
        expect(user.effectiveAccountType, AccountType.trial);
      });

      test('effectiveAccountType returns override when set', () {
        final user = createUser(adminOverrideAccountType: AccountType.premium);
        expect(user.effectiveAccountType, AccountType.premium);
      });

      test('hasPremiumAccess for trial is false', () {
        final user = createUser();
        expect(user.hasPremiumAccess, isFalse);
      });

      test('hasPremiumAccess for premium is true', () {
        final user = createUser(accountType: AccountType.premium);
        expect(user.hasPremiumAccess, isTrue);
      });

      test('hasPremiumAccess for enterprise is true', () {
        final user = createUser(accountType: AccountType.enterprise);
        expect(user.hasPremiumAccess, isTrue);
      });

      test('hasPremiumAccess for lifetime is true', () {
        final user = createUser(accountType: AccountType.lifetime);
        expect(user.hasPremiumAccess, isTrue);
      });

      test('hasPremiumAccess via admin override', () {
        final user = createUser(adminOverrideAccountType: AccountType.premium);
        expect(user.hasPremiumAccess, isTrue);
      });

      test('isLifetimeLicense via accountType', () {
        final user = createUser(accountType: AccountType.lifetime);
        expect(user.isLifetimeLicense, isTrue);
      });

      test('isLifetimeLicense via admin override', () {
        final user = createUser(adminOverrideAccountType: AccountType.lifetime);
        expect(user.isLifetimeLicense, isTrue);
      });

      test('isLifetimeLicense false for trial', () {
        final user = createUser();
        expect(user.isLifetimeLicense, isFalse);
      });
    });
  });

  group('UserRole', () {
    test('fromString parses known values', () {
      expect(UserRole.fromString('guest'), UserRole.guest);
      expect(UserRole.fromString('owner'), UserRole.owner);
      expect(UserRole.fromString('admin'), UserRole.admin);
    });

    test('fromString defaults to guest for unknown', () {
      expect(UserRole.fromString('unknown'), UserRole.guest);
    });

    test('canManageProperties for owner and admin', () {
      expect(UserRole.owner.canManageProperties, isTrue);
      expect(UserRole.admin.canManageProperties, isTrue);
      expect(UserRole.guest.canManageProperties, isFalse);
    });
  });

  group('PropertyAmenity', () {
    test('isEssential for wifi, parking, AC, kitchen', () {
      expect(PropertyAmenity.wifi.isEssential, isTrue);
      expect(PropertyAmenity.parking.isEssential, isTrue);
      expect(PropertyAmenity.airConditioning.isEssential, isTrue);
      expect(PropertyAmenity.kitchen.isEssential, isTrue);
    });

    test('isEssential false for non-essential amenities', () {
      expect(PropertyAmenity.pool.isEssential, isFalse);
      expect(PropertyAmenity.bbq.isEssential, isFalse);
      expect(PropertyAmenity.sauna.isEssential, isFalse);
    });

    test('fromString parses known values', () {
      expect(PropertyAmenity.fromString('wifi'), PropertyAmenity.wifi);
      expect(PropertyAmenity.fromString('pool'), PropertyAmenity.pool);
    });

    test('fromString defaults to wifi for unknown', () {
      expect(PropertyAmenity.fromString('unknown'), PropertyAmenity.wifi);
    });

    test('fromStringList converts list', () {
      final list = PropertyAmenity.fromStringList(['wifi', 'pool', 'parking']);
      expect(list, [
        PropertyAmenity.wifi,
        PropertyAmenity.pool,
        PropertyAmenity.parking,
      ]);
    });

    test('toStringList converts list', () {
      final list = PropertyAmenity.toStringList([
        PropertyAmenity.wifi,
        PropertyAmenity.pool,
      ]);
      expect(list, ['wifi', 'pool']);
    });
  });

  group('PropertyType', () {
    test('fromString parses known values', () {
      expect(PropertyType.fromString('villa'), PropertyType.villa);
      expect(PropertyType.fromString('house'), PropertyType.house);
      expect(PropertyType.fromString('apartment'), PropertyType.apartment);
    });

    test('fromString maps legacy values to other', () {
      expect(PropertyType.fromString('studio'), PropertyType.other);
      expect(PropertyType.fromString('room'), PropertyType.other);
    });
  });
}
