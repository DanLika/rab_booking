# Audit 123 — Full Security Audit (165+ checks) — 2026-06-11

> **FIX WAVE 1 (same day):** F-123-01 ✅ (bounds guard + deposit≤total + throw-on-fee-anomaly, `stripePayment.ts`), F-123-02 ✅ (`sanitizeText` on iCal summary/description, `icalSync.ts`), F-123-04 ✅ (5MB response cap, `icalSync.ts`), F-123-06 ✅ (CORS intent documented inline, `icalExport.ts`), F-123-07 ✅ (per-owner rate limits on `getStripeAccountStatus` 30/300s + `disconnectStripeAccount` 5/300s). Stale `.claude/rules/firestore.md` T11c section rewritten to closed state. Verified: `tsc` clean, eslint 0 new violations on added lines, **462/462 jest tests green**.
>
> **FIX WAVE 2 (AI/LLM, from /vibe-security passes):** F-123-AI ✅ **server-authoritative Gemini daily quota** — counter moved from client-memory (reset on every app launch) to Firestore `users/{uid}/data/ai_usage` {day,count}, consumed atomically in a transaction (`ai_chat_repository.dart` `tryConsumeDailyAiQuota`), gated up-front in `ai_chat_provider.dart` (fail-closed on counter error, consume-before so forced-error retry storms can't farm calls). Rules pin `day` to `request.time` + enforce monotonic increment / daily reset-to-1 (`firestore.rules` `isValidAiUsageCreate/Update`, folded into `users/{uid}/data/{document}`) → restart/tamper can't reset. F-123-AI-CHAT ✅ `ai_chats` write now bounds `messages.size() <= 200`. New emulator test `ai_usage.test.ts` (14 cells incl. reset-to-0 bypass DENY, faked-future-day DENY, cross-user DENY); **full rules suite 173 pass / 6 skip green**; `flutter analyze` clean on all 3 touched Dart files. Behavior change noted: a failed Gemini call now costs 1/30 of the day's budget (safer abuse posture).
>
> NOT fixed (out of scope): F-123-03 (trial-gate, product decision), F-123-05 (key.properties dev-machine), F-123-08 (payment_bridge wildcard, deferred F-99-11), firebase-admin 14 bump (separate smoke-tested PR per F-107-07/08). Operator-only: App Check **enforcement** toggle for the Firebase AI Logic API (blocks forged callers that bypass the client entirely) + live PROD header `curl -I`.
>
> **WAVE 1 DEV-DEPLOYED + LIVE-SMOKED (same day):** all 8 CFs from the 4 touched files deployed to `bookbed-dev` (commit `c1db1076`). First attempt failed 8/8 on F-CUT-01 lockfile-drift recurrence (dependabot batch `65d2d393` regenerated lock under npm 11 → Cloud Build npm-ci reject; re-regenerated via `npx npm@10 install`, committed). `getUnitIcalFeed` additionally hit the stale PR #482 `ICAL_TOKEN_PEPPER` secret-vs-plain-env overlap (cutover-dryrun footnote) — unused plain line removed from `.env.bookbed-dev` (zero code references), redeploy green. Live smoke (`audit/smoke/audit123-deploy-smoke.js`): feed valid-token 200 VCALENDAR + wrong-token 403 ✓; `getStripeAccountStatus` RESOURCE_EXHAUSTED exactly at call 31 (F-123-07 limit 30/300s) ✓.

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

> Context: the SF-078/079/080 trial-gate system is fully MERGED (#666/#668/#669 + #670 banner;
> backfill verified clean 2026-06-11 — 24/24 canonical). audit/113 §2 *intentionally* left these
> paths out of the SF-080 map at ship time; the decision here is whether to extend `isActiveOwner()`
> (rules:59) to them. Pre-flight maps audit/110/112/113 deleted 2026-06-11 — full texts in git
> history; the live gate inventory is the rules file itself.
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

## 4. KNOWN-OPEN CARRIED FORWARD — **canonical open ledger** (audit/99 + audit/107 docs deleted 2026-06-11; full texts in git history; this table absorbs their residuals)

### Closed line (reconciled)

| Item | Status today |
|---|---|
| F-107-01 widget_secrets `hasOnly` | **CLOSED** (verified: `firestore.rules:402-408` whitelist live) |
| F-107-02 CORS 5 callables | **CLOSED** (PR #720; all callables on `getCorsAllowlist()`) |
| F-107-03 / F-99-04 widget CSP | **CLOSED in config** (firebase.json full CSP); live-PROD curl verify = operator item below |
| F-101-03 / F-107-04 instance-local rate limit | **CLOSED** (L2 `enforceRateLimit` on 3 hot anonymous callables, 2026-06-11) |
| audit/99 fix wave F-99-01/02/05/06/07/08 | **CLOSED** (SF-078 #609 + 2026-06-11 wave: pwhist+revoke+icalSyncNow rate limits, COOP headers, devices `hasOnly`; dev-deployed, PROD pickup = SF-081 checklist) |
| F-107-17 contentType "unanchored" regex | **KILLED — false positive 2026-06-11**: rules `string.matches()` is whole-string semantics; `image/jpeg-evil-suffix` does NOT match `image/(jpeg\|png\|webp\|gif\|heic\|heif)` |
| SF-050 PROD IAM | regrant executed at cutover (35/35); spot-check on next PROD touch |
| SF-061/SF-046 App Check `enforceAppCheck:false` | DEFERRED (CSP prereq; L1+L2 rate limiting compensates) — launch checklist in docs/TODO.md |

### OPEN residuals (LOW/INFO deliberate deferrals — absorbed from audit/99)

| ID | Sev | Item | Note |
|---|---|---|---|
| ~~F-99-03~~ | ~~INFO~~ | ~~`user_profiles` deny-list missing Stripe-linkage mirror~~ | **CLOSED 2026-06-11**: 5 Stripe keys mirrored into both `hasAny` arrays; emulator cells added |
| F-99-09 | LOW dormant | Twilio creds via `process.env \|\| ""` not `defineSecret` | early-returns while empty; convert before activating SMS |
| ~~F-99-10~~ | ~~LOW~~ | ~~shared validators `throw Error` not `HttpsError`~~ | **CLOSED 2026-06-11**: 9 swaps → `HttpsError("invalid-argument")` in `dateValidation.ts` (6, incl. user-reachable same-civil-day `< 1 night`) + `depositCalculation.ts` (3); `bookingReferenceGenerator.ts` intentionally KEPT bare `Error` (input is server-generated doc ID — a throw there is a real bug that SHOULD reach Sentry). 462/462 jest; `createBookingAtomic` redeployed dev |
| F-99-11 / F-107-11 / F-123-08 | LOW (MED footgun) | `web_utils_web.dart:325,332` `sendMessageToParent` `targetOrigin:'*'` (leaks `cs_*` session IDs to any embedder) | single non-PII-critical caller today; resolve target from trusted-list before adding callers |
| F-99-12/13/14 / F-107-15 | LOW | CSP scoping: `unsafe-inline`+`unsafe-eval` (CanvasKit needs eval), `*.cloudfunctions.net` wildcard, `*.a.run.app` absent | hardening-sprint batch: change + 3-surface redeploy + smoke as one unit |
| F-99-15 | INFO latent | deep-link cold-start auth race | guard when wiring app_links stream (F-62-05 class) |
| ~~F-99-16~~ | ~~INFO~~ | ~~FCM SW `bookingId` concat without format check~~ | **CLOSED in code 2026-06-11**: shape guard in `firebase-messaging-sw.js` click handler; ships with next hosting deploy (already on the PROD-pickup checklist) |
| F-99-17 / F-107-07 | LOW | `uuid <11.1.1` via firebase-admin@12 (8 npm-audit moderates, unreachable in CF paths) | clears with firebase-admin 13/14 bump — separate smoke-tested PR (+ firebase-functions 6→7, F-107-08) |

### OPEN residuals (absorbed from audit/107 KNOWN-OPEN)

| ID | Sev | Item | Note |
|---|---|---|---|
| F-107-05 | MED partial (SF-068) | `properties.create` accepts client `subdomain` (format-valid squat) before CF reservation | drop `subdomain` from create payload in owner repo + strip from `create.affectedKeys`; force `setPropertySubdomain` callable |
| ~~F-107-09 / F-86-02~~ | ~~LOW~~ | ~~availability CG queries lack date-range filter~~ | **CLOSED 2026-06-11**: `check_out > startTs` (bookings) + `end_date > startTs` (ical_events) server-side; 2 new CG composites (`unit_id+status+check_out`, `unit_id+end_date`) deployed dev + READY; t2+t3 live green. **PROD ordering: indexes BEFORE CF** (rider in docs/TODO.md). F-86-01 sibling also FIXED same day; F-86-03 (Stripe min-floor) still open — `audit/edge-0530/README.md` |
| ~~F-107-10~~ | ~~LOW~~ | ~~`stripeSubscription.ts` no explicit `region`~~ | **CLOSED 2026-06-11**: `region: "us-central1"` pinned explicitly on both callables (region immutable; migration tracked in docs/TODO.md) |
| F-107-12 / F-67-03 | LOW partial | widget form persistence keeps PII 15min in SharedPreferences keyed by `unitId` (`notes` scrubbed) | move to sessionStorage on web (deferred refactor) |
| ~~F-107-13~~ | ~~LOW~~ | ~~deprecated top-level `ical_feeds` `resource == null` probe~~ | **CLOSED 2026-06-11**: ZERO legacy docs verified on BOTH envs (Admin SDK read) → block retired wholesale to `read, write: if false` (supersedes F-98-01 partial deny). Residual documented in cells: legacy-property OWNER can still read via the owner-scoped `/{path=**}/ical_feeds` CG clause — harmless |
| F-107-14 | LOW | `users.create` deny-list without `hasOnly` shape bind | DEFERRED with finding: client signup payload (`enhanced_auth_provider.dart:462`) sends `'role'` which the deny-list already blocks, yet signup works → that client `set` likely never succeeds (doc created by `onUserCreate` Admin trigger). `hasOnly` needs the dead client write-path inventoried/removed first or it bricks registration |
| ~~F-107-16~~ | ~~INFO~~ | ~~`securityEvents.timestamp` client-controlled~~ | **CLOSED 2026-06-11 (full fix)**: client switched to `FieldValue.serverTimestamp()` (×2 writes in `security_events_service.dart`; the recentSecurityEvents ARRAY copy keeps client clock — serverTimestamp is invalid inside array elements) + rules bind `timestamp == request.time`; 3 emulator cells (server-ts ALLOW, client-clock DENY, backdate DENY) |
| F-107-18 / SF-067 | operator | storage→firestore IAM `datastore.viewer` grant — PROD confirmed at cutover | re-verify on env re-creates |
| F-107-19 / F-CUT-01 | process | npm-11 lockfile drift — **recurred 2026-06-11** (dependabot batch), re-fixed via `npx npm@10 install` | permanent guard queued in docs/TODO.md |

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
