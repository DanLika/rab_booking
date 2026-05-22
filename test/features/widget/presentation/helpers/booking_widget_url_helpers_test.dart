import 'package:flutter_test/flutter_test.dart';

import 'package:bookbed/features/widget/presentation/helpers/booking_widget_url_helpers.dart';

void main() {
  group('sanitizeId', () {
    test('returns null when input is null', () {
      expect(sanitizeId(null), isNull);
    });

    test('returns empty string when input is empty', () {
      expect(sanitizeId(''), '');
    });

    test('returns input unchanged when no slash present', () {
      expect(sanitizeId('abc123'), 'abc123');
    });

    test('strips trailing path segment after first slash', () {
      expect(sanitizeId('abc123/calendar'), 'abc123');
    });

    test('strips multiple path segments after first slash', () {
      expect(sanitizeId('abc123/calendar/extra/segments'), 'abc123');
    });

    test('preserves leading slash by returning input unchanged', () {
      // indexOf > 0 — a leading slash at index 0 is not stripped
      expect(sanitizeId('/abc'), '/abc');
    });
  });

  group('isValidBookingReference', () {
    test('rejects null', () => expect(isValidBookingReference(null), isFalse));
    test('rejects empty', () => expect(isValidBookingReference(''), isFalse));

    test('accepts canonical uppercase reference', () {
      expect(isValidBookingReference('BK-A3F7E2D1B9C4'), isTrue);
    });

    test('accepts mixed-case reference', () {
      expect(isValidBookingReference('BK-a3f7E2d1B9c4'), isTrue);
    });

    test('rejects wrong prefix', () {
      expect(isValidBookingReference('XK-A3F7E2D1B9C4'), isFalse);
    });

    test('rejects 11-char suffix (too short)', () {
      expect(isValidBookingReference('BK-A3F7E2D1B9C'), isFalse);
    });

    test('rejects 13-char suffix (too long)', () {
      expect(isValidBookingReference('BK-A3F7E2D1B9C4A'), isFalse);
    });

    test('rejects non-alphanumeric in suffix', () {
      expect(isValidBookingReference('BK-A3F7E2D1B9-4'), isFalse);
    });
  });

  group('isValidFirestoreId', () {
    test('rejects null', () => expect(isValidFirestoreId(null), isFalse));
    test('rejects empty', () => expect(isValidFirestoreId(''), isFalse));

    test('accepts canonical 20-char alphanumeric ID', () {
      expect(isValidFirestoreId('aBcDeFgHiJkLmNoPqRsT'), isTrue);
    });

    test('rejects 19-char ID', () {
      expect(isValidFirestoreId('aBcDeFgHiJkLmNoPqRs'), isFalse);
    });

    test('rejects 21-char ID', () {
      expect(isValidFirestoreId('aBcDeFgHiJkLmNoPqRsTu'), isFalse);
    });

    test('rejects ID containing hyphen', () {
      expect(isValidFirestoreId('aBcDeFgHiJ-LmNoPqRsT'), isFalse);
    });

    test('rejects ID containing underscore', () {
      expect(isValidFirestoreId('aBcDeFgHiJ_LmNoPqRsT'), isFalse);
    });
  });

  group('isValidStripeSessionId', () {
    test('rejects null', () => expect(isValidStripeSessionId(null), isFalse));
    test('rejects empty', () => expect(isValidStripeSessionId(''), isFalse));

    test('accepts cs_test_ session id', () {
      expect(isValidStripeSessionId('cs_test_a1b2c3d4e5f6'), isTrue);
    });

    test('accepts cs_live_ session id', () {
      expect(isValidStripeSessionId('cs_live_a1b2c3d4e5f6'), isTrue);
    });

    test('rejects cs_other_ environment', () {
      expect(isValidStripeSessionId('cs_other_a1b2c3'), isFalse);
    });

    test('rejects unprefixed id', () {
      expect(isValidStripeSessionId('a1b2c3d4e5f6'), isFalse);
    });

    test('rejects cs_test_ with empty body', () {
      expect(isValidStripeSessionId('cs_test_'), isFalse);
    });

    test('rejects cs_test_ with non-alphanumeric body', () {
      expect(isValidStripeSessionId('cs_test_abc-def'), isFalse);
    });
  });

  group('safeErrorToString', () {
    test('returns sentinel for null', () {
      expect(safeErrorToString(null), 'Unknown error');
    });

    test('returns toString() result for plain object', () {
      expect(safeErrorToString('plain error message'), 'plain error message');
    });

    test('returns toString() result for Exception', () {
      expect(safeErrorToString(Exception('boom')), contains('boom'));
    });

    test('returns toString() result for int', () {
      expect(safeErrorToString(42), '42');
    });

    test('returns fallback when toString itself throws', () {
      expect(
        safeErrorToString(_ThrowingToString()),
        'Error: Unable to display error details',
      );
    });
  });
}

class _ThrowingToString {
  @override
  String toString() {
    throw Exception('toString threw');
  }
}
