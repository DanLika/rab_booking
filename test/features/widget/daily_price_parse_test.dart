// Locks the fail-OPEN calendar bug found during the 2026-07-13 PROD widget
// E2E: the four calendar streams hard-skipped any `daily_prices` doc missing
// `unit_id`, and dropped any doc whose model parse threw (e.g. no
// `created_at`). Both paths discarded the doc's `available: false`, so an
// owner-blocked day rendered GREEN/available — the guest could select it and
// only hit the wall at submit, where atomicBooking rejects it with
// "Date … is not available for booking."
//
// A block must survive a malformed doc: fail CLOSED, not open.

import 'package:bookbed/features/widget/data/repositories/firebase_booking_calendar_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

const _unitId = 'unit-123';
final _date = Timestamp.fromDate(DateTime.utc(2026, 9, 20));

void main() {
  test('well-formed doc parses, block preserved', () {
    final price = parseDailyPriceDoc(
      {
        'date': _date,
        'unit_id': _unitId,
        'price': 150,
        'available': false,
        'created_at': _date,
        'updated_at': _date,
      },
      '2026-09-20',
      unitId: _unitId,
    );

    expect(price, isNotNull);
    expect(price!.available, isFalse);
    expect(price.price, 150);
    // TimestampConverter hands back a local DateTime; compare the instant.
    expect(price.date.toUtc(), DateTime.utc(2026, 9, 20));
  });

  test(
    'missing unit_id no longer drops the doc — backfilled from the query',
    () {
      final price = parseDailyPriceDoc(
        {'date': _date, 'price': 150, 'available': false, 'created_at': _date},
        '2026-09-20',
        unitId: _unitId,
      );

      expect(price, isNotNull, reason: 'block must not be silently discarded');
      expect(price!.unitId, _unitId);
      expect(price.available, isFalse);
    },
  );

  test('missing created_at no longer drops the doc', () {
    final price = parseDailyPriceDoc(
      {'date': _date, 'unit_id': _unitId, 'price': 150, 'available': false},
      '2026-09-20',
      unitId: _unitId,
    );

    expect(price, isNotNull);
    expect(price!.available, isFalse);
  });

  test('unparseable doc still yields the block when available is false', () {
    // `price` is the wrong type — fromJson throws; the block must survive.
    final price = parseDailyPriceDoc(
      {
        'date': _date,
        'unit_id': _unitId,
        'price': 'not-a-number',
        'available': false,
      },
      '2026-09-20',
      unitId: _unitId,
    );

    expect(price, isNotNull);
    expect(price!.available, isFalse);
    expect(price.price, 0, reason: 'unusable price degrades to 0, not to open');
  });

  test('unparseable doc with no block yields null (day stays available)', () {
    final price = parseDailyPriceDoc(
      {'date': _date, 'unit_id': _unitId, 'price': 'not-a-number'},
      '2026-09-20',
      unitId: _unitId,
    );

    expect(price, isNull);
  });

  test('doc without a usable date yields null — it addresses no cell', () {
    expect(
      parseDailyPriceDoc(
        {'unit_id': _unitId, 'price': 150, 'available': false},
        'garbage',
        unitId: _unitId,
      ),
      isNull,
    );
    expect(
      parseDailyPriceDoc(
        {'date': '2026-09-20', 'unit_id': _unitId, 'available': false},
        '2026-09-20',
        unitId: _unitId,
      ),
      isNull,
      reason: 'a String date is not a Timestamp',
    );
  });

  test('available:true doc parses normally (regression guard)', () {
    final price = parseDailyPriceDoc(
      {
        'date': _date,
        'unit_id': _unitId,
        'price': 200,
        'available': true,
        'created_at': _date,
      },
      '2026-09-20',
      unitId: _unitId,
    );

    expect(price!.available, isTrue);
    expect(price.price, 200);
  });
}
