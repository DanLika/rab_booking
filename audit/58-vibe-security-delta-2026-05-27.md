# Vibe-Security Audit — DELTA scan (audit/58)

**Date:** 2026-05-27 (later same evening as audit/57)
**Baseline:** [audit/57-vibe-security-2026-05-27.md](./57-vibe-security-2026-05-27.md) (commit `a2831e91`)
**HEAD at scan time:** `a2831e91` (zero drift — baseline IS HEAD)
**Method:** Coordinator-only delta scan. No new domain agents spawned (audit/57's 4-agent sweep already current).
**Scope:** Gaps not covered by audit/57's Stripe/Firestore/CF+auth/secrets agents — dependency CVEs, supply-chain, hosting-headers refinement, H-01 deploy safety verification.

---

## All 26 audit/57 open findings remain OPEN.

See [audit/57 § OPEN findings](./57-vibe-security-2026-05-27.md#open-findings-priority-order) — H-02..H-09 + M-01..M-11 + L-01..L-07. This doc does **not** re-list them.

---

## H-01 deploy-safety verification (NEW — closes review gate)

`firestore.rules` uncommitted diff adds 5 stripe-linkage fields to user-doc deny-list (audit/57 § "Applied this session"). Concern: does the rule break any legitimate user-context write?

**Verification (grep on `functions/src/stripe*.ts` + `lib/`):**

| Surface | Write site | Auth context | Verdict |
|---|---|---|---|
| `stripeConnect.ts:100` | `db.collection("users").doc(ownerId).update({stripe_account_id, stripe_connected_at})` | Admin SDK (`db = admin.firestore()`) | ✅ bypasses rules |
| `stripeConnect.ts:259` | `db.collection("users").doc(ownerId).update({stripe_account_id: FieldValue.delete(), ...})` | Admin SDK | ✅ bypasses rules |
| `stripePayment.ts:1088` | `userDoc.ref.update({stripeSubscriptionId: FieldValue.delete(), ...})` (`customer.subscription.deleted` webhook) | Admin SDK | ✅ bypasses rules |
| `stripePayment.ts:1197` | `db.collection("users").doc(userId).update({stripeCustomerId, stripeSubscriptionId, ...})` (`customer.subscription.created`) | Admin SDK | ✅ bypasses rules |
| `stripeSubscription.ts:84/184` | Read-only (`.get()`) | — | n/a |
| Flutter `lib/**` | `grep -rE 'stripeSubscriptionId\|stripe_account_id\|stripeCustomerId' lib/` with `.set\|.update\|FieldValue` | NONE | ✅ zero client writes |

**Verdict:** H-01 fix is **safe to deploy**. Admin SDK writes bypass Firestore rules by design (uses Application Default Credentials, not a user JWT). Flutter client writes nothing to those fields anywhere. The rule denies what was already de-facto unused on the client and adds defense-in-depth against the UID-squat attack described in audit/57 § H-01.

**Rules-test coverage:** `functions/test/firestore_rules/users.test.ts` exists alongside `bookings.test.ts` + `ical_events.test.ts`. Run `cd functions && npm run test:rules` against the emulator to re-verify 28/28 green before deploy.

---

## Delta findings (net-new from this scan)

### N1 — Dependency CVE drift (cumulative MEDIUM)

`functions/` npm audit: **12 moderate, 0 critical, 0 high.** All transitive. None reachable via attacker-controlled input today, but advisories stack:

| Pkg | Sev | Via | Range affected | Reachability |
|---|---|---|---|---|
| `qs` | MOD | direct | 6.11.1–6.15.1 — DoS via `stringify` on null/undefined comma-format arrays w/ `encodeValuesOnly` | only `express` body parsing; CF gen2 callable uses `onCall`, not raw express → not reachable from `onRequest` webhooks today |
| `fast-xml-parser` | MOD | `@google-cloud/storage` → `gcs-resumable-upload` | <5.7.0 — XML Builder CDATA injection | bookbed has no XML-build user input; reachable only if GCS responds with attacker-controlled XML |
| `uuid` | MOD | `gaxios`/`teeny-request` | <11.1.1 — missing buffer bounds in v3/v5/v6 when `buf` arg supplied | bookbed code calls `uuid` w/o `buf` arg — not reachable |
| body-parser, express, firebase-admin, gaxios, google-gax, retry-request, teeny-request, @google-cloud/firestore | MOD | transitive only | — | upstream fix lands when google-gax/firebase-admin major-bumps |

**Action:** track for next `firebase-admin` minor (>12.6.0). Not blocking deploy. Severity: **LOW (real-world)** despite npm-classified MEDIUM, due to non-reachability.

### N2 — `audit/raw/secrets.txt` tracked in git (LOW — false-positive discipline)

Commit `e7a7e03d chore(audit): commit raw scan evidence + gitignore lock file` adds 23 raw scan output files under `audit/raw/`. `.gitignore` rule `!audit/**/*.md` re-allows only `.md`, but the parent `audit/raw/*` files (`.txt`/`.json`) were `git add -f`'d.

`audit/raw/secrets.txt` (57 lines) contains 9 matches for secret-shape patterns. All 9 are **Firebase Web API keys** (`AIzaSy...`) from `lib/firebase_options.dart` — **public by design** ([Firebase docs](https://firebase.google.com/docs/projects/api-keys); identical to keys shipped in every Flutter web/iOS/Android build). Zero `sk_live_*`, `whsec_*`, `sbp_*`, `sk-ant-*`, `-----BEGIN`, or other actually-secret patterns.

**Verdict:** false positive. Safe to keep committed for audit-trail purposes — but consider stripping/rewriting if the grep is ever extended to scan `.env*` files (it would then surface real secrets and persist them in git history). Optional follow-up: `.gitignore` add `audit/raw/secrets*.txt` and `git rm --cached` it to avoid future contamination.

### N3 — Hosting-header gap matrix (refines audit/57 M-09)

audit/57 M-09 says "CSP + HSTS missing". Partially correct — actual coverage from `firebase.json`:

| Header | owner target | widget target | admin target | Notes |
|---|---|---|---|---|
| `X-Frame-Options` | ✅ | ✅ | ✅ | |
| `X-Content-Type-Options` | ✅ | ❌ **missing** | ✅ | widget is iframe-embedded on 3rd-party sites → nosniff matters more here, not less |
| `Referrer-Policy` | ✅ | ❌ **missing** | ✅ | |
| `Content-Security-Policy` | ❌ missing | ✅ | ❌ missing | only widget has it |
| `Strict-Transport-Security` | ❌ missing | ❌ missing | ❌ missing | Firebase Hosting sets `max-age=31536000` by default on `*.web.app` — but for custom domains (`app.bookbed.io`, `view.bookbed.io`, `admin.bookbed.io`) explicit `Strict-Transport-Security` + `preload` is recommended |
| `Permissions-Policy` | ❌ missing | ❌ missing | ❌ missing | **all 3 surfaces** lack `Permissions-Policy: geolocation=(), camera=(), microphone=(), payment=(self)` |

**Severity:** MEDIUM (matches audit/57 M-09). Net-new sub-findings:
- **N3a:** widget target missing `X-Content-Type-Options: nosniff` + `Referrer-Policy` — widget is the most-exposed surface (3rd-party iframe) yet has fewer hardening headers than owner/admin
- **N3b:** `Permissions-Policy` missing on all 3 surfaces (audit/57 only listed CSP + HSTS)
- **N3c:** custom-domain HSTS-preload header not asserted in `firebase.json` (Firebase Hosting default suffices for `*.web.app` but custom domains benefit from explicit declaration)

**Fix (delta to audit/57 M-09):** when authoring the M-09 PR, bundle N3a + N3b + N3c into the same `firebase.json` edit. ~8-line config change covers all three targets.

### N4 — Node engine mismatch (LOW — dev env only)

`functions/package.json` declares `engines.node: "20"`. Local dev shell runs Node 25.1.0. `npm ci --dry-run` reports `npm warn EBADENGINE` but proceeds; functions deploy uses Cloud Functions runtime `nodejs20` (per `firebase.json` indirect via `functions.runtime`).

**Verdict:** non-security, dev-ergonomics only. Run dev via `nvm use 20` to match deployment runtime, or update `engines.node` to `">=20"` if Node 22+ is intentional. No production impact.

---

## Recommended commit / PR sequencing

Per audit/57 § "Next batch", in priority order:

1. **Commit the H-01 firestore.rules change as PR `SF-vibe57-H01-stripe-deny-list`** — small, reviewable, deploy-safe per § H-01 verification above. Block PR title format like `fix(security): SF-vibe57-H01 stripe linkage deny-list (UID-squat)`.
2. Bundle **H-02** (owner_id immutability) as separate rules PR — broader rule surface (8+ collections), needs its own test additions.
3. **M-09 + N3a + N3b + N3c** as one `firebase.json` hosting-headers PR — pure config, no code, ~8 lines, covers all 3 surfaces.
4. `audit/57 § Code-smell` (duplicate `isAllowedReturnUrl`) as `cleanup(stripe)` PR — drop local copy in `stripePayment.ts:80`, import from `utils/returnUrlValidation.ts`.

---

## Open decision for user

**H-01 firestore.rules diff is uncommitted on `main` working tree.** Choose:

- **(A)** Commit + PR now as `SF-vibe57-H01` standalone (recommended — small surface, regression-tests in place, deploy-safe per verification above)
- **(B)** Hold as part of larger SF-vibe57 batch (H-01..H-09 bundle in one PR — bigger reviewer load, longer in-flight risk)
- **(C)** Drop the change (re-stash or `git checkout firestore.rules`) — only choose if H-01 is reclassified as not-a-finding

audit/57 § "Stash hygiene note" — `stash@{0}: On main: sf-vibe57-drift-2026-05-27` is the earlier iteration of this work. Safe to drop after (A) or (B) lands.

---

## Applied this session (user-requested fix batch)

User invoked "fix issues" after this delta scan landed. Applied the audit/58 § "Quick wins bundle":

### H-08 — `customer_email` raw → sanitized (CLOSED)

`functions/src/stripePayment.ts:843` — changed `customer_email: guestEmail` → `customer_email: sanitizedGuestEmail`. Stripe receipt now matches `metadata.guest_email`, closes spear-phish-via-receipt vector.

### H-04 — `verifyEmailCode` IP rate limit (CLOSED)

`functions/src/emailVerification.ts:244-256` — added `checkRateLimit(\`verify_code_${ipHash}\`, 10, 60)` at function entry (10/min per IP). Per-doc `MAX_ATTEMPTS=3` still caps per-email guesses. Now an attacker cannot rotate emails to escape the per-email cap. Uses existing `getClientIp`/`hashIp`/`checkRateLimit` imports already in file.

### M-11 — SSRF IPv6 hex-form bypass (CLOSED)

`functions/src/icalSync.ts:41-54` — added second branch in `isPrivateOrUnsafeIp` that matches `^::ffff:([0-9a-f]{1,4}):([0-9a-f]{1,4})$`, decodes the two 16-bit hex groups into 4 octets, recurses through IPv4 path. Closes the metadata-server reach via `::ffff:a9fe:a9fe` (= 169.254.169.254). Memory `[[ssrf-ipv4-mapped-ipv6-hex-hole]]` cleared.

### M-09 + N3 hosting headers — PARTIAL (CSP deferred)

`firebase.json` hosting array. Added to **all 3 targets** (owner/widget/admin):
- `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- `Permissions-Policy: geolocation=(), camera=(), microphone=(), payment=(self), interest-cohort=()`

Added to **widget only** (N3a fix — widget was missing the basic 2 that owner/admin already had):
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`

Widget keeps existing `frame-ancestors *` CSP (intentional — widget IS the iframe embed surface).

**Deferred:** owner + admin still missing `Content-Security-Policy`. Flutter Web canvaskit requires `script-src 'self' 'unsafe-eval'` + CDN allowances for `gstatic.com`/`googleapis.com`/Stripe. Adding it without a per-route smoke test risks breaking the app. Tracked as M-09-CSP follow-up — separate PR with explicit CSP design + visual smoke test on owner/admin staging.

| Target | Before this PR | After this PR |
|---|---|---|
| owner | XFO, nosniff, Referrer-Policy | + HSTS, Permissions-Policy (CSP still TODO) |
| widget | XFO=ALLOWALL, CSP=`frame-ancestors *` | + nosniff, Referrer-Policy, HSTS, Permissions-Policy |
| admin | XFO, nosniff, Referrer-Policy | + HSTS, Permissions-Policy (CSP still TODO) |

### Verification

| Check | Result |
|---|---|
| `cd functions && npx tsc --noEmit -p .` | ✅ exit 0, no errors |
| `cd functions && npm run test:rules` | ✅ **33/33** pass (3 suites: users, bookings, ical_events) — was 28/28 before this session; +5 H-01-specific deny-case tests added to `users.test.ts` |
| `cd functions && npm test` (jest excl rules) | ✅ 302/302 pass (14 suites) |
| `jq '.hosting[].headers' firebase.json` | ✅ valid JSON, header keys per target match expected |

**H-01 test coverage upgrade:** audit/57's "28/28 PASS" claim was regression-only — existing tests did not exercise the new stripe deny-list. `users.test.ts` Cases 5-9 added this session positively verify each of the 5 fields (`stripeSubscriptionId`, `stripe_account_id`, `stripeCustomerId`, `stripe_customer_id`, `stripe_connected_at`) is DENIED when written by a regular authenticated user to their own users doc. Cases 1-4 (role/isAdmin) unchanged.

### Files modified

- `firestore.rules` (H-01 — re-applied this session; the earlier audit/57 working-tree edit was silently reverted to clean state at some point during the delta scan. Re-applied per the audit/57 spec)
- `functions/src/stripePayment.ts` (H-08)
- `functions/src/emailVerification.ts` (H-04)
- `functions/src/icalSync.ts` (M-11)
- `firebase.json` (M-09 partial + N3a + N3b + N3c)
- `functions/test/firestore_rules/users.test.ts` (+5 H-01 deny-case tests, Case 5-9)

### Recommended PR shape

Suggest splitting into **two** PRs to keep reviewer load low and isolate blast radius:

**PR-1** `fix(security): SF-vibe57 firestore.rules H-01 stripe linkage deny-list`
- `firestore.rules` only (H-01 from audit/57)
- Rules-test verification: 28/28
- Smallest possible surface; can deploy in isolation
- Deploy: `firebase deploy --only firestore:rules --project bookbed-dev` then PROD

**PR-2** `fix(security): SF-vibe57 quick wins (H-04 + H-08 + M-09-partial + M-11)`
- The 4 file edits above (CF code + hosting config)
- Functions deploy: `cd functions && npm run deploy --project bookbed-dev` (smoke on DEV first)
- Hosting deploy: `tool/deploy-dev.sh owner widget admin` for DEV, then PROD `firebase deploy --only hosting`
- Smoke: confirm `curl -I https://bookbed-owner-dev.web.app` shows new headers; rate-limit OTP brute via 11 rapid calls to `verifyEmailCode` (11th returns `resource-exhausted`); SSRF still blocks `::ffff:a9fe:a9fe`.

### Open from audit/57 after batch 1

- **H-02** owner_id immutability (8 collections + new rules tests) — next priority
- **H-03** deprecated top-level `/bookings/{id}` create lock
- **H-05** `checkEmailVerificationStatus` enumerates emails
- **H-06** `resendBookingEmail` per-uid throttle
- **H-07** `resendGuestBookingEmail` token rotation w/o ownership proof
- **H-09** `customer.subscription.deleted` connect-account correlation
- **M-01..M-08, M-10** + **L-01..L-07** — per audit/57

**M-09 CSP for owner/admin** — split into separate test-gated PR per § "Deferred" above.

---

## Applied this session — BATCH 2 (small Highs + small rules wins)

User invoked "fix issues" second time. Applied audit/58 § "Small Highs + small rules wins" bundle.

### H-03 — deprecated top-level `/bookings/{id}` create lock (already CLOSED)

Audit/57 line ref `firestore.rules:337-344` is stale. Current `firestore.rules:387-392` shows the rule was already locked by F-NEW-07:
```
match /bookings/{bookingId} {
  allow read: if (isAuthenticated() && resource.data.owner_id == request.auth.uid);
  allow create: if false;
  allow update, delete: if isResourceOwner();
}
```
Same lock applies on `/units/{unitId}` (line 379) and `/daily_prices/{priceId}` (line 398). No edit needed — finding superseded.

### H-06 — `resendBookingEmail` per-(owner,booking) rate limit (CLOSED)

`functions/src/resendBookingEmail.ts:13` — new import `checkRateLimit`. Lines 64-77 — added `checkRateLimit(\`resend_booking_email:${request.auth.uid}:${bookingId}\`, 5, 3600)` after `bookingId` validation, before Firestore queries. 5/hr per (owner, booking) — generous for legit retry-on-bounce, hard cap on mailbox harassment + Resend bill amp.

### H-09 — `customer.subscription.deleted` + `invoice.paid` Connect correlation (CLOSED)

`functions/src/stripePayment.ts`:
- Lines 1089-1104 (customer.subscription.deleted handler): after `userData` lookup, extract `subscription.customer` as `stripeCustomerId`, compare against `userData.stripeCustomerId`. Mismatch → log + return `{status: "customer_mismatch_skipped"}` (HTTP 200, no retry — data integrity issue, not transient).
- Lines 1163-1177 (invoice.paid handler): same belt+suspenders, using `invoice.customer`. Post-H-01 client deny-list is the primary guard; this is the second line.

### M-04 — `security_events` top-level forgery guard (CLOSED)

`firestore.rules:497-511` — `allow create: if isAuthenticated()` was unconstrained. Tightened to:
- `request.resource.data.userId == request.auth.uid` (bind to caller)
- `keys().hasOnly([userId, type, timestamp, deviceId, ipAddress, location, metadata])` (parity with `users/{uid}/securityEvents` subcollection field guard at line 132-136)
- `type is string && type.size() <= 64`

Closes admin Activity Log poisoning vector.

### M-05 — `app_config/{platform}` enumeration cap (CLOSED)

`firestore.rules:488-496` — `allow read: if isAuthenticated()` allowed enumerating any future `app_config/<anything>` doc. Bound to canonical platform IDs: `platform in ['android', 'ios', 'web']`. Prevents future drift (e.g. accidentally placing sensitive config at `app_config/internal_keys`) from leaking to any authed user.

### L-04 — Storage SVG block (CLOSED)

`storage.rules:16, 29` — both `users/{userId}` and `properties/{propertyId}` paths had `request.resource.contentType.matches('image/.*')`. SVG is `image/svg+xml` → matched → stored XSS via JS inside SVG. Tightened to `'image/(jpeg|png|webp|gif|heic|heif)'`. iCal-exports + public unaffected.

### Verification (batch 2)

| Check | Result |
|---|---|
| `npx tsc --noEmit -p .` | ✅ exit 0 |
| `npm run test:rules` | ✅ **39/39** pass (was 33/33; +6 new tests for M-04/M-05 in `global_collections.test.ts`) |
| `npm test` (jest excl rules) | ✅ 302/302 pass (no regression on H-06/H-09 surfaces) |

`global_collections.test.ts` covers:
- M-04 Case 1: user forges `userId: OTHER_UID` → DENY ✅
- M-04 Case 2: user creates own valid-shape event → ALLOW ✅
- M-04 Case 3: user adds unknown field `pwned: true` → DENY ✅
- M-05 Case 4: authed reads `app_config/android` → ALLOW ✅
- M-05 Case 5: authed reads `app_config/foobar` → DENY ✅
- M-05 Case 6: anonymous reads `app_config/android` → DENY ✅

### Files modified (batch 2)

- `functions/src/resendBookingEmail.ts` (H-06)
- `functions/src/stripePayment.ts` (H-09 — 2 sites)
- `firestore.rules` (M-04 + M-05)
- `storage.rules` (L-04)
- `functions/test/firestore_rules/global_collections.test.ts` (NEW — M-04 + M-05 coverage, 6 cases)

### Recommended PR split (updated for batch 2)

- **PR-1** (unchanged) `firestore.rules` H-01 + `users.test.ts` Case 5-9
- **PR-2** (unchanged) `firebase.json` + CF code H-04/H-08/M-11
- **PR-3** new `functions/src/{resendBookingEmail,stripePayment}.ts` H-06/H-09 — CF code only; smoke on bookbed-dev (trigger 6 resends → 6th returns `resource-exhausted`; trigger fake subscription.deleted with mismatched customer → log shows `customer_mismatch_skipped`)
- **PR-4** new `firestore.rules` M-04/M-05 + `global_collections.test.ts` — rules-only; 39/39 pass + 3-suite emulator validation
- **PR-5** new `storage.rules` L-04 — storage-rules-only; manual SVG-upload smoke (POST `image/svg+xml` → 403)

### Open from audit/57 after batch 2

- **H-02** owner_id immutability (next priority) — bigger surface, dedicated PR
- **H-05** `checkEmailVerificationStatus` enumerates emails — needs design choice (auth vs IP-rate-limit only)
- **H-07** `resendGuestBookingEmail` token rotation w/o ownership proof — needs design choice (require existing token OR don't rotate)
- **M-01..M-03, M-06..M-08, M-10** + **L-01..L-03, L-05..L-07** — per audit/57
- **M-09 CSP for owner/admin** — split into separate test-gated PR
