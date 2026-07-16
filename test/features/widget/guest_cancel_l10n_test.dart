// Guards the guest-cancel snackbar against re-adopting the server's English
// prose. `guestCancelBooking` returns an English-only `message` (it serves logs
// and API clients); the /view screen used to echo it verbatim, so a Croatian
// guest saw an English sentence while the translated string sat unused.
//
// The CF also returns a machine-readable `reason` — THAT is what the client
// localizes off. Same shape as #935's errorCode.
//
// Source scan, not a widget pump: the screen needs Firebase + a booking model
// to build, and the contract worth pinning is "which expression feeds the
// snackbar", which is readable from the source.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const screen =
      'lib/features/widget/presentation/screens/booking_details_screen.dart';

  group('guest cancel — localized, not server prose', () {
    late String src;

    setUpAll(() => src = File(screen).readAsStringSync());

    test('success snackbar does not echo the server message', () {
      expect(
        src.contains("data['message'] ?? tr.bookingCancelledSuccessfully"),
        isFalse,
        reason:
            'the server message is English-only; the ?? fallback never fired',
      );
      expect(src.contains('tr.bookingCancelledSuccessfully'), isTrue);
    });

    test('rejection snackbar localizes off reason, not the server message', () {
      expect(
        src.contains("data['message']?.toString() ??"),
        isFalse,
        reason: 'echoing the server message shows English to every locale',
      );
      expect(src.contains("data['reason'] == 'guest_cancel_disabled'"), isTrue);
      expect(src.contains('tr.errorGuestCancelDisabled'), isTrue);
    });
  });

  test('errorGuestCancelDisabled is translated into all 4 languages', () {
    final src = File(
      'lib/features/widget/presentation/l10n/widget_translations.dart',
    ).readAsStringSync();
    final start = src.indexOf('String get errorGuestCancelDisabled');
    expect(start, greaterThan(-1), reason: 'string must exist');
    final body = src.substring(start, start + 900);
    for (final lang in ["case 'hr'", "case 'de'", "case 'it'"]) {
      expect(body.contains(lang), isTrue, reason: 'missing $lang');
    }
    expect(
      body.contains("case 'en'") || body.contains('default:'),
      isTrue,
      reason: 'missing en/default',
    );
  });
}
