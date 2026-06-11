#!/usr/bin/env node
// audit/123 dev-deploy smoke: F-92-01 regression (feed 200/403) + F-123-07
// (getStripeAccountStatus 30/300s per-owner rate limit). bookbed-dev ONLY.
const path = require('path');
const admin = require(path.resolve('/Users/duskolicanin/git/bookbed/functions/node_modules/firebase-admin'));
const projectId = 'bookbed-dev';
admin.initializeApp({projectId, credential: admin.credential.applicationDefault()});
const db = admin.firestore();
const BASE = 'https://us-central1-bookbed-dev.cloudfunctions.net';
const API_KEY = 'AIzaSyCokYMO3Q0Q8cM5f_y4Ne8C3GaP7cwR-bE';

(async () => {
  // 1. find an export-enabled unit with readable token
  let fixture = null;
  const props = await db.collection('properties').get();
  outer: for (const p of props.docs) {
    const wsSnap = await db.collection('properties').doc(p.id).collection('widget_settings').get();
    for (const ws of wsSnap.docs) {
      const d = ws.data();
      if (!d.ical_export_enabled) continue;
      let tok = (typeof d.ical_export_token === 'string' && d.ical_export_token) || null;
      if (!tok) {
        const sec = await db.collection('properties').doc(p.id).collection('widget_secrets').doc(ws.id).get();
        tok = sec.exists && typeof sec.data().ical_export_token === 'string' ? sec.data().ical_export_token : null;
      }
      if (tok) { fixture = {propertyId: p.id, unitId: ws.id, tok}; break outer; }
    }
  }
  if (!fixture) { console.log('FEED: SKIP — no OK fixture'); } else {
    const ok = await fetch(`${BASE}/getUnitIcalFeed/${fixture.propertyId}/${fixture.unitId}/${fixture.tok}.ics`);
    const body = await ok.text();
    console.log(`FEED valid-token: ${ok.status} ${body.includes('BEGIN:VCALENDAR') ? 'VCALENDAR ✓' : 'NO-VCALENDAR ✗'}`);
    const bad = await fetch(`${BASE}/getUnitIcalFeed/${fixture.propertyId}/${fixture.unitId}/WRONGTOKEN.ics`);
    console.log(`FEED wrong-token: ${bad.status} ${bad.status === 403 ? '✓' : '✗'}`);
  }

  // 2. F-123-07 rate limit: sign in, hammer getStripeAccountStatus
  const auth = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`, {
    method: 'POST', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({email: 'bookbed-test@bookbed.io', password: 'BookBedTest2026!', returnSecureToken: true}),
  });
  const authData = await auth.json();
  if (!authData.idToken) { console.log('RATE: SKIP — signin failed', authData.error?.message); process.exit(0); }
  let exhaustedAt = null;
  for (let i = 1; i <= 35; i++) {
    const r = await fetch(`${BASE}/getStripeAccountStatus`, {
      method: 'POST',
      headers: {'Content-Type': 'application/json', Authorization: `Bearer ${authData.idToken}`},
      body: JSON.stringify({data: {}}),
    });
    const j = await r.json().catch(() => ({}));
    const status = j.error?.status || 'OK';
    if (status === 'RESOURCE_EXHAUSTED') { exhaustedAt = i; break; }
    if (i === 1 || i % 10 === 0) console.log(`  call ${i}: http ${r.status} ${status}`);
  }
  console.log(exhaustedAt
    ? `RATE getStripeAccountStatus: RESOURCE_EXHAUSTED at call ${exhaustedAt} ${exhaustedAt >= 28 && exhaustedAt <= 32 ? '✓ (limit 30)' : '~ (instance split?)'}`
    : 'RATE: no exhaustion in 35 calls ✗ (multi-instance split or limit not live)');
  process.exit(0);
})().catch((e) => { console.error('SMOKE ERROR:', e.message); process.exit(1); });
