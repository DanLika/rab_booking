#!/usr/bin/env node
/**
 * Idempotent seed for bookbed-dev smoke-test fixtures.
 *
 * Modes:
 *
 * 1. Wave 0 fixtures (default — preserves audit/07-chrome-smoke-test.md + audit/12-widget-e2e-dev.md):
 *
 *      /properties/SEED_property_dev_01
 *      /properties/SEED_property_dev_01/units/SEED_unit_dev_01
 *      /properties/SEED_property_dev_01/bookings/SEED_booking_dev_01   (only with --with-booking)
 *
 * 2. Test-owner onboarding (with --test-owner): unblocks the mobile smoke checklist for
 *    `bookbed-test@bookbed.io` (UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`). Without this, the
 *    router force-redirects to `/property-new` because `users/{UID}.onboardingCompleted=false`
 *    + `auth.users[UID].emailVerified=false`. Writes:
 *
 *      auth.users[UID].emailVerified = true                            (Admin SDK)
 *      /users/GILVItIVP5R8WXfnMmyMo1ykhUm2                              (owner role, onboarded)
 *      /properties/SEED_test_owner_property_01                         (owned by UID)
 *      /properties/SEED_test_owner_property_01/units/SEED_test_owner_unit_01
 *      /properties/SEED_test_owner_property_01/bookings/SEED_test_owner_booking_01
 *                                                                      (only with --with-booking)
 *
 * 3. E2E fixture extensions (audit/26 §7) — unblock DD (Stripe) + EE (iCal) flows:
 *
 *    --with-stripe-test-acct  Mock Stripe Connect fields on test-owner user + property.
 *                             MOCK ONLY — does not exercise real Stripe Test mode payments.
 *                             When combined with --with-widget-settings, also wires
 *                             `widget_settings.stripe_config.{enabled,stripe_account_id}`
 *                             so the widget UI surfaces the Stripe payment option.
 *
 *    --with-widget-settings   `properties/{pid}/widget_settings/{uid}` doc with
 *                             `ical_export_enabled=true` + 32-hex `ical_export_token`,
 *                             plus minimum production-shape fields. Unblocks EE iCal flow
 *                             (`getUnitIcalFeed` no longer 404s).
 *
 *    --everything             Shortcut for: --with-booking --with-stripe-test-acct
 *                             --with-widget-settings. Implies --test-owner.
 *
 * Auth: uses Application Default Credentials. Run
 *   gcloud auth application-default login
 * once if not set up.
 *
 * Usage:
 *   node scripts/seed-bookbed-dev.js                              # Wave 0 property + unit
 *   node scripts/seed-bookbed-dev.js --with-booking               # + Wave 0 booking
 *   node scripts/seed-bookbed-dev.js --test-owner                 # also seed test-owner data
 *   node scripts/seed-bookbed-dev.js --test-owner --with-booking  # both + bookings
 *   node scripts/seed-bookbed-dev.js --test-owner --with-stripe-test-acct
 *   node scripts/seed-bookbed-dev.js --test-owner --with-widget-settings
 *   node scripts/seed-bookbed-dev.js --test-owner --everything    # all test-owner fixtures
 *   node scripts/seed-bookbed-dev.js --help                       # show this help
 *   node scripts/seed-bookbed-dev.js --project=bookbed-staging    # alt project (default bookbed-dev)
 *
 * Safe to re-run — uses set({merge: true}) on existing doc IDs.
 *
 * DD flow caveat: --with-stripe-test-acct writes a synthetic `acct_TEST_E2E_DD`
 * Connect ID. Real Stripe Test-mode charges require a live test acct via the
 * Stripe Dashboard. The fixture is presence-only — sufficient for UI surfacing
 * + DB-layer assertions, NOT for end-to-end payment intent processing.
 */

const path = require('path');

const args = process.argv.slice(2);

if (args.includes('--help') || args.includes('-h')) {
  // Re-print the header comment block for `--help`.
  const fs = require('fs');
  const self = fs.readFileSync(__filename, 'utf8');
  const headerMatch = self.match(/^#![^\n]*\n\/\*\*([\s\S]*?)\*\//);
  if (headerMatch) {
    const cleaned = headerMatch[1]
      .split('\n')
      .map((l) => l.replace(/^\s*\*\s?/, ''))
      .join('\n');
    console.log(cleaned.trim());
  } else {
    console.log('See header in scripts/seed-bookbed-dev.js for usage.');
  }
  process.exit(0);
}

const everything = args.includes('--everything');
const withBooking = args.includes('--with-booking') || everything;
// --everything implies --test-owner since all extended fixtures target test-owner IDs.
const seedTestOwnerFlag = args.includes('--test-owner') || everything;
const withStripeTestAcct = args.includes('--with-stripe-test-acct') || everything;
const withWidgetSettings = args.includes('--with-widget-settings') || everything;
const projectArg = args.find((a) => a.startsWith('--project='));
const projectId = projectArg ? projectArg.split('=')[1] : 'bookbed-dev';

if ((withStripeTestAcct || withWidgetSettings) && !seedTestOwnerFlag) {
  console.error(
    'Error: --with-stripe-test-acct and --with-widget-settings target the test-owner\n' +
    'fixtures (SEED_test_owner_*). Pass --test-owner (or use --everything).',
  );
  process.exit(1);
}

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

// Test-owner onboarding fixtures (--test-owner mode)
const TEST_OWNER_UID = 'GILVItIVP5R8WXfnMmyMo1ykhUm2';
const TEST_OWNER_EMAIL = 'bookbed-test@bookbed.io';
const TEST_OWNER_PROPERTY_ID = 'SEED_test_owner_property_01';
const TEST_OWNER_UNIT_ID = 'SEED_test_owner_unit_01';
const TEST_OWNER_BOOKING_ID = 'SEED_test_owner_booking_01';

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

async function seedTestOwner() {
  console.log(`Seeding test-owner data (UID=${TEST_OWNER_UID}, withBooking=${withBooking})`);

  // 1. Flip Firebase Auth emailVerified=true. Auth's emailVerified is the source
  //    of truth — Firestore users/{UID}.emailVerified is NOT trusted by the router
  //    (enhanced_auth_provider.dart: "Do NOT trust Firestore userModel.emailVerified").
  try {
    await admin.auth().updateUser(TEST_OWNER_UID, {emailVerified: true});
    console.log(`  ✓ auth.users[${TEST_OWNER_UID}].emailVerified = true`);
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      console.error(
        `  ✗ Auth user ${TEST_OWNER_UID} not found in project ${projectId}.\n` +
        `    Recreate via REST signUp (see memory/test-account.md) then re-run.`,
      );
      throw err;
    }
    throw err;
  }

  // 2. Idempotency probe — if user doc already says onboarded AND seed property
  //    exists, skip the writes. Honors the "Idempotent — skip if seeded user
  //    already has property" requirement.
  const userRef = db.doc(`users/${TEST_OWNER_UID}`);
  const userSnap = await userRef.get();
  const propRef = db.doc(`properties/${TEST_OWNER_PROPERTY_ID}`);
  const propSnap = await propRef.get();
  const alreadySeeded =
    userSnap.exists &&
    userSnap.data().onboardingCompleted === true &&
    propSnap.exists &&
    propSnap.data().owner_id === TEST_OWNER_UID;

  if (alreadySeeded && !withBooking) {
    console.log('  ⏭  test-owner already seeded (user onboarded + property present) — skipping');
    return;
  }
  if (alreadySeeded) {
    console.log('  ↻ test-owner core already seeded — refreshing booking only');
  }

  // 3. users/{UID} — owner role, onboarding complete. Field names mirror what
  //    enhanced_auth_provider.dart reads on lines 252–270 (mixed snake_case and
  //    camelCase — preserved exactly).
  if (!alreadySeeded) {
    await userRef.set(
      {
        email: TEST_OWNER_EMAIL,
        first_name: 'BookBed',
        last_name: 'Test',
        role: 'owner',
        accountType: 'trial',
        emailVerified: true, // mirrors auth flag for UI display
        onboardingCompleted: true,
        profile_completed: true,
        displayName: 'BookBed Test',
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    console.log(`  ✓ users/${TEST_OWNER_UID}`);

    // 4. properties/{id} — shape matches firebase_owner_properties_repository.dart
    //    createProperty() (lines 191–211). is_active=true so router treats user as
    //    having a usable property.
    await propRef.set(
      {
        owner_id: TEST_OWNER_UID,
        name: 'BookBed Test Villa',
        slug: 'bookbed-test-villa',
        subdomain: 'bookbed-test',
        description: 'Seeded test property for mobile/web smoke runs. Do not delete.',
        property_type: 'villa',
        location: 'Rab',
        city: 'Rab',
        address: 'Seed Address 1',
        latitude: 44.7596,
        longitude: 14.7574,
        amenities: ['wifi', 'parking', 'pool'],
        images: [],
        cover_image: null,
        is_active: true,
        currency: 'EUR',
        country: 'HR',
        rating: 0.0,
        review_count: 0,
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    console.log(`  ✓ properties/${TEST_OWNER_PROPERTY_ID}`);

    // 5. properties/{id}/units/{id}
    const unitRef = db.doc(`properties/${TEST_OWNER_PROPERTY_ID}/units/${TEST_OWNER_UNIT_ID}`);
    await unitRef.set(
      {
        name: 'Apartman A',
        base_price: 100,
        weekend_base_price: 130,
        weekend_days: [5, 6],
        max_guests: 4,
        is_available: true,
        currency: 'EUR',
        property_id: TEST_OWNER_PROPERTY_ID,
        owner_id: TEST_OWNER_UID,
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    console.log(`  ✓ units/${TEST_OWNER_UNIT_ID}`);
  }

  // 6. Optional past booking — gives calendar a non-empty render.
  if (withBooking) {
    const bookingRef = db.doc(
      `properties/${TEST_OWNER_PROPERTY_ID}/bookings/${TEST_OWNER_BOOKING_ID}`,
    );
    const existing = await bookingRef.get();
    const cancellationToken = existing.exists
      ? existing.data().cancellation_token || randomToken()
      : randomToken();

    await bookingRef.set(
      {
        booking_reference: 'BB-SEEDTO1',
        status: 'completed',
        payment_status: 'paid',
        property_id: TEST_OWNER_PROPERTY_ID,
        unit_id: TEST_OWNER_UNIT_ID,
        owner_id: TEST_OWNER_UID,
        guest_first_name: 'Past',
        guest_last_name: 'Guest',
        guest_email: 'past-guest@example.com',
        guest_phone: '+38598000111',
        adults: 2,
        children: 0,
        check_in_date: daysFromNow(-14),
        check_out_date: daysFromNow(-11),
        nights: 3,
        total_price: 300,
        currency: 'EUR',
        cancellation_token: cancellationToken,
        created_at: existing.exists
          ? existing.data().created_at || FieldValue.serverTimestamp()
          : FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    console.log(`  ✓ bookings/${TEST_OWNER_BOOKING_ID} (status=completed, past)`);
  }
}

// --with-stripe-test-acct mock Stripe Connect account ID. NOT a real Stripe
// account — DD payment flow against this fixture requires either Stripe
// Test-mode setup OR a widget feature flag to mock payment processing.
const STRIPE_TEST_ACCT_ID = 'acct_TEST_E2E_DD';

async function seedStripeTestAcct() {
  console.log(`Seeding mock Stripe Connect fields (acct=${STRIPE_TEST_ACCT_ID})`);

  const userRef = db.doc(`users/${TEST_OWNER_UID}`);
  const existing = await userRef.get();
  if (existing.exists && existing.data().stripe_account_id === STRIPE_TEST_ACCT_ID) {
    console.log('  ⏭  users.stripe_account_id already set to mock id — skipping user write');
  } else {
    await userRef.set(
      {
        stripe_account_id: STRIPE_TEST_ACCT_ID,
        // Mirror fields named per task spec audit/26 §7. NOT read by production
        // code today (Stripe Connect status is fetched live from Stripe API in
        // stripeConnect.ts/stripePayment.ts), but reserved for future caching
        // and for fixture-presence assertions in E2E tests.
        stripe_charges_enabled: true,
        stripe_payouts_enabled: true,
        stripe_details_submitted: true,
        stripe_connected_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    console.log(`  ✓ users/${TEST_OWNER_UID}.stripe_*`);
  }

  const propertyRef = db.doc(`properties/${TEST_OWNER_PROPERTY_ID}`);
  const propSnap = await propertyRef.get();
  if (propSnap.exists && propSnap.data().stripe_payments_enabled === true) {
    console.log('  ⏭  properties.stripe_payments_enabled already true — skipping property write');
  } else {
    await propertyRef.set(
      {
        stripe_payments_enabled: true,
        updated_at: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    console.log(`  ✓ properties/${TEST_OWNER_PROPERTY_ID}.stripe_payments_enabled`);
  }
}

async function seedWidgetSettings() {
  console.log(`Seeding widget_settings for ${TEST_OWNER_PROPERTY_ID}/${TEST_OWNER_UNIT_ID}`);

  const settingsRef = db.doc(
    `properties/${TEST_OWNER_PROPERTY_ID}/widget_settings/${TEST_OWNER_UNIT_ID}`,
  );
  const existing = await settingsRef.get();
  const existingData = existing.exists ? existing.data() : {};

  // Preserve existing token if already seeded (idempotent — keeps iCal URLs stable).
  const icalToken = existingData.ical_export_token || randomToken();

  // Combined-flag enhancement: when --with-stripe-test-acct also present, wire
  // stripe_config so the widget UI surfaces the Stripe payment option. Without
  // this, the user/property mock Stripe fields don't reach the widget render path.
  const stripeConfig = withStripeTestAcct
    ? {
        enabled: true,
        deposit_percentage: 20,
        stripe_account_id: STRIPE_TEST_ACCT_ID,
      }
    : existingData.stripe_config || null;

  const payload = {
    property_id: TEST_OWNER_PROPERTY_ID,
    owner_id: TEST_OWNER_UID,
    widget_mode: existingData.widget_mode || 'booking_instant',
    ical_export_enabled: true,
    ical_export_token: icalToken,
    // currency/language not currently read by WidgetSettings.fromFirestore;
    // included per audit/26 §7 spec for forward-compat + intent documentation.
    currency: 'EUR',
    language: 'hr',
    min_nights: existingData.min_nights || 1,
    min_days_advance: existingData.min_days_advance || 0,
    max_days_advance: existingData.max_days_advance || 365,
    weekend_days: existingData.weekend_days || [5, 6],
    allow_pay_on_arrival: existingData.allow_pay_on_arrival ?? false,
    allow_guest_cancellation: existingData.allow_guest_cancellation ?? true,
    cancellation_deadline_hours: existingData.cancellation_deadline_hours || 48,
    created_at: existingData.created_at || FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
  };

  if (stripeConfig) {
    payload.stripe_config = stripeConfig;
  }

  await settingsRef.set(payload, {merge: true});
  console.log(
    `  ✓ widget_settings/${TEST_OWNER_UNIT_ID} ` +
      `(ical_export_enabled=true, token=${icalToken.slice(0, 8)}...` +
      (withStripeTestAcct ? `, stripe_config.enabled=true` : '') +
      `)`,
  );
}

async function seed() {
  console.log(
    `Seeding project=${projectId} ` +
      `(withBooking=${withBooking}, testOwner=${seedTestOwnerFlag}, ` +
      `stripeTestAcct=${withStripeTestAcct}, widgetSettings=${withWidgetSettings})`,
  );

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

  if (seedTestOwnerFlag) {
    await seedTestOwner();
  }

  if (withStripeTestAcct) {
    await seedStripeTestAcct();
  }

  if (withWidgetSettings) {
    await seedWidgetSettings();
  }

  console.log('Done.');
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
