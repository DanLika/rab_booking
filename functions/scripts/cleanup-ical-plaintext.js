#!/usr/bin/env node

/**
 * cleanup-ical-plaintext.js
 *
 * Branch: hotfix/widget-secrets-exfil
 * Step:   Phase A6 — post-deploy cleanup
 *
 * Removes the transitional `ical_export_token_plaintext` field from every
 * widget_secrets/{unitId} doc. Run AFTER:
 *   1. icalExport.ts (A5) has been deployed using the peppered-hash code path.
 *   2. A sample of getUnitIcalFeed/{...}.ics requests return 200 with the new
 *      token (proving the hash verification works end-to-end).
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json \
 *   node functions/scripts/cleanup-ical-plaintext.js --project bookbed-dev [--dry-run]
 */

'use strict';

const admin = require('firebase-admin');

const args = process.argv.slice(2);
function flagValue(name) {
  const idx = args.indexOf(name);
  if (idx === -1) return null;
  return args[idx + 1] || null;
}
function hasFlag(name) {
  return args.includes(name);
}

const projectId = flagValue('--project');
const dryRun = hasFlag('--dry-run');

if (!projectId) {
  console.error('ERROR: --project <id> is required');
  process.exit(2);
}

admin.initializeApp({projectId});
const db = admin.firestore();

async function main() {
  console.log(`[cleanup] project=${projectId} dryRun=${dryRun}`);
  const propertiesSnap = await db.collection('properties').get();
  let total = 0;
  let cleaned = 0;
  let skipped = 0;

  for (const propertyDoc of propertiesSnap.docs) {
    const secretsSnap = await propertyDoc.ref.collection('widget_secrets').get();
    for (const secretsDoc of secretsSnap.docs) {
      total += 1;
      const data = secretsDoc.data() || {};
      if (!('ical_export_token_plaintext' in data)) {
        skipped += 1;
        continue;
      }
      if (dryRun) {
        console.log(
          `[cleanup] DRY-RUN property=${propertyDoc.id} unit=${secretsDoc.id}`,
        );
      } else {
        await secretsDoc.ref.update({
          ical_export_token_plaintext: admin.firestore.FieldValue.delete(),
        });
        console.log(
          `[cleanup] OK property=${propertyDoc.id} unit=${secretsDoc.id}`,
        );
      }
      cleaned += 1;
    }
  }

  console.log(
    `[cleanup] done total=${total} cleaned=${cleaned} skipped=${skipped} dryRun=${dryRun}`,
  );
}

main().catch((error) => {
  console.error('[cleanup] FATAL', error);
  process.exit(3);
});
