# Audit 121 — Handoff color audit, 16 owner pages + chrome, light+dark (2026-06-11)

**Scope:** per user request — page-by-page audit of every section/background color vs `design_handoff` (ground truth `source/tokens.css`), both themes, owner mobile + drawer + app bar. Method: code audit (4 parallel Explore agents over pages 02–16 + chrome) + live iOS-sim verify (Marionette, bookbed-dev, light+dark).

**Note:** `design_handoff/screens/` now has 16 owner PNGs (13 FAQ, 14 Embed, 15 Login, 16 Uredi profil) — prior "01–12 only" note is stale. README screen index maps all.

## Root-cause finding — token layer drift (fixes everything downstream)

`lib/core/design/tokens.dart` (`BBColor`) and `lib/core/theme/app_colors.dart` (`AppColors`, feeds Material colorScheme) had drifted from `tokens.css`:

| Token | Was | Handoff | Notes |
|---|---|---|---|
| BBColor light `primaryDark` | `#5B3DD6` | `#5638C7` | also AppColors |
| BBColor light `primaryLight` | `#9B86F3` | `#B5A4F0` | also AppColors |
| BBColor light `info` | `#6B4CE6` (purple!) | `#4A90D9` | KPI blue tone now correct |
| BBColor light `statusPending` | `#FFB84D` | `#B7791F` | AA-safe amber |
| BBColor light `statusCancelled` | `#718096` | `#4A5568` | |
| BBColor/AppColors dark `surface` | `#0B0B0D` (= panelBg!) | `#121212` | **cards dissolved into panel in dark — every BbCard, app-wide** |
| BBColor `dark` set semantics | reused light consts | `.theme-dark` lifts | new `*DarkMode` consts: secondary/error `#FF8080`, tertiary/warning `#FFC872`, success `#4FAE7F`, info `#6BA8E8`, primaryDark `#6B4CE6`, all 5 status lifts |
| AppColors semantic palette | Tailwind (Emerald `#10B981`, Red `#EF4444`, Amber `#F59E0B`, Blue `#3B82F6`) | handoff (`#2E7D5B`/`#FF6B6B`/`#FFB84D`/`#4A90D9`) | snackbars/dialogs/badges app-wide |
| AppColors status | pending Amber500, cancelled RED, completed GRAY | handoff table (cancelled `#4A5568`, completed `#6B4CE6`) | |
| AppColors `secondaryDark`/`tertiaryDark` | `#E63946`/`#FF9500` | `#E14F4F`/`#E69A28` | |

`BbRedesignTokens` (rd.*) was already fully handoff-correct both themes — drift was only in BBColor/AppColors.

## Chrome

- **App bar** (`app_theme.dart`): was `surface` bg (audit/116) → now **shellBg** both themes (`#F0F1F5`/`#000`) per handoff "transparent on the shell". New `AppColors.shellBgLight/shellBgDark`. Light scaffold default also → shellBg (no seam).
- **Drawer** (`owner_app_drawer.dart`): killed hardcoded `#B794F6` + theme-blind `colorScheme.brandPurple` (12 sites) → `BBColor.of(context).primary` (`#6B4CE6`/`#8B6FFF`).

## Per-page fixes (from agent findings, each verified before edit)

- **02 Rezervacije**: `Colors.red` snackbars + `Colors.red.shade*` conflict badges (5 clusters) → `AppColors.error`/`errorDark`/tints
- **03 Timeline**: 2× `Colors.red` snackbars → `AppColors.error` (grid FROZEN — untouched)
- **04 Mjesečni**: agenda/header bgs `#1A1A1A`/`#F4F5F9`/`#2D2D2D`/`#EEF0F2` → `surfaceVar*`; `_getBookingColor` Material green/orange/gray → `BBColor.status*` (+dark lifts); conflict border → `BBColor.error`
- **06 Units hub**: `_kAvailable/Unavailable` `#66BB6A`/`#EF5350` → `BBColor.success/error`; spinners white/black → primary (Cjenovnik tab content FROZEN — untouched)
- **10 iCal**: `Colors.green` snackbar → `BBColor.success`
- **11 AI Asistent**: 9 hardcoded dark-surface hexes (`#2D2D2D/2E`, `#1A1A1A`, `#E8E8E8`, `#F4F5F9`) → `BBColor.surface*`
- **12 Obavještenja**: body had no explicit bg (scaffold `#FAFAFA` ≠ shell) → wrapped in `pageBackground`
- **14 Embed guide**: 6 hardcoded card/sheet/code-block bgs + ad-hoc blue info box → `BBColor.surface*` + info tint
- **05 Profil, 09 Isplate, 13 FAQ, 15 Login, 16 Uredi profil: CLEAN** (token-true already)
- **07 Booking detail + 08 Pretplata**: agent flags = false positives (white text over photo scrim / `rd.heroGradient` purple hero — correct both themes)

## Pregled extras (same session, earlier turn)

- `UnifiedDashboardData.distinctGuests` (`@Default(0)`) + provider dedupe by `guest_email`→`guest_name`
- KPI strip aligned to handoff order/icons/tones: REZERVACIJE (`receipt_long`/primary) → PROSJ. CIJENA (`payments`/info-blue) → NOVI GOSTI (`person_add`/success) → PROSJEČNA OCJENA (`star`/tertiary, value `—` until reviews data exists; POPUNJENOST tile dropped — radial card already covers it)
- l10n: `ownerDashboardNewGuests`, `ownerDashboardAvgRating` (en+hr)

## Verification

- `flutter analyze lib/` → 0 errors/warnings, 91 infos (= pre-session baseline)
- `flutter test` full suite → **all pass** (bb_card_test dark-surface assertion updated `#0B0B0D`→`#121212`)
- Live iOS sim (bookbed-dev, debug, Marionette): Pregled light+dark (shell/panel/card layering visible in dark now), KPI strip live (NOVI GOSTI=4 real data), drawer light+dark (`#8B6FFF` selected pill dark), Profil dark, Mjesečni dark (lifted status legend), Rezervacije dark, Obavještenja light+dark (shell fix visible). Plist restored to PROD after.

## Second pass (same session, /effort max continue)

- **`BookingStatus.color` theme-blindness FIXED**: added `colorDark` + `colorOf(BuildContext)` to the extension (`core/constants/enums.dart`); migrated all 21 call sites across 8 widgets (timeline_booking_block, timeline_split_day_cell, booking_context_menu, booking_action_menu, smart_booking_tooltip, calendar_filters_panel, bookings_table_view, booking_details_dialog_v2) — dark mode now renders lifted status colors on Timeline blocks/split cells, table badges, menus, tooltips. `color` getter kept (light) for non-widget callers.
- **Units hub availability colors theme-aware**: `_kAvailableColor/_kUnavailableColor` consts → `_availableColor(theme)/_unavailableColor(theme)` (dark lifts).
- **Second live sim pass** (light+dark): Timeline (lifted `#4FAE7F` blocks + error conflict borders in dark — `colorOf` fix confirmed; AA `#B7791F` pending block in light), Units hub (Dostupan lifted in dark after fix, hot-reload verified), iCal, AI chat surface (surfaceVariant chips/input both themes), FAQ, Isplate. Theme restored to Sustavna, plist restored to PROD, full `flutter test` green again.

## Third pass — non-screenshotted screens + shared components

3 parallel Explore audits over the handoff "Other owner screens" + shared chrome:

- **CLEAN (verified, no changes)**: enhanced_register, forgot_password, change_password, notification_settings, 3 legal screens (R5), booking_create_dialog, booking_inline_edit_dialog, bookings_filters_dialog, unit wizard steps 1–4 (colors; publish flow untouched), unit_future_bookings_dialog, multi_select_action_bar, skeleton_loader, input_decoration_helper, error_state_widget.
- **FIXED**:
  - `shared/widgets/message_box.dart` — `_getColors` rewritten from Tailwind Blue/Amber literals to `BBColor` info/warning + dark lifts + AA `statusPending` foreground on light tint (used in owner send-email + booking-detail dialogs)
  - `features/subscription/widgets/trial_banner.dart` — `_ExpiringBanner`/`_ExpiredBanner` were `Colors.amber/red.shadeN` light-only (blinding pastel in dark); now theme-aware warning/error tint gradients + `AppColors.warningDark/errorDark` CTAs
  - `shared/widgets/smart_tooltip.dart` — light tooltip ink `#424242` → palette `#2D3748` (text-primary)
  - `core/utils/error_display_utils.dart` — stale "Mediterranean/Tailwind" doc palette comment corrected (code already token-true)
- **Deliberately NOT touched**: `shared/utils/ui/snackbar_helper.dart` `SnackBarColors` — consumed exclusively by the booking-widget surface (mint/minimalist palette, own status-color system per `.claude/rules/widget.md`); owner scope excludes it. `AppColors.dialogFooterDark #1E1E2A` purple tint kept (intentional per ui-ux.md). `AppColors.activity*` badges left (decorative type-coding, LOW).

`flutter analyze lib/` 91 baseline infos / 0 errors; full `flutter test` green (3rd run).

## Fourth pass — Zarada po kanalu real data (handoff gap closed)

`UnifiedDashboardData.revenueBySource` (direct/booking_com/airbnb/other buckets from booking `source`, zero-priced iCal imports skipped) computed in the provider from the same confirmed+completed set as `revenue` — channel amounts sum exactly to the hero total. `_PregledChannelMix` un-gated (kDebug + `PREGLED_CHANNEL_MIX` define + placeholder proportions removed), renders real buckets, hides on no-priced-revenue periods. Live verify bookbed-dev: Direktno €360 18% / Airbnb €390 19% / Ostalo €1270 63% = €2020. Remaining product gap now only: PROSJEČNA OCJENA (reviews feature).

## Fifth pass — NAPLAĆENI DEPOZITI (handoff gap closed)

Booking docs already carry `paid_amount`/`remaining_amount`/`payment_status` — no new product feature needed. `UnifiedDashboardData.depositsCollected` (Σ paid_amount, confirmed+completed) + `depositsOutstanding` (Σ unpaid remainder, CONFIRMED only — "na dolasku"; completed=settled). New `_PregledDepositsCard` after the occupancy radial per handoff right-column order: success wallet tile, collected headline, collected/expected progress bar, "Naplaćeno (N%)" + "€X na dolasku" row; always renders (€0 calm baseline). Live verify bookbed-dev: €0 (0%) / €1370 na dolasku — honest zeros, seed bookings have paid_amount=0.

## Known residuals (not fixed, by design or out of scope)
- Legacy `AppColors.primaryGradient/heroGradient` still old hexes — 0 callers (dead), cleanup PR candidate
- Subscription `_TrialHero` white-on-gradient is intentional (purple hero both themes), no dark branch needed
- Widget + admin surfaces out of scope (user chose owner-only)
