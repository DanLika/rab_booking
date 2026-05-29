# audit/73 — Parked Findings Batch (F-67-02, F-67-03, F-67-05, F-67-06)

**Date:** 2026-05-28
**Terminal:** H (autonomous)
**Source:** [audit/67](./67-chrome-deepflow-2026-05-28.md)
**Branch base:** `main` (`ceaad693`)

## Result table

| Finding | Severity | PR    | Branch                              | Status            | Verification                          |
|---------|----------|-------|-------------------------------------|-------------------|---------------------------------------|
| F-67-02 | P2       | #537  | `fix/f-67-02-guest-name`            | Fixed (dev-data class) | `flutter analyze` clean; booking_model_test 60/60 |
| F-67-03 | P2       | #538  | `fix/f-67-03-widget-form-leak`      | **Partial** — notes-leak closed; non-notes residue within 15min on shared browser still possible | `flutter analyze` clean; booking_form_state_test 23/23 |
| F-67-05 | P3       | #539  | `fix/f-67-05-ical-error-leak`       | Fixed             | `npm run build` clean; icalSync.test.ts 25/25 (incl. new regression) |
| F-67-06 | P3       | —     | —                                   | **Not a bug**     | Closed as test artifact of F-67-04    |

All PRs left open for review. No PROD deploys. F-67-05 has an unchecked dev-deploy box in its PR description.

## Per-fix detail

### F-67-02 — display guest first+last name instead of "Unknown Guest"

**File:** `lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart` (+16 lines)

**Approach:** Display-side fix only. New private static helper `_backfillGuestName(Map data)` consults `guest_first_name` + `guest_last_name` keys when `guest_name` is missing or empty, and mutates `data['guest_name']` to the composed value **before** `BookingModel.fromJson` runs.

Applied at the two raw-data entry points:
- `_bookingFromDoc` — handles the primary list query + all 10 callers
- `getOwnerBookingById` — single-booking deep-link path

No Firestore writeback, no migration, no `BookingModel` schema change. Bookings with a usable `guest_name` are untouched.

**Why this location:** Both call sites already mutate the raw Firestore map (to extract `property_id` from the document path). Adding the helper there keeps the contract `BookingModel.guestName` non-empty whenever the doc has *any* usable guest-name data. The widget-only `firebase_owner_bookings_repository.dart` iCal-events branch (line 632) was intentionally left alone — that path constructs pseudo-bookings from `ical_events` docs, which legitimately have only an `External Booking` fallback.

**Source of the split-field docs:** `scripts/seed-bookbed-dev.js` lines 280–281 and 462–463 — the dev seed writes `guest_first_name` / `guest_last_name` *without* the canonical `guest_name`, and that's what audit/67 observed. Production CFs (`atomicBooking`, `stripePayment`, `icalSync`, `deleteUserAccount`) all write `guest_name` — confirmed via repo-wide grep. The fix is therefore dev-data-relevant (closes the audit observation) + defensive against future drift. A seed-script cleanup is out of scope for this PR (touches data layer, not display).

### F-67-03 — stop persisting special requests; tighten draft TTL (PARTIAL)

**Files:**
- `lib/features/widget/state/booking_form_state.dart` (+8)
- `lib/features/widget/services/form_persistence_service.dart` (+18/−2; two commits — 60min then 15min after advisor pushback)
- `test/features/widget/state/booking_form_state_test.dart` (+8/−2)

**Approach:** Two defenses against the audit/67 observation that a prior session's Special Requests text (with an old `pt:alert(document.cookie)` XSS fragment) reappeared on a fresh widget mount:

1. `BookingFormState.toPersistedFormData` writes `notes: ''` instead of the live controller text. The specific field observed leaking is now fully closed.
2. `PersistedFormData.isExpired` lowered `24h → 15min`. Tightens but does not eliminate the shared-browser cross-visitor window for non-notes fields.

**What is NOT addressed:** The audit spec explicitly mentioned namespace-per-session as the proper fix. This PR does **not** implement that. A returning visitor on the same browser within 15min on the same unit will still inherit names / email / phone from the prior user. Fully fixing this requires:
- Web: switch storage backend from `SharedPreferences` (which uses `localStorage`) to `window.sessionStorage` via dart:js_interop or html package
- Native: distinct origin / sandboxed prefs per session

That's a `SharedPreferences` refactor — bigger surface, real risk of breaking other consumers, deferred. The 15min ceiling is the narrowest mitigation that doesn't break refresh / return-from-Stripe resume.

Tests assert notes do NOT round-trip through persistence (regression).

**Security framing:** Leaked fragment was an old XSS test payload — SF-014 input sanitization renders such payloads inert. This is a privacy/hygiene leak (cross-session PII visibility), not an active XSS regression.

### F-67-05 — sanitize iCal sync error message

**Files:**
- `functions/src/icalSync.ts` (+19/−4)
- `functions/test/icalSync.test.ts` (+40)

**Approach:** Outer `syncIcalFeedNow` catch echoed the raw upstream `Error.message` back to the client (`"Sync failed: " + errorMessage`), surfacing upstream host + status. Now:

- Outer catch returns a generic, owner-actionable string: *"Sync failed. Verify the feed URL is reachable and points to a valid iCal feed."* Server-side `logError` is unchanged, so Sentry + Cloud Logging still see the full upstream message.
- Known-safe inner errors (`validateIcalUrl` failure, missing `BEGIN:VCALENDAR` header) converted from `throw new Error(...)` to `throw new HttpsError("failed-precondition", ...)`. The outer catch's existing `if (error instanceof HttpsError) throw error;` then re-throws them unchanged, so the owner UI still gets the specific (and safe) reason.

**Regression test:** mocks `https.get` to throw `connect ECONNREFUSED ical.booking.com:443`, asserts the response message contains neither `ical.booking.com` nor `ECONNREFUSED`. Uses `mockResolvedValueOnce` only for the two doc reads that fire before `fetchIcalData` throws — leaving extra `Once` queue entries leaked into the subsequent `scheduledIcalSync` test (caught during local CI; fixed by trimming the queue).

**Region note:** `syncIcalFeedNow` is `onCall(...)` with no explicit `region`. Defaults to `us-central1`. The CLAUDE.md memory line listing it under eu-west1 looks stale; confirm before dev-deploy. Deploy command in PR description uses the function-only form so region is auto-detected.

### F-67-06 — slug autofill "c" — **NOT A BUG**

**Verdict:** Test artifact of [F-67-04](./67-chrome-deepflow-2026-05-28.md) — Flutter web `fill()` drops 1–5 leading characters. The slug generator in `lib/core/utils/slug_utils.dart` is correct.

**Evidence:**

1. Generator logic (`generateSlug` lines 53–94): lowercase → char replacements → space-to-hyphen → non-alphanumeric strip → collapse multi-hyphens → trim. Standard, no `[0]` indexing or split-and-take-first weirdness.
2. Hand-traced `"C-Retest Unit BB 2026-05-28"`:
   - lowercase: `"c-retest unit bb 2026-05-28"`
   - whitespace→hyphen: `"c-retest-unit-bb-2026-05-28"`
   - non-alphanumeric strip: `"c-retest-unit-bb-2026-05-28"`
   - result: `"c-retest-unit-bb-2026-05-28"` ✓
3. Existing tests (`test/core/utils/slug_utils_test.dart`) cover: basic, Croatian special chars, special-char strip, consecutive-hyphen collapse, max-length truncation, empty input. None regress.
4. Audit observation of `"c"` exactly matches the single character `"C"` — which is what would land in the name controller if F-67-04's leading-char drop ate everything after.

**Closed without code change.** Reopening this finding requires a non-`fill()` repro (e.g. real keyboard typing through Marionette or Playwright `pressSequentially`) that still produces a degenerate slug.

A defensive min-length guard (e.g. append `unitId` fragment if `slug.length < 3`) was considered and rejected: it would also degrade the legitimate case of intentionally short unit names (e.g. `"A1"`, `"P3"`) without closing any real bug.

## Branch / workflow notes

- All branches created off `main` `ceaad693`. None stacked.
- Mid-batch race observed: a parallel terminal (G — `fix/owner-cancel-booking`) swapped the active branch between `git add` and `git commit` on F-67-03, hitting `fatal: cannot lock ref 'HEAD'`. Recovery: `git stash -u` the staged files → `git checkout` correct branch → `git stash pop` → re-stage → commit. Captured in `memory/multi-agent-git-race.md`.
- F-67-06 branch created and immediately deleted (zero commits) once the test-artifact verdict was reached.
- Foreign drift parked: `functions/src/bookingActions.ts`, `functions/src/guestCancelBooking.ts`, `functions/src/utils/bookingRefund.ts` (Terminal D + G's turf). Not staged in any commit; left in working tree.

## Verification matrix

| Check                          | F-67-02 | F-67-03 | F-67-05 |
|--------------------------------|---------|---------|---------|
| `flutter analyze` clean        | ✅       | ✅       | n/a     |
| Touched-test green             | 60/60   | 23/23   | 25/25   |
| `npm run build` (functions)    | n/a     | n/a     | ✅       |
| Manual smoke on dev            | ❌ todo  | ❌ todo  | ❌ todo  |
| PROD deploy                    | ❌ no    | ❌ no    | ❌ no    |

## Open items for follow-up

- Smoke F-67-02 + F-67-03 on bookbed-dev once Terminal D / G land their changes (avoid post-merge surprises if those flows hit guest-name / form code).
- Dev-deploy F-67-05 + smoke a malformed feed to confirm response no longer carries upstream host. Region check via `gcloud functions describe syncIcalFeedNow --gen2 --project bookbed-dev` before deploy.
- audit/67 P1 (F-67-01) is being handled separately on `fix/f-67-01-booking-confirm-reject` (PR landed `ca309fe2`); audit/67 F-67-04 Flutter-web `fill()` char-drop is a test-harness gotcha not a product bug, no fix planned.
