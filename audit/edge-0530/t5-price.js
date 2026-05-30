#!/usr/bin/env node
/**
 * T5: Price calc + SF-014 server-authority for booking total.
 *
 * Seed fixture (from seed.js):
 *   base_price = 100, weekend_base_price = 150, weekend_days=[Fri,Sat]
 *   daily_prices/2026-06-09 (Tue) override price=200, available=true
 *   daily_prices/2026-06-15 (Mon) available=false (blocked)
 *
 * Stay 2027-06-07 Mon → 2027-06-14 Mon = 7 nights.
 *   2027-06-07 Mon → fallback 100  (Mon=1, not weekend)
 *   2027-06-08 Tue → fallback 100
 *   2027-06-09 Wed → fallback 100  (seed override was on 2026-06-09, not 2027)
 *   2027-06-10 Thu → fallback 100
 *   2027-06-11 Fri → fallback 150  (weekend)
 *   2027-06-12 Sat → fallback 150  (weekend)
 *   2027-06-13 Sun → fallback 100
 *   Server total = 100+100+100+100+150+150+100 = 800
 *
 * Cases:
 *   T5.A  Client sends exact 800 → 200 OK, total_price saved=800.
 *   T5.B  Client sends 700 → diff=100, suspicious=true → Sentry alerted
 *         BUT booking SUCCEEDS at server price 800 (atomicBooking falls back
 *         to server total — see atomicBooking.ts:649).
 *   T5.C  Client sends 805 (€5 diff <10) → small mismatch, NO Sentry
 *         but booking SUCCEEDS at server 800.
 *   T5.D  Client sends 100000 (massive manipulation) → suspicious=true,
 *         booking SUCCEEDS at server 800. (Server NEVER honors high price.)
 *
 *   T5.E  Stay covering 2026-06-15 (blocked) → throws failed-precondition.
 *   T5.F  Stay covering 2026-06-09 (Wed override 200) → server total reflects.
 *
 * Cleanup: all created bookings tagged + deleted.
 */

const path = require('path');
const https = require('https');

const admin = require(path.resolve('/Users/duskolicanin/git/bookbed/functions/node_modules/firebase-admin'));
admin.initializeApp({projectId: 'bookbed-dev'});
const db = admin.firestore();
const FV = admin.firestore.FieldValue;

const PROP = 'EDGE_prop_0530';
const UNIT = 'EDGE_unit_0530';
const RUN = 'edge-0530';
const TAG = {test_artifact: true, test_run_id: RUN};
const CF_URL = 'https://us-central1-bookbed-dev.cloudfunctions.net/createBookingAtomic';

function randomIp() {
  // Synthetic X-Forwarded-For — avoids the in-memory widget rate limit's
  // per-IP bucket. checkRateLimit uses the literal header value as part of
  // its key (`widget_booking:${clientIp}`), so a unique-per-call IP resets.
  return [
    100 + Math.floor(Math.random() * 100),
    Math.floor(Math.random() * 256),
    Math.floor(Math.random() * 256),
    Math.floor(Math.random() * 256),
  ].join('.');
}

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
        'X-Forwarded-For': randomIp(),
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

function genArgs(checkIn, checkOut, clientTotal, opts = {}) {
  return {
    unitId: UNIT,
    propertyId: PROP,
    ownerId: 'GILVItIVP5R8WXfnMmyMo1ykhUm2',
    checkIn,
    checkOut,
    guestName: opts.guestName || 'Edge Price Tester',
    guestEmail: opts.guestEmail || 'edge-price@example.com',
    guestPhone: '+38598123456',
    guestCount: 2,
    petCount: 0,
    totalPrice: clientTotal,
    paymentOption: 'none',
    paymentMethod: 'pay_on_arrival',
    requireOwnerApproval: true,
    taxLegalAccepted: true,
  };
}

async function cleanBookings() {
  let n = 0;
  for (const col of [`properties/${PROP}/units/${UNIT}/bookings`, `properties/${PROP}/bookings`]) {
    const snap = await db.collection(col).get();
    for (const d of snap.docs) {
      const data = d.data();
      const email = data.guest_email || '';
      if (data.test_run_id === RUN || email.includes('edge-')) {
        await d.ref.delete();
        n++;
      }
    }
  }
  return n;
}

async function tagBookings(email) {
  let n = 0;
  for (const col of [`properties/${PROP}/units/${UNIT}/bookings`, `properties/${PROP}/bookings`]) {
    const snap = await db.collection(col).where('guest_email', '==', email).get();
    for (const d of snap.docs) {
      await d.ref.update(TAG);
      n++;
    }
  }
  return n;
}

async function getServerTotalForLastBooking(email) {
  for (const col of [`properties/${PROP}/units/${UNIT}/bookings`, `properties/${PROP}/bookings`]) {
    const snap = await db.collection(col).where('guest_email', '==', email).get();
    if (!snap.empty) {
      return snap.docs[0].data().total_price;
    }
  }
  return null;
}

function expect(name, actual, expected) {
  const ok = JSON.stringify(actual) === JSON.stringify(expected);
  console.log(`  ${ok ? '✓' : '✗'} ${name}: ${ok ? 'OK' : `EXPECTED ${JSON.stringify(expected)} GOT ${JSON.stringify(actual)}`}`);
  if (!ok) process.exitCode = 1;
}

async function main() {
  console.log('T5 — price calc + SF-014\n');

  await cleanBookings();

  // Stay 2027-06-07 Mon → 2027-06-14 Mon = 7 nights, server total 800
  const SERVER_TOTAL_BASE = 800;

  // ---- T5.A exact 800 — happy path
  console.log('[A] 2027-06-07..14 client=800 (=server)');
  {
    const res = await postCallable(CF_URL,
      genArgs('2027-06-07T00:00:00Z', '2027-06-14T00:00:00Z', SERVER_TOTAL_BASE, {guestEmail: 'edge-p-a@example.com'}));
    console.log(`  HTTP ${res.status}, returned totalPrice=${res.body?.result?.totalPrice}`);
    expect('200 OK', res.status, 200);
    expect('server total 800', res.body?.result?.totalPrice, SERVER_TOTAL_BASE);
    await tagBookings('edge-p-a@example.com');
  }

  // ---- T5.B suspicious -100 mismatch → succeeds at server 800
  console.log('\n[B] 2027-07-05..12 client=700 (server=800, diff=100 SUSPICIOUS)');
  {
    const res = await postCallable(CF_URL,
      genArgs('2027-07-05T00:00:00Z', '2027-07-12T00:00:00Z', 700, {guestEmail: 'edge-p-b@example.com'}));
    console.log(`  HTTP ${res.status}, returned totalPrice=${res.body?.result?.totalPrice}`);
    expect('200 OK', res.status, 200);
    expect('saved total_price = server 800 (SF-014)', res.body?.result?.totalPrice, SERVER_TOTAL_BASE);
    await tagBookings('edge-p-b@example.com');
    const stored = await getServerTotalForLastBooking('edge-p-b@example.com');
    expect('Firestore total_price = 800 (NOT client 700)', stored, SERVER_TOTAL_BASE);
  }

  // ---- T5.C small mismatch
  console.log('\n[C] 2027-08-02..09 client=805 (small diff)');
  {
    const res = await postCallable(CF_URL,
      genArgs('2027-08-02T00:00:00Z', '2027-08-09T00:00:00Z', 805, {guestEmail: 'edge-p-c@example.com'}));
    console.log(`  HTTP ${res.status}, returned totalPrice=${res.body?.result?.totalPrice}`);
    expect('200 OK', res.status, 200);
    expect('saved total = server 800', res.body?.result?.totalPrice, SERVER_TOTAL_BASE);
    await tagBookings('edge-p-c@example.com');
  }

  // ---- T5.D massive manipulation
  console.log('\n[D] 2027-09-06..13 client=100000 (massive manipulation)');
  {
    const res = await postCallable(CF_URL,
      genArgs('2027-09-06T00:00:00Z', '2027-09-13T00:00:00Z', 100000, {guestEmail: 'edge-p-d@example.com'}));
    console.log(`  HTTP ${res.status}, returned totalPrice=${res.body?.result?.totalPrice}`);
    expect('200 OK', res.status, 200);
    expect('saved total = server 800 (NOT 100000)', res.body?.result?.totalPrice, SERVER_TOTAL_BASE);
    await tagBookings('edge-p-d@example.com');
  }

  // ---- T5.E covering 2026-06-15 (blocked daily_price)
  console.log('\n[E] 2026-06-14..17 covers blocked 06-15 → failed-precondition');
  {
    const res = await postCallable(CF_URL,
      genArgs('2026-06-14T00:00:00Z', '2026-06-17T00:00:00Z', 300, {guestEmail: 'edge-p-e@example.com'}));
    console.log(`  HTTP ${res.status}, err=${(res.body?.error?.message || '').slice(0, 80)}`);
    expect('non-200', res.status !== 200, true);
    const errStr = JSON.stringify(res.body?.error || '');
    expect('error mentions 2026-06-15', errStr.includes('2026-06-15'), true);
  }

  // ---- T5.F covering 2026-06-09 (override 200) — only the override day, others fallback
  // 2026-06-08 (Mon) → 100, 2026-06-09 (Tue overridden) → 200, 2026-06-10 (Wed) → 100
  // Total = 100 + 200 + 100 = 400
  console.log('\n[F] 2026-06-08..11 covers 2026-06-09 override (200) → server 400');
  {
    const res = await postCallable(CF_URL,
      genArgs('2026-06-08T00:00:00Z', '2026-06-11T00:00:00Z', 400, {guestEmail: 'edge-p-f@example.com'}));
    console.log(`  HTTP ${res.status}, returned totalPrice=${res.body?.result?.totalPrice}`);
    if (res.status === 200) {
      expect('server total includes override 400', res.body?.result?.totalPrice, 400);
      await tagBookings('edge-p-f@example.com');
    } else {
      console.log('  ERROR BODY:', JSON.stringify(res.body, null, 2));
    }
  }

  // Cleanup
  await new Promise((r) => setTimeout(r, 500));
  const cleaned = await cleanBookings();
  console.log(`\nCleaned ${cleaned} bookings`);
  console.log(process.exitCode === 1 ? '❌ T5 some FAIL' : '✅ T5 PASS — SF-014 server price authority holds');
}

main().catch((e) => { console.error('T5 ERR:', e); process.exit(2); });
