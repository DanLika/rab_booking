# Golden net (P6 — `test/golden-net`)

A pixel-baseline regression net for the BookBed UI. Its job is to catch
**unintended** visual changes when work is applied in parallel — render a
subject, compare against a committed PNG, fail on any diff.

> Note: the repo `.gitignore` ignores `*.md` (only `README.md` is negated), so
> this file is the single tracked doc for the net — the deferred-coverage plan
> lives at the bottom rather than in a separate `DEFERRED.md`.

## Matrix

Every golden runs **4 variants**: light/dark × **mobile(390)** / **tablet(768)**
— see `kGoldenVariants` in `test/helpers/golden_harness.dart`. The owner surface
is Croatian-first, so baselines render in the `hr` locale.

## Layout

```
test/golden/
  screens/   full screens captured at the device viewport (goldenScreen)
  seams/     focused surfaces from @visibleForTesting builders, captured whole
             on a tall surface (goldenSurface)
  */goldens/ committed baseline PNGs (one per subject × variant)
```

Two harness entry points (`test/helpers/golden_harness.dart`):

| helper | capture | use for |
|---|---|---|
| `goldenScreen(name, build:)` | device viewport (clips below fold — realistic) | self-contained / static screens |
| `goldenSurface(name, build:)` | whole subject on a tall surface (RepaintBoundary) | premium panels/chrome from a `buildXForTest` seam |

Deterministic mock data lives in `test/helpers/golden_fixtures.dart` (no
`DateTime.now()`, no randomness).

## Running

```bash
# Verify nothing moved (the net):
flutter test --tags golden

# Re-bless baselines after an INTENTIONAL visual change (review the diff!):
flutter test --tags golden --update-goldens
```

## Isolation — scoped re-bless is safe

The UI's text is `GoogleFonts.inter(...)` / `jetBrainsMono` (via `BBType.*`).
google_fonts loads each (family, weight) lazily from the asset bundle the first
time that variant is requested, through a fire-and-forget async
`loadFontIfNecessary` (it is a different family from `loadGoldenFonts`' own
`FontLoader('Inter')`, so that registration doesn't cover it). `tester.pump()`
advances only **fake** time, so within a cell a just-requested variant may still
be mid-load and lays out as tofu. A full run is masked — an earlier subject kicks
the loads and they land (real async, between tests) before the subject's turn —
but a NAME-SCOPED re-bless renders its subject's `mobile_light` first, so its
variants (e.g. the w500 `BBType.label` field labels) are still loading.

The harness closes this: `_warmGoldenAtlas` (in
`test/helpers/golden_harness.dart`) runs once per isolate under `tester.runAsync`
(real async), requests every weight the UI uses, then awaits
`GoogleFonts.pendingFonts()` so they all land before the first real cell. Each
cell is now independent of execution order, so

```bash
# Scoped re-bless / verify of a single subject is deterministic:
flutter test --tags golden --plain-name "profile_change_password"
```

renders warm and matches the (warm-blessed) baseline. It covers Inter 300–700 +
mono 500 (every weight `BBType` uses); if a future subject tofus a NEW variant as
its isolate's first cell, request that variant there too.

## Make it an ACTIVE gate (run it, or it never fires)

The net is macOS-local — deliberately NOT in CI — so it only protects you if it
is actually run. Fold it into each design apply's **pre-merge ritual on macOS**:
run the affected subject's golden, confirm the diff is the INTENDED change (or
none), then merge. CI excludes the `golden` tag
(`flutter test --exclude-tags golden`, wired in `.github/workflows/ci.yml`), so
nothing here runs on the Linux runner — that is what keeps the net from poisoning
CI, and also what makes running it locally non-optional.

## ⚠️ Baselines are macOS-rasterised — keep them out of cross-platform CI

Font hinting / anti-aliasing differs per OS, so a baseline blessed on macOS will
mismatch on a Linux CI runner even with identical code. These tests are tagged
`golden`; exclude them from the shared CI lane:

```bash
flutter test --exclude-tags golden
```

To run the net in CI, pin a single OS image and bless baselines on it (a
follow-up; not wired here). Until then this is a **local** net — run it on the
same machine that blessed the baselines, after any visual change, and eyeball
the failure PNGs that Flutter writes to `<test>/goldens/failures/`.

---

# Coverage + deferred plan

Covered today — **13 subjects × 4 variants = 52 stable baselines**:

* **Premium focused-surfaces** (via existing `@visibleForTesting` builders):
  `pregled_panel`, `timeline_chrome`, `month_chrome`, `ai_conversation`.
  `pregled_panel` + `timeline_chrome` pin a test-only `now` (their greeting /
  eyebrow-date / "today" badge read `DateTime.now()` in production — without the
  pin they false-red as the clock advances).
* **Self-contained full screens**: register, forgot-password, change-password,
  FAQ, embed-help, about, subscription, stripe-connect, not-found.

Everything below is **out of this pass** with the reason + the concrete way in.

## 1. Dropped because non-deterministic

| Subject | Why | Existing coverage |
|---|---|---|
| `booking_detail` | Renders a `DateTime.now()`-derived string (arrival countdown / activity timestamps); pixels differ between the bless and the compare run. | `owner_booking_detail_layout_test.dart` — overflow across 9 breakpoints × 2 themes × 4 statuses. |
| `legal_privacy_policy` / `legal_terms_conditions` | Footer renders `DateTime.now().year` (annual drift). | — |
| `legal_cookies_policy` | Renders the full `DateTime.now()` date (daily drift). | — |

**On the 3 legal pages (deferred, not seamed):** they were green only because
bless-day == run-day. Unlike `pregled` / `timeline` — high-value premium surfaces
worth a `@visibleForTesting now` param — a static legal page adds little golden
value, so the cheap move is to drop them rather than add a product `now` param to
each. **Way in:** make the displayed date injectable (param or `clock.now()`),
then re-add a `goldenScreen` per page.

**Way in (booking_detail):** thread an injectable clock (`package:clock`
`withClock`) through the detail's relative-time helpers so the test can pin "now",
then golden via `buildBookingDetailContentForTest`.

## 2. Provider-heavy screens — need a seam OR override fixture

Can't be pumped full-screen hermetically (Firestore reads / `enhancedAuthProvider`
`StateNotifier`, which can't be faked — memory `seam-test-proves-fn-not-wiring`).
The project pattern is a `@visibleForTesting buildXForTest` returning the premium
body without Scaffold/drawer/providers — mirror it.

| Screen | Blocker | Seam plan |
|---|---|---|
| `OwnerBookingsScreen` | 24+ providers, 1.5 s Timer init | seam over the ledger body taking a `List<OwnerBooking>` (ledger is already pure — `bookings_ledger.dart`) |
| `BookingWidgetScreen` (widget) | 27+ providers, realtime, widget i18n | seam over calendar+price+form body taking availability/price/`WidgetSettings` fixtures; override `languageProvider` |
| `DashboardOverviewTab` (full) | auth + dashboard providers | panel **already** goldened (`pregled_panel`); full-screen adds only AppBar/drawer chrome |
| `ProfileScreen` / `EditProfileScreen` | `enhancedAuthProvider` (4×) | seam over the form body taking a `UserModel` fixture |
| `PropertyFormScreen` / `UnitFormScreen` / `UnitWizardScreen` / `UnitPricingScreen` | property/unit providers + Firestore | seam over the form body taking a model fixture (wizard: per-step) |
| `NotificationsScreen` / `NotificationSettingsScreen` | Firestore realtime / prefs | override the provider with a fixed list |
| `WidgetSettingsScreen` / `WidgetAdvancedSettingsScreen` | widget-settings provider | override `widgetSettingsProvider` with a fixture |
| `BankAccountScreen` | `companyDetailsProvider` (stream) | override with `Stream.value(CompanyDetails())` — pattern in `bank_account_screen_test.dart` |
| `IcalSyncSettingsScreen` / `IcalExportListScreen` | iCal feed providers | override the feed provider with a fixed list |
| `UnifiedUnitHubScreen` | `unifiedUnitsProvider` | override with a fixed unit list (Cjenovnik tab is FROZEN — golden it as a lock) |

## 3. Auth/redirect screens — override the notifier, then golden

`EnhancedLoginScreen`, `EmailVerificationScreen`, `AdminLoginScreen` (admin dark
theme) — pre-auth, overridable with an idle `enhancedAuthProvider` fixture.

## 4. Admin surface — override fixtures

`AdminDashboardScreen`, `UsersListScreen`, `UserDetailScreen`, `ActivityLogScreen`
— each watches a paginated Firestore provider. Override with fixed pages; golden
under the admin dark theme (`BbAdminDarkTokens.preset`).

## 5. Widget surface — args + widget i18n

`BookingConfirmationScreen` (6 required args — feed a fixture), `BookingViewScreen`
/ `BookingDetailsScreen` (booking-lookup provider), `SubdomainNotFoundScreen`
(`subdomain` arg + `languageProvider` override), `EmbedWidgetGuideScreen`
(snippet provider).

## 6. Intentionally skipped

* `OwnerSplashScreen` — infinite entrance animation; a frozen frame is low-value.
* `BBGalleryScreen` / `BBResponsiveProbeScreen` — dev-only design showcases
  (could be a useful primitive-level golden later).

## Known cosmetic

A few **variant action-glyphs** (e.g. `Icons.copy_rounded`, the password
visibility toggle) rasterise as outline squares at small sizes. Base
MaterialIcons + Material Symbols render correctly (person/email/phone/lock are
sharp), and the squares are **consistent** between bless and compare — so the net
is unaffected. Optional fidelity fix: `FontLoader` the rounded/outlined
MaterialIcons variants alongside the base font in `loadGoldenFonts`.
