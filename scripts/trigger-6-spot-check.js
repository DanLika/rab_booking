#!/usr/bin/env node
/**
 * audit/28 Tier 4 — Resend spot-check trigger.
 *
 * Fires 6 email templates through bookbed-dev deployed Cloud Functions so
 * their Resend message IDs land in the Resend dashboard. Output is a JSON
 * manifest cross-referenced by audit/28 §4.3.
 *
 * Templates fired:
 *   1. booking-confirmation        (createBookingAtomic — anon HTTPS)
 *   2. booking-approved            (Firestore status pending→confirmed → onBookingStatusChange)
 *   3. booking-rejected            (Firestore status pending→cancelled+reason)
 *   4. email-verification          (sendEmailVerificationCode — anon HTTPS)
 *   5. password-reset              (sendPasswordResetEmail — anon HTTPS)
 *   6. custom-email                (sendCustomEmailToGuest — owner-auth HTTPS, optional)
 *
 * Auth: Application Default Credentials. Run
 *   gcloud auth application-default login
 * once if not set up. ADC project override:
 *   GOOGLE_CLOUD_PROJECT=bookbed-dev node scripts/trigger-6-spot-check.js ...
 *
 * Usage:
 *   node scripts/trigger-6-spot-check.js \
 *     --guest-email=test+guest@example.com \
 *     --owner-email=test+owner@example.com \
 *     [--web-api-key=<firebase_web_api_key>] \
 *     [--project=bookbed-dev]
 *
 * Refuses prod by name. Idempotent re-runs append new bookings (uses auto-IDs).
 *
 * Output:
 *   audit/trigger-spot-check-<timestamp>.json
 */

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const getArg = (k) => {
  const a = args.find((x) => x.startsWith(`--${k}=`));
  return a ? a.slice(k.length + 3) : undefined;
};

const projectId = getArg('project') || 'bookbed-dev';
const guestEmail = getArg('guest-email');
const ownerEmail = getArg('owner-email');
const webApiKey = getArg('web-api-key');

if (projectId === 'rab-booking-248fc') {
  console.error('Refusing to trigger against PROD (rab-booking-248fc). Dev only.');
  process.exit(1);
}

if (!guestEmail || !ownerEmail) {
  console.error('Required:');
  console.error('  --guest-email=<addr>    (recipient for templates 1, 2, 3, 6)');
  console.error('  --owner-email=<addr>    (recipient for templates 4, 5)');
  console.error('Optional:');
  console.error('  --web-api-key=<key>     (Firebase Web API key — only for template 6 custom-email)');
  console.error('  --project=bookbed-dev   (defaults to bookbed-dev; refuses prod)');
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

// Seed-fixture identifiers (from scripts/seed-bookbed-dev.js).
const PROPERTY_ID = 'SEED_property_dev_01';
const UNIT_ID = 'SEED_unit_dev_01';
const OWNER_UID = 'Zo01CJ3wymb0pplaYOyaZ2yGUWG2';

// Region — all 4 callables in this set default to us-central1 (no setGlobalOptions
// in functions/src/, and none of the four are listed in the eu-west1 set per
// CLAUDE.md cloud-functions.md region split).
const REGION = 'us-central1';
const cfUrl = (fnName) =>
  `https://${REGION}-${projectId}.cloudfunctions.net/${fnName}`;

async function callable(fnName, data, idToken) {
  const headers = {'Content-Type': 'application/json'};
  if (idToken) headers.Authorization = `Bearer ${idToken}`;
  const r = await fetch(cfUrl(fnName), {
    method: 'POST',
    headers,
    body: JSON.stringify({data}),
  });
  const body = await r.text();
  if (!r.ok) {
    throw new Error(`${fnName} HTTP ${r.status}: ${body}`);
  }
  return JSON.parse(body);
}

async function mintIdToken(uid) {
  if (!webApiKey) {
    throw new Error('--web-api-key required for owner-auth callables');
  }
  const customToken = await admin.auth().createCustomToken(uid);
  const r = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${webApiKey}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({token: customToken, returnSecureToken: true}),
    },
  );
  const j = await r.json();
  if (!r.ok || !j.idToken) {
    throw new Error(`mintIdToken failed: ${JSON.stringify(j)}`);
  }
  return j.idToken;
}

function daysFromNow(days) {
  const d = new Date();
  d.setUTCHours(12, 0, 0, 0);
  d.setUTCDate(d.getUTCDate() + days);
  return admin.firestore.Timestamp.fromDate(d);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const manifest = {
  project: projectId,
  guest_email: guestEmail,
  owner_email: ownerEmail,
  started_at: new Date().toISOString(),
  triggers: [],
};

async function trig1Confirmation() {
  console.log('▶ [1/6] booking-confirmation via createBookingAtomic (anon)');
  const t0 = Date.now();
  try {
    // Field names verified against functions/src/atomicBooking.ts:100-119
    // (camelCase, NOT snake_case). paymentMethod='none' = pay-on-arrival path
    // that auto-confirms + sends booking-confirmation email (vs requireOwnerApproval).
    const result = await callable('createBookingAtomic', {
      unitId: UNIT_ID,
      propertyId: PROPERTY_ID,
      checkIn: daysFromNow(60).toDate().toISOString(),
      checkOut: daysFromNow(63).toDate().toISOString(),
      guestName: 'audit28 spot-check confirmation',
      guestEmail: guestEmail,
      guestPhone: '+38591000001',
      guestCount: 2,
      totalPrice: 300,
      paymentMethod: 'none',
      requireOwnerApproval: false,
      notes: 'audit/28 Tier 4 spot-check',
    });
    const bookingId = result.result?.bookingId || result.result?.booking_id;
    manifest.triggers.push({
      n: 1,
      template: 'booking-confirmation',
      booking_id: bookingId,
      sent_to: guestEmail,
      fired_at: new Date(t0).toISOString(),
      duration_ms: Date.now() - t0,
      ok: true,
    });
    console.log(`  ✓ booking_id=${bookingId}`);
  } catch (e) {
    manifest.triggers.push({
      n: 1,
      template: 'booking-confirmation',
      fired_at: new Date(t0).toISOString(),
      duration_ms: Date.now() - t0,
      ok: false,
      error: e.message,
    });
    console.log(`  ✗ ${e.message}`);
  }
}

async function makePendingBooking(label) {
  const docRef = db
    .collection(`properties/${PROPERTY_ID}/units/${UNIT_ID}/bookings`)
    .doc();
  await docRef.set({
    booking_reference: `SPOT-${label}-${Date.now().toString(36).slice(-6)}`.toUpperCase(),
    property_id: PROPERTY_ID,
    unit_id: UNIT_ID,
    guest_name: `audit28 spot-check ${label}`,
    guest_email: guestEmail,
    guest_phone: '+38591000002',
    guest_count: 2,
    check_in: daysFromNow(50 + (label === 'rejection' ? 5 : 0)),
    check_out: daysFromNow(53 + (label === 'rejection' ? 5 : 0)),
    total_price: 300,
    currency: 'EUR',
    status: 'pending',
    source: 'audit28_spotcheck',
    created_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
    cancellation_token: Math.random().toString(36).slice(2, 18) + Math.random().toString(36).slice(2, 18),
  });
  return docRef;
}

async function trig2Approval() {
  console.log('▶ [2/6] booking-approved via onBookingStatusChange (pending→confirmed)');
  const t0 = Date.now();
  try {
    const ref = await makePendingBooking('approval');
    await sleep(1500); // let onBookingCreated settle first
    // bookingManagement.ts:278 — email fires ONLY when after.approved_at is set.
    // Without this, the status flip is silent (no approval email).
    await ref.update({
      status: 'confirmed',
      approved_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
    manifest.triggers.push({
      n: 2,
      template: 'booking-approved',
      booking_id: ref.id,
      booking_path: ref.path,
      sent_to: guestEmail,
      fired_at: new Date(t0).toISOString(),
      duration_ms: Date.now() - t0,
      ok: true,
    });
    console.log(`  ✓ booking ${ref.id} pending→confirmed`);
  } catch (e) {
    manifest.triggers.push({
      n: 2,
      template: 'booking-approved',
      fired_at: new Date(t0).toISOString(),
      duration_ms: Date.now() - t0,
      ok: false,
      error: e.message,
    });
    console.log(`  ✗ ${e.message}`);
  }
}

async function trig3Rejection() {
  console.log('▶ [3/6] booking-rejected via onBookingStatusChange (pending→cancelled+reason)');
  const t0 = Date.now();
  try {
    const ref = await makePendingBooking('rejection');
    await sleep(1500);
    await ref.update({
      status: 'cancelled',
      rejection_reason: 'audit/28 spot-check synthetic rejection',
      updated_at: FieldValue.serverTimestamp(),
    });
    manifest.triggers.push({
      n: 3,
      template: 'booking-rejected',
      booking_id: ref.id,
      booking_path: ref.path,
      sent_to: guestEmail,
      fired_at: new Date(t0).toISOString(),
      duration_ms: Date.now() - t0,
      ok: true,
    });
    console.log(`  ✓ booking ${ref.id} pending→cancelled+reason`);
  } catch (e) {
    manifest.triggers.push({
      n: 3,
      template: 'booking-rejected',
      fired_at: new Date(t0).toISOString(),
      duration_ms: Date.now() - t0,
      ok: false,
      error: e.message,
    });
    console.log(`  ✗ ${e.message}`);
  }
}

async function trig4Verification() {
  console.log('▶ [4/6] email-verification via sendEmailVerificationCode (anon)');
  const t0 = Date.now();
  try {
    const result = await callable('sendEmailVerificationCode', {
      email: ownerEmail,
    });
    manifest.triggers.push({
      n: 4,
      template: 'email-verification',
      sent_to: ownerEmail,
      fired_at: new Date(t0).toISOString(),
      duration_ms: Date.now() - t0,
      ok: true,
      result: result.result,
    });
    console.log(`  ✓ sent to ${ownerEmail}`);
  } catch (e) {
    manifest.triggers.push({
      n: 4,
      template: 'email-verification',
      fired_at: new Date(t0).toISOString(),
      duration_ms: Date.now() - t0,
      ok: false,
      error: e.message,
    });
    console.log(`  ✗ ${e.message}`);
  }
}

async function trig5PasswordReset() {
  console.log('▶ [5/6] password-reset via sendPasswordResetEmail (anon)');
  const t0 = Date.now();
  try {
    const result = await callable('sendPasswordResetEmail', {
      email: ownerEmail,
    });
    manifest.triggers.push({
      n: 5,
      template: 'password-reset',
      sent_to: ownerEmail,
      fired_at: new Date(t0).toISOString(),
      duration_ms: Date.now() - t0,
      ok: true,
      result: result.result,
    });
    console.log(`  ✓ sent to ${ownerEmail}`);
  } catch (e) {
    manifest.triggers.push({
      n: 5,
      template: 'password-reset',
      fired_at: new Date(t0).toISOString(),
      duration_ms: Date.now() - t0,
      ok: false,
      error: e.message,
    });
    console.log(`  ✗ ${e.message}`);
  }
}

async function trig6CustomEmail() {
  if (!webApiKey) {
    console.log('▶ [6/6] custom-email SKIPPED (--web-api-key not provided)');
    manifest.triggers.push({
      n: 6,
      template: 'custom-email',
      skipped: true,
      reason: 'no web-api-key',
    });
    return;
  }
  console.log('▶ [6/6] custom-email via sendCustomEmailToGuest (owner auth)');
  const t0 = Date.now();
  try {
    const idToken = await mintIdToken(OWNER_UID);
    const confTrigger = manifest.triggers.find(
      (t) => t.template === 'booking-confirmation' && t.ok,
    );
    const bookingId = confTrigger?.booking_id ?? 'SEED_booking_dev_01';
    const result = await callable(
      'sendCustomEmailToGuest',
      {
        booking_id: bookingId,
        subject: 'audit/28 spot-check custom email',
        message:
          'This is a synthetic test email from audit/28 Tier 4 spot-check. Safe to ignore.',
      },
      idToken,
    );
    manifest.triggers.push({
      n: 6,
      template: 'custom-email',
      sent_to: guestEmail,
      booking_id: bookingId,
      fired_at: new Date(t0).toISOString(),
      duration_ms: Date.now() - t0,
      ok: true,
      result: result.result,
    });
    console.log(`  ✓ sent (booking_id=${bookingId})`);
  } catch (e) {
    manifest.triggers.push({
      n: 6,
      template: 'custom-email',
      fired_at: new Date(t0).toISOString(),
      duration_ms: Date.now() - t0,
      ok: false,
      error: e.message,
    });
    console.log(`  ✗ ${e.message}`);
  }
}

(async () => {
  console.log(
    `audit/28 Tier 4 spot-check — project=${projectId} guest=${guestEmail} owner=${ownerEmail}`,
  );
  await trig1Confirmation();
  await sleep(1000);
  await trig2Approval();
  await sleep(1000);
  await trig3Rejection();
  await sleep(1000);
  await trig4Verification();
  await sleep(1000);
  await trig5PasswordReset();
  await sleep(1000);
  await trig6CustomEmail();

  manifest.finished_at = new Date().toISOString();
  const outPath = path.resolve(
    __dirname,
    '..',
    `audit/trigger-spot-check-${Date.now()}.json`,
  );
  fs.writeFileSync(outPath, JSON.stringify(manifest, null, 2));
  const ok = manifest.triggers.filter((t) => t.ok).length;
  const skipped = manifest.triggers.filter((t) => t.skipped).length;
  const failed = manifest.triggers.filter((t) => !t.ok && !t.skipped).length;
  console.log('');
  console.log(`✓ manifest: ${outPath}`);
  console.log(`  ok=${ok} skipped=${skipped} failed=${failed}`);
  if (failed > 0) process.exit(1);
})();
