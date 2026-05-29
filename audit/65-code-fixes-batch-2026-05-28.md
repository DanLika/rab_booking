# audit/65 — Code Fixes Batch (audit/62 + audit/63 + audit/64)

**Date**: 2026-05-28
**Inputs**: audit/62-ios-e2e-smoke-2026-05-28.md, audit/63-android-e2e-smoke-2026-05-28.md, audit/64-chrome-e2e-smoke-2026-05-28.md
**Outcome**: 4/5 PRs landed, 1 finding deferred (scope > 50 LOC)

---

## Summary table

| # | Finding | PR | Branch | Status | Files | LOC | Tests | Analyze |
|---|---|---|---|---|---|---|---|---|
| 1 | F-62-01 logout confirmation | #532 | `fix/f-62-01-logout-confirmation` | OPEN | profile_screen.dart, app_{en,hr}.arb, l10n gen | +47 | 1205/1205 | 0 issues |
| 2 | F-62-03 / F-58c-14 clear email + RememberMe on logout | #533 | `fix/f-62-03-logout-clear-remember-me` | OPEN (stacked on #532) | enhanced_auth_provider.dart, profile_screen.dart | +20 / −8 | 1205/1205 | 0 issues |
| 3 | F-62-05 deep-link warm-start | — | — | **DEFERRED** | (see below) | — | — | — |
| 4 | F-64-04 `<html>` missing lang | #534 | `fix/f-64-04-html-lang` | OPEN | web/index.html | +1 / −1 | n/a (HTML) | n/a |
| 5 | F-63-04 chip row clip at 200% font scale | #535 | `fix/f-63-04-chip-row-overflow` | OPEN | dashboard_overview_tab.dart, bookings_tab_bar.dart | +70 / −77 | 1205/1205 | 0 issues |

All PRs target `main`. Stacking: #533 depends on #532 — merge #532 first to avoid rebase. #534 and #535 independent.

---

## FIX 1 — F-62-01 logout confirmation (PR #532)

`Profil → Odjava` previously called `signOut()` instantly on tap. Wrapped in `showDialog<bool>` confirmation matching the destructive-op pattern elsewhere in the app.

**Files**
- `lib/features/owner_dashboard/presentation/screens/profile_screen.dart` — wrap `onLogout`
- `lib/l10n/app_en.arb` + `app_hr.arb` — `logoutConfirmTitle`, `logoutConfirmMessage`
- `lib/l10n/app_localizations*.dart` — regenerated via `flutter gen-l10n`

Reuses existing `cancel` + `logout` keys for action buttons.

**Verification**
- `flutter analyze lib/features/owner_dashboard/presentation/screens/profile_screen.dart` → 0 issues
- `flutter test test/` → 1205/1205 passed (00:30)
- Pre-commit hook ran `dart format .` (656 files, 1 reformatted on first attempt, 0 on second)

---

## FIX 2 — F-62-03 clear email + RememberMe on logout (PR #533)

Profil → Odjava left `SecureStorage.saved_email` + `remember_me` intact, so the login screen pre-filled the just-logged-out user. Cross-platform (iOS confirmed audit/62, web parallel via audit/58c F-58c-14).

Added a `clearSavedEmail` named param to `signOut()`, **default false** to preserve legacy convenience for session-expiry / credential-revoke paths (Apple cred revoke at `_checkAppleCredentialState`, session-expiry signOuts inside the file). Explicit Profil → Odjava call site passes `true`.

SF-007 unchanged — password is NEVER stored.

**Files**
- `lib/core/providers/enhanced_auth_provider.dart` — new param, wires `SecureStorageService().clearCredentials()`
- `lib/features/owner_dashboard/presentation/screens/profile_screen.dart` — call site passes `clearSavedEmail: true`

**Stacking**: branch rebased onto `fix/f-62-01-logout-confirmation` because both PRs touch the same `onLogout` block in `profile_screen.dart`. Merger should land #532 first.

**Verification**
- `flutter analyze` on 2 files → 0 issues
- `flutter test test/` → 1205/1205 passed (00:29)

---

## FIX 3 — F-62-05 deep-link warm-start (DEFERRED)

**Decision**: SKIP per HARD RULES ("> 50 LOC or architectural change → STOP, write finding to audit/65").

**Root cause found**
- `lib/core/services/deep_link_service.dart` exists as a route-parser BUT has **zero callers** anywhere in `lib/` (verified with `grep -rln "DeepLinkService\|handleDeepLink" lib/`)
- `pubspec.yaml` has **no `app_links` / `uni_links` dependency** — there is no Dart-side listener subscribed to the OS-side intent stream at all
- The Android `AndroidManifest.xml` intent filters for `bookbed://` are registered (so OS opens the app), but the app never receives the URL to navigate
- The parser also lacks a `/unit/{id}` route case — only `/owner/calendar`, `/owner/bookings`, `/owner/platform-connections`

**Why audit observed warm-start only**
Cold-start works coincidentally because OS launches the app — but no navigation happens; the user lands on the default route. Warm-start fails for the same reason (no listener), but with the app already running the missing nav is visible (no-op).

**Scope for a real fix** (well over 50 LOC):
1. Add `app_links: ^6.x` to `pubspec.yaml` + `pubspec.lock` regen
2. Create a service that subscribes to both `appLinks.uriLinkStream` (warm) AND `appLinks.getInitialAppLink` (cold)
3. Wire that service into `main.dart` / `widget_main.dart` / `admin_main_*.dart` init paths (6 entry points)
4. Add `/unit/{id}` route case to `DeepLinkService._handleAppDeepLink`
5. Multi-platform tests: simctl `openurl` (iOS warm + cold), `adb shell am start -a android.intent.action.VIEW -d "bookbed://unit/abc123"` (Android warm + cold), browser intent on web
6. Handle iOS + Android Universal/App Links (`https://bookbed.io/unit/abc123`) — the manifest registers those too

**Risk**: touching app init affects every surface. Needs its own PR + smoke matrix.

**Carry forward**: tracked here; not a new audit doc.

---

## FIX 4 — F-64-04 `<html>` missing lang (PR #534)

Single line: `<html>` → `<html lang="hr">`. Chrome DevTools a11y audit flag; required for screen readers + Chrome auto-translate. HR is BookBed's default locale (per audit/63 default UI).

**Files**
- `web/index.html` — 1 line

**Verification**
- `git diff web/index.html` → only the `lang="hr"` insertion
- Pre-existing Semgrep SRI integrity warnings on lines 156/197-202 (CDN scripts without `integrity` attribute) — flagged by `post-tool-cli-scan` hook; **predates this PR**, documented in commit message + PR body

---

## FIX 5 — F-63-04 chip row overflow at 200% font scale (PR #535)

At system `font_scale=2.0` on Pixel_8 (360dp viewport), the Pregled "Zadnjih 7/30/90/365 dana" chips clipped at the right viewport edge despite a horizontal `SingleChildScrollView` wrapper — user had no scroll affordance and trailing chips were unreachable. Same class on Rezervacije `BookingsTabBar` where "Otkazane" partial-clipped to "O…" already at 1.0× under HR locale.

Converted both surfaces to `Wrap`. Chips break to a second line under constrained widths or large text. Default 1.0× single-line layout unchanged when chips fit.

**Files**
- `lib/features/owner_dashboard/presentation/screens/dashboard_overview_tab.dart` — `_DateRangeSelector` (Pregled date-range chips)
- `lib/features/owner_dashboard/presentation/widgets/bookings/bookings_tab_bar.dart` — `BookingsTabBar` (Rezervacije status tabs)

**Tradeoff**: `bookings_tab_bar.dart` loses `ListView.builder` lazy-render path. Only 5 tabs — negligible.

**Verification**
- `flutter analyze` on 2 files → 0 issues
- `flutter test test/` → 1205/1205 passed (00:29)

---

## Pre-existing analyzer warnings (NOT in scope)

Across all 5 fix branches, `flutter analyze` of the whole tree reports 2 pre-existing infos unrelated to any fix in this batch:

```
info • The value of the argument is redundant because it matches the default value
       • lib/core/services/rate_limit_service.dart:167:22 • avoid_redundant_argument_values
info • Angle brackets will be interpreted as HTML
       • lib/core/utils/web_utils_web.dart:349:51 • unintended_html_in_doc_comment
```

These predate the audit/62/63/64 inputs and are not addressed here.

---

## Hygiene

- Each fix on its own branch off `main` (except FIX 2 stacked on FIX 1).
- Foreign working-tree drift (`Podfile.lock`, `pubspec.lock`, `google-services.json`, `CLAUDE.md`, untracked screenshots in audit/) untouched. Each branch commit stages **only** its own files.
- Pre-commit hook `dart format .` enforced — 1 reformat caught + amended on FIX 1; subsequent commits clean.
- Branch guard `[ "$(git branch --show-current)" = "<expected>" ] || exit 1` before every staging step. Caught one mid-session branch swap (FIX 1 was reset to `main` between `git add` and `git commit` — likely parallel-agent race per `[[multi-agent-git-race]]`; recovered by re-checkout + re-stage on the right branch).
- `gh pr create` warned about uncommitted changes (the foreign drift) — confirmed those files NOT in the PR diffs.

---

## Open PRs (5 net)

```
#532  fix(auth): logout confirmation dialog (F-62-01)
#533  fix(auth): clear saved email + rememberMe on explicit logout (F-62-03)   [stacked on #532]
#534  fix(a11y): add lang=hr to web/index.html (F-64-04)
#535  fix(ui): wrap filter chip rows for large font scale (F-63-04)
```

Existing pre-batch PRs untouched: `#531 docs(audit): SF-051 closure + webhook coverage + Stripe model fix` (worktree owner: another session).

---

## Test plans (per PR body)

- **#532**: iOS+web Profil → Odjava → confirm modal renders, Otkaži keeps session, Odjava signs out
- **#533**: iOS+web login + Remember Me → Odjava → confirm → login screen email field is EMPTY
- **#534**: DevTools elements + Lighthouse a11y no longer flag missing lang
- **#535**: Pixel_8 emulator font_scale=2.0 → all 4 chips visible across 2 lines; HR locale Rezervacije page → "Otkazane" full label

---

## MCP live verification on bookbed-dev (2026-05-28)

Integration branch `smoke/audit-65-integration` (merges of all 4 PR branches at `ba6b2e7c`).
Stack: `flutter run -d web-server --target lib/owner_main_dev.dart --web-port 9333`, chrome-devtools MCP driving real Chrome 148 over CDP.
Test account: `bookbed-test@bookbed.io` ([[test-account]] memory) on bookbed-dev.

| # | Surface | Action | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| FIX 4 | `/login` | `document.documentElement.lang` | `"hr"` | `"hr"` | ✅ |
| FIX 5a | `/owner/overview` @ 360w | "Zadnjih 7/30/90/365 dana" all reachable | 2 chips per row × 2 rows, no clip | confirmed (screenshot fix5-overview-360w.png) | ✅ |
| FIX 5b | `/owner/bookings` @ 360w | "Sve / Na čekanju / Potvrđene / Otkazane / Uvezene" all reachable, no "O…" clip | 5 tabs as 5 full-width rows, "Otkazane" full | confirmed (screenshot fix5-bookings-360w.png) | ✅ |
| FIX 1a | `/owner/profile` | tap Odjava → modal "Jeste li sigurni da se želite odjaviti?" with Odustani + Odjava | modal renders correctly via `role="alertdialog"` | confirmed (snapshot uid=8_0..8_5) | ✅ |
| FIX 1b | dialog Odustani | dialog dismisses, still on /owner/profile, session intact | url unchanged, no modal, snapshot still shows profile tiles | confirmed | ✅ |
| FIX 2 | Odjava → confirm | `localStorage.FlutterSecureStorage.saved_email` cleared, login form email field empty | `saved_email=null`, `remember_me=null`, `firebase:authUser=null`, `<input type=text>.value=""` | confirmed (screenshot fix2-post-logout-login.png) | ✅ |
| — | console errors | 0 errors during full flow | 0 | ✅ |

Pre-logout `localStorage.FlutterSecureStorage.saved_email` held encrypted value `naa+7kcQCFHc6ZlE.FeuLDtBUXETh6gOYK1B79DnlhZT7YI4BcrQKLSPNqC+WYkBmMk6z` — gone after confirmed logout. Same `remember_me` ciphertext gone. Firebase Auth session cookie gone. Full chain (FIX 1 + FIX 2) works end-to-end.

Screenshots: `audit/screenshots-65/` (3 files).

### Follow-up: FIX 5 desktop regression caught + patched (commit `b5332f92`)

After initial MCP smoke at 360w (mobile), broadened to 1280w desktop. `evaluate_script` measurement showed each Rezervacije tab rendered 1208px wide stacked vertically (y-stride 47px) — full-width per row instead of natural horizontal flow. Root cause: `_TabButton`'s `AnimatedContainer(alignment: Alignment.center, ...)`. `Container.alignment` makes the box expand to fill parent constraints. Under the original `ListView.builder horizontal`, each item received tight item constraints so the alignment was a no-op centering. Under `Wrap` (post first FIX 5 commit), children receive loose constraints — the Container grew to the parent column's full width.

Patched on `fix/f-63-04-chip-row-overflow` branch: removed the `alignment: Alignment.center` line. `Row(mainAxisSize: MainAxisSize.min)` already sizes content tightly. Pushed to PR #535.

Re-verified post-patch:
- 1280w: 5 tabs single horizontal row at y=256, x: 36 → 104 → 239 → 368 → 491, widths 60/126/120/115/113 (`fix5-bookings-1280w-postfix.png`)
- 360w: Wrap still works — Sve+Na čekanju+Potvrđene+Otkazane on row 1, Uvezene on row 2, no clip (`fix5-bookings-360w-postfix.png`)

Lesson learned: when refactoring `ListView` → `Wrap`, audit each child for `Container.alignment` / `Expanded` / cross-axis-stretch — these only behave as no-ops inside tightly-constrained list slots, not under Wrap's loose constraints.

### Cross-axis: EN locale + dark mode

After HR-light primary smoke, switched Jezik → English and `chrome-devtools__emulate(colorScheme: dark)`.

| FIX | Surface | Result |
|---|---|---|
| 1 | EN locale logout dialog | "Log out" / "Are you sure you want to log out?" / "Cancel" / "Logout" — both `logoutConfirmTitle` + `logoutConfirmMessage` l10n keys render correctly in EN ✅ |
| 1 | Dark theme dialog visibility | dark card on dark page bg; title + body + buttons readable; primary purple action color preserved (`fix1-dialog-dark-en.png`) ✅ |
| 2 | EN + dark logout | `saved_email/remember_me/firebase:authUser` → null, email field empty ✅ |
| — | console errors during EN + dark flow | 0 ✅ |

Total MCP-verified coverage: HR-light, EN-light, EN-dark; viewport 360w + 1280w; both surfaces (Pregled + Rezervacije); full logout flow (cancel + confirm).

### Pixel_8 mobile emulation + EN locale (closest to audit/62/63 device matrix)

`chrome-devtools__emulate(viewport: "412x915x2.625,mobile,touch", colorScheme: light)` — matches Pixel_8 audit/63 hardware.

| Surface | EN labels | Result |
|---|---|---|
| Pregled chips | "Last 7 days / Last 30 days / Last 90 days / Last 365 days" | 2×2 wrap, no clip (`fix5-pixel8-overview-en.png`) ✅ |
| Rezervacije tabs | "All / Pending / Confirmed / Cancelled / Imported" | 3+2 wrap, "Cancelled" full text (`fix5-pixel8-bookings-en.png`) ✅ |
| Smještajne Jedinice (Unit Hub) | EN | loads, 4 tabs (Basic/Pricing/Widget/Advanced), 0 console errors ✅ |
| Kalendar route | EN | `/owner/calendar` returns 404 page — **pre-existing**, route is collapsible drawer parent without direct path; pre-existing l10n gap: 404 page text is hardcoded HR even when app locale is EN. Out of scope for audit/65. |
| Console errors during entire Pixel_8 EN flow | 0 ✅ |

Drawer entries enumerated on Pixel_8 EN: Overview, Calendar (collapsed), Bookings (1 pending), AI Assistant, Accommodation Units, Integrations (collapsed), FAQ, Notifications (6), Profile. Full navigation tree exercised.

### Lighthouse a11y quantitative (FIX 4 corroboration)

`chrome-devtools__lighthouse_audit(device: desktop, mode: navigation)` on `http://127.0.0.1:9333/`:

| Category | Score |
|---|---|
| **Accessibility** | **100 / 100 ✅** |
| Best Practices | 100 / 100 |
| SEO | 100 / 100 |
| Agentic Browsing | 67 / 100 (only fail: missing `/llms.txt` — unrelated to FIX 4) |

37 audits passed, 1 failed. The single failure (`llms-txt: llms.txt does not follow recommendations`) is in the Agentic Browsing category — an LLM-discoverable docs spec, completely unrelated to FIX 4's `<html lang>` change. Pre-existing. Lighthouse a11y category has zero failures, confirming F-64-04 is resolved.

Report saved: `audit/screenshots-65/report.{json,html}`.
