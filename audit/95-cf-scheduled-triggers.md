# audit/95 — CF smoke: scheduled jobs + Firestore triggers (read-only)

**Date**: 2026-05-30
**Branch**: `test/cf-scheduled-triggers-0530`
**Env**: bookbed-dev only (HARD: never PROD)
**Scope**: 12 scheduled + 6 onDocument CFs not covered in audit/54 / audit/79 / prior smokes
**Mode**: read-only smoke + one live throwaway trigger; no PROD touch; no rules/turf overlap (stripePayment, subdomain, ical_feeds)
**Bundle**: log evidence (24-72 h freshness) + Firestore data probe + 1 controlled live trigger for onBookingCreated

---

## 1. Inventory

`gcloud functions list --v2 --regions=us-central1,europe-west1` confirms all 18 CF in scope deployed + ACTIVE on bookbed-dev. `gcloud scheduler jobs list` confirms all 12 cron jobs ENABLED + schedule matches source.

| # | CF | Type | Region | Source schedule | Deployed schedule | TZ | Match |
|---|---|---|---|---|---|---|---|
| 1 | `scheduledIcalSync` | onSchedule | eu-west1 | `every 15 minutes` | every 15 minutes | UTC (default) | ✅ |
| 2 | `cleanupExpiredStripePendingBookings` | onSchedule | us-central1 | `*/5 * * * *` | `*/5 * * * *` | Zagreb | ✅ |
| 3 | `cleanupPastDailyPrices` | onSchedule | us-central1 | `0 2 1 * *` | `0 2 1 * *` | UTC | ✅ |
| 4 | `autoCompleteCheckedOutBookings` | onSchedule | us-central1 | `0 2 * * *` | `0 2 * * *` | Zagreb | ✅ |
| 5 | `autoCancelExpiredBookings` | onSchedule | us-central1 | `every 24 hours` | every 24 hours | UTC (default — F-95-01) | ⚠️ |
| 6 | `checkInTomorrowReminder` | onSchedule | eu-west1 | `0 18 * * *` | `0 18 * * *` | Zagreb | ✅ |
| 7 | `checkOutTodayReminder` | onSchedule | eu-west1 | `0 8 * * *` | `0 8 * * *` | Zagreb | ✅ |
| 8 | `pendingPaymentReminder` | onSchedule | eu-west1 | `0 10 * * *` | `0 10 * * *` | Zagreb | ✅ |
| 9 | `biweeklySummary` | onSchedule | eu-west1 | `0 9 1,15 * *` | `0 9 1,15 * *` | Zagreb | ✅ |
| 10 | `monthlyRevenueReport` | onSchedule | eu-west1 | `0 10 1 * *` | `0 10 1 * *` | Zagreb | ✅ |
| 11 | `checkTrialExpiration` | onSchedule | eu-west1 | `0 2 * * *` | `0 2 * * *` | UTC (default — F-95-02) | ⚠️ |
| 12 | `sendTrialExpirationWarning` | onSchedule | eu-west1 | `0 9 * * *` | `0 9 * * *` | UTC (default — F-95-02) | ⚠️ |
| 13 | `onBookingCreated` | onDocCreate | us-central1 | n/a | n/a | n/a | ✅ |
| 14 | `onBookingStatusChange` | onDocUpdate | us-central1 | n/a | n/a | n/a | ✅ |
| 15 | `onUserCreate` | onDocCreate | eu-west1 | n/a | n/a | n/a | ✅ |
| 16 | `onPropertyDeleted` | onDocDelete | eu-west1 | n/a | n/a | n/a | ✅ |
| 17 | `onUnitDeleted` | onDocDelete | eu-west1 | n/a | n/a | n/a | ✅ |
| 18 | `newAppUpdateNotification` | onDocUpdate | eu-west1 | n/a | n/a | n/a | ✅ |

---

## 2. Runtime evidence matrix

Log query: `gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="<fn>"' --project=bookbed-dev --freshness=24-72h`. Most recent observed run + steady-state side effect:

| CF | Last run (UTC) | Side effect observed | Verdict |
|---|---|---|---|
| `scheduledIcalSync` | 07:57:05 | `No active feeds to sync` (0 feeds exist on dev) | ✅ healthy idle |
| `cleanupExpiredStripePendingBookings` | 08:05:03 | `No expired Stripe pending bookings found` | ✅ healthy idle |
| `cleanupPastDailyPrices` | (monthly — next fire 2026-06-01) | startup probe only | ✅ wired (next-fire pending) |
| `autoCompleteCheckedOutBookings` | 00:00:33 | `No checked-out bookings found to complete` | ✅ healthy idle |
| `autoCancelExpiredBookings` | 14:26:06 (yesterday) | `Auto-cancel check completed` → `Auto-cancelled expired bookings` | ✅ fires + processes |
| `checkInTomorrowReminder` | 16:00:09 (yesterday) | `No check-ins tomorrow` | ✅ healthy idle |
| `checkOutTodayReminder` | 06:00:13 | `No check-outs today` | ✅ healthy idle |
| `pendingPaymentReminder` | 08:00:11 | `No payments due soon` | ✅ healthy idle |
| `biweeklySummary` | (next fire 2026-06-01) | n/a | ✅ wired |
| `monthlyRevenueReport` | (next fire 2026-06-01) | n/a | ✅ wired |
| `checkTrialExpiration` | 02:00:09 | `No expired trials found` | ✅ healthy idle |
| `sendTrialExpirationWarning` | 09:00:14 (yesterday) | `Completed all warning checks` (7/3/1-day intervals all empty) | ✅ healthy idle |
| `onBookingCreated` | **live smoke 08:08 today** | `[iCal Cache] Invalidated` (8 s end-to-end — see §4) | ✅ trigger fires |
| `onBookingStatusChange` | 2026-05-29 07:43 | `Booking status changed` → `[iCal Cache] Invalidated` | ✅ fires on prior real edit |
| `onUserCreate` | 2026-05-28 09:11 | `Trial Init: Trial and profile initialized successfully` | ✅ fires on real signup |
| `onPropertyDeleted` | (no event 72 h) | n/a — startup probe only | ✅ wired (no real deletes) |
| `onUnitDeleted` | 2026-05-28 07:34 | `Unit cleanup completed` (bookings + widget_settings empty) | ✅ fires on real delete |
| `newAppUpdateNotification` | (no `app_config` write 72 h) | n/a | ✅ wired |

---

## 3. Data probe (bookbed-dev Firestore)

Read-only Admin SDK probe (`audit/smoke/95-probe-bookings.js`, ADC + `GOOGLE_CLOUD_PROJECT=bookbed-dev`) confirms suspect logic classes have **zero real-world exposure on dev**:

| Probe | Result |
|---|---|
| pending bookings with external `source` AND `payment_deadline < now` (F-95-03 candidate) | **0 hits** |
| pending bookings with `check_out < today` (F-95-04 candidate — autoComplete would mark `completed` not `cancelled`) | **0 hits** |
| trial users missing `trialWarning{N}DaySent` flag (F-95-08 candidate — would be excluded from warning query) | **0/2 missing** (both trial users have all 3 flags) |
| Active `ical_feeds` (status in active/error) | 0 feeds — explains `scheduledIcalSync` "no feeds" steady state |

Theoretical gaps remain in code (see §5); PROD probe required before claiming the same on PROD.

---

## 4. Live trigger smoke — onBookingCreated

Single throwaway transaction on the existing test owner `bookbed-test@bookbed.io` (UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`, property `SEED_test_owner_property_01`, unit `SEED_test_owner_unit_01`). Script: `audit/smoke/95-seed-trigger-test.js`. Output:

```
[1] BASELINE cache=true cached_at=2026-05-30T07:30:13.708Z
[2] SEED written: properties/SEED_test_owner_property_01/units/SEED_test_owner_unit_01/bookings/AUDIT95_throwaway_1780128914650
[3] CACHE FLUSHED after 8s (was 2026-05-30T07:30:13.708Z → now none)
[4] DELETED booking (9604ms after seed)
[5] CLEANUP verify exists=false
```

End-to-end: `onBookingCreated` fired and ran `invalidateIcalCache(propertyId, unitId)` within 8 s of the Firestore write. The widget_settings doc's `ical_cache_content` + `ical_cache_generated_at` were cleared as designed (`bookingManagement.ts:199`). Throwaway booking cleaned up immediately (3 ms). No further trigger side effects (initial email skipped — `payment_method: "bank_transfer"` falls through to `atomicBooking`-owned email path per the comment at `bookingManagement.ts:238-247`; the function only logs and creates the in-app owner notification — no `emails_sent.*` write per [[onbookingcreated-no-email-tracking]]).

`onBookingStatusChange` was **not** live-tested (would send a real Resend email on pending→confirmed-with-approved_at). Static read + the 2026-05-29 07:43 log line (`[iCal Cache] Invalidated` + `Booking status changed`) prove the trigger fires; the email/idempotency branches are exercised by the email-system smokes in audit/27 + audit/34 + audit/65.

---

## 5. Findings (F-95-NN)

All findings are **logic/design** notes derived from static source read. Data probe on bookbed-dev shows 0 active exposure for the medium-impact items. None block prod cutover. None reach P0/P1 severity.

### F-95-01 — LOW · `autoCancelExpiredBookings` missing `timeZone`
`functions/src/bookingManagement.ts:93-97` declares `onSchedule({schedule: "every 24 hours", secrets: [...]})` with **no** `timeZone:` field. Cloud Scheduler falls back to UTC, anchored on the deploy moment — currently 14:26 UTC (≈ 16:26 Zagreb summer / 15:26 winter). Drift on every deploy. All sibling Croatia-targeted reminders (`checkInTomorrowReminder`, `checkOutTodayReminder`, `pendingPaymentReminder`, `biweeklySummary`, `monthlyRevenueReport`, `autoCompleteCheckedOutBookings`) explicitly set `timeZone: "Europe/Zagreb"`. **Why no fix here**: this cron only mutates booking status + sends emails; firing time relative to Zagreb users does not materially affect correctness (`payment_deadline < now` is an instant timestamp compare, not time-of-day). Suggest pin to `0 3 * * *` Zagreb at next touch.

### F-95-02 — LOW · trial CFs missing `timeZone`
`functions/src/trial/checkTrialExpiration.ts:21-28` ("Every day at 2:00 AM" per comment, but no `timeZone:` set → fires 02:00 UTC = 03:00 Zagreb summer / 04:00 winter — drift wrt comment intent). Same gap in `functions/src/trial/sendTrialExpirationWarning.ts:23-30` ("9:00 AM" per comment → fires 09:00 UTC = 11:00 Zagreb summer for "good email open rates"; the email is then 9-11 AM Zagreb, so DST swings the user-facing send time by an hour twice a year). Same correctness story as F-95-01: timestamp compares don't care, but the **send-time hint** is split. Pin both to `Europe/Zagreb` next touch.

### F-95-03 — MED · `autoCancelExpiredBookings` no external/iCal source filter
`functions/src/bookingManagement.ts:106-110` queries the collection group `bookings` for `status==pending && payment_deadline < now` and unconditionally cancels every match. Sibling `autoCompleteCheckedOutBookings` filters out external sources (`source ∈ {booking_com, airbnb, ical, external}` and `id.startsWith("ical_")`) at `completeCheckedOutBookings.ts:127-140`; this one does not. iCal-imported reservations live in `properties/{pid}/ical_events`, not `bookings`, so the *normal* exposure is zero (confirmed live: 0/0 on bookbed-dev). But if any future migration / admin tool / Stripe rescue flow writes an external booking into `bookings` with a `payment_deadline`, it will be silently cancelled at the daily run. Mirror the autoComplete filter as a one-line defensive change next touch — not urgent.

### F-95-04 — MED · `autoCompleteCheckedOutBookings` promotes unpaid pending → completed
`completeCheckedOutBookings.ts:110-114` queries `status in ["confirmed","pending"] && check_out < today` and marks all matches `completed` (`updateInBatches`, line 219-222). Semantically a `pending` booking whose stay window has fully elapsed AND that never got paid should land `cancelled`, not `completed`. Race window vs `autoCancelExpiredBookings`:
- normal case: `payment_deadline` is `created_at + 7d` → autoCancel catches it long before check_out passes → status moves to `cancelled` first; autoComplete query no longer matches → safe.
- abuse case: owner-issued long deadlines (`payment_deadline > check_out`, e.g. 30 d) or missing `payment_deadline` (compound query won't match in autoCancel → autoComplete WILL match) → booking lands `completed` despite no payment.

Probe: 0 hits on bookbed-dev today. Future-proof by adding `payment_deadline` invariant check (or restrict query to `status == "confirmed"`) next touch.

### F-95-05 — LOW · `onUnitDeleted` redundant first query
`functions/src/unitManagement.ts:106-111` does `await collectionRef.limit(BATCH_SIZE).get()` and only uses it for an `if (empty) return` early exit, then the `while (true)` loop at line 117 immediately re-queries the same collection. One extra Firestore read per subcollection per unit-delete. Dead-code cleanup at next touch; correctness unaffected.

### F-95-06 — LOW · `onBookingStatusChange` gates approval email on `after.approved_at`
`bookingManagement.ts:322`: `before.status === "pending" && after.status === "confirmed" && after.approved_at`. Any future caller that flips `pending → confirmed` *without* setting `approved_at` (e.g. an admin "force confirm" tool, or a Stripe webhook path that bypasses the standard approval flow) will silently skip the approval email and not write `emails_sent.approval`. Currently no such caller exists (the only writers are `approveBooking` callable + `atomicBooking` confirmed path, both set `approved_at`). Document constraint; do not change logic.

### F-95-07 — LOW · `newAppUpdateNotification` 1000-user cap
`scheduledPushNotifications.ts:631`: `db.collection("users").where("accountStatus","in",[trial,active,premium]).limit(1000)`. PROD with >1000 active users will silently skip notifying anyone past the cap. Not an issue today (dev: 2 trial users; PROD likely sub-1000). Forward concern; replace with paginated loop when active-user count crosses ~700.

### F-95-08 — LOW · `sendTrialExpirationWarning` excludes legacy users
`sendTrialExpirationWarning.ts:71`: `.where(warningFlag, "==", false)`. A doc missing the field is **not** matched by `==false` — Firestore treats missing-field as not-present. Trial users created **before** `onUserCreate` started initializing `trialWarning{7,3,1}Day{s}Sent: false` would never get a 7/3/1-day warning. Probe shows 0/2 dev users are missing the flag, so 100% coverage on dev today. Same can't be claimed for PROD without a separate probe — a single backfill `set({trialWarning7DaysSent: false, trialWarning3DaysSent: false, trialWarning1DaySent: false}, {merge:true})` over PROD `users where accountStatus=trial` would close the gap, but it's gated on PROD ops.

### F-95-09 — INFO · trial CFs UTC vs deploy-anchored
`sendTrialExpirationWarning.ts` schedule `"0 9 * * *"` without `timeZone:` deploys to Cloud Scheduler as UTC. **Verified live**: deployed job is `0 9 * * *` in UTC. Confirms F-95-02 root cause is **source omission**, not Cloud Scheduler quirk.

### F-95-10 — CONFIRMED · `onBookingCreated` always invalidates iCal cache
By design (`bookingManagement.ts:198`: *"Fires for ALL payment methods (Stripe-confirmed and pending alike)"*). Verified live: cache flushed within 8 s of a pending bank_transfer booking write. No bug.

---

## 6. Cleanup

- ✅ Throwaway booking `AUDIT95_throwaway_1780128914650` deleted (verified `exists=false`).
- ✅ No PROD writes (gcloud project pinned to `bookbed-dev` for the entire session).
- ✅ No turf overlap (stripePayment, subdomain, ical_feeds rules untouched).
- ✅ No CF source edits applied this session — findings are **doc-only**; fixes deferred to one of:
  - low-risk batch (F-95-01, F-95-02, F-95-05 — single touch each)
  - design follow-up (F-95-03, F-95-04 — semantics conversation needed)
  - operational (F-95-07, F-95-08 — PROD probe + backfill before any code change)

## 7. PROD-cutover relevance

None of these block PROD cutover. Severity ladder:
- 0 × P0 / P1
- 2 × MED (F-95-03, F-95-04) — both have 0 dev exposure; PROD exposure unknown, mirror probe before cutover claim
- 6 × LOW + 1 × INFO + 1 × CONFIRMED

Recommended action: add this audit to the prod-cutover backlog as an "operational follow-up after cutover" entry. None of the findings warrant gating the next merge train.
