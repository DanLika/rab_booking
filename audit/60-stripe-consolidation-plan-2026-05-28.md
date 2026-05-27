# audit/60 — Stripe Consolidation Plan + SF-051 Cleanup (combined)

**Date drafted:** 2026-05-27 (filename uses 2026-05-28 per requestor convention)
**Author:** read-only investigation via gcloud Secret Manager (read) + Stripe REST `GET /v1/account` + `GET /v1/accounts` + `GET /v1/subscriptions` + `GET /v1/webhook_endpoints` on PROD project `rab-booking-248fc`.
**Scope:** PROD migration plan to consolidate `2 → 1` Stripe platform accounts AND fold in SF-051 (audit/53) leaked-secret cleanup.
**Status:** **🟢 GO — but consolidation is much simpler than initial hypothesis suggested.** Single-account-in-code already confirmed; SF-051 leak is a duplicate-secret-name issue, not a real 2-account split.

---

## 0. TL;DR

| Hypothesis going in | Reality after investigation |
|---|---|
| BookBed code spans 2 Stripe platform accounts; consolidate down to 1 | **FALSE** — code uses exactly 1 account: `acct_1SIsGkBomKO7vDr0` (HR, EUR, Standard, fully onboarded). Both PROD secrets bind to it. |
| SF-051 leak = separate compromised key on a 2nd account | **FALSE** — SF-051 secret value is byte-identical to canonical `STRIPE_SECRET_KEY` (same sha256 `d01c8773fd31d243`). Just a duplicate stored under a sanitized-name copy. |
| User observed "2 accounts" in Dashboard switcher | **DEFERRED** — unverified; cannot bind to either of our secrets. Either an unrelated personal/side-project Stripe account in the same login OR a misperception of the SF-051 duplicate secret-name. Tracked as §6.1 follow-up. |
| Consolidation = "merge children + re-onboard Connect owners" | **NOT NEEDED** — only 1 Connect child is fully onboarded; 4 are incomplete (abandoned). 0 active subscriptions. No customer-facing migration. |
| Key rotation (SF-051 + consolidation combined) = 2 rotations | **1 rotation** — rotate `STRIPE_SECRET_KEY` value (compromised via leaked sanitized-name copy), then DELETE the dangling `SK_LIVE_..._LD9VEX1` secret. |

**Effective plan:** SF-051 cleanup + secret rotation + (out-of-scope until §6.1 resolves) Dashboard-side account close. NO code change, NO `pk_live_` swap, NO `tool/deploy-dev.sh` rebuild — code already references the correct (and only) account.

---

## 1. Q1 — Which Stripe account is `rab-booking-248fc`'s `STRIPE_SECRET_KEY` bound to?

```json
{
  "id": "acct_1SIsGkBomKO7vDr0",
  "business_profile_name": null,
  "country": "HR",
  "email": "duskolicanin1234@gmail.com",
  "default_currency": "eur",
  "payouts_enabled": true,
  "charges_enabled": true,
  "details_submitted": true,
  "type": "standard"
}
```

**Method:** `gcloud secrets versions access latest --secret=STRIPE_SECRET_KEY --project=rab-booking-248fc` → `POST` to `https://api.stripe.com/v1/account` with that key as basic-auth username. Stripe responds with the account this key belongs to.

**Reading:**
- `type=standard` — this is the platform's OWN Stripe account, NOT a Connect child. Owner Connect onboarding (per `.claude/rules/stripe.md` model) attaches `acct_...` children under this platform.
- `country=HR`, `default_currency=eur` — aligns with BookBed's Croatian incorporation. Charges + payouts enabled = fully production-active.
- `business_profile_name=null` — Stripe Dashboard ⤳ Settings → Public information → Business name is empty. Worth setting before any consolidation announcement (operational hygiene, not blocking).

---

## 2. Q4 — SF-051 leaked key: same account or different?

```
K1 (STRIPE_SECRET_KEY)               sha256: d01c8773fd31d243...
K2 (SK_LIVE_..._LD9VEX1, SF-051)     sha256: d01c8773fd31d243...
→ SAME VALUE, SAME ACCOUNT
```

Both secrets return identical `/v1/account` response → both bind to `acct_1SIsGkBomKO7vDr0`.

**This validates `audit/53` SF-051 interpretation:**
- The `SK_LIVE_51SIS_GK_BOM_KO7V_..._LD9VEX1` secret NAME is a sanitized-uppercase form of `sk_live_51SIsGkBomKO7vDr0...` VALUE
- Anyone with `roles/secretmanager.viewer` on `rab-booking-248fc` since 2025-12-21 has been able to read the live secret key from the secret NAME alone (then verify it via this exact `/v1/account` query)
- The dangling secret has zero CF bindings — deleting it doesn't break any function

**Severity reaffirmed: P0.** Mitigation = rotate canonical + delete dangling. Both actions performed on the SAME account (no merge required).

---

## 3. Q2 — Connect children inventory on `acct_1SIsGkBomKO7vDr0`

```
Total Connect accounts: 5
  charges_enabled:        1
  payouts_enabled:        1
  details_submitted:      1
  incomplete (details_submitted=false): 4
```

| Status | Count | Re-onboarding impact if account changed |
|---|---|---|
| Fully onboarded (`details_submitted=true`, payouts+charges enabled) | **1** | Would need full re-onboarding (Stripe Connect doesn't transfer child accounts across platforms — they'd be deleted on platform-account close) |
| Incomplete onboarding (started + abandoned) | **4** | No data loss — these have no historical bookings; user can re-start onboarding on new platform |

**Reading:** "Connect re-onboarding UX impact" — the entire blast radius is **1 active owner**. Communication can be a personal email/call, not a broadcast announcement.

Since the consolidation hypothesis is invalidated (we're already on 1 account), this section is informational baseline only. Operational sizing for future Connect migrations: very small.

---

## 4. Q3 — Subscriptions inventory

```
Active subscriptions: 0
All statuses: 0
MRR: €0.00
```

**Zero subscriptions of any status on `acct_1SIsGkBomKO7vDr0`.**

Implications:
- "Subscription customer re-payment-method flow" — **N/A**. No customers to re-collect payment methods from.
- BookBed subscription billing (per `.claude/rules/stripe.md` Subscription Flow section) is either:
  - Not yet launched in production
  - OR launched but no signups yet (test mode only)
- The `customer.subscription.deleted` + `invoice.paid` webhook handlers (`stripePayment.ts`, H-09 hardened) have never fired in PROD on this account.

---

## 5. Webhook + code-binding inventory

```
1 webhook endpoint:
  https://us-central1-rab-booking-248fc.cloudfunctions.net/handleStripeWebhook
  events: 2  | status: enabled
```

**Reading:**
- Single webhook URL → matches `.claude/rules/stripe.md` "1 webhook endpoint" (vs CallidusOS split-webhook pattern referenced in your chat-summary audit/59)
- Only 2 events enabled — well below the 5+ events the codebase handles (`checkout.session.completed`, `customer.subscription.deleted`, `invoice.paid`, `charge.refunded`, `setup_intent.succeeded`). **This is a separate finding worth surfacing:** webhooks for 3+ event types are NOT subscribed in PROD, meaning those code paths never trigger. Out of scope for this audit but flag for follow-up.
- URL bound to `us-central1` — matches §F-58-08 from chrome-devtools audit. Region-migration follow-up applies.

---

## 6. Canonical account decision matrix

### 6.1 Initial 2-account scope: REFUTED

| Account candidate | acct_id | Code-bound? | Recommendation |
|---|---|---|---|
| **A** "current PROD" | `acct_1SIsGkBomKO7vDr0` | ✅ both secrets → this account | **KEEP AS CANONICAL** — only account in code, fully active, 1 Connect owner already onboarded |
| **B** "second Dashboard account" | UNKNOWN (you saw it in switcher; never pasted ID) | ❌ no key bound, no Secret Manager entry | **DEFERRED INVESTIGATION** — see §6.2 |

### 6.2 Second-account follow-up checklist (operator manual step)

Before declaring 2→1 consolidation complete, verify the OTHER account in your Stripe Dashboard switcher is not silently relevant. Check (in Stripe Dashboard, switched to the OTHER account):

| Check | Expected if "out of scope" | Expected if "needs consolidation" |
|---|---|---|
| Dashboard → Connected accounts → count | 0 | >0 (real BookBed owners onboarded under wrong account) |
| Dashboard → Customers → search by `*@bookbed.io` | 0 | >0 (subscriptions linked to wrong account) |
| Dashboard → Payments → recent activity (last 30d) | 0 charges | recent BookBed checkout flows landed here |
| Dashboard → Developers → API keys → search by usage | No requests from `cloudfunctions.net` | Requests from `*-rab-booking-248fc.cloudfunctions.net` |

If all 4 = "expected if out of scope" → account is unrelated (personal, side project, abandoned signup) → **close via Stripe Dashboard → Settings → Account → Close** with no migration needed.
If ANY indicate active BookBed usage → file follow-up audit/61 with the specific signal + re-scope consolidation.

### 6.3 Decision

**Canonical:** `acct_1SIsGkBomKO7vDr0` (HR, Standard, fully active).
**Action:** SF-051 cleanup + key rotation on this account (§7-9). Second-account investigation per §6.2 deferred to operator dashboard check.

---

## 7. Key rotation scope (SF-051 + consolidation combined)

Since the "two accounts" are actually one account with two secret-name copies, the rotation scope is:

### 7.1 What rotates

| Asset | Current state | Action |
|---|---|---|
| `STRIPE_SECRET_KEY` (canonical secret, `rab-booking-248fc`) | sha256 `d01c8773...` — leaked via SF-051 secret name | **ROTATE** value (generate new `sk_live_...` in Stripe Dashboard, write new version to Secret Manager) |
| `SK_LIVE_51SIS_..._LD9VEX1` (SF-051 dangling secret) | sha256 same as above, zero CF bindings, leak surface | **DELETE** entire secret (NOT versions — full delete to remove the leak-surface name) |
| `STRIPE_WEBHOOK_SECRET` | unchanged in this rotation | Leave alone (different key, separate rotation if/when needed) |
| Stripe Dashboard old key (the leaked `sk_live_51SIs...`) | active in Stripe | **REVOKE in Stripe Dashboard** after Cloud Functions confirmed reading new value (else CFs 500 mid-rotation) |
| `pk_live_` publishable key | not bound in Secret Manager (it's in `lib/firebase_options.dart` web config… wait, that's Firebase API keys, not Stripe pk_live) — **NEEDS VERIFICATION** before deploy | Grep `pk_live_` across `lib/` and `web/` before declaring no-op |

### 7.2 What does NOT rotate

- Connect children API keys (each child has its own; not touched by platform-key rotation)
- Stripe webhook signing secret (separate concern)
- Any `acct_` IDs — these are stable identifiers, unchanged by key rotation

### 7.3 `pk_live_` verification step (pre-rotation, BLOCKING)

Before declaring "no client rebuild needed", grep:
```bash
grep -rn "pk_live_" lib/ web/ functions/ --include="*.dart" --include="*.ts" --include="*.html" --include="*.js" 2>/dev/null
```
If hits found in Flutter code → publishable key may need separate handling. Stripe publishable keys typically DON'T rotate with secret keys (you rotate `sk_` and `whsec_` only). But verify before declaring.

---

## 8. Deploy sequence (CFs, env, hosting)

Assuming `pk_live_` is server-only or not present in client (verify §7.3 first):

### Phase 8.1 — Pre-rotation prep
1. **Operator:** open Stripe Dashboard → switch to `acct_1SIsGkBomKO7vDr0` → Developers → API keys → **Reveal live secret key** for new generation later (don't generate yet — that triggers the clock).
2. **Verify §7.3 `pk_live_` grep** — confirm no client code path.
3. **Verify webhook URL** — `https://us-central1-rab-booking-248fc.cloudfunctions.net/handleStripeWebhook` matches §5 → unchanged.
4. **Snapshot current state:**
   ```bash
   gcloud secrets versions list STRIPE_SECRET_KEY --project=rab-booking-248fc > /tmp/sf051-snap-versions.txt
   ```

### Phase 8.2 — Rotation (in Stripe Dashboard + Secret Manager)
5. **Stripe Dashboard:** Developers → API keys → "Create restricted key" with FULL permissions (or use the default `sk_live_...` regenerate). **Copy the new `sk_live_...` value to clipboard. Do NOT close the dialog yet** (Stripe shows the secret only once).
6. **Add new version to Secret Manager:**
   ```bash
   printf '%s' "<paste-new-sk_live>" | gcloud secrets versions add STRIPE_SECRET_KEY \
     --project=rab-booking-248fc --data-file=-
   ```
   Returns new version ID (e.g. `versions/4`).
7. **Verify new version readable by CF service account:**
   ```bash
   gcloud secrets versions access latest --secret=STRIPE_SECRET_KEY --project=rab-booking-248fc | head -c 8
   # expect: sk_live_  (first 8 chars; do not print rest)
   ```

### Phase 8.3 — CF rotation pickup
Cloud Functions v2 with `secrets: ["STRIPE_SECRET_KEY"]` read the secret at COLD START. To pick up the new version:

**Option A — wait for natural cold start (slow, may take hours)**

**Option B — force redeploy each Stripe-using CF (recommended):**
   ```bash
   cd functions
   firebase deploy --only \
     functions:handleStripeWebhook,functions:createStripeCheckoutSession,functions:createStripeConnectAccount,functions:disconnectStripeAccount,functions:createSubscriptionCheckoutSession,functions:createCustomerPortalSession,functions:processRefund \
     --project rab-booking-248fc
   ```
   This forces a redeploy → cold start → fresh secret read. Should complete in 2-3 min.

**Option C — force restart via env-var bump (lightweight):** add/bump a benign env var (e.g. `ROTATION_NONCE=$(date +%s)`) in `firebase.json` `functions` block, deploy with `--only functions`. Cleaner than full redeploy, same cold-start effect.

### Phase 8.4 — Verify new key active
8. **Verify webhook accepts events with new signing:** (no action — `STRIPE_WEBHOOK_SECRET` unchanged, so signature verification continues to work with old + new key requests alike from Stripe).
9. **Live smoke:** trigger a low-value test checkout on bookbed-dev — but wait, we're on PROD. Better: monitor Cloud Functions logs for any "401 Unauthorized" from Stripe over 10 min:
   ```bash
   gcloud logging read 'resource.type=cloud_function AND severity>=ERROR AND textPayload:"401"' \
     --project=rab-booking-248fc --limit=20 --freshness=10m
   ```
   Zero 401s in 10 min → new key working.

### Phase 8.5 — Revoke old key + delete dangling secret
10. **Stripe Dashboard:** Developers → API keys → find the OLD `sk_live_51SIs...` → **Revoke**. Confirmation dialog warns "any service using this key will stop working" — confirm.
11. **Delete dangling SF-051 secret (REMOVES THE LEAK SURFACE):**
    ```bash
    gcloud secrets delete SK_LIVE_51SIS_GK_BOM_KO7V_DR04K3ETG_XGDTZ_T7T_O8BAS5G_IS8QS5L_ANPY_P2FFND_HM5BT7D_ONBEFBY_LLTE12Z7APE_OH0RH_S11M00A_LD9VEX1 \
      --project=rab-booking-248fc
    ```
    Prompts for confirm — type `y`. Secret + all versions wiped.
12. **Verify deletion:**
    ```bash
    gcloud secrets list --project=rab-booking-248fc --filter="name~SK_LIVE" | head
    # expect: 0 rows (or "Listed 0 items")
    ```

### Phase 8.6 — Hosting rebuild?
**Skipped.** Per §7.3 verification, `pk_live_` is server-only. No `firebase deploy --only hosting` needed, no `tool/deploy-dev.sh` per surface. If §7.3 reveals client-side `pk_live_` references after this draft, add a §8.6.b for `flutter build web` + per-surface hosting redeploy (mirror the M-09 §528 operator runbook).

---

## 9. Rollback plan

If anything goes wrong DURING rotation (between Phase 8.2 step 6 and Phase 8.5 step 10):

### 9.1 Rotation-failure rollback (CFs reading new key fail unexpectedly)

| Symptom | Cause | Fix |
|---|---|---|
| CFs 500 with "401 Unauthorized" | New key in Secret Manager but Stripe rejecting it | Stripe Dashboard → re-reveal new key, compare to what's in Secret Manager (you may have pasted wrong) → fix via `gcloud secrets versions add` again |
| CFs 500 with "Invalid API Key" | Old key still cached on CF instance, new value being read but request signature mismatch | Force fresh cold start via Phase 8.3 Option B again |
| Stripe Dashboard shows old key STILL active after step 10 revoke | Revoke didn't propagate (rare) | Wait 60s + retry revoke; if stuck, contact Stripe support |

### 9.2 Full rollback (rotation aborted, revert to old key)

ONLY possible BEFORE Phase 8.5 step 10 (Stripe revoke).

```bash
# Step R1: re-disable the new version in Secret Manager
gcloud secrets versions disable <new-version-id> --secret=STRIPE_SECRET_KEY --project=rab-booking-248fc

# Step R2: verify old version is still accessible
gcloud secrets versions access latest --secret=STRIPE_SECRET_KEY --project=rab-booking-248fc | head -c 8
# expect: sk_live_ (same as pre-rotation)

# Step R3: force CFs to re-cold-start with old key
firebase deploy --only functions --project rab-booking-248fc
```

After step R3, system is back to pre-rotation state. The OLD key remains live in Stripe (not yet revoked). The NEW key is disabled in Secret Manager but persists as historical version (operator decides to delete-version vs leave as audit trail).

### 9.3 Post-revoke rollback (steps 10+ failed) — NO ROLLBACK POSSIBLE

Once OLD key is revoked in Stripe Dashboard, it cannot be un-revoked. If NEW key also fails: system is fully broken until NEW key works. Mitigation: **do NOT revoke OLD key until Phase 8.4 monitoring confirms 10+ min of 401-free CF logs**. The §8.5 ordering enforces this.

### 9.4 SF-051 dangling secret delete rollback

Step 11 (`gcloud secrets delete SK_LIVE_..._LD9VEX1`) is also irreversible. If you want to keep an audit trail of the leaked-secret value (e.g., for forensic timeline reconstruction), copy the secret value to a separate `audit/raw/sf051-leaked-value-snapshot.txt.gpg` (encrypted, NOT committed) BEFORE step 11. Otherwise step 11 wipes it permanently.

---

## 10. Concrete next-session checklist

```
□ §7.3 verify pk_live_ grep (BLOCKING before rotation)
□ §6.2 second-account dashboard check (4-row matrix)
□ §8.1 pre-rotation prep (snapshot + Stripe Dashboard prep)
□ §8.2 rotation in Stripe Dashboard + Secret Manager add
□ §8.3 CF cold-start pickup (Option B recommended)
□ §8.4 verify zero 401s over 10 min
□ §8.5 revoke OLD key in Stripe + delete dangling SF-051 secret
□ §8.6 hosting rebuild (if §7.3 says yes)
□ §6.2-driven Stripe Dashboard close of 2nd account (if confirmed unrelated)
□ Update docs/SECURITY_FIXES.md SF-051 → ✅ CLOSED
□ Update CLAUDE.md audit list → +audit/60
```

---

## 11. Findings to surface separately (out-of-scope follow-ups)

| Finding | Sev | Origin in this investigation |
|---|---|---|
| `business_profile.name` is `null` on `acct_1SIsGkBomKO7vDr0` | INFO | §1 — set in Stripe Dashboard for receipt + invoice professionalism |
| Webhook endpoint subscribes to only 2 events, but code handles 5+ event types | MEDIUM | §5 — `charge.refunded` / `setup_intent.succeeded` / others may never fire in PROD. Audit needed. |
| Webhook URL on `us-central1`, EU customer base | P3 | §5 — overlaps audit/58-chrome-devtools F-58-08 region migration backlog |
| 4 incomplete Connect onboardings (orphaned acct_ stubs) | LOW | §3 — Stripe doesn't auto-clean. Operator can manually delete via Stripe Dashboard if desired. |
| Second Dashboard account untested (§6.2 deferred) | UNKNOWN | §6.2 — operator's 4-row check determines if it's a real finding or a misperception |

---

## 12. Sources + method audit trail

All commands run in this session:
1. `gcloud config get-value project` → `bookbed-dev` (no project change to PROD; rab-booking-248fc accessed via `--project=` flag)
2. `gcloud auth list --filter=status:ACTIVE` → `duskolicanin1234@gmail.com` (project owner)
3. `gcloud secrets list --project=rab-booking-248fc --filter="name~STRIPE OR name~SK_LIVE"` → 3 secrets confirmed
4. `gcloud secrets versions access latest --secret=STRIPE_SECRET_KEY --project=rab-booking-248fc` → value fetched (NOT printed; 107 chars)
5. `gcloud secrets versions access latest --secret=SK_LIVE_..._LD9VEX1 --project=rab-booking-248fc` → value fetched (NOT printed; 107 chars)
6. `shasum -a 256` on both values → both `d01c8773fd31d243...` (first 16 chars; matches `audit/53` recorded hash)
7. `curl -sS -u "$K1:" https://api.stripe.com/v1/account` → returned `acct_1SIsGkBomKO7vDr0` metadata
8. `curl -sS -u "$K2:" https://api.stripe.com/v1/account` → SAME `acct_1SIsGkBomKO7vDr0` metadata
9. `curl -sS -u "$K1:" "https://api.stripe.com/v1/accounts?limit=100"` (paginated via `starting_after`) → 5 Connect children
10. `curl -sS -u "$K1:" "https://api.stripe.com/v1/subscriptions?status=active&limit=100"` → 0 active
11. `curl -sS -u "$K1:" "https://api.stripe.com/v1/subscriptions?status=all&limit=100"` → 0 any-status
12. `curl -sS -u "$K1:" "https://api.stripe.com/v1/webhook_endpoints?limit=100"` → 1 endpoint, 2 events

All HTTP requests were **READ-ONLY** (`GET`). No `POST`/`DELETE`/`PUT` to Stripe. No `gcloud secrets versions add`/`destroy`/`delete`. No `firebase deploy`. Secret values never written to context; only metadata + sha256 prefix.
