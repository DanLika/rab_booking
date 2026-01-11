import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed_app/features/subscription/models/trial_status.dart';

void main() {
  group('TrialStatus Tests', () {
    test('newUser factory creates trial with 30 days expiry', () {
      final status = TrialStatus.newUser();

      expect(status.accountStatus, AccountStatus.trial);
      expect(status.trialStartDate, isNotNull);
      expect(status.trialExpiresAt, isNotNull);

      final diff = status.trialExpiresAt!.difference(status.trialStartDate!).inDays;
      expect(diff, 30);
    });

    test('isInTrial returns true for trial status', () {
      final status = const TrialStatus(accountStatus: AccountStatus.trial);
      expect(status.isInTrial, isTrue);
    });

    test('daysRemaining calculation works correctly with reference date', () {
      final now = DateTime(2023, 1, 1);
      final expiry = DateTime(2023, 1, 6); // 5 days later

      final status = TrialStatus(
        accountStatus: AccountStatus.trial,
        trialExpiresAt: expiry,
      );

      // Using the new method we will implement
      expect(status.getDaysRemaining(now: now), 5);
    });

    test('daysRemaining returns 0 if expired', () {
      final now = DateTime(2023, 1, 10);
      final expiry = DateTime(2023, 1, 1); // Past

      final status = TrialStatus(
        accountStatus: AccountStatus.trial,
        trialExpiresAt: expiry,
      );

      expect(status.getDaysRemaining(now: now), 0);
    });

    test('isExpiringSoon returns true when remaining <= 7', () {
      final now = DateTime(2023, 1, 1);
      final expiry = DateTime(2023, 1, 4); // 3 days left

      final status = TrialStatus(
        accountStatus: AccountStatus.trial,
        trialExpiresAt: expiry,
      );

      // Check logic manually since isExpiringSoon uses daysRemaining which uses Now
      // We will need to update isExpiringSoon to use reference date too
      // For this test, we construct it such that real DateTime.now() works?
      // No, that's flaky. We will rely on our refactoring.
      expect(status.isExpiringSoonInternal(now: now), isTrue);
    });

    test('statusText returns correct message', () {
      final now = DateTime(2023, 1, 1);
      final expiry = DateTime(2023, 1, 2); // 1 day left

      final status = TrialStatus(
        accountStatus: AccountStatus.trial,
        trialExpiresAt: expiry,
      );

      expect(status.getStatusText(now: now), '1 day left in trial');
    });
  });
}
