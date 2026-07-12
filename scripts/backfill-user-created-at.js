#!/usr/bin/env node
/**
 * Backfill `created_at` on user docs that only carry the legacy camelCase
 * `createdAt`.
 *
 * Why: `UserModel` and the admin Users list both read the canonical snake_case
 * `created_at` (matching `first_name` / `avatar_url`), but profile creation in
 * `enhanced_auth_provider` used to write only `createdAt`. Firestore's
 * `orderBy('created_at')` SILENTLY DROPS docs missing the field, so every owner
 * created through the app was invisible in the admin Users list while still
 * being counted by the `.count()` badge (PROD: 11 of 23 owners hidden).
 *
 * The code fix (writing both names) only covers NEW docs — this backfills the
 * existing ones. Source of truth, in order: existing `createdAt`, else the
 * Firebase Auth user's `creationTime`.
 *
 * Usage:
 *   node scripts/backfill-user-created-at.js --project=<id>            # dry run
 *   node scripts/backfill-user-created-at.js --project=<id> --force    # write
 */
const path = require('path');
// firebase-admin lives in functions/node_modules (repo has no root node_modules).
const admin = require(
  require.resolve('firebase-admin', {
    paths: [path.resolve(__dirname, '../functions/node_modules')],
  })
);

const args = process.argv.slice(2);
const projectId = (args.find((a) => a.startsWith('--project=')) || '').split('=')[1];
const force = args.includes('--force');

if (!projectId) {
  console.error('ERROR: --project=<firebase-project-id> is required');
  process.exit(1);
}

admin.initializeApp({ projectId });
const db = admin.firestore();

(async () => {
  console.log(`[backfill] project=${projectId} mode=${force ? 'FORCE (writes)' : 'DRY RUN'}`);

  const snap = await db.collection('users').get();
  const missing = snap.docs.filter((d) => !d.data().created_at);

  console.log(`[backfill] users=${snap.size} missing created_at=${missing.length}`);
  if (missing.length === 0) {
    console.log('[backfill] nothing to do');
    process.exit(0);
  }

  let written = 0;
  let noSource = 0;

  for (const doc of missing) {
    const data = doc.data();
    let source = null;
    let value = null;

    if (data.createdAt) {
      source = 'createdAt';
      value = data.createdAt; // already a Timestamp
    } else {
      // Fall back to the Auth record's creationTime.
      try {
        const user = await admin.auth().getUser(doc.id);
        if (user.metadata && user.metadata.creationTime) {
          source = 'auth.creationTime';
          value = admin.firestore.Timestamp.fromDate(new Date(user.metadata.creationTime));
        }
      } catch (_) {
        // Auth user gone (orphan doc) — leave it alone rather than invent a date.
      }
    }

    if (!value) {
      noSource++;
      console.log(`  SKIP  ${doc.id} (${data.email || 'no email'}) — no createdAt, no auth record`);
      continue;
    }

    const iso = value.toDate().toISOString().slice(0, 10);
    console.log(`  ${force ? 'WRITE' : 'WOULD'} ${doc.id} (${data.email || 'no email'}) created_at=${iso} [from ${source}]`);

    if (force) {
      await doc.ref.update({ created_at: value });
      written++;
    }
  }

  console.log(`[backfill] done — ${force ? `written=${written}` : `would write=${missing.length - noSource}`} skipped=${noSource}`);
  process.exit(0);
})();
