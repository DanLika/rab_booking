#!/usr/bin/env node
/**
 * Backfill `users/{uid}.accountStatus` drift surfaced by audit/109 §9 Q4
 * and SF-078 pre-flight (audit/110-trial-gate-map.md).
 *
 * Drift classes targeted:
 *   1. accountStatus == 'premium'  (off-spec — not in client enum `AccountStatus`
 *      ∈ {trial, active, trial_expired, suspended}). Normalise to 'active' if
 *      the user carries a live paying-subscription signal (`accountType ∈
 *      {premium, lifetime}` OR `stripeSubscriptionId` set OR
 *      `lifetime_license_granted_at` present). Flagged otherwise for manual
 *      review.
 *   2. accountStatus missing / null. Derive from `trialExpiresAt`:
 *        trialExpiresAt > now    → 'trial'
 *        trialExpiresAt <= now   → 'trial_expired'
 *        no trialExpiresAt       → MANUAL_TRIAGE (no write)
 *   3. Known values (trial, active, trial_expired, suspended) → no-op.
 *
 * Writer-audit (2026-06-03):
 *   grep -rn 'accountStatus[: =].*[\"']' functions/src
 *   → ZERO live writers produce 'premium'. The 3 PROD users carrying
 *   'premium' as accountStatus are legacy data (likely hand-set via
 *   Firebase Console with field-name confusion vs `accountType: 'premium'`).
 *   `admin/updateUserStatus.ts:17` enforces VALID_STATUSES
 *   = ['trial','active','trial_expired','suspended'] — 'premium' rejected.
 *   ⇒ Backfill is safe to ship; no re-drift source.
 *
 * Safety:
 *   - Defaults to --dry-run. Pass --execute to mutate.
 *   - Idempotent per user. Re-running after --execute is a no-op.
 *   - Refuses to run unless an explicit --project flag is given.
 *   - Logs to audit/migrations/<date>-accountstatus-backfill-<env>.log
 *
 * Usage:
 *   node scripts/backfill-accountstatus.js --project bookbed-dev
 *   node scripts/backfill-accountstatus.js --project bookbed-dev --execute
 *   node scripts/backfill-accountstatus.js --project rab-booking-248fc
 *   node scripts/backfill-accountstatus.js --project rab-booking-248fc --execute
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS pointing at a service account with
 * Firestore Admin SDK scope (read + write `users/{uid}` on the target project).
 *
 * Audit trail: audit/109 §9, audit/110, SF-078 pre-flight.
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

// ── Output log ────────────────────────────────────────────────────────────
const ENV = PROJECT_ID === 'rab-booking-248fc' ? 'prod' : (PROJECT_ID === 'bookbed-dev' ? 'dev' : PROJECT_ID);
const NOW = new Date();
const datePrefix = NOW.toISOString().slice(0, 10);
const mode = EXECUTE ? 'EXECUTE' : 'DRYRUN';
const logDir = path.join(__dirname, '..', 'audit', 'migrations');
const logFile = path.join(logDir, `${datePrefix}-accountstatus-backfill-${ENV}-${mode}.log`);
fs.mkdirSync(logDir, { recursive: true });
const logStream = fs.createWriteStream(logFile, { flags: 'a' });
function log(line) {
  process.stdout.write(line + '\n');
  logStream.write(line + '\n');
}

// ── Helpers ──────────────────────────────────────────────────────────────
const KNOWN_STATUSES = new Set(['trial', 'active', 'trial_expired', 'suspended']);

function classify(uid, data) {
  const status = data.accountStatus;
  const accountType = data.accountType;
  const trialExpiresAt = data.trialExpiresAt;
  const stripeSubscriptionId = data.stripeSubscriptionId || data.stripe_subscription_id;
  const lifetimeGrantedAt = data.lifetime_license_granted_at;

  const flags = [];

  // 1. premium → active candidate
  if (status === 'premium') {
    const hasLifetime = !!lifetimeGrantedAt || accountType === 'lifetime';
    const hasStripeSub = !!stripeSubscriptionId;
    const hasPremiumType = accountType === 'premium';

    if (hasLifetime) flags.push('lifetime');
    if (hasStripeSub) flags.push('stripeSubscriptionId-set');
    if (hasPremiumType) flags.push('accountType=premium');

    // Confidence: any signal of paying / lifetime is sufficient to normalise
    // to 'active'. Without any signal, flag MANUAL_REVIEW.
    if (hasLifetime || hasStripeSub || hasPremiumType) {
      return {
        action: 'UPDATE',
        current: status,
        proposed: 'active',
        reason: 'premium-normalise',
        flags,
      };
    }
    return {
      action: 'MANUAL_REVIEW',
      current: status,
      proposed: '(none — needs operator review)',
      reason: 'premium-without-paying-signal',
      flags,
    };
  }

  // 2. missing / null status
  if (status == null) {
    if (trialExpiresAt) {
      let expiresMillis;
      if (typeof trialExpiresAt.toMillis === 'function') {
        expiresMillis = trialExpiresAt.toMillis();
      } else if (trialExpiresAt._seconds != null) {
        expiresMillis = trialExpiresAt._seconds * 1000;
      } else if (trialExpiresAt instanceof Date) {
        expiresMillis = trialExpiresAt.getTime();
      } else {
        return {
          action: 'MANUAL_REVIEW',
          current: '<missing>',
          proposed: '(none — unparseable trialExpiresAt)',
          reason: 'unparseable-trial-expires',
          flags: ['trialExpiresAt-shape:' + typeof trialExpiresAt],
        };
      }
      const isExpired = expiresMillis <= NOW.getTime();
      return {
        action: 'UPDATE',
        current: '<missing>',
        proposed: isExpired ? 'trial_expired' : 'trial',
        reason: isExpired ? 'derived-from-trialExpiresAt-past' : 'derived-from-trialExpiresAt-future',
        flags: ['trialExpiresAt=' + new Date(expiresMillis).toISOString()],
      };
    }
    return {
      action: 'MANUAL_TRIAGE',
      current: '<missing>',
      proposed: '(none — no trialExpiresAt)',
      reason: 'missing-status-and-no-trial-expiry',
      flags: [],
    };
  }

  // 3. Known values → no-op
  if (KNOWN_STATUSES.has(status)) {
    return { action: 'NOOP', current: status, proposed: status, reason: 'known-canonical', flags: [] };
  }

  // 4. Other unknown values (defensive)
  return {
    action: 'MANUAL_REVIEW',
    current: status,
    proposed: '(none — unknown value)',
    reason: 'unknown-status-value',
    flags: [],
  };
}

// ── Main ─────────────────────────────────────────────────────────────────
async function main() {
  log('SF-078 backfill — accountStatus drift normalise');
  log(`Project: ${PROJECT_ID}`);
  log(`Mode:    ${EXECUTE ? 'EXECUTE (will mutate Firestore)' : 'DRY RUN (no writes)'}`);
  log(`Started: ${NOW.toISOString()}`);
  log(`Log:     ${path.relative(path.join(__dirname, '..'), logFile)}`);
  log('');

  const snap = await db.collection('users').get();
  log(`Found ${snap.size} user document(s).`);
  log('');

  const summary = { UPDATE: 0, NOOP: 0, MANUAL_REVIEW: 0, MANUAL_TRIAGE: 0 };
  const breakdownByReason = {};
  const updates = []; // collected for batch apply

  for (const doc of snap.docs) {
    const data = doc.data();
    const c = classify(doc.id, data);
    summary[c.action] = (summary[c.action] || 0) + 1;
    breakdownByReason[c.reason] = (breakdownByReason[c.reason] || 0) + 1;

    const flagStr = c.flags.length ? ` [${c.flags.join(', ')}]` : '';
    log(`  ${doc.id.padEnd(36)} | ${String(c.current).padEnd(16)} → ${String(c.proposed).padEnd(28)} | ${c.action.padEnd(15)} | ${c.reason}${flagStr}`);

    if (c.action === 'UPDATE') {
      updates.push({ ref: doc.ref, current: c.current, proposed: c.proposed });
    }
  }

  log('');
  log('─── Summary ───────────────────────────────────────────────');
  for (const [action, n] of Object.entries(summary)) {
    log(`  ${action.padEnd(16)} ${String(n).padStart(4)}`);
  }
  log('');
  log('─── By reason ─────────────────────────────────────────────');
  for (const [reason, n] of Object.entries(breakdownByReason)) {
    log(`  ${reason.padEnd(40)} ${String(n).padStart(4)}`);
  }
  log('');

  if (!EXECUTE) {
    log('DRY RUN complete — no writes performed.');
    log(`  ${updates.length} UPDATE candidate(s); ${summary.MANUAL_REVIEW || 0} MANUAL_REVIEW; ${summary.MANUAL_TRIAGE || 0} MANUAL_TRIAGE.`);
    log('Re-run with --execute to apply UPDATE rows. MANUAL_REVIEW / MANUAL_TRIAGE rows are NEVER auto-applied.');
  } else {
    log(`Applying ${updates.length} update(s)...`);
    const BATCH_SIZE = 250;
    let written = 0;
    for (let i = 0; i < updates.length; i += BATCH_SIZE) {
      const batch = db.batch();
      const chunk = updates.slice(i, i + BATCH_SIZE);
      for (const u of chunk) {
        batch.update(u.ref, {
          accountStatus: u.proposed,
          statusChangedAt: admin.firestore.FieldValue.serverTimestamp(),
          statusChangedBy: 'scripts/backfill-accountstatus.js (SF-078)',
          statusChangeReason: `backfill: ${u.current} → ${u.proposed}`,
        });
      }
      await batch.commit();
      written += chunk.length;
      log(`  Wrote batch ${i / BATCH_SIZE + 1} (${written}/${updates.length})`);
    }
    log(`EXECUTE complete — ${written} document(s) updated.`);
  }

  log(`Finished: ${new Date().toISOString()}`);
  logStream.end();
  await admin.app().delete();
}

main().catch((err) => {
  console.error('FATAL:', err);
  logStream.end();
  process.exit(1);
});
