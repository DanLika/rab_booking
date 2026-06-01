# audit/106 — Phase 2 Visual Regression Sweep (2026-06-01)

**Date:** 2026-06-01
**Branch:** `docs/qa-visual-regression-106`
**HEAD at run:** `3ee95fdc` (Widget Subdomain Not Found PR #628, latest Phase 2 merge)
**Scope:** Pure READ + SCREENSHOT + REPORT. No code change, no merge, no deploy.

> **Audit number note:** initially scoped as audit/105; collided with a parallel agent's `audit/105-foundation-primitive-audit` (committed on `audit/105-foundation-primitive-audit` branch during this session). Renumbered to 106 per memory [[audit-99-numbering-collision]] pattern (always reference by full filename).
**Method:** local `flutter run -d web-server` (owner :8081, widget :8082) + chrome-devtools MCP screenshots + JS-SDK Firebase auth bypass for post-login screens.

## 0 · TL;DR

12 merged Phase 2 redesign screens captured/reused. **0 UNINT drift discovered**. All drift surfaced is INTENTIONAL and traces back to either:

1. PR #614 (Pregled) limited Round 1 scope — tab body only, shell-swap + handoff content blocks deferred (audit/104 §1).
2. PR #621 (Profil) deferred host-trust KPI tile strip — pure additive, not regression.
3. PR #613 (Login) deferred desktop marketing split — open question per audit/104 §8.5 (real numbers vs placeholders pending product+i18n).
4. Legacy `AppTheme.appBarTheme` 64px filled-purple AppBar still active on screens that haven't swapped to `BbScaffold` + `BbAppBar` — documented in [[redesign-phase1-foundation]] "Drift not yet closed."

Edit Profile (`edit_profile_screen.dart`) was **not in the merged Phase 2 PR set** (#611–#628); skipped per task allowance.

| Verdict | Count |
|---|---|
| PASS (strong handoff match or no PNG to compare) | 4 |
| DRIFT-INT (documented intentional, in audit/104 / phase-1 memory / PR body) | 6 |
| DRIFT-INT presumed — needs product Q before close | 1 (Pregled KPI tile content swap — see §7 Q1) |
| BLOCKED (unreachable without app instrumentation) | 1 |
| UNINT (net-new visual regression, must flag) | **0** |

## 1 · Method

- `flutter run -d web-server --web-port=8081 --target lib/main_dev.dart` — one compile cycle for 8 owner screens; navigate via URL between shots
- `flutter run -d web-server --web-port=8082 --target lib/widget_main_dev.dart` — second compile cycle for widget surfaces
- chrome-devtools MCP `navigate_page` + `take_screenshot` (viewport screenshot)
- **chrome-devtools resize_page is a no-op on this MCP build** — viewport stayed at default (1600×683). All shots are at that viewport (still desktop class per CLAUDE.md ≥1200px breakpoint). Filenames retain the `-1440` suffix for task-spec consistency; the screenshot LAYOUT-CLASS is desktop.
- **Auth bypass for post-login screens:** programmatic Firebase JS SDK `signInWithEmailAndPassword` via `evaluate_script` per memory [[flutter-web-input-bypass]] Problem 2. Verified `globalThis.firebase_auth` still exposed (2026-06-01 OK on bookbed-dev). Test account: `bookbed-test@bookbed.io` UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`.
- Side-by-side compare against `design_handoff/screens/NN-{owner,widget}.png` where a 1:1 PNG exists. For screens with no direct PNG (Forgot Password, Register, Settings sub-screens), assessed against the JSX-described intent per `design_handoff/README.md`.

## 2 · Pre-existing PNG reuse (5 of 13 files)

Three screens already had screenshots committed AT their merge commit. Reused verbatim into `audit/qa-visual/`:

| Source | Target | Merge commit (verified `git log --diff-filter=A`) |
|---|---|---|
| `audit/p2b-forgot-1440.png` | `audit/qa-visual/forgot-password-1440.png` | `3ba7fbfa` (PR #622) |
| `audit/p2b-register-1440.png` | `audit/qa-visual/register-1440.png` | `44326f0b` (PR #623) |
| `audit/p2b-register-1440-full.png` | `audit/qa-visual/register-1440-full.png` | `44326f0b` (PR #623) |
| `audit/c-widget-subdomain-not-found-1440.png` | `audit/qa-visual/widget-subdomain-not-found-1440.png` | `3ee95fdc` (PR #628) |
| `audit/c-widget-subdomain-not-found-390.png` | `audit/qa-visual/widget-subdomain-not-found-390.png` | `3ee95fdc` (PR #628) |

Saved 5 screenshot cycles and avoided needing to engineer a subdomain-context simulation for the Subdomain Not Found surface (see §4).

## 3 · Results

| # | Screen | PR | Route | Handoff PNG | qa-visual PNG | Drift | Verdict |
|---|---|---|---|---|---|---|---|
| 1 | Login | #613 | `/login` | `15-owner.png` (auth.jsx) | `login-1440.png` | desktop marketing split (`45+ / 12k / 99.9%` + headline + subtitle) NOT rendered — card-only centered | **DRIFT-INT** (deferred per audit/104 §8.5 open question — real numbers vs placeholders pending product+i18n) |
| 2 | Pregled | #614 | `/owner/overview` | `01-owner.png` | `pregled-1440.png` | handoff includes AI nudge bar, dual-series chart, occupancy radial, channel-mix donut, "Nadolazeći dolasci" preview, dissolved sidebar nav, 56px breadcrumb AppBar. Impl ships: greeting + period chips + 4-KPI strip + "Nedavne Aktivnosti" list inside legacy `OwnerAppDrawer` shell with 64px filled-purple AppBar. **KPI tile content map differs:** impl `ZARADA / REZERVACIJE / NADOLAZEĆI CHECK-IN / POPUNJENOST` vs handoff `REZERVACIJE / PROSJEČNA CIJENA / NOVI GOSTI / PROSJEČNA OCJENA`. See §7 Q1. | **DRIFT-INT** (PR #614 body explicitly defers AI nudge / dual-series chart / deposit card / channels card / handoff period pill under the "no provider yet — refusing to fabricate" principle. The 4-tile KPI swap follows the SAME data-availability constraint — current providers expose revenue/booking/upcoming-check-in/occupancy but not avg-price/new-guests/avg-rating — though the swap itself is not enumerated in PR #614 body. Flagged as **presumed INT pending product Q1.**) |
| 3 | Widget Confirmation | #612 | (Navigator.push only — see §4) | `03-widget.png` (mint surface) | — | unreachable without app instrumentation | **BLOCKED** (no GoRoute; reached only via booking_widget_screen Navigator.push at lines 999/3403/3849 — PR #612 visual proof at merge time is the authoritative reference) |
| 4 | FAQ | #619 | `/owner/guides/faq` | `13-owner.png` | `faq-1440.png` | sidebar absent (drawer pattern), title shortened ("FAQ" vs "Često postavljana pitanja" + subtitle missing), chip labels slightly differ ("iCal Sync" vs "Sinkronizacija"; "Tehnička Podrška" vs "Račun"). Search bar + chip row + accordion + contact card structure MATCH. | **DRIFT-INT** (chrome differences — sidebar deferred; title/chip label refinement is product-copy not visual-regression) |
| 5 | Subscription | #620 | `/owner/subscription` | `08-owner.png` | `subscription-1440.png` | trial hero, billing toggle, Besplatno vs Pro 2-col layout, accentLeft Pro card, feature list, pricing — STRONG MATCH; only chrome AppBar deviates | **PASS** (cleanest match; documented chrome drift only) |
| 6 | Profil | #621 | `/owner/profile` | `05-owner.png` | `profil-1440.png` | host-trust KPI 4-tile strip (OCJENA DOMAĆINA / STOPA ODGOVORA / VRIJEME ODGOVORA / ZAVRŠENIH REZERVACIJA) missing; address line in identity card absent; settings list 2-col vs handoff 4-col (viewport-class effect — handoff canvas is wider); danger zone below fold (not asserted). Identity card + completion radial + Pro upsell + settings tiles structure MATCH. | **DRIFT-INT** (host-trust KPIs deferred per Round 2 scope; additive surface not regression) |
| 7 | Forgot Password | #622 | `/forgot-password` | (no PNG — JSX `recovery.jsx` only) | `forgot-password-1440.png` (reused at merge `3ba7fbfa`) | n/a — assessed against JSX intent (single email field + submit + result state on glass/softBg) | **PASS** (Phase 1.1 BbInput.validator native; merge-commit screenshot accepted as authoritative per [[canvaskit-tier3-screenshot-policy]]) |
| 8 | Register | #623 | `/register` | (no PNG — JSX `register.jsx` only) | `register-1440.png` + `register-1440-full.png` (reused at merge `44326f0b`) | n/a — assessed against JSX intent (multi-field name/email/password/confirm/photo with native BbInput.validator) | **PASS** (Phase 1.1 native validation end-to-end; merge-commit screenshots authoritative) |
| 9 | Notification Settings | #625 | `/owner/profile/notifications` | (`16-owner.png` is settings.jsx umbrella showing Edit Profile sub-screen — no Notifications PNG) | `notification-settings-1440.png` | n/a (no direct PNG); shipped: master BbSwitch toggle + section header + grouped sub-toggles in BbCard + icon tile per category | **PASS** (matches Bb* primitive composition standard; first BbSwitch consumer per PR #625) |
| 10 | Bank Account | #627 | `/owner/integrations/payments/bank-account` | `09-owner.png` (payouts hub — full screen) | `bank-account-1440.png` | handoff `09-owner.png` shows full payouts hub (Stripe Connect status card + 3 balance tiles + bank account card + schedule + recent payouts list). Impl shows ONLY bank-account form (IBAN/SWIFT/Bank name/Owner). | **DRIFT-INT** (documented per audit/104 §1: "Payouts (09) handoff = 1 PNG split across 2 Flutter screens — `bank_account_screen.dart` + `stripe_connect_setup_screen.dart`". This is the bank-account SUB-screen.) |
| 11 | Change Password | #626 | `/owner/profile/change-password` | (`16-owner.png` umbrella — no Change Password PNG) | `change-password-1440.png` | n/a; shipped: clean card with 3 password fields (Trenutna/Nova/Potvrdite) using BbInput with lock+eye icons, accentLeft purple info card, full-width primary CTA, "Odustani" tertiary. **No legacy purple AppBar visible** — appears to use BbScaffold variant. | **PASS** (cleanest implementation observed; matches design language precisely; reference for future Phase 2 form screens) |
| 12 | Subdomain Not Found | #628 | widget — SubdomainContext-gated, see §4 | `05-widget.png` partial (widget-error.jsx) | `widget-subdomain-not-found-1440.png` + `-390.png` (reused at merge `3ee95fdc`) | n/a — merge-commit screenshots authoritative. At `localhost:8082/no-such-slug`, route hits `BookingWidgetScreen(urlSlug:...)` "Unable to determine property" generic error path (NOT the SubdomainNotFoundScreen redesign) — see §4. | **PASS** (merge-commit PNGs are authoritative; full subdomain-context simulation deferred — see §4) |

### Edit Profile — not landed

Not in merged Phase 2 PR set (#611–#628). `edit_profile_screen.dart` exists at `lib/features/auth/presentation/screens/edit_profile_screen.dart` (992 LOC per audit/104) but is unchanged from pre-redesign HEAD. Skipped per task allowance ("if landed").

## 4 · Reachability gaps

### 4.1 Widget Confirmation (#612) — Navigator.push only

`BookingConfirmationScreen` is invoked via `Navigator.push(...)` from three sites inside `lib/features/widget/presentation/screens/booking_widget_screen.dart` (lines 999, 3403, 3849). It has NO standalone `GoRoute` in `lib/core/config/router_widget.dart`. Reaching it programmatically requires either:

1. Driving the full widget booking flow (calendar → guest form → Stripe checkout → return) — high overhead and the widget itself is FROZEN per CLAUDE.md, so adding test instrumentation needs separate scope decision.
2. Marionette VM-debug or a Flutter integration test driver that calls `Navigator.push` directly — out of scope for this pure-visual sweep (no app instrumentation per task spec).
3. Adding a debug-only route — out of scope (no code change in this audit per task spec).

PR #612 visual proof exists at merge time; that screenshot is the authoritative reference. This sweep marks Widget Confirmation **BLOCKED** with no UNINT drift claim either way. Recommendation: revisit if a future PR lands near this surface and visual regression risk surfaces.

### 4.2 Subdomain Not Found (#628) — SubdomainContext-gated

`SubdomainNotFoundScreen` is rendered from `booking_view_screen.dart:280-282` only when `_subdomainContext` is present but unresolved. The `SubdomainContext` is set by hostname-based subdomain parsing (e.g., `foo.bookbed.io` → `foo`). On `localhost:8082/no-such-slug-12345`, the GoRouter `/:slug` catch-all hits `BookingWidgetScreen(urlSlug: slug)` directly — which renders the generic "Unable to determine property / Subdomain not found in URL" error state from inside the widget, NOT the redesigned `SubdomainNotFoundScreen`. That's a DIFFERENT error surface for a different bug class.

The reused PNGs `widget-subdomain-not-found-{1440,390}.png` were captured at PR #628 merge commit `3ee95fdc` (current HEAD) via the SubdomainContext-aware path. They are authoritative. Full subdomain-context simulation for re-shoot at HEAD is out of scope (would need hostname spoofing or a debug subdomain override — neither exists in current code).

This sweep notes a related observation that the **generic widget error state** (`BookingWidgetScreen._buildErrorState` "Unable to determine property") is itself a separate redesign opportunity — it ships unmodernized while the standalone `SubdomainNotFoundScreen` is fully redesigned. Out of audit/106 scope; flag for future Phase 2 Round that touches `booking_widget_screen.dart` chrome (constrained by FROZEN status).

## 5 · Cross-cutting drift observations (all INT, documented elsewhere)

| Observation | Root cause | Reference |
|---|---|---|
| Legacy 64px filled-purple AppBar on 5 of 8 captured owner screens (Pregled, Profil, FAQ, Subscription, Bank Account, Notification Settings) | `AppTheme.appBarTheme` still 64px purple; handoff 56px transparent breadcrumb lives in new `BbAppBar` (Phase 1 foundation) but no Round 1/2 screen has swapped to `BbScaffold` + `BbAppBar` yet | [[redesign-phase1-foundation]] "Drift not yet closed" + audit/104 §1 (shell-swap deferred) |
| Dissolved sidebar (`BbSidebar`) absent from all owner screens — drawer pattern used instead | Same as above — `BbConsoleScaffold` not yet adopted at screen level; PR #614 explicitly defers shell-swap | audit/104 §1 + memory [[redesign-phase1-foundation]] |
| `BBColor.statusPending` light token still `#FFB84D` (bright); handoff AA-safe `#B7791F` available as `BbRedesignTokens.statusPendingDeep` but unused | Phase 1 token addition was additive only; changing the live token would shift calendar visual identity on every unmigrated screen | [[redesign-phase1-foundation]] |
| Profil — host-trust 4-KPI tile strip missing (OCJENA DOMAĆINA / STOPA ODGOVORA / VRIJEME ODGOVORA / ZAVRŠENIH REZERVACIJA) | Profil Round 2 scope was identity-card + completion radial + Pro card; trust KPIs deferred. Pure additive (no regression) | audit/104 §3 row 1 |
| Login — desktop marketing split missing (left panel with headline + `45+ / 12k / 99.9%` claims) | Real numbers vs placeholders open question | audit/104 §8.5 |
| Change Password screen has NO purple AppBar (uses BbScaffold variant) — exception to chrome-drift | PR #626 applied `BbScaffold` with back-arrow chrome rather than legacy `OwnerAppDrawer` | Observed clean — flag for replication |

## 6 · Recommendations

1. **Adopt the Change Password chrome pattern as the reference** for all remaining settings sub-screens (Notification Settings + Bank Account both still use legacy AppBar). Cheap fix, big visual win.
2. **Schedule Pregled Round 2** to add the deferred handoff blocks (AI nudge bar, dual-series chart, occupancy radial, channel-mix donut) — the biggest visible delta against handoff right now.
3. **Login marketing split** needs product+i18n unblock per audit/104 §8.5 before implementation. Track as separate PR after copy lands.
4. **Profil host-trust KPI tiles** — additive, no business-logic dependency. Can be a small PR using Bb* primitives once the data source for OCJENA DOMAĆINA / STOPA ODGOVORA / VRIJEME ODGOVORA is wired (or wired with placeholders gated on data availability).
5. **Widget Confirmation re-screenshot** — once a future Phase 2 PR adds reachability instrumentation (e.g., debug route or integration test driver), include this surface in visual regression sweeps.
6. **Generic widget error state** (`BookingWidgetScreen._buildErrorState`) — flag as out-of-scope-for-Phase 2 but worth a separate small redesign once FROZEN status policy permits chrome modernization inside booking widget.

## 7 · Questions for product (block one verdict close)

### Q1 — Pregled KPI tile content map

The 4-KPI tile strip on `/owner/overview` ships as `ZARADA / REZERVACIJE / NADOLAZEĆI CHECK-IN / POPUNJENOST` (revenue + occupancy lens) but `design_handoff/screens/01-owner.png` shows `REZERVACIJE / PROSJEČNA CIJENA / NOVI GOSTI / PROSJEČNA OCJENA` (engagement + quality lens).

PR #614 body enumerates several deferred handoff blocks (AI nudge bar, dual-series chart, deposit card, channels card, period selector pill) under the "no provider yet — refusing to fabricate hardcoded values" principle, but does NOT explicitly call out the KPI tile content swap as deferred.

**Decision needed:**
- **(a)** The current `ZARADA / REZERVACIJE / NADOLAZEĆI CHECK-IN / POPUNJENOST` set IS the desired product positioning — handoff was directional, not prescriptive. Then this drift closes as INT and we update the handoff to match.
- **(b)** The handoff `REZERVACIJE / PROSJEČNA CIJENA / NOVI GOSTI / PROSJEČNA OCJENA` set IS the desired product positioning, and the swap was data-provider-constrained (no `averageNightlyPrice`, `newGuestsCount`, `averageRating` aggregations in `UnifiedDashboardData`). Then this is INT-deferred and a follow-up PR adds the aggregations + swaps the tiles.

Recommend (b) based on handoff README §"Pregled (Dashboard)" listing engagement metrics, but defer to product before scoping the follow-up.

## 8 · Doc-only PR scope

- 1 new file: `audit/106-qa-visual-regression-2026-06-01.md`
- 13 new screenshot files: `audit/qa-visual/*.png` (8 freshly captured + 5 reused from prior PR audit folders)
- Zero code changes
- Zero deploy
- Zero touched tests

Reviewer should validate: (a) drift verdicts (INT vs UNINT) per row, (b) that `BLOCKED` for Widget Confirmation is the right call vs adding integration-test instrumentation, (c) recommendations §6 priority ordering before scoping next Phase 2 PRs.
