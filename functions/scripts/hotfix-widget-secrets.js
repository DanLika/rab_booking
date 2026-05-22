#!/usr/bin/env node

/**
 * hotfix-widget-secrets.js
 *
 * Branch: hotfix/widget-secrets-exfil
 * Step:   Phase A3 — migration
 *
 * One-shot migration for the widget_settings → widget_secrets split.
 *
 * For every properties/{propertyId}/widget_settings/{unitId} doc:
 *   1. Read `email_config.resend_api_key` (if present).
 *   2. Read `ical_export_token` (if present).
 *   3. Read `ical_cache_content` + `ical_cache_etag` (if present) — SF-024.
 *   4. Generate a fresh iCal token (32 random bytes hex).
 *   5. Compute sha256(token + pepper) using ICAL_TOKEN_PEPPER from env.
 *   6. Look up the new Resend key for this owner from the CSV provided by A1.
 *   7. Write properties/{propertyId}/widget_secrets/{unitId} with:
 *        - resend_api_key (new value)
 *        - ical_export_token_hash (peppered hash)
 *        - ical_export_token_plaintext (TRANSITIONAL — cleaned up in A6)
 *        - ical_cache_content + ical_cache_etag + ical_cache_updated_at (SF-024)
 *        - rotated_at
 *   8. Strip from widget_settings: email_config.resend_api_key, ical_export_token,
 *      ical_cache_content, ical_cache_etag (SF-024).
 *
 * Idempotency:
 *   Re-running is safe: if widget_secrets/{unitId} already has rotated_at within
 *   the current run, the doc is skipped. Use --force to override.
 *
 * Usage:
 *   ICAL_TOKEN_PEPPER=$(cat /tmp/pepper) \
 *   RESEND_CSV=/tmp/owner-resend-keys.csv \
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json \
 *   node functions/scripts/hotfix-widget-secrets.js \
 *     --project bookbed-dev \
 *     [--dry-run] [--force]
 *
 * Expected CSV format (header required):
 *   owner_id,new_resend_api_key
 *   uid1,re_xxx_new
 *   uid2,re_yyy_new
 *
 * Output:
 *   Progress to stdout. Per-doc actions appended to:
 *     audit/migrations/2026-05-18-widget-secrets-{project}.log
 */

'use strict';

const admin = require('firebase-admin');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// ----------------------------------------------------------------------------
// CLI args
// ----------------------------------------------------------------------------
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
const force = hasFlag('--force');

if (!projectId) {
  console.error('ERROR: --project <id> is required (e.g. --project bookbed-dev)');
  process.exit(2);
}

const pepper = process.env.ICAL_TOKEN_PEPPER;
if (!pepper || pepper.length < 32) {
  console.error('ERROR: ICAL_TOKEN_PEPPER env var is missing or too short (need >= 32 chars)');
  process.exit(2);
}

const csvPath = process.env.RESEND_CSV;
if (!csvPath) {
  console.error('ERROR: RESEND_CSV env var must point to the owner→new-key mapping');
  process.exit(2);
}
if (!fs.existsSync(csvPath)) {
  console.error(`ERROR: RESEND_CSV file not found: ${csvPath}`);
  process.exit(2);
}

// ----------------------------------------------------------------------------
// Owner→key map
// ----------------------------------------------------------------------------
function loadOwnerKeyMap(filePath) {
  const text = fs.readFileSync(filePath, 'utf8');
  const lines = text.split(/\r?\n/).filter((l) => l.trim().length > 0);
  if (lines.length === 0) {
    throw new Error('CSV is empty');
  }
  const header = lines.shift().split(',').map((c) => c.trim().toLowerCase());
  const ownerIdx = header.indexOf('owner_id');
  const keyIdx = header.indexOf('new_resend_api_key');
  if (ownerIdx === -1 || keyIdx === -1) {
    throw new Error('CSV header must contain owner_id and new_resend_api_key');
  }
  const map = new Map();
  for (const line of lines) {
    const cols = line.split(',').map((c) => c.trim());
    if (cols.length < Math.max(ownerIdx, keyIdx) + 1) continue;
    const ownerId = cols[ownerIdx];
    const key = cols[keyIdx];
    if (ownerId && key) {
      map.set(ownerId, key);
    }
  }
  return map;
}

const ownerKeyMap = loadOwnerKeyMap(csvPath);
console.log(`Loaded ${ownerKeyMap.size} owner→key mappings from ${csvPath}`);

// ----------------------------------------------------------------------------
// Logging to migration log file
// ----------------------------------------------------------------------------
const logDir = path.resolve(__dirname, '..', '..', 'audit', 'migrations');
fs.mkdirSync(logDir, {recursive: true});
const logPath = path.join(logDir, `2026-05-18-widget-secrets-${projectId}.log`);
const logStream = fs.createWriteStream(logPath, {flags: 'a'});

function logLine(...parts) {
  const line = `[${new Date().toISOString()}] ${parts.join(' ')}`;
  console.log(line);
  logStream.write(line + '\n');
}

// ----------------------------------------------------------------------------
// Firebase Admin
// ----------------------------------------------------------------------------
admin.initializeApp({projectId});
const db = admin.firestore();

// ----------------------------------------------------------------------------
// Main
// ----------------------------------------------------------------------------
async function main() {
  logLine('=== Starting widget_secrets migration ===');
  logLine('project=', projectId, 'dryRun=', dryRun, 'force=', force);

  const propertiesSnap = await db.collection('properties').get();
  logLine(`Found ${propertiesSnap.size} properties`);

  let total = 0;
  let migrated = 0;
  let skipped = 0;
  let errors = 0;

  for (const propertyDoc of propertiesSnap.docs) {
    const propertyId = propertyDoc.id;
    const propertyData = propertyDoc.data() || {};
    const ownerId = propertyData.owner_id;
    if (!ownerId) {
      logLine(`SKIP property=${propertyId} reason=missing_owner_id`);
      continue;
    }

    const settingsSnap = await propertyDoc.ref.collection('widget_settings').get();
    for (const settingsDoc of settingsSnap.docs) {
      total += 1;
      const unitId = settingsDoc.id;
      const settings = settingsDoc.data() || {};
      const emailConfig = settings.email_config || {};
      const existingResendKey = emailConfig.resend_api_key || null;
      const existingIcalToken = settings.ical_export_token || null;
      // SF-024: iCal cache content leaks bookings/guest PII when widget_settings
      // is publicly readable. Move both blob + etag into widget_secrets too.
      const existingIcalCacheContent = settings.ical_cache_content || null;
      const existingIcalCacheEtag = settings.ical_cache_etag || null;

      const secretsRef = propertyDoc.ref.collection('widget_secrets').doc(unitId);

      try {
        // Idempotency: skip if widget_secrets already migrated (unless --force)
        const existingSecrets = await secretsRef.get();
        if (existingSecrets.exists && !force) {
          const existing = existingSecrets.data() || {};
          if (existing.ical_export_token_hash) {
            logLine(
              `SKIP property=${propertyId} unit=${unitId} reason=already_migrated`,
            );
            skipped += 1;
            continue;
          }
        }

        // Resolve new Resend key from CSV (may be absent if owner never set one)
        let newResendKey = ownerKeyMap.get(ownerId) || null;
        if (existingResendKey && !newResendKey) {
          logLine(
            `WARN property=${propertyId} unit=${unitId} owner=${ownerId} ` +
              `had_old_key=yes but CSV has no replacement — leaving widget_secrets ` +
              `without resend_api_key (CF falls back to platform key)`,
          );
        }

        // Generate fresh iCal token + peppered hash
        const newIcalToken = crypto.randomBytes(32).toString('hex');
        const newIcalTokenHash = crypto
          .createHash('sha256')
          .update(`${newIcalToken}${pepper}`, 'utf8')
          .digest('hex');

        const secretsPayload = {
          property_id: propertyId,
          unit_id: unitId,
          owner_id: ownerId,
          ical_export_token_hash: newIcalTokenHash,
          ical_export_token_plaintext: newIcalToken, // cleaned up in A6
          rotated_at: admin.firestore.FieldValue.serverTimestamp(),
        };
        if (newResendKey) {
          secretsPayload.resend_api_key = newResendKey;
        }
        // SF-024: carry over the existing cache so the first request after
        // migration doesn't have to regenerate. ical_cache_updated_at stamps the
        // moment we relocated, not the original generation time.
        if (existingIcalCacheContent) {
          secretsPayload.ical_cache_content = existingIcalCacheContent;
          secretsPayload.ical_cache_updated_at = admin.firestore.FieldValue.serverTimestamp();
        }
        if (existingIcalCacheEtag) {
          secretsPayload.ical_cache_etag = existingIcalCacheEtag;
        }

        const settingsUpdate = {
          ical_export_token: admin.firestore.FieldValue.delete(),
          'email_config.resend_api_key': admin.firestore.FieldValue.delete(),
          // SF-024: strip cache fields from the publicly readable doc.
          ical_cache_content: admin.firestore.FieldValue.delete(),
          ical_cache_etag: admin.firestore.FieldValue.delete(),
        };

        if (dryRun) {
          logLine(
            `DRY-RUN property=${propertyId} unit=${unitId} owner=${ownerId} ` +
              `old_key_present=${!!existingResendKey} old_token_present=${!!existingIcalToken} ` +
              `new_key_provided=${!!newResendKey} ` +
              `cache_content_present=${!!existingIcalCacheContent} cache_etag_present=${!!existingIcalCacheEtag}`,
          );
        } else {
          await secretsRef.set(secretsPayload, {merge: true});
          await settingsDoc.ref.update(settingsUpdate);
          logLine(
            `MIGRATED property=${propertyId} unit=${unitId} owner=${ownerId} ` +
              `old_key_present=${!!existingResendKey} old_token_present=${!!existingIcalToken} ` +
              `new_key_provided=${!!newResendKey} ` +
              `cache_content_present=${!!existingIcalCacheContent} cache_etag_present=${!!existingIcalCacheEtag}`,
          );
        }
        migrated += 1;
      } catch (error) {
        errors += 1;
        logLine(
          `ERROR property=${propertyId} unit=${unitId} owner=${ownerId} ` +
            `message=${error && error.message ? error.message : String(error)}`,
        );
      }
    }
  }

  logLine('=== Migration done ===');
  logLine(
    `total=${total} migrated=${migrated} skipped=${skipped} errors=${errors} ` +
      `dryRun=${dryRun}`,
  );

  await new Promise((resolve) => logStream.end(resolve));
  process.exit(errors > 0 ? 1 : 0);
}

main().catch((error) => {
  logLine('FATAL', error && error.stack ? error.stack : String(error));
  logStream.end(() => process.exit(3));
});

// Suppress unused readline import warning — kept for potential interactive
// confirmation prompts in later revisions.
void readline;
