#!/usr/bin/env node
// F-92-01 probe: enumerate widget_settings + widget_secrets on bookbed-dev,
// classify each ical_export_enabled unit as vulnerable / safe / unknown.
// READ-ONLY. ADC credentials. bookbed-dev only (asserted).

const path = require('path');
const adminPath = path.resolve(__dirname, '..', '..', 'functions', 'node_modules', 'firebase-admin');
const admin = require(adminPath);

const projectId = 'bookbed-dev';
if (projectId === 'rab-booking-248fc') {
  console.error('REFUSE: never probe PROD');
  process.exit(1);
}

if (!admin.apps.length) {
  admin.initializeApp({projectId, credential: admin.credential.applicationDefault()});
}
const db = admin.firestore();

(async () => {
  const props = await db.collection('properties').get();
  console.log(`properties: ${props.size}`);
  const matrix = [];
  for (const p of props.docs) {
    const wsSnap = await db.collection('properties').doc(p.id).collection('widget_settings').get();
    for (const ws of wsSnap.docs) {
      const wsd = ws.data();
      if (!wsd.ical_export_enabled) continue;
      const secRef = db.collection('properties').doc(p.id).collection('widget_secrets').doc(ws.id);
      const sec = await secRef.get();
      const secData = sec.exists ? sec.data() : null;
      const legacyTok = wsd.ical_export_token;
      const secretsTok = secData?.ical_export_token;
      const secretsHash = secData?.ical_export_token_hash;
      const secretsPlain = secData?.ical_export_token_plaintext;
      const legacyOk = typeof legacyTok === 'string' && legacyTok.length > 0;
      const secretsOk = typeof secretsTok === 'string' && secretsTok.length > 0;
      const status = legacyOk || secretsOk ? 'SAFE' : 'VULNERABLE';
      matrix.push({
        propertyId: p.id,
        unitId: ws.id,
        ical_export_enabled: true,
        legacy_token_len: typeof legacyTok === 'string' ? legacyTok.length : '(missing)',
        secrets_doc_exists: sec.exists,
        secrets_token_len: typeof secretsTok === 'string' ? secretsTok.length : '(missing)',
        secrets_hash_len: typeof secretsHash === 'string' ? secretsHash.length : '(missing)',
        secrets_plaintext_len: typeof secretsPlain === 'string' ? secretsPlain.length : '(missing)',
        verdict: status,
      });
    }
  }
  console.log(JSON.stringify(matrix, null, 2));
  const vulnerable = matrix.filter((m) => m.verdict === 'VULNERABLE');
  console.log(`\nTotal ical_export_enabled units: ${matrix.length}`);
  console.log(`VULNERABLE: ${vulnerable.length}`);
  console.log(`SAFE: ${matrix.length - vulnerable.length}`);
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(2);
});
