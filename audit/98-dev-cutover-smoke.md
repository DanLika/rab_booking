# audit/98 — bookbed-dev cutover dry-run smoke (post-PR #606)

**Scope:** read-only + scoped seed/cleanup smoke against `bookbed-dev`, covering
every fix that lands in the upcoming PROD cutover (audit/90 runbook).
**Branch:** `audit/98-dev-cutover-smoke` (worktree `/tmp/bb-cutover-smoke`).
**Date:** 2026-05-30.
**Commit basis:** `5e775fd1` (HEAD `main` at run time); PR #606 (`bcf689c3` —
SF-077 / FLUTTER-7E) is the last fix in scope.
**Probe accounts:**
- Owner `bookbed-test@bookbed.io` (UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`) — pre-existing test acct from `memory/test-account.md`.
- Throwaway foreign `bookbed-foreign-1780149058@example.test` (UID `WeaNlaj9pZf7ZvbgDrymMuDCqu82`) — created at smoke start, deleted at smoke end.

**Probe-type legend:**
- `REST/anon` — Firestore / Storage / `*.run.app` HTTP from non-authenticated client.
- `REST/id-token` — same with `Authorization: Bearer <Firebase ID token>` (test or foreign UID).
- `Admin SDK` — `firebase-admin` with ADC. Used **only** for seed + cleanup, never for "deny" assertions (would bypass rules → vacuous PASS, per advisor §1).

---

## 1. Matrix

| # | Fix (SF / F-* / audit) | Sub-case | Probe | Expected | HTTP / observed | Verdict |
|---|---|---|---|---|---|---|
| 1a | F-90-01 / SF-050 | OPTIONS preflight `recordLoginFailure`, `Origin: https://bookbed-owner-dev.web.app` + ACR-M + ACR-H | REST/anon | 204 + ACAO echoed | `HTTP/2 204` + `access-control-allow-origin: https://bookbed-owner-dev.web.app` | ✅ PASS |
| 1b | F-90-01 / SF-050 | OPTIONS preflight `recordLoginFailure`, `Origin: https://evil.test` + ACR-M + ACR-H | REST/anon | 204 **no** ACAO | `HTTP/2 204` + `NO-ACAO` | ✅ PASS |
| 1c | F-90-01 / SF-050 | `clearLoginAttempts` unauthenticated POST | REST/anon | `unauthenticated` | `HTTP 401` `{status:UNAUTHENTICATED, message:"must be authenticated"}` | ✅ PASS |
| 1c-bis | F-90-01 / SF-050 | `clearLoginAttempts` with **foreign** token, target test-acct email | REST/id-token (foreign) | `permission-denied` | `HTTP 403` `{status:PERMISSION_DENIED, message:"Can only clear attempts for your own email."}` | ✅ PASS |
| 1d | F-90-01 / SF-050 | `recordLoginFailure` IP rate-limit (same email, back-to-back) | REST/anon | call 1 → 200; call 2 within 60s → 429 | call 1 `HTTP 200 {attemptCount:1,remaining:4}`; call 2 `HTTP 429 {status:RESOURCE_EXHAUSTED}` | ✅ PASS |
| 1e | F-90-01 / SF-050 | 5× `recordLoginFailure` spaced 70s; then `getLoginLockoutStatus` | REST/anon | attemptCount→5, `locked:true`, `lockedUntilMs` set | log: `attemptCount:1→2→3→4→5`, call#5 `{locked:true,attemptCount:5,lockedUntilMs:1780150422870,remainingAttempts:0}`; status read confirms | ✅ PASS |
| 1f | SF-050 PROD-IAM watch (memory `sf050-prod-iam-gap`) | DEV `recordLoginFailure` `allUsers/invoker` reachable from anon | REST/anon | 200 on first hit | call#1 `HTTP 200` (no 401/403) | ✅ PASS (DEV IAM intact) |
| 2a | F-86-01 / PR #565 | OPTIONS `createStripeCheckoutSession`, evil origin | REST/anon | NO ACAO | `204 NO-ACAO` | ✅ PASS |
| 2b | F-86-01 | OPTIONS `createStripeCheckoutSession`, dev + prod allowed origins | REST/anon | ACAO echoed | `204 + ACAO https://bookbed-owner-dev.web.app` / `+ ACAO https://app.bookbed.io` | ✅ PASS |
| 2c-h | F-86-01 | Same matrix for `createBookingAtomic`, `guestCancelBooking`, `getUnitAvailability` | REST/anon | evil → NO ACAO; allowed → ACAO | 6 of 6 evil = NO-ACAO; 6 of 6 allowed = echoed | ✅ PASS |
| 3a | SF-067 / SEC-001 | Owner JPEG upload to `users/{TEST_UID}/profile/*.jpg` | REST/id-token (test) | 200 | `HTTP 200 {name:"users/GILVItIVP5R8WXfnMmyMo1ykhUm2/profile/audit98-…jpg"}` | ✅ PASS |
| 3b | SF-067 / SEC-001 | Anon upload to same path | REST/anon | deny | `HTTP 403 {code:403,message:"Permission denied."}` | ✅ PASS |
| 3c | SF-067 / SEC-001 | Foreign-token upload to test-uid path | REST/id-token (foreign) | deny | `HTTP 403` | ✅ PASS |
| 3d | **SF-067 / F-91-02** | Owner DELETE of own file (validates SF-067 split + IAM `datastore.viewer`) | REST/id-token (test) | 204 | `HTTP 204` | ✅ PASS |
| 3e | SF-067 | Foreign-token DELETE of test-uid file | REST/id-token (foreign) | 403 | `HTTP 403` | ✅ PASS |
| 3f | SF-067 | Anon DELETE | REST/anon | 401/403 | `HTTP 403` (Firebase Storage collapses unauthenticated + permission-denied into 403) | ✅ PASS (semantic) |
| 3g | SEC-002 | SVG upload (`image/svg+xml`) | REST/id-token (test) | reject (contentType regex `image/(jpeg\|png\|webp\|gif\|heic\|heif)`) | `HTTP 403` | ✅ PASS |
| 3h | SEC-002 | 11 MiB JPEG upload (above 10 MB cap on `users/**`) | REST/id-token (test) | reject | `HTTP 403` | ✅ PASS |
| 3i | SF-025 + SF-067 | Anon GET `ical-exports/{any}/{any}/calendar.ics?alt=media` | REST/anon | deny | `HTTP 403` | ✅ PASS |
| 4a | F-94-02-UPDATE / SF-068 | PATCH `properties/{pid}` `subdomain="evil"` (test-acct owns pid) | REST/id-token (test) | deny (affectedKeys) | `HTTP 403 PERMISSION_DENIED` | ✅ PASS |
| 4b | F-94-02-UPDATE / SF-068 | PATCH `properties/{pid}` `owner_id="evil-owner"` | REST/id-token (test) | deny | `HTTP 403` | ✅ PASS |
| 4c | F-94-02-UPDATE / SF-068 | PATCH `properties/{pid}` `created_at=now` | REST/id-token (test) | deny | `HTTP 403` | ✅ PASS |
| 4d | sanity | PATCH `properties/{pid}` `name="renamed"` (benign) | REST/id-token (test) | allow | `HTTP 200` | ✅ PASS |
| 4e | F-94-04 / SF-068 | PATCH `properties/{pid}/widget_settings/{unitId}` `ical_cache_content="INJECTED"` | REST/id-token (test) | deny | `HTTP 403` | ✅ PASS |
| 4f | F-94-04 / SF-068 | PATCH same doc `ical_cache_generated_at=2099-…` | REST/id-token (test) | deny | `HTTP 403` | ✅ PASS |
| 4g | sanity | PATCH same doc `some_benign_field="new-val"` | REST/id-token (test) | allow | `HTTP 200` | ✅ PASS |
| 4h | F-94-03 / SF-068 | PATCH `properties/{pid}/ical_feeds/{feedId}` `sync_count=999` | REST/id-token (test) | deny | `HTTP 403` | ✅ PASS |
| 4i | F-94-03 / SF-068 | PATCH same doc `event_count=999` | REST/id-token (test) | deny | `HTTP 403` | ✅ PASS |
| 4j | F-94-03 / SF-068 | PATCH same doc `last_synced=2099-…` | REST/id-token (test) | deny | `HTTP 403` | ✅ PASS |
| 4k | sanity | PATCH same doc `url="https://benign.test/ical"` | REST/id-token (test) | allow | `HTTP 200` | ✅ PASS |
| 4l | **F-98-01 NEW** | PATCH **top-level** `ical_feeds/{topFeedId}` `sync_count=999` (deprecated legacy path, rule lines 507-516 lacks `affectedKeys` deny) | REST/id-token (test) | should deny (sibling of F-94-03) | `HTTP 200` — write succeeds | 🚨 **FAIL — see §3.1** |
| 4m | F-95 platform_connections dead-code | PATCH `platform_connections/{any}` arbitrary | REST/id-token (test) | deny | `HTTP 403 PERMISSION_DENIED` | ✅ PASS |
| 5a | F-95-01 | `scheduledIcalSync` scheduler `timeZone` | gcloud describe (deployed state) | `Europe/Zagreb` per `icalSync.ts:267` | `UTC` | ⚠️ INFO — see §3.2 |
| 5b | F-95-02 | `autoCancelExpiredBookings` scheduler `timeZone` | gcloud describe | `Europe/Zagreb` per `bookingManagement.ts:96` | `UTC` | ⚠️ INFO — see §3.2 |
| 5c | F-95 control | `autoCompleteCheckedOutBookings` scheduler `timeZone` | gcloud describe | `Europe/Zagreb` | `Europe/Zagreb` | ✅ PASS (control) |
| 5d | F-95 platform_connections | direct write `platform_connections/{any}` | REST/id-token (test) | deny | covered by 4m → 403 | ✅ PASS |
| 6a | SF-069 / SF-076 (PR #581) | `setPropertySubdomain({pid, subdomain:free})` on owned property | REST/id-token (test) | 200 + Firestore `subdomain` updated by CF | `HTTP 200 {result:{success:true,subdomain:"a98-…"}}` | ✅ PASS |
| 6b | SF-069 reserved guard | `setPropertySubdomain` with `subdomain="admin"` | REST/id-token (test) | reject reserved | `HTTP 400 {status:INVALID_ARGUMENT, message:"This subdomain is reserved"}` | ✅ PASS |
| 6c | SF-069 uniqueness guard | `setPropertySubdomain` on a **second** owned property with the same subdomain | REST/id-token (test) | reject taken | `HTTP 409 {status:ALREADY_EXISTS, message:"This subdomain is already taken"}` | ✅ PASS |
| 6d | F-94-02-UPDATE | Direct REST PATCH `properties/{pid}` `subdomain="evil-direct-…"` | REST/id-token (test) | deny | `HTTP 403 PERMISSION_DENIED` | ✅ PASS |
| 6e | **F-94-02-CREATE — known gap (audit/96 §1 explicit trade-off)** | Direct REST CREATE `properties/{new}` with `subdomain="airbnb-{ts}"` + owner_id + created_at in same write | REST/id-token (test) | rule format-validates but does NOT enforce reserved list / uniqueness — squat still possible if attacker bypasses lib | `HTTP 200` doc created with `subdomain=airbnb-{ts}` | ⚠️ KNOWN GAP — see §3.3 |
| 7a | SF-077 / FLUTTER-7E (PR #606) | Refless seed `pending→confirmed+approved_at` at canonical 4-level path `properties/{pid}/units/{uid}/bookings/{bid}` | Admin SDK seed + Admin SDK status flip | `booking_reference` auto-healed, `emails_sent.approval` populated, no 4× retry, no Sentry | log: `[onStatusChange] Restored missing booking_reference (approval)` + `[EmailRetry] attempt 1/4` (single); doc `booking_reference="BK-AUDIT98-7E-V"`, `emails_sent.approval.provider_id=01845a05-…` | ✅ PASS |
| 7b | SF-077 | Refless seed `pending→cancelled+rejection_reason` (rejection branch — NB: status flag is `cancelled`, not `rejected`, per `bookingManagement.ts:482`) | Admin SDK | auto-heal + `emails_sent.rejection` | log: `Restored missing booking_reference (rejection)` + 1/4 retry attempt; doc `emails_sent.rejection.provider_id=10e94295-…` | ✅ PASS |
| 7c | SF-077 / audit/34 §5 idempotency marker | Pending-approval seed (`require_owner_approval=true`, `payment_method=bank_transfer`) | Admin SDK | `emails_sent.initial_trigger_processed` written by `onBookingCreated` | doc `emails_sent.initial_trigger_processed.{booking_id, email}` populated | ✅ PASS |
| 7d | SF-077 retry-storm guard | Both branches above — CF logs | `gcloud functions logs read` | exactly one `attempt 1/4`; no further retries; no error severity | confirmed for both 7a + 7b | ✅ PASS |
| 8a | SF-063 / F-92-01 | `GET /<pid>/<uid>/.ics` (empty token after `.ics` strip) on iCal-export-enabled unit with empty `widget_settings.ical_export_token` legacy + missing `widget_secrets.ical_export_token` | REST/anon | 403 | `HTTP 403 "Invalid token"` | ✅ PASS |
| 8b | SF-063 | Same with URL-encoded `.ics` (`%2eics`) | REST/anon | 403 | `HTTP 403 "Invalid token"` | ✅ PASS |
| 8c | SF-063 | HEAD `/<pid>/<uid>/.ics` | REST/anon | 403 | `HTTP 403` | ✅ PASS |
| 8d | SF-063 sanity | GET `/<pid>/<uid>/wrong-token.ics` | REST/anon | 403 | `HTTP 403 "Invalid token"` | ✅ PASS |
| 8e | SF-063 happy-path | GET `/<pid>/<uid>/<valid>.ics` after seeding `widget_settings.{ical_export_enabled,ical_export_token}` (legacy plaintext path) | REST/anon | 200 + RFC 5545 body | `HTTP 200`, body starts `BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//BookBed//…`, includes `X-WR-TIMEZONE:Europe/Zagreb`, 1075 bytes | ✅ PASS |
| 9a | T11c (commit `ab6bdb3d`) | Anon `runQuery` CG `bookings` WHERE `unit_id+status` | REST/anon | 403 | `HTTP 403 PERMISSION_DENIED` | ✅ PASS |
| 9b | T11c | Anon `runQuery` CG `bookings` WHERE `owner_id` | REST/anon | 403 | `HTTP 403` | ✅ PASS |
| 9c | T11c availability callable | Anon `getUnitAvailability({propertyId,unitId,startDate,endDate})` | REST/anon | 200 + `windows[]` | `HTTP 200`, `result.windows.length=2` (matches seed booking count), `source:"booking"` | ✅ PASS |

---

## 2. Setup map

### 2.1 CF region split (smoke-touched only)

| CF | Region | Notes |
|----|--------|-------|
| `recordLoginFailure`, `getLoginLockoutStatus`, `clearLoginAttempts` | `europe-west1` | F-90-01 IAM `allUsers/invoker` intact on DEV (per 1f). |
| `createStripeCheckoutSession`, `createBookingAtomic`, `guestCancelBooking`, `setPropertySubdomain`, `getUnitIcalFeed`, `syncIcalFeedNow`, `updateBookingTokenExpiration` | `us-central1` | Legacy region per `cf-region-split-us-eu` memory. |
| `getUnitAvailability` | `europe-west1` | T11c migration target. |
| `onBookingStatusChange`, `onBookingCreated` | `us-central1` | Firestore triggers; canonical path `properties/{pid}/units/{uid}/bookings/{bid}`. |

### 2.2 Schedulers

```
firebase-schedule-scheduledIcalSync-europe-west1            TZ=UTC                schedule="every 15 minutes"
firebase-schedule-autoCancelExpiredBookings-us-central1     TZ=UTC                schedule="every 24 hours"
firebase-schedule-autoCompleteCheckedOutBookings-us-central1 TZ=Europe/Zagreb     schedule="0 2 * * *"
```

See §3.2 for the TZ explanation.

### 2.3 Seed footprint (all cleaned in §4)

| Path | Reason |
|------|--------|
| `properties/audit98-prop-1780149497130` (+ `units/{u}/{widget_settings,ical_feeds,bookings/*}`) | Cases 4, 7, 8, 9 |
| `properties/audit98-prop2-1780149659993` | Case 6 squat target |
| `properties/audit98-rest-create-1780149664` | Case 6e known-gap proof |
| `ical_feeds/{audit98-prop_audit98-feed-…}` | Case 4l legacy-path probe |
| `loginAttempts/{docId(lockout-target-1780149212@example.test)}` | Case 1e lockout target |
| Auth user `bookbed-foreign-…@example.test` (`WeaNlaj9pZf7ZvbgDrymMuDCqu82`) | Throwaway foreign UID |
| `users/{TEST_UID}/profile/audit98-*.jpg` Storage objects | Cases 3a/3e (deleted as-we-went + post-cleanup sweep) |

---

## 3. Net-new findings + classification adjustments

### 3.1 F-98-01 — top-level `ical_feeds/{feedId}` direct write to CF-managed fields **NOT denied** (LOW)

`firestore.rules:507-516` (deprecated legacy `match /ical_feeds/{feedId}` block) allows
`update` purely on property-ownership; **no `affectedKeys` `hasAny` deny** mirrors
the subcollection rule at `firestore.rules:336-339`. Smoke 4l confirms an owner-token
REST PATCH `sync_count=999` against a top-level `ical_feeds` doc lands `HTTP 200`.

Surface bound:
- `create` is `if false` (line 512) → no new top-level feeds can be added by clients.
- Existing top-level feeds must be inventoried. On `bookbed-dev` the smoke ran with one
  seeded top-level doc (`audit98-prop-…_audit98-feed-…`) that the cleanup removes.
- A non-smoke inventory of pre-existing top-level `ical_feeds` docs on PROD is
  the gating evidence for severity. If the legacy collection is empty the
  exposure is theoretical only; if any doc with `sync_count/event_count/last_synced`
  is present, an attacker that obtains the property's owner UID can tamper
  dashboard stats and freeze scheduled sync (`icalSync.ts:296-311`).

Fix template (rules-only, parallel to SF-068):

```diff
 match /ical_feeds/{feedId} {
   allow read: …;
   allow create: if false;
-  allow update, delete: if isAuthenticated() &&
+  allow delete: if isAuthenticated() &&
     ('property_id' in resource.data) &&
     get(/databases/$(database)/documents/properties/$(resource.data.property_id)).data.owner_id == request.auth.uid;
+  allow update: if isAuthenticated() &&
+    ('property_id' in resource.data) &&
+    get(/databases/$(database)/documents/properties/$(resource.data.property_id)).data.owner_id == request.auth.uid &&
+    !request.resource.data.diff(resource.data).affectedKeys()
+        .hasAny(['sync_count', 'event_count', 'last_synced']);
 }
```

Suggested SF entry: SF-070 (next free per `docs/SECURITY_FIXES.md`; reconcile with
the SF-062 collision flag in memory `sf-062-pr567-naming-conflict` first — verify
SF-070 is also unclaimed before bumping).

### 3.2 F-95-01 / F-95-02 deployed scheduler `timeZone` = `UTC`, not `Europe/Zagreb` (INFO, not FAIL)

Source files have `timeZone: "Europe/Zagreb"` (`icalSync.ts:267`, `bookingManagement.ts:96`).
Deployed `gcloud functions describe` + `gcloud scheduler jobs describe` show `UTC`.
Both CFs were redeployed `2026-05-30T13:59:51 / :52 UTC` (PR #580 / `27e71da5`).

Per audit/87 §2 the schedules are **interval-based** (`every 15 minutes`, `every 24 hours`).
Cloud Scheduler ignores `timeZone` on interval schedules — there is no anchor
point for it to apply against. The source-side change is cosmetic for now and
makes the spec self-documenting; it has zero runtime effect until/unless the
schedule is converted to a cron expression (which `autoCompleteCheckedOutBookings`
already is, hence its TZ taking effect — control case 5c).

Implication: PROD cutover for these two CFs can ship as-is; no further deploy
action is required to make the TZ line "take effect" on intervals.

### 3.3 F-94-02-CREATE — direct-REST subdomain squat **still reachable** (KNOWN GAP, documented in audit/96)

Smoke 6e confirmed: an authenticated owner can `PATCH /v1/projects/bookbed-dev/databases/(default)/documents/properties/{newId}`
with `subdomain="airbnb-{ts}"` (or any format-valid value, including bare
`"airbnb"` / `"marriott"` / etc.) in the **initial** field set, bypassing the
lib-side 2-phase create that PR #581 (SF-069) added. Rules at lines 213-220
format-validate but do **not** consult the reserved-subdomain list or the
uniqueness index — those checks live exclusively in `setPropertySubdomain`
(`subdomainService.ts`).

This trade-off is documented in `audit/96-f94-02-create-fix.md` §1 ("F-94-02-CREATE
was deferred there because the rule cannot deny initial doc writes containing
the subdomain field without breaking the entire create flow"). Closing it at
the rules layer requires either:
- a Cloud Function `onDocumentCreated` trigger that revalidates `subdomain` on
  properties create and overwrites/clears on reserved/taken (eventually consistent;
  small squat window remains), or
- splitting create into two rule clauses: `subdomain == null` allowed, `subdomain != null`
  denied — and requiring the lib's 2-phase reserve to be the only allowed path.

Not a regression. Surface the matrix row to make the PROD cutover briefing
aware that the affordance still exists for adversarial owners with a Firebase
API key; PROD-side guidance: keep monitoring `properties` for new docs with
suspicious subdomains until a rules-layer close lands.

---

## 4. Cleanup

All seed + probe artefacts deleted at the end of the run (see §6 for the
Admin-SDK helper code). Verifiable post-cleanup state:

```
properties/audit98-prop-1780149497130            → absent
properties/audit98-prop2-1780149659993           → absent
properties/audit98-rest-create-1780149664        → absent
ical_feeds/audit98-prop-…_audit98-feed-…          → absent
loginAttempts/{docId(lockout-target-…@example.test)} → absent
Auth user bookbed-foreign-1780149058@example.test → deleted
users/{TEST_UID}/profile/audit98-*.jpg            → absent (inline delete + sweep)
```

The probe also exercised `setPropertySubdomain` against the test-acct property
twice (cases 6a + 6c-setup), leaving the test-acct property holding
`subdomain="a98-1780149650"` momentarily — cleanup deletes the property doc
which releases the subdomain. The throwaway second prop is similarly deleted.

The cutover-blocking surface is **zero** after cleanup: no test data persists
on `bookbed-dev`, no `loginAttempts/*` doc is locked, no Auth user remains.

---

## 5. PROD cutover gating

**Blocker (this smoke):** none. Matrix is 41 PASS / 1 net-new LOW / 2 INFO / 1 KNOWN-GAP.

**Blocker (parallel work):** F-CUT-01 — `functions/package-lock.json` regenerated under npm 11 fails Cloud Build npm 10 `npm ci` (`Missing: @emnapi/core@1.10.0 from lock file`). Captured by the parallel cutover dry-run agent in `audit/cutover-dryrun-2026-05-30/runbook.md` + memory `cutover-lockfile-drift-2026-05-30.md`. Every first-deploy of a function on PROD will fail until the lockfile is regenerated under Node 20 / npm 10 and committed. This is independent of every smoke row below and must be resolved before PROD cutover begins. **Add as a §1 pre-flight item in `audit/90-prod-cutover-runbook.md`.**

| Item | Status | Action before PROD cutover |
|---|---|---|
| **F-CUT-01 lockfile drift (npm 11 vs Cloud Build npm 10)** | 🚨 Blocker (from sibling work) | Regenerate `functions/package-lock.json` on a Node 20 / npm 10 toolchain; commit; verify `npm ci` clean in CF deploy pre-flight. |
| F-98-01 top-level `ical_feeds` gap | Net-new LOW | Inventory PROD `ical_feeds` for legacy docs (`firestore query collection=ical_feeds limit=1`). If non-empty, decide whether to bundle the F-98-01 rule fix into the PROD cutover or defer to a follow-up PR. If empty, defer. |
| F-95-01/02 TZ INFO | No-op | Source-side cosmetic — no action. |
| F-94-02-CREATE squat | Known gap, documented | No PROD action; runbook owner should add a note that direct-REST squat remains possible. Long-term close = rules split or `onDocumentCreated` trigger (see §3.3). |
| All other matrix rows | PASS | None. |

Order of cutover unchanged from audit/90 §2.

---

## 6. Reproduction recipe

Probe URL set assembled via `gcloud functions describe <name> --project=bookbed-dev`
(see `cf-urls.tsv` in the smoke run state dir):

```
recordloginfailure-whc46z5xxq-ew.a.run.app                (europe-west1)
clearloginattempts-whc46z5xxq-ew.a.run.app                (europe-west1)
getloginlockoutstatus-whc46z5xxq-ew.a.run.app             (europe-west1)
createstripecheckoutsession-whc46z5xxq-uc.a.run.app       (us-central1)
createbookingatomic-whc46z5xxq-uc.a.run.app               (us-central1)
guestcancelbooking-whc46z5xxq-uc.a.run.app                (us-central1)
getunitavailability-whc46z5xxq-ew.a.run.app               (europe-west1)
setpropertysubdomain-whc46z5xxq-uc.a.run.app              (us-central1)
getuniticalfeed-whc46z5xxq-uc.a.run.app                   (us-central1)
```

Owner ID-token from Identity Toolkit `accounts:signInWithPassword` with the
DEV web API key (`AIzaSyDc6vDPLBTN3ePkY39Pw9Jrheh30OhLWEM`, from
`firebase_options_dev.dart`). Foreign UID identical flow with a throwaway
`bookbed-foreign-{ts}@example.test`.

Storage bucket: `bookbed-dev.firebasestorage.app`. Storage REST endpoints:

- Upload: `POST https://firebasestorage.googleapis.com/v0/b/{bucket}/o?name={percent-encoded-path}` with `Authorization: Firebase {idToken}` + content-type.
- DELETE: `DELETE …/o/{percent-encoded-path}` with same auth.
- GET: `…/o/{percent-encoded-path}?alt=media` (anon = no auth header).

Firestore REST endpoints:

- PATCH single doc: `PATCH /v1/projects/bookbed-dev/databases/(default)/documents/{path}?updateMask.fieldPaths=<field>&currentDocument.exists=true` with bearer.
- CG query (deny probe): `POST …documents:runQuery` body `{"structuredQuery":{...,"from":[{"collectionId":"bookings","allDescendants":true}]}}` (no auth).

CORS preflight discriminator (per advisor §2): always include `Origin`,
`Access-Control-Request-Method`, `Access-Control-Request-Headers` together.
Status `204` alone is meaningless; presence/absence of `Access-Control-Allow-Origin`
in the response is the signal.

---

## 7. See also

- `audit/90-prod-cutover-runbook.md` — PROD cutover order; this smoke is the dev-side dry-run.
- `audit/cutover-dryrun-2026-05-30/` — sibling parallel agent's deploy-dryrun (rules + indexes + CF + widget hosting); origin of F-CUT-01 lockfile drift.
- `audit/86-f94-direct-write.md`, `audit/87-f95-low-bundle.md`, `audit/89-f86-01-cors-fix.md`, `audit/91-f91-02-storage-delete.md`, `audit/92-f92-01-ical-token.md`, `audit/96-f94-02-create-fix.md`, `audit/97-flutter-7e-booking-ref.md` — per-fix design docs that this matrix exercises.
- `memory/test-account.md`, `memory/cf-region-split-us-eu.md`, `memory/sf-062-pr567-naming-conflict.md`, `memory/cutover-lockfile-drift-2026-05-30.md`, `memory/cf-deploy-cors-shape-iam-strip.md`.
