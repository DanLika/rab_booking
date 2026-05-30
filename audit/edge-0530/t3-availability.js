#!/usr/bin/env node
/**
 * T3: getUnitAvailability consistency + inclusive-end-window edge case.
 *
 * Calls bookbed-dev's deployed getUnitAvailability callable (europe-west1)
 * anonymously, then cross-checks against direct Firestore reads.
 *
 * Cases:
 *   T3.A  No bookings, no manual blocks → windows.length === 0.
 *   T3.B  Manual block on 2026-06-15 → 1 window source=manual_block.
 *   T3.C  endDate=2026-07-01T00:00:00Z (Zagreb 02:00 CEST 2026-07-01 — i.e.
 *         widget passing exclusive checkout-style endDate). With manual block
 *         on date=2026-07-01 in daily_prices:
 *           - If `where("date","<=",endTs)` is INCLUSIVE → window appears
 *             with start=2026-07-01T00:00Z, end=2026-07-02T00:00Z. The widget
 *             then renders 2026-07-01 as blocked even though it's the
 *             requested exclusive end. That's a 1-day overblock.
 *   T3.D  PII strip: no guest_name / guest_email / payment_status leak —
 *         tested by seeding a pending booking under the unit and asserting
 *         the response keys are limited to {start, end, source, platform?}.
 *   T3.E  ical_event with status=confirmed_echo → not included.
 *
 * Seeds + cleanups via direct Firestore.
 */

const path = require('path');
const https = require('https');

const candidates = [
  path.resolve(__dirname, '..', '..', 'functions', 'node_modules', 'firebase-admin'),
  path.resolve('/Users/duskolicanin/git/bookbed/functions/node_modules/firebase-admin'),
];
let admin;
for (const p of candidates) {
  try { admin = require(p); break; } catch (_) {}
}

admin.initializeApp({projectId: 'bookbed-dev'});
const db = admin.firestore();
const FV = admin.firestore.FieldValue;
const Ts = admin.firestore.Timestamp;

const RUN = 'edge-0530';
const TAG = {test_artifact: true, test_run_id: RUN};
const PROP = 'EDGE_prop_0530';
const UNIT = 'EDGE_unit_0530';
// Real deployed CF on bookbed-dev. europe-west1 hosting prefix.
const CF_URL = 'https://europe-west1-bookbed-dev.cloudfunctions.net/getUnitAvailability';

function postJson(url, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({data: body});
    const u = new URL(url);
    const req = https.request({
      hostname: u.hostname,
      port: 443,
      path: u.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
    }, (res) => {
      let buf = '';
      res.on('data', (c) => buf += c);
      res.on('end', () => {
        try { resolve({status: res.statusCode, body: JSON.parse(buf)}); }
        catch (e) { resolve({status: res.statusCode, body: buf}); }
      });
    });
    req.on('error', reject);
    req.write(data); req.end();
  });
}

function expect(name, actual, expected) {
  const ok = JSON.stringify(actual) === JSON.stringify(expected);
  console.log(`  ${ok ? '✓' : '✗'} ${name}: ${ok ? 'OK' : `EXPECTED ${JSON.stringify(expected)} GOT ${JSON.stringify(actual)}`}`);
  if (!ok) process.exitCode = 1;
}

async function main() {
  console.log('T3 — getUnitAvailability consistency on bookbed-dev\n');
  console.log(`Calling: ${CF_URL}`);

  // ---- T3.A no bookings, only daily_prices manual blocks from seed
  console.log('\n[A] Baseline call: 30 days starting 2026-06-01 — expect 2 manual_block windows');
  {
    const resA = await postJson(CF_URL, {
      propertyId: PROP,
      unitId: UNIT,
      startDate: '2026-06-01T00:00:00Z',
      endDate: '2026-06-30T00:00:00Z',
    });
    console.log(`  HTTP ${resA.status}`);
    if (resA.status !== 200) {
      console.log('  BODY:', JSON.stringify(resA.body, null, 2));
      process.exit(2);
    }
    const windows = resA.body.result.windows;
    console.log(`  windows.length = ${windows.length}`);
    console.log(`  windows = ${JSON.stringify(windows, null, 2)}`);
    // Expect just the 2026-06-15 manual block (only one within range)
    const manualBlocks = windows.filter((w) => w.source === 'manual_block');
    expect('manual_block windows == 1 (2026-06-15)', manualBlocks.length, 1);
    if (manualBlocks.length > 0) {
      expect(
        'block starts 2026-06-15',
        manualBlocks[0].start.slice(0, 10),
        '2026-06-15',
      );
    }
  }

  // ---- T3.C inclusive-end-window candidate
  console.log('\n[C] Inclusive-end-window edge: endDate=2026-07-01T00:00Z, blocked day=2026-07-01');
  {
    // exclusive-checkout-style: widget sees range [2026-06-15, 2026-07-01) — should NOT include 2026-07-01
    const res = await postJson(CF_URL, {
      propertyId: PROP,
      unitId: UNIT,
      startDate: '2026-06-15T00:00:00Z',
      endDate: '2026-07-01T00:00:00Z',
    });
    if (res.status !== 200) {
      console.log('  HTTP', res.status, JSON.stringify(res.body, null, 2));
      process.exit(2);
    }
    const windows = res.body.result.windows;
    const has0701 = windows.some((w) => w.start.startsWith('2026-07-01') && w.source === 'manual_block');
    console.log(`  windows = ${JSON.stringify(windows, null, 2)}`);
    if (has0701) {
      console.log('  ⚠️ FINDING: 2026-07-01 manual_block window appears though endDate is 2026-07-01T00:00Z (exclusive)');
      console.log('     → availability.ts:169  `where("date","<=",endTs)` inclusive — overblocks the checkout day.');
    } else {
      console.log('  ℹ️ No 2026-07-01 window — inclusive-end query OK (may be filtered downstream)');
    }
  }

  // ---- T3.D PII strip
  console.log('\n[D] PII strip — seed a pending booking + verify response keys are slim');
  {
    const bookingId = `EDGE_pii_test_${Date.now()}`;
    const bookingRef = db.doc(`properties/${PROP}/bookings/${bookingId}`);
    await bookingRef.set({
      user_id: 'EDGE_pii_user',
      unit_id: UNIT,
      property_id: PROP,
      owner_id: 'GILVItIVP5R8WXfnMmyMo1ykhUm2',
      guest_name: 'PII_LEAK_GUEST',
      guest_email: 'pii-leak@example.com',
      guest_phone: '+38598999000',
      check_in: Ts.fromDate(new Date(Date.UTC(2026, 5, 20))),
      check_out: Ts.fromDate(new Date(Date.UTC(2026, 5, 22))),
      nights: 2,
      guest_count: 2,
      pet_count: 0,
      total_price: 200,
      deposit_amount: 60,
      payment_method: 'pay_on_arrival',
      payment_status: 'not_required',
      status: 'pending',
      booking_reference: 'EDGE-PII',
      source: 'edge_test',
      access_token: 'EDGE_test_hash',
      created_at: FV.serverTimestamp(),
      updated_at: FV.serverTimestamp(),
      ...TAG,
    });

    // Give Firestore a beat to settle the write before the CF reads it
    await new Promise((r) => setTimeout(r, 1500));

    const res = await postJson(CF_URL, {
      propertyId: PROP,
      unitId: UNIT,
      startDate: '2026-06-15T00:00:00Z',
      endDate: '2026-06-30T00:00:00Z',
    });
    const windows = res.body.result.windows;
    const bookingWindow = windows.find((w) => w.source === 'booking');
    if (!bookingWindow) {
      console.log('  ✗ Booking did not appear as window — check CG query');
      process.exitCode = 1;
    } else {
      const keys = Object.keys(bookingWindow).sort();
      console.log(`  bookingWindow keys = [${keys.join(', ')}]`);
      expect('keys are exactly start+end+source', keys, ['end', 'source', 'start']);
      // No PII fields present (would be on raw doc but stripped):
      const leaks = ['guest_name', 'guest_email', 'guest_phone', 'payment_status', 'access_token', 'booking_reference'];
      const leaked = leaks.filter((k) => k in bookingWindow);
      expect('No PII leak', leaked, []);
    }

    // cleanup the test booking
    await bookingRef.delete();
    console.log('  ✓ test booking cleaned');
  }

  // ---- T3.E confirmed_echo iCal event NOT included
  console.log('\n[E] confirmed_echo iCal event NOT included');
  {
    const eventId = `EDGE_echo_${Date.now()}`;
    const eventRef = db.doc(`properties/${PROP}/units/${UNIT}/ical_events/${eventId}`);
    await eventRef.set({
      unit_id: UNIT,
      property_id: PROP,
      external_id: 'EDGE_external_echo',
      source: 'Booking.com',
      start_date: Ts.fromDate(new Date(Date.UTC(2026, 5, 25))),
      end_date: Ts.fromDate(new Date(Date.UTC(2026, 5, 27))),
      status: 'confirmed_echo',
      eventStatus: 'active',
      created_at: FV.serverTimestamp(),
      ...TAG,
    });
    await new Promise((r) => setTimeout(r, 1500));
    const res = await postJson(CF_URL, {
      propertyId: PROP,
      unitId: UNIT,
      startDate: '2026-06-20T00:00:00Z',
      endDate: '2026-06-30T00:00:00Z',
    });
    const windows = res.body.result.windows;
    const icalWindows = windows.filter((w) => w.source === 'ical_external');
    expect('echo not included', icalWindows.length, 0);
    await eventRef.delete();
  }

  console.log('\n✅ T3 done. Inspect [C] for inclusive-end-window finding.');
}

main().catch((e) => { console.error('T3 ERR:', e); process.exit(2); });
