# l10n Hardcoded-String Recon Sweep

**Sweep date:** 2026-06-20
**HEAD:** `54f0820a` (main)
**Mode:** READ-ONLY recon. No source edited, no git mutation, no build/analyze run.

---

## l10n infrastructure summary (ground truth)

There are **TWO PARALLEL localization systems** in this app — a fact that changes how the widget surface must be scored.

### System A — `gen_l10n` (the official one)
- Source: `lib/l10n/app_hr.arb` (primary, **3218 keys**) + `lib/l10n/app_en.arb` (3712 lines). Generated → `lib/l10n/app_localizations*.dart`.
- **Call-site pattern is `AppLocalizations.of(context)`** — NOT `context.l10n` (that extension does not exist in this repo; the prompt's `context.l10n` hint is approximate). Typical idiom: `final l10n = AppLocalizations.of(context); … Text(l10n.someKey)`.
- Adoption (files importing `AppLocalizations.of`): owner_dashboard **85 / 170**, auth **9 / 18**, subscription **1 / 5**, core **3**, admin **1 / 8**, widget **0 / 160**.

### System B — `WidgetTranslations` (the embedded-widget one)
- Source: `lib/features/widget/presentation/l10n/widget_translations.dart` — a hand-rolled 4-language switch (**HR / EN / DE / IT**), reactive via `languageProvider`. **178 call sites** (`WidgetTranslations.of(context, ref)` → `tr.checkIn` etc.).
- This is why the widget surface shows **0** `AppLocalizations` usage yet is mostly localized. Guest-facing widget strings overwhelmingly route through `tr.*`. **The widget is NOT an un-localized surface** — it has its own (broader, 4-lang) coverage.

### Key-naming convention learned
**camelCase, with a feature/screen prefix.** Largest existing prefixes (by key count): `unitWizard*` (139), `icalExport*` (129), `widgetSettings*` (118), `embedGuide*` (110), `ownerForm*` (88), `ownerDashboard*` (84), `unitHub*` (70), `propertyForm*` (66), `bookingCreate*` (62), `ownerTimeline*` (60), `priceCalendar*` (54), `stripeGuide*` (47), `privacyScreen*` (36), `aiAssistant*` (22), `bankAccount*` (18), `bookingAction*` (17), plus globals (`save`, `cancel`, `delete`, `retry`…) and the existing **`admin*`** cluster (`adminWelcomeBack`, `adminEmailLabel`, `adminSignInButton`, `adminAccessDenied`, `adminFooterCopyright`…). All suggested keys below follow this `<surface/screen>Camel` scheme.

> **Important:** the `admin*` keys **already exist in the .arb** but the admin screens were re-written (premium redesign) WITHOUT wiring them — so admin localization is "infra-ready, call-sites-missing", not greenfield.

---

## 1. Summary — flagged counts per surface

| Surface | Hardcoded UI literals flagged | Notes |
|---|---|---|
| **admin** | **~105** (across 6 screens + 4 `admin_main*` titles) | **Entire surface hardcoded in ENGLISH.** Highest priority. `.arb` keys partly pre-exist. |
| **owner** (owner_dashboard + auth + subscription) | **~275** | Mostly HR stragglers in screens that *already* import `AppLocalizations` (partial migration). |
| **widget** | **~15 genuine** (excl. `widget_translations.dart` itself) | Surface is localized via System B; flagged items are the few that **bypass** `tr.*` — most are EN error/dialog leaks. |
| **shared** (`lib/core/widgets`) | **~3** | Tiny. `bb_input` show/hide tooltips + an FCM "View" action. |

**Rough effort estimate**
- **admin** — ~1.5 days. Mechanical but whole-surface: 6 screens + main titles, ~80 distinct strings, many `admin*` keys already exist (reuse). All English → straight HR translation.
- **owner** — ~2–3 days. ~150 distinct strings spread across ~40 files; screens already have the `AppLocalizations` import so each is a localized swap, but volume is high and several have interpolation/plural needs (`#$reference`, `$nights ${nights==1?…}`, `$daysRemaining days`).
- **widget** — ~0.5 day. Add ~12 keys to `WidgetTranslations` (4 langs each) + convert `popup_blocked_dialog`, the `booking_widget_screen` error toasts, and `widget_mode` labels.
- **shared** — ~1 hr.
- **Total: ~4–6 dev-days** to reach full HR coverage (more if DE/IT parity is wanted for the owner/admin error strings the widget already covers).

---

## 2. Flagged strings by surface

`file:line | string (verbatim, ~60-char cap) | suggested key | sink`. Where a screen already imports `AppLocalizations`, the swap is trivial (marked ✓import).

### 2A. ADMIN (all English — see also §3 priority section)

App titles:
| file:line | string | suggested key | sink |
|---|---|---|---|
| lib/admin_main.dart:37 | `BookBed Admin` | `adminAppTitle` | MaterialApp title |
| lib/admin_main_dev.dart:63 | `BookBed Admin (Dev)` | `adminAppTitleDev` | title |
| lib/admin_main_staging.dart:34 | `BookBed Admin (Staging)` | `adminAppTitleStaging` | title |
| lib/admin_main_production.dart:34 | `BookBed Admin` | `adminAppTitle` | title |

`admin_dashboard_screen.dart` (✓import on this file = no):
| line | string | suggested key | sink |
|---|---|---|---|
| 74 | `Dashboard Overview` | `adminDashboardTitle` | Text |
| 77 | `Welcome back! Here is what's happening with your platform.` | `adminDashboardSubtitle` | Text |
| 90 | `Total Owners` | `adminStatTotalOwners` | label |
| 96 | `Trial Users` | `adminStatTrialUsers` | label |
| 102 | `Premium Users` | `adminStatPremiumUsers` | label |
| 108 | `Lifetime Licenses` | `adminStatLifetimeLicenses` | label |
| 149 | `Analytics` | `adminAnalyticsTitle` | Text |
| 162/163 | `Conversion Rate` / `Trial to Paid` | `adminConversionRate` / `adminTrialToPaid` | label |
| 175/176 | `New Signups` / `Last 7 days` | `adminNewSignups` / `adminLast7Days` | label |
| 481 | `Account Distribution` | `adminAccountDistribution` | Text |
| 519/527/535 | `Trial` / `Premium` / `Lifetime` | `adminAccountTrial`/`Premium`/`Lifetime` | label |
| 630/640 | `Error loading stats` / `Retry` | `adminErrorLoadingStats` / `retry`(global) | Text |

`admin_login_screen.dart`:
| line | string | suggested key | sink |
|---|---|---|---|
| 186 | `Password reset email sent.` | `adminPasswordResetSent` | SnackBar |
| 198 | `Reset password` | `adminResetPasswordTitle` | title |
| 206 | `Enter your work email. We will send a reset link.` | `adminResetPasswordDesc` | content |
| 210 | `Work email` | `adminWorkEmailLabel` | labelText |
| 238/248 | `Cancel` / `Send link` | `cancel`(global) / `adminSendResetLink` | label |
| 435 | `Authorized staff only. Activity is logged.` | `adminAuthorizedStaffNotice` | Text |
| 611 | `Remember this device` | `adminRememberDevice` | label |
| 623 | `Forgot password?` | `adminForgotPassword` | Text |
| 793 | `Continue with Google Workspace` | `adminContinueGoogleWorkspace` | label |
| 954 | `BookBed Admin Console` | `adminConsoleTitle` | Text |
| 978 | `v2.4 · Internal tool · © $year BookBed Inc.` | `adminConsoleFooter` (placeholder `year`) | Text |

`admin_shell_screen.dart`:
| line | string | suggested key | sink |
|---|---|---|---|
| 57/63/69 | `Dashboard` / `Users Management` / `Activity Log` | `adminNavDashboard`/`adminNavUsers`/`adminNavActivity` | nav label |
| 250,469 | `Light Mode` / `Dark Mode` | `adminLightMode` / `adminDarkMode` | label |
| 258,525 | `Sign Out` (+ email variant) | `adminSignOut` | label |
| 409 | `Admin Portal` | `adminPortalTitle` | Text |
| 432 | `MAIN MENU` | `adminMainMenu` | Text |
| 508,664 | `Admin` | `adminRoleLabel` | Text |
| 645 | `Menu` | `adminMenuTooltip` | tooltip |

`users_list_screen.dart`:
| line | string | suggested key | sink |
|---|---|---|---|
| 181/183 | `Users Management` / `Manage platform owners and licenses` | `adminUsersTitle` / `adminUsersSubtitle` | Text |
| 192/269/315/351,527 | `Refresh`/`Clear`/`Retry`/`Load more` | `refresh`/`clear`/`retry`/`adminLoadMore` | label |
| 309 | `Error loading users: $err` | `adminErrorLoadingUsers` (ph `err`) | Text |
| 466-470 | `Name`/`Email`/`Account Type`/`Created At`/`Actions` | `adminColName`/`Email`/`AccountType`/`CreatedAt`/`Actions` | header |
| 513 | `View Details` | `adminViewDetails` | label |
| 603 | `No users found` | `adminNoUsersFound` | Text |
| 643/645/648 | `Sort: Created`/`Sort: Name`/`Sort: Email` | `adminSortCreated`/`Name`/`Email` | label |

`user_detail_screen.dart`:
| line | string | suggested key | sink |
|---|---|---|---|
| 105 | `User not found` | `adminUserNotFound` | Text |
| 227 | `Back to users` | `adminBackToUsers` | label |
| 413/417/462 | `Cancel`/`Confirm`/`Dismiss` | `cancel`/`confirm`/`adminDismiss` | label |
| 484/492/499/506/512 | `User Information`/`User ID`/`Email`/`Role`/`Created At` | `adminUserInfo`/`adminUserId`/`email`/`adminRole`/`adminCreatedAt` | label |
| 578 | `Copied to clipboard` | `copiedToClipboard` | SnackBar |
| 621/631/644 | `Statistics`/`Properties`/`Bookings` | `adminStatistics`/`properties`/`bookings` | label |
| 740 | `Account Status` | `adminAccountStatus` | Text |
| 773/782/791 | `Activate`/`Suspend`/`Reset to Trial` | `adminActivate`/`adminSuspend`/`adminResetTrial` | label |
| 836 | `Admin Controls` | `adminControls` | Text |
| 915 | `Revoke License` / `Grant License` | `adminRevokeLicense` / `adminGrantLicense` | label |
| 939 | `Something went wrong` | `adminSomethingWrong` | Text |

`activity_log_screen.dart`:
| line | string | suggested key | sink |
|---|---|---|---|
| 44/52 | `Activity Log` / `Admin actions and security events` | `adminActivityTitle` / `adminActivitySubtitle` | Text |
| 63/128 | `Refresh`/`Retry` | `refresh`/`retry` | label |
| 88/94 | `No activity yet` / `Admin actions will appear here` | `adminNoActivity` / `adminNoActivityHint` | Text |
| 124 | `Error loading activity log: $err` | `adminErrorLoadingActivity` (ph `err`) | Text |
| 255/261/267 | `Lifetime License Granted`/`Revoked`/`User Status Changed` | `adminEventLicenseGranted`/`Revoked`/`StatusChanged` | Text |
| 196/216/227 | `User: $targetEmail` / `ID: $targetUserId` / `Admin: $adminUid` | `adminEventUser`/`adminEventId`/`adminEventAdmin` (ph) | Text |

### 2B. OWNER — top clusters (verbatim sample; full list in tool output, ~275 lines)

`owner_booking_detail_screen.dart` (✓import) — **38 hits**, the single largest owner file:
| line | string | suggested key | sink |
|---|---|---|---|
| 237 | `Rezervacija #$reference` | `bookingDetailRefTitle` (ph `reference`) | Text |
| 253/258 | `Ispis` / `Podijeli` | `print`/`share` | tooltip |
| 562 | `Ova rezervacija čeka vaše odobrenje` | `bookingDetailAwaitingApproval` | Text |
| 628/636 | `Email` / `Nazovi` | `email`/`bookingDetailCall` | tooltip |
| 721-743 | `Boravak`/`Objekt`/`Jedinica`/`Dolazak`/`Odlazak`/`Trajanje`/`Gosti`/`Izvor` | `bookingDetailStay`/`Property`/`Unit`/`CheckIn`/`CheckOut`/`Duration`/`Guests`/`Source` | title/label |
| 786 | `Napomena gosta` | `bookingDetailGuestNote` | title |
| 977/985/1011 | `Odobri rezervaciju`/`Odbij`/`Uredi` | `bookingDetailApprove`/`reject`/`edit` | label |
| 1027/1038 | `Označi kao završenu` / `Otkaži rezervaciju` | `bookingDetailMarkComplete`/`Cancel` | label |
| 1200/1209/1215 | `Plaćanje`/`Ukupno`/`PLAĆENO (POLOG)` | `bookingDetailPayment`/`Total`/`DepositPaid` | title/label |
| 1357/1372/1394 | `Aktivnost`/`Rezervacija primljena`/`Rezervacija otkazana` | `bookingDetailActivity`/`Received`/`Cancelled` | title |
| 1527/1529/1534 | `Broj rezervacije`/`Kreirano`/`Kanal` | `bookingDetailRefNumber`/`Created`/`Channel` | label |

`dashboard_overview_tab.dart` (✓import) — **29 hits**:
| line | string | suggested key | sink |
|---|---|---|---|
| 367/374 | `Mon`,`Tue`,`Wed`,`Thu`,`Fri`,`Sat`,`Sun` (weekday axis) | `weekdayShortMon`… (or use intl) | label — **EN, see §3** |
| 578 | `Ključni pokazatelji` | `dashboardKpiTitle` | title |
| 860-863 | `7 dana`/`30 dana`/`90 dana`/`Godina` | `dashboardRange7d`/`30d`/`90d`/`Year` | label |
| 958,981 | `Nova rezervacija` | `dashboardNewBooking` | label/Text |
| 1413/1433 | `Sljedećih 14 dana` / `Kalendar` | `dashboardNext14Days`/`calendar` | Text |
| 1446 | `Nema dolazaka u sljedećih 14 dana.` | `dashboardNoArrivals14d` | Text |
| 2239/2263 | `Odbaci` / `Primjeni` | `dismiss`/`apply` | Text |
| 2521 | `/ €${expected.toStringAsFixed(0)} očekivano` | `dashboardExpectedSuffix` (ph) | Text |
| 2572 | `€${outstanding…} na dolasku` | `dashboardOutstandingArrival` (ph) | Text |

`subscription_screen.dart` (✓import) — **21 hits** (incl. EN leaks §3):
| line | string | suggested key | sink |
|---|---|---|---|
| 229,750 | `Nadogradi na Pro` | `subscriptionUpgradeToPro` | label |
| 289/300/316 | `VAŠ PLAN`/`Probni period`/`Pro značajke` | `subscriptionYourPlan`/`TrialPeriod`/`ProFeatures` | Text |
| 388 | `do 10.06.` | `subscriptionUntilDate` (ph `date`) | Text |
| 473/478 | `Mjesečno`/`Godišnje` | `subscriptionMonthly`/`Yearly` | label |
| 641/643/652 | `Besplatno`/`Nakon probe`/`Za prve korake` | `subscriptionFree`/`AfterTrial`/`ForFirstSteps` | Text |
| 663 | `Trenutni plan nakon probe` | `subscriptionCurrentAfterTrial` | label |
| 704/707/770 | `Pro`/`Za ozbiljne iznajmljivače`/`Preporučeno` | `subscriptionProName`/`ProTagline`/`Recommended` | Text |
| 899/909 | `Plan nakon isteka probe · 1 jedinica` / `Zadrži besplatno` | `subscriptionPlanAfterExpiry`/`KeepFree` | Text/label |

`stripe_connect_setup_screen.dart` (✓import) — **15 hits**: `DOSTUPNO ZA ISPLATU` / `U OBRADI` / `ISPLAĆENO (SVIBANJ)` (1039/1047/1054 → `stripeAvailablePayout`/`Processing`/`PaidOutMonth`), `Raspored isplata` (1178 `stripePayoutSchedule`), `Učestalost isplata` / `Automatski · 2 radna dana` (1185/1186), `Minimalni iznos isplate` (1193), `Obavijest o svakoj isplati` / `Email kad isplata krene prema banci` (1201/1202), `Nedavne isplate` (1286 `stripeRecentPayouts`), `Isplaćeno`/`U obradi` (1374). **`ISPLAĆENO (SVIBANJ)` hardcodes the month name "svibanj"** — needs a date placeholder.

`profile_screen.dart` (✓import) — **15 hits**: `Aplikacija`(397)/`Pravno`(429)/`OPASNA ZONA`(448 `profileDangerZone`)/`RAČUN · VLASNIK`(541)/`Domaćin`(676)/`Član od $memberSinceYear`(697)/`Email potvrđen`(709)/`Telefon dodan`(716)/`Dovršite profil`(895)/`Dovrši`(918)/`Probni period`(1123)/`OCJENA DOMAĆINA`(1286)/`STOPA ODGOVORA`(1294)/`VRIJEME ODGOVORA`(1302)/`ZAVRŠENE REZERVACIJE`(1309). Keys `profileApp`/`profileLegal`/`profileHostRating`…

`bookings_premium_header.dart` (✓import) — **13 hits**: `Na čekanju`/`Potvrđeno (mj.)`/`Zarada (mj.)`/`Nadolazeći` (287-311), `BookBed AI`/`Prioritet danas` (521/531), `Kasnije`/`Odgovori` (575/599), `Zahtijeva vašu pažnju` (645), `POLOG PLAĆEN`/`Preostalo na dolasku` (877/919). Keys `bookingsHeaderPending`/`Confirmed`/`Earnings`/`Upcoming`/`Later`/`Reply`…

`enhanced_login_screen.dart` (✓import) — **8 hits**: `OWNER APLIKACIJA`(811)/`Sve vaše rezervacije.\nJedno mjesto.`(816)/`Booking.com, Airbnb i vlastiti widget — sinkronizirano …`(827)/`aktivnih vlasnika`(838)/`rezervacija godišnje`(839)/`© 2026 BookBed Inc.`(851)/`Uvjeti`(865)/`Privatnost`(880). Keys `loginHeroEyebrow`/`loginHeroTitle`/`loginHeroSubtitle`/`loginStatActiveOwners`/`loginStatBookingsYear`. (Note `© 2026` hardcodes the year.)

`enhanced_register_screen.dart` (✓import) — **7 hits**: `OWNER APLIKACIJA`(793)/`Počnite upravljati\nu nekoliko minuta.`(798)/`Dodajte jedinice, povežite kanale…`(809)/`aktivnih vlasnika`(847)/`rezervacija godišnje`(848) + EN `Creating your account...`(362 §3). Reuse `loginHeroEyebrow`/`loginStat*`; add `registerHeroTitle`/`registerHeroSubtitle`.

Other owner files (2-8 hits each, all ✓import unless noted): `widget_settings_screen.dart`(8), `embed_code_generator_dialog.dart`(8), `month_calendar_screen.dart`(7), `embed_widget_guide_screen.dart`(5), `bookings_ledger.dart`(5, **no import**), `booking_block_widget.dart`(4, no import), `calendar_state_builders.dart`(4, no import — §3), `month_calendar_kpi_strip.dart`(4, no import), `language_selection_bottom_sheet.dart`(4), `bank_account_screen.dart`(3), `ical_export_list_screen.dart`(3), `owner_timeline_calendar_screen.dart`(3), `calendar_filters_panel.dart`(3), `calendar_search_dialog.dart`(3), `enhanced_booking_drag_feedback.dart`(3, no import), `ical_sync_premium_header.dart`(3, no import), `about_screen.dart`(2), `ai_assistant_screen.dart`(2), `faq_screen.dart`(2), `booking_create_dialog.dart`(2), `booking_action_menu.dart`(2), `booking_inline_edit_dialog.dart`(2), `calendar_top_toolbar.dart`(2), `edit_booking_dialog.dart`(2), `ical_export_premium_header.dart`(2, no import), `owner_app_drawer.dart`(2), `price_list_calendar_widget.dart`(2), `timeline_calendar_widget.dart`(2 — §3), `widget_live_preview_section.dart`(2), `trial_banner.dart`(5, no import — §3), `profile_image_picker.dart`(1, no import).

### 2C. WIDGET — only the strings that BYPASS `WidgetTranslations`

| file:line | string | suggested fix | sink |
|---|---|---|---|
| popup_blocked_dialog.dart:61 | `Your browser blocked the payment popup. To complete…` | `WidgetTranslations.popupBlockedBody` | Text — **EN leak** |
| popup_blocked_dialog.dart:73/82/92 | `Open Payment Page`/`Copy Payment Link`/`Try Again` | `tr.popupOpenPayment`/`CopyLink`/`TryAgain` | title — **EN** |
| popup_blocked_dialog.dart:74/83/93 | `Opens Stripe Checkout in a new tab` / `Copy link to share…` / `Allow popups and try…` | `tr.popup*Desc` | description — **EN** |
| popup_blocked_dialog.dart:106 | `Cancel` | `tr.cancel` | TextButton — **EN** |
| popup_blocked_dialog.dart:183/192 | `Payment link copied to clipboard` / `Could not copy link…` | `tr.popupLinkCopied`/`CopyFailed` | SnackBar — **EN** |
| booking_widget_screen.dart:3085/3095 | `Property ID is missing. Please refresh the page.` / `Owner ID…` | `tr.errorPropertyIdMissing`/`OwnerIdMissing` | error — **EN** |
| booking_widget_screen.dart:3240 | `The price has been updated since you started booking.\n…` | `tr.priceChangedNotice` | dialog — **EN** |
| widget_mode.dart:18/19 | `Rezervacija bez plaćanja` / `Puna rezervacija sa plaćanjem` | `widgetModeManualLabel`/`InstantLabel` (rendered in owner `widget_settings_screen`) | enum label (HR) |
| widget_mode.dart:25/27/29 | `Gosti vide samo dostupnost…` / `…čeka vašu potvrdu…` / `…odmah rezervisati…` | `widgetModeManualDesc`/`PendingDesc`/`InstantDesc` | enum desc (HR) |
| tax_legal_config.dart:~ | (1 default-value literal) | verify if UI-rendered | borderline |

> Note: `widget_mode.dart` labels are HR but live in `lib/features/widget/domain/models/` and are surfaced in the **owner** settings screen → could go to System A (`AppLocalizations`) instead of System B.

### 2D. SHARED (`lib/core/widgets`)

| file:line | string | suggested key | sink |
|---|---|---|---|
| bb_input.dart:136 | `Prikaži` / `Sakrij` (password reveal) | `show`/`hide` | IconButton tooltip |
| fcm_navigation_handler.dart:121 | `View` | `view`(global) | notification action — **EN leak** |

(`bb_input.dart:232` `$_length / $maxLength` and `owner_app_loader.dart:96` `$pct%` are pure numeric/format — excluded, see §5.)

---

## 3. EN-in-HR-UI leaks — PRIORITY (English strings shipping in a Croatian app)

Detected via a strict filter (≥2 English function-words, no Croatian diacritic). **76 strict leaks**, dominated by admin (whole surface). The non-admin leaks are the most jarring because they sit inside otherwise-Croatian screens:

| Priority | file:line | leaked string | surface |
|---|---|---|---|
| **P0** | **entire `lib/features/admin/**` (6 screens + 4 main titles)** | ~80 English strings (`Dashboard Overview`, `Total Owners`, `Sign Out`, `View Details`, `No users found`, `Something went wrong`…) | admin |
| **P1** | popup_blocked_dialog.dart:61,73-93,106,183,192 | full English popup-blocked dialog (`Open Payment Page`, `Copy Payment Link`, `Try Again`, `Cancel`, body + 3 descriptions + 2 snackbars) | **widget (guest-facing!)** |
| **P1** | booking_widget_screen.dart:3085,3095,3240 | `Property ID is missing. Please refresh the page.`, `Owner ID is missing…`, `The price has been updated since you started booking.` | **widget (guest-facing!)** |
| **P2** | subscription_screen.dart:191,201 | `Could not open browser. Please visit …` | owner |
| **P2** | subscription_screen.dart:430,432 | `Upgrade to Pro`, `Pro subscription coming soon! We're working on integrating …` | owner |
| **P2** | trial_banner.dart:218 | `Expired`, `$daysRemaining days` ("days" is English) | owner |
| **P2** | enhanced_register_screen.dart:362 | `Creating your account...` | owner (auth) |
| **P2** | timeline_calendar_widget.dart:1451,1479 | `Unable to generate date range for timeline. Please refresh the page.`, `Invalid timeline dimensions. Please refresh the page.` | owner |
| **P2** | calendar_state_builders.dart:21,24 | `No units found`, `Add units to your properties to see them in the calendar` | owner |
| **P3** | dashboard_overview_tab.dart:367,374 | weekday axis `Mon…Sun` | owner (borderline — could be intl-driven, see §5) |
| **P3** | core/widgets/fcm_navigation_handler.dart:121 | `View` | shared (notification action) |

**Top-5 highest-impact (recommended first wave):**
1. **Admin surface** — full English app; `admin*` keys partly exist already → biggest win, lowest risk.
2. **`popup_blocked_dialog.dart`** — fully-English dialog shown to paying *guests* mid-checkout.
3. **`booking_widget_screen.dart` guest error toasts** — English errors at the booking moment.
4. **`subscription_screen.dart`** — mixed HR/EN ("Upgrade to Pro", "coming soon") on a monetization screen.
5. **`owner_booking_detail_screen.dart` (38 HR stragglers)** — biggest single un-migrated owner screen (HR, but hardcoded).

---

## 4. Notable clusters (whole screens / files essentially unlocalized)

- **ALL of `lib/features/admin/`** — `admin_dashboard_screen`, `admin_login_screen`, `admin_shell_screen`, `users_list_screen`, `user_detail_screen`, `activity_log_screen`, + the 4 `admin_main*.dart` titles. English, ~105 strings. The `admin*` .arb keys exist but are unwired (premium-redesign rewrite skipped them).
- **`popup_blocked_dialog.dart`** — 100% hardcoded English, guest-facing, bypasses `WidgetTranslations` entirely.
- **`owner_booking_detail_screen.dart`** — 38 HR literals (largest owner straggler), despite importing `AppLocalizations`.
- **`dashboard_overview_tab.dart`** — 29 literals (HR body + EN weekday axis).
- **`subscription_screen.dart`** — 21 literals, HR/EN mix.
- **`stripe_connect_setup_screen.dart` / `profile_screen.dart` / `bookings_premium_header.dart`** — 13-15 HR literals each (premium dashboard widgets added post-l10n-baseline).
- **Login/Register hero panels** (`enhanced_login_screen` / `enhanced_register_screen`) — the marketing hero copy (`OWNER APLIKACIJA`, stat strings, footer) is hardcoded HR though the forms themselves are localized.

---

## 5. Borderline EXCLUSIONS (reviewer sanity-check list)

Items I deliberately did **not** flag (or down-ranked), with rationale:

- **`widget_translations.dart` body (~168 literals)** — this IS the translation source for System B; flagging it would be circular. Excluded.
- **`*.freezed.dart` / `*.g.dart`** — generated; literals there are field-name/`toString` artifacts. Excluded (e.g. `unified_dashboard_data.freezed.dart:..`).
- **Pure interpolation / numeric / format strings** — `'$_length / ${widget.maxLength}'`, `'${pct}%'`, `'ID: $_stripeAccountId'`, `'$email · $phone'`, `'${p.ref} · ${p.date}'`. These are data composition, not translatable copy (the *separators* like `·` are not language-specific). Down-ranked / excluded.
- **Weekday short labels `Mon…Sun`** (dashboard_overview_tab:367/374) — flagged as **P3** not P1: these are 3-letter chart-axis labels and arguably should come from `intl` `DateFormat.E()` rather than a hand key; reviewer should decide intl-vs-key.
- **Brand / proper nouns** — `BookBed`, `BookBed AI`, `Booking.com`, `Airbnb`, `STRIPE`, `Stripe Checkout`, `Pro` (plan name). Not translated. (`Pro` appears in keys only as a fixed product name.)
- **`© 2026 BookBed Inc.` / `© $year BookBed Inc.`** — flagged for the *year-hardcoding* concern, but the copyright line itself is borderline-translatable (`Sva prava pridržana` already has a key `adminFooterCopyright`). Left as low-priority.
- **Log/telemetry strings** — every `LoggingService.*`, `debugPrint`, `[PaymentComplete] …`, Sentry breadcrumbs (e.g. all the `'STRIPE'`-tagged lines in `booking_confirmation_screen.dart`). Not user-facing. Excluded by filter.
- **DB/enum key strings** — single lowercase tokens (`'owner'`, `'pending'`, `'bank_transfer'`) used as Firestore values, not labels. Excluded by the "userfacing" heuristic (single lowercase word).
- **`MaterialLocalizations.of(context).closeButtonTooltip`** etc. — already localized by Flutter's built-in delegate. GOOD, not flagged.
- **`tax_legal_config.dart`** default-value literal — listed as borderline; needs a 5-second eyeball to confirm whether it reaches a `Text()` (likely a non-rendered default). Reviewer should verify.

---

### Method note
Heuristic extractor (Python, in sandbox): match string literals adjacent to UI sinks (`Text(`, `SelectableText(`, `hintText:`, `labelText:`, `helperText:`, `errorText:`, `tooltip:`, `message:`, `semanticLabel:`, `title:`, `content:`, `label:`, `subtitle:`, `hint:`), keep only "user-facing" literals (Croatian diacritic OR multi-word OR Capitalized≥3-char word), drop the ignore-list (keys, assets, packages, URLs, fonts, log/Sentry, imports, comments, pure-interpolation). EN-leak filter additionally required ≥2 English function-words and no Croatian diacritic. Representative samples manually verified per surface. Counts are "flagged hits" (a multi-occurrence line counts each literal); distinct-string counts are lower.
