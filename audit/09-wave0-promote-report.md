# Wave 0 Promote Report

**Date:** 2026-05-18
**Operator:** Claude (Opus 4.7 1M, interactive)
**Scope:** Promote 8 Wave 0 branches + 3 post-test fixes to `main`, apply Stripe SSRF dev allowlist hotfix, resmoke validate, tag stable.
**No push to origin.** **No prod deploy.** Dev deploy: `createStripeCheckoutSession` on `bookbed-dev` only.

---

## State summary

| Field | Value |
|---|---|
| Pre-state HEAD | `eadec3cc fix(widget): recover unit_id from path when daily_price doc is missing field` |
| Pre-state tag | `pre-wave0-promote` → `eadec3cc` |
| Post-state HEAD | `a480e5f3 Merge: fix test:rules after jest config ignore added` |
| Post-state tag | `post-wave0-stable` → `a480e5f3` |
| Branches advanced on `main` | 26 commits ahead of `origin/main` (12 merges + intermediate work, see breakdown) |

---

## Phase 1 — Wave 0 branch merges

| # | Branch | Result | Merge SHA | Gates |
|---|---|---|---|---|
| 1.1 | `chore/dev-deploy-readiness` (T12) | Merged `--no-ff` | `2fdec297` | analyze 0 / flutter 1100 / jest 152 |
| 1.2 | `feat/bb-design-tokens-alias-layer` (T10) | **Already up to date** — ancestor of T12 base, no merge commit | (n/a) | (state unchanged, no re-test) |
| 1.3 | `chore/ai-chat-remove-print` (T7) | Merged `--no-ff` | `fd33e976` | analyze 0 / flutter 1100 / jest 152 |
| 1.4 | `fix/widget-silent-catches` (T8) | **Already up to date** — shares SHA `57e67a27` with T7 (T8 actual work in stash@{8} "T8-silent-catches-WIP-rescued-by-T10") | (n/a) | (state unchanged) |
| 1.5 | `fix/bookings-hotfix-partial` (T11) | Merged `--no-ff` | `04e742df` | analyze 0 / flutter 1100 / **test:rules 8/8** (the 35-case suite is aspirational; only `bookings.test.ts` exists today) |

---

## Phase 2 — Post-test fix merges

| # | Branch | Result | Merge SHA | Conflicts resolved | Gates |
|---|---|---|---|---|---|
| 2.1 | `fix/null-tostring-hardening` | Merged `--no-ff` | `6f187d1a` | 1 file: `docs/TODO.md` (both sides added independent sections; kept both, null-tostring first per ordering decision) | analyze 0 / flutter 1100 / rules 8/8 |
| 2.2 | `fix/error-boundary-and-chat-ux` | Merged `--no-ff` | `13c6a9c9` | 3 files: `CLAUDE.md` (kept context-mode section + v7.1 bump), `docs/CHANGELOG.md` (kept both 6.68 + 6.67, dropped redundant "Reserved v6.67" placeholder), `ai_chat_provider.dart` (dropped orphan `final errorMsg = e.toString();` left behind by T7) | analyze 0 / flutter 1100 / rules 8/8 |
| 2.3 | `fix/environment-url-centralization` | Merged `--no-ff` | `e162d5d1` | 2 files: `.claude/rules/widget.md` (kept "Silent debug guards" from HEAD, dropped obsolete "Brittle host check" + "Hardcoded literals" sections, took post-fix "Host comparisons" from incoming), `docs/CHANGELOG.md` (**bumped env-url entry from claimed 6.67 → 6.69** to avoid collision with already-landed error-boundary 6.67; top "Last Updated" now 6.69) | analyze 0 / flutter 1100 / rules 8/8 |

---

## Phase 3 — Stripe SSRF dev allowlist hotfix

**Finding contrary to prompt:** `functions/src/stripePayment.ts` had a **hardcoded const-array** allowlist (no `WIDGET_ALLOWED_HOSTS` env var existed). The prompt's "append env var to `functions/.env.bookbed-dev`" path was unsatisfiable as written. User-approved alternative: surgical patch making `ALLOWED_RETURN_DOMAINS` env-aware.

**Code change** (`functions/src/stripePayment.ts`, lines ~37-71):
- Converted `const ALLOWED_RETURN_DOMAINS = [...]` → `function getAllowedReturnDomains(): string[] { ... }`
- Function reads `process.env.GCP_PROJECT` / `GCLOUD_PROJECT` / `FUNCTIONS_EMULATOR`
- Appends `https://bookbed-widget-dev.web.app` + `https://bookbed-owner-dev.web.app` when project = `bookbed-dev` or emulator
- Appends `https://bookbed-widget-staging.web.app` + `https://bookbed-owner-staging.web.app` when project = `bookbed-staging`
- Two callers updated to invoke the function: `isAllowedReturnUrl()` and the security-logging branch
- `ALLOWED_WILDCARD_DOMAINS` untouched (separate `.view.bookbed.io` subdomain matching, stays prod-only)

**No env file changes.** No new env vars created. No secrets touched.

**Branch + merge:**
- `fix/stripe-dev-allowlist` (`10b7024f`) → merged `--no-ff` → `e4a260d8`

**Deploy:**
- `firebase deploy --only functions:createStripeCheckoutSession --project bookbed-dev`
- Result: ✓ Successful update of `createStripeCheckoutSession(us-central1)` on `bookbed-dev`
- **NOT deployed** to `rab-booking-248fc` (prod) or `bookbed-staging`

---

## Phase 3b — Post-merge jest config fixes (improvised, both user-approved)

After the Phase 3 gate exposed a pre-existing T11 issue where `npm test` was structurally broken (rules tests required emulator but weren't excluded from default jest run):

1. **`chore/jest-exclude-rules-from-default`** (`041b8cd4`) → merge `3d61e461`
   - Added `testPathIgnorePatterns: ["/node_modules/", "<rootDir>/test/firestore_rules/"]` to `functions/jest.config.js`
   - Cleaned `npm test` (back to 152/152) — but **broke `test:rules`** (config-level ignore stripped firestore_rules even when CLI explicitly requested them; 0 tests matched)

2. **`chore/jest-rules-script-fix`** (`f2d957d6`) → merge `a480e5f3`
   - Updated `functions/package.json` `test:rules` script to add `--testPathIgnorePatterns=/node_modules/` (CLI override clears the config ignore for this command only)
   - Both `npm test` (152/152) and `npm run test:rules` (8/8) clean

---

## Phase 4 — Resmoke validation on post-merge `main`

### 4.1 Local gates on HEAD `a480e5f3`

| Gate | Result |
|---|---|
| `flutter analyze` | 0 issues (5.1s) |
| `flutter test` | 1100 / 1100 pass |
| `cd functions && npm test` | 152 / 152 pass (10 suites) |
| `cd functions && npm run test:rules` | 8 / 8 pass (firestore emulator) |

### 4.2 Widget dev build

```
flutter build web --release --target lib/widget_main_dev.dart --output build/web_widget
✓ Built build/web_widget (compile 32.7s)
```

### 4.3 Live smoke on `bookbed-dev`

**Cloud Function HTTPS probes** (callable wire protocol, unauthenticated POST):

| Endpoint | Body | Status | Response excerpt |
|---|---|---|---|
| `getBookingByStripeSession` | `{sessionId: 'cs_test_bogus_12345'}` | **404 NOT_FOUND** ✓ | `"Booking not yet available."` |
| `verifyBookingAccess` | `{bookingReference: 'BOGUS-REF-99999', email: 'bogus@example.com'}` | **404 NOT_FOUND** ✓ | `"Booking not found."` |
| `createStripeCheckoutSession` | `{unitId: 'bogus'}` | **400 INVALID_ARGUMENT** ✓ | `"Booking data is required"` (function alive, validates input — no SSRF 500) |

**Live Firestore rules regression** (unauthenticated REST runQuery against `bookbed-dev`):

| Query | Expected | Actual | Verdict |
|---|---|---|---|
| `bookings` where `stripe_session_id == 'cs_test_bogus'` | 403 DENIED (T11 closed clause) | **403 PERMISSION_DENIED** | ✓ |
| `bookings` where `booking_reference == 'BOGUS-REF'` | 403 DENIED (T11 closed clause) | **403 PERMISSION_DENIED** | ✓ |
| `bookings` where `unit_id == 'bogus-unit' && status == 'confirmed'` | 200 ALLOWED (T11 left clause, deferred to T11c) | **200 OK** (empty result, query authorized) | ✓ |

**iCal endpoint:**

| Method | URL | Status |
|---|---|---|
| HEAD | `icalExport?propertyId=bogus&unitId=bogus` | 404 (in 200/405 acceptable range; bogus IDs) |
| GET | same | 404 |

### 4.4 Embed URL spot check

`grep -rn "view.bookbed.io" lib/features/ | grep -v test | grep -v .g.dart` → **13 hits**, all categorized:

| Type | Count | Files | Status |
|---|---|---|---|
| Comments / docstrings | 6 | `subdomain_service.dart`, `booking_view_screen.dart`, `embed_widget_guide_screen.dart`, `subdomain_not_found_screen.dart` | No code effect |
| Embed-snippet HTML for owner copy/paste | 4 | `embed_widget_guide_screen.dart:678/693/756/759` | Documented exception (widget.md rule) |
| Demo/example URLs in owner help | 3 | `embed_help_screen.dart:36/297/304` | Documented exception (widget.md rule) |

**Zero non-exception hits in production code paths.** All host comparisons now route via `EnvironmentConfig`.

---

## Phase 5 — Tag + branches awaiting Wave 1 cleanup

**Tag:** `post-wave0-stable` → `a480e5f3` ✓

**Branches mergeable for deletion (NOT deleted in this run — Wave 1 archives-and-deletes):**

- `chore/ai-chat-remove-print` (T7)
- `fix/widget-silent-catches` (T8 — SHA collision with T7; actual work in stash@{8})
- `feat/bb-design-tokens-alias-layer` (T10 — already ancestor of main pre-promote via T12)
- `chore/dev-deploy-readiness` (T12)
- `fix/bookings-hotfix-partial` (T11)
- `fix/null-tostring-hardening`
- `fix/error-boundary-and-chat-ux`
- `fix/environment-url-centralization`
- `test/wave0-integration` (delete-safe — test only)
- `fix/stripe-dev-allowlist` (created in Phase 3, now merged)
- `chore/jest-exclude-rules-from-default` (Phase 3b helper, merged)
- `chore/jest-rules-script-fix` (Phase 3b helper, merged)

---

## Outstanding items / follow-ups

### Stash status (carry-forward for Wave 1 triage)

| Stash | Branch | Description | Action |
|---|---|---|---|
| `stash@{0}` | `fix/error-boundary-and-chat-ux` | `T13-docs-work` | Already covered by `cf91d952` doc commit + merges — review-and-drop candidate |
| `stash@{1}` | `fix/error-boundary-and-chat-ux` | `sibling-agent-booking-view-redo-1779121309` | Sibling-agent artifact — triage for relevance, likely drop |
| `stash@{2}` | `fix/error-boundary-and-chat-ux` | `sibling-agent-widget-redo-1779121234` | Sibling-agent artifact — triage, likely drop |
| `stash@{3}` | `fix/error-boundary-and-chat-ux` | `sibling-agent-env-subdomain-edits` | Likely superseded by T13 — review-and-drop |
| `stash@{4}` | `fix/error-boundary-and-chat-ux` | `sibling-agent-widget-host-edits-from-other-task` | Likely superseded by T13 — review-and-drop |
| `stash@{5}` | `fix/null-tostring-hardening` | `wave0 smoke-test wiring — restore after URL fix` | Real wave0 dev tooling — REVIEW before drop |
| `stash@{6}` | `test/wave0-integration` | `wave0-followup-todo: TODO.md additions` | TODO.md additions — check for unique content not covered by current TODO state |
| `stash@{7}` | `test/wave0-integration` | `wave0-dev-tooling-WIP: marionette + email-verif flag + error_boundary reset + login keys` | Marionette + dev-tooling WIP — likely partially covered; review |
| `stash@{8}` | `fix/widget-silent-catches` | `T8-silent-catches-WIP-rescued-by-T10` | T8 work rescued by T10; verify T10 covered all 18 silent catches before final drop |

(stash@{9}-{13} predate Wave 0 — out of scope here.)

### Architectural follow-ups recorded by these merges

- **T11c**: Drop `unit_id+status` clause from `bookings` rule. Requires `getUnitAvailability` Cloud Function first. Tracked in `docs/TODO.md` § "T11c — Drop `unit_id+status` clause".
- **Login submit crash on Flutter web**: CanvasKit text-input sync, separate bug class from `null.toString()`. Tracked in `docs/TODO.md`.
- **Tech-debt audit findings** (`audit/04-techdebt.md`): C1 MD5 IV, C3 silent catches in confirmation screen, H2 Stripe Price IDs hardcoded, M1-M7. Tracked in `docs/TODO.md`.
- **Stripe SSRF refactor toward env-var pattern**: Current `getAllowedReturnDomains()` is conditional-by-projectId — a real `WIDGET_ALLOWED_HOSTS` env var would be cleaner long-term. CHANGELOG 6.69 follow-up note retained as forward-looking marker.
- **T11 rules suite expansion**: Currently 8/8 (bookings only). The "35-case rules suite" referenced in MEMORY.md is aspirational — units/properties/users/etc. rules tests remain to be authored.

### Pre-existing condition surfaced (jest config)

`functions/jest.config.js` shipped post-T11 without `testPathIgnorePatterns` for `firestore_rules/`, breaking plain `npm test`. Fixed in Phase 3b (`a480e5f3` chain). Not a regression introduced by Wave 0 work, but surfaced by it.

### Multi-agent git race observed

During pre-flight, branch swaps between `git status` and `git add` were observed (≥5 active claude sessions on the host). MEMORY note `multi-agent-git-race` is current and was load-bearing. Sibling agents had already committed equivalent docs (`cf91d952`, `79761cbb`, `1e893e28`) in parallel — no work was lost, but ordering became non-deterministic. Recommend serializing future promote runs via the `.claude/scheduled_tasks.lock` file or an external mutex.

---

## What was NOT done

- ✗ `git push origin main` — by design (user pushes manually after reading this doc)
- ✗ Any deploy to `rab-booking-248fc` (prod) — by design
- ✗ Any deploy to `bookbed-staging` — by design
- ✗ Any branch deletion — Wave 1 archive-and-delete handles
- ✗ Merge or rebase of any branch outside the 8 listed (+3 helper branches created mid-promote)
- ✗ `git commit --amend` on any commit — by design; helper-branch fixes were new commits
- ✗ Cherry-pick from stashes — left for Wave 1 stash triage

---

## Final merge graph (main, since pre-state)

```
* a480e5f3 (HEAD, tag: post-wave0-stable, main) Merge: fix test:rules after jest config ignore added
|\
| * f2d957d6 chore(test): override testPathIgnorePatterns in test:rules to re-include rules suite
|/
* 3d61e461 Merge chore: jest excludes firestore_rules from default run
|\
| * 041b8cd4 chore(functions): exclude firestore_rules from default jest (needs emulator)
|/
* e4a260d8 Merge fix: Stripe dev allowlist
|\
| * 10b7024f fix(stripe): allow dev/staging widget hosts in return URL allowlist
|/
* e162d5d1 Merge fix: centralize widget/dashboard/marketing host URLs
* 13c6a9c9 Merge fix: ErrorBoundary state reset + AI chat error UX
* 6f187d1a Merge fix: eliminate null.toString() coercions
* 04e742df Merge T11-hotfix-partial: close stripe_session_id + booking_reference public-read
* fd33e976 Merge T7: ai_chat_provider print() removal
* 2fdec297 Merge T12: dev env readiness
* eadec3cc (tag: pre-wave0-promote) [pre-state]
```
