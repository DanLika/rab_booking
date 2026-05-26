#!/usr/bin/env node
/**
 * Scrub secret-shaped fields from the publicly-readable `widget_settings` docs
 * and (where relevant) relocate them to the owner-only `widget_secrets`
 * subcollection.
 *
 * Background: /vibe-security audit 2026-05-25 flagged three field leaks on
 * `properties/{p}/widget_settings/{u}` (firestore.rules `allow read: if true`):
 *   1. `email_config.resend_api_key`     → DELETE (Resend now platform-only)
 *   2. `stripe_config.secret_key`        → DELETE (Connect uses platform key)
 *   3. `ical_export_token`               → MOVE to widget_secrets/{u}
 *
 * Safety:
 *   - Defaults to --dry-run. Pass --execute to mutate.
 *   - Idempotent per doc — re-running is a no-op once fields are removed.
 *   - Refuses to run unless an explicit --project flag is given.
 *   - Logs to audit/migrations/<date>-scrub-widget-settings-secrets-<env>.log
 *
 * Usage:
 *   node scripts/scrub-widget-settings-secrets.js --project bookbed-dev
 *   node scripts/scrub-widget-settings-secrets.js --project bookbed-dev --execute
 *   node scripts/scrub-widget-settings-secrets.js --project rab-booking-248fc --execute
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS pointing at a service account with
 * Firestore + Auth Admin SDK scope.
 */

'use strict';

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const args = process.argv.slice(2);
function getArg(flag) {
  const i = args.indexOf(flag);
  return i >= 0 ? args[i + 1] : null;
}

const EXECUTE = args.includes('--execute');
const PROJECT_ID = getArg('--project');

if (!PROJECT_ID) {
  console.error('ERROR: --project <id> required (e.g. bookbed-dev, rab-booking-248fc).');
  process.exit(2);
}

admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();

const FieldValue = admin.firestore.FieldValue;

const isoDate = new Date().toISOString().slice(0, 19).replace(/[:]/g, '-');
const logDir = path.join(__dirname, '..', 'audit', 'migrations');
fs.mkdirSync(logDir, { recursive: true });
const logPath = path.join(
  logDir,
  `${isoDate}-scrub-widget-settings-secrets-${PROJECT_ID}${EXECUTE ? '' : '-DRYRUN'}.log`
);
const logStream = fs.createWriteStream(logPath, { flags: 'a' });

function log(level, msg, extra) {
  const line = `[${new Date().toISOString()}] ${level} ${msg}${extra ? ' ' + JSON.stringify(extra) : ''}`;
  console.log(line);
  logStream.write(line + '\n');
}

async function main() {
  log('INFO', `Mode: ${EXECUTE ? 'EXECUTE' : 'DRY-RUN'} | Project: ${PROJECT_ID}`);

  const snap = await db.collectionGroup('widget_settings').get();
  log('INFO', `Found ${snap.size} widget_settings docs to inspect.`);

  let inspected = 0;
  let scrubbed = 0;
  let icalMoved = 0;
  let resendDeleted = 0;
  let stripeSecretDeleted = 0;
  let skippedClean = 0;

  for (const doc of snap.docs) {
    inspected++;
    const data = doc.data() || {};
    const propertyRef = doc.ref.parent.parent;
    if (!propertyRef) {
      log('WARN', `Doc has no parent property: ${doc.ref.path}`);
      continue;
    }
    const propertyId = propertyRef.id;
    const unitId = doc.id;

    const settingsUpdates = {};
    const secretsUpdates = {};

    // 1. resend_api_key (inside email_config) — DELETE
    const emailConfig = data.email_config;
    if (emailConfig && typeof emailConfig === 'object' && 'resend_api_key' in emailConfig) {
      settingsUpdates['email_config.resend_api_key'] = FieldValue.delete();
      resendDeleted++;
    }
    if ('resend_api_key' in data) {
      // Top-level legacy field
      settingsUpdates['resend_api_key'] = FieldValue.delete();
      resendDeleted++;
    }

    // 2. stripe_config.secret_key — DELETE
    const stripeConfig = data.stripe_config;
    if (stripeConfig && typeof stripeConfig === 'object' && 'secret_key' in stripeConfig) {
      settingsUpdates['stripe_config.secret_key'] = FieldValue.delete();
      stripeSecretDeleted++;
    }

    // 3. ical_export_token — MOVE to widget_secrets/{unitId}
    if (typeof data.ical_export_token === 'string' && data.ical_export_token.length > 0) {
      secretsUpdates.ical_export_token = data.ical_export_token;
      secretsUpdates.property_id = propertyId;
      secretsUpdates.owner_id = data.owner_id ?? null;
      secretsUpdates.unit_id = unitId;
      secretsUpdates.updated_at = FieldValue.serverTimestamp();
      settingsUpdates['ical_export_token'] = FieldValue.delete();
      icalMoved++;
    }

    if (Object.keys(settingsUpdates).length === 0 && Object.keys(secretsUpdates).length === 0) {
      skippedClean++;
      continue;
    }

    log('PLAN', `${propertyId}/${unitId}`, {
      settings_deletes: Object.keys(settingsUpdates),
      secrets_writes: Object.keys(secretsUpdates),
    });

    if (EXECUTE) {
      // Write widget_secrets FIRST so the token never has a gap where it's
      // gone from widget_settings but not yet in widget_secrets (icalExport.ts
      // tolerates both, but minimizing the window is still cheap).
      if (Object.keys(secretsUpdates).length > 0) {
        await propertyRef.collection('widget_secrets').doc(unitId).set(secretsUpdates, { merge: true });
      }
      if (Object.keys(settingsUpdates).length > 0) {
        await doc.ref.update(settingsUpdates);
      }
      scrubbed++;
    }
  }

  log('SUMMARY', 'Done', {
    project: PROJECT_ID,
    mode: EXECUTE ? 'EXECUTE' : 'DRY-RUN',
    inspected,
    scrubbed,
    skipped_already_clean: skippedClean,
    ical_tokens_moved: icalMoved,
    resend_keys_deleted: resendDeleted,
    stripe_secret_keys_deleted: stripeSecretDeleted,
  });
  log('INFO', `Log written: ${logPath}`);

  await new Promise((res) => logStream.end(res));
}

main().catch((err) => {
  log('FATAL', err.stack || err.message || String(err));
  process.exit(1);
});
