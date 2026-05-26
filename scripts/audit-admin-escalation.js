#!/usr/bin/env node
/**
 * Audit admin self-escalation pre-deploy of firestore.rules `role` block.
 *
 * Lists every account flagged as admin via either path and compares against a
 * caller-provided allowlist of intended-admin UIDs. Anyone outside the list is
 * a suspected self-escalation (the rules pre-fix let any signed-up user write
 * `role: "admin"` to their own `users/{uid}` doc, which trips
 * `isAdminFromFirestore()` rule and grants global admin).
 *
 * Sources checked:
 *   1. Firestore: `users` where `role == 'admin'`
 *   2. Firestore: `users` where `isAdmin == true` (defense-in-depth — should not exist)
 *   3. Firebase Auth custom claims: `isAdmin == true`
 *
 * Read-only. Does not mutate. Run before deploying the rules fix.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/sa.json \
 *     node scripts/audit-admin-escalation.js \
 *     --project bookbed-dev \
 *     --intended-admins uid1,uid2,uid3
 *
 *   # Or pipe allowlist from a file:
 *   node scripts/audit-admin-escalation.js --project rab-booking-248fc \
 *     --intended-admins-file ./admins.txt
 *
 * Output: JSON report to stdout + non-zero exit if rogue UIDs found.
 */

'use strict';

const fs = require('fs');
const admin = require('firebase-admin');

function parseArgs(argv) {
  const args = { project: null, intendedAdmins: [], intendedAdminsFile: null };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--project') args.project = argv[++i];
    else if (a === '--intended-admins') args.intendedAdmins = argv[++i].split(',').map((s) => s.trim()).filter(Boolean);
    else if (a === '--intended-admins-file') args.intendedAdminsFile = argv[++i];
    else if (a === '--help' || a === '-h') {
      console.error('Usage: node scripts/audit-admin-escalation.js --project <id> --intended-admins <uid1,uid2> [--intended-admins-file <path>]');
      process.exit(0);
    }
  }
  if (!args.project) {
    console.error('ERROR: --project required (e.g. bookbed-dev or rab-booking-248fc)');
    process.exit(2);
  }
  if (args.intendedAdminsFile) {
    // Operator-supplied CLI flag — read verbatim. No untrusted input source.
    const lines = fs.readFileSync(args.intendedAdminsFile, 'utf8').split('\n');
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) args.intendedAdmins.push(trimmed);
    }
  }
  return args;
}

async function listAllAuthUsersWithAdminClaim(auth) {
  const result = [];
  let nextPageToken;
  do {
    const page = await auth.listUsers(1000, nextPageToken);
    for (const u of page.users) {
      if (u.customClaims && u.customClaims.isAdmin === true) {
        result.push({ uid: u.uid, email: u.email || null });
      }
    }
    nextPageToken = page.pageToken;
  } while (nextPageToken);
  return result;
}

async function listFirestoreAdmins(db, field, value) {
  const snap = await db.collection('users').where(field, '==', value).get();
  return snap.docs.map((d) => ({
    uid: d.id,
    email: d.data().email || null,
    role: d.data().role || null,
    isAdminField: d.data().isAdmin === true,
    createdAt: d.data().createdAt || d.data().created_at || null,
  }));
}

async function main() {
  const args = parseArgs(process.argv);
  const intended = new Set(args.intendedAdmins);

  admin.initializeApp({ projectId: args.project });
  const db = admin.firestore();
  const auth = admin.auth();

  const [firestoreRoleAdmins, firestoreIsAdminField, claimAdmins] = await Promise.all([
    listFirestoreAdmins(db, 'role', 'admin'),
    listFirestoreAdmins(db, 'isAdmin', true),
    listAllAuthUsersWithAdminClaim(auth),
  ]);

  const flagged = new Map();
  const flag = (source, entry) => {
    const existing = flagged.get(entry.uid) || { uid: entry.uid, email: entry.email, sources: [] };
    existing.sources.push(source);
    if (!existing.email && entry.email) existing.email = entry.email;
    if (entry.role !== undefined) existing.role = entry.role;
    if (entry.isAdminField !== undefined) existing.isAdminField = entry.isAdminField;
    if (entry.createdAt) existing.createdAt = entry.createdAt;
    flagged.set(entry.uid, existing);
  };

  for (const u of firestoreRoleAdmins) flag('firestore.users.role==admin', u);
  for (const u of firestoreIsAdminField) flag('firestore.users.isAdmin==true', u);
  for (const u of claimAdmins) flag('auth.customClaims.isAdmin', u);

  const all = Array.from(flagged.values());
  const intendedHits = all.filter((u) => intended.has(u.uid));
  const rogues = all.filter((u) => !intended.has(u.uid));

  const report = {
    project: args.project,
    timestamp: new Date().toISOString(),
    intended_admins_provided: args.intendedAdmins.length,
    intended_admins_seen: intendedHits.map((u) => ({ uid: u.uid, email: u.email, sources: u.sources })),
    rogue_admins: rogues,
    counts: {
      firestore_role_admin: firestoreRoleAdmins.length,
      firestore_isAdmin_field: firestoreIsAdminField.length,
      auth_claim_admin: claimAdmins.length,
      unique_admins_total: all.length,
      rogue: rogues.length,
    },
  };

  process.stdout.write(JSON.stringify(report, null, 2) + '\n');

  if (rogues.length > 0) {
    console.error(`\nFAIL: ${rogues.length} rogue admin account(s) detected. Investigate before deploying rules.`);
    console.error('Suggested remediation per rogue UID:');
    console.error('  1. Force token refresh: admin.auth().revokeRefreshTokens(uid)');
    console.error('  2. Clear claim: admin.auth().setCustomUserClaims(uid, null)');
    console.error('  3. Strip Firestore fields: users/{uid}.update({ role: FieldValue.delete(), isAdmin: FieldValue.delete() })');
    process.exit(1);
  }
  console.error(`\nOK: no rogue admin accounts detected for project ${args.project}.`);
}

main().catch((err) => {
  console.error('Audit failed:', err.stack || err.message || err);
  process.exit(2);
});
