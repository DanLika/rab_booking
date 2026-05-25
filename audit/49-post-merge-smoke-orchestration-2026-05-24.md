# audit/49 — Post-Merge Smoke Orchestration 2026-05-24

**Status:** Scoped programmatic verification + deferred-manual replay checklists for 8 smokes following the 29-PR merge consolidation (audit/48).
**Main HEAD at audit time:** `4d72e3e6` (post-#472 merge).
**Critical finding:** Hosting headers from PR #463 live in `firebase.json` but **NOT live on `bookbed-owner-dev` + `bookbed-admin-dev`** — surfaces last deployed before #463 merged. Operator action required (`tool/deploy-dev.sh <surface>` per audit/33 P1 procedure).

---

## §1 Deploy verify (3 dev surfaces, runtime offset evidence)

Re-fetched each `/main.dart.js` bundle, grep'd for project IDs and contextualized every match.

| Surface | `rab-booking-248fc` matches | All enum-only? | Active Firebase init projectId | Verdict |
|---|---|---|---|---|
| `bookbed-owner-dev.web.app` (7.32 MB) | 2 (offsets 237598, 1193372) | ✅ both in `EnvironmentConfig` switch-case enum strings | `bookbed-dev` (FirebaseOptions at offset ~6.66 MB) | ✅ runtime clean |
| `bookbed-widget-dev.web.app` (3.77 MB) | 0 | n/a (widget bundle excludes admin env enum) | `bookbed-dev` | ✅ runtime clean |
| `bookbed-admin-dev.web.app` (3.32 MB) | 0 | n/a | `bookbed-dev` | ✅ runtime clean |

### Owner surface `rab-booking-248fc` enum proofs

**Offset 237598** — `EnvironmentConfig.projectId` getter switch-case:
```js
case 0:return"bookbed-dev"
case 1:return"bookbed-staging"
case 2:return"rab-booking-248fc"
```

**Offset 1193372** — `currentEnvironment()` reverse lookup (string → enum):
```js
if(J.i(s,"bookbed-dev"))return"development"
if(J.i(s,"bookbed-staging"))return"staging"
if(J.i(s,"rab-booking-248fc"))return"production"
```

Neither is an active Firebase init — they're static enum maps used by `EnvironmentConfig` to label the current runtime by reading what Firebase ALREADY initialized. The actual init at offset ~6660308 uses the `bookbed-dev` FirebaseOptions struct exclusively.

**audit/33 §11.3 (HAR verified clean) confirmed; deploy contamination class formally closed for all 3 surfaces at runtime.**

---

## §2 Code-grep invariants for merged PRs

| PR | Title | Invariant | Verdict |
|---|---|---|---|
| #455 | audit/20 ErrorBoundary + Sentry filter | `lib/core/error_handling/error_filter.dart` exists (17 occurrences of message/stack matchers); `beforeSend` wired in `lib/main.dart` + `lib/widget_main.dart` | ✅ |
| #456 | PR-A direct-write + nights fold | `owner_booking_callable_service.dart` calls `createOwnerBookingAtomic`; `atomicBooking.ts:605/628` writes `nights` field | ✅ |
| #458 | PR-B `provider_id` capture in `EmailSent` | `bookingHelpers.ts:14` adds `provider_id?: string | null` with audit/26 PR-B comment | ✅ |
| #461 | iCal cache invalidation on booking create | `invalidateIcalCache` imported in `atomicBooking.ts:43` + `bookingManagement.ts:25`; 3 call sites in main | ✅ |
| #463 | SSRF redirect re-validation + DoS per-IP key + hosting headers | `firebase.json` declares `X-Frame-Options` + `X-Content-Type-Options` + `Referrer-Policy` under `source='**'` for owner+admin; `validateIcalUrl` re-checks at line 345; `rateLimitKey = ${ipHash}:${bookingReference}` at `resendGuestBookingEmail.ts:83` | ✅ code / ⚠️ deploy (see §3.S.1) |
| #467 | admin-dev contamination fix | `lib/admin_main_dev.dart` exists; `tool/deploy-dev.sh` admin case present | ✅ |
| #470 | sanitizer digit allow + cooldown 60s prose | `input_sanitizer.dart:127` regex `[^\p{L}\p{N}\s'\-]`; CHANGELOG 6.44 corrected to "60-second" with audit/35 footnote | ✅ |
| #471 | widget `MaterialApp.locale` wired from `languageProvider` | `widget_main.dart:294` `locale: appLocale`; same in `widget_main_dev.dart:151` | ✅ |
| #472 | `emails_sent.*` parity on booking create | `persistEmailSent(` count in `atomicBooking.ts` = **5** (4 sites from audit/34 §5 spec + 1 path for owner_notification in bank_transfer flow) | ✅ |
| #475 | gitignore cache surface hardening | `.gitignore` contains `jest_dx`, `.mcp.json`, `node-compile-cache` | ✅ |
| #462 | role escalation + deploy unblock (env-gated) | `functions/.env.bookbed-dev` + `functions/.env.rab-booking-248fc` **MISSING** locally (operator-managed per audit/38); not merged this session | ⚠️ env-gated |

10/10 merged PR invariants land cleanly in `main`. #462 not merged (env block per audit/38).

---

## §3 Security regression partials (programmatic)

### §3.S.1 Hosting headers — **DEPLOY GAP DETECTED**

```python
HEAD https://bookbed-owner-dev.web.app/   → x-frame-options=∅  x-content-type-options=∅  referrer-policy=∅
HEAD https://bookbed-admin-dev.web.app/   → x-frame-options=∅  x-content-type-options=∅  referrer-policy=∅
HEAD https://bookbed-widget-dev.web.app/  → x-frame-options=ALLOWALL  content-security-policy=frame-ancestors *
```

`firebase.json` declares the security headers under `source='**'` for owner+admin (per PR #463). The deployed bundles do NOT carry them → **owner+admin not redeployed since #463 merged at `11a25bde` 2026-05-24**.

Widget surface intentionally has `ALLOWALL` + `frame-ancestors *` to support iframe embedding — correct.

**Operator action:** `tool/deploy-dev.sh owner` + `tool/deploy-dev.sh admin` (per audit/33 P1 procedure) to push the header config live.

### §3.S.2 Public Firestore rules read attempts

Not executed this session — requires Firebase Web SDK + anonymous JWT. Deferred to §4.7.

Code-level confirmation that the rules layer was tightened by T11c + SF-023 + SF-025 + audit/17 is already in `firestore.rules` (collection groups locked under non-anon clauses; iCal events deny anon reads).

### §3.S.3 SSRF in `icalSync` (code-level)

`functions/src/icalSync.ts:44` defines `validateIcalUrl(url)`. Called at line 345 before fetch (initial URL) AND inside the redirect handler (re-validation per PR #463 fix). 5-redirect limit at line 437.

Negative pattern confirmed absent (no `fetch` against unvalidated `Location:` header).

### §3.S.4 DoS per-IP rate-limit key (code-level)

`functions/src/resendGuestBookingEmail.ts:83`:
```ts
const rateLimitKey = `resend_guest_email:${ipHash}:${bookingReference}`;
if (!checkRateLimit(rateLimitKey, 3, 3600)) {
```

Per-IP + per-booking key construction confirmed (PR #463). Pre-#463 the key was global (`resend_guest_email:${bookingReference}`) which let any one IP DoS the booking-confirmation resend across all guests.

### §3.S.5 Dormant-5 template deletions

Not exhaustively grep'd this session — defer to §4.7. Pre-merge baseline (audit/28 §3.4) identified 5 templates with no CF caller; PR #459 doc-only confirms supersession by PR #462 path. No new orphan-import regression suspected (would have surfaced as `flutter analyze` or `npm run build` error, and §2/§4 build verify passed).

### Deferred (require runtime + auth state)

- End-to-end booking lifecycle with real email send + Resend `provider_id` capture (§4.3)
- iCal external import → conflict detection round-trip (§4.8)
- Stripe checkout valid/invalid `priceId` (needs Stripe sandbox + #462 env) (§4.8)
- Multi-tenant isolation (needs 2 active owner accounts) (§4.8)

---

## §4 Per-smoke deferred-manual replay checklists

Each subsection is a self-contained runbook. Estimated runtime aggregates to ~10–12 h end-to-end if executed sequentially; smokes 1, 2, 5, 6 are parallel-eligible (different surfaces).

### §4.1 audit/49.1 Widget UI replay (post-#450, #471)

- **Target:** `https://bookbed-widget-dev.web.app/?property=SEED_test_owner_property_01&unit=SEED_test_owner_unit_01`
- **Auth:** none (public widget); seed account = [memory test-account.md].
- **Checkpoints** (from audit/32 template):
  - CP1: page loads, no console errors
  - CP2: calendar renders, available dates click-through
  - CP3: widget_mode propagates from settings
  - CP4: HR locale via `?lang=hr` → month header + date pill in HR (post-#471 — was static-locale trap killed)
  - CP5: form persist round-trip — F5 keeps adults, children, pets (post-#450 A.1 — pets field now persisted via `BookingFormState.toPersistedFormData/applyFromPersisted`)
  - CP6: "Powered by BookBed" badge → opens `https://bookbed.io` (hardcoded per widget rule; #450 C dropped per intentional exception)
- **Pre-fix vs post-fix delta:** CP4 was English-only static; CP5 lost pets across reload.
- **Tooling:** chrome-devtools MCP (`new_page`, `navigate_page`, `fill`, `take_screenshot`, `evaluate_script`).
- **Runtime:** ~30 min.
- **Acceptance:** closes audit/32 N1 (locale wiring) + audit/23 A.1 (pets persistence).

### §4.2 audit/49.2 Owner web replay (post-#467, #470 + #462 if env-set)

- **Target:** `https://bookbed-owner-dev.web.app`
- **Auth:** [memory test-account.md] (dev) — DO NOT use PROD account.
- **Pre-req:** §3.S.1 deploy gap closed first (`tool/deploy-dev.sh owner`).
- **Checkpoints** (from audit/33 template):
  - CP1: subdomain resolves `bookbed-dev` projectId (not `rab-booking-248fc`) — also re-verify §1 evidence at runtime
  - CP2: login + dashboard renders without ErrorBoundary trap (post-#455)
  - CP3: register a new owner with displayName="Smoke C1" → digit preserved (post-#470)
  - CP4: trigger email-resend cooldown → UI shows 60s (post-#470 doc)
  - CP5: role-escalation attempt — open DevTools console, attempt `firebase.firestore().doc('users/<self-uid>').update({role:'admin'})` → expect permission denied (covered by #462 rules tightening once env-set + merged)
  - CP6: NULL toString error class (audit/33 §4.4 N4) should NOT appear; verify Sentry filter (#455) suppresses Marionette-style keyboard events
- **Pre-fix vs post-fix delta:** CP3 used to truncate "Smoke C1"→"Smoke C"; CP4 doc said 30s.
- **Tooling:** chrome-devtools MCP.
- **Runtime:** ~45 min.
- **Acceptance:** closes audit/35 F-Auth-D1+D2 (sanitizer + cooldown drift), audit/33 §4.4 N4 (NULL toString class), audit/30 role-escalation gate (gated on #462 env unblock).

### §4.3 audit/49.3 Booking lifecycle E2E (post-#456, #458, #461, #472)

- **Target:** submit a booking via widget → owner approves → Resend delivers → iCal feed updates → guest cancels.
- **Auth:** dev owner [memory test-account.md] + throwaway guest email (Mailinator-style).
- **Checkpoints:**
  - CP1: widget submit → `bookings/{id}` doc shows `nights` field populated (PR #456 fold)
  - CP2: doc shows `emails_sent.pending_request` + `emails_sent.pending_owner_notification` after submit (PR #472)
  - CP3: owner approve → doc shows `emails_sent.approval.provider_id` = real Resend id, NOT null (PR #458 PR-B integration on `bookingManagement.ts` send path)
  - CP4: iCal feed (`getUnitIcalFeed`) immediately reflects the new booking (PR #461 cache invalidation, no 5-min lag)
  - CP5: guest direct-write of `bookings/{id}` from anon Firebase JS SDK → expect denied (T11c + #456 routing)
  - CP6: cancellation → `emails_sent.cancellation` written; iCal frees the date
- **KNOWN GAP G.1:** PR #472's create-time `emails_sent.{pending_request, pending_owner_notification, confirmation, owner_notification}` writes use `provider_id: null` because the 4 `atomicBooking.ts` email functions (`sendPendingBookingRequestEmail`, `sendPendingBookingOwnerNotification`, `sendBookingConfirmationEmail`, `sendOwnerNotificationEmail`) still return `Promise<void>`. PR #458 PR-B only updated the `bookingManagement.ts`-side functions. CP3 will show real provider_id ONLY for owner-approve/reject/cancellation paths (which thread through `bookingManagement.ts`). Create-time still null. **Follow-up PR needed** to extend PR-B to atomicBooking email functions.
- **Tooling:** Firebase Console + Mailinator + Resend dashboard.
- **Runtime:** ~60 min.
- **Acceptance:** closes audit/26 PR-A (direct-write bypass) + PR-B (provider_id) + audit/30 (iCal cache lag) + audit/34 §5 (emails_sent parity).

### §4.4 audit/49.4 Auth flows + SPF Gmail `Authentication-Results` closure

- **Target:** register fresh `<random>@gmail.com` throwaway → DO NOT click verify → Show Original in Gmail.
- **Auth:** throwaway Gmail account (NEVER reuse).
- **Checkpoints:**
  - CP1: registration mail arrives within 60 s
  - CP2: Gmail header `Authentication-Results: mx.google.com; spf=pass / dkim=pass / dmarc=pass` — full triple
  - CP3: capture `ARC-Authentication-Results` for forwarded chain
  - CP4: update audit/28 §5.3 with raw header excerpt + state CLOSED
- **Pre-req:** audit/28 §3 SPF gap on `bookbed.io` — Resend NOT in SPF include record. DMARC currently passes via DKIM-only alignment; SPF policy still `~all`. P3 deliverability optimization, not a blocker.
- **Tooling:** Gmail web → Show Original; admin SDK cleanup (`auth.deleteUser(uid)`) for the throwaway.
- **Runtime:** ~20 min.
- **Acceptance:** closes audit/28 §5.3 + audit/35 C2 (auth flows resumed).

### §4.5 audit/49.5 iOS owner Marionette (post-#455 + `fix/seed-checkin-field-name`)

- **Pre-req:**
  1. Push branch `fix/seed-checkin-field-name` (currently worktree-only per audit/40 §6) + open PR + merge.
  2. Run `audit/migrations/40-backfill-checkin-field.js --apply` against `bookbed-dev` (idempotent; refuses against `rab-booking-248fc`).
  3. iOS plist swap: `cp ios/Runner/GoogleService-Info.plist.backup ios/Runner/GoogleService-Info.plist` (per `.claude/rules/ios-development.md`).
  4. `flutter run -d <ios-device-id> --target lib/main_dev.dart`.
- **Checkpoints** (from audit/36 template):
  - D1: Marionette MCP `connect` to VM service URI
  - D3: Owner login → Rezervacije list → expect **4 entries** for SEED test owner (was 0 pre-fix due to `check_in_date` field-name drift)
  - D5: tap pending row → detail screen renders, NO ErrorBoundary trap (post-#455 stack-layer filter is platform-independent — `marionette_flutter` is pure Dart)
  - D6: counter persist across iOS background/foreground transition (post-#450)
  - D10: PLIST RESTORE step `git checkout ios/Runner/GoogleService-Info.plist` to revert to PROD on exit
- **Pre-fix vs post-fix delta:** FINDING-iOS-01 (ErrorBoundary trap) + FINDING-iOS-02 (Rezervacije empty) both expected ✅ post-fix.
- **Tooling:** marionette MCP (`tap`, `enter_text`, `take_screenshots`, `get_interactive_elements`).
- **Runtime:** ~45 min + plist swap risk window.
- **Acceptance:** closes audit/36 FINDING-iOS-01 + FINDING-iOS-02 (+ cross-confirms audit/40 root cause).

### §4.6 audit/49.6 Admin dashboard (post-#467 deploy + admin claim provision)

- **Target:** `https://bookbed-admin-dev.web.app`
- **Pre-req:** §3.S.1 deploy gap closed (`tool/deploy-dev.sh admin`); provision admin custom claim for [memory test-account.md] via admin SDK.
- **Checkpoints** (from audit/37 template):
  - CP1: §1 evidence runtime-verify (projectId=bookbed-dev)
  - CP2: login with admin claim → dashboard renders
  - CP3: subscription overview reads `/users` collection (admin-scope)
  - CP4: lifetime license grant action (audit/14 SF-018 path) writes `accountStatus=lifetime`
  - CP5: trial expiration warning queue visible
  - CP6: subscription list / refund / disconnect Stripe Connect — all 3 paths visible (gated on #462 if any depend on `ALLOWED_SUBSCRIPTION_PRICE_IDS`)
- **Tooling:** chrome-devtools MCP + Firebase admin SDK for claim provisioning.
- **Runtime:** ~30 min.
- **Acceptance:** closes audit/37 §1-§9.

### §4.7 audit/49.7 Security regression matrix (full E2E)

- **Pre-req:** all surfaces re-deployed; #462 env-unblocked; admin claim provisioned (for cross-tenant test).
- **Probes:**
  - P1: HEAD `/` against owner+admin → `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`. Re-run §3.S.1 post-deploy.
  - P2: anon Firebase JS SDK → read `users/<random>` → expect denied (T11c clause 1 closure)
  - P3: anon Firebase JS SDK → `collectionGroup('bookings').get()` → expect denied (T11c)
  - P4: anon Firebase JS SDK → `collectionGroup('ical_events').get()` → expect denied (SF-023)
  - P5: anon HTTP POST to `resendGuestBookingEmail` 4× from same IP within 1 h → 4th call returns rate-limit error (#463)
  - P6: anon HTTP POST to `getUnitIcalFeed` with redirect-loop URL → SSRF re-validation rejects per `validateIcalUrl` (#463)
  - P7: dormant-5 templates — manually invoke each via emulator → expect "no caller" error or success-with-warning (audit/28 §3.4)
- **Tooling:** Firebase Web SDK + curl from clean IP (use IPv6 or different network for IP-rotation tests).
- **Runtime:** ~90 min.
- **Acceptance:** closes audit/30 + audit/31 + audit/26 §5 (multi-PR security gate).

### §4.8 audit/49.8 Cross-feature integration (NEW scope)

- **Pre-req:** all above smokes green; #462 env-unblocked.
- **Scenarios:**
  - X1: iCal external import (Booking.com test feed) → seed conflict block → widget calendar shows blocked dates within 30 s polling window (FirebaseAvailabilityRepository default)
  - X2: Stripe subscription checkout — owner clicks "Upgrade" → POST `createSubscriptionCheckoutSession` with **valid** `ALLOWED_SUBSCRIPTION_PRICE_IDS` entry → 302 to Stripe Checkout
  - X3: same as X2 but with `priceId=price_INVALID` → 403 "Price not allowed." (PR #462 fail-CLOSED)
  - X4: multi-tenant: owner A creates booking on property P → owner B (different uid) reads `bookings/{id}` directly → expect denied (T11c clause 2 — only owner_id match allowed)
  - X5: SPF E2E — trigger CF (e.g. ReSend Booking Confirmation) → guest Gmail receives within 60s with full Authentication-Results triple pass
- **Tooling:** Stripe Dashboard (test mode), Mailinator + Gmail, Booking.com sandbox iCal feed.
- **Runtime:** ~60 min.
- **Acceptance:** closes audit/22 (PROD cutover prereq) + audit/24 §2 + audit/27 (lifecycle).

---

## §5 Known gap log

| ID | Gap | Impact | Follow-up |
|---|---|---|---|
| **G.1** | `atomicBooking.ts` 4 email functions still `Promise<void>` (`sendPendingBookingRequestEmail`, `sendPendingBookingOwnerNotification`, `sendBookingConfirmationEmail`, `sendOwnerNotificationEmail`) | PR #472 writes `provider_id: null` placeholder for create-time keys. Idempotency hole closed regardless. Resend silent-drop signal lost on these 4 send sites. | Open new PR: thread `sendEmailWithValidation` return value through all 4 atomicBooking email functions (extends #458 PR-B pattern). |
| **G.2** | PR #462 env-gated | `functions/.env.*` files not present in sandboxed read; operator-managed per audit/38. Until `ALLOWED_SUBSCRIPTION_PRICE_IDS` set per env, all subscription checkout calls fail-CLOSED. | Operator: create Stripe Price IDs (test+live) → populate per-env `.env` files → re-CI #462 → merge. |
| **G.3** | Hosting headers from PR #463 in `firebase.json` but NOT live on `bookbed-owner-dev` + `bookbed-admin-dev` (HEAD probe returns ∅) | XSS framing protection + content-type sniffing protection + referrer leakage protection NOT enforced on deployed dev surfaces. Production unverified (intentionally NOT probed). | Operator: `tool/deploy-dev.sh owner && tool/deploy-dev.sh admin`. Re-run §3.S.1 post-deploy. |
| **G.4** | audit/28 §5.3 Gmail `Authentication-Results` still DEFERRED | SPF + DKIM + DMARC triple-pass uncertified by direct header capture. SPF policy is currently `~all` (soft fail); DMARC passes via DKIM-only alignment. P3 deliverability concern. | §4.4 closes when human captures headers from throwaway Gmail. |
| **G.5** | FINDING-iOS-02 fix (`fix/seed-checkin-field-name`) NOT MERGED | iOS Rezervacije list shows empty pending pane for SEED test owner; cross-platform side-effect on `atomicBooking.ts:743-744` overlap-detection query against affected docs. | Open PR for branch + merge + run `audit/migrations/40-backfill-checkin-field.js --apply` against bookbed-dev. §4.5 covers iOS re-smoke. |
| **G.6** | audit/24 region drift | `createSubscriptionCheckoutSession` deployed to `us-central1` while remaining CFs are `europe-west1`. Cross-region latency penalty + observability split. Out-of-scope this orchestration. | Future audit; not blocking subscription flow correctness. |
| **G.7** | chrome-devtools MCP `isolatedContext` IndexedDB leak (audit/33 §9.1) | Service-worker registration of one CDP session can serve stale main.dart.js bundle on next CDP-launched session if cache-clear command did not include IDB delete. Operator-knowledge finding, not code. | Memory entry to be added: chrome-devtools-isolated-context-idb-cleanup recipe. |

---

## §6 Session orchestration summary

### Merge SHAs (29 PRs landed)

```
8f6e6d28  PR #478 — test fix (T11c fixture lag) [BISECT UNBLOCK]
657f392d  PR #467 — admin DEV contamination
56c6e19b  PR #453 — Stripe + widget_settings fixtures
e5aba063  PR #470 — displayName + cooldown drift
11a25bde  PR #463 — SSRF + DoS + headers
c3c29620  PR #449 — seed --test-owner
c36c02a3  PR #456 — PR-A direct-write + SF-026
69c735f3  PR #459 — audit/29 PR-A doc
e86d75ac  PR #458 — PR-B provider_id capture
ad23cd4e  PR #447 — booking widget Phase 0+1 refactor
edcc8a9f  PR #451 — --release rule prose
555d729c  PR #452 — CF same-day validation
fe5a8e36  PR #455 — ErrorBoundary narrowing
b117c055  PR #461 — iCal cache invalidation
6f9f9437  PR #471 — widget MaterialApp.locale wiring
b2e265c0  PR #464 — audit/32 smoke H
951614b6  PR #465 — audit/34 lifecycle smoke
210730e4  PR #469 — audit/37 admin smoke
1b8b048e  PR #476 — dependabot @tootallnate/once 2.0.1
437d3579  PR #477 — dependabot protobufjs 7.6.1
5d877df4  PR #479 — audit/48 consolidation doc
eba56306  PR #475 — gitignore cache hardening
23e04a4a  PR #468 — audit/36 iOS smoke (rebased)
4ed26f14  PR #466 — audit/35 auth smoke (rebased)
1825bd6d  PR #460 — Gemini prompt fence Phase C (rebased)
3e84f807  PR #450 — widget counter persist + maxPets clamp (manual 3-way)
4d72e3e6  PR #472 — emails_sent parity on booking create (manual 3-way)
```

### Main HEAD progression

```
3573c40f  → 2026-05-24 11:03Z (session start; red CI 6 days)
4d72e3e6  → 2026-05-24 20:28Z (session end; ~120 commits)
```

### Manual conflict resolutions (Phase 3B)

5/7 rebased + merged: `#475` (gitignore conflict — kept both blocks), `#468` (`-X ours`, doc commit dropped as upstream), `#466` (`-X ours` clean), `#460` (`-X ours`, doc commit dropped, code commit clean), `#450` (manual 4-block 3-way; adapted A.1 pets persistence into `BookingFormState`), `#472` (small `EmailSent` doc-comment conflict, atomicBooking auto-merged).

1 closed-superseded: `#448` (test-debt cleanup — fully covered by PR #478).

0 HALT remaining from Phase 3B.

### Outstanding open

- **30 PRs open at audit time:** ~17 bot/test-suggestion (#428-#445 family), #462 env-gated, #474 current-session feature branch (FCM env-aware SW + VAPID, MERGEABLE, untouched), 4 documentation/sequel PRs (#479 already merged before this audit).

### Worktrees retained

- `/Users/duskolicanin/git/bookbed` — main checkout (parallel-agent WIP on `fix/audit-33-har-followups`)
- `/tmp/bb-tests-fix-wt` — #478 (MERGED)
- `/tmp/bb-ci-retrigger-wt` — CI-retrigger pattern worktree
- `/tmp/bb-audit48-wt` — audit/48 (MERGED #479)
- `/tmp/bb-audit49-wt` — this doc
- `/tmp/bb-rebase-{475,468,466,460,450,448,472}` — 7 rebase worktrees (3 aborted, 4 successful)
- 19 pre-existing BookBed agent worktrees (parallel state)
- 5 Cursor detached-HEAD worktrees

Total: ~30 worktrees. Cleanup deferred per "do not delete until tested".

---

## Acceptance gate for audit/49 closure

- §1 ✅ deploy clean (offset evidence)
- §2 ✅ 10/10 invariants land
- §3 partials: ⚠️ G.3 hosting header deploy gap surfaced
- §4 deferred-manual checklists written (8 subsections, ~70 checkpoints total)
- §5 7 gaps documented with follow-up actions
- §6 ✅ 29 merges chronicled

Closes when:
- §4.1 + §4.2 + §4.5 + §4.6 manual smokes run green
- G.3 hosting headers re-deployed and re-verified
- G.5 FINDING-iOS-02 fix landed
- §4.4 SPF triple-pass captured

NOT a hard gate on G.1 + G.2 + G.6 (each is its own follow-up PR scope).
