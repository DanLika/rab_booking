# Bookings Hotfix — Partial (T11-hotfix-partial)

**Branch**: `fix/bookings-hotfix-partial`
**Date**: 2026-05-18
**Status**: rules deployed to `bookbed-dev`; functions + Flutter widget changes in-branch (not yet deployed)

## 1. Scope

Closes 2 of the 3 public-read clauses on the `bookings` read rule (audit/03-backend.md §3.4 flag #1).

- **REMOVED**: `'stripe_session_id' in resource.data && resource.data.stripe_session_id != null`
- **REMOVED**: `'booking_reference' in resource.data && resource.data.booking_reference != null`
- **KEPT**: `'unit_id' in resource.data && 'status' in resource.data` — INTENTIONALLY deferred to **T11c** (after the `getUnitAvailability` Cloud Function ships). Tracked in `audit/06-availability-cf-design.md`.

Rule edits applied in **three** locations:
1. Subcollection `properties/{p}/units/{u}/bookings/{bookingId}` (line ~160)
2. Collection-group `{path=**}/bookings/{bookingId}` (line ~258)
3. Deprecated top-level `bookings/{bookingId}` (line ~318) — included for hygiene, likely no live data

## 2. Before / after rule diff (canonical)

```diff
@@  match /properties/{propertyId}/units/{unitId}/bookings/{bookingId}  @@
         allow read: if
           isPropertyOwner(propertyId) ||
           (isAuthenticated() && resource.data.owner_id == request.auth.uid) ||
-          ('unit_id' in resource.data && 'status' in resource.data) ||
-          ('stripe_session_id' in resource.data && resource.data.stripe_session_id != null) ||
-          ('booking_reference' in resource.data && resource.data.booking_reference != null);
+          // INTENTIONAL: unit_id+status clause kept here until T11c (after
+          // getUnitAvailability CF rollout). See audit/06-availability-cf-design.md.
+          ('unit_id' in resource.data && 'status' in resource.data);
```

(Same shape applied to the CG and deprecated-top-level rules — full diff in `git diff main -- firestore.rules`.)

## 3. Flutter call-site changes

Pre-hotfix audit found **only one** direct Firestore read on bookings that hit a removed clause from the guest side:

| File:Line | Method | Status |
|---|---|---|
| `lib/features/widget/presentation/screens/booking_widget_screen.dart:1338` | `bookingRepo.fetchBookingByStripeSessionId(sessionId)` | **CHANGED** — now polls `BookingLookupService.getBookingByStripeSession(sessionId)` |
| `lib/core/services/booking_service.dart:384` | `getBookingByReference()` | **DEAD CODE** — zero call sites in `lib/`. Left in place; flagged for removal in a separate cleanup. |

The guest booking-view + cancel flows were already on `verifyBookingAccess`:
- `lib/.../screens/booking_view_screen.dart` — `BookingLookupService.verifyBookingAccess(ref, email, token)` (unchanged)
- `lib/.../providers/booking_lookup_provider.dart` — same (unchanged)
- `lib/.../widgets/details/cancel_confirmation_dialog.dart` — `guestCancelBooking` callable (unchanged)
- `lib/.../screens/booking_details_screen.dart` — receives `BookingDetailsModel` from `verifyBookingAccess` via go_router extras; no direct reads (unchanged)

### 3.1 Why a new callable instead of routing through `verifyBookingAccess`

The task brief proposed routing the Stripe-success polling through `verifyBookingAccess(bookingReference, email, accessToken)`. After auditing the Stripe redirect flow this turned out not to fit cleanly:

1. The Stripe `success_url` (`stripePayment.ts:743`) carries only `?stripe_status=success&session_id={CHECKOUT_SESSION_ID}` — no `booking_reference`, no `email`, no `access_token`.
2. The polling helper `_handleStripeReturnWithSessionId` (`booking_widget_screen.dart:1298`) has **four** call sites, three of which are cross-tab callbacks (PaymentBridge, postMessage from popup, BroadcastChannel) that pass only `sessionId`/`bookingRef` in the payload — no `email`/`token`.

Two options on the table after the orient pass (advisor was consulted at this point):

- **(A)** Bake `&ref=…&email=…&token=…` into the Stripe `success_url`. Worked for the same-tab redirect path, but does not feed the three cross-tab callbacks; would require threading `email`/`token` through `postMessage` / `BroadcastChannel` payloads in three more files — fragile.
- **(B)** Add a new callable `getBookingByStripeSession(sessionId)` that wraps the lookup in Admin SDK. One function, one call site change inside `_handleStripeReturnWithSessionId`, no URL-contract change, no token-on-postMessage exposure.

Chose (B). Diff is smaller (~80 lines of CF + ~50 lines of Flutter) and the security surface is cleaner: the `cs_xxx` Stripe session ID is itself a proof-of-purchase capability — anyone who legitimately completed checkout knows it; anyone guessing one cannot brute-force the keyspace under the 60-attempts-per-hour-per-IP rate limit baked into the new function.

### 3.2 New Cloud Function

```
functions/src/getBookingByStripeSession.ts        (new, ~140 lines)
functions/src/index.ts                            (export added)
```

- Trigger: `onCall` v2, default region
- Rate limit: 60 / hour / IP (uses existing `checkRateLimit` + `hashIp`)
- Returns the same `{success, booking: BookingDetailsModel}` shape as `verifyBookingAccess` so the Flutter side can reuse the existing model + provider.
- Returns `not-found` (treated as "webhook in flight" by the Flutter poller, not an error).

### 3.3 Flutter changes

```
lib/features/widget/presentation/providers/booking_lookup_provider.dart
    + getBookingByStripeSession(sessionId) → BookingDetailsModel?

lib/features/widget/presentation/screens/booking_widget_screen.dart
    + imports booking_lookup_provider + booking_details_model
    _handleStripeReturnWithSessionId(...):
        - bookingRepo.fetchBookingByStripeSessionId(sessionId)  (BookingModel?)
        + bookingLookupService.getBookingByStripeSession(sessionId)  (BookingDetailsModel?)
        loop now exits on details.status == 'confirmed'
        confirmation-screen params now sourced from BookingDetailsModel fields
        confirmation-screen `booking: null` (popup-window notification path
            is same-tab redirect-only; condition isPopupWindow stays false)
```

`fetchBookingByStripeSessionId` in `firebase_booking_repository.dart` is left in place — its single call site is removed but the abstract method on `BookingRepository` keeps the contract intact. Mark for cleanup in a follow-up.

## 4. Tests

### 4.1 Rules unit-test harness (new)

```
functions/test/firestore_rules/bookings.test.ts       (new)
functions/tsconfig.test.json                          (new — types: [jest, node])
functions/package.json                                (script + deps)
```

Added to `devDependencies`:
- `@firebase/rules-unit-testing: ^3.0.4`
- `firebase: ^10.14.1`
- `@types/node: ^20.11.30`

New script:
```
"test:rules": "firebase emulators:exec --only firestore --project demo-bookbed-rules 'jest --config jest.config.js --testPathPatterns=test/firestore_rules --runInBand'"
```

(Note: Jest 30 renamed `--testPathPattern` to `--testPathPatterns`.)

### 4.2 Test cases — all green

```
$ cd functions && npm run test:rules
PASS test/firestore_rules/bookings.test.ts
  bookings rule (T11-hotfix-partial)
    ✓ unauthenticated reader is DENIED on subcollection booking when clause 1 missing
    ✓ foreign authenticated uid is DENIED reading someone else's booking (clause 1 absent)
    ✓ booking owner_id ALLOWED via owner_id clause
    ✓ admin via isAdmin() custom claim ALLOWED
    ✓ admin via Firestore /users/{uid}.role=='admin' ALLOWED
    ✓ widget calendar (unit_id + status) clause STILL ALLOWS reads — kept until T11c
    ✓ authenticated stranger reading by stripe_session_id alone is DENIED (clause removed)
    ✓ authenticated stranger reading by booking_reference alone is DENIED (clause removed)

Test Suites: 1 passed, 1 total
Tests:       8 passed, 8 total
```

Note: the "widget calendar" test is the regression guard for T11c — if/when clause 1 is finally removed, that test will need to be replaced with a CF-mediated availability check, not deleted silently.

## 5. Deploy log (dev only)

```
$ firebase deploy --only firestore:rules --project bookbed-dev
=== Deploying to 'bookbed-dev'...
i  deploying firestore
✔  cloud.firestore: rules file firestore.rules compiled successfully
i  firestore: uploading rules firestore.rules...
✔  firestore: released rules firestore.rules to cloud.firestore
✔  Deploy complete!
```

**No prod deploy** — task scope explicitly excludes `rab-booking-248fc`.

## 6. Manual smoke test on dev — handoff

The interactive UI smoke tests cannot be executed from the audit session (no Flutter web instance running, no Stripe test-mode card flow). Below is the **test plan that a human (or follow-up agent) must run before this is considered safe to land on prod**, plus what was verified offline.

### 6.1 Verified offline (this session)

| Check | How | Result |
|---|---|---|
| Rules compile cleanly on dev | `firebase deploy --only firestore:rules --project bookbed-dev` | ✔ |
| Owner read still allowed (rule semantics) | rules-unit-test "booking owner_id ALLOWED via owner_id clause" | ✔ |
| Widget date picker still works (clause 1 intact) | rules-unit-test "widget calendar (unit_id + status) clause STILL ALLOWS reads" | ✔ |
| Admin (custom claim) still works | rules-unit-test "admin via isAdmin() custom claim ALLOWED" | ✔ |
| Admin (Firestore role) still works | rules-unit-test "admin via Firestore /users/{uid}.role=='admin' ALLOWED" | ✔ |
| `stripe_session_id` clause actually removed | rules-unit-test "authenticated stranger reading by stripe_session_id alone is DENIED" | ✔ |
| `booking_reference` clause actually removed | rules-unit-test "authenticated stranger reading by booking_reference alone is DENIED" | ✔ |

### 6.2 Pending — requires interactive testing on dev

Cannot run these offline. The new `getBookingByStripeSession` CF + the Flutter widget changes need to be deployed to dev first:

```
# 1. Deploy the new callable (functions deploy NOT done by this PR — scope was rules-only)
cd functions
npm run build
firebase deploy --only functions:getBookingByStripeSession --project bookbed-dev

# 2. Build + deploy the dev widget bundle
flutter build web --target=lib/widget_main_dev.dart --release \
  --dart-define=ENVIRONMENT=development -o build/web_widget
cp web/bookbed-overlay.js build/web_widget/   # see CLAUDE.md memory #21
firebase deploy --only hosting:widget --project bookbed-dev
```

Then manually exercise on `https://bookbed-widget-dev.web.app` (or whatever the dev widget origin resolves to):

| Flow | Expected | What to verify |
|---|---|---|
| Stripe-success redirect | Confirmation screen hydrates after webhook flips status | Network panel shows POST to `getBookingByStripeSession` (not direct Firestore read), polling completes within ~30 s, no `permission-denied` in console |
| Guest cancel | Loads booking via `verifyBookingAccess`, cancels successfully | Network panel shows `verifyBookingAccess` + `guestCancelBooking`, no direct Firestore CG reads |
| Widget date picker | Booked dates still render as blocked | No `permission-denied`; calendar overlay shows existing bookings (clause 1 in effect) |
| Owner dashboard | Owner sees only their bookings | Realtime listeners on `collectionGroup('bookings').where('owner_id', '==', uid)` continue streaming |

## 7. Explicit deferred work — T11c

Clause 1 (`'unit_id' in resource.data && 'status' in resource.data`) **is still public**. That is the largest remaining surface in audit/03-backend.md §3.4 flag #1 — every booking document remains readable to any caller with a Firebase API key as long as the doc has both fields (every booking does).

The plan is to replace the widget's direct `collectionGroup('bookings').where('unit_id', '==', …)` queries with a CF-mediated `getUnitAvailability` (returns a sparse blocked-dates array with **zero PII**), then drop clause 1. Design: `audit/06-availability-cf-design.md`. Tracked as **T11c**.

## 8. Risks + caveats

- **Cross-tab notification (popup/BroadcastChannel) path is rare in practice** (stripe.md says same-tab redirect is the documented flow), but the new `getBookingByStripeSession` covers it identically — both same-tab and cross-tab callers funnel into the same CF call.
- **Rate-limit pressure**: 60 lookups/hour/IP. The 15-attempt × 2 s polling loop uses 15 calls — well below the ceiling. Multiple users behind the same NAT IP in the same hour could theoretically trip it; if observed in dev, bump to 120/hour.
- **Dead code**: `firebase_booking_repository.dart::fetchBookingByStripeSessionId` and `booking_service.dart::getBookingByReference` now have zero call sites in `lib/`. Not removed in this PR (out of scope); flagged for a follow-up.
- **getBookingByStripeSession is NOT deployed by this PR**. The Flutter source change in this branch will fail at runtime on dev until the function is also deployed.
