#!/usr/bin/env node
/**
 * Edge-case data-integrity test fixtures on bookbed-dev.
 *
 * Seeds:
 *   /properties/EDGE_prop_0530                              (test_artifact:true)
 *   /properties/EDGE_prop_0530/units/EDGE_unit_0530        (test_artifact:true,
 *                                                          base_price=100, weekend=150)
 *   /properties/EDGE_prop_0530/units/EDGE_unit_0530/daily_prices/{N dates}
 *   /properties/EDGE_prop_0530/widget_settings/EDGE_unit_0530
 *   /properties/EDGE_prop_0530/units/EDGE_unit_zero        (base_price=0.10 — €0.50 floor test)
 *
 * Owned by TEST_OWNER_UID (bookbed-test@bookbed.io).
 *
 * Cleanup: node seed.js --cleanup
 *
 * Auth: ADC, ENV GCLOUD_PROJECT=bookbed-dev.
 */

const path = require('path');

// Worktree node_modules isn't installed — fall back to main repo's copy.
const candidatePaths = [
  path.resolve(__dirname, '..', '..', 'functions', 'node_modules', 'firebase-admin'),
  path.resolve('/Users/duskolicanin/git/bookbed/functions/node_modules/firebase-admin'),
];
let admin;
for (const p of candidatePaths) {
  try {
    admin = require(p);
    break;
  } catch (_) { /* try next */ }
}
if (!admin) {
  console.error('firebase-admin not found in:', candidatePaths.join(' OR '));
  process.exit(2);
}

const PROJECT_ID = 'bookbed-dev';
if (process.env.GCLOUD_PROJECT && process.env.GCLOUD_PROJECT !== PROJECT_ID) {
  console.error(`Refusing to seed: GCLOUD_PROJECT=${process.env.GCLOUD_PROJECT} != ${PROJECT_ID}`);
  process.exit(1);
}

admin.initializeApp({projectId: PROJECT_ID});
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

const TEST_OWNER_UID = 'GILVItIVP5R8WXfnMmyMo1ykhUm2';
const PROP_ID = 'EDGE_prop_0530';
const UNIT_ID = 'EDGE_unit_0530';
const UNIT_ZERO_ID = 'EDGE_unit_zero';
const RUN_ID = 'edge-0530';

const TAG = {
  test_artifact: true,
  test_run_id: RUN_ID,
};

function zagrebDayUTC(yyyy, mm, dd) {
  return Timestamp.fromDate(new Date(Date.UTC(yyyy, mm - 1, dd)));
}

async function seedCore() {
  console.log(`Seeding edge fixtures on ${PROJECT_ID} for owner ${TEST_OWNER_UID}`);

  await db.doc(`properties/${PROP_ID}`).set(
    {
      owner_id: TEST_OWNER_UID,
      name: 'EDGE Test Villa',
      slug: 'edge-test-villa',
      subdomain: 'edge-test-0530',
      description: 'Seeded for data-integrity edge tests. Auto-cleanup.',
      property_type: 'villa',
      location: 'Rab',
      city: 'Rab',
      address: 'Edge Address 1',
      latitude: 44.7596,
      longitude: 14.7574,
      amenities: ['wifi'],
      images: [],
      cover_image: null,
      is_active: true,
      currency: 'EUR',
      country: 'HR',
      rating: 0.0,
      review_count: 0,
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
      ...TAG,
    },
    {merge: true},
  );
  console.log(`  ✓ properties/${PROP_ID}`);

  await db.doc(`properties/${PROP_ID}/units/${UNIT_ID}`).set(
    {
      name: 'Edge Unit',
      base_price: 100,
      weekend_base_price: 150,
      weekend_days: [5, 6],   // Fri/Sat in JS getDay()
      max_guests: 4,
      max_total_capacity: 4,
      min_stay_nights: 1,
      is_available: true,
      currency: 'EUR',
      property_id: PROP_ID,
      owner_id: TEST_OWNER_UID,
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
      ...TAG,
    },
    {merge: true},
  );
  console.log(`  ✓ units/${UNIT_ID}`);

  // Unit with €0.10 base price for Stripe €0.50 floor test (T6.b)
  await db.doc(`properties/${PROP_ID}/units/${UNIT_ZERO_ID}`).set(
    {
      name: 'Edge Unit (low price)',
      base_price: 0.10,
      weekend_base_price: 0.10,
      weekend_days: [5, 6],
      max_guests: 2,
      max_total_capacity: 2,
      min_stay_nights: 1,
      is_available: true,
      currency: 'EUR',
      property_id: PROP_ID,
      owner_id: TEST_OWNER_UID,
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
      ...TAG,
    },
    {merge: true},
  );
  console.log(`  ✓ units/${UNIT_ZERO_ID}`);

  // Daily-price override on a Tuesday (non-weekend) to test override priority
  // 2026-06-09 Tue 100→200 override; 2026-06-10 Wed (no override → fallback 100);
  // 2026-06-12 Fri (no override → weekend 150); 2026-06-13 Sat (no override → 150)
  // 2026-06-14 Sun (no override → 100); 2026-06-15 Mon (with available=false → blocked)
  const dailyPricesPath = `properties/${PROP_ID}/units/${UNIT_ID}/daily_prices`;
  await db.doc(`${dailyPricesPath}/2026-06-09`).set({
    date: zagrebDayUTC(2026, 6, 9),
    price: 200,
    available: true,
    ...TAG,
  });
  await db.doc(`${dailyPricesPath}/2026-06-15`).set({
    date: zagrebDayUTC(2026, 6, 15),
    price: 100,
    available: false,    // blocked by owner
    ...TAG,
  });
  // 2026-07-01: a manual-block day for the inclusive-end-window test (T3)
  await db.doc(`${dailyPricesPath}/2026-07-01`).set({
    date: zagrebDayUTC(2026, 7, 1),
    price: 100,
    available: false,
    ...TAG,
  });
  console.log(`  ✓ daily_prices: 2026-06-09 override, 2026-06-15 + 2026-07-01 blocked`);

  // widget_settings allows getUnitAvailability to succeed without 404 fallback
  await db.doc(`properties/${PROP_ID}/widget_settings/${UNIT_ID}`).set({
    enabled: true,
    show_calendar: true,
    show_pricing: true,
    auto_confirm: false,
    require_owner_approval: true,
    require_email_verification: false,
    available_payment_methods: ['pay_on_arrival'],
    deposit_percentage: 30,
    ...TAG,
  }, {merge: true});
  console.log(`  ✓ widget_settings/${UNIT_ID}`);

  console.log('\nSeed complete.');
}

async function cleanup() {
  console.log(`Cleanup: deleting all docs tagged test_run_id="${RUN_ID}" on ${PROJECT_ID}`);
  let deleted = 0;

  // Direct path delete — descendants need separate handling.
  const paths = [
    `properties/${PROP_ID}/units/${UNIT_ID}`,
    `properties/${PROP_ID}/units/${UNIT_ZERO_ID}`,
    `properties/${PROP_ID}/widget_settings/${UNIT_ID}`,
    `properties/${PROP_ID}`,
  ];

  // First: daily_prices subcollection
  const dailyPricesSnap = await db
    .collection(`properties/${PROP_ID}/units/${UNIT_ID}/daily_prices`)
    .get();
  for (const doc of dailyPricesSnap.docs) {
    await doc.ref.delete();
    deleted++;
  }
  console.log(`  ✓ daily_prices (${dailyPricesSnap.size} docs)`);

  // bookings under this prop (atomic + owner-create writes target subcoll)
  const bookingsSnap = await db
    .collection(`properties/${PROP_ID}/bookings`)
    .where('test_run_id', '==', RUN_ID)
    .get();
  for (const doc of bookingsSnap.docs) {
    await doc.ref.delete();
    deleted++;
  }
  // also legacy unit-bookings subcoll if any
  const legBookingsSnap = await db
    .collection(`properties/${PROP_ID}/units/${UNIT_ID}/bookings`)
    .get();
  for (const doc of legBookingsSnap.docs) {
    await doc.ref.delete();
    deleted++;
  }
  console.log(`  ✓ bookings (${bookingsSnap.size + legBookingsSnap.size} docs)`);

  // ical_events under this unit
  const icalSnap = await db
    .collection(`properties/${PROP_ID}/units/${UNIT_ID}/ical_events`)
    .get();
  for (const doc of icalSnap.docs) {
    await doc.ref.delete();
    deleted++;
  }
  console.log(`  ✓ ical_events (${icalSnap.size} docs)`);

  // ical_feeds under this unit
  const feedsSnap = await db
    .collection(`properties/${PROP_ID}/units/${UNIT_ID}/ical_feeds`)
    .get();
  for (const doc of feedsSnap.docs) {
    await doc.ref.delete();
    deleted++;
  }
  console.log(`  ✓ ical_feeds (${feedsSnap.size} docs)`);

  for (const p of paths) {
    try {
      await db.doc(p).delete();
      deleted++;
    } catch (e) { /* ignore */ }
  }
  console.log(`  ✓ root docs (${paths.length})`);

  console.log(`\nCleanup complete: ${deleted} docs deleted.`);
}

(async () => {
  try {
    if (process.argv.includes('--cleanup')) {
      await cleanup();
    } else {
      await seedCore();
    }
  } catch (e) {
    console.error('ERR:', e.message);
    process.exit(2);
  }
  process.exit(0);
})();
