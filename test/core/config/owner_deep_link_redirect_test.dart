// Guards the owner deep-link bounce.
//
// On a cold boot the auth listener has not restored the session yet, so opening
// a protected deep link (a bookmark, or a notification/email pointing at a
// booking) hits the router while `isAuthenticated` is still false. The router
// bounces to /login — and used to DROP the requested location, so once auth came
// back the owner was silently dumped on the overview instead of the page they
// asked for.
//
// The fix carries the target in `?from=`, and `safeInternalPath` decides whether
// it may be honoured. These cells pin that decision, including the open-redirect
// vectors an attacker could stuff into `from` (a login link is user-supplied
// input: `/#/login?from=https://evil.com`).

import 'package:bookbed/core/config/router_owner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('safeInternalPath — honoured targets', () {
    test('plain protected route survives the bounce', () {
      expect(safeInternalPath('/owner/bookings'), '/owner/bookings');
    });

    test('route with query params survives (e.g. a booking deep link)', () {
      expect(
        safeInternalPath('/owner/bookings?bookingId=abc123'),
        '/owner/bookings?bookingId=abc123',
      );
    });

    test('nested route survives', () {
      expect(safeInternalPath('/owner/unit-hub'), '/owner/unit-hub');
    });
  });

  group('safeInternalPath — refused (open-redirect vectors)', () {
    test('absolute URL is refused', () {
      expect(safeInternalPath('https://evil.com/steal'), isNull);
    });

    test('protocol-relative URL is refused', () {
      // `//evil.com` is a protocol-relative URL — the browser would leave the app.
      expect(safeInternalPath('//evil.com/steal'), isNull);
    });

    test('scheme-bearing target is refused', () {
      expect(safeInternalPath('javascript:alert(1)'), isNull);
    });

    test('path not starting with / is refused', () {
      expect(safeInternalPath('owner/bookings'), isNull);
    });
  });

  group('safeInternalPath — refused (loop guards / empty)', () {
    test('login target is refused (would bounce forever)', () {
      expect(safeInternalPath('/login'), isNull);
    });

    test('register target is refused', () {
      expect(safeInternalPath('/register'), isNull);
    });

    test('null falls back to the caller default', () {
      expect(safeInternalPath(null), isNull);
    });

    test('empty string falls back to the caller default', () {
      expect(safeInternalPath(''), isNull);
    });
  });
}
