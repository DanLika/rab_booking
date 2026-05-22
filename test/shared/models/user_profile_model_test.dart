import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/models/user_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Address', () {
    test('supports value comparisons', () {
      expect(const Address(city: 'Paris'), const Address(city: 'Paris'));
    });

    test('fromJson and toJson', () {
      final json = {
        'country': 'France',
        'city': 'Paris',
        'street': 'Champs-Élysées',
        'postalCode': '75008',
      };

      final address = Address.fromJson(json);
      expect(address.country, 'France');
      expect(address.city, 'Paris');
      expect(address.street, 'Champs-Élysées');
      expect(address.postalCode, '75008');

      expect(address.toJson(), json);
    });

    test('empty address creation', () {
      const address = Address();
      expect(address.country, '');
      expect(address.city, '');
      expect(address.street, '');
      expect(address.postalCode, '');
    });
  });

  group('SocialLinks', () {
    test('fromJson and toJson', () {
      final json = {
        'website': 'https://example.com',
        'facebook': 'https://facebook.com/example',
      };

      final links = SocialLinks.fromJson(json);
      expect(links.website, 'https://example.com');
      expect(links.facebook, 'https://facebook.com/example');

      expect(links.toJson(), json);
    });

    test('empty links creation', () {
      const links = SocialLinks();
      expect(links.website, '');
      expect(links.facebook, '');
    });
  });

  group('CompanyDetails', () {
    final now = DateTime.now();

    test('fromJson and toJson', () {
      final json = {
        'companyName': 'Test Corp',
        'taxId': 'TAX123',
        'vatId': 'VAT123',
        'bankAccountIban': 'IBAN123',
        'swift': 'SWIFT123',
        'bankName': 'Test Bank',
        'accountHolder': 'John Doe',
        'address': {
          'country': 'France',
          'city': 'Paris',
          'street': 'Champs-Élysées',
          'postalCode': '75008',
        },
        'updatedAt': now.toIso8601String(),
      };

      final company = CompanyDetails.fromJson(json);
      expect(company.companyName, 'Test Corp');
      expect(company.taxId, 'TAX123');
      expect(company.address.city, 'Paris');
      expect(company.updatedAt, now);

      final toJson = company.toJson();
      expect(toJson['companyName'], 'Test Corp');
      expect(toJson['address'], isA<Address>());
      expect((toJson['address'] as Address).city, 'Paris');
    });

    test('fromFirestore creates instance from map with Timestamp', () {
      final data = {
        'companyName': 'Test Corp',
        'taxId': 'TAX123',
        'vatId': 'VAT123',
        'bankAccountIban': 'IBAN123',
        'swift': 'SWIFT123',
        'bankName': 'Test Bank',
        'accountHolder': 'John Doe',
        'address': {
          'country': 'France',
          'city': 'Paris',
          'street': 'Champs-Élysées',
          'postalCode': '75008',
        },
        'updatedAt': Timestamp.fromDate(now),
      };

      final company = CompanyDetails.fromFirestore(data);
      expect(company.companyName, 'Test Corp');
      expect(company.address.city, 'Paris');
      expect(company.updatedAt, now);
    });

    test('fromFirestore handles missing address and updatedAt', () {
      final data = {
        'companyName': 'Test Corp',
      };

      final company = CompanyDetails.fromFirestore(data);
      expect(company.companyName, 'Test Corp');
      expect(company.address, const Address());
      expect(company.updatedAt, isNull);
    });

    group('hasBankDetails', () {
      test('returns true when all required bank details are present', () {
        const company = CompanyDetails(
          bankAccountIban: 'IBAN123',
          bankName: 'Test Bank',
          accountHolder: 'John Doe',
        );
        expect(company.hasBankDetails, isTrue);
      });

      test('returns false when IBAN is missing', () {
        const company = CompanyDetails(
          bankName: 'Test Bank',
          accountHolder: 'John Doe',
        );
        expect(company.hasBankDetails, isFalse);
      });

      test('returns false when bankName is missing', () {
        const company = CompanyDetails(
          bankAccountIban: 'IBAN123',
          accountHolder: 'John Doe',
        );
        expect(company.hasBankDetails, isFalse);
      });

      test('returns false when accountHolder is missing', () {
        const company = CompanyDetails(
          bankAccountIban: 'IBAN123',
          bankName: 'Test Bank',
        );
        expect(company.hasBankDetails, isFalse);
      });
    });
  });

  group('UserProfile', () {
    final now = DateTime.now();

    test('fromJson and toJson', () {
      final json = {
        'userId': 'user123',
        'displayName': 'John Doe',
        'emailContact': 'john@example.com',
        'phoneE164': '+385911234567',
        'address': {
          'country': 'Croatia',
          'city': 'Zagreb',
          'street': 'Ilica 1',
          'postalCode': '10000',
        },
        'social': {
          'website': 'https://johndoe.com',
          'facebook': 'https://facebook.com/johndoe',
        },
        'propertyType': 'villa',
        'logoUrl': 'https://example.com/logo.png',
        'updatedAt': now.toIso8601String(),
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.userId, 'user123');
      expect(profile.displayName, 'John Doe');
      expect(profile.address.city, 'Zagreb');
      expect(profile.social.website, 'https://johndoe.com');

      final toJson = profile.toJson();
      expect(toJson['userId'], 'user123');
      expect(toJson['address'], isA<Address>());
      expect((toJson['address'] as Address).city, 'Zagreb');
      expect(toJson['social'], isA<SocialLinks>());
      expect((toJson['social'] as SocialLinks).website, 'https://johndoe.com');
    });

    test('fromFirestore creates instance with userId separately', () {
      final data = {
        'displayName': 'John Doe',
        'emailContact': 'john@example.com',
        'phoneE164': '+385911234567',
        'address': {
          'country': 'Croatia',
          'city': 'Zagreb',
          'street': 'Ilica 1',
          'postalCode': '10000',
        },
        'social': {
          'website': 'https://johndoe.com',
          'facebook': 'https://facebook.com/johndoe',
        },
        'propertyType': 'villa',
        'logoUrl': 'https://example.com/logo.png',
        'updatedAt': Timestamp.fromDate(now),
      };

      final profile = UserProfile.fromFirestore('user123', data);
      expect(profile.userId, 'user123');
      expect(profile.displayName, 'John Doe');
      expect(profile.address.city, 'Zagreb');
      expect(profile.social.website, 'https://johndoe.com');
      expect(profile.updatedAt, now);
    });

    test('fromFirestore handles missing nested objects', () {
      final data = <String, dynamic>{};

      final profile = UserProfile.fromFirestore('user123', data);
      expect(profile.userId, 'user123');
      expect(profile.address, const Address());
      expect(profile.social, const SocialLinks());
      expect(profile.updatedAt, isNull);
    });

    test('toFirestore includes FieldValue.serverTimestamp()', () {
      const profile = UserProfile(
        userId: 'user123',
        displayName: 'John Doe',
        emailContact: 'john@example.com',
      );

      final firestoreData = profile.toFirestore();

      expect(firestoreData['displayName'], 'John Doe');
      expect(firestoreData['emailContact'], 'john@example.com');
      expect(firestoreData['updatedAt'], isA<FieldValue>());
      // Ensure userId is not in the data map
      expect(firestoreData.containsKey('userId'), isFalse);
    });

    group('completionPercentage', () {
      test('returns 0 for empty profile', () {
        const profile = UserProfile(userId: 'user123');
        expect(profile.completionPercentage, 0);
      });

      test('returns correct percentage for partial profile', () {
        const profile = UserProfile(
          userId: 'user123',
          displayName: 'John Doe', // 1/7
          emailContact: 'john@example.com', // 2/7
          address: Address(city: 'Zagreb'), // 3/7
        );
        // 3/7 = 42.8% -> rounded to 43
        expect(profile.completionPercentage, 43);
      });

      test('returns 100 for fully completed profile', () {
        const profile = UserProfile(
          userId: 'user123',
          displayName: 'John Doe', // 1/7
          emailContact: 'john@example.com', // 2/7
          phoneE164: '+385911234567', // 3/7
          address: Address(city: 'Zagreb', country: 'Croatia'), // 4/7 & 5/7
          propertyType: 'villa', // 6/7
          logoUrl: 'https://example.com/logo.png', // 7/7
        );
        expect(profile.completionPercentage, 100);
      });
    });
  });

  group('UserData', () {
    test('fromJson and toJson', () {
      final json = {
        'profile': {
          'userId': 'user123',
          'displayName': 'John Doe',
        },
        'company': {
          'companyName': 'Test Corp',
        },
      };

      final userData = UserData.fromJson(json);
      expect(userData.profile.userId, 'user123');
      expect(userData.profile.displayName, 'John Doe');
      expect(userData.company.companyName, 'Test Corp');

      // The generated toJson() for complete UserData will include default empty fields
      // since the models populate defaults on fromJson if missing
      final toJson = userData.toJson();
      expect(toJson['profile'], isA<UserProfile>());
      expect((toJson['profile'] as UserProfile).userId, 'user123');
      expect((toJson['profile'] as UserProfile).displayName, 'John Doe');
      expect(toJson['company'], isA<CompanyDetails>());
      expect((toJson['company'] as CompanyDetails).companyName, 'Test Corp');
    });
  });
}
