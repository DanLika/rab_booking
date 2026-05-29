# audit/77 — Visual QA sweep + auto-fix batch

**Date:** 2026-05-29
**Branch:** `ops/visual-qa-sweep`
**Scope:** Owner + Widget + Admin (DEV stack only), `bookbed-dev` project, Chrome 148 over chrome-devtools MCP, no PROD touches, no Firebase deploys, no rules/schema edits.
**Verifier credentials:** `bookbed-test@bookbed.io` / `BookBedTest2026!` (per `[[test-account]]`).
**Test data:** `SEED_test_owner_property_01` / `SEED_test_owner_unit_01`.

> **Mode**: fully autonomous time-boxed run (~90 min). Subsamples viewports to 1440 light + 390 dark + a widget 320 / dark sample to fit budget. Owner sweep ran ahead of widget and admin; admin sweep limited to public surface (test account lacks admin claim — admin custom-claim provisioning is out of scope, see `audit/37`).

## 1. Execution summary

| Phase | Result |
|---|---|
| Static sweep (Playfair refs / hex-literal census / l10n locale tag check) | ✅ no actual Playfair font regression (post-#545 stays clean — only doc/comment matches) |
| Owner sweep — 20 routes, viewport 1440 + sample 390 light + 390 dark | ✅ 0 console errors, 3 surface bugs |
| Widget sweep — 1440 + 320, EN + HR locale probes | ✅ 0 console errors, 1 product-policy note |
| Admin sweep — login surface only (no admin claim on test account) | ✅ login renders clean dark |
| Auto-fix — 2 mechanical commits | ✅ landed on `ops/visual-qa-sweep` |
| Verification — `flutter analyze` + `flutter test` | ✅ analyze: 94 pre-existing infos (deprecated_member_use, not new); test: 1205/1205 |

## 2. Findings — FIXED IN-BRANCH

### F-77-01 — Pretplata badges shipped in English **(P2)** — FIXED
**Surface:** `/owner/subscription` (web)
**Symptom:** `Current` and `RECOMMENDED` badges on the Free Trial + Pro plan cards render in English to HR users.
**Root cause:** `lib/features/subscription/screens/subscription_screen.dart:237` + `:256` — both badge labels hardcoded as `Text('Current', …)` / `Text('RECOMMENDED', …)` even though the surrounding screen already pulls `AppLocalizations`.
**Fix:** added `subscriptionBadgeCurrent` (EN `Current`, HR `Trenutni`) + `subscriptionBadgeRecommended` (EN `RECOMMENDED`, HR `PREPORUČENO`) keys to both `arb` files; regenerated `app_localizations_*.dart`; threaded `l10n` through `_buildPlanCard` and replaced both `Text()` calls.
**Commit:** `799c9d3a`
**Screenshots:** before — `audit/screenshots-77/15-subscription-1440-light.png`.

### F-77-02 — Calendar timeline toolbar month label is English **(P3)** — FIXED
**Surface:** `/owner/calendar/timeline` (web). Mirrors `[[dateformat-static-locale-trap]]` family — but the trap here was even bluntier: a hardcoded EN month-name table.
**Symptom:** Toolbar date-picker chip reads `Jun 2026` (EN abbreviation) while the date header beneath the same toolbar correctly reads `lipnja 2026` (HR full month). Both fed by the same DateTime, but two different code paths.
**Root cause:** `lib/features/owner_dashboard/domain/models/date_range_selection.dart:165` — `_getMonthName(int)` is a hardcoded `['Jan', 'Feb', …]` table called by `toDisplayString()`. The body's `timeline_date_header.dart:72` already uses `DateFormat('MMMM yyyy', Localizations.localeOf(context).languageCode)` — so the body was correct and the toolbar was not.
**Fix:** `toDisplayString` now takes a `String? locale` parameter and uses `DateFormat('MMM', locale)` / `DateFormat('MMMM', locale)`. Toolbar (single caller in repo) passes `Localizations.localeOf(context).languageCode`. Dead `_getMonthName` table removed.
**Commit:** `06b383c8`
**Screenshots:** before — `audit/screenshots-77/04-timeline-1440-light.png` ("Jun 2026" pill).

## 3. Findings — DOCUMENTED (not fixed)

### F-77-03 — `/owner/widget-settings` is a dead route constant **(P3)** — DOCUMENTED
**Surface:** drawer / direct URL `http://app/owner/widget-settings`.
**Symptom:** Lands on the 404 page (`Stranica nije pronađena`).
**Root cause:** `lib/core/config/router_owner.dart:102` declares `static const String widgetSettings = '/owner/widget-settings';` BUT no `GoRoute` registers a handler for that path. Only `unitWidgetSettings` (`/owner/units/:id/widget-settings`) has a handler. `OwnerRoutes.widgetSettings` is referenced nowhere else in `lib/` — pure dead constant.
**Why not fixed here:** either (a) the constant should be removed (true dead code) or (b) the screen genuinely needs a global widget-settings entry that lists units and forwards to `unitWidgetSettings(:id)` — that's a UX decision, not a one-file mechanical fix.
**Recommendation:** delete the constant in a hygiene pass, or build a global-widget-settings index screen if there's product demand. Not blocker.
**Screenshots:** `audit/screenshots-77/17-widget-settings-1440-light.png`.

### F-77-04 — Widget defaults to English even when `?locale=hr` set **(P3, product-policy)** — DOCUMENTED
**Surface:** `view.bookbed.io/?property=…&unit=…[&locale=hr]`.
**Symptom:** With `?locale=hr` in the query string, calendar still renders `MON / TUE / WED / …` weekdays + `Month` / `Year` view toggles + `Min. stay: 1 night` infobar (EN).
**Root cause:** widget bootstrap does not parse `locale=` from `Uri.base.queryParameters`. Locale is browser-detected, with an in-widget flag dropdown as the user-facing override.
**Why not fixed here:** widget locale handling is a product decision — does the owner want hard-coded HR per their booking page (`?locale=hr`) or polite browser detection? Adding the param would also need integration into the widget owner-side preset. Out of scope.
**Recommendation:** discuss owner-controlled `embedConfig.defaultLocale` route through `widget_settings` collection; align with widget docs.

### F-77-05 — `/owner/widget-settings` route mismatch is reachable from external links **(P3, informational)** — DOCUMENTED
Same surface as F-77-03 but called out separately because it directly affects the embed-guide flow. The embed guide screen renders correctly (`audit/screenshots-77/16-embed-1440-light.png`); the gap is just the standalone global page that doesn't exist.

## 4. Findings — RULED OUT during sweep

- **Playfair font regression** (post-#545 mandate) — `grep -ril "playfair"` returns 2 matches, both are doc-strings / probe-screen comments. No actual `GoogleFonts.playfairDisplay()` or `fontFamily: 'PlayfairDisplay'` call site.
- **Hardcoded color leak in admin shell** (`Color(0xFFF8F9FA)` / `0xFF1E1E2E` / `0xFF161621`) — left in place: matches CLAUDE.md "NE refaktoriraj postojeće call sites in-place — bulk codemod je zaseban PR".
- **Console error catalog** — `list_console_messages` returned 0 error/warn entries across all owner screens visited and the admin login screen. The owner web bundle is quiet on `bookbed-dev`.

## 5. Screenshot inventory

| # | Surface | Viewport | Theme | Locale | Path |
|---|---|---|---|---|---|
| 01 | login | 1440 | light | hr | screenshots-77/01-login-1440-light.png |
| 02 | overview | 1440 | light | hr | screenshots-77/02-overview-1440-light.png |
| 03 | bookings | 1440 | light | hr | screenshots-77/03-bookings-1440-light.png |
| 04 | calendar/timeline | 1440 | light | hr | screenshots-77/04-timeline-1440-light.png |
| 05 | calendar/month | 1440 | light | hr | screenshots-77/05-month-1440-light.png |
| 06 | unit-hub | 1440 | light | hr | screenshots-77/06-unithub-1440-light.png |
| 07 | profile | 1440 | light | hr | screenshots-77/07-profile-1440-light.png |
| 08 | notifications | 1440 | light | hr | screenshots-77/08-notifications-1440-light.png |
| 09 | guides/faq | 1440 | light | hr | screenshots-77/09-faq-1440-light.png |
| 10 | ai-assistant | 1440 | light | hr | screenshots-77/10-ai-1440-light.png |
| 11 | ical/import | 1440 | light | hr | screenshots-77/11-ical-import-1440-light.png |
| 12 | ical/export-list | 1440 | light | hr | screenshots-77/12-ical-export-1440-light.png |
| 13 | bank-account | 1440 | light | hr | screenshots-77/13-bank-1440-light.png |
| 14 | integrations/stripe | 1440 | light | hr | screenshots-77/14-stripe-1440-light.png |
| 15 | subscription | 1440 | light | hr | screenshots-77/15-subscription-1440-light.png |
| 16 | guides/embed-widget | 1440 | light | hr | screenshots-77/16-embed-1440-light.png |
| 17 | widget-settings (404) | 1440 | light | hr | screenshots-77/17-widget-settings-1440-light.png |
| 18 | profile/edit | 1440 | light | hr | screenshots-77/18-profile-edit-1440-light.png |
| 19 | profile/change-password | 1440 | light | hr | screenshots-77/19-pw-1440-light.png |
| 20 | profile/notifications | 1440 | light | hr | screenshots-77/20-notif-settings-1440-light.png |
| 21 | overview mobile | 390 | light | hr | screenshots-77/21-overview-390-light.png |
| 22 | overview mobile dark | 390 | dark | hr | screenshots-77/22-overview-390-dark.png |
| 30 | widget | 1440 | light | en (browser) | screenshots-77/30-widget-1440-light.png |
| 31 | widget `?locale=hr` | 1440 | light | en (override ignored) | screenshots-77/31-widget-1440-hr.png |
| 32 | widget mobile | 320 | light | en | screenshots-77/32-widget-320-light.png |
| 40 | admin login | 1440 | light | hr | screenshots-77/40-admin-login-1440-light.png |

## 6. Verification

**`flutter analyze` (post-fix):**
- 94 issues found, all `info` severity
- 0 `error`, 0 `warning`
- All infos are pre-existing `deprecated_member_use_from_same_package` from the `BB*` token migration — same set that was there pre-branch (audit/74 line: "design tokens transition")

**`flutter test`:** `All tests passed!` — `+1205` final pass count, matches the pre-branch baseline.

**Branch guard:** verified via `git -C /tmp/bb-vqa-wt symbolic-ref --short HEAD | grep -qx ops/visual-qa-sweep` before each commit; no foreign-branch writes.

## 7. Out-of-scope but observed

These would each be their own PR (or feed the Tier 2 redesign chain):

1. **Bookings list "Email" column wrap** at 1440 is awkward but not broken — guest email wraps to 2 lines when the email is long, while the row still aligns. Would benefit from `text-overflow: ellipsis` or a guest-email-tooltip pattern. Already in design-audit `audit/71` territory.
2. **Drawer-state observability** — owner shell uses an end-drawer + a desktop-only sidebar variant per the global user preference (`F8F9FA → light-gray gradient` from CLAUDE.md global instructions). Desktop sidebar was not visually verified in this sweep because the test screens didn't trigger the desktop variant on first paint. Worth a paragraph in the design-audit follow-up.
3. **Drawer + bell + dashboard badge count drift** confirmed in `[[ipwhois-app-pii-leak-on-login]]`'s sibling notes (`audit/58c F-58c-20`) — saw similar dashboard 9/9 vs bell, did not re-verify here. Leaving to that audit's owner.
4. **`Color(0xFFF8F9FA)` in `admin_shell_screen.dart:63` light surface** — user's global preference (CLAUDE.md) says to replace `#F8F9FA` with a light-gray nuance everywhere. Admin shell is a candidate, but admin redesign is a separate chain (`audit/37`). Documented here so the admin redesign PR can pick it up.

## 8. Commit log on this branch

```
06b383c8 fix(calendar): localize toolbar month label (audit/77 F-77-02)
799c9d3a fix(l10n): localize Pretplata "Current" + "RECOMMENDED" badges (audit/77 F-77-01)
```

## 9. Memory deltas

None worth saving — both fixes are mechanical, root causes captured in this doc and the commit messages. The `[[dateformat-static-locale-trap]]` memory already covered the class.
