#!/usr/bin/env node
/**
 * seed-rezervacije-smoke-dev.js — comprehensive Rezervacije smoke fixtures on
 * bookbed-dev for the test owner (bookbed-test@bookbed.io / UID below).
 *
 * Self-contained + idempotent (fixed SEED_rez_smoke_* IDs, merge:true). Seeds
 * one property + two units (one long-named for overflow stress) and a ~20-row
 * booking matrix covering EVERY Rezervacije state path, plus an iCal feed + two
 * imported events for the Uvezene tab.
 *
 *   node scripts/seed-rezervacije-smoke-dev.js            # seed (project bookbed-dev)
 *   node scripts/seed-rezervacije-smoke-dev.js --delete   # remove everything it seeded
 *   node scripts/seed-rezervacije-smoke-dev.js --project=bookbed-dev
 *
 * Auth: Application Default Credentials — run once:
 *   gcloud auth application-default login && gcloud config set project bookbed-dev
 *
 * Admin SDK → bypasses Firestore rules. DEV ONLY. Never point at PROD.
 */
const path = require('path');
const adminPath = path.resolve(
  __dirname,
  '..',
  'functions',
  'node_modules',
  'firebase-admin',
);
const admin = require(adminPath);

const argv = process.argv.slice(2);
const DELETE = argv.includes('--delete');
const pIdx = argv.indexOf('--project');
const projectId = pIdx >= 0 ? argv[pIdx + 1] : 'bookbed-dev';

if (projectId !== 'bookbed-dev') {
  console.error('Refusing to run against non-dev project:', projectId, '— DEV ONLY.');
  process.exit(1);
}

admin.initializeApp({ projectId });
const db = admin.firestore();
const T = admin.firestore.Timestamp;

const OWNER = 'GILVItIVP5R8WXfnMmyMo1ykhUm2'; // bookbed-test@bookbed.io
const PROP = 'SEED_rez_smoke_property';
const UNIT_A = 'SEED_rez_smoke_unit_a';
const UNIT_B = 'SEED_rez_smoke_unit_b';
const FEED = 'SEED_rez_smoke_feed';
const BK = 'SEED_rez_smoke_bk_'; // booking id prefix
const EV = 'SEED_rez_smoke_ev_'; // ical event id prefix

const now = () => T.now();
function days(n) {
  const d = new Date();
  d.setUTCHours(12, 0, 0, 0);
  d.setUTCDate(d.getUTCDate() + n);
  return T.fromDate(d);
}

// ── State-matrix core (each path the operator must be able to act out) ──
const CORE = [
  // id, unit, ci, co, status, name, total, paid, source
  ['01', UNIT_A, 5, 8, 'pending', 'Petra Jurić', 520, 104, 'direct'],
  ['02', UNIT_A, 10, 14, 'confirmed', 'Ivan Perić', 900, 180, 'direct'],
  ['03', UNIT_B, -10, -7, 'confirmed', 'Luka Babić', 540, 540, 'direct'], // past → Završi
  ['04', UNIT_A, -2, 3, 'confirmed', 'Marko Horvat', 600, 120, 'direct'], // in-progress → only msg/edit
  ['05', UNIT_A, 6, 9, 'cancelled', 'Ana Šimić', 420, 0, 'direct'], // strike + — payment
  ['06', UNIT_B, -20, -17, 'completed', 'Eva Novak', 300, 300, 'direct'], // Završene tab
  ['07', UNIT_B, 12, 16, 'confirmed', 'Petra Jurić-Maksimović Vrlo Dugačko Prezime Za Overflow Test', 1200, 240, 'direct'],
  ['08', UNIT_A, 4, 7, 'pending', 'Sandra Kovač', 360, 0, 'direct'], // 0% paid
];

// ── Fillers to push past the windowed page (scroll + "Prikazano X" footer) ──
const FILLER_NAMES = [
  'Tomislav Vuković', 'Maja Kovačević', 'Josip Marić', 'Iva Babić',
  'Nikola Jurišić', 'Lana Petrović', 'Filip Horvat', 'Dora Knežević',
  'Ante Matić', 'Klara Novosel', 'Roko Šarić', 'Tena Vidović',
];
const FILLERS = FILLER_NAMES.map((name, i) => {
  const n = i + 9;
  const status = i % 3 === 0 ? 'completed' : 'confirmed';
  const past = status === 'completed';
  const ci = past ? -(30 + i) : 18 + i;
  const total = 300 + i * 45;
  const paid = i % 2 === 0 ? total : Math.round(total * 0.2);
  return [
    String(n).padStart(2, '0'),
    i % 2 === 0 ? UNIT_A : UNIT_B,
    ci, ci + 3, status, name, total, paid, 'direct',
  ];
});

const ALL = [...CORE, ...FILLERS];

function bookingDoc([id, unit, ci, co, status, name, total, paid]) {
  const [first, ...rest] = name.split(' ');
  const last = rest.join(' ');
  const nights = co - ci;
  return {
    unit_id: unit,
    owner_id: OWNER,
    property_id: PROP,
    check_in: days(ci),
    check_out: days(co),
    check_in_time: '14:00',
    check_out_time: '10:00',
    status,
    guest_name: name,
    guest_first_name: first,
    guest_last_name: last,
    guest_email: `${first.toLowerCase().replace(/[^a-z]/g, '')}@example.com`,
    guest_phone: `+3859800${id}`,
    booking_reference: `BB-SMOKE-${id}`,
    total_price: total,
    paid_amount: paid,
    deposit_amount: paid,
    remaining_amount: total - paid,
    payment_method: 'bank_transfer',
    payment_status: paid >= total && total > 0 ? 'paid' : 'pending',
    source: 'direct',
    guest_count: 2,
    pet_count: 0,
    adults: 2,
    nights: nights > 0 ? nights : 1,
    notes: 'Seeded for Rezervacije smoke test.',
    created_at: now(),
    updated_at: now(),
    ...(status === 'cancelled'
      ? { cancellation_reason: 'Smoke test', cancelled_at: now(), cancelled_by: OWNER }
      : {}),
  };
}

async function deleteCollection(ref) {
  const snap = await ref.get();
  if (snap.empty) return 0;
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
  return snap.size;
}

async function run() {
  const propRef = db.doc(`properties/${PROP}`);
  if (DELETE) {
    let n = 0;
    n += await deleteCollection(propRef.collection('bookings'));
    n += await deleteCollection(propRef.collection('ical_events'));
    n += await deleteCollection(propRef.collection('ical_feeds'));
    n += await deleteCollection(propRef.collection('units'));
    await propRef.delete().catch(() => {});
    console.log('✓ deleted property subtree', PROP, '— sub-docs removed:', n);
    return;
  }

  // Property + units
  await propRef.set(
    {
      owner_id: OWNER,
      name: 'Vila Smoke (Rezervacije test)',
      description: 'Seed fixture for Rezervacije smoke test.',
      property_type: 'villa',
      location: 'Rab, Hrvatska',
      is_active: true,
      currency: 'EUR',
      country: 'Croatia',
      created_at: now(),
      updated_at: now(),
    },
    { merge: true },
  );
  await propRef.collection('units').doc(UNIT_A).set(
    {
      property_id: PROP, owner_id: OWNER, name: 'Apartman A',
      base_price: 130, max_guests: 4, currency: 'EUR',
      created_at: now(), updated_at: now(),
    },
    { merge: true },
  );
  await propRef.collection('units').doc(UNIT_B).set(
    {
      property_id: PROP, owner_id: OWNER,
      name: 'Studio B — Premium Suite s Pogledom na More (dugačko ime)',
      base_price: 200, max_guests: 2, currency: 'EUR',
      created_at: now(), updated_at: now(),
    },
    { merge: true },
  );
  console.log('✓ property + units:', PROP, UNIT_A, UNIT_B);

  // Bookings
  const byStatus = {};
  for (const row of ALL) {
    const id = BK + row[0];
    await propRef.collection('bookings').doc(id).set(bookingDoc(row), { merge: true });
    byStatus[row[4]] = (byStatus[row[4]] || 0) + 1;
  }
  const seededCount = ALL.length;
  const statusSummary = JSON.stringify(byStatus);
  console.log('✓ bookings seeded:', seededCount, statusSummary);

  // iCal feed + imported events (Uvezene tab)
  await propRef.collection('ical_feeds').doc(FEED).set(
    {
      unit_id: UNIT_A, property_id: PROP, platform: 'booking_com',
      ical_url: 'https://ical.booking.com/seed-smoke.ics',
      import_enabled: true, sync_interval_minutes: 15, status: 'active',
      sync_count: 1, event_count: 2, created_at: now(), updated_at: now(),
    },
    { merge: true },
  );
  const events = [
    ['01', UNIT_A, 14, 17, 'Imported Booking.com Gost', 'booking_com'],
    ['02', UNIT_B, 22, 25, 'Imported Airbnb Gost', 'airbnb'],
  ];
  for (const [id, unit, ci, co, name, source] of events) {
    await propRef.collection('ical_events').doc(EV + id).set(
      {
        unit_id: unit, feed_id: FEED, start_date: days(ci), end_date: days(co),
        guest_name: name, source, external_id: `${source}_evt_${id}`,
        status: 'active', created_at: now(), updated_at: now(),
      },
      { merge: true },
    );
  }
  console.log('✓ ical feed + imported events:', FEED, events.length);
  console.log('Done. Owner UID', OWNER, 'property', PROP);
}

run().then(() => process.exit(0)).catch((e) => {
  console.error('SEED FAILED:', e.message || e);
  process.exit(1);
});
