# audit/89 — F-86-01 closure: CORS allowlist on 8 framework-default callables (SF-062)

**Date**: 2026-05-29
**PR**: `fix/f86-01-cors-8-callables` → `main`
**Scope**: `functions/src/` only — 6 source files, 2 test mocks. No PROD touches. Dev deploy + IAM re-grant + sandbox smoke matrix.
**Origin chain**: audit/57 (vibe-security M-09 reflective CORS) → audit/58 F-58-07 (`onCall` default reflective CORS class) → audit/84 PR #559 (10 explicit `cors: true` swapped to `getCorsAllowlist()`) → audit/86 F-86-01 (memory `[[f86-01-cors-allowlist-gap-8-callables]]`: 8 framework-default callables still reflect arbitrary `Origin` on `OPTIONS` preflight).

---

## 1. Problem

audit/84 PR #559 swept the **explicit-`cors: true`** subset of callables. The **framework-default** subset (`onCall(opts, handler)` where `opts.cors` is omitted) was left untouched and continues to reflect whatever `Origin` arrives. Verified 2026-05-29 against bookbed-dev — `OPTIONS … -H "Origin: https://evil.test"` returns `Access-Control-Allow-Origin: https://evil.test`.

8 callables affected. 3 are payment hot-path: `createBookingAtomic`, `createStripeCheckoutSession`, `guestCancelBooking`. Cross-origin reads of Stripe Checkout URL responses are readable from attacker site (no `Access-Control-Allow-Credentials`, so cookie session not exposed; Bearer-token theft via separate XSS still possible).

## 2. Affected callables (region split per audit/58 F-58-08)

| Callable | Region | Source | Existing opts (before) |
|---|---|---|---|
| `checkSubdomainAvailability` | us-central1 | `subdomainService.ts:168` | `onCall<{...}>(handler)` — no opts |
| `createBookingAtomic` | us-central1 | `atomicBooking.ts:60` | `{secrets: ["RESEND_API_KEY"]}` |
| `createStripeCheckoutSession` | us-central1 | `stripePayment.ts:132` | `{secrets, enforceAppCheck:false, consumeAppCheckToken:true}` |
| `guestCancelBooking` | us-central1 | `guestCancelBooking.ts:65` | `{secrets: ["RESEND_API_KEY", stripeSecretKey]}` |
| `deleteUserAccount` | europe-west1 | `deleteUserAccount.ts:47` | `{region, timeoutSeconds: 540}` |
| `recordLoginFailure` | europe-west1 | `loginLockout.ts:98` | `{region}` |
| `getLoginLockoutStatus` | europe-west1 | `loginLockout.ts:171` | `{region}` |
| `clearLoginAttempts` | europe-west1 | `loginLockout.ts:212` | `{region}` |

## 3. Fix

Per-CF: import `getCorsAllowlist` from `./utils/corsAllowlist` (PR #559's helper), inject `cors: getCorsAllowlist()` into the existing opts object. All other opts preserved verbatim.

`subdomainService.ts:168` was the irregular case — `onCall<T>(handler)` form. New shape: `onCall<T>({cors: getCorsAllowlist()}, handler)`. Generic type-param retained.

## 4. Test mock follow-up

`test/stripePayment.test.ts` + `test/guestCancelBooking.test.ts` mock `firebase-functions/params` to provide `defineSecret` + `defineString` only. Pre-fix `onCall(opts, …)` skipped the `Expression`-check fast-path (`"cors" in opts === false`). Post-fix, `onCall` reaches `if (opts.cors instanceof params_1.Expression)` at `firebase-functions/lib/v2/providers/https.js:152` — `params_1.Expression === undefined` → `TypeError: Right-hand side of 'instanceof' is not an object` at module load.

Mock extended: `Expression: class Expression {}` added to both test files. `cors: Array` never satisfies `instanceof Expression`, so the array path is taken untouched.

## 5. Stale-`node_modules` gotcha (informational, not in scope)

Initial `npm run build` in `functions/` emitted 4 `tsc` errors against `Stripe.Stripe` namespace — symptomatic of `stripe@19.1.0` resolved on-disk vs `^22.2.0` declared in `package.json`. PR #503 (`9539b3e5`) MERGED the dep bump + the audit/78 adapt content together, but local `node_modules` had been carried forward from before. `npm install` in `functions/` resolved → source compiles cleanly against `stripe@22.2.0`. Worth flagging in onboarding / fresh-clone runbooks; symmetric to the `flutter pub get` pub-cache desync trap (CLAUDE.md TOOLING GOTCHA).

## 6. Verification

```
$ cd functions && npm run build
> tsc
(0 errors)

$ npm test
Test Suites: 19 passed, 19 total
Tests:       387 passed, 387 total
Time:        20.125 s

$ npm run test:rules
Test Suites: 4 passed, 4 total
Tests:       46 passed, 46 total
Time:        6.422 s
```

ts-jest TS151002 warnings unchanged (pre-existing, tracked in audit/78 §3 + §5).

## 7. Dev deploy + IAM re-grant

Per memory `[[cf-deploy-cors-shape-iam-strip]]`: Firebase Functions v2 deploy where `cors` option shape changes (here: omitted → `(string|RegExp)[]`) strips Cloud Run `allUsers/invoker` IAM binding on PROD. Dev behavior re-verified during this deploy (matrix below). IAM re-grant is **mandatory** post-deploy per region.

### Deploy command

```
firebase deploy --project bookbed-dev --only \
  functions:checkSubdomainAvailability,\
  functions:createBookingAtomic,\
  functions:createStripeCheckoutSession,\
  functions:guestCancelBooking,\
  functions:deleteUserAccount,\
  functions:recordLoginFailure,\
  functions:getLoginLockoutStatus,\
  functions:clearLoginAttempts \
  --non-interactive
```

### IAM re-grant matrix

```
# us-central1
for fn in checkSubdomainAvailability createBookingAtomic createStripeCheckoutSession guestCancelBooking; do
  gcloud run services add-iam-policy-binding "$fn" \
    --region=us-central1 --project=bookbed-dev \
    --member=allUsers --role=roles/run.invoker
done

# europe-west1
for fn in deleteUserAccount recordLoginFailure getLoginLockoutStatus clearLoginAttempts; do
  gcloud run services add-iam-policy-binding "$fn" \
    --region=europe-west1 --project=bookbed-dev \
    --member=allUsers --role=roles/run.invoker
done
```

## 8. CORS smoke matrix

`OPTIONS` preflight from `Origin: https://evil.test` should **omit** `Access-Control-Allow-Origin` entirely (not `*`, not echoed). From `Origin: https://app.bookbed.io` (or `bookbed-owner-dev.web.app`) should **echo** the exact origin. Discriminator per advisor: any `*` reply → old revision serving.

Sandboxed via `ctx_execute(language: "shell")` — `curl` blocked per CLAUDE.md.

_(filled in §9 after deploy completes)_

## 9. Smoke results

Executed via `ctx_execute(language: "javascript")` against the legacy callable URL `https://<region>-bookbed-dev.cloudfunctions.net/<fn>` (CDN proxies to underlying Cloud Run service). All 24 cells GREEN — 8 CFs × 3 origins.

| Callable | Region | `Origin: https://evil.test` | `Origin: https://app.bookbed.io` | `Origin: https://bookbed-owner-dev.web.app` |
|---|---|---|---|---|
| `checkSubdomainAvailability` | us-central1 | 204 / **ACAO=(none)** ✓ | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ |
| `createBookingAtomic` | us-central1 | 204 / **ACAO=(none)** ✓ | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ |
| `createStripeCheckoutSession` | us-central1 | 204 / **ACAO=(none)** ✓ | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ |
| `guestCancelBooking` | us-central1 | 204 / **ACAO=(none)** ✓ | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ |
| `deleteUserAccount` | europe-west1 | 204 / **ACAO=(none)** ✓ | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ |
| `recordLoginFailure` | europe-west1 | 204 / **ACAO=(none)** ✓ | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ |
| `getLoginLockoutStatus` | europe-west1 | 204 / **ACAO=(none)** ✓ | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ |
| `clearLoginAttempts` | europe-west1 | 204 / **ACAO=(none)** ✓ | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ |

`Vary: Origin, Access-Control-Request-Headers` set on every response — proper CORS-aware caching signal.

### Widget-origin matrix (payment hot-path, 3 CFs × 3 origins, follow-up advisor check)

| Callable | `view.bookbed.io` (PROD widget) | `bookbed-widget-dev.web.app` (DEV widget) | `test.view.bookbed.io` (wildcard regex) |
|---|---|---|---|
| `createBookingAtomic` | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ |
| `createStripeCheckoutSession` | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ |
| `guestCancelBooking` | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ | 204 / ACAO echoed ✓ |

Wildcard regex `/^https:\/\/[a-z0-9][a-z0-9-]*\.view\.bookbed\.io$/` (corsAllowlist.ts:37) confirmed reachable via `test.view.bookbed.io`.

### Functional POST probe (proves the function actually executes post-CORS gate)

`POST https://europe-west1-bookbed-dev.cloudfunctions.net/recordLoginFailure` from `Origin: https://app.bookbed.io` with body `{"data":{"email":"audit89-probe-<ts>@bookbed-dev.test"}}` →

```
status=200 | ACAO=https://app.bookbed.io
body={"result":{"locked":false,"attemptCount":1,"lockedUntilMs":null,"remainingAttempts":4}}
```

Function executed end-to-end; `cors: getCorsAllowlist()` does not interact badly with the existing `region` / `secrets` opts. Side effect: a `loginAttempts/audit89-probe-...@bookbed-dev.test` doc with `attemptCount=1` exists on bookbed-dev — auto-resets after `ATTEMPT_RESET_MS = 1h` per `loginLockout.ts:39`.

F-86-01 CLOSED on bookbed-dev.

### Cloud Run service-name gotcha (dev observation)

`gcloud run services add-iam-policy-binding` on PROD per `[[cf-deploy-cors-shape-iam-strip]]` uses the callable's **camelCase** name. On bookbed-dev (re-verified during §7) the underlying Cloud Run services are **lowercase** (`checksubdomainavailability` etc.). Initial IAM re-grant loop with camelCase names returned `NOT_FOUND` for all 8; lowercase loop succeeded. Likely Firebase Functions v2 normalizes service names → lowercase on Cloud Run create. PROD operators: verify actual service name via `gcloud run services list --region=<r>` before scripting.

## 10. Open items / not in scope

- PROD cutover gated separately (user-manual gate per "AUTONOMAN" scope ban). Pre-cutover: re-run §8 smoke against PROD URLs + IAM re-grant on `rab-booking-248fc`.
- Broader sweep of remaining framework-default callables (catch-all: `grep -rEn "export const \w+ = onCall\(" functions/src/ | grep -v "cors:"`). Net count post-this-PR should be 0 for hot-path callables; cold-path admin/email triggers are lower risk.
- F-86-01 closure tag in memory `[[f86-01-cors-allowlist-gap-8-callables]]` to be flipped 🚨 → ✅ post-PROD-deploy.

## 11. Cross-references

- audit/86-orphan-sweep.md — separate finding under the same audit/86 batch
- audit/84-security-sweep-2026-05-29.md STEP 3 — PR #559 origin sweep
- audit/58-chrome-devtools-audit-2026-05-27.md F-58-07 — root-cause class
- memory `[[f86-01-cors-allowlist-gap-8-callables]]`
- memory `[[cf-deploy-cors-shape-iam-strip]]`
- memory `[[oncall-default-cors-reflective]]`
- SF-062 — this fix's SECURITY_FIXES.md entry
