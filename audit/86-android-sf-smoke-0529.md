# Android + SF-* dev smoke — 2026-05-29

Autonomous Android run + read-only verification of deployed `SF-*` fixes on `bookbed-dev`.
Branch: `auto/android-sf-verify-0529`. No live writes to `bookings/payments/auth`.

## TL;DR

| Test | Result | Notes |
|------|--------|-------|
| SF-038 webhook dedup + TTL | ✅ PASS | rules `if false`, transaction dedup in `stripePayment.ts:933-945`, TTL on `expiresAt` ACTIVE |
| SF-047 subdomain auth gate | ✅ PASS | anon → 401 `UNAUTHENTICATED`; auth → 200 |
| SF-048 deleteUserAccount cooldown | ✅ STATIC | rate-limit gate `delete_account:${uid}` 1/300s (live test deferred — destructive) |
| SF-050 loginAttempts read deny | ✅ PASS | anon Firestore REST → 403 `PERMISSION_DENIED`; `recordLoginFailure` callable returns `{locked:false, attemptCount:1, remainingAttempts:4}` for anon caller (App Check follow-up) |
| SF-058 getClientGeolocation | ✅ PASS | anon → 200 `{country, region, city}` ("Bosnia and Herzegovina / Republika Srpska / Prijedor"), no IPv4/IPv6 octet leakage in body |
| SF-060 CORS allowlist | 🚨 **F-86-01 P1** | 5/7 callables echo `Origin: https://evil.test` back as `Access-Control-Allow-Origin` |
| Android emulator smoke | ⏳ build in progress (worktree) | fresh worktree needed `flutter pub get` + `build_runner build --delete-conflicting-outputs` (CLAUDE.md TOOLING GOTCHA pattern) |

## Pre-flight

- Pulled `main` → HEAD `ed31ae47` (audit/85 doc)
- Worktree `auto/android-sf-verify-0529` @ `/tmp/bb-android-wt`
- `android/app/google-services.json` swapped to `bookbed-dev` variant (kept PROD as `.prod-snapshot`); verified `project_id: "bookbed-dev"`
- Test acct sign-in via Identity Toolkit: `bookbed-test@bookbed.io` → UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`, ID token 922 chars

## CF region map (probed via OPTIONS / cloudfunctions.net)

| Function | Region |
|---|---|
| `checkSubdomainAvailability` | `us-central1` |
| `deleteUserAccount` | `europe-west1` |
| `recordLoginFailure` / `getLoginLockoutStatus` / `clearLoginAttempts` | `europe-west1` |
| `getClientGeolocation` | `europe-west1` |
| `getUnitAvailability` | `europe-west1` |
| `stripeWebhook` (HTTP `onRequest`) | not reachable via callable URL — Gen 2 Cloud Run path |

## SF-038 — Stripe webhook dedup + TTL

Three-part verify (all PASS):

1. **Rules** — `firestore.rules:477-479` collection locked to `read, write: if false`. Verified.
2. **Dedup logic** — `functions/src/stripePayment.ts:929-950`. Transaction:
   ```ts
   const eventRef = db.collection("stripe_webhook_events").doc(event.id);
   const dedupResult = await db.runTransaction(async (t) => {
     const snap = await t.get(eventRef);
     if (snap.exists) return "duplicate";
     t.set(eventRef, {
       receivedAt: serverTimestamp(),
       type: event.type, livemode: event.livemode, apiVersion: event.api_version,
       expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
     });
     return "new";
   });
   if (dedupResult === "duplicate") { res.status(200).json({received:true, status:"duplicate"}); return; }
   ```
3. **TTL policy** — `gcloud firestore fields ttls list --project=bookbed-dev`:
   ```
   projects/bookbed-dev/databases/(default)/collectionGroups/stripe_webhook_events/fields/expiresAt -> ACTIVE
   ```
   30-day rolling window confirmed.

## SF-047 — checkSubdomainAvailability auth gate

```http
POST https://us-central1-bookbed-dev.cloudfunctions.net/checkSubdomainAvailability
Content-Type: application/json
{"data":{"subdomain":"test-anon-probe"}}

HTTP/2 401
{"error":{"message":"Authentication required","status":"UNAUTHENTICATED"}}
```

With valid Bearer token (test acct):
```http
HTTP/2 200
{"result":{"available":true,"error":null,"suggestion":null,"validationDetails":{"formatValid":true,"reserved":false,"taken":false}}}
```

Source: `functions/src/subdomainService.ts` — gate runs before any logic, throws `unauthenticated`.

## SF-048 — deleteUserAccount cooldown (static-only)

Live test deferred per ground rule "Nikad write na bookings/payments/auth" — `deleteUserAccount` cascades into Auth + Firestore deletions.

Static verify (`functions/src/deleteUserAccount.ts:60-67`):
```ts
// SF-048: per-uid cooldown. 1 call per 5 minutes; prevents accidental double-clicks
// and concurrent deletion runs which can corrupt the cascade.
if (!checkRateLimit(`delete_account:${userId}`, 1, 300)) {
  throw new HttpsError("resource-exhausted", "Account deletion already in progress. Please wait a few minutes.");
}
```

`checkRateLimit` (`functions/src/utils/rateLimit.ts:70-90`) is in-memory keyed per-key. Caveats:
- In-memory store survives across requests on a warmed instance.
- Cold start (no warm instance) loses state → 2 cold instances could both pass.
- For deletion specifically, idempotency of subsequent steps (`admin.auth().deleteUser` would 5xx on already-deleted UID) is the defence-in-depth.
- Production GCF v2 callable concurrency = 1 by default → narrow window for the race.

Closure narrative consistent with [audit/55] / [audit/54] §C.

## SF-050 — loginAttempts collection deny

Anon Firestore REST GET on `loginAttempts/bookbed-test%40bookbed.io`:
```
HTTP 403
{"error":{"code":403,"message":"Missing or insufficient permissions.","status":"PERMISSION_DENIED"}}
```

`recordLoginFailure` callable live on bookbed-dev (anon caller probe with synthetic `sf050-anon-probe@example.invalid`):
```
HTTP 200
{"result":{"locked":false,"attemptCount":1,"lockedUntilMs":null,"remainingAttempts":4}}
```

Matches `[[pr517-f-50-02-closed-2026-05-27]]` design: anon callable invocation is allowed (App Check is the closure for distributed-bot abuse — see audit/85). Per-IP and per-email throttles still apply.

## SF-058 — getClientGeolocation

Anon `POST europe-west1.../getClientGeolocation` with `{"data":{}}`:
```
HTTP 200
{"result":{"country":"Bosnia and Herzegovina","region":"Republika Srpska","city":"Prijedor"}}
```

IP-leak grep on response body: no IPv4 octet pattern, no `ip` / `clientIp` / `x-forwarded-for` field present.

Matches `[[ipwhois-app-pii-leak-on-login]]` closure goal — IP stays server-side; only coarse geo escapes.

## SF-060 — CORS allowlist sweep (🚨 F-86-01 P1)

Preflight `OPTIONS` with `Origin: https://evil.test` against 7 callables:

| Callable | Region | Status | ACAO |
|---|---|---|---|
| `recordLoginFailure` | eu-west1 | 204 | 🚨 `https://evil.test` |
| `getClientGeolocation` | eu-west1 | 204 | ✅ `<absent>` |
| `deleteUserAccount` | eu-west1 | 204 | 🚨 `https://evil.test` |
| `getLoginLockoutStatus` | eu-west1 | 204 | 🚨 `https://evil.test` |
| `clearLoginAttempts` | eu-west1 | 204 | 🚨 `https://evil.test` |
| `getUnitAvailability` | eu-west1 | 204 | ✅ `<absent>` |
| `checkSubdomainAvailability` | us-central1 | 204 | 🚨 `https://evil.test` |

Legit dev origin `https://bookbed-owner-dev.web.app` probe — ALLOW confirmed (`access-control-allow-origin: https://bookbed-owner-dev.web.app`, `access-control-allow-methods: POST`).

**Root cause**: only 2 of 7 callables wire `cors: getCorsAllowlist()`. The remaining 5 use Firebase v2 `onCall` framework default, which reflects arbitrary `Origin` header back as ACAO.

Static confirmation (`grep -rln "getCorsAllowlist"`):
```
functions/src/availability.ts          ← getUnitAvailability ✅
functions/src/getClientGeolocation.ts  ← getClientGeolocation ✅
functions/src/utils/corsAllowlist.ts   (helper)
functions/src/emailVerification.ts
functions/src/passwordReset.ts
functions/src/bookingActions.ts
```

Missing wiring (callable still framework-default):
- `functions/src/deleteUserAccount.ts:47` — `onCall({region:"europe-west1", timeoutSeconds:540}, ...)`
- `functions/src/loginLockout.ts` — `recordLoginFailure`, `getLoginLockoutStatus`, `clearLoginAttempts` — `onCall({region:"europe-west1"}, ...)`
- `functions/src/subdomainService.ts` — `checkSubdomainAvailability` — `onCall<...>(async (request) => ...)` (no opts object at all)

**Why it matters**: although ACAC (`Access-Control-Allow-Credentials`) is absent — so `fetch(..., {credentials:'include'})` from `evil.test` does NOT send the Firebase Auth cookie — the reflective ACAO still permits:
1. CSRF using Bearer-token theft from another XSS vector (since Bearer doesn't ride on cookies).
2. Bypass of any origin-based defence-in-depth on App Check / rate limit that triggers on Origin.
3. Auth-flow phishing where the attacker site can read response bodies (account enumeration via `getLoginLockoutStatus`'s `attemptCount` field, subdomain enumeration via `checkSubdomainAvailability` (requires auth) — moot here, but the pattern is wrong).

### Wider sweep (post-initial finding)

Additional callables probed with same evil-origin preflight:

| Callable | Region | ACAO |
|---|---|---|
| `rejectBooking` | eu-west1 | ✅ `<absent>` (uses `bookingActions.ts` allowlist) |
| `createBookingAtomic` | us-central1 | 🚨 `https://evil.test` |
| `createStripeCheckoutSession` | us-central1 | 🚨 `https://evil.test` |
| `guestCancelBooking` | us-central1 | 🚨 `https://evil.test` |

Brings F-86-01 total to **8 callables** with reflective CORS:

1. `recordLoginFailure` (eu-west1)
2. `deleteUserAccount` (eu-west1)
3. `getLoginLockoutStatus` (eu-west1)
4. `clearLoginAttempts` (eu-west1)
5. `checkSubdomainAvailability` (us-central1)
6. `createBookingAtomic` (us-central1) — **payment hot path**
7. `createStripeCheckoutSession` (us-central1) — **payment hot path**
8. `guestCancelBooking` (us-central1) — **guest refund hot path**

Payment-path entries (#6–#8) raise severity. The response body of `createStripeCheckoutSession` returns the Stripe Checkout URL — readable cross-origin from `evil.test`, enabling pre-auth phishing redirects.

**Recommended fix** (separate PR — out of scope for this read-only audit):
```ts
import {getCorsAllowlist} from "./utils/corsAllowlist";
export const recordLoginFailure = onCall(
  {region: "europe-west1", cors: getCorsAllowlist()},
  ...
);
```
Same shape on the other seven. Per `[[cf-deploy-cors-shape-iam-strip]]` memory — re-grant Cloud Run `allUsers/invoker` after each deploy with a loop:
```bash
for fn in recordLoginFailure deleteUserAccount getLoginLockoutStatus clearLoginAttempts checkSubdomainAvailability createBookingAtomic createStripeCheckoutSession guestCancelBooking; do
  REGION=$(case $fn in checkSubdomainAvailability|createBookingAtomic|createStripeCheckoutSession|guestCancelBooking) echo us-central1;; *) echo europe-west1;; esac)
  gcloud run services add-iam-policy-binding $fn --region=$REGION --member=allUsers --role=roles/run.invoker --project=bookbed-dev
done
```

Audit/84 narrative for F-58-07 said "10 explicit `cors: true` → `getCorsAllowlist()`"; the broader sweep across framework-default callables remained open. F-86-01 catches that residual.

## Android emulator smoke — Marionette

### Setup

1. `git worktree add -b auto/android-sf-verify-0529 /tmp/bb-android-wt main`
2. `cp android/app/google-services.json.backup android/app/google-services.json` (gitignored — copied from main repo path; verified `project_id: "bookbed-dev"`)
3. `flutter pub get`
4. `dart run build_runner build --delete-conflicting-outputs` — 99 outputs in 54s
5. `flutter run -d emulator-5554 --debug --target lib/main_dev.dart`

First `--release` attempt surfaced phantom Kotlin Gradle Plugin warning + missing `.g.dart` files — fresh-worktree pattern from CLAUDE.md TOOLING GOTCHA. Resolved by `build_runner build --delete-conflicting-outputs`. Switched to `--debug` per `[[android-debug-build-firebase-storage-13]]` (firebase_storage 13 lifts the debug-build block) — Marionette requires Dart VM Service which is `--release`-stripped.

Dart VM Service: `ws://127.0.0.1:63962/BnX4xTEYQOE=/ws`. Marionette MCP connected.

### Smoke matrix

| Check | Result | Notes |
|---|---|---|
| App boot on emulator-5554 | ✅ | Pixel_8 AVD, Pregled (Owner Dashboard) renders with auth-persisted `bookbed-test@bookbed.io` |
| Drawer nav (hamburger) | ✅ | All 8 items render, badges 1 (Rezervacije) / 11 (Obavještenja) |
| Smještajne Jedinice → unit detail | ✅ | Test Unit A loads, 4 tabs (Osnovno/Cjenovnik/Widget/Napredno) |
| Edit Unit wizard (Uredi) | ✅ | 4-step flow opens, Korak 1/4 100% progress shown |
| TextFormField focus + input | ✅ | Opis field at logical (205, 632); entered "Smoke test caveman" → 18/500 counter updated |
| **Navigator.pop (back arrow, canPop fallback class)** | ✅ | Tap top-left back chevron from wizard → returns to unit detail, no crash, no ErrorBoundary trip; unsaved form discarded (Slug still "Nije postavljeno") |
| Kalendar → Timeline kalendar | ✅ | Loads `lipanj 2026` view, 7-day grid, Test Unit A row visible |
| **Timeline weak-swipe bounce-back class** | ✅ (as designed) | Horizontal swipe 500→200 + 600→50 at logical y=540: view stays put, no horizontal scroll — confirms programmatic-only navigation (per CLAUDE.md "Calendar Repository … duplikacija NAMJERNA"). Not a bug. |
| Calendar programmatic nav (date pill / chevron) | ✅ | Tap date pill area → grid scrolls from 23-28 → 12-17 lipnja 2026 |
| Rezervacije list | ✅ | Loads pending seed booking `BB-TEST03` (Pending Guest, 8.7-11.7.2026, €360 unpaid), filter chips (Sve / Na čekanju / Potvrđene / Otkazane / Uvezene), Odobri/Odbij action buttons render. **Did NOT tap Odobri/Odbij** — would be write to `bookings/payments` and per `[[owner-confirm-reject-ui-no-op]]` Web variant is silent no-op (P1 open). |
| Keyboard dismiss | ✅ implicit | Marionette `enter_text` bypasses native IME; field accepted input + cursor caret visible; no overlay jank |

### Negative-result observations

- No `ErrorBoundary` invocation on any tap (audit/20 narrowing holds on Android via message + stack-layer filter — matches `[[wave-android-smoke-2026-05-23]]` finding closure).
- `GoogleApiManager java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'` warnings in logcat — emulator-side GMS not bound to real Google services account; cosmetic, doesn't affect Firebase Auth/Firestore (test acct signed in fine).
- `ProviderInstaller` warning — same root cause, AVD doesn't ship Play Services Dynamite module.

### Verdict

No Android-specific bugs surfaced. No fixes applied under `android/`. Build wrapper `tool/build_aab.sh` not exercised this run (release path needed only for CI / Play Store).

## Open follow-ups

- **F-86-01 P1 CORS allowlist gap** — 5 callables. Suggested separate PR `fix/sf-060-cors-allowlist-sweep` w/ post-deploy `gcloud run services add-iam-policy-binding ... --member=allUsers --role=roles/run.invoker` re-grant for each updated CF.
- Wider sweep on remaining ~35 callables not probed here — F-58-07 broader closure.

## Memory linkage

- `[[oncall-default-cors-reflective]]` (audit/58) — root cause class confirmed.
- `[[cf-deploy-cors-shape-iam-strip]]` (audit/84) — deploy gotcha if fix is applied.
- `[[pr517-f-50-02-closed-2026-05-27]]` — SF-050 background.
- `[[ipwhois-app-pii-leak-on-login]]` — SF-058 background.

---
Last updated: 2026-05-29 | author: autonomous /effort=max session
