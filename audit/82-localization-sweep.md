# audit/82 — Localization sweep (close audit/71 §4.4 / §4.9 / §4.23)

**Date:** 2026-05-28
**Branch:** `redesign/02-localization-sweep`
**Worktree:** `/tmp/bb-rd-02-wt`
**Base:** `origin/main @ 6b52daa6` (post-#545)
**Scope:** Close every i18n gap audit/71 surfaced so redesign prompts 01-39 never reintroduce hardcoded EN strings.

---

## §1 TL;DR

| Fix | Where | Before | After |
|---|---|---|---|
| 1. Syncfusion calendar EN headers (Backward/Forward, S M T W T F S) | `month_calendar_screen.dart` + `main.dart` + `pubspec.yaml` | EN day strip starting Sunday | HR day strip starting Monday |
| 2. Google auth button EN | `enhanced_login_screen.dart` + arb | hardcoded "Sign in with Google" | `l10n.signInWithGoogle` → "Prijava preko Googlea" |
| 3. Apple auth button EN | `enhanced_login_screen.dart` + arb | hardcoded "Sign in with Apple" | `l10n.signInWithApple` → "Prijava preko Applea" (new key) |
| 4. Admin login EN | `admin_login_screen.dart` + arb | 7 hardcoded EN strings | `l10n.adminWelcomeBack` etc. (11 new keys, all HR + EN) |
| 5. "Slug N/A" leak | `unified_unit_hub_screen.dart` + arb | literal `'N/A'` | `l10n.notSet` → "Nije postavljeno" |

| Check | Result |
|---|---|
| `flutter gen-l10n` | clean (regenerated AppLocalizations) |
| `flutter analyze lib/` | 92 infos (90 intentional `@Deprecated` bridge flags + 2 pre-existing); **0 errors, 0 warnings** ✅ |
| `flutter test --no-pub` | **+1205 All tests passed** ✅ |

---

## §2 Detailed changes

### 2.1 Syncfusion calendar HR locale + Monday start

**Bug class:** audit/71 §4.4 — Syncfusion `SfCalendar` Month-view header strip showed `S M T W T F S` (EN, Sunday first) while Owner-Dashboard timeline used `Pon Uto Sri Čet Pet Sub Ned` (HR, Monday first). User confusion.

**Root cause:** Syncfusion calendar reads locale strings via its own `SfGlobalLocalizations.delegate` — not the Material/Cupertino global delegates. The `syncfusion_localizations` package was NOT in `pubspec.yaml` and the delegate was NOT registered, so calendar fell through to English defaults regardless of `MaterialApp.locale: Locale('hr')`.

**Fix (3-part):**
1. `pubspec.yaml`: add `syncfusion_localizations: ^28.1.33` (version-matched to existing `syncfusion_flutter_calendar`).
2. `lib/main.dart`: import `package:syncfusion_localizations/syncfusion_localizations.dart` + add `SfGlobalLocalizations.delegate` to `MaterialApp.localizationsDelegates`.
3. `lib/features/owner_dashboard/presentation/screens/calendar/month_calendar_screen.dart` line 412-413: add `firstDayOfWeek: DateTime.monday` to `SfCalendar` (matches Timeline calendar).

**FROZEN compliance:** zero changes to calendar cell dimensions, `MonthViewSettings.appointmentDisplayMode`, `MonthCellStyle.textStyle.fontSize`, agenda heights, or any frozen dimension. Only `firstDayOfWeek` + delegate wiring (text rendering).

**Cjenovnik (`price_list_calendar_widget.dart`):** also uses `SfCalendar` — FROZEN per CLAUDE.md NIKADA NE MIJENJAJ. NOT touched. Delegate registration via `main.dart` auto-applies HR there too if/when it's re-enabled in future.

### 2.2 Google + Apple auth buttons

**Bug class:** audit/71 §4.9 — `enhanced_login_screen.dart:700/707` hardcoded `'Sign in with Google'` / `'Sign in with Apple'` despite l10n keys already existing for the former. Apple key didn't exist at all.

**Fix:**
- `lib/l10n/app_hr.arb` + `app_en.arb`:
  - Updated `signInWithGoogle` HR: "Prijavite se sa Google" → **"Prijava preko Googlea"** (natural Croatian declension)
  - Added `signInWithApple` (new key) — HR: **"Prijava preko Applea"** / EN: "Sign in with Apple"
  - Updated `continueWithGoogle` HR: "Nastavite s Google" → **"Nastavi preko Googlea"**
  - Updated `continueWithApple` HR: "Nastavite s Apple" → **"Nastavi preko Applea"**
- `enhanced_login_screen.dart:700,707`: replaced hardcoded strings with `l10n.signInWithGoogle` / `l10n.signInWithApple`.

### 2.3 Admin login screen

**Bug class:** audit/71 §4.23 — `admin_login_screen.dart` rendered all UI in English despite `admin_main_*.dart` correctly wiring `localizationsDelegates` + `Locale('hr')`. The screen just hardcoded English text.

**Fix:** 7 strings replaced; 11 l10n keys added (admin-namespaced to avoid collisions with owner-app keys for the same concepts where rendering may differ):

| Old EN literal | New l10n key | HR translation |
|---|---|---|
| `'Welcome Back'` | `adminWelcomeBack` | "Dobrodošli natrag" |
| `'Please sign in to access the admin portal.'` | `adminLoginSubtitle` | "Prijavite se za pristup administracijskom portalu." |
| `'Email Address'` | `adminEmailLabel` | "Email adresa" |
| `'admin@bookbed.io'` (hint) | `adminEmailHint` | (unchanged — proper-name) |
| `'Email is required'` | `adminEmailRequired` | "Email je obavezan" |
| `'Password'` | `adminPasswordLabel` | "Lozinka" |
| `'Password is required'` | `adminPasswordRequired` | "Lozinka je obavezna" |
| `'Sign In'` | `adminSignInButton` | "Prijava" |
| `'Access denied. Admin privileges required.'` | `adminAccessDenied` | "Pristup odbijen. Potrebne su administratorske ovlasti." |
| `'Login failed. Please check your credentials and try again.'` | `adminLoginFailed` | "Prijava nije uspjela. Provjerite svoje podatke i pokušajte ponovno." |
| `'© <year> BookBed Inc. All rights reserved.'` | `adminFooterCopyright(year)` | "© {year} BookBed Inc. Sva prava pridržana." (parameterized) |

`initState` `'Access denied'` literal was deferred to `didChangeDependencies` (l10n is not reachable in `initState`). Pattern: store the `'not_admin'` boolean in initState, resolve the localized string in didChangeDependencies.

### 2.4 "Slug N/A" → "Nije postavljeno"

**Bug class:** audit/71 §5.2 — `unified_unit_hub_screen.dart:1444` rendered literal `'N/A'` for missing unit slug. Confusing — looks like a "Not Applicable" status code rather than "this field is not set."

**Fix:** added `notSet` l10n key (HR: "Nije postavljeno" / EN: "Not set"), replaced fallback at line 1444.

The 6 other `'N/A'` occurrences in `lib/` (per audit/71 §5.2 grep) — left for follow-up. They're in calendar files (FROZEN) and widget/QR code path. Out of audit/82's stated scope.

### 2.5 Other audit/71 §5.2 items not in this PR

- **"Pay with Stripe" widget CTA EN** — audit/71 §5.2 explicitly notes "handled in prompt 28" — out of scope here.
- **More widget HR drift** — widget app uses a separate `widget_translations.dart` system (not AppLocalizations); migration to AppLocalizations is a larger refactor and not part of this audit-71-closure PR.

---

## §3 Files changed

```
M  pubspec.yaml                                                                          (+5 / -0)
M  pubspec.lock                                                                          (auto)
M  lib/main.dart                                                                         (+5 / -0)
M  lib/l10n/app_hr.arb                                                                   (+22 / -3)
M  lib/l10n/app_en.arb                                                                   (+22 / -3)
M  lib/l10n/app_localizations.dart                                                       (regenerated by flutter gen-l10n)
M  lib/l10n/app_localizations_hr.dart                                                    (regenerated)
M  lib/l10n/app_localizations_en.dart                                                    (regenerated)
M  lib/features/auth/presentation/screens/enhanced_login_screen.dart                     (2 lines: l10n.signInWithGoogle / signInWithApple)
M  lib/features/admin/presentation/screens/admin_login_screen.dart                       (~25 lines: import + initState/didChangeDependencies + 7 l10n refs)
M  lib/features/owner_dashboard/presentation/screens/calendar/month_calendar_screen.dart (+7 / -0: firstDayOfWeek + comment)
M  lib/features/owner_dashboard/presentation/screens/unified_unit_hub_screen.dart        (1 line: 'N/A' → l10n.notSet)
A  audit/82-localization-sweep.md                                                        (this file)
```

NOT touched: calendar FROZEN files (14 listed in audit/80b §2), Cjenovnik (`unit_pricing_screen.dart`, `price_list_calendar_widget.dart`), widget `widget_translations.dart` system.

---

## §4 Verification

```
$ cd /tmp/bb-rd-02-wt
$ git branch --show-current
redesign/02-localization-sweep
$ flutter pub get
Got dependencies! (added syncfusion_localizations: 28.1.33)
$ flutter gen-l10n
(silent — clean regenerated lib/l10n/app_localizations*.dart)
$ flutter analyze lib/
92 issues found (0 errors, 0 warnings, 92 infos — 90 intentional @Deprecated bridge flags from #543 + 2 pre-existing on main)
$ flutter test --no-pub
+1205: All tests passed!
```

### Visual spot-check (deferred to reviewer — no live device this session)
1. Owner Month calendar (`/calendar` route, Month view): header should now read **"Sij 2026 ▶"** or similar HR month name, day strip **Pon Uto Sri Čet Pet Sub Ned**, nav buttons **Natrag/Naprijed**. (Pre-PR: "Jan 2026", "S M T W T F S", "Backward/Forward").
2. Auth login (`/login`): Google button reads **"Prijava preko Googlea"**, Apple button **"Prijava preko Applea"**. (Pre-PR: "Sign in with Google", "Sign in with Apple").
3. Admin login (`admin.bookbed.io` or local admin dev): all text in HR. (Pre-PR: all EN).
4. Owner unit detail page where slug is unset: shows **"Nije postavljeno"**. (Pre-PR: "N/A").

### Croatian diacritics
ARB additions include `č ć đ š ž ć`. Inter (post-#545) renders all five. No diacritic-substitution required.

---

## §5 What this PR does NOT do

- Migrate `lib/features/widget/presentation/l10n/widget_translations.dart` to `AppLocalizations` (widget has its own translation system; large refactor).
- Translate `'N/A'` in the 6 remaining calendar / QR-code paths (calendar is FROZEN; QR code is widget-specific).
- Wire `SfGlobalLocalizations.delegate` into `admin_main_*.dart` or `widget_main_*.dart` (admin doesn't use SfCalendar; widget doesn't use SfCalendar). Only owner needs it.
- Translate `'Pay with Stripe'` widget CTA — audit/71 §5.2 notes this is handled in prompt 28.

---

## §6 Hand-off

After this PR merges:
- audit/71 §4.4 (Syncfusion EN headers), §4.9 (Google/Apple buttons EN), §4.23 (admin EN), §5.2 row 5 ("Slug N/A") — all CLOSED.
- Remaining §5.2 items (Pay with Stripe → prompt 28; widget HR drift → separate refactor) — explicitly out of scope.

Redesign prompts 01-39: when building new pages, MUST use `l10n.<key>` from AppLocalizations (not hardcoded literals). The pattern shown in admin_login_screen.dart (`final l10n = AppLocalizations.of(context);` then `l10n.adminEmailLabel` etc.) is canonical.
