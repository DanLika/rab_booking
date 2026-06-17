# audit/129 — owner Settings cluster (recon, READ-ONLY, DRAFT — not committed)

**Status:** 🔎 recon — read-only, awaiting operator scope decision
**Date:** 2026-06-17
**Branch:** `design/129-owner-settings` (off `origin/main 77b8c3a6`, post-127/128). Base-verified: `app_gradients` light `#F0F1F5` / dark OLED `#000` / card `#1E1E1E` ✓.

## TL;DR — "owner Settings" is a CLUSTER, and it's already MIGRATED

There is **no single `owner_settings_screen.dart`.** Settings = **9 screens** reached from the `profile_screen` hub (`/owner/profile`). The "unmigrated/legacy" assumption is **STALE** (same as booking-detail) — **every screen is already Bb*-migrated, hex=0, mostly `context.gradients`-wired, and the exemplar even cites the handoff in its comments.** This is NOT a migration job and does NOT warrant a booking-detail-scale campaign. Real work = **2 outliers + optional fidelity polish.**

## §1 — Per-screen fingerprint (all 9, design-system state)

| screen | LOC | Bb* | raw Material | hex | `context.gradients` | state |
|---|---|---|---|---|---|---|
| `profile_screen` (hub) | 1503 | 28 | 3 | 0 | ✓ | migrated; handoff = `profile-premium.jsx` |
| `edit_profile_screen` | 842 | 57 | 3 | 0 | ✓ | heavily migrated |
| `change_password_screen` | 639 | 18 | 1 | 0 | ✓ | migrated |
| `notification_settings_screen` | 382 | 20 | 1 | 0 | ✓ | **premium + handoff-aware** (exemplar) |
| `bank_account_screen` | 596 | 31 | 3 | 0 | **✗ grad=0** | migrated but ⚠️ no `pageBackground` |
| `about_screen` | 537 | 24 | 1 | 0 | ✓ | migrated |
| `widget_settings_screen` | 1625 | 28 | 1 | 0 | ✓ | migrated |
| `widget_advanced_settings_screen` | 459 | **6** | **8** | 0 | ✓ | ⚠️ **LEGACY outlier** |
| `ical_sync_settings_screen` | 1654 | 52 | 2 | 0 | ✓ | heavily migrated |

**hex = 0 across the entire cluster** — no hardcoded colors anywhere.

## §2 — Exemplar: `notification_settings_screen` (382 LOC) is DONE

`CommonAppBar` + `context.gradients.pageBackground` + `ConstrainedBox(680)` + `BbCard`(accentLeft info/error) + `BbSwitch` + `BbSectionHeader` + `BbIcon` + `BbEmptyState`, full l10n. Comments cite `settings.jsx §381 SInfoBanner` / `§305 NotifTable` — built to the handoff. Divergences are **minor / data-honest**: single wired category (payments) renders compact vs the handoff's full NotifTable grid (bookings removed, calendar/marketing unwired — documented); no QuietHours (unwired). Nits: 1 hardcoded HR string (`:217`), `Container(36×36)` icon-tile magic, `fontSize: 13/10` overrides.

## §3 — The 2 real outliers

- **S1 · `widget_advanced_settings_screen` — LEGACY (HIGH yield).** Bb=6/Mat=8. Its own comment (`:348`): *"hand-rolled `Container(gradient) + Material + InkWell + Icons.check`"* — bespoke selection chrome + a **hand-rolled gradient** (flatten target) instead of Bb* primitives. This is the only screen that genuinely needs migration.
- **S2 · `bank_account_screen` — grad=0 (LOW-risk hygiene).** `body: Container(...)` (`:476`) does **not** consume `context.gradients.pageBackground` — the lone §2-class straggler (cf. audit/126). Should inherit the flat palette like its siblings.

## §4 — Hub: `profile_screen` (1503 LOC)

The account/settings hub. Groups: **Account** (Edit Profile→`profileEdit`, Change Password→`profileChangePassword`, Notifications, Subscription, **Language toggle**, **Theme toggle**), **App** (Help/Support, About→`about`; group title `'Aplikacija'` hardcoded `:397`), **Legal** (Terms→`termsConditions`…). Custom `_ProfilSettingsGroup` (BbCard + BbSectionHeader + rows). Handoff = `profile-premium.jsx` (489 LOC, premium).

## §5 — Handoff coverage (both exist)

- `settings.jsx` (401) → **EditProfile · ChangePassword · NotificationSettings** (3 forms; primitives `SettingsScaffold`/`SFormSection`/`SToggle`/`SPasswordField`/`SStrengthMeter`/`SReqList`/`NotifTable`/`QuietHours`/`SInlineSaveBar`).
- `profile-premium.jsx` (489) → **Profile/account hub** (premium).
- Renders deferred to apply (per chosen screen) — recon scoped to the system map, not pixels.

## §6 — FROZEN check

- **No** Cjenovnik/pricing or Unit-Wizard touch (those live in `unified_unit_hub`, not the settings cluster).
- Inter-screen nav = go_router `context.push` — **not** the FROZEN widget `Navigator.push` confirmation. Clean.
- ⚠️ **`widget_advanced` / `widget_settings` touch WIDGET config** — adjacent to FROZEN surfaces (subdomain-validation regex, App-Check-OFF per CLAUDE.md). S1 migration must stay chrome-only and not disturb widget-config logic.

## §7 — l10n

Cluster is **heavily localized** (`l10n.*` throughout). Hardcoded-HR debt is **low** — a handful (`notification:217`, `profile:'Aplikacija':397`, likely a few in `widget_advanced`). Count per chosen screen at apply; separate sweep, not this pass.

## §8 — Scope (discrete, operator-pick)

| # | item | yield | risk |
|---|---|---|---|
| **S1** | `widget_advanced` legacy → Bb* + flatten hand-rolled gradient | **HIGH** (only real legacy screen) | med (widget-config adjacency — chrome-only) |
| **S2** | `bank_account` → consume `context.gradients.pageBackground` | low (hygiene) | low |
| **S3** | `profile_screen` hub fidelity vs `profile-premium.jsx` | med (needs sub-recon) | low |
| **S4** | `edit_profile` / `change_password` fidelity vs `settings.jsx` (SStrengthMeter/SReqList/SFormSection) | low | low |
| — | l10n sweep (handful of HR strings) | — | separate |

**Recommendation:** Settings is largely DONE — do **not** run a 9-screen campaign. Highest yield = **S1 (widget_advanced) + S2 (bank_account)**, both small + self-contained. S3/S4 = optional fidelity polish if you want pixel-parity with `settings.jsx`/`profile-premium.jsx`. Pick a focused scope; I'll deep-recon + render the chosen screen at apply.

---

## §9 — APPLIED (operator scope: S2 only; S1 dropped)

**S2 · `bank_account_screen.dart` — DONE.** Body `Container(color: rd.shellBg)` (`:476`) → `decoration: BoxDecoration(gradient: context.gradients.pageBackground)` + added `gradient_extensions` import. **Bug-vs-hygiene verdict: untokenized-but-correct HYGIENE, not a wrong-bg bug** — `rd.shellBg` (light `#F0F1F5` / dark `#000`, `bb_redesign_tokens:94/122`) is byte-identical to `pageBackground` (`app_gradients:66/73`), so the body always painted the correct OLED `#000` in dark; the change only routes it through the canonical token (audit/126 single-source pattern). `rd` preserved (3× elsewhere → no unused warning). analyze 0.

**S1 · `widget_advanced_settings_screen.dart` — DROPPED (recon FALSE POSITIVE).** The recon flagged it "legacy (hand-rolled `Container(gradient)+Material+InkWell+Icons.check` selection chrome)". **Apply-time verification (comment-vs-code):**
- Precise grep excluding comment lines for `LinearGradient`/`Material(`/`InkWell`/`Icons.check`/`selected:` → **0 hits**.
- `:347-352` — the hand-rolled chrome is a **comment** stating it was *replaced by `BbButton`*.
- `:199-203` — the "purple gradient header slab" is a **comment** stating it was *retired to `color: c.surface` per audit/120*.
- Page bg already `context.gradients.pageBackground`; `Mat=8` = standard `Scaffold`/`AppBar`(×3 data/loading/error)/theme-aware `Container`s.
The screen is already flat + Bb-tokenized. The recon's `Bb=6/Mat=8` heuristic misread comments-documenting-past-migrations as current legacy. **Lesson:** a low-Bb/high-Material fingerprint is a *candidate* signal, not proof — confirm against code, not comments. (Only real residual = raw `AppBar` ×3 vs `CommonAppBar`; deferred, not in S1 scope.)

**Verification:** analyze 0 · `dart format` · full test suite green · `build web --no-tree-shake-icons` clean · render bank_account light+dark × 3 + live `:8091` dark. **NOT committed** (awaiting operator 100/100 dark eyeball). NO PROD.
