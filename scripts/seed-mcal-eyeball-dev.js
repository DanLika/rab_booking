#!/usr/bin/env node
/**
 * Temp eyeball seed for the Mjesečni (month) calendar premium-chrome fidelity
 * pass. Adds CANONICAL-shape bookings (check_in / check_out — NOT the legacy
 * check_in_date that scripts/seed-bookbed-dev.js writes, which BookingModel does
 * not parse) spread across the CURRENT month so the month grid renders real
 * appointments to tap + swipe over.
 *
 * Targets the test-owner fixture (run `node scripts/seed-bookbed-dev.js
 * --test-owner` first for onboarding + property/unit):
 *   property SEED_test_owner_property_01 / unit SEED_test_owner_unit_01
 *   owner    GILVItIVP5R8WXfnMmyMo1ykhUm2 (bookbed-test@bookbed.io)
 *
 * Idempotent (fixed MCAL_* doc ids + merge). Auth: Application Default
 * Credentials. Default project bookbed-dev; refuses PROD.
 *
 * Usage: node scripts/seed-mcal-eyeball-dev.js
 */
const path = require('path');
const admin = require(
  path.resolve(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'),
);

const projectArg = process.argv.find((a) => a.startsWith('--project='));
const projectId = projectArg ? projectArg.split('=')[1] : 'bookbed-dev';

if (projectId === 'rab-booking-248fc') {
  console.error('✗ Refusing to seed PROD (rab-booking-248fc). Aborting.');
  process.exit(1);
}

admin.initializeApp({projectId});
const db = admin.firestore();
const {FieldValue} = admin.firestore;

const OWNER_UID = 'GILVItIVP5R8WXfnMmyMo1ykhUm2';
// Uniquely-named unit ("Studio B — Premium Suite…") so it is unambiguous in the
// unit-filter dropdown (the test owner has two units both named "Apartman A").
const PROPERTY_ID = 'SEED_rez_smoke_property';
const UNIT_ID = 'SEED_rez_smoke_unit_b';

// Current month = June 2026 (Lipanj). UTC midnight to match the repository's
// DateTime.utc map keys. month index 5 = June.
function ts(y, m, d) {
  return admin.firestore.Timestamp.fromDate(new Date(Date.UTC(y, m, d)));
}

const Y = 2026;
const M = 5; // June

// Spread across the month: early / mid / late, mixed statuses, empty gaps, no
// same-unit overlaps (keeps the overbooking badge quiet for a clean read).
const BOOKINGS = [
  {id: 'MCAL_01', status: 'confirmed', inD: 4, outD: 7, name: 'Ana Kovač', price: 360},
  {id: 'MCAL_02', status: 'pending', inD: 9, outD: 11, name: 'Marko Horvat', price: 240},
  {id: 'MCAL_03', status: 'completed', inD: 13, outD: 15, name: 'Iva Novak', price: 220},
  {id: 'MCAL_04', status: 'confirmed', inD: 20, outD: 24, name: 'Luka Marić', price: 520},
  {id: 'MCAL_05', status: 'pending', inD: 26, outD: 28, name: 'Petra Babić', price: 260},
];

async function main() {
  console.log(`Seeding month-calendar eyeball bookings → project=${projectId}`);
  for (const b of BOOKINGS) {
    const ref = db.doc(`properties/${PROPERTY_ID}/bookings/${b.id}`);
    const nights = b.outD - b.inD;
    await ref.set(
      {
        booking_reference: `BB-${b.id}`,
        status: b.status,
        payment_status: b.status === 'pending' ? 'unpaid' : 'paid',
        property_id: PROPERTY_ID,
        unit_id: UNIT_ID,
        owner_id: OWNER_UID,
        guest_name: b.name,
        guest_first_name: b.name.split(' ')[0],
        guest_last_name: b.name.split(' ')[1] || '',
        guest_email: `${b.id.toLowerCase()}@example.com`,
        guest_phone: '+38598000222',
        adults: 2,
        children: 0,
        guest_count: 2,
        check_in: ts(Y, M, b.inD),
        check_out: ts(Y, M, b.outD),
        nights,
        total_price: b.price,
        currency: 'EUR',
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    console.log(
      `  ✓ ${b.id} ${b.status} ${Y}-06-${String(b.inD).padStart(2, '0')}→${b.outD} (${b.name})`,
    );
  }
  console.log('Done.');
  process.exit(0);
}

main().catch((e) => {
  console.error('✗ Seed failed:', e);
  process.exit(1);
});
