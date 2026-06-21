# Frozen-Fence Integrity + Dead-Code Recon

**Date:** 2026-06-20
**HEAD:** `54f0820a` (feat(owner): Settings cheap-wins — widget_advanced AppBar unification + notif l10n (audit/135) (#762))
**Mode:** READ-ONLY (no code changed, no files deleted). Verification via `git log/show/diff` + ref-counting greps.

**Update 2026-06-20 (post-#767):** B.1 Tier-1 singletons were SHIPPED via `9ba7a5ff` (#767) and are removed from the candidate tables below (rolled up under "✅ Shipped via #767"). Cascade: deleting `price_calculator_provider.dart` newly-orphaned `booking_price_breakdown.dart` (+`NightlyPrice`), now folded into B.2 with a deletability verdict (see B.2 "Addition" note). Net B.2 count holds at 61 (−1 shipped, +1 new). This recon doc still deletes nothing itself; #767 was a separate PR.

---

## PART A — FROZEN-FENCE ("NIKADA NE MIJENJAJ") INTEGRITY

**Overall verdict: ALL 11 FROZEN SURFACES INTACT.** No frozen CONTENT was modified after its freeze point. Recent commits touching frozen-adjacent files are additive/shell-only or documented-sanctioned (T11c). Two doc-staleness notes flagged (calendar repo line count; rule is dormant-by-removal) — neither is a violation.

| # | Frozen surface | Path | Last commit touching FROZEN scope (sha · date · subject) | Verdict |
|---|----------------|------|-----------------------------------------------------------|---------|
| 1 | Cjenovnik tab CONTENT (pricing grid + Spremi) | `lib/features/owner_dashboard/presentation/screens/unified_unit_hub_screen.dart` (real content embedded from `unit_pricing_screen.dart`) | content unchanged; recent `7301e77b` (2026-06-19, audit/134) = **Osnovno tab + read-only display card** only; `ea00773b` (2026-06-13) = **additive desktop two-column wrapper** (only reachable when `showAppBar` true; hub embeds `showAppBar:false` → always single-column) | **INTACT** (recent edits additive-only) |
| 2 | Unit Wizard publish — 2-doc serial write (unit → widget_settings, Doc2 id from Doc1) | `lib/features/owner_dashboard/presentation/screens/unit_wizard/unit_wizard_screen.dart` `_publishUnit()` L321–334 | `a452ab58` (2026-06-13, "publish flow FROZEN/untouched" — chrome/token only, 0 publish-path lines) | **INTACT** (serial `await` Doc1 then Doc2; no batch/`Future.wait`/reorder) |
| 3 | Timeline z-index — cancelled drawn first, confirmed on top | `lib/features/owner_dashboard/presentation/widgets/timeline/timeline_grid_widget.dart` (paint=list order) | `fb27426a` (scroll sync/perf; did NOT alter status draw-order) | **INTACT — but now VESTIGIAL** (see note) |
| 4 | Calendar repository — no edits, no tests | `lib/features/widget/data/repositories/firebase_booking_calendar_repository.dart` | `ab6bdb3d` (2026-05-22, **T11c sanctioned** security migration) — NEWEST; nothing edited it since; working tree byte-stable | **INTACT-since-T11c** (⚠ doc says 989 lines; file is now **1293** — grown by T11c itself, see note) |
| 5 | Owner email ALWAYS sent (no conditional) | `functions/src/atomicBooking.ts` L1330–1349 (pending) + L1448–1475 (auto-confirm) | `f5eab8c0` (CORS-only) / `a9e962b5` (SF-079 upstream gate, not email skip) / `a42db4af` (rate-limit) — owner-email logic untouched | **INTACT** (both sites `sendEmailIfAllowed(..., true)` = `forceIfCritical`, bypasses prefs at `emailNotificationHelper.ts:53`) |
| 6 | Subdomain regex `/^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/` | `functions/src/subdomainService.ts:47` | `a2897d50` (CORS allowlist; regex untouched) | **INTACT** (byte-identical) |
| 7 | `generateViewBookingUrl()` | `functions/src/emailService.ts:315` | `73d142d6` (quote-style `'`→`"` + trailing-whitespace formatting ONLY) | **INTACT** (logic/branching unchanged) |
| 8 | Navigator.push for confirmation (NOT state-based) | `lib/features/widget/presentation/screens/booking_widget_screen.dart` L1000/3489/3935 + `_showConfirmationFromUrl` L3823 | `4ec7fd7d` (SF-079, explicitly "frozen-safe" — banner above calendar, not the nav path) | **INTACT** (all sites `Navigator.push(MaterialPageRoute(...))`; no `_showConfirmation` bool toggle) |
| 9 | Timeline fixed dims 50/42/100/60px, no breakpoints | `lib/features/owner_dashboard/presentation/widgets/timeline/timeline_dimensions.dart:13-16` | `457d4ecc` (freeze-establishing commit itself) | **INTACT** (only `MediaQuery` use = pre-existing `screenWidth` getter that chooses how many days to *show*, not cell size; FIXED consts untouched) |
| 10 | firestore.rules bookings READ — `unit_id`+`status` clause 1 (T11c CLOSED) | `firestore.rules` L345/601/625 | `fdd74bd4` (registration userdoc fix — unrelated to bookings read clause) | **INTACT** (clause correctly REMOVED at all 3 surfaces per T11c; comments document closure 2026-05-22) |
| 11 | App Check OFF on widget entries (`AppCheckInit.activate` removed) | `lib/widget_main.dart` / `lib/widget_main_dev.dart` / `lib/widget_main_staging.dart` | `2ee8d838` (prod+dev disable) / `9cd2d2de` (staging parity) | **INTACT** (only COMMENT mentions of `AppCheckInit.activate` in `widget_main.dart:139,151`; **zero `.activate` calls** in all 3 entries; owner/admin keep it = allowed) |

### Frozen notes (not violations, worth recording)

- **#4 doc staleness:** CLAUDE.md + `.claude/rules/calendar.md` cite "989 linija". The file is currently **1293 lines** — T11c (`ab6bdb3d`, net −69 but a full rewrite) left it at 1293 on 2026-05-22. The growth is the sanctioned T11c commit, **not a post-freeze edit**. Consider updating the doc figure to 1293 so the next auditor's `wc -l` check matches.
- **#3 dormant rule:** the cancelled-first / confirmed-on-top z-order is no longer actively exercised. Owner timeline **filters cancelled out before paint** (`owner_calendar_provider.dart:108-119`); the public widget calendar never carries `cancelled` status (T11c synthesizes `confirmed`-only). The explicit status-sort+opacity layering was deliberately **removed** (commit `1e9515ab`) and replaced by filter-out — retired by removal, **not inverted**. No live view currently renders both cancelled+active blocks together; the rule would need re-implementation only if such a view returns.

---

## PART B — DEAD-CODE / DEBT CANDIDATES

Scope: `lib/**` + `functions/src/**`. Excluded: `*.g.dart`, `*.freezed.dart`, `test/`, `*.test.ts`, `__tests__/`, `functions/lib/`, entrypoints. Every candidate ref-count was measured by grep across the corpus; dynamic/string/generated refs disambiguated.

**Coverage:** Dart — full-corpus (955 private decls, 1196 public classes/widgets/exts, 147 providers, 591 files). functions/src — 308 named exports + 100 non-test .ts files; transitive reachability from `index.ts` computed via its 38 `export *` barrels (barreled module exports are LIVE CF surface even with 0 internal caller).

### B.1 — Dead-code candidates (high-confidence first)

> **✅ Shipped via #767 (`9ba7a5ff`, 2026-06-20):** the following Tier-1 candidates were deleted and are removed from the table below — `functions/src/config/tokenConfig.ts` (orphan fns module), `lib/features/widget/presentation/providers/price_calculator_provider.dart` (stale dup; cascade → see B.2 "Addition"), the 3 constant-holder classes `PaymentMethodValues` / `PaymentOptionValues` / `ActiveBookingStatuses`, the 5 dead extensions `GlassmorphismWidget` / `CurrencyConversionExtension` / `HapticCallback` / `PriceFormatting` / `ThemeConditional`, and the cascade-orphaned `HapticFeedbackType` enum.

| symbol / file:line | kind | ref count | confidence | note |
|--------------------|------|-----------|------------|------|
| `withSentry` `functions/src/sentry.ts:189` | fn | 0 | **HIGH** | unused Sentry wrapper |
| `sendSms` `functions/src/smsService.ts:29` | fn | 0 | **HIGH** | SMS never wired (cf. TODO `index.ts:95`) |
| `sendPaymentReminderEmail` `emailService.ts:800` | fn | 0 | **HIGH** | dormant-by-design email sender |
| `sendCheckInReminderEmail` `emailService.ts:863` | fn | 0 | **HIGH** | dormant email sender |
| `sendCheckOutReminderEmail` `emailService.ts:927` | fn | 0 | **HIGH** | dormant email sender |
| `sendRefundNotificationEmail` `emailService.ts:703` | fn | 0 | **HIGH** | dormant email sender |
| `sendOwnerCancellationNotificationEmail` `emailService.ts:648` | fn | 0 | **HIGH** | dormant email sender |
| `sendOverbookingNotifications` `overbookingNotifications.ts:40` | fn | 0 | **HIGH** | 0 callers |
| `findBookingByReference` `utils/bookingLookup.ts:177` | fn | 0 | **HIGH** | in-file hits are log-tag strings, not calls |
| `isValidBookingReference` `utils/bookingReferenceGenerator.ts:52` | fn | 0 | **HIGH** | sibling `generateBookingReference` has 11 refs |
| `getRateLimitStatus` `utils/rateLimit.ts:284` | fn | 0 | **HIGH** | in-file hit is `@example` JSDoc |
| `getNotificationPreferences` `notificationPreferences.ts:30` | fn | 0 | **HIGH** | 0 callers |
| `shouldSendSmsNotification` `notificationPreferences.ts:134` | fn | 0 | **HIGH** | 0 callers (SMS dead) |
| `isAuthoritative` `utils/platformClassification.ts:137` | fn | 0 | **HIGH** | 0 callers |
| `buildEmailTemplate` `email/templates/base.ts:78` | fn | 0 | **HIGH** | also @deprecated |
| `generateParagraph` / `generateSpacer` / `generateInfoBox` / `generateList` `email/utils/template-helpers.ts:514/529/673/695` | fn ×4 | 0 each | **HIGH** | unused template helpers |
| `getColorVariables` `email/styles/colors.ts:129` | fn | 0 | **HIGH** | 0 refs |
| `logDebug` `functions/src/logger.ts:211` | const | 0 | **HIGH** | unused log level wrapper |
| `logComplete` `logger.ts:237` | const | 0 | **HIGH** | unused |
| `LogLevel` `logger.ts:38` | enum | 0 | **HIGH** | unused |
| `widgetSettingsExistProvider` `widget_settings_provider.dart:51` | provider | 0 | **HIGH** | manual provider, 0 consumers |
| `revenueAnalyticsRepositoryProvider` `lib/shared/providers/repository_providers.dart:65` | provider | 0 | MED-HIGH | provider + backing `FirebaseRevenueAnalyticsRepository` both unconsumed (dead cluster; removing orphans `firebase_revenue_analytics_repository.dart`) |
| `propertyPerformanceRepositoryProvider` `repository_providers.dart:72` | provider | 0 | MED-HIGH | provider + `FirebasePropertyPerformanceRepository` both unconsumed (removing orphans `firebase_property_performance_repository.dart`) |
| `calendarDataServiceProvider` `widget_repository_providers.dart:124` | provider | 0 | MED-HIGH | 0 consumers |
| `tabCommunicationServiceProvider` `widget_repository_providers.dart:144` | provider | 0 | MED-HIGH | 0 consumers |
| `paginatedBookingsNotifierProvider` + class `PaginatedBookingsNotifier` `owner_bookings_provider.dart:225/678-701` | provider sub-graph | 0 external | MED-HIGH | `ownerBookingsProvider` / `hasMoreBookingsProvider` / `isLoadingBookingsProvider` / `isLoadingMoreBookingsProvider` (L678-701) consume ONLY each other — entire cluster dead |
| `conflictsForUnitProvider` `overbooking_detection_provider.dart:165` | @riverpod provider | 0 ext | MED | 0 refs outside own file + .g.dart |
| `ownerPropertiesCountProvider` `owner_properties_provider.dart:37` | @riverpod provider | 0 ext | MED | |
| `widgetContextByUnitOnlyProvider` `widget_context_provider.dart:198` | @riverpod provider | 0 ext | MED | |
| `cachedWidgetContextProvider` `widget_context_provider.dart:235` | @riverpod provider | 0 ext | MED | |
| `currentSubdomainProvider` `subdomain_provider.dart:23` | @riverpod provider | 0 ext | MED | |
| `ownerBankDetailsProvider` `owner_bank_details_provider.dart:11` | @riverpod provider | 0 ext | MED | whole file also unreferenced (B.2) |
| **61 unreferenced `.dart` files** (full list below) | files | 0 imports each | **HIGH** (unless noted) | basename in 0 import/export/part anywhere in `lib/`; public symbols 0 cross-file refs |

**Category-1 private symbols:** **0 dead** — every top-level private class/mixin/enum/extension/function/var (955 checked) is referenced ≥1× beyond its declaration; all 286 private widgets are instantiated. (`_LedgerMetrics`, `_EmbedMode` were false positives — used via `.member`/enum access.)

### B.2 — 61 unreferenced `.dart` files (HIGH confidence; basename in 0 imports, symbols 0 cross-file)

> Note: 9 conditional-import/`part` stubs (`*_web.dart`/`*_io.dart`/barrels) were correctly excluded. The coupled repo files behind dead analytics providers (B.1) are imported, so NOT counted here, but become orphaned if those providers are removed.

**core/ (11):** `core/errors/error_handler.dart` · `core/services/cache_service.dart` · `core/services/deep_link_service.dart` · `core/services/email_notification_service.dart` (899L) · `core/services/performance_optimization_service.dart` · `core/theme/app_effects.dart` · `core/utils/flutter_animate_extensions.dart` · `core/utils/seo_web_stub.dart` · `core/widgets/keyboard_aware_constrained_box.dart` · `core/widgets/owner_app_loader.dart` · `core/widgets/owner_splash_screen.dart` (421L)

**features/auth/ (6):** `auth/models/saved_credentials.dart` · `auth/presentation/widgets/auth_background.dart` · `auth/presentation/widgets/glass_card.dart` · `auth/presentation/widgets/gradient_auth_button.dart` · `auth/presentation/widgets/line_art_icons.dart` (321L) · `auth/presentation/widgets/premium_input_field.dart`

**features/owner_dashboard/ (19):** `providers/owner_bookings_view_preference_provider.dart` · `screens/unit_wizard/widgets/wizard_step_container.dart` · `services/overbooking_notification_service.dart` · `utils/unit_validators.dart` · `widgets/booking_details_dialog.dart` (960L) · `widgets/booking_details_dialog_v2.dart` (828L) · `widgets/calendar/booking_block_widget.dart` · `widgets/calendar/booking_context_menu.dart` · `widgets/calendar/booking_status_change_dialog.dart` · `widgets/calendar/calendar_filter_chips.dart` · `widgets/calendar/calendar_state_builders.dart` · `widgets/calendar/room_row_header.dart` · `widgets/calendar/scroll_direction_lock.dart` · `widgets/calendar/shared/calendar_summary_bar.dart` · `widgets/dashboard_stats_skeleton.dart` · `widgets/property_card_owner.dart` (593L) · `widgets/recent_activity_widget.dart` · `widgets/timeline/timeline_split_day_cell.dart` · `utils/responsive_calendar_layout.dart`

**features/subscription/ (1):** `subscription/data/subscription_repository.dart`

**features/widget/ (16):** `domain/models/guest_details.dart` · `domain/models/booking_price_breakdown.dart` (newly orphaned by #767 → ✅ removed via #778, see "Addition" note) · `presentation/models/booking_confirmation_data.dart` · `providers/ical_sync_status_provider.dart` · `providers/owner_bank_details_provider.dart` · `widgets/bank_transfer/bank_details_section.dart` · `widgets/bank_transfer/important_notes_section.dart` · `widgets/bank_transfer/payment_warning_section.dart` · `widgets/bank_transfer/qr_code_payment_section.dart` · `widgets/confirmation/booking_reference_card.dart` · `widgets/confirmation/email_spam_warning_card.dart` · `widgets/pwa/connectivity_banner.dart` · `widgets/pwa/pwa_install_button.dart` · `widgets/widget_shell_skeleton.dart` · `widgets/zoom_hint_overlay.dart` · `utils/firestore_validators.dart`

**shared/ (8):** `shared/models/booking_service_model.dart` · `shared/widgets/bookbed_logo.dart` · `shared/widgets/debounced_search_field.dart` · `shared/widgets/deferred_loader.dart` · `shared/widgets/feature_highlight_widget.dart` · `shared/widgets/gradient_button.dart` · `shared/widgets/loading_overlay.dart` (distinct from live `global_navigation_loader.dart`) · `shared/widgets/login_loading_overlay.dart`

> **Exclusion (2026-06-20):** `widgets/popup_blocked_dialog.dart` was pulled from this list — it is being KEPT and localized (System B `WidgetTranslations`, branch `fix/widget-l10n-guest`) and will be WIRED into the blocked-popup path separately (branch #7; `booking_widget_screen.dart` is FROZEN). It is import-unreferenced only because that wiring hasn't landed yet → **B.2 must NOT delete it.** (The `features/widget/` group was also mislabeled 19; 17 entries were actually listed, now 16.)
>
> ⚠ Many of these are plausibly-superseded redesign artifacts (`booking_details_dialog.dart` + `_v2`, `gradient_auth_button.dart`, `glass_card.dart`, `owner_splash_screen.dart`). Recommend confirming none are referenced from web `index.html`/asset manifests or reflectively before any future removal PR.
>
> **Addition (2026-06-20, post-#767):** `domain/models/booking_price_breakdown.dart` (148 L; classes `BookingPriceBreakdown`, `NightlyPrice`, `AdditionalServicePrice`) is **newly orphaned** by #767. Its sole consumer was the now-deleted `price_calculator_provider.dart`, which `import`ed it and built `NightlyPrice` lists (confirmed against `9ba7a5ff^`: `import '../../domain/models/booking_price_breakdown.dart'` + `NightlyPrice(...)` at L60/83). Post-#767 grep: **0 importers** of the basename repo-wide; `BookingPriceBreakdown` + `NightlyPrice` are referenced only inside the file itself. The two `dashboard_overview_tab.dart` "NightlyPrice" hits are the local var **`avgNightlyPrice`** (substring false positive — that file does not import the model). **B.2 verdict: the WHOLE FILE is deletable** — `NightlyPrice` has no external consumer, so it goes with the file (all 3 classes are dead-by-orphan). It occupies the `features/widget/` slot vacated by `price_calculator_provider.dart`, so the net 61 is unchanged. **✅ removed via `chore/deadcode-b2-rm-price-breakdown` (c00bab36 → PR #778, squashed to main `fc07eb8d`) on 2026-06-21.**

### B.3 — TODO / FIXME / HACK / XXX debt

| Marker | Real count | Note |
|--------|-----------|------|
| TODO | **10** | all legit |
| FIXME | 0 | — |
| HACK | 0 | — |
| XXX | 0 | 17 raw matches all false positives (URL placeholders `?ref=XXX`, phone-format docs) |

**All 10 TODOs:**
- `lib/core/config/environment.dart:125` — paste bookbed-staging VAPID key from Firebase Console
- `lib/core/config/environment.dart:127` — paste bookbed-dev VAPID key from Firebase Console
- `lib/features/owner_dashboard/presentation/screens/widget_settings_screen.dart:657` — TODO(wave1a): wire real subscription tier
- `lib/features/owner_dashboard/presentation/screens/change_password_screen.dart:505` — TODO(B4b): wire `revokeAllRefreshTokens` *(cross-link: the CF `revokeTokens.ts:40` exists + is registered but client never calls it)*
- `functions/src/guestCancelBooking.ts:254` — Add cancellation policy logic (full_refund/50_percent/no_refund)
- `functions/src/index.ts:95` — SMS feature not yet implemented (requires Twilio/SMS provider)
- `functions/src/emailService.ts:25` — Suspicious Activity Email (deferred)
- `functions/src/emailService.ts:978` — sendSuspiciousActivityEmail removed (TODO future)
- `functions/src/stripeSubscription.ts:24` — (pointer to docs/TODO.md)
- `functions/src/loginLockout.ts:25` — (pointer to docs/TODO.md "App Check launch checklist")

### B.4 — @deprecated inventory (34 hand-authored; ~49 `.g.dart` boilerplate excluded)

**Live debt (deprecated but STILL called — migrate callers before removing):**
- `AppTypography.bodyMedium` `app_typography.dart:230` — 2 callers
- `AppTypography.bodyLarge` `app_typography.dart:234` — 1 caller
- `WidgetConfig` typedef `embed_url_params.dart:314` — 3 callers (`dynamic_theme_service.dart:15,127,186`)
- `deleteIcalFeedsLegacy` `functions/src/deleteUserAccount.ts:331` — 1 caller (L97, intentional legacy-cleanup path)

**Removable now (deprecated, 0 callers):**
- `AppTypography.bodySmall` `app_typography.dart:238`
- `DateRangeFilter.lastWeek/.currentMonth/.lastQuarter/.lastYear` `unified_dashboard_data.dart:163-172` (4 alias factories)
- `OwnerRoutes.icalIntegration` `router_owner.dart:117` · `OwnerRoutes.guideIcal` `router_owner.dart:119`
- `NameValidator` (class) `form_validators.dart:64`
- `WidgetConfig` (whole file) `widget_config.dart:1` (once typedef above retired)
- `buildEmailTemplate` `email/templates/base.ts:78` (also B.1)
- **20 `tokens.dart` deprecated `BB*` aliases** (all 0 direct callers): `BBSpace` xs2/xxs2/xs6/sm20/lg40/xl-range/xxxl96 · `BBRadius` tiny/subtle/medium/large · `BBType` doubles xs/sm/md/lg/xl/xxl/display1/display2/display3. These are intentional deprecate-on-use guard-rails (cf. CLAUDE.md `BBSpace.xs2` rule) — removable but low-value; "Heavy usage (48×)" in their doc-comment refers to the underlying `AppDimensions` source, not these aliases.

### B.5 — functions/src local dead code
**Local (non-exported) 0-reference functions/consts: NONE.** All 100 files scanned clean.

---

## Summary

- **FROZEN: 11/11 INTACT.** Zero violations. 2 doc-hygiene notes (calendar repo line count 989→1293 stale in CLAUDE.md; #3 z-order dormant-by-removal).
- **Dead code (high-confidence):** 61 unreferenced `.dart` files + ~25 dead fns exports + ~17 orphaned/dead-cluster providers. *(✅ Shipped via #767 (`9ba7a5ff`): 1 orphan fns module + 1 stale-dup Dart file + 5 dead Dart extensions + 3 dead constant-holder classes + `HapticFeedbackType`. B.2 holds at 61: `price_calculator_provider.dart` removed as shipped, `booking_price_breakdown.dart` added as newly orphaned, then ✅ removed via #778.)*
- **Debt:** 10 TODOs (0 FIXME/HACK/XXX), 34 `@deprecated` (4 live debt, ~30 removable incl. 20 token-alias guard-rails).
- **Nothing deleted by this recon.** B.1 Tier-1 shipped separately via #767 (`9ba7a5ff`). Remaining candidates ref-count-verified; recommend a confirmation grep against web `index.html`/asset manifests before any removal PR (redesign artifacts likely).
