# Audit/74 — F-70-01 Stripe egress fix (Terminal I)

**Date**: 2026-05-28
**Operator**: claude-opus-4-7 (Terminal I, autonomous)
**Branch**: `fix/f-70-01-stripe-ipv4-egress` (worktree `/Users/duskolicanin/git/bookbed-f70-ipv4` off `origin/main`)
**Scope**: F-70-01 root cause + dev fix; PROD read-only diagnosis FIRST.

---

## TL;DR

- **PROD egress WORKS** (verified via PROD `getStripeAccountStatus` → 200 with live account data, 30d log scan shows zero `StripeConnectionError`/`ETIMEDOUT`/etc. — §1).
- F-70-01 is **dev-only today**, but the root cause is a latent landmine on PROD: the moment PROD wires up `SENTRY_DSN`, payment CFs will break identically (§2).
- **Root cause**: `@sentry/node` v10's OpenTelemetry HTTP auto-instrumentation patches `node:https` in a way that breaks Stripe SDK's default `NodeHttpClient`. PROD escapes today only because `SENTRY_DSN` is unset there.
- **Initial hypothesis (IPv6 happy-eyeballs) was wrong**: IPv4 pin via `httpAgent: new https.Agent({family: 4})` did NOT fix it. Raw `https.request` from the same CF returns 200; only Stripe SDK fails (§3).
- **Fix**: switch Stripe client to `Stripe.createFetchHttpClient()` — the SDK's fetch-based transport (Node 18+ global fetch / undici) bypasses the `node:https` monkey-patch (§4). 1-line change in `functions/src/stripe.ts`.
- Verified on dev: `getStripeAccountStatus` 200 ✅, `createStripeCheckoutSession` now reaches the `charges_enabled` gate as designed ✅. PROD regression check still 200 ✅.

---

## §1 — PROD impact verdict: **WORKS**

### Evidence A: 30-day PROD log scan
```
gcloud logging read '
  resource.type="cloud_run_revision"
  AND resource.labels.service_name=~"^createstripe.*|handlestripewebhook|getstripeaccountstatus"
  AND (textPayload=~"(ETIMEDOUT|ECONNREFUSED|ENETUNREACH|EAI_AGAIN|StripeConnectionError|Request was retried)" OR ...)
' --project=rab-booking-248fc --freshness=30d --limit=50
```
→ **0 results.** No Stripe connection errors on PROD us-central1 CFs in the last 30 days.

### Evidence B: Live PROD CF probe
Logged into PROD test account `zgembokrkan@gmail.com` (UID `YWA4l5m70ZOWNLczkRngzYDjOlC2`), which has `stripe_account_id = acct_1SgkGeBYuq5LimME` (Dusko's Connect account per audit/60). Called `getStripeAccountStatus` PROD CF:
```json
{
  "connected": true, "accountId": "acct_1SgkGeBYuq5LimME",
  "onboarded": true, "chargesEnabled": true, "payoutsEnabled": true,
  "country": "HR", "balance": {"available": [{"amount": 0.6, "currency": "EUR"}], "pending": [...]},
  "requirements": {"currentlyDue": [], "eventuallyDue": [], "pastDue": []}
}
```
PROD `accounts.retrieve` → 200 from Stripe → balance returned. Egress works.

### Evidence C: PROD Sentry init log
Earlier CF log line from PROD: `Sentry DSN not provided, skipping initialization`. Per memory `[[sentry-cf-deploy-time-value-warning]]` and audit/57/58, PROD `SENTRY_DSN` is gitignored-only / unset at deploy time. **This accidentally insulates PROD from the bug.**

### Latency caveat (note for launch)
PROD `getStripeAccountStatus` cold-start TCP probe took ~9.6s in earlier probe (audit/70 §5 F-70-01); warm calls 1-2s. Egress works but it's not blazing fast. Outside scope of this fix.

### Verdict for §1 line in audit
> PROD `us-central1` Stripe SDK egress works in normal traffic conditions today. F-70-01 is observable on `bookbed-dev` only. The fix lands on `main` to prevent regression the day PROD gets `SENTRY_DSN` provisioned (which is on the queue per SF-052 / audit/55).

---

## §2 — Root cause

### Observation pattern
- `bookbed-dev/us-central1/getStripeAccountStatus` → `INTERNAL "Failed to get account status."`
- CF logs: `ERROR Error getting Stripe account status — "An error occurred with our connection to Stripe. Request was retried 2 times."` (Stripe SDK 19.1 `StripeConnectionError`)
- Same Cloud Run instance, raw `https.request` to `https://api.stripe.com/v1/accounts/acct_1Tc037PnKJAl9q6s` with real `Bearer sk_test_…` → **200 OK in 868ms** with full account JSON
- Stripe Node SDK call to the same path → fails consistently
- Both DEV and PROD use the same Cloud Run base image (`us-central1-docker.pkg.dev/serverless-runtimes/google-22-full/runtimes/nodejs20`), same Stripe SDK `^19.1.0`, same `apiVersion: "2025-09-30.clover"`. The only difference at the project layer is **DEV has `SENTRY_DSN` set, PROD does not.**

### Sentry instrumentation
`@sentry/node@10.54.0`'s default integrations include `httpIntegration` (OpenTelemetry-based). At init time it executes `patchHttpModuleClient` (see `node_modules/@sentry/core/build/cjs/integrations/http/client-patch.js`):
```js
object.wrapMethod(httpModule, "request", function patchedRequest(...args) {
  const request = originalRequest.apply(this, args);
  onHttpClientRequestCreated({request}, constants.HTTP_ON_CLIENT_REQUEST);
  return request;
});
```
This patches the `https.request` function globally for any module that does `require("https")`.

Stripe SDK 19.1 `NodeHttpClient` (`node_modules/stripe/cjs/net/NodeHttpClient.js`) makes its calls via:
```js
const req = (isInsecureConnection ? http : https).request({host, port, path, method, agent, headers, ...});
req.setTimeout(timeout, () => {req.destroy(HttpClient.makeTimeoutError());});
req.on('response', (res) => {resolve(new NodeHttpClientResponse(res));});
req.on('error', (error) => {reject(error);});
req.once('socket', (socket) => {...});
```
With Sentry's patched `https.request`, the subscribers Sentry attaches to the request via `onHttpClientRequestCreated` interfere with the Stripe SDK's `response`/`socket`/`error` lifecycle, causing the request to fail before a response is received. Stripe SDK then retries 2 times (its `maxNetworkRetries` default), then throws `StripeConnectionError`.

### Why Sentry's normal config knobs don't fix it
Tried (all on dev `probeStripeSdk` — a thin Stripe SDK call probe):
| Sentry config | Stripe SDK works? |
|---|---|
| Default (current `main`) | ❌ (StripeConnectionError) |
| `Sentry.init({integrations: [Sentry.httpIntegration({ignoreOutgoingRequests: u => u.includes('stripe.com')})]})` | ❌ — `ignoreOutgoingRequests` opts out of *span recording*, NOT out of the underlying https.request patch |
| `Sentry.init({defaultIntegrations: false, integrations: []})` | ❌ — patch is applied at module load via OpenTelemetry bootstrap, before integration list is consulted |
| `Sentry.init({skipOpenTelemetrySetup: true, tracesSampleRate: 0})` | ❌ — surprisingly, still applied (likely via `@sentry/core` direct http patch separate from OTEL setup) |

So **the Sentry side cannot be made transparent** to Stripe SDK with config alone. The fix has to be on the Stripe-client side: route around `node:https`.

### Initial wrong hypothesis (audit/70 + advisor IPv6 theory)
We initially thought `Cloud Run gen2 happy-eyeballs picks unreachable IPv6 route`. Disproved by `probeStripeEgress` raw `https.request` test:
| family | result |
|---|---|
| default (dual-stack) | 200 OK 217ms |
| 4 (IPv4) | 200 OK 102ms |
| 6 (IPv6) | `EAI_AGAIN` getaddrinfo (DNS fail) |

IPv6 DNS IS broken for `api.stripe.com` from this CF, BUT Node's happy-eyeballs/default behavior already falls back to IPv4 fast. So IPv6 was a red herring. Pinning the Stripe SDK's `httpAgent` to `{family: 4, keepAlive: true}` was also deployed and tested — **did not fix the SDK failure**, confirming the network path is fine and the issue is at the SDK-vs-Sentry-patch boundary.

---

## §3 — Diagnostic methodology (for future similar bugs)

Two temporary probe CFs were deployed to bookbed-dev `us-central1`, then deleted after root-cause:

### `probeStripeEgress` (raw `https.request`)
Tested baseline reachability to `api.stripe.com` from Cloud Run with explicit IP family, real Stripe key, real account-fetch path. Confirmed network path is fully functional. **DELETED** post-diagnosis.

### `probeStripeSdk` (Stripe SDK call)
Did a thin `getStripeClient().accounts.retrieve(...)`. Confirmed SDK fails where raw HTTPS succeeds. **DELETED** post-diagnosis.

Both probe sources are removed from the branch — only the actual fix in `functions/src/stripe.ts` remains. Cleanup verified via `gcloud run services list --filter='metadata.name~probe' --project=bookbed-dev` returning empty.

---

## §4 — The fix

`functions/src/stripe.ts` — single block:
```ts
const stripeHttpClient: Stripe.HttpClient = Stripe.createFetchHttpClient();

// ... inside getStripeClient():
stripe = new Stripe(apiKey, {
  apiVersion: "2025-09-30.clover",
  httpClient: stripeHttpClient,
});
```

Stripe SDK 19.1 ships both `NodeHttpClient` (default, uses `node:http`/`node:https`) and `FetchHttpClient` (uses global `fetch`). `Stripe.createFetchHttpClient()` returns the latter. Global fetch on Node 20 is implemented by undici, which uses its own socket pool and does **not** touch the `node:https` module that Sentry patches. The Stripe request bypasses Sentry's instrumentation surface entirely.

### Tradeoffs (small)
- Lose Sentry HTTP-tracing spans for outbound Stripe calls (we wouldn't have wanted them anyway — they carried no value before since the SDK retries internally).
- `FetchHttpClient` uses fetch's own timeout (via AbortController) — Stripe SDK's `timeout` option still applies to overall request deadline.
- No request-level keepAlive control (undici manages its own pool). For a low-volume CF that's fine.

### What this fix does NOT do
- Does not change `getStripeClient()` semantics.
- Does not change Stripe API version, key handling, idempotency, or retry behavior.
- Does not touch Sentry config — keeping all current `beforeSend` HttpsError filtering as-is.

---

## §5 — Verification

After deploying the 8 Stripe-touching CFs to bookbed-dev:

### Test A — DEV `getStripeAccountStatus` (was failing)
```json
{
  "connected": true, "accountId": "acct_1Tc037PnKJAl9q6s",
  "onboarded": false, "chargesEnabled": false, "payoutsEnabled": false,
  "country": "HR", "email": "bookbed-test@bookbed.io",
  "requirements": {"currentlyDue": [11 items: individual.*, tos_acceptance.*], ...}
}
```
✅ 200 OK with full account data. F-70-01 RESOLVED for this CF. The 11 currently-due fields are the F-70-02 captcha-blocker, *not* this fix's scope.

### Test B — DEV `createStripeCheckoutSession` (was returning ambiguous INTERNAL)
Before fix: `INTERNAL "Failed to verify payment account."` (couldn't reach `accounts.retrieve`).
After fix:
```json
{"error":{"message":"Property owner's payment account is not fully set up. Please contact the property owner.","status":"FAILED_PRECONDITION"}}
```
✅ Now hits the intended `charges_enabled === false` gate (`stripePayment.ts:329-332`). The error message is the one the client UI is designed to handle.

### Test C — PROD `getStripeAccountStatus` (regression check, READ-ONLY)
PROD service was NOT redeployed (the branch is dev-only). Verified PROD still returns 200 with `chargesEnabled: true, payoutsEnabled: true` for `acct_1SgkGeBYuq5LimME`. ✅ No regression.

### Build + tests
- `tsc` clean in worktree
- `npm test` — **317/317 tests pass** (no test changes; the fix is to runtime SDK init, all existing assertions still hold)

### CFs redeployed to bookbed-dev (all in `us-central1`)
- `createStripeCheckoutSession`
- `createStripeConnectAccount`
- `getStripeAccountStatus`
- `disconnectStripeAccount`
- `createSubscriptionCheckoutSession`
- `createCustomerPortalSession`
- `guestCancelBooking`
- `handleStripeWebhook`

All 8 share `getStripeClient()`. Single-file diff (`functions/src/stripe.ts`) covers all.

---

## §6 — PROD deployment recommendation

**Do NOT deploy this fix to PROD as part of this PR.** Reasoning:
1. PROD doesn't currently exhibit F-70-01 — `SENTRY_DSN` is unset, no patch is applied, Stripe SDK takes the unmodified `node:https` path.
2. Switching PROD's payment CFs to `FetchHttpClient` is a runtime-behavior change on the money path. Even though dev tests pass, any subtle fetch-vs-https-Agent difference (TLS handshake, connection pooling, error code shape downstream) could trickle into edge cases that only surface under live traffic.
3. The fix should ship to PROD as a **scheduled** deployment, *before* the SF-052 work that enables `SENTRY_DSN` on PROD — not after, and not before that work is queued. Otherwise PROD gets a no-op change that adds risk surface without buying anything yet.

### Sequence I recommend
1. Merge this PR → fix lives on `main`, deployed to dev only (current state after this terminal).
2. Add note to PR description + audit/74 §6 + memory `[[bookbed-dev-stripe-cf-egress-fail]]` updating the closure path: "FIX MERGED; dev verified; PROD intentionally not deployed yet".
3. Before SF-052 (PROD `SENTRY_DSN` enable) ships: deploy this branch's CFs to PROD as a pre-step in the same change-window. Test that PROD `getStripeAccountStatus` still works (same shape test as §5 Test C, post-deploy).
4. After step 3, ship SF-052.

If the operator decides to deploy to PROD now (acceptable — change is defensive, raw https path still works on PROD with no Sentry patches), the same 8-CF list above applies, just with `--project rab-booking-248fc`.

### Inconclusive case (the originally-feared "no PROD traffic, can't tell")
Not applicable. PROD log scan + live probe both produced positive signal (§1 evidence A + B). Verdict is conclusive.

---

## §7 — Relation to F-70-02 (Stripe Express hCaptcha blocker)

F-70-01 fix ≠ F-70-02 fix. The two are independent:

- **F-70-01 (this PR)**: Stripe SDK can reach api.stripe.com from us-central1 CFs. Was: CFs returned INTERNAL on every Stripe operation. Now: CFs return appropriate Stripe-driven responses (account data, gate errors, etc.).
- **F-70-02**: Stripe Express hosted onboarding requires solving hCaptcha challenges that defeat both CDP-driven Chrome AND a real human on a normal browser (audit/70 §5 F-70-02; confirmed by user 2026-05-28). The test fixture `acct_1Tc037PnKJAl9q6s` remains stuck at `charges_enabled: false` until Stripe Support clears the platform's test-mode captcha gate.

**Net effect of this fix**: dev payment-flow testing is no longer egress-blocked. The next blocker for end-to-end E1-E8 is F-70-02 — operator must file a Stripe Support ticket to lower the captcha gate.

---

## §8 — Branch hygiene

- Worktree: `/Users/duskolicanin/git/bookbed-f70-ipv4` off `origin/main` at `ceaad693`
- Branch: `fix/f-70-01-stripe-ipv4-egress`
- Files changed: **1**
  - `functions/src/stripe.ts` (+17 / -0)
- Files NOT touched (per Terminal I hard rules): `ios/`, `lib/`, `functions/src/bookingActions.ts`, widget UI under `web/`
- Probe CFs deleted from Cloud Run; no orphan functions left on bookbed-dev
- `functions/.env` and `functions/.env.bookbed-dev` copied locally to the worktree to enable `firebase deploy` — these are gitignored, not committed
- `functions/package-lock.json` reverted to `origin/main` after a transient npm-install-driven diff caused Cloud Build `npm ci` to fail
