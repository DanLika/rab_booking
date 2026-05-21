# Widget E2E Smoke Test — bookbed-dev (PARTIAL)

**Date:** 2026-05-21
**Branch:** `main` @ `cfb49208`
**Status:** PARTIAL — backend/build/static checks only. Browser-drive tasks 1-10 BLOCKED.

---

## Blocker — Chrome DevTools MCP not installed

Task spec requires Chrome DevTools MCP to drive widget E2E. Available MCP servers in this session: `marionette` (Flutter VM service only, not Safari), `supabase`, `semgrep`, `context-mode`, `Netlify`, `claude.ai Gmail/Calendar/Drive`. No browser-automation MCP.

**Tasks BLOCKED pending Chrome DevTools MCP install:**
- TASK 1 (HAR + first interactive paint)
- TASK 2 (Mode 2 booking E2E)
- TASK 3 (Mode 3 Stripe payment E2E)
- TASK 4 (Mode 1 calendar-only)
- TASK 5 (Guest cancellation flow)
- TASK 6 (Edge cases — date/form/Stripe-decline)
- TASK 7 (Responsive breakpoints 320–1920)
- TASK 8 (i18n EN/DE/IT/HR)
- TASK 9 (Dark mode contrast)
- TASK 10 (Sentry dev env-tag verification — needs runtime client error capture)

Marionette (Flutter VM) was rejected as substitute: wrong code path (`!kIsWeb` branches, no web-specific Stripe redirect / iframe API / viewport emulation / browser console).

**Recommended install:** `claude mcp add chrome-devtools "npx @anthropic-ai/chrome-devtools-mcp"` then restart session.

---

## Session anomaly — branch flipped mid-run

- Initial check: `git branch --show-current` = `main` ✓
- ~5 commands later: `git branch --show-current` = `hotfix/widget-secrets-exfil` (no manual checkout)
- Restored to `main` per user direction.

Likely a multi-agent git race (already documented in memory `multi-agent-git-race.md`). Worth flagging before next session. Workdir state: clean both times.

---

## PRE-FLIGHT results

### #3 — Cloud Functions on bookbed-dev

All 4 required CFs deployed (real name `createStripeCheckoutSession`, prompt had wrong shorthand):

| CF | Type | Region |
|---|---|---|
| `createStripeCheckoutSession` | callable v2 | us-central1 |
| `getUnitIcalFeed` | https v2 | us-central1 |
| `verifyBookingAccess` | callable v2 | us-central1 |
| `getBookingByStripeSession` | callable v2 | us-central1 |

Also present (related): `handleStripeWebhook`, `createSubscriptionCheckoutSession`, `cleanupExpiredStripePendingBookings`, `createStripeConnectAccount`, `getStripeAccountStatus`, `disconnectStripeAccount`.

### #4 — Test fixtures on bookbed-dev

Queried via Firebase Admin SDK (ADC token):

| Fixture | Status | Notes |
|---|---|---|
| `properties/SEED_property_dev_01` | ✓ exists | name=`BookBed Dev Test Villa`, subdomain=`seed-dev`, owner_id=`Zo01CJ3wymb0pplaYOyaZ2yGUWG2` |
| `units/SEED_unit_dev_01` | ✓ exists | base=€120, weekend=€150, max=4, available=true |
| `widget_settings/widget_settings` | ✗ MISSING | Defaults to `WidgetMode.bookingPending` (Mode 2) — sufficient for default-mode test, blocks Mode 1/3 testing without seeding |
| `widget_secrets/widget_secrets` | ✗ MISSING | Concerning given branch `hotfix/widget-secrets-exfil` exists. Hotfix NOT merged to `main` (verified) AND `grep -rn "widget_secrets\|widgetSecrets" lib/ --include="*.dart"` returns **0 matches** on `main` → widget code on `main` doesn't read this doc → seed is compatible with current `main`. Re-seed required before testing hotfix branch. |
| `bookings/SEED_booking_dev_01` | ✗ MISSING | Conflicts with `audit/11-sentry-env-fix.md` line 64-71 which 7h ago found it `EXISTS, status='cancelled'`. Deleted in interim (unknown actor). Task 5 (cancel flow) blocked — can be backfilled by Task 2 (create new booking). |
| Auth `smoketest-runtime@bookbed.test` | ✓ UID `Zo01CJ3wymb0pplaYOyaZ2yGUWG2` (= property `owner_id` ✓) | |
| Auth `wave0-smoke-202605181440@bookbed.test` | ✗ not found | Memory ref was for a different smoke run |

**Memory note:** `scripts/seed-bookbed-dev.js` referenced in `memory/wave0-smoke-test-2026-05-18.md` is NOT in repo (confirmed by `audit/11-sentry-env-fix.md` line 83). Cannot re-seed automatically. If browser run needs fixtures, write fresh seed via Admin SDK.

### #5 — Bundle build

```
flutter pub get   → OK (2 discontinued, 133 outdated transitive — pre-existing)
flutter build web --release --target lib/widget_main_dev.dart --output build/web_widget
  → ✓ Built build/web_widget in 30.9s
```

| Artifact | Size |
|---|---|
| `build/web_widget/main.dart.js` | **3.6 MB** (under 5 MB flag threshold ✓) |
| `build/web_widget/canvaskit/canvaskit.wasm` | 6.8 MB (vendored, expected) |
| Total `build/web_widget/` | **37 MB** |

**Build warnings (pre-existing, not regressions):**
- Wasm dry-run incompatibilities: `flutter_secure_storage_web` (`dart:html`, `dart:js_util`, `package:js`) + `image-4.5.4` (`avoid_double_and_int_checks` lint). Path to wasm builds blocked by these deps. Tracked separately.
- Font tree-shaking: MaterialIcons 99.1%, CupertinoIcons 99.4%, TablerIcons 4.2% reduction.

---

## Static code checks

### T11 firestore bookings bypass — PASS

CLAUDE.md `NIKADA NE MIJENJAJ` says clause 1 (`unit_id+status`) is INTENTIONALLY public until T11c `getUnitAvailability` CF lands. Other 2 clauses (`stripe_session_id`/`booking_reference`) were closed in T11-hotfix-partial.

Verified static behavior matches the rule:

| Check | Result |
|---|---|
| Hard-coded `firestore.googleapis.com` URL anywhere in `lib/` | **0 matches** ✓ |
| `collectionGroup('bookings')` in widget code | **0 matches** ✓ (no client bypasses) |
| `collectionGroup('units')` in widget | 2 callsites — `firebase_daily_price_repository.dart:95`, `booking_price_calculator.dart:200`. Not bookings → out of T11 scope. |
| `FirebaseFirestore.instance` in widget | 1 callsite — `subdomain_service.dart:17` (resolves property by subdomain, not bookings) → out of T11 scope. |
| Stripe return path | `booking_widget_screen.dart:1326` explicit comment `// T11-hotfix-partial: route through getBookingByStripeSession callable`, calls callable at :1343 ✓ |
| Booking access lookup | `booking_lookup_provider.dart:40` `verifyBookingAccess` callable, :102 `getBookingByStripeSession` callable ✓ |

**Runtime validation deferred** (would need browser-drive: open `view.bookbed.io/?session_id=...`, Network tab → confirm zero direct GETs to `firestore.googleapis.com/v1/projects/bookbed-dev/.../bookings?...`).

### Sentry env-tag wiring — ⚠️ WIDGET DART STILL BROKEN

`audit/11-sentry-env-fix.md` (2026-05-21) fixed **functions/src/sentry.ts** only. Widget Dart-side Sentry init has the same class of bug but was NOT touched.

| File | Line | Code | Verdict |
|---|---|---|---|
| `lib/widget_main.dart` | 115 | `options.environment = 'production';` | **HARDCODED** regardless of project. Any deployed widget release binary (incl. on dev hosting if widget_main.dart is ever served there) tags events `production`. |
| `lib/main.dart` | 499 | `options.environment = 'production';` | Same hardcoded value in owner-dashboard `lib/main.dart`. |
| `lib/widget_main_dev.dart` | 17 | `// const String _sentryDsn = ...` (commented out) | Dev widget entry has Sentry disabled entirely — safe-by-omission only because no DSN. |

**Why it's the runtime version of yesterday's CF bug:** verified deploy entry points:

| Deploy target | Script | Entry point | Sentry result |
|---|---|---|---|
| **dev** (`bookbed-widget-dev.web.app`) | `scripts/deploy_dev.sh:10` | `lib/widget_main.dart` | Tags `production` ⚠️ |
| **staging** | `scripts/deploy_staging.sh:10` | `lib/widget_main.dart` | Tags `production` ⚠️ |
| **prod** (`view.bookbed.io`) | `scripts/deploy_prod.sh:17` | `lib/widget_main.dart` | Tags `production` ✓ |
| CI | `.github/workflows/deploy-widget.yml:41` | `lib/widget_main.dart` | Tags `production` |

`widget_main_dev.dart` (Sentry off) is **local-dev-only** — never built by deploy scripts. So every deployed widget across all three envs ships with `options.environment = 'production'` baked in. Identical bug class to `audit/11-sentry-env-fix.md` but on the Dart/widget side. Yesterday's commit `4b56f8fb` only fixed the CF side.

**Recommended fix (out of scope for this run):** mirror the CF approach in Dart — read `EnvironmentConfig.sentryEnvironment` (or detect from `Firebase.options.projectId`), with explicit per-project labels `development|staging|production|unknown`. Apply same pattern to `lib/main.dart:499` (owner dashboard).

### Stripe session round-trip — PASS

| Check | Location | Result |
|---|---|---|
| Stripe checkout init | `lib/core/services/stripe_service.dart:60` | `httpsCallable('createStripeCheckoutSession')` ✓ |
| Return URL parsing | `booking_url_state_service.dart:131` | `uri.queryParameters['session_id']` ✓ |
| Session ID validation | `booking_widget_screen.dart:128-131` | regex `^cs_(test|live)_[A-Za-z0-9]+$` ✓ (defense against arbitrary param injection) |
| Hydration lookup | `booking_widget_screen.dart:1343` | `lookupService.getBookingByStripeSession(sessionId)` callable ✓ |

**Runtime validation deferred** (would need real Stripe test-mode checkout + return — needs browser).

---

## Open observations for next session

1. **Sentry Dart-side env tag fix needed.** Mirror `functions/src/sentry.ts` `detectEnvironment()` for `widget_main.dart` and `lib/main.dart`. (Pre-existing, not introduced by this run.)
2. **Branch race recurrence.** Memory `multi-agent-git-race.md` exists; consider adding pre-commit hook that aborts if branch ≠ branch-at-`git add` time.
3. **Seed script not in repo.** `scripts/seed-bookbed-dev.js` referenced in 2 places (memory + audit/07) but never committed. Either commit or remove the refs.
4. **`SEED_booking_dev_01` re-vanished.** Was confirmed present ~7h ago; gone now. Worth investigating before next smoke run — manual cleanup? CF? agent?
5. **Wasm dry-run blockers.** `flutter_secure_storage_web` + `image-4.5.4` block wasm build. Low-pri but worth tracking.

---

## When Chrome DevTools MCP available — resume order

1. Re-seed fixtures (or generate new IDs) — write a tiny Admin SDK script first, commit it as `scripts/seed-bookbed-dev.js` so it stops vanishing.
2. Re-confirm branch = `main`, build artifacts unchanged.
3. Serve `python3 -m http.server 8080 --directory build/web_widget`.
4. Run TASK 1 (HAR + console + bundle metrics).
5. Run TASK 2 (Mode 2 — default).
6. Set `widget_settings.widget_mode = 'fullPayment'` via Admin SDK (Stripe Connect needed for the owner — see `audit/07-chrome-smoke-test.md` line 246; Connect is interactive OAuth, cannot be faked).
7. Run TASK 3 only if Stripe Connect onboarding completed.
8. Continue 4–10.

---

**Files referenced:**
- `audit/07-chrome-smoke-test.md` (Wave 0 fixture spec)
- `audit/11-sentry-env-fix.md` (CF Sentry fix from earlier today)
- `audit/06-bookings-hotfix-partial.md` (T11 hotfix — clauses 2/3 closed)
- `memory/multi-agent-git-race.md`
- `memory/wave0-smoke-test-2026-05-18.md`
