#!/usr/bin/env node
/**
 * Seed rich Pregled-premium fixture data on bookbed-dev.
 *
 * Phase C-1 (audit/116) requires `revenueHistory >= 4 points`, multi-channel
 * bookings, occupancy > 0, and >=1 upcoming arrival so the Premium cards
 * render with signal (not empty states).
 *
 * Reuses the test-owner property + unit from scripts/seed-bookbed-dev.js
 * (SEED_test_owner_property_01 / SEED_test_owner_unit_01). Run that seed
 * with `--test-owner` first if those don't exist yet.
 *
 * Writes 10 bookings with deterministic IDs (SEED_premium_bk_01..10):
 *   - 4× completed (days -28, -21, -14, -7) — fills revenueHistory window
 *   - 2× confirmed (days -2, +5)
 *   - 2× upcoming confirmed (days +1, +3) — for arrivals card
 *   - 2× pending (days +14, +21)
 * Channel `source` rotates: Direktno, Booking.com, Airbnb.
 *
 * Field names follow what `unified_dashboard_provider.dart` reads:
 *   - `check_in` (NOT `check_in_date`)  — audit/40 finding
 *   - `check_out`
 *   - `status`, `payment_status`, `total_price`, `source`, `unit_id`, `property_id`, `owner_id`
 *
 * Idempotent — set({merge:true}). Re-running refreshes timestamps but keeps IDs.
 *
 * Auth: Application Default Credentials. Run:
 *   gcloud auth application-default login
 *   gcloud config set project bookbed-dev   # OR use --project=bookbed-dev
 *
 * Usage:
 *   node scripts/seed-pregled-premium-dev.js
 *   node scripts/seed-pregled-premium-dev.js --project=bookbed-dev
 *   node scripts/seed-pregled-premium-dev.js --dry-run
 *
 * SAFETY: refuses to run against any project containing 'prod' or 'rab-booking-248fc'.
 */

const args = process.argv.slice(2);
const projectArg = args.find((a) => a.startsWith('--project='));
const projectId = projectArg ? projectArg.split('=')[1] : 'bookbed-dev';
const dryRun = args.includes('--dry-run');

if (/prod|rab-booking-248fc/i.test(projectId)) {
  console.error(`✗ Refusing PROD-shaped project: ${projectId}`);
  process.exit(1);
}

const admin = require('firebase-admin');
admin.initializeApp({ projectId });
const db = admin.firestore();
const { FieldValue, Timestamp } = admin.firestore;

const TEST_OWNER_UID = 'GILVItIVP5R8WXfnMmyMo1ykhUm2';
const PROPERTY_ID = 'SEED_test_owner_property_01';
const UNIT_ID = 'SEED_test_owner_unit_01';

function daysFromNow(days) {
  const d = new Date();
  d.setUTCHours(12, 0, 0, 0);
  d.setUTCDate(d.getUTCDate() + days);
  return Timestamp.fromDate(d);
}

function token32() {
  let s = '';
  for (let i = 0; i < 32; i++) s += Math.floor(Math.random() * 16).toString(16);
  return s;
}

const GUESTS = [
  { first: 'Marko', last: 'Horvat', email: 'marko.horvat@example.com', phone: '+38598111001' },
  { first: 'Sandra', last: 'Kovač', email: 'sandra.kovac@example.com', phone: '+38598111002' },
  { first: 'Eva', last: 'Novak', email: 'eva.novak@example.com', phone: '+38598111003' },
  { first: 'Luka', last: 'Babić', email: 'luka.babic@example.com', phone: '+38598111004' },
  { first: 'Petra', last: 'Jurić', email: 'petra.juric@example.com', phone: '+38598111005' },
  { first: 'Ivan', last: 'Perić', email: 'ivan.peric@example.com', phone: '+38598111006' },
  { first: 'Ana', last: 'Šimić', email: 'ana.simic@example.com', phone: '+38598111007' },
  { first: 'Tomislav', last: 'Vukić', email: 't.vukic@example.com', phone: '+38598111008' },
  { first: 'Maja', last: 'Petrović', email: 'maja.petrovic@example.com', phone: '+38598111009' },
  { first: 'Dario', last: 'Knežević', email: 'dario.k@example.com', phone: '+38598111010' },
];

const CHANNELS = ['Direktno', 'Booking.com', 'Airbnb'];

// nights determines total_price (×130 EUR per night, mid-range price point).
// createdHoursAgo backdates `created_at` so AI nudge surfaces on pending rows
// (gate: oldest pending wait >= 6h).
const SEED = [
  { idx: 0, offsetIn: -28, nights: 3, status: 'completed', payment: 'paid',    createdHoursAgo: 700 },
  { idx: 1, offsetIn: -21, nights: 4, status: 'completed', payment: 'paid',    createdHoursAgo: 540 },
  { idx: 2, offsetIn: -14, nights: 2, status: 'completed', payment: 'paid',    createdHoursAgo: 360 },
  { idx: 3, offsetIn: -7,  nights: 3, status: 'completed', payment: 'paid',    createdHoursAgo: 200 },
  { idx: 4, offsetIn: -2,  nights: 5, status: 'confirmed', payment: 'partial', createdHoursAgo: 96  },
  { idx: 5, offsetIn:  1,  nights: 3, status: 'confirmed', payment: 'partial', createdHoursAgo: 72  }, // upcoming
  { idx: 6, offsetIn:  3,  nights: 2, status: 'confirmed', payment: 'partial', createdHoursAgo: 48  }, // upcoming
  { idx: 7, offsetIn:  5,  nights: 4, status: 'confirmed', payment: 'partial', createdHoursAgo: 28  },
  { idx: 8, offsetIn: 14,  nights: 3, status: 'pending',   payment: 'unpaid',  createdHoursAgo: 14  }, // oldest pending → drives AI nudge
  { idx: 9, offsetIn: 21,  nights: 2, status: 'pending',   payment: 'unpaid',  createdHoursAgo: 9   },
];

function hoursAgo(h) {
  const d = new Date(Date.now() - h * 60 * 60 * 1000);
  return Timestamp.fromDate(d);
}

const PRICE_PER_NIGHT = 130;

async function ensurePropertyAndUnit() {
  const propRef = db.doc(`properties/${PROPERTY_ID}`);
  const unitRef = db.doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}`);
  const [propSnap, unitSnap] = await Promise.all([propRef.get(), unitRef.get()]);
  if (!propSnap.exists) {
    console.error(`✗ Property ${PROPERTY_ID} missing. Run scripts/seed-bookbed-dev.js --test-owner first.`);
    process.exit(2);
  }
  if (!unitSnap.exists) {
    console.error(`✗ Unit ${UNIT_ID} missing. Run scripts/seed-bookbed-dev.js --test-owner first.`);
    process.exit(2);
  }
  // Ensure owner_id matches (defensive: protects against wrong-project run)
  if (propSnap.data().owner_id !== TEST_OWNER_UID) {
    console.error(`✗ Property owner_id mismatch — expected ${TEST_OWNER_UID}, got ${propSnap.data().owner_id}.`);
    process.exit(3);
  }
  console.log(`✓ Property ${PROPERTY_ID} + unit ${UNIT_ID} present, owner = ${TEST_OWNER_UID}`);
}

async function seedBookings() {
  console.log(`\nSeeding 10 premium bookings on ${projectId}/${PROPERTY_ID}/${UNIT_ID}\n`);
  let writeCount = 0;
  for (const s of SEED) {
    const g = GUESTS[s.idx];
    const channel = CHANNELS[s.idx % CHANNELS.length];
    const id = `SEED_premium_bk_${String(s.idx + 1).padStart(2, '0')}`;
    const ref = db.doc(`properties/${PROPERTY_ID}/bookings/${id}`);
    const existing = await ref.get();
    const cancellationToken = existing.exists
      ? (existing.data().cancellation_token || token32())
      : token32();

    const data = {
      booking_reference: `BB-${2400 + s.idx}`,
      status: s.status,
      payment_status: s.payment,
      property_id: PROPERTY_ID,
      unit_id: UNIT_ID,
      owner_id: TEST_OWNER_UID,
      guest_first_name: g.first,
      guest_last_name: g.last,
      guest_email: g.email,
      guest_phone: g.phone,
      adults: 2,
      children: 0,
      // Canonical field names read by unified_dashboard_provider.dart
      check_in: daysFromNow(s.offsetIn),
      check_out: daysFromNow(s.offsetIn + s.nights),
      nights: s.nights,
      total_price: s.nights * PRICE_PER_NIGHT,
      currency: 'EUR',
      source: channel,
      cancellation_token: cancellationToken,
      // Always set to the backdated stamp so re-runs refresh the wait-window
      // (drives the AI-nudge "Prioritet danas" gate on pending rows).
      created_at: hoursAgo(s.createdHoursAgo ?? 0),
      updated_at: FieldValue.serverTimestamp(),
    };

    if (dryRun) {
      console.log(`  ↩ DRY ${id} ${s.status.padEnd(9)} ${channel.padEnd(11)} ` +
        `check_in=${s.offsetIn>=0?'+':''}${s.offsetIn}d nights=${s.nights} ` +
        `€${data.total_price} guest=${g.first} ${g.last}`);
    } else {
      await ref.set(data, { merge: true });
      writeCount++;
      console.log(`  ✓ ${id} ${s.status.padEnd(9)} ${channel.padEnd(11)} ` +
        `check_in=${s.offsetIn>=0?'+':''}${s.offsetIn}d nights=${s.nights} ` +
        `€${data.total_price} guest=${g.first} ${g.last}`);
    }
  }
  console.log(`\n${dryRun ? 'Would write' : 'Wrote'} ${dryRun ? SEED.length : writeCount} bookings.`);
}

(async () => {
  console.log(`Pregled-premium seed → project ${projectId} ${dryRun ? '(DRY RUN)' : ''}`);
  await ensurePropertyAndUnit();
  await seedBookings();
  console.log('\nDone. Open https://bookbed-owner-dev.web.app → Pregled to verify.');
  process.exit(0);
})().catch((e) => {
  console.error('✗', e);
  process.exit(1);
});
