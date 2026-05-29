# audit/68 — Stripe Dashboard Tasks (PROD, live mode)

**Date:** 2026-05-28
**Account:** `acct_1SIsGkBomKO7vDr0` (BookBed, HR, EUR)
**Auth path:** REST + PROD `STRIPE_SECRET_KEY` v5 from Secret Manager (`sha8 6ec442ab`)
**Branch:** `main`
**CLI status at session start:** Authed to CallidusOS sandbox `acct_1T6Y41Q82cgbc9Mn` → REST fallback used.

## Summary

| # | Task | Status | Method |
|---|---|---|---|
| 1 | Webhook events expansion (F-61-01/07/08) | DONE — 7 events live | REST POST |
| 2 | `business_profile.name` (F-64-bonus) | API BLOCKED → Dashboard-only | REST POST |
| 3 | Reject 3 abandoned Connect children | DONE — all 3 `rejected.other` | REST POST |
| 4 | Dev webhook `api_version` parity (F-61-03) | DEFERRED | (none) |

No signing-secret rotation. No CF redeploys. Production handlers (audit/61) already cover the 5 newly-added webhook event types.

---

## Task 1 — Webhook events expansion ✅

**Endpoint:** `we_1SgiznBomKO7vDr0CSwE9NNj`
**URL:** `https://us-central1-rab-booking-248fc.cloudfunctions.net/handleStripeWebhook`
**livemode:** true | **api_version:** `2025-09-30.clover` (unchanged)

### Before

```
enabled_events = [
  "checkout.session.completed",
  "checkout.session.expired"
]
description = "Handles checkout.session.completed and expired events for BookBed bookings"
```

### Action

```
POST /v1/webhook_endpoints/we_1SgiznBomKO7vDr0CSwE9NNj
  enabled_events[]=checkout.session.completed
  enabled_events[]=checkout.session.expired
  enabled_events[]=charge.refunded
  enabled_events[]=customer.subscription.deleted
  enabled_events[]=customer.subscription.updated
  enabled_events[]=invoice.paid
  enabled_events[]=invoice.payment_failed
  description=Handles 7 event types: checkout.session.{completed,expired}, charge.refunded, customer.subscription.{deleted,updated}, invoice.{paid,payment_failed} (BookBed bookings + subscription billing)
```

POST replaces full `enabled_events` array — all 7 sent.

### After

```
enabled_events count = 7
match = True   (set equals expected)
missing = ∅
extra = ∅
status = enabled
api_version = 2025-09-30.clover   (unchanged)
```

### Side effects

- Signing secret unchanged (POST/update never rotates `whsec_*`). `STRIPE_WEBHOOK_SECRET` in PROD Secret Manager remains valid.
- CF handlers for the 5 new event types already exist (audit/61 verified). No CF deploy required.

---

## Task 2 — `business_profile.name` ⚠️ Dashboard-only

### Before

```
business_profile.name = None
business_profile.url = "https://bookbed.io"
business_profile.support_email = None
business_profile.product_description = None
```

### Action (attempted)

```
POST /v1/accounts/acct_1SIsGkBomKO7vDr0
  business_profile[name]=BookBed
```

### Result

```
{
  "type": "invalid_request_error",
  "message": "You cannot use this method on your own account: you may only use it on connected accounts."
}
```

Stripe's `/v1/accounts/{id}` update endpoint is reserved for **connected** (Standard/Express/Custom child) accounts. The platform's own account (`acct_1SIsGkBomKO7vDr0`) cannot be updated via API.

### After

Unchanged. **Dashboard fallback required:**

1. https://dashboard.stripe.com/settings/account → "Public business information"
2. Set "Public business name" = `BookBed`
3. Save.

### Recommendation

Also fill while in Dashboard:

- `business_profile.support_email` → `info@book-bed.com` (per AI KB)
- `business_profile.product_description` → e.g. "Booking management platform for property owners (rentals)."

These three together close F-64-bonus end-to-end; the API path is permanently unavailable.

---

## Task 3 — Reject abandoned Connect children ✅

### Pre-flight verification

All three confirmed abandoned (charges/payouts/details all `false`, requirements past-due, never completed onboarding):

| Account | Email | Created (epoch) | charges_enabled | payouts_enabled | details_submitted | disabled_reason | currently_due |
|---|---|---|---|---|---|---|---|
| `acct_1SwQCYBRnYwyvWUE` | jovalikareels@gmail.com | 1770050535 | false | false | false | `requirements.past_due` | 15 |
| `acct_1St5GYAwUrOseNX8` | ironlifepodrska@gmail.com | 1769255075 | false | false | false | `requirements.past_due` | 15 |
| `acct_1SqfjqBjD6wZNOjK` | jasko@jasko-rab.com | 1768680292 | false | false | false | `requirements.past_due` | 15 |

### Action

```
POST /v1/accounts/{id}/reject  reason=other
```

executed against each of the 3 IDs.

### After

All 3 returned:

```
charges_enabled = False
payouts_enabled = False
disabled_reason = rejected.other
```

Same end state as `acct_1TYSMdPWhhVc6lN0` rejected earlier this session. Reject is irreversible — owners would need to register fresh Connect accounts if they ever return.

---

## Task 4 — Dev webhook `api_version` parity ⏸ Deferred

**Endpoint:** `we_1TbQwwBomKO7vDr0ZfB9tbig` (bookbed-dev) — `api_version=null`
**PROD pinned:** `2025-09-30.clover`

### Why deferred

Stripe's webhook-endpoint `api_version` is **set at creation time and immutable** ([[stripe-webhook-api-version-immutable]] — verified in audit/61 §6.1; POST/update with `api_version` returns 400 `parameter_unknown`).

Pinning the dev endpoint requires:

1. Create new endpoint with `api_version=2025-09-30.clover` (returns new `whsec_*` secret).
2. Copy new secret to `bookbed-dev` Secret Manager `STRIPE_WEBHOOK_SECRET`.
3. Redeploy CFs on bookbed-dev so they pick the new env var.
4. Delete old endpoint `we_1TbQwwBomKO7vDr0ZfB9tbig`.

Multi-step, requires signing-secret rotation + CF redeploy on dev. Not worth executing solely for parity given:

- Dev endpoint receives only test events (no live customers).
- Stripe deprecation cycle ≥ 12 months; default unpinned dev endpoint will receive current `2025-09-30.clover` payloads in practice.
- Schema drift between dev (default) and PROD (pinned) hasn't bitten any handler yet (audit/52 + audit/55 smokes all pass on dev).

### When to revisit

If Stripe announces a breaking webhook payload change AND we want to validate handlers against the next pinned version on dev before flipping PROD — recreate dev with the matching pin. Otherwise leave default.

---

## Verification matrix

| Surface | Check | Result |
|---|---|---|
| PROD webhook | `GET /v1/webhook_endpoints/we_1SgiznBomKO7vDr0CSwE9NNj` → `len(enabled_events)==7` | ✅ |
| PROD webhook | Set diff matches the 7 target events | ✅ no missing, no extra |
| PROD webhook | `status==enabled`, `livemode==true`, `api_version==2025-09-30.clover` | ✅ |
| PROD acct | `business_profile.name` post-task | ❌ still null (Dashboard-only) |
| Connect children | All 3 IDs → `disabled_reason==rejected.other` | ✅ |
| CF handlers | audit/61 already confirmed code paths exist for 5 new events | ✅ (no deploy needed) |
| Signing secret | Webhook POST/update on existing endpoint does not rotate `whsec_*` | ✅ no env-var work |

---

## Open follow-ups

1. **Dashboard:** Set `business_profile.{name,support_email,product_description}` (Task 2 fallback).
2. **Memory note candidate:** Add to [[stripe-webhook-api-version-immutable]] that `POST /v1/accounts/{platform-own-acct}` is also rejected by Stripe — only connected accounts editable via API. (Currently undocumented in repo memory.)
3. **F-61-03 dev parity:** Stays open as low-priority backlog; revisit only on Stripe schema-change announcement.

## Cleanup

- `/tmp/.stripe_key_bookbed_prod` shredded post-session (see closing step).
- No new commits required (no source changes — config mutations only).
- No CF redeploys.
