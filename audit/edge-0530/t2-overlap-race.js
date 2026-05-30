#!/usr/bin/env node
/**
 * T2: createBookingAtomic overlap race + turnover-day check.
 *
 * Region: createBookingAtomic ships with default region = us-central1
 * (`functions/src/atomicBooking.ts:60` no `region:` opt).
 *
 * Cases:
 *   T2.A  Sequential 1: Book Apr 1–3 successfully (status=pending).
 *   T2.B  Sequential 2: Re-book Apr 1–3 → must throw `already-exists`.
 *   T2.C  Turnover same-day: book Apr 3–5 → success (checkout 3 == checkin 3
 *         is NOT overlap per `check_out > checkInDate` query at line 750).
 *   T2.D  Parallel race: 2 simultaneous Promise.all calls for Apr 10–12
 *         → exactly ONE succeeds, the other throws `already-exists` (the
 *         Firestore txn must serialize via document-level locking).
 *   T2.E  Cancelled-status overlap: seed a `cancelled` booking on Apr 20–22,
 *         then book Apr 20–22 → success (status filter is
 *         `["pending","confirmed"]`).
 *   T2.F  Stale pending placeholder still blocks: seed a pending booking
 *         older than cleanupExpiredPendingBookings TTL → new booking on
 *         same dates throws `already-exists` (cleanup has not run yet).
 *   T2.G  Same Zagreb-civil-day check (8 AM + 8 PM same date in input)
 *         → throws `Stay must be at least 1 night`.
 *
 * Cleanup: tagged docs deleted at end + via --cleanup.
 */

const path = require('path');
const https = require('https');

const candidates = [
  path.resolve('/Users/duskolicanin/git/bookbed/functions/node_modules/firebase-admin'),
];
const admin = require(candidates[0]);
admin.initializeApp({projectId: 'bookbed-dev'});
const db = admin.firestore();
const FV = admin.firestore.FieldValue;
const Ts = admin.firestore.Timestamp;

const PROP = 'EDGE_prop_0530';
const UNIT = 'EDGE_unit_0530';
const RUN = 'edge-0530';
const TAG = {test_artifact: true, test_run_id: RUN};
const CF_URL = 'https://us-central1-bookbed-dev.cloudfunctions.net/createBookingAtomic';

function postCallable(url, data) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({data});
    const u = new URL(url);
    const req = https.request({
      hostname: u.hostname,
      port: 443,
      path: u.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
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
    req.write(body); req.end();
  });
}

function genBookingArgs(checkIn, checkOut, opts = {}) {
  return {
    unitId: UNIT,
    propertyId: PROP,
    ownerId: 'GILVItIVP5R8WXfnMmyMo1ykhUm2',
    checkIn,
    checkOut,
    guestName: opts.guestName || 'Edge Race Tester',
    guestEmail: opts.guestEmail || 'edge-race@example.com',
    guestPhone: '+38598123456',
    guestCount: 2,
    petCount: 0,
    totalPrice: opts.totalPrice ?? 200,
    paymentOption: 'none',
    paymentMethod: 'pay_on_arrival',
    requireOwnerApproval: true,
    taxLegalAccepted: true,
  };
}

async function tagBookingsByRequest(emailOrName) {
  // After a successful booking, find the doc by guest_email + flag with test_artifact.
  // This avoids needing the returned bookingId to clean up later.
  const snap = await db.collection(`properties/${PROP}/units/${UNIT}/bookings`)
    .where('guest_email', '==', emailOrName)
    .get();
  for (const d of snap.docs) await d.ref.update(TAG);
  return snap.size;
}

async function listAllRunBookings() {
  // Reverse engineer: query the subcoll where our seed cleanup will look.
  // Returns array of doc refs (mix of legacy + subcoll).
  const sub = await db.collection(`properties/${PROP}/units/${UNIT}/bookings`).get();
  const top = await db.collection(`properties/${PROP}/bookings`).get();
  return [...sub.docs, ...top.docs];
}

async function cleanAllRunBookings() {
  const docs = await listAllRunBookings();
  let n = 0;
  for (const d of docs) {
    const data = d.data();
    if (
      data.test_run_id === RUN ||
      (data.guest_email || '').endsWith('@example.com') ||
      (data.guest_email || '').includes('edge-')
    ) {
      await d.ref.delete();
      n++;
    }
  }
  return n;
}

function expect(name, actual, expected) {
  const ok = JSON.stringify(actual) === JSON.stringify(expected);
  console.log(`  ${ok ? '✓' : '✗'} ${name}: ${ok ? 'OK' : `EXPECTED ${JSON.stringify(expected)} GOT ${JSON.stringify(actual)}`}`);
  if (!ok) process.exitCode = 1;
}

async function main() {
  console.log('T2 — createBookingAtomic overlap race + turnover\n');

  // Pre-clean
  const cleaned = await cleanAllRunBookings();
  console.log(`Pre-clean removed ${cleaned} stale bookings\n`);

  // ---- T2.A baseline book Apr 1–3 (use 2027 to avoid past-date guard)
  console.log('[A] Sequential book 2027-04-01 → 2027-04-03 (expect 201)');
  let firstBookingId = null;
  {
    const args = genBookingArgs(
      '2027-04-01T00:00:00Z',
      '2027-04-03T00:00:00Z',
      {guestEmail: 'edge-a@example.com'},
    );
    const res = await postCallable(CF_URL, args);
    console.log(`  HTTP ${res.status}; ok=${res.body?.result?.success ?? '-'}`);
    if (res.status !== 200) {
      console.log('  BODY:', JSON.stringify(res.body, null, 2));
    }
    expect('T2.A status 200', res.status, 200);
    if (res.body?.result?.bookingId) {
      firstBookingId = res.body.result.bookingId;
      const n = await tagBookingsByRequest('edge-a@example.com');
      console.log(`  Tagged ${n} doc(s) with test_artifact`);
    }
  }

  // ---- T2.B same dates → already-exists
  console.log('\n[B] Re-book 2027-04-01 → 2027-04-03 (expect already-exists)');
  {
    const args = genBookingArgs(
      '2027-04-01T00:00:00Z',
      '2027-04-03T00:00:00Z',
      {guestEmail: 'edge-b@example.com'},
    );
    const res = await postCallable(CF_URL, args);
    const code = res.body?.error?.status || res.body?.error?.code || res.body?.error?.message;
    console.log(`  HTTP ${res.status}; err=${JSON.stringify(res.body?.error || res.body)}`);
    if (res.status === 200) {
      console.log('  ⚠️ ALSO TAGGED for cleanup');
      await tagBookingsByRequest('edge-b@example.com');
    }
    expect('T2.B HTTP not 200', res.status !== 200, true);
    const errStr = JSON.stringify(res.body?.error || '');
    expect('T2.B already-exists signal', errStr.includes('ALREADY_EXISTS') || errStr.includes('already-exists') || errStr.includes('no longer available'), true);
  }

  // ---- T2.C turnover same-day Apr 3 → Apr 5 (3 is checkout of A, checkin of C)
  console.log('\n[C] Turnover book 2027-04-03 → 2027-04-05 (expect 200 — no overlap)');
  {
    const args = genBookingArgs(
      '2027-04-03T00:00:00Z',
      '2027-04-05T00:00:00Z',
      {guestEmail: 'edge-c@example.com'},
    );
    const res = await postCallable(CF_URL, args);
    console.log(`  HTTP ${res.status}; ok=${res.body?.result?.success ?? '-'}`);
    if (res.status !== 200) {
      console.log('  BODY:', JSON.stringify(res.body, null, 2));
    }
    expect('T2.C status 200 (turnover allowed)', res.status, 200);
    if (res.body?.result?.bookingId) await tagBookingsByRequest('edge-c@example.com');
  }

  // ---- T2.D parallel race for 2027-04-10 → 2027-04-12
  console.log('\n[D] Parallel race: 2 simultaneous calls for 2027-04-10 → 2027-04-12');
  {
    const argsX = genBookingArgs(
      '2027-04-10T00:00:00Z',
      '2027-04-12T00:00:00Z',
      {guestEmail: 'edge-d-x@example.com'},
    );
    const argsY = genBookingArgs(
      '2027-04-10T00:00:00Z',
      '2027-04-12T00:00:00Z',
      {guestEmail: 'edge-d-y@example.com'},
    );
    const [r1, r2] = await Promise.all([
      postCallable(CF_URL, argsX),
      postCallable(CF_URL, argsY),
    ]);
    console.log(`  X: HTTP ${r1.status}, err=${(r1.body?.error?.message || '').slice(0, 80)}`);
    console.log(`  Y: HTTP ${r2.status}, err=${(r2.body?.error?.message || '').slice(0, 80)}`);
    const successes = [r1, r2].filter((r) => r.status === 200).length;
    expect('T2.D exactly one success', successes, 1);
    // Tag both for cleanup
    await tagBookingsByRequest('edge-d-x@example.com');
    await tagBookingsByRequest('edge-d-y@example.com');
  }

  // ---- T2.E cancelled-status existing → re-book OK
  console.log('\n[E] cancelled-status booking on 2027-04-20 → re-book same dates OK');
  {
    const cancelledRef = db.doc(`properties/${PROP}/units/${UNIT}/bookings/EDGE_cancelled_e2026`);
    await cancelledRef.set({
      user_id: 'EDGE_e_user',
      unit_id: UNIT,
      property_id: PROP,
      owner_id: 'GILVItIVP5R8WXfnMmyMo1ykhUm2',
      guest_email: 'edge-e-cancelled@example.com',
      guest_name: 'Cancelled E',
      check_in: Ts.fromDate(new Date(Date.UTC(2027, 3, 20))),
      check_out: Ts.fromDate(new Date(Date.UTC(2027, 3, 22))),
      status: 'cancelled',
      cancellation_reason: 'edge test',
      cancelled_at: FV.serverTimestamp(),
      payment_status: 'refunded',
      total_price: 200,
      created_at: FV.serverTimestamp(),
      ...TAG,
    });

    const args = genBookingArgs(
      '2027-04-20T00:00:00Z',
      '2027-04-22T00:00:00Z',
      {guestEmail: 'edge-e-new@example.com'},
    );
    const res = await postCallable(CF_URL, args);
    console.log(`  HTTP ${res.status}; cancelled-status overlap allowed? ${res.status === 200}`);
    expect('T2.E re-book over cancelled succeeds', res.status, 200);
    if (res.body?.result?.bookingId) await tagBookingsByRequest('edge-e-new@example.com');
  }

  // ---- T2.F stale pending placeholder STILL blocks
  console.log('\n[F] Stale pending (created_at 2 hrs ago) STILL blocks new booking');
  {
    const stalePending = db.doc(`properties/${PROP}/units/${UNIT}/bookings/EDGE_stale_f`);
    const twoHrAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);
    await stalePending.set({
      user_id: 'EDGE_f_user',
      unit_id: UNIT,
      property_id: PROP,
      owner_id: 'GILVItIVP5R8WXfnMmyMo1ykhUm2',
      guest_email: 'edge-f-stale@example.com',
      guest_name: 'Stale F',
      check_in: Ts.fromDate(new Date(Date.UTC(2027, 4, 1))),
      check_out: Ts.fromDate(new Date(Date.UTC(2027, 4, 3))),
      status: 'pending',
      payment_method: 'stripe',
      payment_status: 'pending',
      total_price: 200,
      created_at: Ts.fromDate(twoHrAgo),
      updated_at: Ts.fromDate(twoHrAgo),
      ...TAG,
    });

    const args = genBookingArgs(
      '2027-05-01T00:00:00Z',
      '2027-05-03T00:00:00Z',
      {guestEmail: 'edge-f-new@example.com'},
    );
    const res = await postCallable(CF_URL, args);
    const code = JSON.stringify(res.body?.error || '');
    console.log(`  HTTP ${res.status}; err=${code.slice(0, 80)}`);
    expect('T2.F stale pending blocks new booking', res.status !== 200, true);
  }

  // ---- T2.G same Zagreb-civil-day → throws
  console.log('\n[G] Same Zagreb civil day input (08:00Z + 20:00Z 2027-06-01) → throw');
  {
    const args = genBookingArgs(
      '2027-06-01T06:00:00Z',  // Zagreb 08:00
      '2027-06-01T18:00:00Z',  // Zagreb 20:00, same civil day
      {guestEmail: 'edge-g@example.com'},
    );
    const res = await postCallable(CF_URL, args);
    const errStr = JSON.stringify(res.body?.error || '');
    console.log(`  HTTP ${res.status}; err=${errStr.slice(0, 100)}`);
    expect('T2.G HTTP not 200', res.status !== 200, true);
    expect(
      'T2.G error mentions 1 night',
      errStr.includes('1 night') || errStr.includes('Stay must be at least'),
      true,
    );
  }

  // Final cleanup
  console.log('\n');
  const finalCleaned = await cleanAllRunBookings();
  console.log(`Final cleanup removed ${finalCleaned} bookings.\n`);
  console.log(process.exitCode === 1 ? '❌ T2 some FAIL — inspect above' : '✅ T2 PASS — all overlap+race checks green');
}

main().catch((e) => { console.error('T2 ERR:', e); process.exit(2); });
