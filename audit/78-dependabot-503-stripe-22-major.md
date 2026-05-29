# audit/78 — Dependabot PR #503: Stripe Node SDK 19.1.0 → 22.2.0 major bump adapt

**Date:** 2026-05-29
**PR:** [#503](https://github.com/DanLika/rab_booking/pull/503) `dependabot/npm_and_yarn/functions/stripe-22.1.1`
**Worktree branch:** `ops/dependabot-503-stripe-22-adapt` → fast-forwarded onto PR head
**Scope:** Cloud Functions only (`functions/src/stripe.ts`, `functions/src/stripeConnect.ts`, `functions/src/stripePayment.ts`).
**No PROD touches** — no Stripe Dashboard, no rule edits, no env-var rotations. Webhook endpoint api_version pin preserved per `[[stripe-webhook-api-version-immutable]]`.

## 1. CI failure pre-adapt

`gh run view 26454049400 --log-failed` — `Test Cloud Functions` job died at `tsc` with 12 errors:

```
src/stripe.ts(15,13): TS2709 Cannot use namespace 'Stripe' as a type.
src/stripe.ts(20,36): TS2709 Cannot use namespace 'Stripe' as a type.
src/stripe.ts(27,7):  TS2322 Type '"2025-09-30.clover"' is not assignable to type '"2026-04-22.dahlia"'.
src/stripeConnect.ts(150,49): TS7006 Parameter 'b' implicitly has an 'any' type.
src/stripeConnect.ts(154,45): TS7006 Parameter 'b' implicitly has an 'any' type.
src/stripePayment.ts(894,21):  TS2694 Namespace 'StripeConstructor' has no exported member 'Event'.
src/stripePayment.ts(918,48):  TS2694 Namespace 'StripeConstructor' has no exported member 'Charge'.
src/stripePayment.ts(976,49):  TS2694 Namespace 'StripeConstructor' has no exported member 'Checkout'.
src/stripePayment.ts(1029,54): TS2694 Namespace 'StripeConstructor' has no exported member 'Subscription'.
src/stripePayment.ts(1070,49): TS2694 Namespace 'StripeConstructor' has no exported member 'Invoice'.
src/stripePayment.ts(1117,49): TS2694 Namespace 'StripeConstructor' has no exported member 'Checkout'.
```

Local `tsc --noEmit` reproduced + added one new error after the first round of fixes:
`src/stripeConnect.ts(182,11): TS2353 'stripeAccount' does not exist in type 'BalanceRetrieveParams'.`

## 2. Breaking changes adapted

| # | Change (v22 CHANGELOG / migration guide) | Old call-site | New call-site |
|---|---|---|---|
| 1 | "CJS entry point no longer exports `.default` or `.Stripe` as separate properties." Default import is now the callable wrapper `StripeConstructor`; the class type lives at `Stripe.Stripe`. | `let stripe: Stripe \| null`; `getStripeClient(): Stripe` | `let stripe: Stripe.Stripe \| null`; `getStripeClient(): Stripe.Stripe` |
| 2 | `Stripe.<Resource>` (Event/Charge/Checkout.Session/Subscription/Invoice) — the namespace types live in the inner `stripe.core` namespace, not re-exported through the CJS bridge. | `event.data.object as Stripe.Charge` (and 5 sibling casts) | drop cast — v22 typed-event union narrows `event.data.object` via `event.type` discriminant automatically |
| 3 | `Stripe.HttpClient` type position lookup fails (it's a value, not type) | `const stripeHttpClient: Stripe.HttpClient = Stripe.createFetchHttpClient()` | drop annotation, let TS infer |
| 4 | `apiVersion` constructor option narrowed to the latest pinned API version (`"2026-05-27.dahlia"` in v22.2.0). PROD webhook endpoint api_version is `"2025-09-30.clover"` and per `[[stripe-webhook-api-version-immutable]]` cannot be rotated without a 6-step procedure. | `apiVersion: "2025-09-30.clover"` | `apiVersion: "2025-09-30.clover" as any` with eslint-disable + comment pointing at audit/68 |
| 5 | `Stripe` import now unused in `stripePayment.ts` after dropping the cast types. | `import Stripe from "stripe";` (only used for type lookups, all gone) | removed |
| 6 | `balance.retrieve` — `stripeAccount` moved from `BalanceRetrieveParams` (1st arg, params) to `RequestOptions` (2nd arg). v21 SDK was permissive; v22 type-checks strictly. | `balance.retrieve({stripeAccount: id})` | `balance.retrieve({}, {stripeAccount: id})` |

**Implicit-any in stripeConnect.ts:185/189** — the `b => ({...})` sort callbacks were flagged in CI's v22.1.1 run but disappeared as a cascade effect once the `Stripe.Stripe` type narrowing was correct. No explicit annotation needed in v22.2.0.

## 3. Verification

```
$ npx tsc --noEmit
(no output — 0 errors)

$ npm test
Test Suites: 19 passed, 19 total
Tests:       387 passed, 387 total
Time:        11.732 s
```

ts-jest emits 10× `TS151002` warnings (hybrid module-kind + `isolatedModules: false`) — pre-existing on `main`, unrelated to Stripe bump.

## 4. PROD-safety notes

- The PROD webhook endpoint at `we_1SgiznBomKO7vDr0CSwE9NNj` (audit/68 §1) is pinned to api_version `2025-09-30.clover` (Stripe Dashboard, immutable per audit/68 Task 4). This PR preserves that pin on the SDK client. **No Stripe Dashboard action required.**
- v22 changes the SDK's serializer when constructing requests, but our request shapes are unchanged. The clover→dahlia delta consists of param additions + `decimal_string` typing — none of our paths touch the affected fields.
- F-50-03 dedup table (`stripe_webhook_events/{event.id}`) still keys on `event.id`; v22 event-id format unchanged.

## 5. Deferred (NOT in this PR)

- `tsconfig.json` `module: "NodeNext"` is forcing CJS resolution for the entire functions/ tree; switching to ESM would let us use the cleaner `import Stripe from "stripe"` + `Stripe.<Resource>` pattern. That's a project-wide refactor — out of scope.
- ts-jest `isolatedModules: true` migration (TS151002 warnings) — pre-existing, separate cleanup.
- Stripe Dashboard webhook api_version rotation `clover → dahlia` — the 6-step rotation is tracked separately as F-61-03 in audit/68.

## 6. Commit + push

```
44dc95fe fix(stripe): adapt to v22 SDK type/namespace + Balance API changes
```

Fast-forwarded onto PR #503's branch (`dependabot/npm_and_yarn/functions/stripe-22.1.1`) at `c2b9ec85..44dc95fe`. Dependabot rebases would lose this commit; if dependabot reopens, re-cherry-pick.

## 7. Memory deltas

- No new memory file needed. The findings — (a) v22 CJS namespace fracture and (b) the `apiVersion` cast pattern — are captured in this audit doc + commit message. Cross-referenced from `[[stripe-webhook-api-version-immutable]]`.
