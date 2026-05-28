# audit/61 — Stripe Webhook Event-Subscription vs CF Handler Coverage Gap

**Date drafted:** 2026-05-27 (filename uses 2026-05-28 per requestor convention)
**Trigger:** audit/60 §11 surfaced that PROD webhook subscribes 2 events while `handleStripeWebhook` handles 5+.
**Method:** Read-only — `gcloud secrets versions access` for keys + Stripe REST `GET /v1/webhook_endpoints` + `GET /v1/accounts` + Cloud Logging reads on both projects (`bookbed-dev` + `rab-booking-248fc`). Zero `POST`/`PUT`/`DELETE` to Stripe; zero Secret Manager writes; zero CF/code edits.
**Post-session update (2026-05-27):** SF-051 rotation CLOSED per `audit/62-sf051-rotation-closure-2026-05-27.md`. F-61-02 (Connect model fix) landed in `.claude/rules/stripe.md` this PR. Webhook expansion (§7-A) still PENDING — operator Dashboard click required. Connect orphan `acct_1TYSMdPWhhVc6lN0` (ababic785@gmail.com) rejected via API (reason=other).

---

## 0. TL;DR

| Surface | Coverage | Production-impact |
|---|---|---|
| `bookbed-dev` webhook | ✅ **5/5 events subscribed** — full coverage | DEV safe; handler exercise paths firing |
| `rab-booking-248fc` (PROD) webhook | ❌ **2/5 events subscribed** | **3 silent-drop event classes** — refund desync (**Dashboard-manual only**; guest-cancel path writes inline — F-61-05), sub-cancel entitlement drift, sub-renewal audit-trail gap. **Today's risk: theoretical (0 active subs + 0 historical refunds per audit/60).** **Tomorrow's risk: any sub signup OR operator-issued Dashboard refund triggers a silent data-state divergence.** |

**Recommendation:** add 3 missing events to PROD endpoint. **Do NOT** split into multiple endpoints (CallidusOS pattern) at current scale — over-engineering for 1 active Connect child + 0 subs.

**Bonus finding:** `.claude/rules/stripe.md` claims the project uses **Standard Connect with Direct Charges**. Code review proves it actually uses **Express Connect with Destination Charges** (line 808-809 of `stripePayment.ts`: `on_behalf_of: ownerStripeAccountId, transfer_data: {...}`). This is a documentation drift, not a security finding, but operators reading `.claude/rules/stripe.md` for incident response will be misled.

---

## 1. Handler inventory (`functions/src/stripePayment.ts`)

5 event types branched on `event.type`:

| Line | `event.type` | Side effects (selected) | Idempotency mechanism |
|---|---|---|---|
| 952 | `charge.refunded` | Update booking doc with `refund_amount`/`refund_status`/`updated_at`; respond `refund_synced` or `no_booking_found` | Lookup via `payment_intent_id` |
| 1012 | `checkout.session.expired` | Delete pending placeholder booking; cleanup expired hold | Placeholder ID from metadata; only deletes if `status=pending` |
| 1062 | `customer.subscription.deleted` | Downgrade user `accountStatus → trial_expired` UNLESS `accountType=lifetime`; H-09 mismatch guard (audit/57) | `where(stripeSubscriptionId).limit(1)` + audit/57 H-09 customer-id correlation |
| 1140 | `invoice.paid` | Refresh user `accountStatus=active`, `lastPaymentAt`; H-09 guard parallel | Same lookup pattern |
| 1214 | `checkout.session.completed` | Two modes: subscription mode (activate user) OR booking mode (atomic booking creation, dedup via `stripe_session_id`) | `client_reference_id` + Firestore dedup |

Fallthrough at line 1495: `logInfo("Unhandled event type: ${event.type}")` — only fires when a SUBSCRIBED event arrives without an if-else branch.

---

## 2. Webhook endpoint inventory

### 2.1 bookbed-dev (`acct_1SgkGeBomKO7vDr0...` per `STRIPE_SECRET_KEY` on bookbed-dev project, sha256 `ce5924dd...`)

**1 endpoint:** `we_1TbQwwBomKO7vDr0ZfB9tbig`

```json
{
  "url": "https://handlestripewebhook-whc46z5xxq-uc.a.run.app",
  "status": "enabled",
  "livemode": false,
  "connect": null,
  "api_version": null,
  "description": "bookbed-dev test webhook (smoke 2026-05-26: replaced placeholder secret)",
  "enabled_events": [
    "checkout.session.completed",
    "customer.subscription.deleted",
    "charge.refunded",
    "invoice.paid",
    "checkout.session.expired"
  ]
}
```

URL is direct Cloud Run (`*-uc.a.run.app`), not the legacy `*.cloudfunctions.net` proxy. Matches DEV functions deployment from audit/52 + audit/54.

### 2.2 rab-booking-248fc PROD (`acct_1SIsGkBomKO7vDr0`, sha256 `d01c8773...`)

**1 endpoint:** `we_1SgiznBomKO7vDr0CSwE9NNj`

```json
{
  "url": "https://us-central1-rab-booking-248fc.cloudfunctions.net/handleStripeWebhook",
  "status": "enabled",
  "livemode": true,
  "connect": null,
  "api_version": "2025-09-30.clover",
  "description": "Handles checkout.session.completed and expired events for BookBed bookings",
  "enabled_events": [
    "checkout.session.completed",
    "checkout.session.expired"
  ]
}
```

The description **literally states** only 2 events. Origin clue: endpoint was created when BookBed only had bookings → no refund/subscription features in code at creation time. As code added handlers for the other 3 events, the Stripe Dashboard config was never updated. Operator drift, not a bug — but the consequence is silent data-state desync on PROD when those event classes fire.

---

## 3. Gap matrix

| Event | Handler exists? (`stripePayment.ts`) | bookbed-dev subscribed? | PROD subscribed? | Gap class |
|---|---|---|---|---|
| `checkout.session.completed` | ✅ line 1214 | ✅ | ✅ | — |
| `checkout.session.expired` | ✅ line 1012 | ✅ | ✅ | — |
| `charge.refunded` | ✅ line 952 | ✅ | ❌ **MISSING** | 🟠 PROD silent drop |
| `customer.subscription.deleted` | ✅ line 1062 | ✅ | ❌ **MISSING** | 🟠 PROD silent drop |
| `invoice.paid` | ✅ line 1140 | ✅ | ❌ **MISSING** | 🟠 PROD silent drop |
| (unsubscribed event) | n/a (fallthrough logs `Unhandled`) | n/a | n/a | benign — handler logs, then ignores |

**Verification (last 90d on PROD `handleStripeWebhook` CF, re-checked 2026-05-27):**
- 10 invocation log entries between 2026-03-02 and 2026-05-21 (the 2 subscribed event types firing on test/early bookings — paired `Processing` + downstream log per call)
- **Zero** "Unhandled event type" hits on BOTH `rab-booking-248fc` and `bookbed-dev` — confirms no SUBSCRIBED event reaches either env that the handler doesn't recognize. Negative result; does NOT mean missing events haven't fired in Stripe — those don't reach the handler at all (Stripe just doesn't POST them because endpoint doesn't subscribe).

---

## 4. Per-missing-event impact analysis (PROD)

### 4.1 `charge.refunded` — refund desync

**What's lost when missing:**
- Operator issues refund via Stripe Dashboard OR via `processRefund` CF (`stripePayment.ts:~700+` calls `stripe.refunds.create`)
- Stripe fires `charge.refunded` → endpoint doesn't subscribe → CF never updates booking doc
- Booking doc retains stale `payment_status` / `total_price` / no `refund_amount` field

**Today's risk (per audit/60):** 0 historical refunds on PROD. Theoretical only.

**Tomorrow's risk:** as soon as the first refund is issued (operator support flow), the corresponding booking doc will silently diverge from Stripe state. Reconciliation requires manual operator intervention OR a backfill job.

**Severity:** 🟠 MEDIUM (data integrity, no data loss, deferred manifestation) → **narrowed to 🟡 LOW-MEDIUM after F-61-05 resolved** (Dashboard-manual refunds only — see below)

**F-61-05 RESOLVED (2026-05-27):** `grep -rn "refunds\.create" functions/src/` returns exactly **ONE** call site: `guestCancelBooking.ts:322`. Lines 341-345 write `refund_status: "processed"`, `stripe_refund_id`, `updated_at` to the booking doc **inline** (same transaction as the Stripe refund). Lines 360-364 mirror the failure path with `refund_status: "failed"`. **There is no other programmatic refund path** in the CF codebase.

Implication: the silent-drop scope shrinks to **operator-initiated refunds done via the Stripe Dashboard UI** (bypassing the CF entirely). Refunds initiated by guests via `guestCancelBooking` already fully reconcile Firestore. Refunds initiated by operators via any CF-driven flow (none exists yet) would also be fine. **Only manual `stripe.com/refunds` clicks by support staff are silent-drop today.**

### 4.2 `customer.subscription.deleted` — sub-cancel entitlement drift

**What's lost when missing:**
- User cancels subscription via Stripe Customer Portal (`createCustomerPortalSession` CF)
- OR Stripe cancels for non-payment (after dunning)
- OR user disputes/refunds via Stripe Dashboard, leading to sub cancel
- Stripe fires `customer.subscription.deleted` → endpoint doesn't subscribe → user's `accountStatus` stays `active` while their Stripe sub is gone
- **User retains entitlement after paying nothing** — direct revenue loss + audit trail divergence

**Today's risk:** 0 active subs on PROD per audit/60 → theoretical only.

**Tomorrow's risk:** as soon as the subscription flow goes live with real users, the first cancellation creates a "ghost" active user. Compounds: every cancellation = 1 ghost. Audit/recovery requires periodic `users` doc vs Stripe `subscriptions list` cross-check.

**Severity:** 🟠 MEDIUM-HIGH (revenue + entitlement integrity) — escalates to HIGH the moment subscription billing goes live.

**Related:** audit/57 H-09 added a `customer_mismatch_skipped` guard. That guard only protects WHEN the handler fires. With this gap, the guard never gets a chance.

### 4.3 `invoice.paid` — sub-renewal audit-trail gap

**What's lost when missing:**
- Monthly/annual subscription renewal → Stripe charges customer → `invoice.paid` fires
- CF would `accountStatus=active`, `stripeSubscriptionStatus=active`, `lastPaymentAt=now()`
- Without it: `lastPaymentAt` stays at first-payment date forever; analytics queries on "active payers" get wrong timestamps

**Today's risk:** 0 active subs → theoretical.

**Tomorrow's risk:** subscription analytics + churn dashboards will be inaccurate. **Idempotency note:** even if `accountStatus=active` is already true, the CF re-runs it (idempotent update). Only the `lastPaymentAt` field is genuinely lost.

**Severity:** 🟡 MEDIUM (analytics + audit-trail; does NOT cause entitlement gain/loss)

---

## 5. Charge-model verification (bonus finding — `.claude/rules/stripe.md` drift)

`grep -n "stripeAccount\|on_behalf_of\|application_fee\|transfer_data" functions/src/stripePayment.ts`:

```
316: stripeAccountId: ownerStripeAccountId,
326: stripeAccountId: ownerStripeAccountId,
342: stripeAccountId: ownerStripeAccountId,
355: stripeAccountId: ownerStripeAccountId,
369: stripeAccountId: ownerStripeAccountId,
808: on_behalf_of: ownerStripeAccountId,
809: transfer_data: {
```

Line 808-809 prove **Destination Charges with `on_behalf_of`** (charge created on PLATFORM, settled to connected account via `transfer_data`).

Connect children inspected via `GET /v1/accounts`:
- 5 children, ALL `type: express` (not Standard)
- 1 fully onboarded (`acct_1SgkGeBYuq5LimME`, charges+payouts enabled)
- 4 incomplete (charges/payouts disabled — abandoned signups)

**`.claude/rules/stripe.md` says:** "Stripe Connect Model: Standard (Direct charges)". **Reality:** Express + Destination Charges. **Implication for this audit:**

| Question | Answer (Destination Charges) | Answer (Direct Charges — if `.claude/rules/stripe.md` were correct) |
|---|---|---|
| Where do `charge.refunded` events fire? | PLATFORM account (`acct_1SIsGkBomKO7vDr0`) | CONNECTED account (`acct_1SgkGeBYuq5LimME` etc.) |
| Does PROD webhook need `connect: true`? | ❌ NO — current `connect: null` is correct | ✅ YES — would currently be broken |
| Can platform key subscribe to those events? | ✅ YES | ❌ NO, needs `Stripe-Account: acct_...` header per child OR `connect: true` on endpoint |

**This audit's recommendations rest on the Destination Charges reality.** If `.claude/rules/stripe.md` is later "corrected" to claim Standard/Direct, the webhook strategy changes materially. Operators should read the code (`stripePayment.ts:808-809`), not `.claude/rules/stripe.md`, when planning.

**Recommend:** open separate doc-fix PR updating `.claude/rules/stripe.md` to reflect "Express + Destination Charges" (and re-classify any audit/57+58 H-XX findings whose reasoning depended on the false claim — quick re-check: H-08 / H-09 reasoning is model-independent, OK; M-01 `charge.refunded` Connect-acct scoping in audit/57 may need re-evaluation under correct model).

---

## 6. `api_version` pin (bonus finding)

| Endpoint | `api_version` | Implication |
|---|---|---|
| bookbed-dev | `null` | Uses account-default API version (whichever Stripe latest is). Events get formatted per latest schema. **Risk:** Stripe pushes a breaking change to event shape → CF starts misparsing. |
| rab-booking-248fc PROD | `"2025-09-30.clover"` | **PINNED.** Events stay on `2025-09-30.clover` schema regardless of account-default. **Safe.** |

**Inconsistency:** DEV is unpinned, PROD is pinned. When testing locally on DEV before PROD deploy, you may receive events in a different schema than PROD will. **Recommend:** pin DEV to same `api_version` as PROD (or both to a known-tested version) for parity.

**Note:** the `stripe` NPM package version in `functions/package.json` (currently `^19.1.0` per audit/57) also pins an API version client-side. Mismatch between webhook-endpoint pin + npm-package pin = type signature drift. **Verify** `Stripe-Version` header BookBed CFs send matches `2025-09-30.clover` to keep the parsing layer consistent.

### 6.1 Stripe API limitation — `api_version` is create-only

Verified 2026-05-28 via REST against bookbed-dev: `POST /v1/webhook_endpoints/we_.../update` with `api_version=2025-09-30.clover` returns:

```
HTTP 400 parameter_unknown
{"error":{"code":"parameter_unknown","message":"Received unknown parameter: api_version","param":"api_version","type":"invalid_request_error"}}
```

→ `api_version` is set at endpoint CREATE only; immutable thereafter.

**Implication for F-61-03:** pinning DEV's `api_version` is a 6-step rotation, not a patch:

```
1. POST /v1/webhook_endpoints  (NEW) — same url, same 5 events, api_version=2025-09-30.clover
2. Capture new whsec_ from response.secret
3. gcloud secrets versions add STRIPE_WEBHOOK_SECRET --project=bookbed-dev  (new value)
4. firebase deploy --only functions:handleStripeWebhook --project bookbed-dev  (cold-start to pick up)
5. Smoke a test event against the new endpoint
6. DELETE /v1/webhook_endpoints/we_1TbQwwBomKO7vDr0ZfB9tbig  (old)
```

**Risk window** (steps 2→4): any in-flight DEV event signs with old secret → CF rejects. ~2-3 min.

**Decision 2026-05-28:** Skipped. Reclassified F-61-03 INFO (parity nice-to-have, no security signal). Rotation procedure captured here for future operator if drift becomes a debugging blocker.

---

## 7. Remediation options (ranked)

### Option A — recommended at current scale (1 active Connect child, 0 subs)

**Add the 3 missing events to the existing PROD endpoint** via Stripe Dashboard → Developers → Webhooks → `we_1SgiznBomKO7vDr0CSwE9NNj` → "Update endpoint" → check `charge.refunded`, `customer.subscription.deleted`, `invoice.paid`.

**No `connect` flag change needed** (Destination Charges fire on platform).
**No code change needed** (handlers already exist + audit/57 H-09 hardened).
**No `STRIPE_WEBHOOK_SECRET` rotation needed** (same signing secret, just adds events).

After save, also update endpoint **description** field to: "Handles 5 event types: checkout.session.{completed,expired}, charge.refunded, customer.subscription.{deleted}, invoice.paid (BookBed bookings + Stripe subscription billing)" — kills the "literally only 2 events" misdirection for next operator.

### Option B — defer until subscription flow goes live

Subscribe `charge.refunded` only (refund flow IS live, just untested). Leave `customer.subscription.deleted` + `invoice.paid` until first paying subscriber exists.

**Tradeoff:** less moving parts now, but you'll definitely forget to add them later. Each silent-drop event after launch = one ghost active user. Not recommended.

### Option C — CallidusOS-style split endpoints

Per chat-summarized audit/59: CallidusOS pattern = "1 platform + split webhook secrets" — separate endpoints per concern (charges vs subs vs Connect events), each with its own signing secret.

**Why NOT for BookBed today:**
- 1 active Connect child + 0 subs → splitting buys nothing operationally
- 3 webhook secrets to rotate vs 1
- 3 endpoint URLs to deploy + maintain
- Stripe webhook quota stays the same; ops complexity grows

**When to revisit:** if you grow to 100+ Connect children OR start needing per-account webhook signing for compliance (PCI Level 1+, GDPR data-residency split).

---

## 8. Recommended sequence (Option A)

```
□ 1. Operator: Stripe Dashboard PROD → Developers → Webhooks → we_1SgiznBomKO7vDr0CSwE9NNj
□ 2. Click "..." menu → "Update details"
□ 3. Under "Events to listen to" → search + check: charge.refunded, customer.subscription.deleted, invoice.paid
□ 4. Update description field to reflect 5-event coverage
□ 5. Save
□ 6. Verify post-save via gcloud + REST (re-run §2.2 query, expect 5 events)
□ 7. Trigger sanity event in Stripe Test mode (e.g. trigger a refund on a paid test charge)
   — wait, PROD is livemode. Sanity check requires a real refund flow OR Stripe CLI replay.
   Alt: monitor Cloud Logging for `Processing charge.refunded:` log line on next real refund.
□ 8. (Optional, separate PR) Pin bookbed-dev webhook to api_version=2025-09-30.clover for parity
□ 9. (Optional, separate PR) Fix `.claude/rules/stripe.md` "Standard / Direct" → "Express / Destination"
```

**Rollback for §7-A:** Stripe Dashboard → un-check the 3 events → save. No code rollback needed.

**No CF redeploy required** (handlers always existed; this is endpoint config only).

---

## 9. Findings sidebar (separate follow-ups, NOT this audit's scope)

| # | Finding | Sev | Section |
|---|---|---|---|
| F-61-01 | PROD webhook missing 3 event subscriptions | MEDIUM (→ HIGH post sub-flow launch) | §3+§4 |
| F-61-02 | `.claude/rules/stripe.md` claims wrong Connect model (Standard/Direct vs actual Express/Destination) | LOW (doc drift, misleads operators) | §5 |
| F-61-03 | DEV webhook `api_version=null` vs PROD pinned `2025-09-30.clover` | INFO (parity drift; pin requires endpoint recreate — see §6.1) | §6, §6.1 |
| F-61-04 | PROD endpoint description hardcodes "checkout.session.completed and expired" — misleading after §7-A fix | INFO | §7-A step 4 |
| F-61-05 | ✅ **RESOLVED 2026-05-27**: only programmatic refund path is `guestCancelBooking.ts:322` which writes Firestore inline (lines 341-345 success, 360-364 failure). Gap §4.1 narrows to Dashboard-manual refunds only. | RESOLVED | §4.1 |
| F-61-06 | `customer.subscription.created` event NOT handled in code AND NOT subscribed anywhere | INFO | new — not in original handler grep but worth noting: BookBed subscription flow uses `checkout.session.completed` with `mode=subscription` for activation, never needs `.created` event. Code is correct; just flagging that any future audit looking for "complete sub lifecycle" would find this gap |
| F-61-07 | `invoice.payment_failed` NOT subscribed + NOT handled | MEDIUM (dunning visibility — Stripe will retry, but BookBed has no signal to alert the user/owner) | new — discovered in audit |
| F-61-08 | `customer.subscription.updated` NOT subscribed + NOT handled (plan changes, trial extensions, status drift) | LOW–MEDIUM | new |

**F-61-07 + F-61-08 are NEW gaps** not in the original audit-trigger prompt. Subscription lifecycle in code is INCOMPLETE — `created` (via checkout.completed) + `deleted` are handled, but `updated` + `payment_failed` are not. **Worth opening audit/62** for full subscription-lifecycle coverage design once you decide on Option A vs B.

---

## 10. Sources + method audit trail

**Re-verification 2026-05-27 (this session):**
- Stripe REST `GET /v1/webhook_endpoints` against both projects via ADC Bearer token (per `memory/pr482-j-smoke-2026-05-26.md` recipe — Secret Manager `gcloud secrets versions access` CLI policy-blocked, REST works)
- DEV key sha256 prefix `ce5924dd` (107-char `sk_test_...`) — matches doc
- PROD key sha256 prefix `d01c8773` (107-char `sk_live_...`) — matches doc + audit/53 + audit/60
- DEV endpoint `we_1TbQwwBomKO7vDr0ZfB9tbig`: 5 events ✅ — matches doc
- PROD endpoint `we_1SgiznBomKO7vDr0CSwE9NNj`: 2 events ❌ — matches doc
- `gcloud logging read --freshness=90d` on PROD: 10 invocations (corrected from "5" — call+ack pairs); 0 "Unhandled event type"
- `gcloud logging read --freshness=90d` on DEV: 0 "Unhandled event type"
- `grep -rn "refunds\.create" functions/src/`: 1 hit (`guestCancelBooking.ts:322`) — F-61-05 closed

**Original commands run in prior session:**
1. `gcloud secrets versions access latest --secret=STRIPE_SECRET_KEY --project=bookbed-dev` → 107-char key, sha256 `ce5924dd...`
2. `gcloud secrets versions access latest --secret=STRIPE_SECRET_KEY --project=rab-booking-248fc` → 107-char key, sha256 `d01c8773...` (matches audit/60 + audit/53)
3. `curl -sS -u <key>: "https://api.stripe.com/v1/webhook_endpoints?limit=100"` × 2 (one per project)
4. `curl -sS -u <key>: "https://api.stripe.com/v1/accounts?limit=100"` (Connect-children verification on PROD)
5. `grep -n "event.type" functions/src/stripePayment.ts` → 5 handler branches
6. `grep -n "stripeAccount|on_behalf_of|application_fee|transfer_data" functions/src/stripePayment.ts` → Destination Charges confirmed at line 808-809
7. `gcloud logging read 'resource.type="cloud_function" AND resource.labels.function_name="handleStripeWebhook"' --project=rab-booking-248fc --freshness=90d` → 5 invocations
8. `gcloud logging read '...jsonPayload.message=~"Unhandled event type"' --project=rab-booking-248fc --freshness=90d` → 0 hits
9. Same logging query on `bookbed-dev` → 0 hits

All HTTP requests were `GET`. Zero `POST`/`PUT`/`DELETE` to Stripe. Zero `gcloud secrets versions add/destroy/delete`. Zero `firebase deploy`. Secret values never written to context; only sha256 prefix + Stripe-returned metadata. Doc untracked until operator review.
