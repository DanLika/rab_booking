#!/usr/bin/env node

/**
 * count-owners-with-resend.js
 *
 * Branch: hotfix/widget-secrets-exfil (Phase A — pre-rotation)
 *
 * Read-only audit script. Counts:
 *   - total widget_settings docs (= total configured units)
 *   - widget_settings docs with a non-empty email_config.resend_api_key
 *   - unique property owner_ids backing those docs (~= owners to email
 *     rotated keys to in step A1)
 *
 * Output: one summary line + a stub CSV ready to fill with new keys, written
 * to stdout. Sample of (owner_id, property_id, unit_id) rows printed for
 * manual sanity check.
 *
 * No writes. Safe to run against prod.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json \
 *   node functions/scripts/count-owners-with-resend.js <project_id>
 *
 * Examples:
 *   node functions/scripts/count-owners-with-resend.js bookbed-dev
 *   node functions/scripts/count-owners-with-resend.js rab-booking-248fc
 */

'use strict';

const admin = require('firebase-admin');

const projectId = process.argv[2];
if (!projectId) {
  console.error('ERROR: project_id required as first arg');
  console.error('Usage: node count-owners-with-resend.js <project_id>');
  process.exit(2);
}

admin.initializeApp({projectId});
const db = admin.firestore();

async function main() {
  const settingsSnap = await db.collectionGroup('widget_settings').get();
  const totalDocs = settingsSnap.size;

  // Filter for non-empty resend_api_key in email_config map.
  const withKey = settingsSnap.docs.filter((doc) => {
    const data = doc.data() || {};
    const ec = data.email_config || {};
    const key = ec.resend_api_key;
    return typeof key === 'string' && key.trim().length > 0;
  });

  // Resolve owner_id per doc via the parent property.
  // Path shape: properties/{propertyId}/widget_settings/{unitId}
  // Doing N small property fetches in parallel; bounded by number of
  // docs-with-key, typically tiny.
  const rows = await Promise.all(
    withKey.map(async (doc) => {
      const parts = doc.ref.path.split('/');
      const propertyId = parts[1];
      const unitId = parts[3];
      const propertyDoc = await db.collection('properties').doc(propertyId).get();
      const ownerId = propertyDoc.data()?.owner_id || '<UNKNOWN_OWNER>';
      return {ownerId, propertyId, unitId};
    }),
  );

  const uniqueOwners = new Set(rows.map((r) => r.ownerId));

  console.log('=== widget_settings audit ===');
  console.log(`project=${projectId}`);
  console.log(`total_widget_settings_docs=${totalDocs}`);
  console.log(`docs_with_resend_api_key=${withKey.length}`);
  console.log(`unique_owners_with_resend_api_key=${uniqueOwners.size}`);
  console.log('');

  if (rows.length === 0) {
    console.log('No widget_settings docs carry a resend_api_key — nothing to rotate.');
    return;
  }

  console.log('=== sample rows (first 10) ===');
  for (const row of rows.slice(0, 10)) {
    console.log(`owner=${row.ownerId} property=${row.propertyId} unit=${row.unitId}`);
  }
  if (rows.length > 10) {
    console.log(`... and ${rows.length - 10} more`);
  }

  console.log('');
  console.log('=== CSV stub for /tmp/resend-keys-mapping.csv ===');
  console.log('owner_id,new_resend_api_key');
  // Each owner gets ONE new key (script uses owner_id as lookup key).
  for (const ownerId of uniqueOwners) {
    console.log(`${ownerId},`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('FATAL', error && error.stack ? error.stack : String(error));
    process.exit(3);
  });
