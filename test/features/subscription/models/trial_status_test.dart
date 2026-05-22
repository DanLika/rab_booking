import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookbed/features/subscription/models/trial_status.dart';

void main() {
  group('AccountStatusExtension', () {
    test('value returns correct string', () {
      expect(AccountStatus.trial.value, 'trial');
      expect(AccountStatus.active.value, 'active');
      expect(AccountStatus.trialExpired.value, 'trial_expired');
      expect(AccountStatus.suspended.value, 'suspended');
    });

    test('fromString parses correctly', () {
      expect(AccountStatusExtension.fromString('trial'), AccountStatus.trial);
      expect(AccountStatusExtension.fromString('active'), AccountStatus.active);
      expect(
        AccountStatusExtension.fromString('trial_expired'),
        AccountStatus.trialExpired,
      );
      expect(
        AccountStatusExtension.fromString('suspended'),
        AccountStatus.suspended,
      );
    });

    test('fromString defaults to trial for unknown/null values', () {
      expect(AccountStatusExtension.fromString(null), AccountStatus.trial);
      expect(
        AccountStatusExtension.fromString('unknown_status'),
        AccountStatus.trial,
      );
    });
  });

  group('TrialStatus', () {
    final now = DateTime(2024, 1, 15);

    test('newUser factory sets correct defaults', () {
      final status = TrialStatus.newUser();

      expect(status.accountStatus, AccountStatus.trial);
      expect(status.trialStartDate, isNotNull);
      expect(status.trialExpiresAt, isNotNull);

      // Calculate diff and check it's approximately 30 days
      final duration = status.trialExpiresAt!.difference(
        status.trialStartDate!,
      );
      expect(duration.inDays, 30);
    });

    test('fromFirestore creates instance correctly', () {
      final startTimestamp = Timestamp.fromDate(DateTime.utc(2024));
      final endTimestamp = Timestamp.fromDate(DateTime.utc(2024, 1, 31));
      final changedTimestamp = Timestamp.fromDate(DateTime.utc(2024, 1, 2));

      final data = {
        'accountStatus': 'active',
        'trialStartDate': startTimestamp,
        'trialExpiresAt': endTimestamp,
        'statusChangedAt': changedTimestamp,
        'statusChangedBy': 'admin_123',
        'statusChangeReason': 'Payment processed',
      };

      final status = TrialStatus.fromFirestore(data);

      expect(status.accountStatus, AccountStatus.active);
      expect(status.trialStartDate, startTimestamp.toDate());
      expect(status.trialExpiresAt, endTimestamp.toDate());
      expect(status.statusChangedAt, changedTimestamp.toDate());
      expect(status.statusChangedBy, 'admin_123');
      expect(status.statusChangeReason, 'Payment processed');
    });

    test('fromFirestore handles null values', () {
      final status = TrialStatus.fromFirestore({});

      expect(
        status.accountStatus,
        AccountStatus.trial,
      ); // Default from Extension
      expect(status.trialStartDate, isNull);
      expect(status.trialExpiresAt, isNull);
      expect(status.statusChangedAt, isNull);
      expect(status.statusChangedBy, isNull);
      expect(status.statusChangeReason, isNull);
    });

    group('status getters', () {
      test('hasFullAccess is true for trial and active', () {
        expect(
          const TrialStatus(accountStatus: AccountStatus.trial).hasFullAccess,
          isTrue,
        );
        expect(
          const TrialStatus(accountStatus: AccountStatus.active).hasFullAccess,
          isTrue,
        );
        expect(
          const TrialStatus(
            accountStatus: AccountStatus.trialExpired,
          ).hasFullAccess,
          isFalse,
        );
        expect(
          const TrialStatus(
            accountStatus: AccountStatus.suspended,
          ).hasFullAccess,
          isFalse,
        );
      });

      test('isInTrial is true only for trial', () {
        expect(
          const TrialStatus(accountStatus: AccountStatus.trial).isInTrial,
          isTrue,
        );
        expect(
          const TrialStatus(accountStatus: AccountStatus.active).isInTrial,
          isFalse,
        );
      });

      test('isTrialExpired is true only for trialExpired', () {
        expect(
          const TrialStatus(
            accountStatus: AccountStatus.trialExpired,
          ).isTrialExpired,
          isTrue,
        );
        expect(
          const TrialStatus(accountStatus: AccountStatus.trial).isTrialExpired,
          isFalse,
        );
      });

      test('isSuspended is true only for suspended', () {
        expect(
          const TrialStatus(accountStatus: AccountStatus.suspended).isSuspended,
          isTrue,
        );
        expect(
          const TrialStatus(accountStatus: AccountStatus.active).isSuspended,
          isFalse,
        );
      });

      test('isActive is true only for active', () {
        expect(
          const TrialStatus(accountStatus: AccountStatus.active).isActive,
          isTrue,
        );
        expect(
          const TrialStatus(accountStatus: AccountStatus.trial).isActive,
          isFalse,
        );
      });
    });

    group('date calculations', () {
      test('getDaysRemaining returns correct days', () {
        final status = TrialStatus(
          accountStatus: AccountStatus.trial,
          trialExpiresAt: DateTime(2024, 1, 25), // 10 days from 'now'
        );

        expect(status.getDaysRemaining(now: now), 10);
      });

      test('getDaysRemaining returns 0 if expired', () {
        final status = TrialStatus(
          accountStatus: AccountStatus.trial,
          trialExpiresAt: DateTime(2024, 1, 10), // Past date
        );

        expect(status.getDaysRemaining(now: now), 0);
      });

      test('getDaysRemaining returns 0 if not in trial', () {
        final status = TrialStatus(
          accountStatus: AccountStatus.active,
          trialExpiresAt: DateTime(2024, 1, 25),
        );

        expect(status.getDaysRemaining(now: now), 0);
      });

      test('getDaysRemaining returns 0 if trialExpiresAt is null', () {
        final status = const TrialStatus(accountStatus: AccountStatus.trial);

        expect(status.getDaysRemaining(now: now), 0);
      });

      test('isExpiringSoonInternal returns true if 7 days or less', () {
        final status = TrialStatus(
          accountStatus: AccountStatus.trial,
          trialExpiresAt: DateTime(2024, 1, 20), // 5 days left
        );

        expect(status.isExpiringSoonInternal(now: now), isTrue);
      });

      test('isExpiringSoonInternal returns false if > 7 days', () {
        final status = TrialStatus(
          accountStatus: AccountStatus.trial,
          trialExpiresAt: DateTime(2024, 1, 25), // 10 days left
        );

        expect(status.isExpiringSoonInternal(now: now), isFalse);
      });

      test('isExpiringSoonInternal returns false if expired/0 days', () {
        final status = TrialStatus(
          accountStatus: AccountStatus.trial,
          trialExpiresAt: DateTime(2024, 1, 10), // Expired
        );

        expect(status.isExpiringSoonInternal(now: now), isFalse);
      });
    });

    group('getStatusText', () {
      test('returns correct text for trial ending today', () {
        final status = TrialStatus(
          accountStatus: AccountStatus.trial,
          trialExpiresAt: now,
        );
        expect(status.getStatusText(now: now), 'Trial ending today');
      });

      test('returns correct text for 1 day left', () {
        final status = TrialStatus(
          accountStatus: AccountStatus.trial,
          trialExpiresAt: now.add(const Duration(days: 1)),
        );
        expect(status.getStatusText(now: now), '1 day left in trial');
      });

      test('returns correct text for multiple days left', () {
        final status = TrialStatus(
          accountStatus: AccountStatus.trial,
          trialExpiresAt: now.add(const Duration(days: 5)),
        );
        expect(status.getStatusText(now: now), '5 days left in trial');
      });

      test('returns correct text for active subscription', () {
        expect(
          const TrialStatus(
            accountStatus: AccountStatus.active,
          ).getStatusText(),
          'Active subscription',
        );
      });

      test('returns correct text for expired trial', () {
        expect(
          const TrialStatus(
            accountStatus: AccountStatus.trialExpired,
          ).getStatusText(),
          'Trial expired',
        );
      });

      test('returns correct text for suspended account', () {
        expect(
          const TrialStatus(
            accountStatus: AccountStatus.suspended,
          ).getStatusText(),
          'Account suspended',
        );
      });
    });

    test('toString returns properly formatted string', () {
      final status = TrialStatus(
        accountStatus: AccountStatus.trial,
        trialExpiresAt: now.add(const Duration(days: 5)),
      );

      // We can't easily mock the 'now' used inside the toString's daysRemaining getter,
      // so we just verify the prefix
      expect(
        status.toString(),
        contains('TrialStatus(status: AccountStatus.trial, daysRemaining:'),
      );
    });
  });
}
