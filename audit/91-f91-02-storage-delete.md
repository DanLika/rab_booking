# audit/91 — F-91-02 Storage DELETE deny + SEC-001 / SF-025 silent-no-op (SF-067)

**Date:** 2026-05-30
**Branch:** `test/f91-02-storage-delete-0530`
**Worktree:** `/tmp/bb-f91-wt`
**Scope:** `storage.rules` only. NULA PROD. bookbed-dev only.
**Outcome:** 17/17 cases PASS on bookbed-dev post-fix. PROD cutover gated on operator IAM grant (see §6).

---

## 1. F-91-02 — silent owner DELETE deny on `users/**`

### Hypothesis from F-91-02

The pre-fix `allow write` clause in every `match` block gates on `request.resource.size < N` and/or `request.resource.contentType.matches(...)`. On a DELETE op, `request.resource` is null — those clauses evaluate against null → comparison fails → DELETE silently denied for the legitimate owner.

### Empirical confirmation

Live REST smoke on bookbed-dev, signed in as `bookbed-test@bookbed.io` (UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`), bucket `bookbed-dev.firebasestorage.app`:

| Case | Path | Op | Expect | Pre-fix |
|------|------|----|--------|---------|
| S1 | `users/{TEST_UID}/f91-smoke/img.png` | PUT image/png 88 B | 200 | **200 ✅** (write OK pre-fix) |
| S6 | `users/{TEST_UID}/f91-smoke/img.png` | DELETE (owner) | 200/204 | **403 ❌** F-91-02 |

→ Hypothesis confirmed. F-91-02 LIVE on `users/**`.

### Code-side blast radius

`grep -rn "\.delete()" lib/ --type dart` for Storage refs identified 3 active client DELETE call sites — all silently broken pre-fix:

1. `lib/core/services/storage_service.dart:118` `deleteProfileImage` — *catch-block swallows error* → user clicks "remove profile image"; UI updates; **file persists in Storage forever**.
2. `lib/features/owner_dashboard/data/firebase/firebase_owner_properties_repository.dart:346` `deletePropertyImage` — re-throws `PropertyException` → user sees error toast; would have surfaced as a complaint at some point, but didn't (probable explanation §7).
3. `lib/core/services/ical_export_service.dart:151` `deleteIcalFile` — partial swallow (only `object-not-found` ignored; everything else rethrows but is itself wrapped further up by `autoRegenerateIfEnabled` catch at 131-137 → silent).

---

## 2. Bonus discovery — SEC-001 + SF-025 silent-no-op DENY since Jan 7, 2026

While extending the smoke to cover the other rule blocks, both write AND read on `properties/**` and `ical-exports/**` from the legitimate owner also denied (S2/S3/S12). Tautology test (rules stripped of the Firestore lookup, `request.auth != null` only):

| Case | Path | Op | With `firestore.get(...)` lookup | Without lookup |
|------|------|----|----------------------------------|----------------|
| TAUT_S2 | `properties/{PID}/...` | PUT | 403 | **200** |
| TAUT_S3 | `ical-exports/{PID}/{UID}/...` | PUT | 403 | **200** |
| TAUT_S7 | same | DELETE | 403 | **204** |
| TAUT_S8 | same | DELETE | 403 | **204** |

→ The Firestore cross-product lookup was the deny source on `properties/**` + `ical-exports/**`.

### Root cause: two bugs in the original SEC-001 / SF-025 rule text

#### Bug 2A — `get(...)` is Firestore-rules-only syntax

Storage rules require `firestore.get(...)` (and `firestore.exists(...)`) per Firebase docs. Plain `get(...)` compiles with a non-fatal compiler warning the deploy CLI emits as:

```
⚠  [W] 42:12 - Invalid function name: get.
```

(Empirically observed on first re-deploy attempt during this audit.) The deploy still releases. Runtime: the call evaluates to null → `null.data.owner_id == request.auth.uid` is false → DENY.

#### Bug 2B — `$(database)` is unbound in Storage rules

Firestore rules wrap content in `match /databases/{database}/documents` which captures `database`. Storage rules have no such enclosing match — `$(database)` is a free variable with no value. Per Firebase docs, the literal `(default)` must be used.

### Timeline

- **Jan 7, 2026** — SEC-001 added the IDOR ownership check to `properties/{propertyId}/{allPaths=**}` write rule (commit `a91757d2`).
- **May 22, 2026** — SF-025 (audit/17) added the same pattern to `ical-exports/{propertyId}/{unitId}/{allPaths=**}` read + write (commit `79e7f9a7`).

→ For ~5 months on `properties/**` and ~8 days on `ical-exports/**`, every legitimate owner write to these paths has been silently DENY. The security goal of SEC-001 (block IDOR overwrites) was achieved — but as a side-effect of *everything* denying, not as the intended owner-only allow.

### Why this was never user-visible

| Production write path | Storage rule it actually hits | Status |
|-----------------------|-------------------------------|--------|
| `storage_service.dart:135` `uploadPropertyImage` → `users/{uid}/properties/{pid}/{fname}` | `match /users/{userId}/**` | ✅ works (auth-only) |
| `storage_service.dart:170` `uploadUnitImage` → `users/{uid}/properties/{pid}/units/{uid}/{fname}` | `match /users/{userId}/**` | ✅ works |
| `firebase_owner_properties_repository.dart:323` `uploadPropertyImage` → `property-images/{pid}/{fname}` | default deny `match /{allPaths=**}` | ❌ **denied** (latent — separate finding §8) |
| `ical_export_service.dart:266` `_uploadToStorage` → `ical-exports/{pid}/{uid}/calendar.ics` | `match /ical-exports/{propertyId}/{unitId}/**` | ❌ **silently denied for ~8 days** |
| `ical_export_service.dart:151` `deleteIcalFile` | same | ❌ silently denied |

For the iCal path, `ical_export_service.dart:131-137` `autoRegenerateIfEnabled()` has a top-level `catch` that downgrades the failure to a log line and returns. Net surface: every booking change since 2026-05-22 has silently failed to refresh the owner's downstream `.ics` feed on this code path. (The CF-side iCal pipeline in `functions/src/icalSync.ts` runs admin-SDK and bypasses Storage rules; that path is unaffected and likely the reason no operator noticed.)

---

## 3. Fix (storage.rules)

Three changes in one diff:

1. **F-91-02 fix:** split `allow write` → `allow create, update` + `allow delete` in all three protected blocks (`users/`, `properties/`, `ical-exports/`). Size and content-type gates apply only to `create, update`; `delete` carries auth/ownership only. Per Firebase docs the granular keywords are the canonical way — `request.method` is Firestore-only and not exposed in Storage rules.
2. **SEC-001 / SF-025 fix A:** `get(...)` → `firestore.get(...)`.
3. **SEC-001 / SF-025 fix B:** `$(database)` → `(default)`.

Identical comment blocks above each `match` document the why so future readers find it before re-introducing the regression.

Cross-product `firestore.get(...)` from Storage rules also requires the Firebase Storage service agent to have read access to Firestore. See §4.

---

## 4. IAM grant required for Firestore lookups (operator step)

`firestore.get()` from a Storage rule is executed by the Firebase Storage service agent:

```
service-{PROJECT_NUMBER}@gcp-sa-firebasestorage.iam.gserviceaccount.com
```

On bookbed-dev (project number `733027606474`), pre-fix this principal had only `roles/firebasestorage.serviceAgent`. The cross-product Firestore reads silently returned null → ownership check failed → deny.

Fix applied to bookbed-dev during this audit:

```bash
gcloud projects add-iam-policy-binding bookbed-dev \
  --member="serviceAccount:service-733027606474@gcp-sa-firebasestorage.iam.gserviceaccount.com" \
  --role="roles/datastore.viewer" \
  --condition=None
```

`roles/datastore.viewer` is read-only and the minimal scope sufficient for `firestore.get()` + `firestore.exists()`.

For PROD cutover (rab-booking-248fc), the operator must run the same `add-iam-policy-binding` against PROD's storage service agent (different `{PROJECT_NUMBER}`) before deploying these rules — otherwise the new owner-allow path on `properties/**` and `ical-exports/**` will continue to silently deny. The deploy itself does not surface this requirement; only a post-deploy smoke does.

→ **operator blocker** added to PROD-cutover dependency list (cross-ref audit/90).

---

## 5. Final smoke matrix — 17/17 PASS on bookbed-dev

Post-fix + post-IAM-grant, with `test-acct` (`bookbed-test@bookbed.io`), throwaway acct for IDOR, and anon caller. Bucket `bookbed-dev.firebasestorage.app`.

| Case | Path | Actor | Op | Expect | Actual |
|------|------|-------|----|--------|--------|
| S1 | `users/{TEST_UID}/f91-final/img.png` | owner | PUT image/png | 200 | 200 ✅ |
| S2 | `properties/{PID}/f91-final/img.png` | owner | PUT image/png | 200 | **200 ✅** (NEW — was 403) |
| S3 | `ical-exports/{PID}/{UNIT}/f91-final.ics` | owner | PUT text/calendar | 200 | **200 ✅** (NEW) |
| S12 | same | owner | GET | 200 | **200 ✅** (NEW) |
| S4 | `users/{TEST_UID}/f91-final/evil.svg` | owner | PUT image/svg+xml | 403 | 403 ✅ (L-04 cap intact) |
| S5 | `ical-exports/{PID}/{UNIT}/big.bin` | owner | PUT 6 MiB | 403 | 403 ✅ (5 MiB cap intact) |
| S18 | `properties/{PID}/big.bin` | owner | PUT 11 MiB | 403 | 403 ✅ (10 MiB cap intact) |
| S6 | `users/{TEST_UID}/f91-final/img.png` | owner | DELETE | 200/204 | **204 ✅** (F-91-02 fix) |
| S7 | `properties/{PID}/f91-final/img.png` | owner | DELETE | 200/204 | **204 ✅** (F-91-02 fix) |
| S8 | `ical-exports/{PID}/{UNIT}/f91-final.ics` | owner | DELETE | 200/204 | **204 ✅** (F-91-02 fix) |
| S9 | `users/{TEST_UID}/...` | throwaway | DELETE | 401/403 | 403 ✅ (IDOR intact) |
| S10 | same | anon | DELETE | 401/403 | 403 ✅ |
| S11 | `ical-exports/{PID}/{UNIT}/...` | anon | GET | 401/403 | 403 ✅ (SF-025 intact) |
| S13 | `properties/{PID}/...` | throwaway | PUT | 403 | 403 ✅ (SEC-001 intact) |
| S14 | `ical-exports/{PID}/{UNIT}/...` | throwaway | PUT | 403 | 403 ✅ |
| S15 | `properties/{PID}/...` | throwaway | DELETE | 403 | 403 ✅ |
| S16 | `ical-exports/{PID}/{UNIT}/...` | throwaway | DELETE | 403 | 403 ✅ |

Throwaway acct `f91-throwaway-1780126102260@example.test` (UID `FTbweWhjMYNbI2ypioe2nJgv5Yw1`) deleted after smoke (HTTP 200 from `accounts:delete`).

Files uploaded during smoke deleted at end. Bucket left clean.

---

## 6. PROD cutover prereqs

Before deploying these rules to `rab-booking-248fc`:

1. Identify PROD storage service agent: `service-{PROD_PROJECT_NUMBER}@gcp-sa-firebasestorage.iam.gserviceaccount.com`. The project number is in `lib/firebase_options.dart` `messagingSenderId` for the PROD web config.
2. Grant `roles/datastore.viewer` to that principal:

```bash
gcloud projects add-iam-policy-binding rab-booking-248fc \
  --member="serviceAccount:service-{PROD_PROJECT_NUMBER}@gcp-sa-firebasestorage.iam.gserviceaccount.com" \
  --role="roles/datastore.viewer" \
  --condition=None
```

3. Verify with `gcloud projects get-iam-policy rab-booking-248fc --flatten="bindings[].members" --filter="bindings.members:service-{PROD_PROJECT_NUMBER}@gcp-sa-firebasestorage.iam.gserviceaccount.com"` — should show both `roles/firebasestorage.serviceAgent` AND `roles/datastore.viewer`.
4. Deploy storage rules: `firebase deploy --only storage --project rab-booking-248fc`.
5. Re-run the §5 smoke matrix against PROD (against a known-PROD test acct + property — see [[test-account-prod]] for credentials).

Skipping step 2 reverts the rule to its current ~5-month silent-DENY state for `properties/**` + `ical-exports/**`, which would now ALSO silently DENY `users/**` DELETE because the F-91-02 split landed against the broken Firestore lookup. **The IAM grant is load-bearing for both fixes once these rules ship.**

Add to [audit/90](./90-prod-cutover-runbook.md) operator blockers list.

---

## 7. Why `firebase_owner_properties_repository.dart` `deletePropertyImage` complaints never landed

Tracking down whether this DELETE deny ever surfaced to users:

| Storage path actually used for property images | Rule it hits | Pre-fix DELETE outcome |
|------------------------------------------------|---------------|------------------------|
| `users/{uid}/properties/{pid}/{fname}` (storage_service.dart) | `users/**` block | F-91-02 deny (silent — UI uses try/catch on `deleteProfileImage` only; `deletePropertyImage` rethrows but property edit flow may not actively delete) |
| `property-images/{pid}/{fname}` (firebase_owner_properties_repository.dart:323) | default deny | always 403 even on UPLOAD — code path may be unused / dead-coded |
| Anything else | default deny | n/a |

The `property-images/` path appears not to be reached in production owner flows (no smoke ran it; client-side it's only wired into the legacy repository, may be superseded by `storage_service.dart` calls). Filed as F-91-04 if reproducible — out of scope for this PR.

---

## 8. Out-of-scope / follow-ups

- **F-91-04** (suspected): `property-images/{pid}/**` storage path written by `firebase_owner_properties_repository.dart:323` has no matching rule → default deny. Either dead code or a latent broken upload path. Needs grep for current callers + flow audit. Not closed here.
- **App Check enforcement** on Firebase Storage on bookbed-dev: API disabled (`SERVICE_DISABLED` from `firebaseappcheck.googleapis.com`). Not blocking this fix; tracked separately under SF-061 (App Check enforcement DEFERRED).
- **iCal export silent-failure surfacing**: `ical_export_service.dart:131-137` catch-and-log pattern hid the SF-025 regression for ~8 days. Worth adding a Sentry breadcrumb or a circuit-breaker that triggers after N consecutive auto-regen failures.

---

## 9. Files changed

- `storage.rules` — rewrote 3 `match` blocks per §3.
- `docs/SECURITY_FIXES.md` — added SF-067 entry.
- `audit/91-f91-02-storage-delete.md` (this doc).
- `CLAUDE.md` — index entry pointing here.

No client-side code change. The bug was entirely in the rules surface; once rules eval correctly, existing `ref.delete()` / `ref.putData()` callers stop returning 403.

---

## 10. Smoke artifacts

- `/tmp/f91-prefix-results.json` — pre-fix matrix (S6 deny + S2/S3 deny baseline).
- `/tmp/f91-postfix-final.json` — final 17/17 PASS matrix.

(Files local to the audit run worktree, not committed.)
