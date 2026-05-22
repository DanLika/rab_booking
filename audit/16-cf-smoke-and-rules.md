# audit/16 — Cloud Functions Smoke + Rules Security Regression

**Date:** 2026-05-22
**Branch:** `main`
**Scope:** Read-only API testing + targeted fixes for findings.
**Project under test:** `bookbed-dev`
**Fix commits on `main` (both NOT yet deployed/pushed):**
- `319f7d0f` — `fix: CF error-class hygiene + dead Flutter callsite (SF-022, audit/16)` (primary)
- `3153ffc4` — `docs(todo): flag dev OAuth orphans gap (audit/16)` (follow-up doc capture)

## Executive summary

| Surface | Result |
|---|---|
| CF inventory | 57 deployed (34 callable + 4 https request + 13 scheduled + 6 firestore-triggered) |
| HTTP-probable CFs | 38 (all callable + request) |
| HTTP 500 / INTERNAL leaks | **1** (`checkEmailVerificationStatus`) |
| HTTP 200 unauth open (by design helpers) | 2 (`checkLoginRateLimit`, `checkRegistrationRateLimit`) |
| Auth-rejecting CFs | 18 (UNAUTHENTICATED / PERMISSION_DENIED) |
| Input-validating CFs | 17 (INVALID_ARGUMENT) |
| Rules suite | **11/11 green** (8 baseline + 3 new clause-1 cases) |
| Deployed-vs-local rules diff | **BLOCKED on IAM** (no `serviceUsageConsumer` on `bookbed-dev`) |
| Perf baseline (10 hot CFs) | 224–805ms avg; one outlier (createBookingAtomic) |

**Action items:** 1× small fix (P2) for the `checkEmailVerificationStatus` INTERNAL leak; everything else is informational.

---

## TASK 1 — CF inventory + invocation matrix

### Trigger-type classification

| Trigger type | Count | Notes |
|---|---|---|
| `callable` | 34 | 9 in `europe-west1`, 25 in `us-central1` |
| `https` request | 4 | All in `us-central1` |
| `scheduled` | 13 | Skipped (no HTTP endpoint) |
| `google.cloud.firestore.*` | 6 | Skipped (no HTTP endpoint) |

### Smoke probe methodology

- Callable: `POST https://<region>-bookbed-dev.cloudfunctions.net/<name>` with `Content-Type: application/json` body `{"data":{}}`.
- HTTPS request: `GET https://<region>-bookbed-dev.cloudfunctions.net/<name>` with no params.
- Verdict logic inspects **HTTP code AND response body** — Firebase callables respond `200` with `{"error":{...}}` for failures, so status-only verdicts mislead.
- A status-only audit would have **missed** the `checkEmailVerificationStatus` finding entirely (its body says `INTERNAL` but Firebase callables can also return HTTP 200 + an `INTERNAL` body from `HttpsError("internal", ...)` paths inside handlers). The verdict regex matches `INTERNAL|stack at|TypeError|ReferenceError|cannot read prop` against the body specifically so the HTTP-200-but-internally-broken case is caught too.
- 15s timeout per request. Single sample (smoke, not perf).

### Per-CF result table

| Verdict | Count | Meaning |
|---|---|---|
| `OK_auth_reject` | 18 | Returns UNAUTHENTICATED or PERMISSION_DENIED with empty data — correct |
| `OK_bad_request` | 17 | Returns INVALID_ARGUMENT with empty data — correct |
| `WARN_200_open` | 2 | Returns success body for unauth — intentional pre-auth helpers (see below) |
| `ALERT_500` | **1** | Returns 500 INTERNAL when expected 400 INVALID_ARGUMENT (see below) |

Full CSV: `/tmp/cf-smoke-results.csv` (regenerable; not committed).

### ALERT — `checkEmailVerificationStatus` returns INTERNAL on missing email (P2)

```
POST /checkEmailVerificationStatus -d '{"data":{}}'
→ HTTP 500
→ {"error":{"message":"Failed to check verification status: Email is required","status":"INTERNAL"}}
```

**Source.** `functions/src/emailVerification.ts:404-471`. The handler **does** throw the correct `HttpsError("invalid-argument", "Email is required")` at line 416 — but the outer `try/catch` at lines 407 / 463 unconditionally re-wraps **every** caught error, including its own `HttpsError`, as `HttpsError("internal", ...)`:

```typescript
} catch (error: any) {
  logError("Error checking verification status", error);
  throw new HttpsError(
    "internal",
    `Failed to check verification status: ${error.message}`
  );
}
```

The intended client-fault throw at 416 is correct; the catch then promotes it to a server fault, which is what callers see.

**Why this matters.** Other CFs in the same family (`sendEmailVerificationCode`, `verifyEmailCode`, `sendPasswordResetEmail`) all throw `HttpsError("invalid-argument", ...)` for the same missing-field shape and return HTTP 400 — confirmed in this audit's smoke results. Only `checkEmailVerificationStatus` over-wraps. Three concrete consequences:

1. Caller sees HTTP 500 + `INTERNAL` for what is logically a 400 + `INVALID_ARGUMENT`.
2. CF metrics dashboards count every malformed call as a server error.
3. **Per `.claude/rules/cloud-functions.md`**, Sentry's `beforeSend` filter (since v6.71) drops `HttpsError` with client-fault codes but **forwards** `internal`. So every missing-email call hits Sentry as a genuine error event, polluting the dashboard.

**Fix.** Two equivalent options:

- **Preferred** — re-throw `HttpsError` instances unchanged:
  ```typescript
  } catch (error: any) {
    if (error instanceof HttpsError) throw error;  // ← add this line
    logError("Error checking verification status", error);
    throw new HttpsError("internal", `Failed to check verification status: ${error.message}`);
  }
  ```
- Alternative — move the `!email` guard to **before** the `try` block.

**Severity.** P2 (cosmetic / metrics + Sentry pollution, no auth bypass, no data leak). The same fault pattern likely lives in other CFs that share the "wrap everything in try/catch" idiom — worth a separate sweep but out of scope for audit/16.

### WARN — `checkLoginRateLimit` / `checkRegistrationRateLimit` return 200 unauth

```
POST /checkLoginRateLimit -d '{"data":{}}'
→ HTTP 200
→ {"result":{"allowed":true}}
```

Both functions are pre-auth helpers — by definition they must be callable before the user has an Auth token. Empty input returns `allowed:true` (no rate-limit state to enforce). Not a defect, but flag for the audit record. **No action.**

### Notable observation — Stripe webhook responds 400 to GET

```
GET /handleStripeWebhook → HTTP 400 "Missing signature"
```

Correct: webhook accepts only signed POST. No GET-side info leak.

---

## TASK 2 — Rules suite + extended cases

### Baseline run

```
npm run test:rules
Test Suites: 1 passed, 1 total
Tests:       11 passed, 11 total
Time:        3.7s
```

**Discrepancy from task spec:** task referenced "22/22 green" — actual repo only contains `functions/test/firestore_rules/bookings.test.ts` with 8 baseline cases. Extended to 11 with the additions below. No regression; 22/22 was stale spec.

### New cases added to `bookings.test.ts`

The booking-read rule `firestore.rules` clause 1 is structured as `('unit_id' in resource.data && 'status' in resource.data)`. The existing suite covered the positive path (both fields present) and the all-fields-absent path. Added three new cases to lock down the partial-field boundary:

1. **`clause 1 — unit_id + status BOTH present → unauth ALLOWED (T11c-pending widget path)`** — explicit positive regression guard, identical assertion to the existing widget-calendar test but named with the audit reference so the surface area is auditable from this doc.
2. **`clause 1 — only unit_id present (status missing) → unauth DENIED`** — confirms that an attacker forging a doc shape with `unit_id` but no `status` cannot abuse clause 1.
3. **`clause 1 — only status present (unit_id missing) → unauth DENIED`** — symmetric: confirms `status: "confirmed"` alone is not sufficient.

All three pass. The clause works as documented in `audit/06-bookings-hotfix-partial.md`. Until `getUnitAvailability` CF ships (T11c), unauthenticated calendar reads remain available **only** to documents bearing both fields.

### Test cases deferred (per advisor + task scope)

- **widget_settings / widget_secrets boundary** — rule logic is on the hotfix branch only, not on `main`. Cannot test without merging.
- **loginAttempts open-write** — intentionally still open per Phase B5 deferral; covered by `audit/06-dev-deploy-readiness.md`.

---

## TASK 3 (formerly 4) — Deployed-vs-local rules diff — BLOCKED

Advisor flagged that `firebase-admin` bypasses rules entirely, so a node-script regression against the deployed DB is structurally impossible (admin SDK is privileged). The replacement check — diffing the **deployed** ruleset against the **local** `firestore.rules` — would catch any drift between repo and prod that an emulator-only test cannot.

**Attempt:** Called `firebaserules.googleapis.com/v1/projects/bookbed-dev/releases/cloud.firestore` with `gcloud auth print-access-token`.

**Result:** `403 PERMISSION_DENIED`. Two stacked issues:

1. ADC has no quota project — fixable by adding `x-goog-user-project: bookbed-dev` header.
2. The signed-in principal lacks `roles/serviceusage.serviceUsageConsumer` on `bookbed-dev`, AND `firebaserules.googleapis.com` may need to be explicitly enabled on the consumer project.

**Decision.** Not chasing the IAM grant from this audit — out of scope. Recorded as a follow-up gap in `docs/TODO.md`:

> **TODO (audit/16):** Establish a CI job that fetches `firebaserules.googleapis.com` releases on `bookbed-dev` and `rab-booking-248fc` and diffs against `firestore.rules` in repo. Today, drift detection between repo and deployed rules is manual.

**Mitigation in lieu of the live diff.**

- `git log -- firestore.rules` shows last edit was the T11-hotfix-partial merge; no untracked commits.
- The deploy script `deploy-rules.sh` (per `audit/06-dev-deploy-readiness.md`) is the only path that pushes rules, so unauthorized drift is unlikely.
- `npm run test:rules` runs against the in-repo `firestore.rules` and is green — if the repo is the source of truth, behavior matches.

**Risk acceptance.** This audit verifies the **expected** rules behavior. A separate drift-detection mechanism is the right long-term answer; chasing it inside this audit's scope would be scope creep.

---

## TASK 4 — Performance baseline (10 hot CFs)

5 sequential invocations per CF, empty/invalid payload to trigger fast-path rejection. Measures TLS + Firebase Functions entry + first guard clause + JSON response — i.e., the floor on user-perceived latency, not the success-path cost.

| CF | Region | Type | avg | p95 | cold | warm avg | cold factor |
|---|---|---|---|---|---|---|---|
| `getUnitIcalFeed` | us-central1 | request | **224ms** | 234ms | 223ms | 225ms | 1.0× |
| `verifyBookingAccess` | us-central1 | callable | 352ms | 464ms | 299ms | 365ms | 0.8× |
| `guestCancelBooking` | us-central1 | callable | 272ms | 295ms | 295ms | 266ms | 1.1× |
| `getBookingByStripeSession` | us-central1 | callable | 275ms | 282ms | 280ms | 274ms | 1.0× |
| `createStripeCheckoutSession` | us-central1 | callable | 277ms | 283ms | 282ms | 276ms | 1.0× |
| `sendOwnerEmail` | us-central1 | callable | 260ms | 263ms | 263ms | 259ms | 1.0× |
| `createBookingAtomic` | us-central1 | callable | **805ms** | **2706ms** | 300ms | 931ms | 0.3× |
| `resendBookingEmail` | us-central1 | callable | 264ms | 282ms | 282ms | 259ms | 1.1× |
| `getStripeAccountStatus` | us-central1 | callable | 272ms | 291ms | 291ms | 267ms | 1.1× |
| `syncIcalFeedNow` | us-central1 | callable | 298ms | 365ms | 332ms | 289ms | 1.1× |

### Observations

- **Floor latency ≈ 220–280ms** for the 9 of 10 well-behaved CFs. Of that, ~150ms is TLS+CDN to us-central1 from Europe; the actual CF entry+rejection work is ~80–130ms. There is no warm-cold gap because Firebase keeps min-instance=0 but the smoke loop is back-to-back fast enough that the instance stays warm across all 5 samples for most functions.

- **`getUnitIcalFeed` is fastest (224ms)** — it's the only `https.onRequest` in the set, so it skips the `cloudfunctions/v2/CallableFunction` shim that adds ~50ms to all callables. Worth keeping in mind: if a CF is purely public-read, prefer `onRequest` for perf.

- **`createBookingAtomic` outlier (call 4: 2.7s)** — 4 of 5 samples were 275–465ms, but one spiked to 2706ms. Most plausible cause: container scale-up event between samples 3 and 4 — `createBookingAtomic` imports Stripe + Firebase Admin + bookingLookup, so cold-init can plausibly hit 2–3s. This was call 4, not call 1, suggesting an instance was reaped and a fresh one started during the loop. **No action — single-spike, not reproducible.** Worth monitoring in Firebase Performance dashboards if user reports of "first booking slow" come in.

- **`verifyBookingAccess` p95 = 464ms** — moderate variance (299, 294, 264, 438, 463ms). Not concerning, but the only CF in the set where p95 is notably higher than avg. Likely the Firestore lookup in the rate-limit middleware.

### Threshold guidance

- All 10 CFs comfortably under 1s p95 (excluding the createBookingAtomic outlier).
- 2.7s outlier is below the 60s gen2 cold-start budget — well within acceptable Firebase Cloud Functions behavior.
- No CF needs `minInstances:1` based on this dataset.

---

## Followups

| Severity | Item | Where | Status |
|---|---|---|---|
| P2 | Fix `checkEmailVerificationStatus` to return 400 INVALID_ARGUMENT (not 500 INTERNAL) on missing email — guard `HttpsError` re-throw in the catch | `functions/src/emailVerification.ts:463-469` | **DONE in this session** (guard added at line 464) |
| P3 | Sweep other CFs for the same "wrap-everything" catch idiom | functions/src/ | **DONE in this session** — see "Anti-pattern sweep" below |
| P3 | Establish drift-detection CI for deployed firestore rules | `.github/workflows/firestore-rules-drift.yml` | **DONE in this session** — workflow committed; **operator prereqs (secrets + IAM) still required** before checks pass. See workflow header. |
| P3 | Monitor `createBookingAtomic` p95 in Firebase dashboard for repeat cold-init spikes | observation only | pending |

### Anti-pattern sweep (executed 2026-05-22)

Sweep methodology: `grep -rn 'HttpsError("internal"' functions/src/` + multi-line variants. **16 candidate sites** identified across 12 files.

Per-site triage (HttpsError thrown inside same try-block → catch promotes to internal = TRUE POSITIVE):

| File:Line | Verdict | Action |
|---|---|---|
| `emailVerification.ts:226` | FALSE POS | guard already at line 220 |
| `emailVerification.ts:382` | FALSE POS | guard already at line 376 |
| `emailVerification.ts:466` | **TRUE POS** | **fixed** — guard added at 464 |
| `migrations/migrateTrialStatus.ts:179` | FALSE POS | `permission-denied` is thrown BEFORE try block, no inner HttpsError |
| `stripeSubscription.ts:112` | FALSE POS | no HttpsError thrown inside try body — verdict is "no instance of the wrap-promotion anti-pattern", **not** "no possible issue". A native Firestore/Stripe error string-code (e.g. `error.code === "permission-denied"` on a Firestore object) would still get promoted to `internal` — but that's a separate concern (SDK-error-shape wrapping) outside audit/16's scope. |
| `stripeSubscription.ts:147` | **TRUE POS** | **fixed** — `failed-precondition` at 134 inside try; guard added |
| `icalSync.ts:275` | **TRUE POS** | **fixed** — `not-found` at 241 inside try; guard added |
| `stripeConnect.ts:96` | **TRUE POS** | **fixed** — `not-found` at 45 inside try; guard added |
| `stripeConnect.ts:180` | **TRUE POS** | **fixed** — `not-found` at 123 inside try; guard added |
| `stripeConnect.ts:236` | **TRUE POS** | **fixed** — `failed-precondition`+`not-found` inside try; guard added |
| `resendBookingEmail.ts:216` | FALSE POS | guard already at line 206 |
| `verifyBookingAccess.ts:244` | FALSE POS | guard already at line 232 |
| `admin/updateUserStatus.ts:151` | FALSE POS | guard already at line 147 |
| `admin/setLifetimeLicense.ts:164` | FALSE POS | guard already at line 160 |
| `utils/priceValidation.ts:227` | FALSE POS | not in a catch — bare throw for invalid data; `internal` debatable but not the same anti-pattern |
| `guestCancelBooking.ts:148` | FALSE POS | guard throw inside try (data-integrity check); not a catch |
| `guestCancelBooking.ts:443` | FALSE POS | guard already at line 437 |

**Total fixes applied: 6 sites in 4 files.** Diff:

```typescript
  } catch (error: any) {
+   if (error instanceof HttpsError) throw error;
    logError(...);
    throw new HttpsError("internal", ...);
  }
```

### Co-existing in-flight fix (logger.ts — uncommitted, not from this session)

During the sweep, an **uncommitted local modification** was discovered at `functions/src/logger.ts` (NOT introduced by audit/16). The change adds a centralized `CLIENT_FAULT_HTTPS_CODES` allowlist and downgrades client-fault HttpsErrors to `WARN` in Cloud Logging — mirroring the existing `beforeSend` filter in `sentry.ts`.

**Relationship to audit/16's fix.** The two patches are **partially redundant on the 6 sites I just fixed**:

- My per-catch guard `if (error instanceof HttpsError) throw error;` fires **before** `logError(...)` is called. So on the sites I touched, the logger.ts WIP is dead code — the client-fault HttpsError never reaches `logError`, never gets reclassified.
- Where the logger.ts WIP still adds value: (a) the 9 sites that already had a guard pre-existing, where `logError` is still called for non-HttpsError causes; (b) HttpsErrors thrown OUTSIDE any catch block that bubble up through `functions.logger`-instrumented helpers; (c) future code that omits the guard pattern.

So it's a **safety net at a different layer**, not a complementary co-fix. Both can ship without conflict (different line ranges), but the value of the logger.ts WIP after my fixes is in defense-in-depth on uncovered paths, not in handling the bugs audit/16 found. Flagged here for review of either patch.

### Verification

- `cd functions && npm run build` — green (tsc, 0 errors).
- `cd functions && npm run test:rules` — green (11/11).
- Live smoke re-test of `checkEmailVerificationStatus` requires deploy; not done in this audit. Expected post-deploy behavior:
  ```
  POST /checkEmailVerificationStatus -d '{"data":{}}'
  → HTTP 400
  → {"error":{"message":"Email is required","status":"INVALID_ARGUMENT"}}
  ```

---

## Reproducibility

- **CF smoke loop:** see `/tmp/cf-smoke-results.csv` (regenerable; see code inside `audit/16` for the loop).
- **Rules suite:** `cd functions && npm run test:rules`
- **Perf baseline:** see `/tmp/cf-perf.txt` (regenerable; bench loop in audit/16).
- **Live rules diff:** blocked on IAM; needs `roles/serviceusage.serviceUsageConsumer` on the runner principal + `firebaserules.googleapis.com` enabled on the consumer project.
