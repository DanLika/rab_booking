# audit/100 — Closure bundle for audit/99 HIGH net-new findings (SF-078)

**Date:** 2026-05-30
**PR:** TBD (created against `main` from `fix/audit99-high-bundle`).
**Scope:** functions/src + firestore.rules. NO Flutter client, NO iOS/Android.
**SF assignment:** SF-078 (next free above SF-077).
**Status:** DEV-only. PR opened for review; **NOT merged, NOT PROD-deployed.**

This bundle closes four net-new HIGH findings surfaced during the audit/99 multi-agent sweep on 2026-05-30. The audit/99 doc itself (the parallel-agent report) is co-included for reference. PROD deploy gated by post-merge runbook in audit/90.

## Findings closed

| # | ID | Sev | Surface | Closure |
|---|---|---|---|---|
| 1 | F-99-01 | HIGH | `firestore.rules:264-266` — `bookings` update deny-list status-machine-only; CF-managed scalars owner-writable | Extend `!affectedKeys().hasAny([…])` deny-list with 7 fields. Mirror SF-068 sibling shape. |
| 2 | H-1 | HIGH | `stripePayment.ts:87` + `utils/returnUrlValidation.ts:51` — `startsWith()` accepts `https://bookbed.io.evil.com/…` and `https://attacker@bookbed.io/…` (userinfo trick) | Replace with `new URL()` host+protocol equality; reject userinfo. Single source of truth. |
| 3 | H-2 | HIGH | `utils/returnUrlValidation.ts:18-19` — `http://localhost` / `http://127.0.0.1` unconditionally in BASE_ALLOWED_DOMAINS, regressing SF-073 in extracted util | Hoist to LOCAL_DEV_DOMAINS; gate via `process.env.FUNCTIONS_EMULATOR === "true"` (mirrors `stripePayment.ts:46-71` shape). |
| 4 | H-3 | HIGH→MED | 12 callable files with framework-default reflective CORS (audit/89 carry-over) | Wire `cors: getCorsAllowlist()` on 17 callables across 12 files. |

## Why H-1 is genuinely HIGH

The validator runs on the redirect target Stripe forwards the customer to after checkout / portal / Connect onboarding. A successful prefix-bypass (`https://bookbed.io.evil.com/…`) or userinfo trick (`https://attacker@bookbed.io/…`) means an attacker who can submit a `returnUrl` parameter (widget API surface) gets the customer's browser redirected to attacker-controlled host with the Stripe session id appended in the URL. The session id is the proof-of-purchase capability that `getBookingByStripeSession` and the legacy poll path treat as authorization to fetch booking PII. So: phishable in-context redirect + access-capability leak. Not refund-routing, but session-id exfil.

## Why H-2 is HIGH (PROD regression)

SF-073 explicitly removed `http://localhost` / `http://127.0.0.1` from PROD's allowlist for a documented reason (exfil to operator-network hosts). The extracted util `utils/returnUrlValidation.ts` (F-NEW-02 refactor) re-introduced them unconditionally to BASE_ALLOWED_DOMAINS without the emulator gate. Today `stripeConnect.ts` and `stripeSubscription.ts` route through the util (line 8 + 6 respectively). Both PROD CFs accept `http://localhost/…` returnUrl in their current deploy.

Verified via `git blame` proxy: util file pre-dates SF-073 gate documentation in `stripePayment.ts` comment lines 47-50. The extraction missed the gate.

## Why F-99-01 is HIGH not MED (final framing)

After advisor reconcile in audit/99, exploit realism per axis:
- **No-prereq:** owner can forge `emails_sent.*` to suppress CF idempotent re-sends, rewrite `booking_reference` to break support workflows, tamper `created_at`, `source`, `provider_id`. Each is local-state corruption on attacker's own bookings — survives at MED on its own.
- **`owner_id` rewrite:** owner could detach a booking from their dashboard or reassign to another owner — moves to HIGH because the attacker can replicate cross-owner data exfil patterns with a confederate UID.
- **PI-leak variant (latent):** `payment_intent_id` rewrite + future PI disclosure surface → refund-routing collision → wrong booking flagged refunded, wrong calendar window released, wrong owner emailed.

Aggregate sev = HIGH. Closure is one-line deny-list extension. Cost-benefit favors preventive close.

## Changes

### A) firestore.rules — bookings update deny-list (F-99-01)

`firestore.rules:264-266` — extend the existing `!affectedKeys().hasAny([…])` deny-list. New fields appended:
```
'payment_intent_id', 'emails_sent', 'booking_reference',
'owner_id', 'created_at', 'source', 'provider_id'
```
Same `!`+`hasAny` shape as SF-068 sibling closures (properties / ical_feeds / widget_settings).

### B) utils/returnUrlValidation.ts — host-only + emulator gate (H-1 + H-2)

- Removed `http://localhost` / `http://127.0.0.1` from `BASE_ALLOWED_DOMAINS`; hoisted to `LOCAL_DEV_DOMAINS`; appended only when `process.env.FUNCTIONS_EMULATOR === "true"`. Mirrors `stripePayment.ts:46-71`.
- Replaced `startsWith()` exact match with `new URL()` host+protocol equality. Wildcard branch retains its safe split-based check + gains explicit `https:` protocol requirement.
- Rejects URLs carrying credentials (`parsed.username !== ""` or `parsed.password !== ""`) — closes the `https://attacker@bookbed.io/…` userinfo trick.
- Port left permissive: allowed entries don't specify a port, so input ports (including emulator's `:5000`) pass on hostname+protocol match. If a future allowed entry adds an explicit port, strict equality already kicks in by definition of `URL.port`.

### C) stripePayment.ts — drop duplicate validator (H-1 + H-2)

Removed local copies of `getAllowedReturnDomains` / `ALLOWED_WILDCARD_DOMAINS` / `isAllowedReturnUrl` (lines 37-127). Imports from `./utils/returnUrlValidation`. Eliminates the drift class that gave us H-2 in the first place. Logging at line 174-177 drops the dead `allowedWildcards` field reference.

`stripeConnect.ts` and `stripeSubscription.ts` were already on the util — they automatically inherit both fixes.

### D) CORS allowlist wiring on 12 callables (H-3)

Added `import {getCorsAllowlist} from "./utils/corsAllowlist";` and `cors: getCorsAllowlist()` to:

| File | Callables wired |
|---|---|
| `authRateLimit.ts` | `checkLoginRateLimit`, `checkRegistrationRateLimit` |
| `customEmail.ts` | `sendCustomEmailToGuest` |
| `getBookingByStripeSession.ts` | `getBookingByStripeSession` |
| `icalSync.ts` | `syncIcalFeedNow` |
| `passwordHistory.ts` | `checkPasswordHistory`, `savePasswordToHistory` |
| `resendBookingEmail.ts` | `resendBookingEmail` |
| `resendGuestBookingEmail.ts` | `resendGuestBookingEmail` |
| `revokeTokens.ts` | `revokeAllRefreshTokens` |
| `stripeConnect.ts` | `createStripeConnectAccount`, `getStripeAccountStatus`, `disconnectStripeAccount` |
| `stripeSubscription.ts` | `createSubscriptionCheckoutSession`, `createCustomerPortalSession` |
| `updateBookingTokenExpiration.ts` | `updateBookingTokenExpiration` |
| `verifyBookingAccess.ts` | `verifyBookingAccess` |

17 callables across 12 files. Existing `{secrets: [...]}` or `{region: "europe-west1"}` opts blocks were extended in place, not replaced.

**Deploy hazard:** per memory topic `cf-deploy-cors-shape-iam-strip`, flipping `cors` between absent / `true` / array on v2 onCall can strip Cloud Run `allUsers/invoker` on PROD with a ~60s degraded window. The runbook for the post-merge deploy MUST include a `gcloud run services add-iam-policy-binding` re-grant loop across all 17 callables (sample script in `audit/84 STEP 3`).

## Tests

### New unit tests (jest)

`functions/test/returnUrlValidation.test.ts` — 25 cases:
- 16 H-1 host-only validation (legit + 8 attack vectors + 4 wildcard + 3 edge cases)
- 9 H-2 SF-073 localhost gate (PROD reject + emulator allow + project-id + allowlist-shape probes)

Result: **25/25 PASS** locally (1.7s).

### Extended firestore-rules tests

`functions/test/firestore_rules/bookings.test.ts` — appended F-99-01 section, 8 new cases:
- 7 deny probes (one per new deny-list field: `payment_intent_id`, `emails_sent`, `booking_reference`, `owner_id`, `created_at`, `source`, `provider_id`)
- 1 still-allowed probe (`internal_notes` — confirms deny-list narrow, doesn't accidentally close legitimate owner writes)

Result: **all 7 rules suites PASS, 105/111 cases pass + 6 skipped** (`npm run test:rules`, exit 0, 8.2s).

### Full unit-test suite

`npm test`: **430/431 PASS**. One unrelated 5000ms timeout flake in `test/bookingManagement.test.ts:119` (`onBookingCreated > should create an in-app notification for owner`) — pre-existing notification-emulator flake, **does not touch any file in this PR's scope**. Same-file siblings (`emails_sent.initial_trigger_processed` marker tests) pass green. Out of scope for this closure; tracked separately.

### Local build

`npm run build` (tsc): clean, no errors.

## Out of scope (deferred)

- **M-1 / M-2 / M-3** from audit/99 — explicitly excluded per user direction.
- **App Check enforcement** — separate work.
- **F-99-02 passwordHistory bcrypt-loop rate-limit** — MED, deferred (separate PR).
- **F-99-04 widget CSP scope** + **F-99-05 COOP** — `firebase.json` changes; separate PR.
- **F-99-06 devices.platform** mutation — LOW, defer.
- **F-99-07/08/09/10** — LOW, defer.
- **F-99-11..F-99-17** — LOW / INFO / latent / transitive.
- **`bookings` collection-group (CG) `update`** — the CG match at line 401-ish has no `update` rule = implicit deny. Subcollection path is the only writable surface, fixed. No CG mirror needed.

## PROD cutover

NOT in this PR. PROD deploy gated by:
1. Code review on PR.
2. Merge to `main` (operator-gated).
3. Pre-deploy verification of `functions/package-lock.json` (F-CUT-01 closed today via 167e6353 — confirmed in lockfile-drift memory).
4. Deploy CFs via `firebase deploy --only functions:<list>` (do NOT mass-deploy; staged per audit/90 runbook).
5. Post-deploy `gcloud run services add-iam-policy-binding ... allUsers/invoker` loop on all 17 callables (memory `cf-deploy-cors-shape-iam-strip` + audit/84 STEP 3).
6. Deploy rules via `firebase deploy --only firestore:rules` separately.
7. Smoke: post-deploy OPTIONS preflight on each of the 17 callables to confirm CORS allowlist response + IAM still grants `allUsers/invoker`.
8. Smoke: anon-write probe on `bookings` update with `payment_intent_id` → expect 403.
9. Smoke: returnUrl probe with `https://bookbed.io.evil.com/x` → expect `invalid-argument`.

## Branch / worktree state

- Worktree: `/tmp/bb-h99-wt`
- Branch: `fix/audit99-high-bundle`
- Base: `main` @ `167e6353` (F-CUT-01 lockfile fix).
- Files touched: 18 source + 2 test + 2 audit docs = 22 files.
- Branch-guard verified at each git op.

## Linked

- audit/99 (companion in PR)
- audit/90 (PROD cutover runbook)
- audit/89 / SF-062 (CORS allowlist sweep history)
- audit/78 Phase B / PR #554 (bookings deny-list origin)
- audit/86 / PR #578 / SF-068 (F-94 sibling closures)
- SF-073 (localhost PROD-exfil first close, in `stripePayment.ts`)
- Memory: `cf-deploy-cors-shape-iam-strip`, `sf050-prod-iam-gap-2026-05-29`, `cutover-lockfile-drift-2026-05-30`
