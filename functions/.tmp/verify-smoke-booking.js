#!/usr/bin/env node
/**
 * Verify smoke booking landed.
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=... node .tmp/verify-smoke-booking.js \
 *     --project bookbed-dev --since-mins 15
 *
 * Looks up most recent booking in seed unit + reports:
 *   - doc path, status, dates, guest, emails_sent flags
 *   - createBookingAtomic invocation gate (was anon or auth?)
 *
 * Pass --reference BK-XXX to look up exact booking_reference.
 */

const admin = require('firebase-admin');

const args = Object.fromEntries(
  process.argv.slice(2).reduce((acc, cur, i, arr) => {
    if (cur.startsWith('--')) {
      const k = cur.slice(2);
      const v = arr[i + 1] && !arr[i + 1].startsWith('--') ? arr[i + 1] : true;
      acc.push([k, v]);
    }
    return acc;
  }, [])
);

const PROJECT = args.project || 'bookbed-dev';
const SINCE_MINS = parseInt(args['since-mins'] || '15', 10);
const REF = args.reference;

admin.initializeApp({projectId: PROJECT});
const db = admin.firestore();

(async () => {
  const since = new Date(Date.now() - SINCE_MINS * 60 * 1000);
  const cutoff = admin.firestore.Timestamp.fromDate(since);

  console.log(`Project: ${PROJECT}`);
  console.log(`Looking for bookings since: ${since.toISOString()}`);
  if (REF) console.log(`Filter: booking_reference == ${REF}`);

  let q = db.collectionGroup('bookings').where('created_at', '>=', cutoff);
  if (REF) q = q.where('booking_reference', '==', REF);

  const snap = await q.orderBy('created_at', 'desc').limit(10).get();

  console.log(`\nFound ${snap.size} matching booking(s):`);
  if (snap.empty) {
    console.log('NO BOOKINGS FOUND. Either smoke booking failed to write, or filter window too narrow.');
    process.exit(2);
  }

  for (const doc of snap.docs) {
    const d = doc.data();
    console.log('\n---');
    console.log(`Path: ${doc.ref.path}`);
    console.log(`Status: ${d.status}`);
    console.log(`Reference: ${d.booking_reference}`);
    console.log(`Guest: ${d.guest_first_name} ${d.guest_last_name} <${d.guest_email}>`);
    console.log(`Dates: ${d.check_in} -> ${d.check_out}`);
    console.log(`Total: €${d.total_price_eur ?? d.total_price}`);
    console.log(`Source: ${d.source}`);
    console.log(`Created: ${d.created_at?.toDate?.()?.toISOString()}`);
    console.log(`Owner: ${d.owner_id}`);
    console.log(`Property: ${d.property_id} / Unit: ${d.unit_id}`);
    console.log(`emails_sent: ${JSON.stringify(d.emails_sent || {})}`);
  }
  process.exit(0);
})().catch((e) => {
  console.error('ERROR:', e.message);
  process.exit(1);
});
