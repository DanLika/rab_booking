#!/usr/bin/env node
// Smoke for F-67-01 closure: completeBooking CF on bookbed-dev.
// Creates a throwaway "confirmed" booking owned by bookbed-test user, mints
// an ID token via admin custom-token → identitytoolkit:signInWithCustomToken,
// calls the CF, asserts post-state, cleans up. Mirrors scripts/trigger-6-spot-check.js
// patterns + audit/56 §smoke setup.

'use strict';

process.env.GOOGLE_CLOUD_PROJECT = 'bookbed-dev';

const admin = require('firebase-admin');
admin.initializeApp({projectId: 'bookbed-dev'});

// Web API keys for Firebase JS SDK are PUBLIC by design (shipped in
// every web bundle). Load from lib/firebase_options_dev.dart at runtime so
// we never inline a "looks like a secret" literal — see audit/58 §N2.
const fs = require('fs');
const path = require('path');
const optionsFile = fs.readFileSync(
  path.join(__dirname, '../..', 'lib', 'firebase_options_dev.dart'),
  'utf8'
);
const webBlockMatch = optionsFile.match(
  /FirebaseOptions web = FirebaseOptions\([\s\S]*?apiKey:\s*['"]([^'"]+)['"]/
);
if (!webBlockMatch) {
  throw new Error('Could not locate web apiKey in firebase_options_dev.dart');
}
const WEB_API_KEY = webBlockMatch[1];

const OWNER_UID = 'GILVItIVP5R8WXfnMmyMo1ykhUm2'; // bookbed-test@bookbed.io
const OWNER_EMAIL = 'bookbed-test@bookbed.io';
// Smoke-only credential: bookbed-dev throwaway test account, NOT a real
// secret. Read from env var so it does not live in the file. Set via:
//   BB_TEST_PW='...' node audit/smoke/complete-booking-smoke.js
const OWNER_PW = process.env.BB_TEST_PW;
if (!OWNER_PW) {
  throw new Error('Set BB_TEST_PW env var (bookbed-dev test owner password)');
}
const CF_URL = 'https://europe-west1-bookbed-dev.cloudfunctions.net/completeBooking';

const db = admin.firestore();

async function mintIdToken() {
  const r = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${WEB_API_KEY}`,
    {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        email: OWNER_EMAIL,
        password: OWNER_PW,
        returnSecureToken: true,
      }),
    },
  );
  const j = await r.json();
  if (!r.ok || !j.idToken) {
    throw new Error(`mintIdToken HTTP ${r.status}: ${JSON.stringify(j)}`);
  }
  return j.idToken;
}

async function findOrCreateConfirmedBooking() {
  // Try to find an existing owner-owned property + unit
  const propSnap = await db
    .collection('properties')
    .where('owner_id', '==', OWNER_UID)
    .limit(1)
    .get();
  if (propSnap.empty) {
    throw new Error(`No property for ${OWNER_UID}. Seed test fixtures first.`);
  }
  const propRef = propSnap.docs[0].ref;
  const unitSnap = await propRef.collection('units').limit(1).get();
  if (unitSnap.empty) {
    throw new Error('No unit under that property.');
  }
  const unitRef = unitSnap.docs[0].ref;

  // Create throwaway confirmed booking with check-in in the past so the
  // status transition is realistic (matches UI's `isPast` gate, even though
  // CF doesn't enforce it).
  const now = new Date();
  const pastIn = new Date(now);
  pastIn.setDate(pastIn.getDate() - 7);
  const pastOut = new Date(now);
  pastOut.setDate(pastOut.getDate() - 5);
  const bookingRef = unitRef.collection('bookings').doc();
  await bookingRef.set({
    booking_reference: 'BB-SMOKE-' + Date.now(),
    owner_id: OWNER_UID,
    property_id: propRef.id,
    unit_id: unitRef.id,
    status: 'confirmed',
    check_in: admin.firestore.Timestamp.fromDate(pastIn),
    check_out: admin.firestore.Timestamp.fromDate(pastOut),
    guest_name: 'F67 Smoke',
    guest_email: 'smoke@bookbed.io',
    payment_status: 'unpaid',
    paid_amount: 0,
    total_price: 100,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {bookingRef, propertyId: propRef.id, unitId: unitRef.id};
}

async function callCompleteBooking(idToken, bookingId) {
  const r = await fetch(CF_URL, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({data: {bookingId}}),
  });
  const body = await r.text();
  return {status: r.status, body};
}

(async () => {
  const summary = {steps: []};
  let bookingRef;
  try {
    summary.steps.push('1. mint id token');
    const idToken = await mintIdToken();
    if (!idToken || idToken.length < 100) {
      throw new Error('idToken short');
    }
    summary.steps.push('  idToken=' + idToken.length + ' chars OK');

    summary.steps.push('2. seed throwaway confirmed booking');
    const created = await findOrCreateConfirmedBooking();
    bookingRef = created.bookingRef;
    summary.steps.push('  bookingId=' + bookingRef.id);

    summary.steps.push('3. call completeBooking CF');
    const callResult = await callCompleteBooking(idToken, bookingRef.id);
    summary.steps.push('  HTTP=' + callResult.status);
    summary.steps.push('  body=' + callResult.body.slice(0, 200));
    if (callResult.status !== 200) {
      throw new Error('CF did not return 200');
    }

    summary.steps.push('4. read-back assert');
    const snap = await bookingRef.get();
    const data = snap.data();
    summary.steps.push('  status=' + data.status);
    summary.steps.push(
      '  completed_at=' + (data.completed_at ? 'set' : 'MISSING')
    );
    summary.steps.push(
      '  updated_at=' + (data.updated_at ? 'set' : 'MISSING')
    );
    if (data.status !== 'completed') {
      throw new Error('status != completed');
    }
    if (!data.completed_at) {
      throw new Error('completed_at missing');
    }

    summary.steps.push('5. negative: re-call (should reject — not confirmed anymore)');
    const negResult = await callCompleteBooking(idToken, bookingRef.id);
    summary.steps.push('  HTTP=' + negResult.status);
    summary.steps.push('  body=' + negResult.body.slice(0, 200));
    if (negResult.status === 200) {
      throw new Error('CF accepted a second call — state guard broken');
    }

    summary.steps.push('SMOKE PASS');
  } catch (e) {
    summary.steps.push('FAIL: ' + e.message);
    process.exitCode = 1;
  } finally {
    if (bookingRef) {
      try {
        await bookingRef.delete();
        summary.steps.push('cleanup: throwaway booking deleted');
      } catch (e) {
        summary.steps.push('cleanup FAIL: ' + e.message);
      }
    }
    console.log(summary.steps.join('\n'));
  }
})();
