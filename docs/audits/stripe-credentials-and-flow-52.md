# Stripe Credentials & Flow Audit — audit/52

**Date:** 2026-05-26
**Scope:** BookBed two-project Stripe surface (`bookbed-dev` test / `rab-booking-248fc` LIVE) after PR #481 (F-50-04 `widget_settings.stripe_config.secret_key` removal) merged `a847497e`.
**Mode:** Read-only.

---

## TL;DR

- **F-50-04 closure introduced a charge-model/refund-pattern mismatch.** Checkout creates a **Destination Charge** (`transfer_data.destination` + `on_behalf_of`, PI on platform) but `guestCancelBooking.ts` now refunds via `{stripeAccount: ownerStripeAccountId}` (Direct-Charge pattern). PI does not live on the connected account → refund call expected to fail with `No such payment_intent`. Latent until a guest cancellation hits the deadline window. **P0.**
- **`customer.subscription.deleted` webhook blindly downgrades lifetime users.** No `accountType === "lifetime"` guard at `stripePayment.ts:1052-1058` — Stripe-side cancellation of any subscription tied to a lifetime user wipes their lifetime grant. **P0.**
- **`ALLOWED_SUBSCRIPTION_PRICE_IDS` empty on both env files — P3 deferred (re-classified 2026-05-26).** Structural evidence supersedes earlier P0 framing: (a) Stripe Dashboard `acct_1SIsGkBomKO7vDr0` (bookbed.io live) has **0 subscription products** via MCP `list_products`; (b) **zero call-graph consumers** in `lib/` for `SubscriptionRepository.createCheckoutSession` / `subscriptionRepositoryProvider`; (c) web `_showUpgradeDialog` shows a "Pro subscription coming soon!" `AlertDialog` (canary text — guarded by CI); (d) mobile path redirects to `app.bookbed.io` via `url_launcher` (App Store Reader-App pattern, commit `18dc6bca` 2026-01-14). Fail-CLOSED at `stripeSubscription.ts:51` is correct posture until the canary flips. **Reopen triggers** are codified in F-52-03 below.
- No `idempotencyKey` on any Stripe write call across 4 files (checkout/customers/refunds/accounts/accountLinks/billingPortal). No Stripe-event idempotency guard (`stripeEvents/{event.id}` Firestore dedup). No `automatic_tax` / `tax_id_collection`. iCal feed has zero subscription-status enforcement (cancelled subs keep serving). All flagged below.
- `.env.{development,production,staging}` at repo root contain `STRIPE_*` keys but no Flutter code loads them (no `flutter_dotenv` dep) — orphan files, not loaded at runtime. `.gitignore` covers them. No leak risk *today*, but the `sk_test_*` (107 chars, real) sitting in `.env.development` on dev machines is a soft hazard.

---

## Q1 — Test/live key separation

**State.** `functions/src/stripe.ts:12,22` — `stripeSecretKey = defineSecret("STRIPE_SECRET_KEY")` then `apiKey = stripeSecretKey.value()`. Single secret name, resolved per-project from GCP Secret Manager. Separation is **operator-enforced** (Secret Manager value per project), not code-enforced.

No prefix assertion. `getStripeClient()` accepts any string. A misconfigured Secret Manager value (sk_live_ on dev, sk_test_ on prod) would silently route real charges to the wrong account.

**Risk.** **P1.**
**Gap.** No defense-in-depth check analogous to the Dart `kDebugMode` Firebase project-ID assert (`.claude/rules/ios-development.md`).
**Fix.** In `getStripeClient()`, after `apiKey = stripeSecretKey.value()`:

```typescript
const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
const isProd = projectId === "rab-booking-248fc";
const expectedPrefix = isProd ? "sk_live_" : "sk_test_";
if (!apiKey.startsWith(expectedPrefix)) {
  throw new Error(`STRIPE_SECRET_KEY mode mismatch: project=${projectId} expects ${expectedPrefix}*`);
}
```

---

## Q2 — Publishable key separation

**State.** **No Flutter Stripe client lib used.** `pubspec.yaml` has no `flutter_stripe` / `stripe_*` dependency. Widget uses Stripe **Checkout (hosted)** — redirect to `session.url`, return via `success_url`. No `pk_*` ever ships in the Flutter bundle.

The `STRIPE_PUBLISHABLE_KEY` lines in `.env.development` / `.env.production` / `.env.staging` are **dead config** — no loader. `.env.production` value (`pk_live_XXXX...XXXX`, 32 chars) is a placeholder, not a real key. `.env.development` (107 chars `pk_test_*`) and `.env.staging` (same) contain real test-mode keys but nothing reads them.

**Risk.** **OK** (hosted-checkout model removes the need for a client publishable key).
**Gap.** Orphan env files invite cargo-culting; future devs may wire dotenv loading and ship the placeholder live key. The `STRIPE_SECRET_KEY=sk_test_...` lines in `.env.development` and `.env.staging` ARE real test secrets in plaintext on developer disks (acceptable per Stripe TOS but not ideal).
**Fix.** Delete the `STRIPE_*` lines from the three `.env.*` files, leave a `STRIPE_PUBLISHABLE_KEY=NOT_USED_HOSTED_CHECKOUT` comment so future readers don't re-add them.

---

## Q3 — Webhook signing secrets

**State.** One webhook endpoint: `handleStripeWebhook` (`stripePayment.ts:878`, `onRequest`, default `us-central1`). One secret: `STRIPE_WEBHOOK_SECRET` (`stripePayment.ts:35`). Per-project value via Secret Manager. **No separate Connect-webhook secret** because Destination-Charge model fires `charge.refunded` and subscription events on the platform endpoint already.

**Risk.** **OK** for current charge model. Becomes **P1** if checkout migrates to true Direct Charges — Connect events would fire on a *separate* webhook URL needing its own secret.
**Gap.** None today. Note documented assumption.
**Fix.** None. Add comment to `handleStripeWebhook` that this is the **platform** webhook only; if Connect-direct-charges adoption ever happens, add a `handleStripeConnectWebhook` with a `STRIPE_CONNECT_WEBHOOK_SECRET`.

---

## Q4 — Platform secret vs connected-account secrets

**State.** Single platform `STRIPE_SECRET_KEY` everywhere. All 4 files use `getStripeClient()`. Connected-account-scoped calls pass `{stripeAccount: ownerId}` header — confirmed at `guestCancelBooking.ts:342` (refund) and `stripeConnect.ts:147` (balance retrieve). No per-owner secret stored.

**Pre-#481 (legacy):** owner's own `stripe_config.secret_key` was stored on `widget_settings/{unitId}` (publicly readable) and used directly via `createStripeClient(stripeConfig.secret_key)`. PR #481 (commit `9b436342` / merged `a847497e`) removed that vector — confirmed by `git log -p`.

**Risk.** **OK** (secret consolidation correct).
**Gap.** Migration script `audit/migrations/41-scrub-widget-settings-secrets.js` must have run on all envs to scrub leftover `stripe_config.secret_key` fields. PROD scrub status not verified from this audit.
**Fix.** Operator: confirm migration 41 executed on `rab-booking-248fc`. `gcloud firestore export` → grep `stripe_config.secret_key`.

---

## Q5 — `ALLOWED_SUBSCRIPTION_PRICE_IDS` provisioning

**State.** `functions/.env:13` — `ALLOWED_SUBSCRIPTION_PRICE_IDS=` (empty value, base file). `functions/.env.rab-booking-248fc` — **line absent entirely** (per-env file overrides; missing line means empty after parse). No `functions/.env.bookbed-dev` exists at all.

Code at `stripeSubscription.ts:47-67` reads `process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS`, splits on `,`, filters empty, and **throws `HttpsError("failed-precondition", "Subscription pricing is not configured. Contact support.")` if `allowedPriceIds.length === 0`** — fail-CLOSED.

**Risk.** **P3 deferred (verified 2026-05-26).** Re-classified from earlier P0 framing on structural evidence: Stripe Dashboard `acct_1SIsGkBomKO7vDr0` live mode has **0 subscription products** (MCP `list_products`); no Flutter call-graph consumer for `SubscriptionRepository.createCheckoutSession` or `subscriptionRepositoryProvider` (`rg` audit across `lib/`); web `_showUpgradeDialog` is a "Pro subscription coming soon!" `AlertDialog`; mobile redirects to web dashboard via `url_launcher` per App Store Reader-App pattern. Fail-CLOSED at `stripeSubscription.ts:51` is double-protected (env-var fence + no live caller). Provisioning an allowlist before products exist would be cargo-cult.

**Active impact (verified 2026-05-26).** Zero call-graph consumers of `SubscriptionRepository.createCheckoutSession` in `lib/`. The `_showUpgradeDialog` web path shows a "coming soon" AlertDialog (canary). Mobile path redirects to `app.bookbed.io` via `url_launcher` (App Store Reader-App pattern, commit `18dc6bca`). The broken Cloud Function has no live caller; the `failed-precondition` exception is unreachable from current UI.

**Gap (closed by CI guard).** `scripts/check-no-stray-stripe-ui.sh` (added in same commit) fails when (a) a new caller of `SubscriptionRepository.createCheckoutSession` / `createPortalSession` / `subscriptionRepositoryProvider` appears, OR (b) the `_showUpgradeDialog` canary text ("coming soon" / "stay tuned") is removed. Either condition triggers reopen to P0 — see F-52-03 reopen triggers.

**Fix (when reopen fires).** Operator: run `tool/setup-pr462-env.sh` for both envs OR set explicitly:
- `functions/.env.bookbed-dev` → `ALLOWED_SUBSCRIPTION_PRICE_IDS=price_TEST1,price_TEST2,...` (test-mode IDs)
- `functions/.env.rab-booking-248fc` → `ALLOWED_SUBSCRIPTION_PRICE_IDS=price_LIVE1,price_LIVE2,...` (live-mode IDs)

See `audit/38-pr462-env-prereq.md` and `.claude/rules/stripe.md § Subscription Flow`. Format note: report value **counts + last-4** in audit output, never full IDs.

---

## Q6 — Charge flow

**State.** **Destination Charge.** `stripePayment.ts:798-803`:

```typescript
payment_intent_data: {
  on_behalf_of: ownerStripeAccountId,
  transfer_data: {
    destination: ownerStripeAccountId,
  },
},
```

PI created on **platform** (no `stripeAccount` header on `checkout.sessions.create`). Funds transferred to connected account via `transfer_data.destination`. Settlement merchant on Stripe Dashboard = connected account (via `on_behalf_of`), but the PI itself lives on the platform.

**Risk.** **OK** as a model. Compatible with single webhook endpoint.
**Gap.** `.claude/rules/stripe.md` says "Stripe Connect Model: Standard (Direct charges)" — **wrong**. The actual model is **Express** Connect (`stripeConnect.ts:56` — `type: "express"`) with **Destination Charges**. Documentation drift.
**Fix.** Update `.claude/rules/stripe.md`: change "Standard (Direct charges)" → "Express (Destination charges)". Also see Q14 — the doc drift caused F-52-01.

---

## Q7 — `application_fee_amount` (platform fee)

**State.** **No `application_fee_amount` anywhere.** `checkout.sessions.create` payload at `stripePayment.ts:778-835` has none in `payment_intent_data`. Platform takes **0%** of every booking. Stripe's own processing fee (1.4% + €0.25 EU cards) is charged to the connected account.

**Risk.** **OK** (intentional — BookBed monetizes via subscription, not per-booking commission).
**Gap.** `.claude/rules/stripe.md` line *"Fee (1.4% + €0.25) se SKIDA SA OWNER-A"* is correct but misread by memory-system note `pr482-j-smoke` ("application_fee_amount = 0" is confirmed; no fee floor needed).
**Fix.** None. Note in the doc: "Stripe processing fees are deducted from owner's payout by Stripe directly; BookBed does not add `application_fee_amount`."

---

## Q8 — Subscription billing

**State.** Subscriptions live entirely on the **platform** account, no Connect involvement. `stripeSubscription.ts:100-122` — `checkout.sessions.create` with `mode: "subscription"`, `customer: customerId`, `line_items[].price: priceId`. No `transfer_data`, no `on_behalf_of`. Lifetime license is **NOT a Stripe product** — it's a Firestore-only grant at `admin/setLifetimeLicense.ts:84-94` (`accountType: "lifetime"`, `accountStatus: "active"`). Lifetime users never create a subscription.

Price-ID gate: `stripeSubscription.ts:47-67` (see Q5).

**Risk.** **OK** model. Lifetime branch creates a footgun with `customer.subscription.deleted` — see Q16.
**Gap.** Region drift — `stripeSubscription.ts` does not set `region`, defaults to `us-central1`. Rest of BookBed billing-adjacent CFs (`setLifetimeLicense` etc.) are `europe-west1`. Documented as P3 in `audit/24`.
**Fix.** None for billing model. Region drift left to its existing P3 follow-up.

---

## Q9 — Webhook endpoints

**State.** One endpoint, one handler:

| Function | File:line | Region | Events handled |
|---|---|---|---|
| `handleStripeWebhook` | `stripePayment.ts:878` | `us-central1` (default) | `charge.refunded` (917), `checkout.session.expired` (975), `customer.subscription.deleted` (1025), `invoice.paid` (1066), `checkout.session.completed` (1116, both subscription + booking branches) |

No `handleStripeConnectWebhook` — Destination-Charge model means Connect events fire on platform endpoint by default.

**Risk.** **OK.**
**Gap.** Unknown events fall into the `else` at line 1387 (`logInfo` + `200 OK`). Some operationally-useful events not subscribed: `invoice.payment_failed` (sub renewal failure), `customer.subscription.updated` (plan change), `checkout.session.async_payment_*`, `payment_intent.payment_failed`.
**Fix.** Add `invoice.payment_failed` handler to flip user `accountStatus → past_due` with a grace window before next billing attempt. Verify Stripe Dashboard webhook subscription list matches handler branches.

---

## Q10 — Signature verification

**State.** `stripePayment.ts:898-902` — `stripeClient.webhooks.constructEvent(req.rawBody, sig, webhookSecret)`. **Fail-on-error**: catch block at 903-914 returns HTTP 400 + logs `logWebhookSignatureFailure` (security event). No quiet fallback. Missing-signature header check at 881-885 returns 400 with "likely bot/crawler" note.

Synchronous `constructEvent`, not `constructEventAsync`. `req.rawBody` is firebase-functions v2 default (already raw).

**Risk.** **OK.**
**Gap.** None.
**Fix.** None.

---

## Q11 — Event idempotency

**State.** **No `stripeEvents/{event.id}` guard.** Webhook re-delivery (Stripe's default retry on 5xx) would re-execute every branch. Partial protection inside each branch:

- `charge.refunded` (917): writes `refund_status: "processed"` — re-write is harmless.
- `checkout.session.completed` (1116) subscription branch: re-writes `accountStatus: "active"` — harmless re-up.
- `checkout.session.completed` (1116) booking branch: has booking-level idempotency at 1221 (`status === "confirmed" && stripe_session_id === session.id` → early return).
- `customer.subscription.deleted` (1025): re-writes `accountStatus: "trial_expired"` — *not* harmless if user re-subscribed between deliveries (would re-revoke).
- `invoice.paid` (1066): writes `lastPaymentAt: serverTimestamp()` — clobbers timestamp on every retry.

No `livemode` persistence.

**Risk.** **P1** (some branches are not idempotent — `customer.subscription.deleted` race + `invoice.paid` timestamp drift).
**Gap.** Audit/50 already flagged this as **F-50-03** (CRITICAL). This audit confirms unresolved.
**Fix.** First lines of `handleStripeWebhook` after `constructEvent` succeeds:

```typescript
const eventRef = db.collection("stripe_webhook_events").doc(event.id);
const result = await db.runTransaction(async (t) => {
  const snap = await t.get(eventRef);
  if (snap.exists) return "duplicate";
  t.create(eventRef, {
    receivedAt: admin.firestore.FieldValue.serverTimestamp(),
    type: event.type,
    livemode: event.livemode,
    apiVersion: event.api_version,
  });
  return "new";
});
if (result === "duplicate") {
  res.json({received: true, status: "duplicate"});
  return;
}
```

Add TTL (`expires_at` 30d + Firestore TTL policy) so the collection doesn't grow forever.

---

## Q12 — App Check / IP allowlist

**State.** `handleStripeWebhook` is `onRequest` with no auth (correct — Stripe is the unauthenticated caller, identity proven by signature). No IP allowlist defense-in-depth.

**Risk.** **OK** (signature verification is the right primary control). **P3** (no second layer).
**Gap.** A leaked webhook secret would let an attacker forge events; IP allowlist of Stripe's publicly-published egress ranges (https://docs.stripe.com/ips#webhook-notifications) would add belt-and-braces.
**Fix.** Optional. Match `request.ip` against Stripe's IP list at top of handler; deny anything else with 403. Maintenance cost (Stripe rotates ranges) probably exceeds value given solid signing.

---

## Q13 — Idempotency keys on Stripe write calls

**State.** **Zero `idempotencyKey` parameters across all Stripe write calls.** Inventory:

| Call | File:line | Operation | Has key? |
|---|---|---|---|
| `checkout.sessions.create` (booking) | `stripePayment.ts:778` | create checkout session | ❌ |
| `checkout.sessions.create` (subscription) | `stripeSubscription.ts:100` | create sub checkout | ❌ |
| `customers.create` | `stripeSubscription.ts:82` | create Stripe customer | ❌ |
| `refunds.create` | `guestCancelBooking.ts:331` | issue refund | ❌ |
| `accounts.create` | `stripeConnect.ts:55` | create Express account | ❌ |
| `accountLinks.create` | `stripeConnect.ts:82` | onboarding link | ❌ |
| `billingPortal.sessions.create` | `stripeSubscription.ts:157` | customer portal | ❌ |
| `accounts.retrieve` (×2) | `stripePayment.ts:303`, `stripeConnect.ts:137` | read, no idempotency needed | n/a |
| `balance.retrieve` | `stripeConnect.ts:146` | read, no idempotency needed | n/a |

**Risk.** **P1.** Network retry on any write call → duplicate Stripe object. Refund and accounts.create are the highest-impact (duplicate refund = real money out; duplicate Express account creates orphan in the connected list).

**Gap.** Pattern absent from the codebase.

**Fix.** Per-call. Examples:

- `refunds.create` — `idempotencyKey: \`refund-${bookingId}\`` (booking-level uniqueness)
- `accounts.create` — `idempotencyKey: \`connect-${ownerId}\`` (already gated by `if (!stripeAccountId)` so retry safe at app level, but defense-in-depth)
- `checkout.sessions.create` booking — `idempotencyKey: \`checkout-${placeholderBookingId}\`` (placeholder doc is the natural unique key)
- `checkout.sessions.create` subscription — `idempotencyKey: \`sub-checkout-${userId}-${priceId}-${Date.now() bucket}\`` (no natural unique; window-based)
- `customers.create` — `idempotencyKey: \`customer-${userId}\`` (one per user)

Each via `{idempotencyKey: "..."}` as the second arg.

---

## Q14 — Refund paths

**State.** Two refund triggers:

1. **Guest-initiated** (`guestCancelBooking.ts:299-373`) — guest provides booking ref + email, deadline checked (`cancellation_deadline_hours`, default 48h), full paid amount refunded if `paymentStatus === "paid"`. Comment at 302-311 says "Direct Charges pattern, mirrors stripePayment.ts" — **but stripePayment.ts uses Destination Charges** (see Q6). Refund call at 331:

   ```typescript
   const refund = await stripe.refunds.create(
     {
       payment_intent: paymentIntentId,
       amount: Math.round(cancellationResult.refundAmount * 100),
       reason: "requested_by_customer",
       metadata: {...},
     },
     {stripeAccount: ownerStripeAccountId}
   );
   ```

   `{stripeAccount}` header scopes the call to the connected account. But the PI was created on the **platform** (Destination Charge) — calling `refunds.create` on the connected account asks Stripe to find a PI that doesn't exist there. Expected failure: `No such payment_intent: pi_xxx`.

2. **Owner / Stripe Dashboard-initiated** — manual refund via Stripe Dashboard fires `charge.refunded` webhook, handled at `stripePayment.ts:917-974` (mirrors `refund_amount` + `refund_status: "processed"` onto the booking doc). This path is correct for Destination charges (Dashboard knows which account holds the charge).

**Refund authorization.** Guest refund gated by booking-ref + email match (`guestCancelBooking.ts:122-136`). No role check beyond identity proof. No owner-initiated refund Cloud Function exists (owners would use Stripe Dashboard directly). Audit log: `logSuccess`/`logError` to Cloud Logging; no `security_events` write for refunds specifically.

**Per-iteration safety.** `refunds.create` lacks `idempotencyKey` (Q13). Mitigated by transaction-level idempotency at `guestCancelBooking.ts:204-220` (`alreadyCancelled` short-circuit), but Stripe-call-level retry inside the same invocation is not protected.

**Risk.** **P0** — F-52-01 latent (refund-pattern mismatch). **P1** — no idempotencyKey.

**Gap.** This is the highest-confidence finding in the audit. Comment-vs-code drift confirmed by reading PR #481 diff:

```
+ // Refund via platform Stripe key + Connect account header (Direct Charges
+ // pattern, mirrors stripePayment.ts). ...
- const stripe = createStripeClient(stripeConfig.secret_key);
- const refund = await stripe.refunds.create({ payment_intent, amount, ... });
+ const refund = await stripe.refunds.create(
+   { payment_intent, amount, ... },
+   {stripeAccount: ownerStripeAccountId}
+ );
```

The old code used the *owner's* secret key directly (no header) — which worked because the charge was on the owner's account under that key. The new code uses *platform* key + `stripeAccount` header — which would work only if the charge were a true Direct Charge. Since checkout actually creates Destination Charges, the new refund path is mis-targeted.

**Fix.** Remove the `{stripeAccount: ownerStripeAccountId}` header in `guestCancelBooking.ts:342`:

```typescript
const refund = await stripe.refunds.create({
  payment_intent: paymentIntentId,
  amount: Math.round(cancellationResult.refundAmount * 100),
  reason: "requested_by_customer",
  reverse_transfer: true, // needed: claw funds back from connected acct on Destination refund
  metadata: { booking_id: bookingId, booking_reference: bookingReference, cancelled_by: "guest" },
  // idempotencyKey passed as second arg, NOT in body
}, { idempotencyKey: `refund-${bookingId}` });
```

The `reverse_transfer: true` flag is mandatory when refunding a Destination Charge: it reverses the original `transfer_data.destination` transfer so funds are clawed back from the connected account, otherwise platform refunds out of pocket. No `application_fee_amount` is set on the charge so `refund_application_fee` is not needed.

**Validation before deploy.** Hit a `bookbed-dev` test-mode booking → guest cancel → tail `gcloud logging read 'jsonPayload.message=~"Failed to process Stripe refund"' --project=bookbed-dev`. Without the fix, the log should show "No such payment_intent" errors.

---

## Q15 — PII / PCI scope

**State.** **Out of scope.** Card data never touches BookBed servers. Stripe Checkout (hosted, redirect-based) means PAN/CVV are entered on `checkout.stripe.com`. Server only sees `payment_intent_id` (`pi_*`) and `session_id` (`cs_*`) — both safe to log/store.

Firestore booking docs store: `payment_intent_id`, `stripe_session_id`, `stripe_refund_id`, `payment_status`, `paid_amount`, `refund_amount`, `refund_status`. No card metadata.

**Risk.** **OK** — SAQ-A scope only (hosted-payment-page).
**Gap.** None.
**Fix.** None.

---

## Q16 — Lifetime license vs subscription

**State.** Lifetime is a Firestore grant (`accountType: "lifetime"`, `accountStatus: "active"`) set by `admin/setLifetimeLicense.ts:84-94`. Not a Stripe object — no `stripeSubscriptionId` written. Lifetime users should NEVER hit the subscription checkout (no UI path to it — verify).

**Footgun:** `customer.subscription.deleted` webhook (`stripePayment.ts:1025-1065`) finds user by `stripeSubscriptionId`, then unconditionally writes:

```typescript
await userDoc.ref.update({
  accountStatus: "trial_expired",
  stripeSubscriptionStatus: "canceled",
  ...
});
```

**No `accountType === "lifetime"` guard.** Transition path that would trigger this: user buys monthly sub → admin later grants lifetime via `setLifetimeLicense` (which writes `accountStatus: "active"` but does NOT cancel the Stripe sub or clear `stripeSubscriptionId`) → sub eventually cancels via Stripe (failed payment, voluntary cancel via customer portal) → webhook downgrades the lifetime user to `trial_expired` despite them being a lifetime holder.

**Risk.** **P0** (data-loss class — silently revokes lifetime entitlement).

**Gap.** No state-machine guard between grant and subscription lifecycle.

**Fix.** In `customer.subscription.deleted` handler at `stripePayment.ts:1052`:

```typescript
const userData = userDoc.data();
if (userData?.accountType === "lifetime") {
  // Cancel lingering Stripe sub on a lifetime user — don't touch accountStatus.
  await userDoc.ref.update({
    stripeSubscriptionStatus: "canceled",
    stripeSubscriptionId: admin.firestore.FieldValue.delete(),
    statusChangedAt: admin.firestore.FieldValue.serverTimestamp(),
    statusChangedBy: "system_webhook",
    statusChangeReason: "subscription_canceled_lifetime_user_unchanged",
  });
  res.json({received: true, status: "lifetime_user_protected"});
  return;
}
// existing trial_expired path
```

Symmetric fix in `setLifetimeLicense.ts` — when granting lifetime, cancel any active Stripe subscription via API (`stripe.subscriptions.cancel(subId)`) so the webhook never fires.

---

## Q17 — Plan downgrade on cancellation

**State.** `customer.subscription.deleted` writes `accountStatus: "trial_expired"`. No grace period — hard cutoff at webhook receipt. Effects depend on consumers of `accountStatus`:

- **Widget access** — bookings continue to function (no `accountStatus` check in `createStripeCheckoutSession` or `atomicBooking.ts`).
- **iCal feed** — see Q18 — also unaffected by `accountStatus`.
- **Owner dashboard UI** — Flutter app likely shows trial-expired banner / upgrade CTA (not verified here).
- **Stripe Connect onboarding** — `createStripeConnectAccount` has no `accountStatus` gate.

**Risk.** **P2.** Hard cutoff is acceptable for SaaS, but with **no guard on widget/iCal/Connect paths**, the only actual consequence of a "cancelled" subscription is a UI banner — there's no enforcement.

**Gap.** Subscription is effectively decorative — paying customers and trial-expired customers get the same backend behavior.

**Fix.** Decision needed (open question for Duško). Options:
1. Soft enforcement — show UI banner, no functional restriction. (Current behavior.)
2. Hard enforcement — gate `createStripeCheckoutSession` on `accountStatus in ("active","trial")`. Guests still able to view widget but cannot complete a booking through a trial-expired owner's units.
3. Grace period — add `subscription_grace_period_ends_at` field, gate enforcement after grace window.

---

## Q18 — iCal feed vs subscription status

**State.** `icalExport.ts:92` (`getUnitIcalFeed`) — `onRequest` public endpoint. Token-gated via `widget_secrets.ical_export_token` (or legacy `widget_settings.ical_export_token`). **Zero `accountStatus` check.** A cancelled (trial_expired) owner's iCal feed continues to serve at full fidelity — Booking.com / Airbnb / Adriagate keep syncing.

**Risk.** **P2** (continuation-of-service after non-payment).
**Gap.** Same as Q17 — no enforcement layer.
**Fix.** Add owner-status check before serving:

```typescript
const ownerDoc = await db.collection("users").doc(ownerId).get();
const accountStatus = ownerDoc.data()?.accountStatus;
if (accountStatus === "trial_expired" || accountStatus === "suspended") {
  response.status(402).send("Subscription required for iCal feed access");
  return;
}
```

(402 Payment Required is the canonical status.) Caveat: lookup adds a Firestore read per feed request — mitigate by caching `accountStatus` in the existing `widget_settings.ical_cache_*` shape, refreshed on status-change webhook.

---

## Q19 — VAT / Stripe Tax

**State.** **No `automatic_tax: { enabled: true }` anywhere.** `rg automatic_tax functions/src` → 0 hits. Neither booking checkout nor subscription checkout invokes Stripe Tax. No `tax_id_collection` either.

For booking checkout — guest is paying property owner (merchant of record per `.claude/rules/stripe.md`). VAT is the owner's responsibility under HR tax law (typically `obrt-paušalist` flat-rate scheme covers it). BookBed is not the merchant of record for guest bookings, so Stripe Tax on the booking checkout would be incorrect.

For subscription checkout — BookBed IS the merchant of record. Subscription tiers are sold from BookBed → owner. Per memory note, Duško operates the platform without a registered business entity — this is a tax-status problem upstream of Stripe Tax. Until BookBed has an EU OSS / Croatian VAT registration, `automatic_tax: true` would fail or charge incorrectly.

**Risk.** **P2** (compliance debt, not active vulnerability).

**Gap.** No Stripe Tax integration plan documented. Subscription revenue accrues to a non-registered entity — eventual EU tax authority interest is a P2 business risk, not a code risk.

**Fix.** Defer to business decision. Once BookBed registers a business entity:
1. Enable Stripe Tax on platform account (dashboard).
2. Add `automatic_tax: { enabled: true }` to `stripeSubscription.ts:100-122` `checkout.sessions.create`.
3. Set `tax_id_collection: { enabled: true }` to let business customers provide VAT ID for B2B-VAT-exempt invoicing.

---

## Q20 — `tax_id_collection`

**State.** Not enabled anywhere (see Q19).
**Risk.** **P3** — no tax ID captured on subscription checkout. Currently fine because no Stripe Tax → no invoice line uses the VAT ID.
**Gap.** B2B customers (owners running an `obrt`, `j.d.o.o.`, etc.) cannot have their VAT ID on Stripe invoices for accounting.
**Fix.** When (if) Stripe Tax is enabled, also set `tax_id_collection: { enabled: true }` and `customer_update: { name: 'auto', address: 'auto' }` so Stripe builds compliant invoices.

---

## Top P0 findings (2 active, 1 deferred)

### F-52-01 — Refund pattern mismatched with charge model (LATENT)

**Files.** `functions/src/guestCancelBooking.ts:331-343` (refund call) vs `functions/src/stripePayment.ts:798-803` (charge creation).

**Issue.** Checkout creates a Destination Charge (PI on platform, `transfer_data.destination` → connected acct). Refund call uses Direct-Charge pattern (`{stripeAccount: ownerStripeAccountId}` header → asks Stripe to find PI on connected account). PI doesn't exist there. Expected error: `No such payment_intent: pi_xxx`. Also missing `reverse_transfer: true` which a Destination refund needs to claw funds back from the connected account.

**Status.** LATENT. No evidence of exercise yet. Verify via `gcloud logging read 'jsonPayload.message=~"Failed to process Stripe refund"'` on both projects, last 90d. Zero hits → not yet triggered.

**Fix.** See Q14 fix block. Two-line change + `reverse_transfer: true` + idempotencyKey. Validate in dev with a test-mode booking + guest cancel.

**Tracker.** Propose `SF-035`.

---

### F-52-02 — Lifetime users silently downgraded by webhook

**File.** `functions/src/stripePayment.ts:1025-1058`.

**Issue.** `customer.subscription.deleted` handler unconditionally writes `accountStatus: "trial_expired"` for any user found by `stripeSubscriptionId`. No `accountType === "lifetime"` check. Transition path: user buys monthly sub, admin grants lifetime via `setLifetimeLicense` (doesn't cancel sub), Stripe later cancels sub → lifetime grant revoked.

**Fix.** See Q16 fix block. Add `if (userData.accountType === "lifetime") { ... }` short-circuit before the downgrade. Plus symmetric fix in `setLifetimeLicense.ts` to cancel any lingering sub at grant-time.

**Tracker.** Propose `SF-036`.

---

### F-52-03 — DEFERRED (P3, re-classified 2026-05-26 from earlier P0 framing)

**Files.** `functions/.env:13` (empty value), `functions/.env.rab-booking-248fc` (line absent), no `functions/.env.bookbed-dev`. Consumer: `functions/src/stripeSubscription.ts:47-67`.

**Issue.** `createSubscriptionCheckoutSession` reads the env var, splits + filters, throws `HttpsError("failed-precondition", "Subscription pricing is not configured. Contact support.")` if the allowlist is empty.

**Active impact (verified 2026-05-26).** Zero call-graph consumers of `SubscriptionRepository.createCheckoutSession` in `lib/`. The `_showUpgradeDialog` web path shows a "Pro subscription coming soon!" `AlertDialog` (canary text — guarded by CI, see scripts/check-no-stray-stripe-ui.sh). Mobile path redirects to `app.bookbed.io` via `url_launcher` (App Store Reader-App pattern, commit `18dc6bca` 2026-01-14). The broken Cloud Function has no live caller; the `failed-precondition` exception is unreachable from current UI.

**Re-classification rationale.** Structural protection is double-layered: (a) Stripe Dashboard has 0 products → no checkout intent to honour even if invoked; (b) UI has no caller path → checkout function cannot be invoked. Fail-CLOSED at `stripeSubscription.ts:51` is correct posture until the canary flips. Provisioning empty env vars before products exist would be cargo-cult — not "preparing for launch" but "shipping a misconfiguration that no operator workflow exercises". The earlier P0 framing under-estimated the structural barriers; pre-canary, the time-bomb has no fuse path.

**Reopen triggers (any one → P0, run fix block + remove canary guard in same PR):**
1. **Stripe Dashboard publishes any product** in `acct_1SIsGkBomKO7vDr0` (live) or test-mode account — `list_products` returns non-empty. Provisioning the allowlist is then mandatory before any further deploy.
2. **UI route `/upgrade`, `/pricing`, `/subscribe`** (or equivalent) wired in `lib/core/config/router_*.dart` with real navigation — *not* a placeholder dialog.
3. **`createSubscriptionCheckoutSession` literal appears in any new file** under `lib/` outside `subscription_repository.dart`.
4. **Any new `ref.watch(subscriptionRepositoryProvider)` / `ref.read(subscriptionRepositoryProvider)` consumer**, OR any new caller of `SubscriptionRepository.createCheckoutSession` / `.createPortalSession`. **The CI guard at `scripts/check-no-stray-stripe-ui.sh` enforces this and the canary text — removing the "coming soon" / "stay tuned" body from `_showUpgradeDialog` trips the same reopen.**

**Fix path (when reopened).** See Q5 fix block. Operator: run `tool/setup-pr462-env.sh` for both envs *before* the triggering commit merges. Plus update the CI guard to also assert env-var is non-empty whenever the Flutter bundle contains the new caller — currently the guard is canary-text-only because the caller doesn't exist yet.

**Tracker.** `SF-037` — status: **Deferred (P3)**, depends on subscription tier launch + canary removal.

---

> **Next-most-impactful finding (P1, surface F-52-05 / SF-039):** no `idempotencyKey` on any of 7 Stripe write calls (`refunds.create`, `checkout.sessions.create` ×2, `customers.create`, `accounts.create`, `accountLinks.create`, `billingPortal.sessions.create`). Network retry of any one → duplicate Stripe object. Refund and `accounts.create` are the highest-impact. The hotfix PR (#508) closes idempotency for `refunds.create` only; remaining 6 sites need a sweep. Worth a dedicated follow-up PR even though it's not P0.

---

## Proposed SF tracker entries

| ID | Title | Severity | Status |
|---|---|---|---|
| SF-035 | Stripe refund pattern realigned with Destination Charge model + idempotencyKey + reverse_transfer | P0 | Open (latent) |
| SF-036 | `customer.subscription.deleted` webhook respects `accountType === "lifetime"` | P0 | Open |
| SF-037 | `ALLOWED_SUBSCRIPTION_PRICE_IDS` provisioned on `rab-booking-248fc` + `bookbed-dev` runtime | P3 | Deferred (2026-05-26) — 0 Stripe products + 0 call-graph consumers + canary dialog. Reopen triggers per F-52-03. CI guard `scripts/check-no-stray-stripe-ui.sh` enforces. |
| SF-038 | Stripe-event idempotency via `stripe_webhook_events/{event.id}` Firestore dedup | P1 | Open (also audit/50 F-50-03) |
| SF-039 | `idempotencyKey` on every Stripe write call (refunds/customers/accounts/sessions) | P1 | Open |
| SF-040 | `getStripeClient()` prefix assertion (sk_test vs sk_live per GCLOUD_PROJECT) | P1 | Open |
| SF-041 | iCal feed enforces `accountStatus` (cancelled subs cannot serve feeds) | P2 | Open (product decision needed) |
| SF-042 | `invoice.payment_failed` webhook handler + sub past_due grace state | P2 | Open |
| SF-043 | `.env.{development,production,staging}` orphan Stripe key cleanup | P2 | Open |
| SF-044 | `.claude/rules/stripe.md` Connect-model documentation (Express + Destination, not Standard + Direct) | P3 | Open |

(Ceiling per `docs/SECURITY_FIXES.md` is `SF-034`; next available is `SF-035`.)

---

## Open questions for Duško

1. **Q14 / F-52-01** — Has any production refund completed successfully since PR #481 merged (`a847497e`, 2026-05-25)? If yes, my Destination-vs-Direct reading is wrong; if no, please run a test-mode guest-cancel through `bookbed-dev` and check the function logs for "No such payment_intent" before relying on the refund flow in PROD.
2. **Q5 / F-52-03** — Deferred to P3 on 2026-05-26 after structural verification (0 Stripe products + 0 call-graph consumers + canary "coming soon" dialog). CI guard `scripts/check-no-stray-stripe-ui.sh` enforces reopen triggers. Subscription tier launch timeline?
3. **Q17** — Is subscription enforcement intentional-soft (UI-only) or should `accountStatus` gate widget bookings + iCal feeds? Audit `accountStatus` consumers across the Flutter app and CF surface to confirm scope.
4. **Q19** — Business-entity registration timeline? Stripe Tax cannot be enabled correctly until the platform side has a tax-registered entity. Defer Q19/Q20 fixes accordingly.
5. **Q4 migration cleanup** — Did `audit/migrations/41-scrub-widget-settings-secrets.js` run on PROD Firestore, or only DEV? Per `memory/pr482-j-smoke-2026-05-26.md`, dev migration executed (2 docs). PROD status unknown from this audit.

---

## Verification commands (suggested next steps)

```bash
# F-52-01 — check for refund failures post-#481
gcloud logging read 'jsonPayload.message=~"Failed to process Stripe refund" OR jsonPayload.message=~"No such payment_intent"' \
  --project=rab-booking-248fc --freshness=90d --format=json | jq '.[] | {ts:.timestamp, msg:.jsonPayload.message}'
gcloud logging read 'jsonPayload.message=~"Failed to process Stripe refund" OR jsonPayload.message=~"No such payment_intent"' \
  --project=bookbed-dev --freshness=90d --format=json | jq '.[] | {ts:.timestamp, msg:.jsonPayload.message}'

# F-52-03 — confirm ALLOWED_SUBSCRIPTION_PRICE_IDS at runtime
gcloud functions describe createSubscriptionCheckoutSession \
  --gen2 --region=us-central1 --project=rab-booking-248fc \
  --format='value(serviceConfig.environmentVariables.ALLOWED_SUBSCRIPTION_PRICE_IDS)'
gcloud functions describe createSubscriptionCheckoutSession \
  --gen2 --region=us-central1 --project=bookbed-dev \
  --format='value(serviceConfig.environmentVariables.ALLOWED_SUBSCRIPTION_PRICE_IDS)'

# Q4 migration verification
gcloud firestore export gs://rab-booking-248fc-firestore-export/audit52-widget-settings \
  --collection-ids=widget_settings --project=rab-booking-248fc
# (then download + grep for "secret_key" / "stripe_config")
```

---

**No code modified.** Read-only audit. Files inspected: `functions/src/stripe.ts`, `stripePayment.ts`, `stripeConnect.ts`, `stripeSubscription.ts`, `guestCancelBooking.ts`, `getBookingByStripeSession.ts`, `admin/setLifetimeLicense.ts`, `icalExport.ts:1-100`, `cleanupExpiredPendingBookings.ts:1-130`, `functions/.env`, `functions/.env.rab-booking-248fc`, `.env.{development,production,staging}`, `pubspec.yaml`, plus `docs/SECURITY_FIXES.md` SF index. Git log on `guestCancelBooking.ts` consulted for PR #481 diff.
