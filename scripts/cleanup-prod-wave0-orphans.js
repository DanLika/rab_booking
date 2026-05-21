#!/usr/bin/env node
/**
 * Cleanup PROD Wave 0 orphan artifacts.
 *
 * Removes the contamination documented in audit/14 + audit/15:
 *   - Auth user wave0-smoke-202605181440@bookbed.test (UID qoN6...)
 *   - users/{UID} Firestore doc
 *   - properties/{PROP_ID} + nested units + bookings
 *   - Stripe Connect acct_1TYSMdPWhhVc6lN0 — NOT dissolved by this script
 *
 * SAFETY GATES:
 *   1. Defaults to --dry-run (prints what WOULD delete, deletes nothing).
 *      Pass --execute to actually delete.
 *   2. Before delete: verifies Stripe Connect account acct_1TYSMdPWhhVc6lN0
 *      is REJECTED/DELETED via Stripe API (requires STRIPE_LIVE_SECRET_KEY
 *      env var). If the account is still active, refuses to proceed.
 *   3. Idempotent — each delete checks existence first.
 *
 * Usage:
 *   STRIPE_LIVE_SECRET_KEY=sk_live_... node scripts/cleanup-prod-wave0-orphans.js
 *      → dry run, prints plan
 *   STRIPE_LIVE_SECRET_KEY=sk_live_... node scripts/cleanup-prod-wave0-orphans.js --execute
 *      → actually deletes
 *
 * Logs to: audit/migrations/<ISO-date>-prod-wave0-cleanup.log
 *
 * Refuses to run against any project other than rab-booking-248fc.
 */

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const EXECUTE = args.includes('--execute');
const SKIP_STRIPE_CHECK = args.includes('--skip-stripe-check'); // emergency override

const PROJECT_ID = 'rab-booking-248fc';
const TEST_UID = 'qoN6aykKwqZI4n9REgqXfEFG8KM2';
const TEST_EMAIL = 'wave0-smoke-202605181440@bookbed.test';
const TEST_PROPERTY_ID = '6VCCLt8rnSokrIani9oU';
const TEST_UNIT_ID = 'seg85UhyMQM8hw7ZpLhq';
const STRIPE_ACCT = 'acct_1TYSMdPWhhVc6lN0';

const isoDate = new Date().toISOString().slice(0, 10);
const logDir = path.join(__dirname, '..', 'audit', 'migrations');
fs.mkdirSync(logDir, { recursive: true });
const logPath = path.join(logDir, `${isoDate}-prod-wave0-cleanup.log`);
const logStream = fs.createWriteStream(logPath, { flags: 'a' });

function log(level, msg) {
  const line = `[${new Date().toISOString()}] ${level} ${msg}`;
  process.stdout.write(line + '\n');
  logStream.write(line + '\n');
}

async function main() {
  log('INFO', `cleanup-prod-wave0-orphans starting (dryRun=${!EXECUTE})`);
  log('INFO', `target project: ${PROJECT_ID}`);
  log('INFO', `target UID: ${TEST_UID}`);
  log('INFO', `target email: ${TEST_EMAIL}`);
  log('INFO', `target property: ${TEST_PROPERTY_ID} / unit: ${TEST_UNIT_ID}`);
  log('INFO', `Stripe Connect account (not dissolved by this script): ${STRIPE_ACCT}`);

  // ----- Stripe pre-flight check -----
  if (!SKIP_STRIPE_CHECK) {
    const stripeKey = process.env.STRIPE_LIVE_SECRET_KEY;
    if (!stripeKey || !stripeKey.startsWith('sk_live_')) {
      log('ERROR', 'STRIPE_LIVE_SECRET_KEY env var missing or not a live key (expected sk_live_...).');
      log('ERROR', 'Cannot verify Stripe Connect account state. Refusing to proceed.');
      log('ERROR', 'If you have manually dissolved the account via Stripe Dashboard, rerun with --skip-stripe-check.');
      process.exit(1);
    }

    let Stripe;
    try {
      Stripe = require(path.resolve(__dirname, '..', 'functions', 'node_modules', 'stripe'));
    } catch (e) {
      log('ERROR', `stripe SDK not found in functions/node_modules: ${e.message}`);
      log('ERROR', 'Run `cd functions && npm install` first.');
      process.exit(1);
    }
    const stripe = new Stripe(stripeKey);

    try {
      const acct = await stripe.accounts.retrieve(STRIPE_ACCT);
      log('INFO', `Stripe Connect account state: ${JSON.stringify({
        id: acct.id,
        type: acct.type,
        charges_enabled: acct.charges_enabled,
        payouts_enabled: acct.payouts_enabled,
        details_submitted: acct.details_submitted,
        country: acct.country,
        created: acct.created ? new Date(acct.created * 1000).toISOString() : null,
        external_account_count: acct.external_accounts?.data?.length ?? 0,
      })}`);

      if (acct.charges_enabled || acct.payouts_enabled || acct.details_submitted) {
        log('ERROR', 'Stripe Connect account is still ACTIVE.');
        log('ERROR', 'Refusing to delete Firestore artifacts while live Stripe account remains.');
        log('ERROR', 'Dissolve the account via Stripe Dashboard first, then re-run.');
        process.exit(1);
      }
      log('INFO', 'Stripe Connect account is dormant (no charges/payouts/submitted). Safe to proceed.');
    } catch (err) {
      if (err.code === 'resource_missing' || err.statusCode === 404) {
        log('INFO', 'Stripe Connect account already deleted/not found. Safe to proceed.');
      } else {
        log('ERROR', `Stripe API error: ${err.message}`);
        log('ERROR', 'Cannot verify account state. Refusing to proceed.');
        process.exit(1);
      }
    }
  } else {
    log('WARN', '--skip-stripe-check passed. Trusting operator that Stripe Connect was manually dissolved.');
  }

  // ----- Firebase Admin init -----
  let admin;
  try {
    admin = require(path.resolve(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
  } catch (e) {
    log('ERROR', `firebase-admin not found: ${e.message}. Run \`cd functions && npm install\`.`);
    process.exit(1);
  }
  admin.initializeApp({ projectId: PROJECT_ID });
  const db = admin.firestore();
  const auth = admin.auth();

  // Refuse if somehow we initialized against a non-prod project
  const initProject = admin.app().options.projectId;
  if (initProject !== PROJECT_ID) {
    log('ERROR', `Refusing: admin initialized against ${initProject}, expected ${PROJECT_ID}.`);
    process.exit(1);
  }

  // ----- Existence checks + delete plan -----
  const plan = [];

  // Bookings under target property
  const bookings = await db.collection(`properties/${TEST_PROPERTY_ID}/bookings`).get();
  for (const b of bookings.docs) {
    plan.push({ kind: 'firestore', path: b.ref.path, op: 'delete' });
  }

  // Unit
  const unitDoc = await db.doc(`properties/${TEST_PROPERTY_ID}/units/${TEST_UNIT_ID}`).get();
  if (unitDoc.exists) {
    plan.push({ kind: 'firestore', path: unitDoc.ref.path, op: 'delete' });
  } else {
    log('INFO', `unit ${TEST_UNIT_ID} already absent`);
  }

  // Property subcollections sanity (widget_settings, widget_secrets, pricing_calendar, etc.)
  const propRef = db.doc(`properties/${TEST_PROPERTY_ID}`);
  const subcols = await propRef.listCollections();
  for (const sc of subcols) {
    const subDocs = await sc.get();
    for (const sd of subDocs.docs) {
      plan.push({ kind: 'firestore', path: sd.ref.path, op: 'delete' });
    }
  }

  // Property itself
  const propDoc = await propRef.get();
  if (propDoc.exists) {
    plan.push({ kind: 'firestore', path: propRef.path, op: 'delete' });
  } else {
    log('INFO', `property ${TEST_PROPERTY_ID} already absent`);
  }

  // User doc
  const userRef = db.doc(`users/${TEST_UID}`);
  const userDoc = await userRef.get();
  if (userDoc.exists) {
    // sanity check the user is who we think it is
    const stored = userDoc.data().email;
    if (stored && stored !== TEST_EMAIL) {
      log('ERROR', `user doc ${TEST_UID} has email "${stored}" but expected "${TEST_EMAIL}". REFUSING to delete.`);
      process.exit(1);
    }
    plan.push({ kind: 'firestore', path: userRef.path, op: 'delete' });
  } else {
    log('INFO', `user doc ${TEST_UID} already absent`);
  }

  // Auth user
  try {
    const authUser = await auth.getUser(TEST_UID);
    if (authUser.email !== TEST_EMAIL) {
      log('ERROR', `auth user ${TEST_UID} has email "${authUser.email}" but expected "${TEST_EMAIL}". REFUSING.`);
      process.exit(1);
    }
    plan.push({ kind: 'auth', uid: TEST_UID, op: 'deleteUser' });
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      log('INFO', `auth user ${TEST_UID} already absent`);
    } else {
      log('ERROR', `auth check failed: ${err.message}`);
      process.exit(1);
    }
  }

  log('INFO', `delete plan: ${plan.length} operations`);
  for (const step of plan) {
    log('PLAN', JSON.stringify(step));
  }

  if (!EXECUTE) {
    log('INFO', 'Dry run complete. Pass --execute to apply.');
    process.exit(0);
  }

  // ----- Execute -----
  for (const step of plan) {
    if (step.kind === 'firestore') {
      try {
        await db.doc(step.path).delete();
        log('DELETED', step.path);
      } catch (e) {
        log('ERROR', `delete ${step.path} failed: ${e.message}`);
        process.exit(1);
      }
    } else if (step.kind === 'auth') {
      try {
        await auth.deleteUser(step.uid);
        log('DELETED', `auth user ${step.uid}`);
      } catch (e) {
        log('ERROR', `delete auth user ${step.uid} failed: ${e.message}`);
        process.exit(1);
      }
    }
  }

  log('INFO', 'Cleanup complete.');
}

main()
  .then(() => { logStream.end(); })
  .catch((e) => {
    log('FATAL', String(e && e.stack ? e.stack : e));
    logStream.end();
    process.exit(1);
  });
