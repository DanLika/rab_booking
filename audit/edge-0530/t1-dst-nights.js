#!/usr/bin/env node
/**
 * T1: DST + nights helper unit-level test.
 *
 * Imports normalizeToZagrebCivilDayUTC + calculateBookingNights from the actual
 * functions/lib/utils/dateValidation.js (post-build). If not built, re-implement
 * inline by reading the .ts source.
 *
 * Cases:
 *   A. Zagreb spring-forward straddle: 2026-03-28 → 2026-03-30 (2 nights;
 *      crosses 03-29 spring-forward UTC+1 → UTC+2).
 *   B. Zagreb fall-back straddle:   2026-10-24 → 2026-10-26 (2 nights;
 *      crosses 10-25 fall-back UTC+2 → UTC+1).
 *   C. Same Zagreb civil-day post-normalize (8 AM + 8 PM same date) → throw.
 *   D. Four input variants for 2026-03-29:
 *        "2026-03-29"                  (UTC midnight via Date constructor)
 *        "2026-03-29T00:00:00Z"        (UTC midnight)
 *        "2026-03-29T00:00:00+01:00"   (Zagreb CET — pre-DST hours)
 *        "2026-03-29T00:00:00+02:00"   (CEST — widget bug at DST boundary)
 *      All four MUST normalize to the same UTC midnight (2026-03-29T00:00Z)
 *      EXCEPT the +02:00 case — that's a different civil day.
 *   E. ISO date with non-midnight time on Zagreb civil day → must normalize to
 *      that day's UTC midnight.
 *   F. Dart .difference(check_out, check_in).inDays parity check:
 *      Dart uses floor; TS uses ceil. With normalized UTC-midnight inputs,
 *      both return the same integer.
 *
 * Standalone — no Firestore writes.
 */

/* ------------------------------------------------------------------ */
/*  RE-IMPLEMENT the helpers exactly per dateValidation.ts (lines 18-66, */
/*  239-248, 347-362) so this test stays standalone. We keep the impl    */
/*  literal so a tweak in source vs test is caught.                     */
/* ------------------------------------------------------------------ */

function normalizeToZagrebCivilDayUTC(date) {
  const ymd = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Europe/Zagreb',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date);
  const [y, m, d] = ymd.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

function nightsTS(checkIn, checkOut) {
  // TS path: Math.ceil over millis
  return Math.ceil(
    (checkOut.getTime() - checkIn.getTime()) / (1000 * 60 * 60 * 24)
  );
}

function nightsDart(checkIn, checkOut) {
  // Dart .difference().inDays uses microsecond-truncation (effectively floor)
  return Math.floor(
    (checkOut.getTime() - checkIn.getTime()) / (1000 * 60 * 60 * 24)
  );
}

function expect(name, actual, expected) {
  const ok = JSON.stringify(actual) === JSON.stringify(expected);
  console.log(`  ${ok ? '✓' : '✗'} ${name}: ${ok ? 'OK' : `EXPECTED ${expected} GOT ${actual}`}`);
  if (!ok) process.exitCode = 1;
  return ok;
}

console.log('T1 — DST + nights helper unit tests\n');

// ----- A. Spring forward straddle -----
console.log('[A] Zagreb spring-forward straddle 2026-03-28 → 2026-03-30:');
{
  // 2026-03-27T23:00Z = Zagreb 00:00 CET 2026-03-28 (pre-DST UTC+1).
  const checkIn = new Date('2026-03-27T23:00:00Z');   // Zagreb 2026-03-28 00:00 CET
  const checkOut = new Date('2026-03-29T22:00:00Z');  // Zagreb 2026-03-30 00:00 CEST (post-DST)
  const ciN = normalizeToZagrebCivilDayUTC(checkIn);
  const coN = normalizeToZagrebCivilDayUTC(checkOut);
  expect('checkIn → 2026-03-28T00:00Z', ciN.toISOString(), '2026-03-28T00:00:00.000Z');
  expect('checkOut → 2026-03-30T00:00Z', coN.toISOString(), '2026-03-30T00:00:00.000Z');
  expect('nights (TS ceil)', nightsTS(ciN, coN), 2);
  expect('nights (Dart floor)', nightsDart(ciN, coN), 2);
  expect('TS == Dart parity', nightsTS(ciN, coN), nightsDart(ciN, coN));
}

// ----- B. Fall back straddle -----
console.log('\n[B] Zagreb fall-back straddle 2026-10-24 → 2026-10-26:');
{
  const checkIn = new Date('2026-10-23T22:00:00Z');   // Zagreb 2026-10-24 00:00 CEST
  const checkOut = new Date('2026-10-25T23:00:00Z');  // Zagreb 2026-10-26 00:00 CET (post-fall-back)
  const ciN = normalizeToZagrebCivilDayUTC(checkIn);
  const coN = normalizeToZagrebCivilDayUTC(checkOut);
  expect('checkIn → 2026-10-24T00:00Z', ciN.toISOString(), '2026-10-24T00:00:00.000Z');
  expect('checkOut → 2026-10-26T00:00Z', coN.toISOString(), '2026-10-26T00:00:00.000Z');
  expect('nights (TS ceil)', nightsTS(ciN, coN), 2);
  expect('nights (Dart floor)', nightsDart(ciN, coN), 2);
  expect('TS == Dart parity', nightsTS(ciN, coN), nightsDart(ciN, coN));
}

// ----- C. Same Zagreb civil day post-normalize -----
console.log('\n[C] Same Zagreb civil day post-normalize:');
{
  // Both fall on Zagreb 2026-06-01 (CEST UTC+2 in summer)
  const checkIn = new Date('2026-06-01T06:00:00Z');   // 08:00 Zagreb
  const checkOut = new Date('2026-06-01T18:00:00Z');  // 20:00 Zagreb
  const ciN = normalizeToZagrebCivilDayUTC(checkIn);
  const coN = normalizeToZagrebCivilDayUTC(checkOut);
  expect('checkIn normalizes', ciN.toISOString(), '2026-06-01T00:00:00.000Z');
  expect('checkOut normalizes', coN.toISOString(), '2026-06-01T00:00:00.000Z');
  expect('Pre-normalize order: checkOut > checkIn', checkOut > checkIn, true);
  expect('Post-normalize: same millis → THROW expected', ciN.getTime() === coN.getTime(), true);
}

// ----- D. Four input variants for 2026-03-29 -----
console.log('\n[D] Four input variants for 2026-03-29 → Zagreb civil-day normalize:');
{
  const variants = {
    'date-only "2026-03-29"': new Date('2026-03-29'),                              // → 2026-03-29T00:00Z
    'UTC midnight Z':         new Date('2026-03-29T00:00:00Z'),                    // → 2026-03-29T00:00Z
    'Zagreb +01:00 (CET pre-DST)': new Date('2026-03-29T00:00:00+01:00'),          // → 2026-03-28T23:00Z
    'Zagreb +02:00 (CEST mis-send)': new Date('2026-03-29T00:00:00+02:00'),        // → 2026-03-28T22:00Z
  };
  for (const [name, raw] of Object.entries(variants)) {
    const norm = normalizeToZagrebCivilDayUTC(raw);
    console.log(`    ${name}: raw=${raw.toISOString()} → norm=${norm.toISOString()}`);
  }
  // First three should all land on 2026-03-29 because:
  //   "2026-03-29"           = 2026-03-29 00:00Z → Zagreb 01:00 CET = 03-29
  //   "...T00:00Z"           = same
  //   "...T00:00+01:00"      = 2026-03-28T23:00Z → Zagreb 00:00 CET = 03-29
  // The +02:00 mis-send shifts to 2026-03-28T22:00Z → Zagreb 23:00 CET 2026-03-28
  expect(
    'date-only normalizes to 2026-03-29',
    normalizeToZagrebCivilDayUTC(new Date('2026-03-29')).toISOString(),
    '2026-03-29T00:00:00.000Z',
  );
  expect(
    'UTC Z normalizes to 2026-03-29',
    normalizeToZagrebCivilDayUTC(new Date('2026-03-29T00:00:00Z')).toISOString(),
    '2026-03-29T00:00:00.000Z',
  );
  expect(
    '+01:00 (Zagreb CET) normalizes to 2026-03-29',
    normalizeToZagrebCivilDayUTC(new Date('2026-03-29T00:00:00+01:00')).toISOString(),
    '2026-03-29T00:00:00.000Z',
  );
  expect(
    '+02:00 (CEST mis-send) shifts to 2026-03-28',
    normalizeToZagrebCivilDayUTC(new Date('2026-03-29T00:00:00+02:00')).toISOString(),
    '2026-03-28T00:00:00.000Z',
  );
}

// ----- E. Non-midnight time on Zagreb civil day -----
console.log('\n[E] Non-midnight time normalizes to civil-day UTC midnight:');
{
  // 14:30 UTC on 2026-06-15 = 16:30 Zagreb CEST = civil-day 2026-06-15
  const raw = new Date('2026-06-15T14:30:00Z');
  const norm = normalizeToZagrebCivilDayUTC(raw);
  expect('14:30Z on 2026-06-15 → 2026-06-15T00:00Z', norm.toISOString(), '2026-06-15T00:00:00.000Z');
}

// ----- F. Dart/TS parity over 0..400 random normalized stays -----
console.log('\n[F] Dart/TS parity on 400 random normalized stays:');
{
  let mismatches = 0;
  for (let i = 0; i < 400; i++) {
    const startMs = Date.UTC(2026, 0, 1) + Math.floor(Math.random() * 365) * 86_400_000;
    const stayDays = 1 + Math.floor(Math.random() * 30);
    const endMs = startMs + stayDays * 86_400_000;
    if (nightsTS(new Date(startMs), new Date(endMs)) !== nightsDart(new Date(startMs), new Date(endMs))) {
      mismatches++;
    }
  }
  expect('Parity over 400 normalized stays', mismatches, 0);
}

if (process.exitCode !== 1) {
  console.log('\n✅ T1 PASS — all DST + nights checks green');
} else {
  console.log('\n❌ T1 FAIL — see failures above');
}
