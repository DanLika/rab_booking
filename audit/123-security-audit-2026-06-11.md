# Audit 123 — Full Security Audit (165+ checks) — 2026-06-11

> **FIX WAVE (same day):** F-123-01 ✅ (bounds guard + deposit≤total + throw-on-fee-anomaly, `stripePayment.ts`), F-123-02 ✅ (`sanitizeText` on iCal summary/description, `icalSync.ts`), F-123-04 ✅ (5MB response cap, `icalSync.ts`), F-123-06 ✅ (CORS intent documented inline, `icalExport.ts`), F-123-07 ✅ (per-owner rate limits on `getStripeAccountStatus` 30/300s + `disconnectStripeAccount` 5/300s). Stale `.claude/rules/firestore.md` T11c section rewritten to closed state. Verified: `tsc` clean, eslint 0 new violations on added lines, **462/462 jest tests green**. NOT fixed (out of scope): F-123-03 (product decision), F-123-05 (dev-machine), F-123-08 (deferred-by-decision F-99-11), firebase-admin 14 bump (separate smoke-tested PR per F-107-07/08).

**Scope:** HUGE project (656 Dart + 100 TS files, ~268K lines). 9 parallel domain agents + gitleaks (full git history) + semgrep (`p/security-audit` + `p/secrets`) + npm audit. Coordinator cross-verified contested claims against ground truth.

**HEAD:** `2f3226d1` | **Tools:** gitleaks 95 raw hits → 0 real, semgrep 0 findings, npm audit 0 crit / 0 high / 8 moderate.

---

## VERDICT

**No CRITICAL or HIGH new findings.** Codebase reflects 100+ prior SF fixes; core surfaces (rules, payments, SSRF, email injection, secrets, auth) are in strong shape. New findings below are MEDIUM defense-in-depth + LOW hygiene items.

```
🔴 CRITICAL: 0   🟠 HIGH: 0   🟡 MEDIUM: 3 new   🔵 LOW: 5 new   ℹ️ known-open carried: see §4
```

---

## 1. FALSE POSITIVES KILLED (coordinator-verified)

| Agent claim | Verdict | Evidence |
|---|---|---|
| CG bookings public-read via `unit_id`+`status` still live (claimed HIGH) | **FALSE — CLOSED** | `firestore.rules:510-521`: only `isAdmin()` or `resource.data.owner_id == request.auth.uid`. T11c clause removed 2026-05-22. (`.claude/rules/firestore.md` §T11c text is stale — describes pre-close state.) |
| `generateSubdomainFromName` IDOR (claimed P0) | **FALSE** | `functions/src/subdomainService.ts:266-317` — pure string generator; `propertyId` only excludes self in uniqueness check; no property read/write. Auth + 30/300s rate limit present. |
| gitleaks: stripe token in `SEVALLA_DEPLOYMENT_GUIDE.md` | **FALSE** | Literal placeholder `sk_live_xxxxxx`; file history-only. |
| gitleaks: JWTs in `lib/core/config/web_config.dart` + `fix_rls.js` | **FALSE** | Supabase **anon** key + Stripe **publishable** test key (public by design); files deleted from HEAD (legacy Supabase remnants). |
| gitleaks: gcp-api-key ×~80 (google-services.json, firebase-messaging-sw.js, firebase_options*.dart, audit docs) | **FALSE** | Firebase API keys — public by design. |
| Android `key.properties` plaintext password (claimed CRITICAL) | **Downgraded LOW** → F-123-05 | Gitignored + untracked; standard Android signing practice; dev-machine-only exposure. |

---

## 2. NEW FINDINGS

### F-123-01 🟡 MEDIUM — Payment amount upper-bound gaps (defense-in-depth)
`functions/src/stripePayment.ts:439-456` + `utils/priceValidation.ts`
- No max total price (€1M booking accepted; Stripe is the only backstop).
- Fee anomaly `> 10000` → Sentry capture only, **proceeds** instead of rejecting.
- No `depositAmount <= totalPrice` validation (negative remaining_amount possible).
Core price integrity is solid (server recalculates from `daily_prices`, mismatch corrected, negative/NaN rejected, cents rounding correct, currency hardcoded EUR, Connect account server-fetched). This is bounds hardening only.
**Fix:** throw on fee anomaly; add `MAX_BOOKING_PRICE` const; assert deposit ≤ total.

### F-123-02 🟡 MEDIUM — iCal SUMMARY/DESCRIPTION stored unsanitized (stored-XSS class)
`functions/src/icalSync.ts:821-825` → Firestore `guest_name` / `description` (`:1125-1144`).
Attacker-controlled feed (owner pastes arbitrary URL) can inject `<script>`/HTML into booking docs. Current renderers are Flutter `Text` widgets (auto-escape) + emails (escapeHtml at template layer) → no live sink today, but any future HTML rendering of `description` becomes XSS.
**Fix:** `sanitizeText(vevent.summary)` / `sanitizeText(vevent.description)` at parse time — utility already exists in `utils/inputSanitization.ts` and is simply not called here.

### F-123-03 🟡 MEDIUM (product decision) — Trial-gate absent on 3 subcollections
`firestore.rules:268` (units), `:401` (widget_secrets), `:431` (ical_feeds) + CG write paths.
SF-080 `isActiveOwner()` gates properties/bookings/daily_prices/widget_settings but NOT units, widget_secrets, ical_feeds — expired-trial owner can still mutate these.
**Fix:** product call — if intended, document; else add `&& isActiveOwner()` to the 6 rules.

### F-123-04 🔵 LOW — iCal fetch has no response-size cap
`functions/src/icalSync.ts:755-757` — unbounded `data` accumulation until 30s timeout. Malicious feed can balloon memory.
**Fix:** abort at ~1MB in the `data` handler.

### F-123-05 🔵 LOW — `android/key.properties` plaintext signing passwords on disk
Gitignored/untracked; dev-machine risk only. **Fix (optional):** env-var injection in Gradle.

### F-123-06 🔵 LOW — `getUnitIcalFeed` hardcodes `Access-Control-Allow-Origin: *`
`functions/src/icalExport.ts:107-108`. Token-gated (timing-safe, empty-token fail-closed per F-92-01 fix) and .ics feeds are consumed cross-origin/server-to-server by design — mostly intentional. Browser-side fetch of a leaked URL is the only marginal vector.
**Fix (optional):** none required; document intent inline.

### F-123-07 🔵 LOW — No rate limit on `getStripeAccountStatus` / `disconnectStripeAccount`
`functions/src/stripeConnect.ts:145-225`. Auth-gated, owner-only; consistency item.

### F-123-08 🔵 LOW — `payment_bridge.js` wildcard postMessage fallback
`web/payment_bridge.js:374-375` — send-side falls back to `'*'` (payload = sessionId + status only; receive-side origin allowlist correct incl. `endsWith('.bookbed.io')`). Same class as known-deferred F-99-11/F-107-11.
**Fix (optional):** specific origin for popup→parent path.

---

## 3. SUPPLY CHAIN

- **8 moderate npm advisories — all one root:** `uuid` <11.1.1 OOB write (GHSA-w5hq-g745-h8pq) transitive via `firebase-admin@^12.6.0`. Not exploitable here (no user-controlled `buf` to uuid v3/v5/v6). **Fix = known F-107-07:** bump firebase-admin (now `^14.0.0` clears all 8; F-107-08 firebase-functions 6→7 same PR candidate).
- `.github/workflows/ci.yml:228` uses `npm install` not `npm ci` (temp measure) — restore after lockfile sync (F-107-19 class).
- Actions pinned to major tags (not SHAs) — acceptable; no `pull_request_target`; no hardcoded secrets.
- Postinstall scripts: `@firebase/util`, `protobufjs` (benign) + `unrs-resolver` (downloads NAPI binaries — watch).
- pubspec security set all current (`flutter_secure_storage 9.2.4`, `http 1.6.0`, firebase_* current). No typosquats either ecosystem.
- Lockfile v3, `npm ci --dry-run` passes locally.

---

## 4. KNOWN-OPEN CARRIED FORWARD (no re-finding; statuses reconciled vs stale agent ledger)

| Item | Status today |
|---|---|
| F-107-01 widget_secrets `hasOnly` | **CLOSED** (verified: `firestore.rules:402-408` whitelist live) |
| F-107-02 CORS 5 callables | **CLOSED** (PR #720; agents confirm all callables on `getCorsAllowlist()`) |
| F-107-03 widget CSP | **CLOSED in config** (firebase.json full CSP); live-PROD curl verify = operator item below |
| F-101-03/F-107-04 instance-local rate limit | **CLOSED** (L2 `enforceRateLimit` on 3 hot anonymous callables, 2026-06-11) |
| SF-061/SF-046 App Check `enforceAppCheck:false` | DEFERRED (CSP prereq; L1+L2 rate limiting compensates) |
| F-99-03/09/10/11/12-14/15/16 | DEFERRED-by-decision (audit/99 residual ledger unchanged) |
| F-107-09 CG date-range filters, F-107-10 region drift, F-107-12 form persistence, F-107-13 legacy ical_feeds probe, F-107-14 users hasOnly, F-107-16 timestamp bind, F-107-17 contentType anchor | OPEN per audit/107 KNOWN-OPEN list |
| SF-050 PROD IAM | regrant executed at cutover (audit/102: 35/35 + regrant); spot-check on next PROD touch |

**OPERATOR VERIFY (only live-state unknowns):**
```bash
curl -sI https://app.bookbed.io | grep -i content-security-policy
curl -sI https://bookbed-admin.web.app | grep -i content-security-policy
curl -sI https://view.bookbed.io | grep -i content-security-policy
# missing → firebase deploy --only hosting --project rab-booking-248fc
```

---

## 5. CLEAN SWEEPS (PASS, evidence in agent transcripts)

- **Secrets:** 0 real leaks in working tree + full git history; Secret Manager via `defineSecret`; SF-040 key-prefix assert; SF-007 email-only Remember Me on flutter_secure_storage.
- **Rules:** no `allow: if true` holes (12 public-read paths all intentional widget data); privilege escalation closed (role/isAdmin/accountStatus/stripe_* deny-listed); storage rules SF-091 correct (firestore.get, split DELETE, image-type+10MB caps).
- **CF access control:** 62 functions inventoried; all mutating handlers verify ownership via Firestore (never client-supplied ownerId); admin CFs gate on `isAdmin` claim; webhook = POST-only + constructEvent HMAC + event.id dedup w/ 30-day TTL.
- **Payments:** server-side pricing, fail-closed `ALLOWED_SUBSCRIPTION_PRICE_IDS`, host-exact `returnUrlValidation` (userinfo rejected, HTTPS-only wildcards), no test-mode path in prod.
- **SSRF:** icalSync defense complete — scheme allowlist, all-address DNS resolve, private-IP blocks incl. hex IPv4-mapped IPv6 (`::ffff:a9fe:a9fe` handled, lines 51-61), DNS pinning, redirect re-validation, 30s timeout.
- **Injection:** 0 command-exec, 0 fs ops, email HTML escapeHtml everywhere, CRLF header guards (incl. unicode line separators), no FieldPath injection.
- **Flutter client:** deep-link whitelist, no WebView, keepAlive providers watch auth, logout wipes web storage, widget bundle secret-free.
- **Headers:** full 6-header set + CSP on all 3 targets in firebase.json (unsafe-inline/eval = CanvasKit constraint, known F-107-15).

---

## RECOMMENDED ACTION ORDER

1. **F-123-02** — wire `sanitizeText()` into icalSync parse (2-line fix, kills stored-XSS class). Bundle **F-123-04** size cap same file.
2. **F-123-01** — payment bounds trio (max price, throw-on-anomaly, deposit≤total).
3. **F-107-07/08** — firebase-admin 14 + firebase-functions 7 bump (clears all 8 npm advisories).
4. **F-123-03** — product decision on trial-gating units/widget_secrets/ical_feeds.
5. Operator: 3× `curl -I` live header verify.
6. Stale-doc cleanup: `.claude/rules/firestore.md` T11c section still describes clause 1 as live — update to reflect closure (caused agent false positive this audit).
