# Sentry env-tag fix + Wave 0 seed verification

**Date:** 2026-05-21
**Branch:** `fix/sentry-env-detection` off `main` → merged into `main` as `4b56f8fb`, pushed to origin
**Commits:**
- `91224f23 fix(sentry): detect env from GCP_PROJECT|GCLOUD_PROJECT, add staging`
- `78d1cc46 chore(sentry): log resolved env + project env vars at init`
- `4b56f8fb Merge: Sentry env detection fix` (no-ff into main)

**Deploys:**
- bookbed-dev: 50 functions redeployed (commits 91224f23 + 78d1cc46)
- rab-booking-248fc (prod): 50 functions redeployed

**Scope note:** `--only functions:<list>` of 50 healthy source functions used instead of `--only functions`. Plain `--only functions` would have prompted to delete 6 dev-only orphans (`comebackReminder`, Airbnb/Booking OAuth pair, `sendOwnerEmail`) that are still needed for the in-flight `hotfix/widget-secrets-exfil` work and the audit-pending OAuth ship-or-cut decision — not authorized in scope of this fix.

## Trigger

Sentry issue `120771669` ("Error: Booking not found") came in on 2026-05-18 17:22 CEST tagged `environment: production`. The exception URL is `https://us-central1-bookbed-dev.cloudfunctions.net/` — clearly **bookbed-dev**, not prod. Same misclassification was already flagged in `.claude/rules/cloud-functions.md` ("Sentry env tag bug audit 2026-05-18"). Cleaning this up makes the prod Sentry dashboard trustworthy again.

## Root cause

`functions/src/sentry.ts:30-32` used:

```ts
environment: process.env.FUNCTIONS_EMULATOR === "true"
  ? "local"
  : (process.env.GCP_PROJECT === "rab-booking-248fc" ? "production" : "development"),
```

In Cloud Functions Gen 2 (all current functions are v2), `GCP_PROJECT` is not reliably populated; `GCLOUD_PROJECT` is the documented fallback. Worse, when `GCP_PROJECT` is empty the ternary already routes everything else to `"development"`, but `bookbed-staging` would also be labeled `"development"`, and any env where `GCP_PROJECT` resolves to the production id (legacy v1 carry-over, manual export) gets `"production"` regardless of project.

## Fix (diff)

```diff
+/**
+ * Detect the Sentry environment tag from runtime env vars.
+ *
+ * Cloud Functions Gen 2 does not reliably populate GCP_PROJECT; GCLOUD_PROJECT
+ * is the documented fallback. Returning explicit per-project labels prevents
+ * dev/staging errors from polluting the production Sentry dashboard.
+ */
+function detectEnvironment(): string {
+  if (process.env.FUNCTIONS_EMULATOR === "true") return "local";
+  const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
+  if (projectId === "bookbed-dev") return "development";
+  if (projectId === "bookbed-staging") return "staging";
+  if (projectId === "rab-booking-248fc") return "production";
+  return "unknown";
+}
@@
-      environment: process.env.FUNCTIONS_EMULATOR === "true"
-        ? "local"
-        : (process.env.GCP_PROJECT === "rab-booking-248fc" ? "production" : "development"),
+      environment: detectEnvironment(),
```

Build: `npm run build` → 0 errors.

## Seed verification (Task A)

Sentry payload showed `bookingId: SEED_booking_dev_01, bookingReference: BB-SEED01, guestEmail: seed-guest@example.com` — a wave0 smoke-test fixture. Verified via Admin SDK against bookbed-dev:

```
[1] Direct path check: properties/SEED_property_dev_01/units/SEED_unit_dev_01/bookings/SEED_booking_dev_01
  FOUND at canonical path. data:
   booking_reference: BB-SEED01
   status: cancelled
   guest_email: seed-guest@example.com
   property_id: SEED_property_dev_01
   unit_id: SEED_unit_dev_01
   owner_id: Zo01CJ3wymb0pplaYOyaZ2yGUWG2

[2] collectionGroup scan for any doc with id=SEED_booking_dev_01:
  FOUND at: properties/SEED_property_dev_01/units/SEED_unit_dev_01/bookings/SEED_booking_dev_01

[3] Seed property + unit existence:
  property SEED_property_dev_01: EXISTS
  unit SEED_unit_dev_01: EXISTS
```

The Sentry "Booking not found" event was **historical**: the cancel CF was invoked before the smoke-test seed created the booking, or after a different test had transiently deleted it. The booking is presently in place (status=cancelled, consistent with wave0 memory note "after #37 test"). **No reseed required.**

Side note: `scripts/seed-bookbed-dev.js` referenced in `memory/wave0-smoke-test-2026-05-18.md` is **not in the repo** (verified via `git log --all`). Memory is inaccurate — the script may have been local to that session's working tree only. The seed fixtures, however, did land in Firestore.

## Dev deploy verification (Task B-dev)

```
firebase deploy --only "$ONLY" --project bookbed-dev
✔  Deploy complete!     # 50 functions, two passes (added log-line after first pass)
```

The plan's suggested smoke trigger (deliberate 4xx) does NOT produce a Sentry event because `sentry.ts` has a `beforeSend` filter (added in commit `16224575`, since 6.71) that drops `HttpsError` events with client-fault codes including `not-found`, `invalid-argument`, `permission-denied`, `unauthenticated`, etc. So we extended `logInfo` at init to log the resolved env + raw env-var values, and read them via `firebase functions:log`.

Dev result, captured at cold-start of `handleStripeWebhook`:
```json
{
  "environment": "development",
  "gcpProject": null,
  "gcloudProject": "bookbed-dev",
  "severity": "INFO",
  "message": "Sentry initialized for Cloud Functions"
}
```

Three findings:
1. `GCP_PROJECT` is `null` on Gen 2 — confirms the old `process.env.GCP_PROJECT === "rab-booking-248fc"` check could **never** match on Gen 2, regardless of project. Old code routed dev to `"development"` only by accident (the false branch of the ternary).
2. `GCLOUD_PROJECT` is the only populated project identifier on Gen 2.
3. `detectEnvironment()` correctly returns `"development"`.

## Prod deploy (Task B-prod)

```
firebase deploy --only "$ONLY" --project rab-booking-248fc
✔  Deploy complete!     # 50 functions
```

Prod result, `handleStripeWebhook` cold-start log:
```json
{
  "environment": "production",
  "gcpProject": null,
  "gcloudProject": "rab-booking-248fc",
  "severity": "INFO",
  "message": "Sentry initialized for Cloud Functions"
}
```

Same null-`GCP_PROJECT` pattern on prod, confirming Gen 2 behavior is consistent across projects. `detectEnvironment()` resolves to `"production"`.

## Final state

- `main` is now at `4b56f8fb` (pushed to origin); contains the fix.
- `fix/sentry-env-detection` retained locally for traceability — safe to delete after this audit lands.
- `hotfix/widget-secrets-exfil` working tree restored intact: `firestore.rules` + `functions/src/email/sendOwnerEmail.ts` WIP plus 2 doc edits (`.claude/rules/cloud-functions.md` + `docs/CHANGELOG.md`) that arrived externally during this session — preserved as uncommitted.
- 6 dev-only orphan functions (`comebackReminder`, 4 Airbnb/Booking OAuth, `sendOwnerEmail`) left untouched — they live outside the `--only` list. Their fate is in `audit/11-cloudfunctions-inventory.md` §3 (P1 cleanup + DECIDE).

## Cleanup notes

- The `.claude/rules/cloud-functions.md` "Sentry env tag bug (audit 2026-05-18)" section is now obsolete and can be removed.
- `wave0-smoke-test-2026-05-18.md` memory entry incorrectly claims `scripts/seed-bookbed-dev.js` is in-repo (`git log --all` finds no commits). Update or delete that bullet; the seed data itself is intact in dev Firestore so no remediation needed.

## Stop

No further work in this session per plan.

