// ignore_for_file: avoid_redundant_argument_values, prefer_const_constructors
// Note: Explicit default values kept in tests for documentation clarity
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/domain/models/settings/booking_behavior_config.dart';
import 'package:bookbed/features/widget/domain/constants/widget_constants.dart';

void main() {
  group('BookingBehaviorConfig', () {
    group('constructor', () {
      test('creates with default values', () {
        const config = BookingBehaviorConfig();

        expect(config.requireOwnerApproval, false);
        expect(config.allowGuestCancellation, true);
        expect(config.cancellationDeadlineHours, 48);
        expect(config.minNights, WidgetConstants.defaultMinStayNights);
        expect(config.maxNights, null);
        expect(config.weekendDays, WidgetConstants.defaultWeekendDays);
        expect(config.minDaysAdvance, WidgetConstants.defaultMinDaysAdvance);
        expect(config.maxDaysAdvance, WidgetConstants.defaultMaxDaysAdvance);
      });

      test('creates with custom values', () {
        final config = BookingBehaviorConfig(
          requireOwnerApproval: true,
          allowGuestCancellation: false,
          cancellationDeadlineHours: 24,
          minNights: 3,
          maxNights: 14,
          weekendDays: [5, 6], // Friday, Saturday
          minDaysAdvance: 2,
          maxDaysAdvance: 180,
        );

        expect(config.requireOwnerApproval, true);
        expect(config.allowGuestCancellation, false);
        expect(config.cancellationDeadlineHours, 24);
        expect(config.minNights, 3);
        expect(config.maxNights, 14);
        expect(config.weekendDays, [5, 6]);
        expect(config.minDaysAdvance, 2);
        expect(config.maxDaysAdvance, 180);
      });
    });

    group('fromMap', () {
      test('parses complete map correctly', () {
        final map = {
          'require_owner_approval': true,
          'allow_guest_cancellation': false,
          'cancellation_deadline_hours': 72,
          'min_nights': 2,
          'max_nights': 7,
          'weekend_days': [5, 6, 7],
          'min_days_advance': 1,
          'max_days_advance': 90,
        };

        final config = BookingBehaviorConfig.fromMap(map);

        expect(config.requireOwnerApproval, true);
        expect(config.allowGuestCancellation, false);
        expect(config.cancellationDeadlineHours, 72);
        expect(config.minNights, 2);
        expect(config.maxNights, 7);
        expect(config.weekendDays, [5, 6, 7]);
        expect(config.minDaysAdvance, 1);
        expect(config.maxDaysAdvance, 90);
      });

      test('uses defaults for missing fields', () {
        final config = BookingBehaviorConfig.fromMap({});

        expect(config.requireOwnerApproval, false);
        expect(config.allowGuestCancellation, true);
        expect(config.cancellationDeadlineHours, 48);
        expect(config.minNights, WidgetConstants.defaultMinStayNights);
        expect(config.maxNights, null);
        expect(config.weekendDays, WidgetConstants.defaultWeekendDays);
      });

      test('preserves explicit null for cancellationDeadlineHours', () {
        final map = {
          'cancellation_deadline_hours': null,
        };

        final config = BookingBehaviorConfig.fromMap(map);

        // When explicitly set to null in Firestore, should be null (no deadline)
        expect(config.cancellationDeadlineHours, isNull);
      });

      test('uses default when cancellationDeadlineHours key is missing', () {
        final map = <String, dynamic>{};

        final config = BookingBehaviorConfig.fromMap(map);

        // When key doesn't exist, use default value of 48
        expect(config.cancellationDeadlineHours, 48);
      });

      test('clamps negative minDaysAdvance to 0', () {
        final map = {'min_days_advance': -5};

        final config = BookingBehaviorConfig.fromMap(map);

        expect(config.minDaysAdvance, 0);
      });

      test('clamps negative maxDaysAdvance to 0', () {
        final map = {'max_days_advance': -10};

        final config = BookingBehaviorConfig.fromMap(map);

        expect(config.maxDaysAdvance, 0);
      });

      test('clamps minDaysAdvance to max 365', () {
        final map = {'min_days_advance': 500};

        final config = BookingBehaviorConfig.fromMap(map);

        expect(config.minDaysAdvance, 365);
      });

      test('clamps maxDaysAdvance to max 730', () {
        final map = {'max_days_advance': 1000};

        final config = BookingBehaviorConfig.fromMap(map);

        expect(config.maxDaysAdvance, 730);
      });

      test('clamps minNights to minimum 1', () {
        final map = {'min_nights': 0};

        final config = BookingBehaviorConfig.fromMap(map);

        expect(config.minNights, 1);
      });
    });

    group('isValidConfig', () {
      test('returns true for valid configuration', () {
        const config = BookingBehaviorConfig(
          minNights: 1,
          maxNights: 7,
          minDaysAdvance: 0,
          maxDaysAdvance: 365,
        );

        expect(config.isValidConfig, true);
      });

      test('returns false when maxNights is less than minNights', () {
        const config = BookingBehaviorConfig(
          minNights: 5,
          maxNights: 3,
        );

        expect(config.isValidConfig, false);
      });

      test('returns true when maxNights is null (no limit)', () {
        const config = BookingBehaviorConfig(
          minNights: 5,
          maxNights: null,
        );

        expect(config.isValidConfig, true);
      });

      test('returns true when maxNights is 0 (no limit)', () {
        const config = BookingBehaviorConfig(
          minNights: 5,
          maxNights: 0,
        );

        expect(config.isValidConfig, true);
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final config = BookingBehaviorConfig(
          requireOwnerApproval: true,
          allowGuestCancellation: false,
          cancellationDeadlineHours: 24,
          minNights: 2,
          maxNights: 10,
          weekendDays: [6, 7],
          minDaysAdvance: 1,
          maxDaysAdvance: 365,
        );

        final map = config.toMap();

        expect(map['require_owner_approval'], true);
        expect(map['allow_guest_cancellation'], false);
        expect(map['cancellation_deadline_hours'], 24);
        expect(map['min_nights'], 2);
        expect(map['max_nights'], 10);
        expect(map['weekend_days'], [6, 7]);
        expect(map['min_days_advance'], 1);
        expect(map['max_days_advance'], 365);
      });
    });

    group('isValidDuration', () {
      test('returns true for valid duration within range', () {
        final config = BookingBehaviorConfig(
          minNights: 2,
          maxNights: 7,
        );

        expect(config.isValidDuration(2), true);
        expect(config.isValidDuration(5), true);
        expect(config.isValidDuration(7), true);
      });

      test('returns false for duration below minimum', () {
        final config = BookingBehaviorConfig(
          minNights: 3,
        );

        expect(config.isValidDuration(1), false);
        expect(config.isValidDuration(2), false);
      });

      test('returns false for duration above maximum', () {
        final config = BookingBehaviorConfig(
          minNights: 1,
          maxNights: 5,
        );

        expect(config.isValidDuration(6), false);
        expect(config.isValidDuration(10), false);
      });

      test('allows any duration when maxNights is null', () {
        final config = BookingBehaviorConfig(
          minNights: 1,
          maxNights: null,
        );

        expect(config.isValidDuration(100), true);
        expect(config.isValidDuration(365), true);
      });

      test('allows any duration when maxNights is 0', () {
        final config = BookingBehaviorConfig(
          minNights: 1,
          maxNights: 0,
        );

        expect(config.isValidDuration(100), true);
      });
    });

    group('isWeekend', () {
      test('correctly identifies weekend days with default [6, 7]', () {
        const config = BookingBehaviorConfig();

        // Saturday = 6, Sunday = 7
        expect(config.isWeekend(DateTime(2024, 1, 6)), true); // Saturday
        expect(config.isWeekend(DateTime(2024, 1, 7)), true); // Sunday
        expect(config.isWeekend(DateTime(2024, 1, 8)), false); // Monday
        expect(config.isWeekend(DateTime(2024, 1, 12)), false); // Friday
      });

      test('correctly identifies custom weekend days', () {
        final config = BookingBehaviorConfig(
          weekendDays: [5, 6], // Friday, Saturday
        );

        expect(config.isWeekend(DateTime(2024, 1, 5)), true); // Friday
        expect(config.isWeekend(DateTime(2024, 1, 6)), true); // Saturday
        expect(config.isWeekend(DateTime(2024, 1, 7)), false); // Sunday
      });
    });

    group('isValidAdvanceNotice', () {
      test('returns true for valid advance notice', () {
        final config = BookingBehaviorConfig(
          minDaysAdvance: 1,
          maxDaysAdvance: 90,
        );

        expect(config.isValidAdvanceNotice(1), true);
        expect(config.isValidAdvanceNotice(45), true);
        expect(config.isValidAdvanceNotice(90), true);
      });

      test('returns false for too short advance notice', () {
        final config = BookingBehaviorConfig(
          minDaysAdvance: 3,
        );

        expect(config.isValidAdvanceNotice(0), false);
        expect(config.isValidAdvanceNotice(2), false);
      });

      test('returns false for too long advance notice', () {
        final config = BookingBehaviorConfig(
          maxDaysAdvance: 30,
        );

        expect(config.isValidAdvanceNotice(31), false);
        expect(config.isValidAdvanceNotice(100), false);
      });

      test('allows any advance when maxDaysAdvance is 0', () {
        final config = BookingBehaviorConfig(
          minDaysAdvance: 0,
          maxDaysAdvance: 0,
        );

        expect(config.isValidAdvanceNotice(365), true);
        expect(config.isValidAdvanceNotice(1000), true);
      });
    });

    group('canCancelForCheckIn', () {
      test('returns false when cancellation not allowed', () {
        final config = BookingBehaviorConfig(
          allowGuestCancellation: false,
        );

        final futureCheckIn = DateTime.now().add(const Duration(days: 30));
        expect(config.canCancelForCheckIn(futureCheckIn), false);
      });

      test('returns true when no deadline set', () {
        final config = BookingBehaviorConfig(
          allowGuestCancellation: true,
          cancellationDeadlineHours: null,
        );

        final nearCheckIn = DateTime.now().add(const Duration(hours: 1));
        expect(config.canCancelForCheckIn(nearCheckIn), true);
      });

      test('returns true when before deadline', () {
        final config = BookingBehaviorConfig(
          allowGuestCancellation: true,
          cancellationDeadlineHours: 48,
        );

        final farCheckIn = DateTime.now().add(const Duration(hours: 72));
        expect(config.canCancelForCheckIn(farCheckIn), true);
      });

      test('returns false when after deadline', () {
        final config = BookingBehaviorConfig(
          allowGuestCancellation: true,
          cancellationDeadlineHours: 48,
        );

        final nearCheckIn = DateTime.now().add(const Duration(hours: 24));
        expect(config.canCancelForCheckIn(nearCheckIn), false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        const original = BookingBehaviorConfig(
          minNights: 1,
          maxNights: 7,
        );

        final copy = original.copyWith(
          minNights: 3,
          requireOwnerApproval: true,
        );

        expect(copy.minNights, 3);
        expect(copy.maxNights, 7); // unchanged
        expect(copy.requireOwnerApproval, true);
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        const config1 = BookingBehaviorConfig(minNights: 2);
        const config2 = BookingBehaviorConfig(minNights: 2);

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('different configs are not equal', () {
        const config1 = BookingBehaviorConfig(minNights: 2);
        const config2 = BookingBehaviorConfig(minNights: 3);

        expect(config1, isNot(equals(config2)));
      });
    });
  });
}
