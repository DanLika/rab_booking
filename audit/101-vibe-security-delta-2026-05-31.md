# audit/101 — vibe-security delta (return-URL + rate-limit class, 2026-05-31)

**Scope:** Single-agent `/vibe-security` skill pass, reconciled against audit/99 (multi-agent sweep) + audit/100 (SF-078 closure on parallel branch).
**Method:** Targeted re-check of the Stripe return-URL surface + the rate-limit substrate. Did NOT re-run the broad sweep that audit/99 already covers.
**Out of scope:** Findings already enumerated in audit/99 (H/M/L/INFO list there is authoritative — see audit/99 §Findings).
**Reconciliation:** Parallel agent landed PR #609 / SF-078 on branch `fix/audit-99-high-bundle` (commit `75315489`) closing F-101-01 + F-101-02 + an enlarged 17-callable CORS sweep. **NOT yet merged to `main` HEAD `167e6353` as of this audit.** Findings below describe state on `main`; closure status updates when PR #609 lands.

## Headline

`isAllowedReturnUrl` in BOTH `functions/src/stripePayment.ts:87-127` AND `functions/src/utils/returnUrlValidation.ts:51-83` matches the allowlist with `returnUrl.startsWith(domain)`. No host-boundary check. `https://view.bookbed.io.evil.com/` and `https://view.bookbed.io@evil.com/` both `startsWith('https://view.bookbed.io') === true`; the second resolves `URL.hostname === 'evil.com'`. Stripe `success_url` / `cancel_url` / `return_url` / `refresh_url` become attacker-controlled across all three Stripe surfaces (booking checkout, subscription, Connect). Combined with the anonymous `getBookingByStripeSession` callable (booking PII lookup via `cs_…`), post-payment exfil + phishing chain.

Sibling regression: `utils/returnUrlValidation.ts:18-19` keeps `http://localhost` + `http://127.0.0.1` in `BASE_ALLOWED_DOMAINS` permanently — the inline copy in `stripePayment.ts:51` correctly gates them on `FUNCTIONS_EMULATOR` per **SF-073 / F-93-01** (audit/95). Connect + Subscription return URLs ride the regressed copy in PROD.

## Findings — net-new vs audit/99

### HIGH (2)

| # | ID | File:line | Finding |
|---|---|---|---|
| 100-01 | F-101-01 | `functions/src/stripePayment.ts:90-92` + `functions/src/utils/returnUrlValidation.ts:55-58` | `returnUrl.startsWith(domain)` boundary bypass. Verified: `'https://view.bookbed.io.evil.com/'.startsWith('https://view.bookbed.io') === true`; `new URL('https://view.bookbed.io@evil.com/').hostname === 'evil.com'`. Affects `createStripeCheckoutSession` (`stripePayment.ts:261`), `createSubscriptionCheckoutSession` (`stripeSubscription.ts:47`), `createCustomerPortalSession` (`stripeSubscription.ts:175`), `createStripeConnectAccount` + `createStripeConnectAccountLink` (`stripeConnect.ts:47,54`). Post-redirect attacker captures `session_id={CHECKOUT_SESSION_ID}` (interpolated at `stripePayment.ts:772`), then anonymously calls `getBookingByStripeSession` (no auth, `cs_` prefix-only validation, IP-rate-limit 60/3600 = enumeration ceiling per attacker IP) to hydrate full booking record (`guest_name`/`guest_email`/`guest_phone`/`check_in`/`check_out`/`total_price`). Wildcard branch is safe (split-based parts compare, `stripePayment.ts:107-121`); bug is exclusively in the exact-match branch. **Fix:** parse with `new URL(...)`, reject when `parsed.username` / `parsed.password` truthy, compare `parsed.protocol + parsed.hostname` against allowlist hostnames; keep wildcard branch as-is. Patch both files (or delete inline copy and import the utils version, but fix utils first per F-101-02). |
| 100-02 | F-101-02 | `functions/src/utils/returnUrlValidation.ts:18-19` | `http://localhost` + `http://127.0.0.1` unconditional in `BASE_ALLOWED_DOMAINS`. Regresses SF-073 / F-93-01 (audit/95) which moved them behind `if (isEmulator)` in the inline `stripePayment.ts:46-71` copy. The extracted utils version (consumed by `stripeConnect.ts` + `stripeSubscription.ts`) was created from a pre-SF-073 snapshot. In PROD, attacker passes `return_url=http://localhost:<port>/x?session_id=…`; Stripe sends operator's browser to operator-localhost — any sidecar (IDE LSP, dev tunnel, debug server) listening on that port captures Connect/Subscription state. **Fix:** lift `LOCAL_DEV_ORIGINS` (already a separate const at `utils/returnUrlValidation.ts:55-62`-style — verify) out of `BASE_ALLOWED_DOMAINS` and append in `getAllowedReturnDomains()` only when `process.env.FUNCTIONS_EMULATOR === 'true'` OR `projectId === 'bookbed-dev'`. Mirror `stripePayment.ts:57-66` shape. |

### MEDIUM (1)

| # | ID | File:line | Finding |
|---|---|---|---|
| 100-03 | F-101-03 | `functions/src/utils/rateLimit.ts:27` (module-load) | `rateLimitStore = new Map<string, number[]>()` — per-CF-instance, not shared. File comment acknowledges it. Anonymous-facing callables using the in-memory variant (`checkRateLimit`, not `enforceRateLimit`): `availability.ts:146` (`avail:` 30/60s), `getClientGeolocation.ts:48` (`geo:` 60/3600s), `loginLockout.ts:111` (`recordLoginFailure` 1/60s), `icalExport.ts:113` (`ical_feed_` 60/3600s), `emailVerification.ts:63` (`send_verification_` 10/3600s), `atomicBooking.ts:95` (widget booking 10/600s), `stripePayment.ts:157` (`stripe_checkout:` 10/300s), `getBookingByStripeSession.ts:30` (`stripe_session_` 60/3600s). Cloud Functions cold-start spawns a fresh instance with empty Map; bursting through scale-out resets the budget per instance. With `enforceAppCheck: false` (SF-046) as the only other gate, the practical ceiling multiplies by min(active-instance-count). Re-enables a softened form of the F-50-02 anon-DoS class against `loginAttempts/{email}` and anon booking-spam against `bookings`. **Fix:** migrate the hot anonymous callables (`recordLoginFailure`, `createBookingAtomic` widget path, `createStripeCheckoutSession`) to `enforceRateLimit` (Firestore-backed, shared across instances). Keep `checkRateLimit` for the cheap read-only surfaces (`avail:`, `geo:`, `stripe_session_`) where amplification value is low. |

## Verified safe (not findings, captured to suppress re-discovery)

- **Stripe price recompute on mismatch** — `stripePayment.ts:561-602`. `validateBookingPrice` throws `invalid-argument` with `"Price mismatch"` substring; catch reassigns `totalPrice`, `depositAmount`, `depositAmountInCents` from `calculateBookingPrice` (server) before `unit_amount: depositAmountInCents` at L803. No path delivers client value to Stripe after mismatch detection.
- **Stripe webhook idempotency** — `stripePayment.ts:968-989`. `event.id` deduped via `stripe_webhook_events` doc + 30d TTL inside `db.runTransaction` (atomic). Retry returns `{received: true, status: "duplicate"}` without re-executing branches.
- **`.env.*` git history** — `git log --all --diff-filter=A -- .env.staging .env.development .env.production` returns nothing. `git log --all -p -S 'sk_test_51SIsGk' -- '*.env*'` matches only the commit that added the prefix-assertion check in `functions/src/stripe.ts`. Local-only, gitignored.
- **Wildcard return-URL branch** (`stripePayment.ts:101-123` + `utils/returnUrlValidation.ts:66-83`) — split-based parts comparison, correctly blocks `evil-view.bookbed.io` (3 parts vs 3) while allowing `jasko-rab.view.bookbed.io` (4 vs 3). Not in scope of F-101-01.

## Cross-reference table — overlap with audit/99 + audit/100

| audit/99 ID | audit/101 ID | audit/100 (SF-078, PR #609) | Relation |
|---|---|---|---|
| 99-18 (audit/89 followup, ~15 callables) | (none) | H-3 17-callable CORS sweep | Audit/99's CORS inventory + audit/100's PR #609 close subsume my parallel finding. |
| 99-04 / 99-05 / 99-12..14 (CSP, COOP) | (none) | (none) | Hosting-header class — audit/99 owns; not in PR #609 scope. |
| 99-01 (`bookings` deny-list short) | (none) | F-99-01 closed (mirrors SF-068) | audit/99 owns finding; PR #609 closes. |
| (none) | F-101-01 | H-1 `startsWith`→`new URL()` host-only + userinfo reject | Net-new this audit; PR #609 closes on parallel branch (NOT yet on main). |
| (none) | F-101-02 | H-2 SF-073 PROD localhost extracted-util regression | Net-new this audit; PR #609 closes on parallel branch (NOT yet on main). |
| (none) | F-101-03 | (none) | Net-new this audit — rate-limit architectural class (audit/99 found per-callable gaps 99-02/07/08 but not the in-memory `Map` substrate). **PR #609 does not address.** |

## SF numbering reconciliation

- F-101-01 + F-101-02 → **SF-078** via PR #609 (audit/100). Confirmed by [[sf078-audit99-high-bundle]] memory entry. Not yet on main.
- F-101-03 (rate-limit architectural class) → unallocated. Separate PR + separate SF when migrating `recordLoginFailure` / `createBookingAtomic` widget path / `createStripeCheckoutSession` to `enforceRateLimit`. Per audit/95 §0 reconciliation discipline: do NOT pre-allocate; pick next-free at PR-open time.

## Out-of-scope, not fixed here

- No code change. Pure audit doc.
- `firestore.rules`, `storage.rules`, `lib/`, `ios/`, `android/`, FROZEN surfaces (Calendar Repository, Cjenovnik tab, Unit Wizard publish flow) untouched.
- No PROD deploy. No merge.

## Verification recipe (when fix lands)

```bash
# F-101-01 startsWith bypass — should THROW for both
curl -X POST https://europe-west1-bookbed-dev.cloudfunctions.net/createStripeCheckoutSession \
  -H 'Content-Type: application/json' \
  -d '{"data":{"returnUrl":"https://view.bookbed.io.evil.com/","bookingData":{...}}}'
# Expect: HttpsError "invalid-argument" "Invalid returnUrl..."

curl -X POST https://europe-west1-bookbed-dev.cloudfunctions.net/createStripeConnectAccount \
  -H 'Authorization: Bearer <id_token>' \
  -d '{"data":{"returnUrl":"https://app.bookbed.io@evil.com/back"}}'
# Expect: HttpsError "invalid-argument"

# F-101-02 localhost in PROD — should THROW from Connect/Subscription
curl -X POST https://us-central1-rab-booking-248fc.cloudfunctions.net/createSubscriptionCheckoutSession \
  -H 'Authorization: Bearer <prod_id_token>' \
  -d '{"data":{"priceId":"price_X","returnUrl":"http://localhost:8080/exfil"}}'
# Expect: HttpsError "invalid-argument"

# F-101-03 rate-limit migration — N parallel callers from same IP
# After migration: 2nd+ N+1 caller hits Firestore-backed ceiling regardless of CF instance.
# Today: each new cold-start gives the attacker a fresh budget.
```

## References

- audit/99 — same-day multi-agent sweep (authoritative for non-return-URL surface).
- audit/95 §F-93-01 / SF-073 — closed localhost regression in `stripePayment.ts` (this audit catches the utils copy that regressed it).
- audit/58 F-58-07 — reflective-Origin CORS class (audit/99 99-18 owns current inventory).
- audit/50 F-50-02 — `loginAttempts` anon DoS class (F-101-03 re-enables softened form).
- MEMORY `[[return-url-startswith-open-redirect]]` — net-new this run.
- MEMORY `[[in-memory-rate-limit-multi-instance-bypass]]` — net-new this run.
