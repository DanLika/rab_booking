// Guards the Croatian guest/night pluralization fix (2026-07-13): the owner
// bookings card hardcoded "N gosta" for every count, so a single-guest booking
// read "1 gosta" (should be "1 gost") and a five-guest one "5 gosta" (should be
// "5 gostiju").

import 'package:bookbed/features/owner_dashboard/presentation/widgets/bookings/croatian_plural.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('guestWord', () {
    test('one form for 1, 21, 31 (n%10==1, not teens)', () {
      expect(guestWord(1), 'gost');
      expect(guestWord(21), 'gost');
      expect(guestWord(101), 'gost');
    });

    test('paucal form for 2–4, 22–24', () {
      for (final n in [2, 3, 4, 22, 33, 104]) {
        expect(guestWord(n), 'gosta', reason: 'n=$n');
      }
    });

    test('many form for 0, 5–20, teens, 25+', () {
      for (final n in [0, 5, 6, 10, 11, 12, 13, 14, 15, 20, 25, 111]) {
        expect(guestWord(n), 'gostiju', reason: 'n=$n');
      }
    });
  });

  group('nightWord', () {
    test('one form ("noć") for 1 and 1-ending non-teens (21, 31)', () {
      expect(nightWord(1), 'noć');
      expect(nightWord(21), 'noć');
    });
    test('"noći" for paucal and many alike', () {
      for (final n in [2, 3, 5, 7, 11, 22]) {
        expect(nightWord(n), 'noći', reason: 'n=$n');
      }
    });
  });
}
