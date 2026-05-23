# audit/30 — Eliminate `isAdminFromFirestore()` (defense-in-depth post-hotfix)

**Status:** candidate / not started
**Sized:** M (~4–6h)
**Blocks:** nothing immediate
**Blocked by:** `hotfix/role-escalation-deploy-unblock` (which closes the exploitable hole)
**Author hint:** spawned from `/vibe-security` audit 2026-05-23

---

## 1. Why this exists

The hotfix `hotfix/role-escalation-deploy-unblock` added `'role'` to the
protected-fields allowlist in `firestore.rules` so clients can no longer
self-promote via `users/{uid}.role = 'admin'`. That closes the **exploitable**
gap.

What it does **not** address: the rule `isAdminFromFirestore()` still grants
admin authority based on a Firestore document field — a category of design
where DB writes become security decisions. Even with the field protected, the
shape is fragile:

- Any future rule that writes `role` from a less-scrutinized surface re-opens
  the hole (e.g. a server-side migration script with broken claim check, a
  badly-scoped admin CF, a partner-import seed job).
- The rule helper does a `get(/databases/.../users/{uid})` on every read/write
  evaluation — adds a Firestore read per gated operation, raises bill, slows
  hot paths.
- Two parallel admin signals (JWT claim `isAdmin` + Firestore `role`) means
  two places to keep in sync. JWT claim is already authoritative for CFs
  (`functions/src/admin/*.ts` only checks `request.auth.token.isAdmin`).

The cleaner shape: admin authority lives **only** in the JWT custom claim.
Firestore rules check `request.auth.token.isAdmin == true` and nothing else.
Admin Dashboard reads that need cross-user reach move to Cloud Functions that
gate on the claim and call the Admin SDK.

## 2. Current call sites

```bash
grep -n "isAdminFromFirestore" firestore.rules
```

Yields ~10 call sites in `firestore.rules` (helpers + every `match` that
allows "admin can do X via DB role"). All need to be migrated.

## 3. Migration plan

### Step 1 — inventory Admin Dashboard reads (Flutter)
- Find all repositories / providers that perform admin reads across users
  (e.g. `lib/features/admin/data/repositories/users_repository.dart`).
- For each read: does it need cross-user reach, or just the current user?
  Cross-user → CF migration. Single-user (current admin's profile) → unchanged.

### Step 2 — author the CF reads
For each cross-user read identified, add (or extend) a callable in
`functions/src/admin/` that:
- gates on `request.auth?.token.isAdmin === true`
- pages results server-side (avoid pulling the entire `users` collection)
- returns sanitized projections (no `password_hash`-equivalent surfaces, no
  customer PII the admin doesn't need)

### Step 3 — flip the dashboard to CFs
Replace direct Firestore reads in Admin Dashboard repos with `httpsCallable`
to the new CFs. Riverpod providers stay the same shape; the data source
changes.

### Step 4 — drop the rule helper
```diff
- function isAdminFromFirestore() {
-   return isAuthenticated() &&
-     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
- }
```

And in every `allow ...: if ... || isAdmin() || isAdminFromFirestore();`
clause, drop the `|| isAdminFromFirestore()` tail.

### Step 5 — bootstrap path for the first admin
Currently the first admin is bootstrapped via direct Firestore write (set
`users/{uid}.role = 'admin'` + claim via the Firebase Auth admin SDK). After
this audit lands, the bootstrap is **only** the claim — drop the Firestore
write. Document the bootstrap recipe in `docs/admin-bootstrap.md`.

## 4. Rollback / risk

- **Rollback:** revert the rule helper deletion + reintroduce the
  `|| isAdminFromFirestore()` tails. Safe — fixed by the hotfix, not by this
  follow-up.
- **Risk during migration:** if an Admin Dashboard read is missed and still
  hits Firestore directly, it will start failing once the rule helper is
  dropped. Mitigation: Step 1 inventory + ship the change behind a feature
  flag (read CF response in parallel with current Firestore read, alert on
  divergence) before flipping the rule cutover.

## 5. Test plan

- Extend `functions/test/firestore_rules/users.test.ts`:
  - admin via Firestore `/users/{uid}.role == 'admin'` → DENIED (after rule
    helper is dropped)
  - admin via JWT claim `isAdmin: true` → still ALLOWED everywhere
- E2E: log in as admin, open Admin Dashboard, verify every page renders + CRUD
  flows work via new CFs.
- Sentry: monitor for `firestore/permission-denied` in admin dashboard traffic
  for 48h after deploy.

## 6. See also

- `hotfix/role-escalation-deploy-unblock` — the Critical fix this audit is the
  defense-in-depth follow-up for
- `firestore.rules:39` — current `isAdminFromFirestore()` definition
- `functions/src/admin/setLifetimeLicense.ts`, `functions/src/admin/updateUserStatus.ts` —
  reference shape of claim-gated admin CFs

## 7. Sign-off (when work completes)

| Section | State |
|---|---|
| §1 inventory of cross-user dashboard reads | ⏳ |
| §2 CF reads authored | ⏳ |
| §3 dashboard flipped to CFs | ⏳ |
| §4 rule helper dropped | ⏳ |
| §5 bootstrap recipe documented | ⏳ |
| §6 rules tests extended | ⏳ |
| §7 prod 48h Sentry watch clean | ⏳ |
