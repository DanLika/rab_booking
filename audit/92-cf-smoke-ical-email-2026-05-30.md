# CF smoke — iCal + email + notification + lifecycle (2026-05-30)

Autonomous smoke on bookbed-dev. Worktree `test/cf-smoke-ical-email-0530` off `origin/main` HEAD `ed31ae47`. No PROD writes; one PROD read-only probe (widget_settings.ical_export_token presence). All throwaway artifacts cleaned.

`audit/91` slug already reserved in `memory/MEMORY.md` for sanitizeEmail/SF-050 work; this doc carries the next free slug (92) and uses `F-92-NN` for findings to avoid collision.

## TL;DR

| # | CF / surface | Verdict |
|---|---|---|
| 1 | `getUnitIcalFeed` (us-central1, onRequest) | 🟡 **F-92-01 MEDIUM** empty-token bypass + ✅ rest |
| 2 | `getUnitAvailability` (eu-west1, callable) | ✅ + round-trip ical_external + echo skip |
| 3 | `syncIcalFeedNow` (us-central1, callable) | ✅ unauth/owner/region all gates fire |
| 4 | `scheduledIcalSync` (eu-west1, every 15m) | ✅ deployed + scheduled + last run 06:42Z |
| 5 | `resendBookingEmail` (us-central1, callable) | ✅ incl. SF-vibe57 H-06 5/hr rate limit |
| 6 | `sendCustomEmailToGuest` (us-central1, callable) | 🟡 **F-92-02 LOW** validation order bounces tests pre-gate |
| 7 | `approve` / `reject` / `cancel` / `completeBooking` (eu-west1) | ✅ all 4 actions: 401/400/404/403 matrix green |
| 8 | `autoCompleteCheckedOutBookings` (us-central1, daily) | ✅ + external/iCal source filter present |
| 9 | `autoCancelExpiredBookings` (us-central1, 24h) | 🟡 **F-92-03 INFO** missing parallel external/iCal source filter |
| 10 | `cleanupExpiredStripePendingBookings` (us-central1, 5m) | ✅ deployed + 5m cycle observed |
| 11 | `notificationService` (internal helper) | ✅ STATIC ONLY — BUG-011 action key present |
| 12 | SSRF guards (M-11 hex, pinned lookup, redirect re-validate) | ✅ STATIC ONLY — behavioral DEFERRED |
| 13 | `BEGIN:VCALENDAR` guard (BUG-009) | ✅ STATIC ONLY — behavioral DEFERRED |
| 14 | F-67-05 client message scrubbing | ✅ STATIC ONLY — confirmed via source read |
| 15 | SF-066/FLUTTER-7B `logWarn` on transient | ✅ STATIC ONLY — logWarn vs logError split correct |

## Pre-flight

| Item | State |
|---|---|
| Worktree | `/tmp/bb-cf-ical-wt` on `test/cf-smoke-ical-email-0530` |
| Base | `origin/main` @ `ed31ae47` (docs: App Check client init audit) |
| `gcloud config core/project` | unchanged (PROD = `rab-booking-248fc`, per [[gcloud-quota-project-bookbed]]) |
| Admin SDK target | `bookbed-dev` via `GOOGLE_CLOUD_PROJECT` env override only |
| Dev Web API key | `AIzaSyDc6vDPLBTN3ePkY39Pw9Jrheh30OhLWEM` (per `lib/firebase_options_dev.dart:25`) |
| Seed property A | `SEED_property_dev_01` / unit `SEED_unit_dev_01` (owner `Zo01CJ3wymb0pplaYOyaZ2yGUWG2`) |
| Seed property B | `SEED_test_owner_property_01` / unit `SEED_test_owner_unit_01` (owner `GILVItIVP5R8WXfnMmyMo1ykhUm2` per [[test-account]]) |
| Firestore region | `europe-west3` (dev) |

## Findings

### F-92-01 — `getUnitIcalFeed` empty-token bypass on partially-migrated widget_secrets — MEDIUM

**Severity rationale**: it IS an auth-gate bypass (CF documented as token-secured), but the information leaked is `dates + unit name` only — both already publicly retrievable via the anonymous `getUnitAvailability` CF + the property catalogue. NO guest PII leaks (`generateBookingEvent` only emits `"Reserved"` per GDPR design). Frame as defense-in-depth gap, not data exfil.

**Root cause** — schema migration / code mismatch:

`functions/src/icalExport.ts:162-176` reads `widget_secrets.ical_export_token`. A migration referenced by PR #482 (widget_secrets workstream) wrote `widget_secrets.ical_export_token_plaintext` + `ical_export_token_hash` on bookbed-dev's 2 seed units, but the corresponding code-side read of `_plaintext` / `_hash` never landed on `main`. Verified with `grep -rEn "ical_export_token_(plaintext|hash)" functions/src lib` — **zero matches** in either tree.

Resolution chain:
1. `storedToken` = `widget_secrets.ical_export_token` → `undefined` (field missing on dev migrated docs)
2. fallback `legacyToken = widget_settings.ical_export_token` → `""` (legacy slot blanked on dev)
3. `tokenToCompare = ""`
4. `verifyIcalToken(providedToken, "")` with `providedToken = ""` ⇒ `Math.max(0,0)=0` ⇒ both `Buffer.from("", "utf8")` zero-length ⇒ `crypto.timingSafeEqual(empty, empty)` returns `true`

**Trigger URL**: `…/getUnitIcalFeed/{pid}/{uid}/.ics`. The `pathParts[2].replace(/\.ics$/i, "")` strips `.ics` → `token = ""`.

**Live probe** (cleaned, no writes):

```
P7 GET .../SEED_property_dev_01/SEED_unit_dev_01/.ics   → 200 OK | 643b VCALENDAR
P7 GET .../SEED_test_owner_property_01/SEED_test_owner_unit_01/.ics → 200 OK | 1892b VCALENDAR
```

Both responses included a real booking VEVENT (`UID:booking-SEED_booking_dev_01@bookbed.io DTSTART:20260624`).

Negative-control: flipping `ical_export_enabled=false` then re-probing returned `403 "iCal export is disabled"` (gate fires correctly); state restored to `true` immediately after.

**Scope**

| Env | Sampled | `ical_export_enabled=true` | With token (safe) | Vulnerable |
|---|---|---|---|---|
| bookbed-dev | 2 / 2 properties | 2 | 0 | **2** |
| rab-booking-248fc (PROD, read-only) | 13 properties | 11 | 11 | **0** |

PROD scope is **directly verified** by Admin-SDK read of `widget_settings.ical_export_token` presence on every PROD widget_settings doc (no writes). The PR #482 migration has NOT run on PROD (per `audit/90` §1: `ICAL_TOKEN_PEPPER` missing) — the legacy token slot remains populated, so the bypass condition does not occur there today.

**Mitigation (recommended, NOT applied in this PR — doc-only)**

Patch `icalExport.ts` to fail-CLOSED on empty stored token AND empty supplied token, BEFORE timing-safe compare. Smallest sufficient change:

```typescript
// after computing tokenToCompare
if (!token || token.length === 0 || !tokenToCompare || tokenToCompare.length === 0) {
  logError("[iCal Feed] Token gate fail-CLOSED", { propertyId, unitId });
  response.status(403).send("Invalid token");
  return;
}
```

Pros: closes the bypass for any state where either side is empty. Cons: minor change in HTTP shape on legitimate-but-misconfigured units (today 200 OK, after 403) — but those are the vulnerable units.

A parallel dev-data fix would seed `widget_settings.ical_export_token` for the two SEED units to restore legacy-path safety while PR #482 readside isn't merged.

---

### F-92-02 — `sendCustomEmailToGuest` validation runs AFTER booking lookup — LOW

`functions/src/customEmail.ts` flow:

1. auth check
2. rate limit (Firestore 10/min)
3. required-field presence check (`!bookingId || !guestEmail || …`)
4. **`findBookingById()` — DB roundtrip**
5. owner_id ownership
6. guest_email match
7. length caps (MAX_SUBJECT_LENGTH 998, MAX_MESSAGE_LENGTH 50000)
8. RFC validateEmail

Smoke probes C3 (invalid-email), C4 (CRLF-in-subject), C5 (5000-char subject) all bounced at step 4 with `NOT_FOUND` because `bookingId:"x"` doesn't exist. These tests are therefore **INCONCLUSIVE** for the length / CRLF / RFC gates — the gates were NEVER reached in this run.

Implication: first caller to actually exercise the cheap checks is an attacker who DOES own a booking (passes ownership gate). Validation order should put cheap stateless checks before DB lookup.

**Note on CRLF in `subject`**: `validateEmail` only sanitizes `guestEmail`. `subject` is length-capped only, no explicit CRLF / header-character filter. Whether Resend's API SDK escapes CRLF in subject when serializing to JSON `→` SMTP header is implementation-dependent. Header-injection risk class — recommend defense-in-depth `subject.replace(/[\r\n]/g, "")` and/or hard reject pattern.

**Follow-up test plan** (not executed this run — heavy setup):
1. Write a throwaway booking under throwaway-owned property
2. Re-fire C3/C4/C5 with the real `bookingId`
3. Confirm 400 INVALID_ARGUMENT at gates 7+8

---

### F-92-03 — `autoCancelExpiredBookings` lacks external/iCal source filter — INFO

`autoCompleteCheckedOutBookings.ts` filters out `source in ['booking_com','airbnb','ical','external']` AND `doc.id.startsWith('ical_')` before status mutation.

`bookingManagement.ts:93-177 autoCancelExpiredBookings` has no equivalent filter — only `status=='pending' AND payment_deadline < now`. In practice external/iCal bookings never carry `payment_deadline`, so this is unreachable today; if a future ingestion path ever set the field on an external booking, the CF would attempt to send a `sendBookingCancellationEmail` to whatever `guest_email` was on the doc.

Documented for parity; LOW priority follow-up = add the same source filter to autoCancel.

---

## Behavioural matrix

### CF #1 — `getUnitIcalFeed` (probe URL `https://us-central1-bookbed-dev.cloudfunctions.net/getUnitIcalFeed`)

| Probe | Method | URL fragment | Expected | Actual |
|---|---|---|---|---|
| P1 | GET | `/just-one` | 400 | 400 "Invalid URL format. Expected: /{propertyId}/{unitId}/{token}" |
| P2 | GET | `/SEED_property_dev_01/nonexistent_unit/anything` | 404 | 404 "Unit not found" |
| P3 | GET | `/nonexistent_prop/SEED_unit_dev_01/anything` | 404 | 404 "Unit not found" |
| P4 | OPTIONS | any | 204 | 204 No Content |
| P5 | POST | any | 405 | 405 Method Not Allowed |
| P6 | GET | `/SEED_property_dev_01/SEED_unit_dev_01/` | 400 | 400 (pathParts<3 due to trailing slash split) |
| P7 | GET | `…/SEED_unit_dev_01/.ics` | 403 (intended) | **200 OK 643b VCALENDAR** → **F-92-01** |
| P8 | GET | `…/SEED_unit_dev_01/RANDOMBOGUS12345.ics` | 403 | 403 "Invalid token" |
| P9 | HEAD | `…/SEED_unit_dev_01/RANDOMBOGUS12345` | 403 | 403 Forbidden, 0 byte body (HEAD-correct) |

### CF #2 — `getUnitAvailability` (`https://europe-west1-bookbed-dev.cloudfunctions.net/getUnitAvailability`)

Anonymous callable. 8 probes:

| Probe | Input shape | Result |
|---|---|---|
| P1 | valid 60d range | 200, `windows[1] {source:"booking"}` — `SEED_booking_dev_01` |
| P2 | missing propertyId | 400 INVALID_ARGUMENT "propertyId must be a non-empty string" |
| P3 | missing unitId | 400 INVALID_ARGUMENT |
| P4 | endDate < startDate | 400 INVALID_ARGUMENT "endDate must be after startDate" |
| P5 | range 367 days | 400 OUT_OF_RANGE "Date range exceeds 366 days" |
| P6 | unknown unitId | 200, `windows[]` empty (+ logWarn rate-limited 1/hr per IP) |
| P7 | garbage date string | 400 INVALID_ARGUMENT "startDate is not a valid date" |
| P8 | empty propertyId | 400 INVALID_ARGUMENT |

**PII strip check** (P1 response body, full):

```json
{
  "unitId": "SEED_unit_dev_01",
  "windows": [{"start":"2026-06-23T12:00:00.000Z","end":"2026-06-26T12:00:00.000Z","source":"booking"}],
  "generatedAt": "2026-05-30T06:45:09.434Z",
  "cacheHint": 30
}
```

Only `start` / `end` / `source` per `AvailabilityWindow`. No `guest_name` / `guest_email` / `payment_*` ever surfaces.

### CF #2b — `getUnitAvailability` ical round-trip e2e

Write → query → cleanup. SEED unit, far-future 2028 range to avoid overlap.

```
WROTE properties/SEED_property_dev_01/ical_events/SMOKE_ical_event_smoke91-1780123540989
CF STATUS: 200
WINDOWS: [{
  "start": "2028-03-15T00:00:00.000Z",
  "end":   "2028-03-20T00:00:00.000Z",
  "source": "ical_external",
  "platform": "smoke_test_platform"
}]
✅ ROUND-TRIP PASS
✅ PLATFORM ATTRIB OK
✅ ECHO SKIP OK: confirmed_echo not surfaced  (second event status:"confirmed_echo")
CLEANUP DONE
```

Confirms:
- `availability.ts:228` platform attribution carries verbatim from `ical_events.source`
- `availability.ts:221` echo skip (`if (data.status === "confirmed_echo") continue`) works
- CollectionGroup query `where("unit_id","==",unitId)` on `ical_events` resolves cross-property

### CF #3 — `syncIcalFeedNow` (us-central1, NOT europe-west1)

Region note: `syncIcalFeedNow` is declared `onCall(async …)` with NO region override → defaults to `us-central1`. `scheduledIcalSync` IS pinned `region: "europe-west1"`. Region split per `audit/58` F-58-08 / [[cf-region-split-us-eu]].

| Probe | Result |
|---|---|
| S1 no auth | 401 UNAUTHENTICATED "User must be authenticated" |
| S2 auth, missing args | 400 INVALID_ARGUMENT "feedId and propertyId are required" |
| S3 auth, fake propertyId | 403 PERMISSION_DENIED "You do not own this property" |
| S4 auth, SEED property owned by other UID | 403 PERMISSION_DENIED |

Same probes against `europe-west1` 404 (CF not in that region — confirms exclusive us-central1 placement).

### CF #4 — `scheduledIcalSync` (eu-west1, every 15m)

Log read (last 3 invocations):

```
2026-05-30T06:42:04.746529Z INFO [Scheduled iCal Sync] No active feeds to sync
2026-05-30T06:42:04.612257Z INFO [Scheduled iCal Sync] Starting automatic sync of all feeds
2026-05-30T06:27:04.960023Z INFO [Scheduled iCal Sync] No active feeds to sync
```

Scheduler job `firebase-schedule-scheduledIcalSync-europe-west1` ENABLED, schedule `every 15 minutes`, last attempt `2026-05-30T06:42:04Z`. No bookbed-dev `ical_feeds` docs are currently active+15min-elapsed (clean dev state). Live behavioural trigger DEFERRED — would require seeding an `ical_feeds` doc with attacker URL on a SEED property + waiting for next 15m tick OR firing `syncIcalFeedNow` as that owner.

### CF #5 — `resendBookingEmail` (us-central1)

| Probe | Result |
|---|---|
| R1 no auth | 401 UNAUTHENTICATED |
| R2 auth, no bookingId | 400 INVALID_ARGUMENT "Booking ID is required" |
| R3 auth, fake bookingId | 404 NOT_FOUND "Booking not found" |
| R4 burst 6× same bookingId | calls 1-5 = 404, call 6 = **429 RESOURCE_EXHAUSTED** — SF-vibe57 H-06 5/hr per (uid,bookingId) fires |

### CF #6 — `sendCustomEmailToGuest` (us-central1)

| Probe | Result | Notes |
|---|---|---|
| C1 no auth | 401 UNAUTHENTICATED | ✅ gate |
| C2 auth, all fields empty | 400 INVALID_ARGUMENT "Missing required fields" | ✅ gate |
| C3 auth, invalid email | 404 NOT_FOUND | ⚠️ **INCONCLUSIVE** — `findBookingById` bounced |
| C4 auth, CRLF in subject | 404 NOT_FOUND | ⚠️ **INCONCLUSIVE** |
| C5 auth, 5000-char subject | 404 NOT_FOUND | ⚠️ **INCONCLUSIVE** |
| C6 auth, SEED booking owned by other UID | 403 PERMISSION_DENIED "You can only send emails to guests of your own bookings" | ✅ ownership gate |

See **F-92-02** above. Length/CRLF/RFC gates not exercised this run; mark as static-only based on source read.

### CF #7 — `bookingActions` (eu-west1) — approve / reject / cancel / completeBooking

4 actions × 4 probes = 16 calls. Uniform matrix:

| Probe | All 4 actions |
|---|---|
| no auth | 401 UNAUTHENTICATED "You must be signed in." |
| auth, no bookingId | 400 INVALID_ARGUMENT "bookingId must be a string." |
| auth, fake bookingId | 404 NOT_FOUND "Booking not found." |
| auth, SEED booking owned by other UID | 403 PERMISSION_DENIED "You do not own this booking." |

`loadOwnedBookingForAction()` ownership + status gating consistent across all 4. F-67-01 migration off direct-write SDK confirmed deployed and gating correctly on dev.

### CF #8/9/10 — scheduled lifecycle

Scheduler inventory (`gcloud --project=bookbed-dev scheduler jobs list`):

| Job | Region | Schedule | Last attempt | Last log |
|---|---|---|---|---|
| `autoCompleteCheckedOutBookings` | us-central1 | `0 2 * * *` Zagreb | 2026-05-30 00:00:26Z | "No checked-out bookings found to complete" |
| `autoCancelExpiredBookings` | us-central1 | every 24h | 2026-05-29 14:26:01Z | "Auto-cancelled expired bookings" / "Auto-cancel check completed" |
| `cleanupExpiredStripePendingBookings` | us-central1 | `*/5 * * * *` | 2026-05-30 06:50:02Z | "No expired Stripe pending bookings found" |
| `cleanupPastDailyPrices` | us-central1 | `0 2 1 * *` monthly | (no recent execution this freshness window) |
| `scheduledIcalSync` | europe-west1 | every 15m | 2026-05-30 06:42:04Z | "No active feeds to sync" |
| `pendingPaymentReminder`, `sendTrialExpirationWarning`, `checkOutTodayReminder`, `checkInTomorrowReminder`, `monthlyRevenueReport`, `checkTrialExpiration`, `biweeklySummary` | europe-west1 | various | recent | (out of scope this audit) |

All deployed, all firing on schedule. External/iCal source filter present on autoComplete (verified in source, `completeCheckedOutBookings.ts:140-156`); MISSING on autoCancel → **F-92-03**.

### CF #11 — `notificationService` (internal helper, not exposed)

Static-only verification:
- `notificationService.ts:24-33` BUG-011 idempotency key includes action: `${ownerId}_${type}_${bookingId}_${action}_${minute}`
- `createBookingNotification()` lines 80-87 pass `metadata.action` correctly
- Writes to `users/{ownerId}/notifications/{idempotencyKey}` via `.set()` (idempotent overwrite)

No behavioural probe — would require triggering a booking create/update + reading the resulting notif doc. Defer to e2e booking lifecycle test (parallel to `audit/34`).

### #12 — SSRF guards (STATIC ONLY — behavioural DEFERRED)

Static verification on `functions/src/icalSync.ts`:
- L155 — protocol whitelist `http:` / `https:` (blocks `file:`, `gopher:`, `data:`, etc.)
- L39-90 `isPrivateOrUnsafeIp()` — 10/8, 127/8, 169.254/16, 172.16-31/12, 192.168/16, 100.64-127/10, 224+/4, IPv6 ::1, fe80:, fc/fd, ff
- L43-44 IPv4-mapped IPv6 decimal form `::ffff:a.b.c.d`
- L49-58 **SF-vibe57 M-11** hex form `::ffff:a9fe:a9fe` (closed in `audit/58`)
- L175 `dns.lookup(hostname, {all: true, verbatim: true})` — checks ALL addresses
- L187-198 reject if ANY resolved addr private/unsafe
- L611-625 pinned `lookup` callback — Node 18+ `autoSelectFamily` dispatch fix (`audit/55` PR #514 `1c3d6985`) handles both array and 3-arg signature
- L649-672 redirect re-validation (defeats SSRF via attacker-controlled 302)
- L497-511 BUG-009: BEGIN:VCALENDAR guard with size-only redaction (HIGH-1 fix — never echo response body in error)
- L436-444 F-67-05 client message scrub on `syncIcalFeedNow` failure (no upstream host leak)
- L122-132 + L329-340 `isTransientFetchError()` → `logWarn` not `logError` (SF-066/FLUTTER-7B pattern)

**Behavioural probes DEFERRED** — would require:
1. Throwaway property + ownership on bookbed-dev
2. Write `ical_feeds/{id}` doc with attacker URL (e.g. `http://169.254.169.254`)
3. Call `syncIcalFeedNow` as that owner → expect 500 with scrubbed message
4. Verify Cloud Logging WARN entry "SSRF guard blocked private IP"

Cloud Logging shows 5× historical SSRF blocks on 2026-05-27 (prior audit/58c run) confirming the guard fires under runtime — but those are NOT from this session.

### #13 — `BEGIN:VCALENDAR` guard (BUG-009 / audit/31 HIGH-1)

Source `icalSync.ts:497-511` correct. Behavioural DEFERRED — would require hosting a fake iCal endpoint returning non-VCALENDAR content (e.g. HTML 200 OK) and pointing a feed at it.

### #14 — F-67-05 client message scrub

Source `icalSync.ts:436-444`. Error message returned to client is generic ("Sync failed. Verify the feed URL is reachable…"); upstream `host:` / response body never echoed. Validated DEFERRED (same fixture as #13).

### #15 — `logWarn` vs `logError` split (SF-066 / FLUTTER-7B)

Source `icalSync.ts:122-132` `TRANSIENT_NET_CODES` set + 5xx regex + "Request timeout" regex. Routed to `logWarn` in scheduled (L329-340) and manual (L557-563) paths. Avoids per-tick Sentry alerts on third-party flakiness. Sentry filter at `sentry.ts:beforeSend` separately drops `HttpsError` client-fault codes per `[[sentry-beforesend-httperror-only]]`.

## Cleanup verification

Final state read at end of session:

| Artifact | Created | Deleted | Final |
|---|---|---|---|
| Throwaway auth users (`smoke91*@bookbed-smoke.test`) | 3 in primary script + 2 from earlier attempts | 5 | **0 remaining** (`listUsers` filter) |
| `ical_events` (round-trip + echo) | 2 (`SMOKE_ical_event_*` + `*_echo`) | 2 | **0 orphans** (`feed_id == "SMOKE_FEED_91"` query) |
| `widget_settings.ical_export_enabled` on `SEED_test_owner_unit_01` | flipped false → true (negative control) | n/a | **true** (verified read) |
| Worktree | created | (deletion in PR-close step) | retained for now |

## PROD safety statement

- ZERO PROD writes this session
- ONE PROD read-only sample: `properties.{*}.widget_settings.{*}.ical_export_token` presence for first 100 properties, paired Admin SDK `widget_secrets` lookup on each `ical_export_enabled=true && legacy_token=empty` candidate (none found)
- `gcloud config core/project` unchanged from `rab-booking-248fc` baseline ([[gcloud-quota-project-bookbed]])
- `bookbed-dev` Admin SDK use scoped via `GOOGLE_CLOUD_PROJECT` env override

## Recommended follow-ups (not landing this PR)

1. **F-92-01 fix** (own PR, ~5 LOC + tests) — defensive `if (!tokenToCompare || tokenToCompare.length === 0) return 403` in `icalExport.ts` BEFORE `verifyIcalToken` call
2. **F-92-01 dev-data fix** — backfill `widget_settings.ical_export_token` on 2 dev SEED units to restore legacy-path safety until PR #482 readside lands
3. **F-92-02** — reorder `customEmail.ts` validation: length/CRLF/RFC checks BEFORE `findBookingById`; explicit `subject.replace(/[\r\n]/g, "")` defense-in-depth
4. **F-92-02 retest** — write throwaway booking owned by throwaway user, re-fire C3/C4/C5 to confirm validation gates work
5. **F-92-03** — add `source in ['booking_com','airbnb','ical','external']` filter to `autoCancelExpiredBookings` for parity with `autoCompleteCheckedOutBookings`
6. **SSRF behavioural** — throwaway-feed live probe with `http://169.254.169.254/computeMetadata/v1/`, `file:///etc/passwd`, and `http://[::ffff:a9fe:a9fe]/` to confirm guard fires E2E (not just historical)
7. **BEGIN:VCALENDAR behavioural** — synthetic HTTP endpoint returning HTML/JSON to verify `Fetched iCal data is empty or invalid` error path

## Cross-refs

- `audit/54` — CF smoke 2026-05-26 (SF-038/047/048 + Sentry + TTL)
- `audit/55` — F-50-02 PR #517 closure
- `audit/56` — PR #514 SSRF lookup callback regression fix
- `audit/57` / `audit/58` / `audit/58b` / `audit/58c` — vibe-security baseline + DevTools deep-flow
- `audit/90` — PROD cutover runbook (§1 PR #482 / `ICAL_TOKEN_PEPPER`)
- [[smoke-blocked-date-recipe]] — anon CF probe recipe used here
- [[cf-region-split-us-eu]] — region split inference method
- [[gcloud-quota-project-bookbed]] — quota-project safe pattern
- [[sentry-beforesend-httperror-only]] — sentry filter scope
- [[ssrf-ipv4-mapped-ipv6-hex-hole]] — M-11 history
- [[node-autoselectfamily-lookup-callback]] — pinned-lookup gotcha

---

Branch `test/cf-smoke-ical-email-0530` off `origin/main` `ed31ae47`. Doc-only PR.
