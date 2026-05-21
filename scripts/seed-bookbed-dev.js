#!/usr/bin/env node
/**
 * Idempotent seed for bookbed-dev smoke-test fixtures.
 *
 * Writes (or refreshes) the three Wave 0 docs referenced in audit/07-chrome-smoke-test.md
 * and audit/12-widget-e2e-dev.md:
 *
 *   /properties/SEED_property_dev_01
 *   /properties/SEED_property_dev_01/units/SEED_unit_dev_01
 *   /properties/SEED_property_dev_01/bookings/SEED_booking_dev_01  (only with --with-booking)
 *
 * Reconstructed from audit/07 spec (the original script was local to a prior session and
 * never landed in the repo — see audit/11-sentry-env-fix.md line 83).
 *
 * Auth: uses Application Default Credentials. Run
 *   gcloud auth application-default login
 * once if not set up.
 *
 * Usage:
 *   node scripts/seed-bookbed-dev.js                 # property + unit only
 *   node scripts/seed-bookbed-dev.js --with-booking  # also writes SEED_booking_dev_01
 *   node scripts/seed-bookbed-dev.js --project=bookbed-staging  # alt project (defaults to bookbed-dev)
 *
 * Safe to re-run — uses set({merge: true}) on existing doc IDs.
 */

const path = require('path');

const args = process.argv.slice(2);
const withBooking = args.includes('--with-booking');
const projectArg = args.find((a) => a.startsWith('--project='));
const projectId = projectArg ? projectArg.split('=')[1] : 'bookbed-dev';

if (projectId === 'rab-booking-248fc') {
  console.error('Refusing to seed PROD (rab-booking-248fc). This script is dev-only.');
  process.exit(1);
}

const adminPath = path.resolve(__dirname, '..', 'functions', 'node_modules', 'firebase-admin');
let admin;
try {
  admin = require(adminPath);
} catch (e) {
  console.error('firebase-admin not found at', adminPath);
  console.error('Run `cd functions && npm install` first.');
  process.exit(1);
}

admin.initializeApp({projectId});
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const PROPERTY_ID = 'SEED_property_dev_01';
const UNIT_ID = 'SEED_unit_dev_01';
const BOOKING_ID = 'SEED_booking_dev_01';
const OWNER_UID = 'Zo01CJ3wymb0pplaYOyaZ2yGUWG2';

function daysFromNow(days) {
  const d = new Date();
  d.setUTCHours(12, 0, 0, 0);
  d.setUTCDate(d.getUTCDate() + days);
  return admin.firestore.Timestamp.fromDate(d);
}

function randomToken() {
  // 32 hex chars — same shape as the production cancellation_token field.
  let s = '';
  for (let i = 0; i < 32; i++) s += Math.floor(Math.random() * 16).toString(16);
  return s;
}

async function seed() {
  console.log(`Seeding project=${projectId} (withBooking=${withBooking})`);

  const propertyRef = db.doc(`properties/${PROPERTY_ID}`);
  await propertyRef.set(
    {
      name: 'BookBed Dev Test Villa',
      subdomain: 'seed-dev',
      owner_id: OWNER_UID,
      is_active: true,
      currency: 'EUR',
      country: 'HR',
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
  console.log(`  ✓ property ${PROPERTY_ID}`);

  const unitRef = db.doc(`properties/${PROPERTY_ID}/units/${UNIT_ID}`);
  await unitRef.set(
    {
      name: 'Apartman 1',
      base_price: 120,
      weekend_base_price: 150,
      weekend_days: [5, 6],
      max_guests: 4,
      is_available: true,
      currency: 'EUR',
      property_id: PROPERTY_ID,
      owner_id: OWNER_UID,
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
  console.log(`  ✓ unit ${UNIT_ID}`);

  if (withBooking) {
    const bookingRef = db.doc(`properties/${PROPERTY_ID}/bookings/${BOOKING_ID}`);
    const existing = await bookingRef.get();
    const cancellationToken = existing.exists ? existing.data().cancellation_token || randomToken() : randomToken();

    await bookingRef.set(
      {
        booking_reference: 'BB-SEED01',
        status: 'confirmed',
        payment_status: 'paid',
        property_id: PROPERTY_ID,
        unit_id: UNIT_ID,
        owner_id: OWNER_UID,
        guest_first_name: 'Seed',
        guest_last_name: 'Guest',
        guest_email: 'seed-guest@example.com',
        guest_phone: '+38598000000',
        adults: 2,
        children: 0,
        check_in_date: daysFromNow(30),
        check_out_date: daysFromNow(33),
        nights: 3,
        total_price: 360,
        currency: 'EUR',
        cancellation_token: cancellationToken,
        created_at: existing.exists ? existing.data().created_at || FieldValue.serverTimestamp() : FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    console.log(`  ✓ booking ${BOOKING_ID} (ref=BB-SEED01, token=${cancellationToken.slice(0, 8)}...)`);
  }

  console.log('Done.');
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
