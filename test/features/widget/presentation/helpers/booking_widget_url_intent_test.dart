import 'package:flutter_test/flutter_test.dart';

import 'package:bookbed/features/widget/presentation/helpers/booking_widget_url_intent.dart';

void main() {
  // Canonical fixtures that pass the strict validation regexes.
  const ref = 'BK-A3F7E2D1B9C4'; // valid BK- + 12 alphanumeric
  const bookingId = 'aBcDeFgHiJkLmNoPqRsT'; // 20 alphanumeric
  const sessionId = 'cs_test_a1b2c3d4e5f6';

  group('FreshLoad', () {
    test('returned when URL has no booking parameters', () {
      final intent = parseInitialUrlIntent(
        Uri.parse('https://view.bookbed.io/?property=ABC&unit=XYZ'),
      );
      expect(intent, isA<FreshLoad>());
    });

    test(
      'returned when stripe_status is success but session_id is missing',
      () {
        final intent = parseInitialUrlIntent(
          Uri.parse('https://view.bookbed.io/?stripe_status=success'),
        );
        expect(intent, isA<FreshLoad>());
      },
    );

    test(
      'returned when stripe_status is success but session_id is malformed',
      () {
        final intent = parseInitialUrlIntent(
          Uri.parse(
            'https://view.bookbed.io/?stripe_status=success&session_id=garbage',
          ),
        );
        expect(intent, isA<FreshLoad>());
      },
    );

    test(
      'returned when booking_status=success but confirmation is missing',
      () {
        final intent = parseInitialUrlIntent(
          Uri.parse('https://view.bookbed.io/?booking_status=success'),
        );
        expect(intent, isA<FreshLoad>());
      },
    );

    test('returned when confirmation is malformed (wrong prefix)', () {
      final intent = parseInitialUrlIntent(
        Uri.parse(
          'https://view.bookbed.io/?confirmation=XK-INVALID12CH&bookingId=$bookingId&payment=stripe',
        ),
      );
      expect(intent, isA<FreshLoad>());
    });

    test('returned when bookingId is malformed (wrong length)', () {
      final intent = parseInitialUrlIntent(
        Uri.parse(
          'https://view.bookbed.io/?confirmation=$ref&bookingId=short&payment=stripe',
        ),
      );
      expect(intent, isA<FreshLoad>());
    });
  });

  group('StripeReturnSession', () {
    test('returned for valid session_id + stripe_status=success', () {
      final intent = parseInitialUrlIntent(
        Uri.parse(
          'https://view.bookbed.io/?stripe_status=success&session_id=$sessionId',
        ),
      );
      expect(intent, isA<StripeReturnSession>());
      expect((intent as StripeReturnSession).sessionId, sessionId);
    });

    test('NOT returned when legacy params also present (legacy wins)', () {
      final intent = parseInitialUrlIntent(
        Uri.parse(
          'https://view.bookbed.io/?stripe_status=success&session_id=$sessionId&confirmation=$ref&bookingId=$bookingId',
        ),
      );
      expect(intent, isA<LegacyStripeReturn>());
    });
  });

  group('LegacyStripeReturn', () {
    test('returned for valid confirmation + bookingId + payment=stripe', () {
      final intent = parseInitialUrlIntent(
        Uri.parse(
          'https://view.bookbed.io/?confirmation=$ref&bookingId=$bookingId&payment=stripe',
        ),
      );
      expect(intent, isA<LegacyStripeReturn>());
      final legacy = intent as LegacyStripeReturn;
      expect(legacy.confirmationRef, ref);
      expect(legacy.bookingId, bookingId);
      expect(legacy.paymentType, 'stripe');
    });

    test(
      'returned for valid confirmation + bookingId + stripe_status=success',
      () {
        final intent = parseInitialUrlIntent(
          Uri.parse(
            'https://view.bookbed.io/?confirmation=$ref&bookingId=$bookingId&stripe_status=success',
          ),
        );
        expect(intent, isA<LegacyStripeReturn>());
        expect((intent as LegacyStripeReturn).paymentType, isNull);
      },
    );

    test('rejected when payment != stripe and stripe_status != success', () {
      final intent = parseInitialUrlIntent(
        Uri.parse(
          'https://view.bookbed.io/?confirmation=$ref&bookingId=$bookingId&payment=cash',
        ),
      );
      expect(intent, isA<FreshLoad>());
    });
  });

  group('DirectBookingReturn', () {
    test(
      'returned for booking_status=success + valid confirmation + bookingId',
      () {
        final intent = parseInitialUrlIntent(
          Uri.parse(
            'https://view.bookbed.io/?booking_status=success&confirmation=$ref&bookingId=$bookingId&payment=cash',
          ),
        );
        expect(intent, isA<DirectBookingReturn>());
        final direct = intent as DirectBookingReturn;
        expect(direct.confirmationRef, ref);
        expect(direct.bookingId, bookingId);
        expect(direct.paymentType, 'cash');
      },
    );

    test('NOT returned when legacy stripe params present (legacy wins)', () {
      final intent = parseInitialUrlIntent(
        Uri.parse(
          'https://view.bookbed.io/?booking_status=success&confirmation=$ref&bookingId=$bookingId&payment=stripe',
        ),
      );
      expect(intent, isA<LegacyStripeReturn>());
    });
  });

  group('priority resolution', () {
    test('LegacyStripeReturn beats StripeReturnSession when both eligible', () {
      final intent = parseInitialUrlIntent(
        Uri.parse(
          'https://view.bookbed.io/?stripe_status=success&session_id=$sessionId&confirmation=$ref&bookingId=$bookingId',
        ),
      );
      expect(intent, isA<LegacyStripeReturn>());
    });

    test('LegacyStripeReturn beats DirectBookingReturn when both eligible', () {
      final intent = parseInitialUrlIntent(
        Uri.parse(
          'https://view.bookbed.io/?booking_status=success&confirmation=$ref&bookingId=$bookingId&payment=stripe',
        ),
      );
      expect(intent, isA<LegacyStripeReturn>());
    });

    test('exhaustive switch on returned intent compiles', () {
      final intent = parseInitialUrlIntent(
        Uri.parse('https://view.bookbed.io/'),
      );
      final tag = switch (intent) {
        FreshLoad() => 'fresh',
        StripeReturnSession() => 'stripe-session',
        LegacyStripeReturn() => 'legacy',
        DirectBookingReturn() => 'direct',
      };
      expect(tag, 'fresh');
    });
  });
}
