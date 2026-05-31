# audit/104 — Phase 2 screen inventory + readiness map

**Date:** 2026-05-31
**Branch:** `docs/phase2-screen-readiness`
**Scope:** PURE READ. No code change, no test, no deploy. Inventory + classification only.
**Predecessors:** audit/103 (Phase 1 foundation), PRs #611/#614/#615/#613/#612 merged.

## 0 · TL;DR

- 29 handoff screens (16 owner / 8 admin / 5 widget). 3 ✅ DONE Round 1 (Login / Pregled / WidgetConfirmation). 21 MATCHED to existing Flutter files. 5 NO-MATCH (4 admin + 1 partial widget). 4 FROZEN or FROZEN-ADJACENT (Units / Timeline / Wizard / Booking Widget) — solo PRs, deferred.
- **Phase 1.1 BbInput.validator status:** NOT YET MERGED (agent in-flight). 8 form-bearing screens hold for it.
- **Round 2 recommendation (top 5, pure composition, zero-overlap, non-FROZEN):** Profile (05) → FAQ (13) → Subscription (08) → Calendar Month (04) → Forgot Password (recovery, after Phase 1.1).
- **Admin dark-theme first pick:** admin-auth.jsx → `admin_login_screen.dart` (461 LOC, Form, no FROZEN) — smallest + validates dark BbInput / BbButton + introduces AdminScaffold dark variant.
- **NO-MATCH admin screens (need net-new Flutter files in Round 3+):** admin-bookings, admin-payments, admin-sync, admin-support. `activity_log_screen.dart` (279 LOC) may partially cover admin-sync — verify before scoping.

---

## 1 · Inventory table — all 29 handoff screens

Legend: ✅ DONE (Round 1 merged) · 🟢 MATCHED (file exists) · 🔴 NO-MATCH (no Flutter file) · 🧊 FROZEN-ADJACENT (FROZEN region inside) · `Form` = `_formKey` / `TextFormField` / `validate` present.

### Owner (16 screens)

| # | Handoff PNG | JSX module | Flutter file | Status | LOC | Form | FROZEN | Parent shell | Notes |
|---|---|---|---|---|---|---|---|---|---|
| 01 | `01-owner.png` | `pregled-premium.jsx` | `lib/features/owner_dashboard/presentation/screens/dashboard_overview_tab.dart` | ✅ DONE | (PR #614) | n | n | shared (drawer) | tab body only refactored; shell-swap deferred |
| 02 | `02-owner.png` | `rezervacije-premium.jsx` | `…/owner_bookings_screen.dart` | 🟢 | 2162 | n | n | shared (drawer) | big — KPI strip + AI nudge + pending queue + ledger table |
| 03 | `03-owner.png` | `calendar-premium.jsx` + `calendar-timeline.jsx` | `…/owner_timeline_calendar_screen.dart` | 🟢🧊 | 791 | n | n@screen | shared (drawer) | screen itself doesn't import timeline_dimensions; chrome migratable, geometry-widgets inside FROZEN |
| 04 | `04-owner.png` | `calendar-month.jsx` | `…/calendar/month_calendar_screen.dart` | 🟢 | 1022 | n | n | shared (drawer) | month grid + Google-Calendar spanning bars |
| 05 | `05-owner.png` | `profile-premium.jsx` | `…/profile_screen.dart` | 🟢 | 864 | n | n | shared (drawer) | identity card + completion radial + host-trust KPIs |
| 06 | `06-owner.png` | `units.jsx` | `…/unified_unit_hub_screen.dart` | 🟢🧊 | 1786 | n | **Y** | shared (drawer) | imports `unit_pricing_screen` (Cjenovnik FROZEN) — chrome migratable, Cjenovnik tab untouched |
| 07 | `07-owner.png` | `booking-detail.jsx` | `lib/features/widget/presentation/screens/booking_details_screen.dart` (widget side) — owner-side may be a dialog | 🟢 | 622 | n | n | standalone | check whether owner sees this as full screen or dialog; widget file may not be the right target |
| 08 | `08-owner.png` | `subscription.jsx` | `lib/features/subscription/screens/subscription_screen.dart` | 🟢 | 519 | n | n | **own Scaffold** (not under owner_dashboard) | trial hero + Besplatno vs Pro comparison |
| 09 | `09-owner.png` | `payouts.jsx` | `…/bank_account_screen.dart` + `…/stripe_connect_setup_screen.dart` | 🟢 (2 files) | 474 + 1018 | Y / n | n | shared (drawer) | 2 Flutter screens for 1 handoff screen; bank account has form |
| 10 | `10-owner.png` | `ical.jsx` | `…/ical/ical_sync_settings_screen.dart` | 🟢 | 1998 | Y | n | shared (drawer) | very large — feed list + OTA logos + status + error states; form-bearing |
| 11 | `11-owner.png` | `ai-assistant.jsx` | `…/guides/ai_assistant_screen.dart` | 🟢 | 1166 | n | n | shared (drawer) | S=4 D=8 unusual: embeds multiple sub-Scaffolds (chat surface) |
| 12 | `12-owner.png` | `notifications.jsx` | `…/notifications_screen.dart` | 🟢 | 1203 | n | n | shared (drawer) | typed icons + inline actions + mark-all-read |
| 13 | `13-owner.png` | `faq.jsx` | `…/guides/faq_screen.dart` | 🟢 | 477 | n | n | shared (drawer) | search + category chips + accordion + contact card |
| 14 | `14-owner.png` | `embed.jsx` | `…/guides/embed_widget_guide_screen.dart` | 🟢 | 1781 | n | n | shared (drawer) | copyable snippet + mint preview + install steps |
| 15 | `15-owner.png` | `auth.jsx` | `…/enhanced_login_screen.dart` | ✅ DONE | (PR #613) | Y | n | own (auth flow) | glass + softBg per #615 fixup |
| 16 | `16-owner.png` | `settings.jsx` (umbrella) | `…/edit_profile_screen.dart` + `…/change_password_screen.dart` + `…/notification_settings_screen.dart` | 🟢 (3 files) | 992 + 641 + 650 | Y / Y / n | n | shared (drawer) | "settings" handoff = 3 owner-side sub-screens |

### Owner — extras (JSX modules in handoff README without separate PNG)

| Handoff doc ref | JSX | Flutter file | Status | LOC | Form | FROZEN | Notes |
|---|---|---|---|---|---|---|---|
| Registracija | `register.jsx` | `…/enhanced_register_screen.dart` | 🟢 | 674 | Y | n | sibling of Login |
| Oporavak računa | `recovery.jsx` | `…/forgot_password_screen.dart` | 🟢 | 318 | Y | n | TINY — best Phase 1.1 validation candidate |
| Legal | `legal.jsx` | `…/privacy_policy_screen.dart` + `…/terms_conditions_screen.dart` | 🟢 (2 files) | 527 + 526 | n / n | n | static-content pair |
| Unit Wizard | `wizard.jsx` | `…/unit_wizard/unit_wizard_screen.dart` | 🟢🧊 | 496 | n | **Y** | Step 4 publish FROZEN; other steps migratable |
| Booking create/edit dialogs | `dialogs.jsx`, `dialogs-misc.jsx`, `filters-dialog.jsx` | (dialogs, not screens) | — | — | — | — | not standalone screens; address inside their hosting screens |

### Widget (5 screens)

| # | Handoff PNG | JSX module | Flutter file | Status | LOC | Form | FROZEN | Notes |
|---|---|---|---|---|---|---|---|---|
| 01 | `01-widget.png` | `widget-calendar.jsx` | `…/booking_widget_screen.dart` | 🟢🧊 | 4143 | Y | **Y** | whole booking widget is FROZEN per CLAUDE.md (4143 LOC includes calendar + guest-form + pricing inline) |
| 02 | `02-widget.png` | `widget-guest-form.jsx` | embedded in `booking_widget_screen.dart` | 🧊 | — | Y | **Y** | not a standalone screen |
| 03 | `03-widget.png` | `widget-confirmation.jsx` | `…/booking_confirmation_screen.dart` | ✅ DONE | (PR #612) | n | n | mint surface validated |
| 04 | `04-widget.png` | `widget-pricing.jsx` | embedded in `booking_widget_screen.dart` (`booking_view_screen.dart` 380 LOC may be price-display variant) | 🧊 | — | n | **Y** | not standalone |
| 05 | `05-widget.png` | `widget-error.jsx` | `…/subdomain_not_found_screen.dart` (partial) | 🟢 partial | 152 | n | n | only covers subdomain-not-found; other widget error states are inline in `booking_widget_screen.dart` (FROZEN) |

### Admin (8 screens)

| # | Handoff PNG | JSX module | Flutter file | Status | LOC | Form | FROZEN | Notes |
|---|---|---|---|---|---|---|---|---|
| 01 | `01-admin.png` | `admin-auth.jsx` | `…/admin/presentation/screens/admin_login_screen.dart` | 🟢 | 461 | Y | n | smallest admin; great dark-theme first pick |
| 02 | `02-admin.png` | `admin-shell.jsx` (Overview) | `…/admin_shell_screen.dart` + `…/admin_dashboard_screen.dart` | 🟢 (2 files) | 419 + 556 | n | n | shell + overview body — like owner Pregled split |
| 03 | `03-admin.png` | `admin-viz.jsx` (Analytics) | `…/admin_dashboard_screen.dart` (overlap with admin-shell?) OR net-new tab | 🟢 partial | 556 | n | n | verify whether analytics lives inside dashboard tab or needs new file |
| 04 | `04-admin.png` | `admin-users.jsx` (Owners) | `…/users_list_screen.dart` + `…/user_detail_screen.dart` | 🟢 (2 files) | 740 + 1047 | n | n | list + detail pair |
| 05 | `05-admin.png` | `admin-bookings.jsx` | **(none)** | 🔴 NO-MATCH | — | — | — | needs net-new Flutter screen |
| 06 | `06-admin.png` | `admin-payments.jsx` | **(none)** | 🔴 NO-MATCH | — | — | — | needs net-new |
| 07 | `07-admin.png` | `admin-sync.jsx` (Sync health) | `…/activity_log_screen.dart` (279 LOC may partially cover) | 🔴 partial / NO-MATCH | (279) | n | n | activity_log is generic event log; sync-health is OTA feed status — likely needs net-new |
| 08 | `08-admin.png` | `admin-support.jsx` | **(none)** | 🔴 NO-MATCH | — | — | — | net-new; intentional HR thread per handoff README |

---

## 2 · Phase 1.1 BbInput.validator status

**main HEAD = `5ab91fc1`** (Round 1 PRs all merged). **Phase 1.1 NOT YET MERGED** — verified by `grep -E 'validator|FormFieldValidator' lib/shared/widgets/redesign/bb_input.dart` returns no matches on `main`. Agent is in-flight (background); Phase 1.1 PR (`foundation/phase-1.1-bbinput-validator`) hasn't landed yet.

### Form-bearing screens blocked until Phase 1.1 lands

These 8 screens have `_formKey` / `TextFormField` / `validate` — refactoring them onto `BbInput` today requires per-screen `FormField<String>` wraps (Login PR #613 pattern). Wait for Phase 1.1 to land first to avoid replicating the workaround:

1. `enhanced_register_screen.dart` (674)
2. `forgot_password_screen.dart` (318)
3. `change_password_screen.dart` (641)
4. `edit_profile_screen.dart` (992)
5. `bank_account_screen.dart` (474)
6. `ical_sync_settings_screen.dart` (1998)
7. `admin_login_screen.dart` (461)
8. `booking_widget_screen.dart` (4143) — FROZEN anyway

---

## 3 · Round 2 recommendation — 5 screens, ranked by visible-win × low-risk

All picks: pure composition, zero file overlap, non-FROZEN, can run in parallel terminals.

| Rank | Screen | Flutter file | LOC | Why | Risk |
|---|---|---|---|---|---|
| **1** | Profil (05) | `…/profile_screen.dart` | 864 | Biggest visible win after Pregled. Validates `BbCard` + identity-card pattern + completion radial + verified chips + host-trust KPI tiles. No form, no FROZEN. | Low — moderate LOC, shared drawer parent (don't swap shell) |
| **2** | FAQ (13) | `…/guides/faq_screen.dart` | 477 | Small + safe + validates `BbInput` search box (NON-form) + chips + accordion + contact card. Quick parallel terminal. | Very low |
| **3** | Subscription (08) | `lib/features/subscription/screens/subscription_screen.dart` | 519 | Different parent (`feature/subscription`, not owner_dashboard) — exercises trial hero (`heroGradient`) + Pro vs Besplatno comparison cards + billing toggle chip. Tests `BbCard(variant: accentLeft)` for Pro highlight. | Low — own Scaffold (no shared drawer concern) |
| **4** | Kalendar Mjesečni (04) | `…/calendar/month_calendar_screen.dart` | 1022 | No FROZEN refs at screen level. Month grid + occupancy KPI strip + Google-style spanning bars. Validates `BbCard` + spanning-bar custom layout on top of redesign primitives. | Medium — touches calendar UI (cousin of FROZEN Timeline); be very careful not to import `timeline_dimensions` or `firebase_booking_calendar_repository` |
| **5** | Oporavak računa (recovery, no PNG) | `…/forgot_password_screen.dart` | 318 | TINY (smallest form-bearing). End-to-end validation of Phase 1.1 `BbInput.validator`. Single email field + submit + result state. **Defer until Phase 1.1 merges** (currently in-flight). | Very low after Phase 1.1 |

**Suggested order:**
- Wave 2A (parallel, before Phase 1.1 lands): #1 Profil + #2 FAQ + #3 Subscription (all non-form, fully unblocked)
- Wave 2B (after Phase 1.1 + Login cleanup): #5 Forgot Password (validates Phase 1.1 end-to-end), then #4 Calendar Month (cousin-FROZEN — solo terminal for careful review)

---

## 4 · Solo / late-stage screens (FROZEN-adjacent)

These need careful per-screen scoping; do NOT batch with Wave 2A/2B:

| Screen | Flutter file | FROZEN piece | Migration scope |
|---|---|---|---|
| Smještajne Jedinice (06) | `unified_unit_hub_screen.dart` | Cjenovnik tab via `unit_pricing_screen` import | Migrate chrome + non-Cjenovnik tabs; leave Cjenovnik tab untouched |
| Kalendar Timeline (03) | `owner_timeline_calendar_screen.dart` | Inner timeline widgets (`timeline_dimensions.dart`, `firebase_booking_calendar_repository.dart`) | Migrate page chrome + outer panels; timeline grid widget stays |
| Unit Wizard (`wizard.jsx`) | `unit_wizard_screen.dart` | Step 4 publish flow | Migrate Steps 1-3 chrome; Step 4 publish untouched |
| Booking Widget (01-widget) | `booking_widget_screen.dart` (4143 LOC) | ENTIRE WIDGET per CLAUDE.md NIKADA NE MIJENJAJ | Two options: (a) keep frozen + ship redesigned widget as separate new feature flag, or (b) carefully migrate chrome inside frozen widget. **Needs explicit product decision before scoping.** |
| Booking detail (07) | `booking_details_screen.dart` (widget-side) | Need to verify if owner-side detail is a dialog (in `dialogs.jsx`) or full screen | Verify owner-side render path before scoping |

---

## 5 · Admin dark-theme rollout (Round 3+)

Round 1/2 didn't touch admin; admin runs its own dark deep-purple console (handoff §"AdminScaffold"). Sequencing:

| Step | Screen | Flutter file | Notes |
|---|---|---|---|
| 1 | admin-auth.jsx (01-admin) | `admin_login_screen.dart` (461 LOC, Form, no FROZEN) | First dark-theme PR; introduces dark variants of `BbInput`/`BbButton` if any token gaps surface; cousin of owner Login but pure dark |
| 2 | admin-shell.jsx (02-admin) Overview | `admin_shell_screen.dart` + `admin_dashboard_screen.dart` | Introduces `AdminScaffold` dark variant (handoff says distinct dark deep-purple `#1E1A33` console — separate from owner's `BbScaffold`) |
| 3 | admin-users.jsx (04-admin) | `users_list_screen.dart` + `user_detail_screen.dart` | Exercise admin list+detail pattern in dark |
| 4 | admin-viz.jsx (03-admin) Analytics | overlap check with `admin_dashboard_screen.dart` | Verify if analytics is dashboard tab or separate route before scoping |
| 5–8 | admin-bookings / admin-payments / admin-sync / admin-support | **NET-NEW Flutter screens needed** | Scope as new feature work, not refactor; needs product/UX decision on parity with owner-side equivalents |

**Foundation gap risk for admin dark:** redesign tokens have light + dark variants for shellBg/panelBg/glass/softBg/purpleGlow/etc., but admin's `#1E1A33` deep-purple console is *distinct* from the standard dark scheme. May need a third theme variant `BbRedesignTokens.adminDark` or override at `AdminScaffold` level. Flag for Phase 1.3 token addition when admin work starts.

---

## 6 · NO-MATCH summary — 4 screens need net-new Flutter files

| Handoff JSX | Suggested target path | Estimated scope | Priority |
|---|---|---|---|
| `admin-bookings.jsx` | `lib/features/admin/presentation/screens/admin_bookings_screen.dart` | Mid (table + filters + master-detail) | After admin dark foundation lands |
| `admin-payments.jsx` | `lib/features/admin/presentation/screens/admin_payments_screen.dart` | Mid (Stripe Connect status + payouts log) | After Stripe Connect refactor stable |
| `admin-sync.jsx` | `lib/features/admin/presentation/screens/admin_sync_health_screen.dart` | Mid (OTA feed status grid + alerts) | After iCal sync screen (owner side 10) refactored — share patterns |
| `admin-support.jsx` | `lib/features/admin/presentation/screens/admin_support_screen.dart` | Large (master-detail inbox + threaded conversation) | Lowest urgency — current admin doesn't have support inbox; net-new feature |

---

## 7 · Parallel-safety matrix (for Wave 2A simultaneous terminals)

| Terminal | Screen | File | Branches off | Worktree | Overlap risk |
|---|---|---|---|---|---|
| T1 | Profil | `profile_screen.dart` | `main@5ab91fc1` | `/tmp/bb-rd2-profile-wt` | none |
| T2 | FAQ | `guides/faq_screen.dart` | same | `/tmp/bb-rd2-faq-wt` | none |
| T3 | Subscription | `subscription/screens/subscription_screen.dart` | same | `/tmp/bb-rd2-subscription-wt` | none |

All three touch entirely different feature directories. Zero file overlap. Same `--no-tree-shake-icons` CI prerequisite (already on main via #614). Same softBg token availability (already on main via #615).

---

## 8 · Open questions for product / design before later waves

1. **Booking Widget (01-widget):** FROZEN per CLAUDE.md but handoff has full redesign. Keep frozen or scope a careful in-place refactor?
2. **Owner-side booking detail (07-owner):** is it a full screen or a dialog? The widget-side file `booking_details_screen.dart` (622 LOC) may not be the owner target.
3. **Admin dark deep-purple `#1E1A33`:** standalone `AdminScaffold` or `BbRedesignTokens.adminDark` variant?
4. **Admin NO-MATCH net-new screens (5–8):** scope confirmation before estimation — admin-support inbox is the largest single new feature.
5. **Marketing copy for Login desktop split** (`45+ / 12k / 99.9%` claims + headline + subtitle): real numbers or placeholders? Needs product + i18n team input before "Login desktop split" PR can land.
6. **Settings umbrella (16-owner):** handoff is one screen; Flutter has 3 sub-screens (edit profile / change password / notification settings). Migrate all 3 in one PR or three?
7. **Payouts (09-owner):** handoff is one screen; Flutter has 2 (`bank_account` + `stripe_connect_setup`). Same question.

---

## 9 · Doc-only PR scope

- 1 new file: `audit/104-phase2-screen-readiness.md`
- Zero code changes
- Zero deploy
- Zero touched tests

Reviewer should validate: (a) screen→file mapping correctness (especially booking detail 07-owner and admin-sync), (b) Wave 2A pick order matches their priority, (c) admin dark-theme rollout sequencing.
