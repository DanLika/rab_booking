// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/domain/models/settings/payment/bank_transfer_config.dart';
import 'package:bookbed/core/utils/nullable.dart';

void main() {
  group('BankTransferConfig', () {
    group('constructor', () {
      test('creates with default values', () {
        const config = BankTransferConfig();

        expect(config.enabled, false);
        expect(config.depositPercentage, 20);
        expect(config.ownerId, isNull);
        expect(config.paymentDeadlineDays, 3);
        expect(config.enableQrCode, true);
        expect(config.customNotes, isNull);
        expect(config.useCustomNotes, false);
      });
    });

    group('copyWith with Nullable wrapper', () {
      test('updates ownerId to new value', () {
        const original = BankTransferConfig(ownerId: 'old_owner');

        final updated = original.copyWith(
          ownerId: const Nullable('new_owner'),
        );

        expect(updated.ownerId, 'new_owner');
      });

      test('explicitly sets ownerId to null', () {
        const original = BankTransferConfig(ownerId: 'existing_owner');

        final updated = original.copyWith(
          ownerId: const Nullable(null),
        );

        expect(updated.ownerId, isNull);
      });

      test('preserves ownerId when not specified', () {
        const original = BankTransferConfig(ownerId: 'preserved_owner');

        final updated = original.copyWith(enabled: true);

        expect(updated.ownerId, 'preserved_owner');
        expect(updated.enabled, true);
      });

      test('explicitly sets customNotes to null', () {
        const original = BankTransferConfig(customNotes: 'Some notes');

        final updated = original.copyWith(
          customNotes: const Nullable(null),
        );

        expect(updated.customNotes, isNull);
      });

      test('updates bankName (legacy field) to null', () {
        const original = BankTransferConfig(bankName: 'Old Bank');

        final updated = original.copyWith(
          bankName: const Nullable(null),
        );

        expect(updated.bankName, isNull);
      });

      test('updates multiple nullable fields at once', () {
        const original = BankTransferConfig(
          ownerId: 'owner1',
          customNotes: 'notes',
          iban: 'HR12345',
        );

        final updated = original.copyWith(
          ownerId: const Nullable('owner2'),
          customNotes: const Nullable(null),
          iban: const Nullable('HR67890'),
        );

        expect(updated.ownerId, 'owner2');
        expect(updated.customNotes, isNull);
        expect(updated.iban, 'HR67890');
      });

      test('uses Nullable.nil() for explicit null', () {
        const original = BankTransferConfig(ownerId: 'owner');

        final updated = original.copyWith(
          ownerId: const Nullable.nil(),
        );

        expect(updated.ownerId, isNull);
      });
    });

    group('hasOwnerId', () {
      test('returns false when ownerId is null', () {
        const config = BankTransferConfig(ownerId: null);

        expect(config.hasOwnerId, false);
      });

      test('returns false when ownerId is empty', () {
        const config = BankTransferConfig(ownerId: '');

        expect(config.hasOwnerId, false);
      });

      test('returns true when ownerId has value', () {
        const config = BankTransferConfig(ownerId: 'user_123');

        expect(config.hasOwnerId, true);
      });
    });

    group('hasLegacyBankDetails', () {
      test('returns true with complete legacy fields', () {
        const config = BankTransferConfig(
          bankName: 'Test Bank',
          accountHolder: 'John Doe',
          iban: 'HR1234567890123456789',
        );

        expect(config.hasLegacyBankDetails, true);
      });

      test('returns false with missing bankName', () {
        const config = BankTransferConfig(
          accountHolder: 'John Doe',
          iban: 'HR1234567890123456789',
        );

        expect(config.hasLegacyBankDetails, false);
      });
    });
  });
}
