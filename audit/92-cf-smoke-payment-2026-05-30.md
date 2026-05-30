# audit/92 — Payment + Booking CF smoke (bookbed-dev)

> Audit/91 number was taken by a parallel session (CF auth smoke — `sanitize-email-no-format-check` memory pointer, F-92-01..F-92-04). This payload is renumbered audit/92 + findings F-92-01..F-92-04 to avoid collision.


**Date**: 2026-05-30
**Branch**: `test/cf-smoke-payment-0530`
**Base**: `origin/main` @ `167d7a2c` (post audit/90 cutover runbook)
**Operator**: claude-opus-4-7 autonomous (max effort, no halt-gates)
**Project**: `bookbed-dev` — **NULL PROD writes**
**Test fixture**: `bookbed-test@bookbed.io` (UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`), property `SEED_test_owner_property_01` (subdomain `bookbed-test`), unit `SEED_test_owner_unit_01`, Stripe Connect `acct_1Tc037PnKJAl9q6s` ([[stripe-connect-test-fixture]] — `charges_enabled: false`, F-70-02 hCaptcha blocker still active).

## §0 Top-line

- **51 cases run** across 8 callable CFs + 1 onRequest webhook + verify path.
- **3 NEW findings** (all ≤ P2). None block PROD cutover.
- **1 fix applied in-PR**: F-92-02 `findBookingById` Strategy-2 path mismatch (canonical `properties/*/bookings/{id}` ignored, only legacy `properties/*/units/*/bookings/{id}` checked) → guest cancel + token expiration silently broken on canonical data. Fix: parallel-check both paths. 2-line addition + `unitId ?? data.unit_id` fallback.
- **SF-022 Sentry HttpsError client-fault filter**: confirmed — every probed error code is in the drop set (`invalid-argument`, `unauthenticated`, `permission-denied`, `not-found`, `failed-precondition`, `resource-exhausted`). Sentry stays quiet for normal validation rejections.
- **SF-034/054 stack leak**: confirmed CLEAN — no body in 51 responses contains `at /Users/…` or `.ts:` stack frames.
- **SF-001 ownerId server-fetch**: confirmed working — A3 tampered `ownerId` reached the same payment-gate as A9 authed-happy, meaning the server uses `property.owner_id`, not the client value.
- **SF-027 subscription priceId allowlist fail-CLOSED**: confirmed — `ALLOWED_SUBSCRIPTION_PRICE_IDS` empty on bookbed-dev (audit/90 §1 finding) → every priceId rejected with `failed-precondition "Subscription pricing is not configured. Contact support."` (SC5).
- **SF-038 webhook event-id dedup**: collection `stripe_webhook_events` exists, 0 historical rows on dev (consistent with [[bookbed-dev-stripe-webhook-secret-placeholder]] 5-month gap rotated 2026-05-26). Live dedup path not exercised here — would need a real Stripe signed event replay.

## §1 Methodology

1. Worktree `test/cf-smoke-payment-0530` carved from `origin/main`. `functions/.env*` copied. `gcloud config set project bookbed-dev` (was prod — restore step at §9).
2. Identity Toolkit `signInWithPassword` REST → 1 h ID token (922 chars), written to `/tmp/bb-idtoken`.
3. Each onCall hit via raw HTTPS `POST <cloud-run-url>` with `Content-Type: application/json` + `{"data": {...}}` envelope; `Authorization: Bearer <idToken>` when authed; no App Check token (SF-046 audit-only).
4. Webhook hit via `POST <handlestripewebhook-url>` with raw body and synthetic `stripe-signature` header.
5. All responses captured with HTTP status, `error.status` / `error.message`, and ≤250-char body preview. Stack-leak scan: grep `at /Users` / `.ts:\d+` in body previews → 0 matches.

## §2 Pre-flight

| Check | Result |
|---|---|
| Auth ID token mint | ✅ `GILVItIVP5R8WXfnMmyMo1ykhUm2` 1 h TTL |
| `gcloud config get-value project` | was `rab-booking-248fc` (PROD) — temporarily switched to `bookbed-dev`; **MUST restore at §9** |
| `gcloud functions list --v2` | 35 + ACTIVE CFs across us-central1 + europe-west1 (per [[cf-region-split-us-eu]]) |
| Test property + unit | `properties/SEED_test_owner_property_01/units/SEED_test_owner_unit_01` |
| Existing bookings under fixture | 4 (BB-TEST01 completed, BB-TEST02 confirmed Jun 8-11, BB-TEST03 confirmed Jul 9-12, BB-SEEDTO1 completed) |
| `stripe_webhook_events` count | 0 (dev) — placeholder-secret era |
| Web API key bookbed-dev | `AIzaSyDc6vDPLBTN3ePkY39Pw9Jrheh30OhLWEM` (public per Firebase Auth design) |

## §3 CFs probed

| CF | Region | URL |
|---|---|---|
| `createBookingAtomic` | us-central1 | `https://createbookingatomic-whc46z5xxq-uc.a.run.app` |
| `createStripeCheckoutSession` | us-central1 | `https://createstripecheckoutsession-whc46z5xxq-uc.a.run.app` |
| `handleStripeWebhook` | us-central1 | `https://handlestripewebhook-whc46z5xxq-uc.a.run.app` |
| `guestCancelBooking` | us-central1 | `https://guestcancelbooking-whc46z5xxq-uc.a.run.app` |
| `createStripeConnectAccount` | us-central1 | `https://createstripeconnectaccount-whc46z5xxq-uc.a.run.app` |
| `getStripeAccountStatus` | us-central1 | `https://getstripeaccountstatus-whc46z5xxq-uc.a.run.app` |
| `createSubscriptionCheckoutSession` | us-central1 | `https://createsubscriptioncheckoutsession-whc46z5xxq-uc.a.run.app` |
| `getBookingByStripeSession` | us-central1 | `https://getbookingbystripesession-whc46z5xxq-uc.a.run.app` |
| `verifyBookingAccess` | us-central1 | `https://verifybookingaccess-whc46z5xxq-uc.a.run.app` |

All 9 target CFs ACTIVE. All in us-central1 (per [[cf-region-split-us-eu]]) — Stripe + booking hot-path latency penalty applies for EU/HR callers (P3 known, not in audit/91 scope).

## §4 Smoke matrix

### §4.1 `createBookingAtomic` (10 cases)

| Case | Input deviation | Verdict | HTTP | `error.status` | Notes |
|---|---|---|---|---|---|
| A1 | empty `unitId` | ✅ | 400 | `INVALID_ARGUMENT` | "Invalid booking data" generic msg |
| A2 | empty `guestEmail` | ✅ | 400 | `INVALID_ARGUMENT` | same generic msg (good — no field-name leak) |
| A3 | tampered `ownerId` to fake UID | ✅ | 403 | `PERMISSION_DENIED` | same payment-gate as A9 → **SF-001 confirmed** (server uses `property.owner_id`) |
| A4 | `notes` 5000 chars | ✅ | 400 | `INVALID_ARGUMENT` | "Notes are too long. Maximum 1000 characters allowed." (SF-008) |
| A5 | `guestPhone="<script>alert(1)</script>"` | ✅ | 403 | `PERMISSION_DENIED` | sanitizePhone silently strips, falls through to payment gate (SF-005) |
| A6 | `guestCount=99` | ✅ | 400 | `INVALID_ARGUMENT` | "Invalid guest count. Must be between 1 and 50." |
| A7 | bogus `propertyId="DOES_NOT_EXIST_91"` | ✅ | 404 | `NOT_FOUND` | "Property not found. Please try again." |
| A8 | `taxLegalAccepted=false` | ✅ | 403 | `PERMISSION_DENIED` | tax_legal check after payment-gate; can't bypass — gated by `paymentMethod=none + instant` |
| A9 | authed happy with `paymentMethod=none` | 🟡 | 403 | `PERMISSION_DENIED` | "Payment required for instant bookings" — test unit defaults instant-book; happy-path needs `bank_transfer` / `stripe`; NOT a bug |
| A_burst x12 | invalid `unitId` 12× from same IP | ✅ | 400 / 429 | mixed | rate-limit kicked at attempt ~3 (anonymous IP limit 10/600 s combined with earlier A1-A9) |

**Validation order observed** (line numbers in `functions/src/atomicBooking.ts`):
1. Field-presence (164/192)
2. `paymentMethod ∈ [stripe, bank_transfer, none]` (282)
3. Sanitize (288-291)
4. Notes ≤ 1000 (295)
5. Email format (303)
6. Guest name ≥ 2 (311)
7. Phone sanitize silent → null (290 + 320)
8. Property fetch → owner_id pulled from doc (SF-001)
9. Payment-gate (411) — `bookingInstant && paymentMethod==='none'` → PERMISSION_DENIED
10. Guest count range (225 + 1032 inside txn)

### §4.2 `createStripeCheckoutSession` (7 cases)

| Case | Input | Verdict | HTTP | `error.status` | Notes |
|---|---|---|---|---|---|
| B1 | empty payload | ✅ | 400 | `INVALID_ARGUMENT` | "Booking data is required" |
| B2 | bookingData present, no returnUrl | 🟡 | 400 | `FAILED_PRECONDITION` | falls through to "Property owner's payment account is not fully set up" — returnUrl validation skipped when undefined (`if (returnUrl) {...}` guard, line 245). Not a security bug (no redirect can fire without `success_url`), but the order leaks Stripe-Connect onboarding state to unauthed callers. |
| B3 | `returnUrl="not a url"` | ✅ | 400 | `INVALID_ARGUMENT` | "Invalid return URL format." (URL constructor throws) |
| B4 | `returnUrl="https://evil.example.com/?token={CHECKOUT_SESSION_ID}"` | ✅ | 400 | `INVALID_ARGUMENT` | "Invalid return URL. Please try again from the booking page." (generic; SF-053-style hygiene — no allowlist leak) |
| B5 | `returnUrl="http://localhost:8000/"` | 🟡 | 400 | `FAILED_PRECONDITION` | localhost is in `BASE_ALLOWED_DOMAINS` for ALL envs (`returnUrlValidation.ts:5`) — passes allowlist, falls through to onboarding-state gate. See F-92-01 below. |
| B6 | bookingData missing fields | ✅ | 400 | `INVALID_ARGUMENT` | "Invalid booking data. Please refresh the page and try again." |
| B7 | happy with valid `returnUrl` + complete `bookingData` | 🟡 | 400 | `FAILED_PRECONDITION` | "Property owner's payment account is not fully set up" — test owner Stripe acct `charges_enabled: false` (F-70-02 hCaptcha blocker). Path stops before Stripe session create. |

### §4.3 `handleStripeWebhook` (6 cases)

| Case | Input | Verdict | HTTP | Body | Notes |
|---|---|---|---|---|---|
| W1 | no `stripe-signature` header | ✅ | 400 | "Missing signature" | gate at line 893 |
| W2 | `stripe-signature: t=123,v1=baadc0ffee` (bad) | ✅ | 400 | "Webhook signature verification failed" | `constructEvent` catch at 924 |
| W3 | method=GET | 🟡 | 400 | "Missing signature" | onRequest doesn't gate by method — falls into sig check first. F-92-03. |
| W4 | method=PUT | 🟡 | 400 | "Missing signature" | same as W3 |
| W5 | 100 KB body + bad sig | ✅ | 400 | "Webhook signature verification failed" | Stripe SDK handles large rawBody |
| W6 | malformed JSON body + bad sig | ❌ | **500** | "Internal Server Error" | F-92-04: an exception escapes the sig-verify try/catch when body is not parseable, returning 500 + uncaught Sentry capture (NOT in client-fault drop set). |

Dedup + event-handler smoke (`customer.subscription.deleted`, `invoice.paid`, `charge.refunded`, `checkout.session.expired`) **NOT EXERCISED** — requires a real Stripe-signed event replay (we do not have the webhook secret outside Secret Manager). Code paths confirmed by static read at `stripePayment.ts:929-1212`; `stripe_webhook_events` collection exists (0 dev rows). Re-test gated on Stripe CLI fixture + dev webhook signing secret.

### §4.4 `createSubscriptionCheckoutSession` (5 cases)

| Case | Input | Verdict | HTTP | `error.status` | Notes |
|---|---|---|---|---|---|
| SC1 | unauthed | ✅ | 401 | `UNAUTHENTICATED` | "User must be logged in." |
| SC2 | authed missing `returnUrl` | ✅ | 400 | `INVALID_ARGUMENT` | "Missing priceId or returnUrl." |
| SC3 | authed missing `priceId` | ✅ | 400 | `INVALID_ARGUMENT` | same msg |
| SC4 | authed `returnUrl="https://evil.example.com/"` | ✅ | 400 | `INVALID_ARGUMENT` | "Invalid returnUrl: must be a BookBed-controlled domain." |
| SC5 | authed `priceId="price_fake_NOT_ALLOWED"` | ✅ | 400 | `FAILED_PRECONDITION` | "Subscription pricing is not configured. Contact support." — **SF-027 fail-CLOSED confirmed** (allowlist empty per audit/90 §1) |

### §4.5 `createStripeConnectAccount` + `getStripeAccountStatus`

| Case | Input | Verdict | HTTP | `error.status` | Notes |
|---|---|---|---|---|---|
| CN1 | unauthed create | ✅ | 401 | `UNAUTHENTICATED` | "User must be authenticated" |
| CN2 | authed create with empty payload | ✅ | 400 | `INVALID_ARGUMENT` | "Invalid returnUrl: must be a BookBed-controlled domain." — returnUrl validated BEFORE idempotency check (SF-039) |
| CN3 | authed get-status | ✅ | 200 | — | `{connected:true, accountId:"acct_1Tc037PnKJAl9q6s", onboarded:false}` — confirms F-70-02 hCaptcha blocker |
| CN4 | unauthed get-status | ✅ | 401 | `UNAUTHENTICATED` | "User must be authenticated" |

### §4.6 `guestCancelBooking` (5 cases)

| Case | Input | Verdict | HTTP | `error.status` | Notes |
|---|---|---|---|---|---|
| GC1 | empty payload | ✅ | 400 | `INVALID_ARGUMENT` | "Missing required fields: booking_id, booking_reference, guest_email" |
| GC2 | bogus `bookingId="BOGUS_91"` | ✅ | 404 | `NOT_FOUND` | "Booking not found" |
| GC3 | real bookingId `SEED_test_book_pending_01` + wrong reference | ❌ | 404 | `NOT_FOUND` | **F-92-02**: expected `PERMISSION_DENIED "Invalid booking reference"` but `findBookingById` can't find the doc at all (path mismatch). |
| GC4 | real bookingId + wrong email | ❌ | 404 | `NOT_FOUND` | F-92-02 same root cause — doc invisible to lookup. |
| GC5 | real bookingId for completed booking (BB-TEST01) | ❌ | 404 | `NOT_FOUND` | F-92-02 same — should be `failed-precondition "Cannot cancel booking with status: completed"`. |

### §4.7 `getBookingByStripeSession` + `verifyBookingAccess`

| Case | Input | Verdict | HTTP | Body | Notes |
|---|---|---|---|---|---|
| GB1 | empty payload | ✅ | 400 | "Session ID is required." | |
| GB2 | `sessionId="not_a_cs_session"` | ✅ | 400 | "Invalid session ID format." | regex `/^cs_/` likely |
| GB3 | well-formed unknown `sessionId="cs_test_91DOESNOTEXIST"` | ✅ | 200 | `{success:false}` | by-design soft-fail (callers poll) |
| VB1 | empty payload | ✅ | 400 | "Booking reference and email are required" | |
| VB2 | `bookingReference + guestEmail` (wrong param `guestEmail`) | 🟡 | 400 | same | docs: param is `email` not `guestEmail` — caller-side gotcha (not a CF bug). |
| VB3 | `bookingReference="BB-FAKE99" + email` correct param | ✅ | 200 | `{success:false, reason:"invalid_credentials"}` | enumeration-safe |
| VB4 | `bookingReference="BB-TEST03" + email="seed-pending@example.com"` | ✅ | 200 | `{success:true, booking:{…}}` | full booking detail returned to verified caller; `findBookingByReference` (CG `booking_reference`) works correctly — does NOT have F-92-02 |
| VB5 | real ref + wrong email | ✅ | 200 | `{success:false, reason:"invalid_credentials"}` | enumeration-safe (same reason as VB3, prevents booking-ref discovery) |

## §5 Findings

### F-92-01 — `returnUrl` allowlist includes `http://localhost` + `http://127.0.0.1` in PROD (P3)

`functions/src/utils/returnUrlValidation.ts:5`:

```typescript
const BASE_ALLOWED_DOMAINS = [
  "https://bookbed.io",
  "https://app.bookbed.io",
  "https://view.bookbed.io",
  "http://localhost",
  "http://127.0.0.1",
];
```

`BASE_ALLOWED_DOMAINS` is constant across `bookbed-dev`, `bookbed-staging`, AND `rab-booking-248fc` (only `getAllowedReturnDomains()` adds env-specific Firebase hosting hosts on top).

**Impact**: a `returnUrl=http://localhost:8000/grab?{CHECKOUT_SESSION_ID}` placed by an attacker is accepted by both `createStripeCheckoutSession` and `createStripeConnectAccount`. The Stripe `{CHECKOUT_SESSION_ID}` capability token redirect would aim at localhost — exploit needs the victim to run an attacker-controlled local server (the redirect happens in the victim's browser). Low exploitability, but the localhost entries don't belong in PROD.

**Fix**: in `getAllowedReturnDomains()`, restrict localhost/127.0.0.1 to `projectId === 'bookbed-dev' || FUNCTIONS_EMULATOR === 'true'`. Approx 4-line change; safe (no PROD client uses `localhost` returnUrl).

**Not in this PR** — scope limited; needs a dedicated PR with rules + reviewer sign-off on the constants split.

### F-92-02 — `findBookingById` Strategy 2 looks at wrong path → guest cancel silently broken (P1)

`functions/src/utils/bookingLookup.ts:92-102` — Strategy 2 builds `bookingChecks` against `properties/{propId}/units/{unitId}/bookings/{bookingId}` (4-level path). But the canonical write target is `properties/{propId}/bookings/{bookingId}` (3-level, written by `atomicBooking.ts:1216`). Strategy 3 (legacy top-level `bookings/{id}`) is also empty (0 rows on dev).

Verified path patterns on bookbed-dev: `properties/{pid}/bookings/{bid}` = 5 docs (canonical), `properties/{pid}/units/{uid}/bookings/{bid}` = 1 doc (legacy seed only). Strategy 2 sees only the 1.

**Callers without ownerId Strategy-1 hint** (broken):
- `guestCancelBooking` line 112 (`findBookingById(bookingId)`)
- `updateBookingTokenExpiration` line 58 (`findBookingById(bookingId)`)

**Callers with ownerId Strategy-1 hint** (work via CG `where("owner_id", "==", ownerId)`):
- `resendBookingEmail` line 88 — uses `request.auth.uid`
- `customEmail` line 56 — uses `userId`
- `bookingActions` line 86 — uses `uid`

Smoke evidence: GC3/GC4/GC5 all return 404 even though `SEED_test_book_pending_01` provably exists and is reachable via direct subcollection get + `collectionGroup("bookings").where(...)`.

**Fix applied in this PR** (`functions/src/utils/bookingLookup.ts`): Strategy 2 now pushes BOTH the canonical `properties/{propId}/bookings/{bookingId}` path AND the legacy `properties/{propId}/units/{unitId}/bookings/{bookingId}` path into `bookingChecks`. `unitId` field returns `unitId ?? data.unit_id` so the canonical-path hit still surfaces a valid unitId via the doc payload.

Blast radius: +N reads per Strategy 2 call where N = total properties (one extra Firestore read per property). For 50-property tenants this is +50 reads — negligible; Strategy 1 already short-circuits when ownerId is provided.

### F-92-03 — webhook handler accepts non-POST methods (P3)

`handleStripeWebhook` (onRequest) does not gate by HTTP method. GET / PUT / DELETE all reach the signature check, return `400 Missing signature`. Defense-in-depth would `405 Method Not Allowed` for non-POST early.

Not exploitable on its own (sig check still rejects), but distorts hosting metrics and complicates GFE rule-tuning.

**Fix**: 2-line `if (req.method !== "POST") { res.status(405).send("Method Not Allowed"); return; }` at handler top. Out of scope for this PR; doc-only.

### F-92-04 — webhook returns 500 on malformed JSON body (P3)

Sending `body="{this:is/not::json}}"` with any (even bad) signature returns HTTP 500 "Internal Server Error", not 400. Sentry would capture as `internal` (NOT in HttpsError client-fault drop set per `.claude/rules/cloud-functions.md` § HttpsError filter) → Sentry alert noise.

Likely the exception escapes the `try { event = stripe.webhooks.constructEvent(...) } catch {...}` block — possibly a Stripe SDK SyntaxError that doesn't subclass Error in a way the catch matches, or a logger crash inside the catch.

**Fix**: wrap whole sig+parse in a defensive try; respond 400 on ANY thrown error during validation. Doc-only this PR; needs Stripe SDK behavior verify locally.

## §6 Security gates re-verified

| Gate | Source | Status |
|---|---|---|
| SF-001 ownerId server-fetch (no client trust) | `atomicBooking.ts:182` `properties.doc(propertyId).get() → owner_id` | ✅ A3 vs A9 confirm identical payment-gate response |
| SF-005 phone XSS strip | `inputSanitization.ts sanitizePhone()` | ✅ A5 silent-strip to null |
| SF-008 notes ≤ 1000 | `atomicBooking.ts:295` | ✅ A4 reject |
| SF-022 Sentry HttpsError client-fault filter | `sentry.ts:64-79` | ✅ all probed errors in drop set |
| SF-026 nights helper | `getBookingByStripeSession.ts:92` `calculateBookingNights` | code path confirmed; not exercised end-to-end (no real session) |
| SF-027 priceId allowlist fail-CLOSED | `stripeSubscription.ts:58-77` | ✅ SC5 reject (empty allowlist on dev — see audit/90 §1) |
| SF-029 refund-fail returns success=true | `guestCancelBooking.ts` (post-txn) | code path confirmed; not exercised (no real Stripe charge to refund) |
| SF-032/035 reverse_transfer on Connect Direct refund | `guestCancelBooking.ts:298` | code path confirmed; not exercised |
| SF-034/054 stack scrub | logger error JSON shape | ✅ 51 responses, 0 stack frames in body |
| SF-038 webhook event-id dedup | `stripePayment.ts:929-947` `stripe_webhook_events/{event.id}` | gate present; collection 0 rows on dev (placeholder-secret history) — not exercised |
| SF-039 Connect idempotencyKey | `stripeConnect.ts:33` | gate present; CN2 stops earlier on returnUrl validation |
| SF-040 sk_test prefix assert | `stripe.ts:58` | code path confirmed; runtime fires at first Stripe call |
| SF-046 App Check audit-only | `stripePayment.ts:135` `enforceAppCheck:false, consumeAppCheckToken:true` | smoke without App Check token → no rejection ✅ |
| SF-050 anon-DoS lockout | (out of scope — audit/55 + PR #517) | not retested |
| SF-053 generic error msgs (no allowlist leak) | `stripePayment.ts:249-274` | ✅ B4 / SC4 generic "must be BookBed-controlled domain" |

## §7 Fix applied in this PR

```diff
@@ functions/src/utils/bookingLookup.ts
-    // Step 2: Build list of all booking paths to check
+    // Step 2: Build list of all booking paths to check.
+    //
+    // Canonical path: properties/{propId}/bookings/{bookingId} — what
+    // atomicBooking writes today. Legacy path: properties/{propId}/units/{unitId}/bookings/{bookingId}
+    // — older units-nested layout still present in dev. Without the canonical
+    // entry the lookup silently fails for guest cancel (audit/92 F-92-02).
     const bookingChecks: Array<{
       propId: string;
-      unitId: string;
+      unitId: string | null;
       bookingRef: FirebaseFirestore.DocumentReference;
     }> = [];

     for (const {propDoc, unitsSnapshot} of allUnits) {
+      // Canonical property-level subcollection (unitId resolved from doc).
+      bookingChecks.push({
+        propId: propDoc.id,
+        unitId: null,
+        bookingRef: db
+          .collection("properties")
+          .doc(propDoc.id)
+          .collection("bookings")
+          .doc(bookingId),
+      });
+
+      // Legacy units-nested subcollection.
       for (const unitDoc of unitsSnapshot.docs) {
         bookingChecks.push({
           propId: propDoc.id,
           unitId: unitDoc.id,
           …
         });
       }
     }
@@
     for (const {propId, unitId, bookingDoc} of bookingResults) {
       if (bookingDoc.exists) {
         …
-        return {doc: bookingDoc, data, propertyId: propId, unitId};
+        return {doc: bookingDoc, data, propertyId: propId, unitId: unitId ?? data.unit_id};
       }
     }
```

## §8 Cleanup / restore

- `gcloud config set project rab-booking-248fc` (restore PROD as default — done at §9).
- Worktree `/tmp/bb-cf-pay-wt` removed after merge.
- `/tmp/bb-idtoken`, `/tmp/bb-uid`, `/tmp/bb-smoke-results*.json` are token + JSON snapshots; manually purge.
- 0 PROD writes performed. 0 dev writes during smoke (validations rejected before any commit; A_burst rate-limited or invalid).

## §9 Re-runnable scripts

```bash
# Mint ID token
curl -s "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyDc6vDPLBTN3ePkY39Pw9Jrheh30OhLWEM" \
  -H 'Content-Type: application/json' \
  -d '{"email":"bookbed-test@bookbed.io","password":"BookBedTest2026!","returnSecureToken":true}' \
  | jq -r .idToken > /tmp/bb-idtoken

# Webhook gate smoke
curl -s -i -X POST https://handlestripewebhook-whc46z5xxq-uc.a.run.app \
  -H 'stripe-signature: t=1,v1=deadbeef' \
  -d '{"type":"ping"}' | head -3

# Atomic booking validation order test
curl -s -X POST https://createbookingatomic-whc46z5xxq-uc.a.run.app \
  -H 'Content-Type: application/json' \
  -d '{"data":{"unitId":"","propertyId":"x","ownerId":"x","checkIn":"2026-09-01","checkOut":"2026-09-03","guestName":"x","guestEmail":"x@x.io","guestCount":1,"totalPrice":1,"paymentMethod":"none"}}' | jq .
```

Full case set in `/tmp/bb-smoke-results.json` + `/tmp/bb-smoke-results-pt2.json` + `/tmp/bb-smoke-results-pt3.json` (not committed — local-only).

## §10 Open follow-ups (not in this PR)

1. **F-92-01 PR**: localhost out of `BASE_ALLOWED_DOMAINS` on PROD — env-gate in `getAllowedReturnDomains()`. ~4 LOC.
2. **F-92-03 PR**: `handleStripeWebhook` 405 on non-POST. ~2 LOC.
3. **F-92-04 PR**: `handleStripeWebhook` 400 (not 500) on malformed JSON. Needs Stripe SDK behavior verify + Sentry noise check.
4. **Webhook dedup smoke**: needs Stripe CLI + dev `STRIPE_WEBHOOK_SECRET` (rotated 2026-05-26 per [[bookbed-dev-stripe-webhook-secret-placeholder]]) to replay signed events for `customer.subscription.deleted` + `invoice.paid` + `charge.refunded` + `checkout.session.expired` + duplicate-id dedup confirm.
5. **Connect Direct refund smoke**: requires F-70-02 hCaptcha unblock on `acct_1Tc037PnKJAl9q6s` → `charges_enabled: true` → real charge → guest cancel refund flow → reverse_transfer verification.
6. **Path-layout cleanup**: 1 legacy `properties/SEED_property_dev_01/units/SEED_unit_dev_01/bookings/SEED_booking_dev_01` doc exists on bookbed-dev with cancelled status — same booking ID as the canonical `properties/SEED_property_dev_01/bookings/SEED_booking_dev_01` (confirmed status). Double-write residue from older atomicBooking. Backfill / delete dev-only — not blocking.
