# audit/135 — Owner Settings fidelity diff (continuation of audit/129 §8 S3/S4)

**DRAFT — READ-ONLY — NOT committed.** Code-first, budget-lean. No apply, no commit, no live-render this pass (deferred to apply-time per chosen screen, like audit/129). Recon off clean `main` `03528e74` (in-sync origin). Base palette ✓ `#F0F1F5` / `#000` / `#1E1E1E`.

**Scope:** ONLY the audit/129-deferred fidelity diff (S3 hub + S4 forms + confirm exemplar + check no-handoff screens). 129 already mapped structure (all 9 Bb*-migrated, hex=0) + shipped S2 (bank_account) + dropped S1. **Not re-mapping.** Color = audit/127 (excluded). Method: 3 code-first agents + firsthand grep verification of every "gap" before trusting it.

---

## Per-screen ledger

### S3 — `profile_screen` (hub, 1503) vs `profile-premium.jsx` (489)
**Verdict: largely MATCHES. One real gap (heavy), two handoff items are correct data-honest omissions.**

| Item | code vs handoff | Class | Cost |
|---|---|---|---|
| Settings rows (icon tile / chevron / divider), Language+Theme toggles (text-value subtitle), stat strip (4→2 col, UPPERCASE), group eyebrow+icon labels, responsive | **already matches** | — | — |
| **Pro-card benefits grid** — handoff `_ProfilProCard` shows a 4-benefit tile grid (`profile-premium.jsx:271`); code (`profile_screen.dart:1042-1162`) omits it (title + trial pill + progress + CTA only). Benefits data **exists** (`subscription_screen.dart:681-682`). | **REAL gap** | SAFE | **heavy** (new grid component + mobile/desktop branching) |
| ~~3rd "Identitet" verification chip~~ (`profile-premium.jsx:170`) | **data-honest omission** — no identity/KYC feature exists; adding = fabrication | correct as-is | — |
| ~~"Javni profil" header button~~ (`profile-premium.jsx:392`) | **data-honest omission** — no `publicProfile` route/feature exists | correct as-is | — |

### S4 — `change_password` (639) + `edit_profile` (842) vs `settings.jsx` (401)
**Verdict: both MATCH functionally. Cheap cosmetic deltas only; the "missing checklist" alarm was false.**

**`change_password`:**
| Item | code vs handoff | Class | Cost |
|---|---|---|---|
| `SPasswordField` show/hide ×3, `SStrengthMeter` live bar (`:433`), requirements feedback (`_missingRequirements` rendered in meter `:618-620`) | **already matches** (functional) | — | — |
| `SReqList` style — handoff = static 4-item checklist w/ checkmarks; code = **dynamic missing-only list** | minor variant (data-honest) | SAFE | cheap (optional) |
| No `SFormSection` titled grouping (single `BbCard` + custom header `:285`) | cosmetic | SAFE | cheap |
| Info-banner tone: `info` vs handoff `tertiary` (`:481`) | borderline (≈color, 127-adjacent) | SAFE | cheap (skip-able) |
| "Odjavi me sa svih uređaja" toggle **NOT wired** (TODO `:505-511`) | **feature gap, not fidelity** — needs session-revoke backend | SAFE | **heavy** (deferred) |
| Save = stacked buttons vs `SInlineSaveBar` sticky | mobile-aligned | SAFE | med (deferrable) |

**`edit_profile`:**
| Item | code vs handoff | Class | Cost |
|---|---|---|---|
| `BbSectionHeader(h3)` titled cards, email verified-chip, phone helper | **already matches** (h3 serves `SFormSection` role) | — | — |
| Name fields **1-col stack** vs handoff **2-col grid** (Ime∣Prezime desktop, `settings.jsx:178`) | layout delta | SAFE | cheap |
| `BbAvatarUpload` (picker) vs `BBAvatarSlot` + Promijeni/Ukloni buttons | architecture (existing working widget) | SAFE | heavy → **leave** |
| Address + Company + socials cards | code **exceeds** handoff (richer) — NOT a gap | — | — |
| Save = stacked buttons vs `SInlineSaveBar` sticky | mobile-aligned | SAFE | med (deferrable) |

### Confirm / no-handoff (low priority)
| Screen | LOC | Handoff | Verdict |
|---|---|---|---|
| `notification_settings` | 382 | `settings.jsx` NotifTable/SInfoBanner | **DONE/exemplar.** Nits only: hardcoded HR string (`:217` → l10n), `Container(36×36)` magic, `fontSize:13/10` literals → `BBType`. Compact-payments / no-QuietHours / unwired categories = **data-honest, correct.** |
| `about` | 537 | **none** (no `about*.jsx`) | design-to-system; clean (`CommonAppBar`+`context.gradients`+`Bb*`). **No gap.** |
| `widget_settings` | 1625 | **none** (`widget-*.jsx` = guest) | design-to-system; Bb*-adopted. **No gap.** FROZEN-adjacent. |
| `widget_advanced` | 459 | **none** | **Raw `AppBar` ×4** (`:286/391/433/453`) → `CommonAppBar` (audit/126+129 chrome debt). cheap. FROZEN-adjacent. |
| `bank_account` | 599 | — | **DONE** (S2 shipped #760). Skip. |
| `subscription` | 1006 | — | own feature; not a settings-handoff target. Out of scope. |

---

## FROZEN check (129 said clean — CONFIRMED)
All settings nav = go_router `context.push`, **not** the FROZEN widget `Navigator.push` confirmation → SAFE. ⚠️ `widget_settings` + `widget_advanced` touch WIDGET config (subdomain regex, App-Check-OFF) → **FROZEN-ADJACENT**: chrome-only edits OK, do NOT disturb widget-config logic.

---

## Scope (operator picks)

### 🟢 Cheap-wins bundle (SAFE, high-confidence, ~1 small PR)
1. **`widget_advanced`: `AppBar` ×4 → `CommonAppBar`** — clearest win; closes the 126/129 chrome debt. (FROZEN-adjacent: chrome-only.)
2. **`notification_settings` nits** — `:217` HR string → l10n; `Container(36×36)` + `fontSize:13/10` → tokens.
3. **`edit_profile`: 2-col name grid** (Ime∣Prezime, desktop) — single layout fix.
4. *(optional/marginal)* `change_password` + `edit_profile` section-title polish; `change_password` info-banner tone. Skip-able.

### 🟠 Heavy / deferrable
- **S3 Pro-card benefits grid** (new component; benefits data exists) — the only substantive S3 fidelity gap.
- **`change_password` sign-out-other-devices toggle** — feature wiring (session revoke), not fidelity. Deferred TODO.
- **`SInlineSaveBar` sticky footer** (both forms) — low value; stacked buttons work + are mobile-aligned.
- **`edit_profile` avatar slot+buttons** — architecture; leave.

### ✅ Already matches / do NOT touch
S3 hub chrome (rows/toggles/stat-strip/labels/responsive); S4 strength-meter + requirements feedback + field styling; `notification_settings` core; `about`; `widget_settings`. **Data-honest omissions** (keep): S3 identity chip + public-profile button; notif compact-payments / QuietHours / unwired categories.

**Headline:** Settings is in good shape — the cheap-wins bundle (#1 widget_advanced AppBar + #2 notif nits + #3 edit_profile name-grid) is the high-yield, low-risk pick; the only heavy fidelity item is the S3 Pro-card benefits grid. **No live-render spent** (code-diffs conclusive); render the chosen screen at apply.

**STOP — no apply. Operator picks (lean-now or post-budget-reset).**

---

## §APPLIED — cheap-wins bundle (2 of 3) → `design/135-settings-cheapwins`

Operator scope: cheap-wins bundle, SAFE only, budget-lean. Worktree off `origin/main` `03528e74`. CHANGELOG 7.29.

- ✅ **`widget_advanced` AppBar×4 → `CommonAppBar`** (`:287/396/440/464`) + import; exemplar back-nav (`leadingIcon: arrow_back` / `onLeadingIconTap: pop`), main-branch save `actions` kept. Chrome-only; widget-config logic untouched.
  - **EMBED-CHECK (the one risk — `widget_advanced` is uniquely embedded headless in the hub Napredno tab):** all 4 `CommonAppBar` sit AFTER an `if (!widget.showAppBar) return <bare content>` guard (`:283/376/436/460`); hub embeds with `showAppBar:false` (`unified_unit_hub_screen:1494`) → embedded path returns bare content (no Scaffold/AppBar) → **NO double-header.** raw `AppBar(`=0, `CommonAppBar`=4, guards=4. Swap stayed inside the standalone-only conditional. ✅
- ✅ **`notif` HR banner → l10n** `notificationSettingsBannerInfo` (en+hr). Visually neutral. Magic sizes (36/13/10 = handoff, no exact token) left to avoid pixel drift.
- ❌ **`edit_profile` 2-col name grid DROPPED** — single `_displayNameController` ("Puno ime"), not first/last; 2-col = split one field into two = data-model + validation + save/UX + existing-name migration ("Ana Kovač" → ?). Feature, not cheap fidelity. **Deferred (likely permanent)** — same principle as audit/134 gallery/fees (don't reshape the data model for a mock pixel-match).

**Attest:** analyze **0 net-new** · format · suite **+1535 green** · build web `--no-tree-shake-icons` clean. Live-render **skipped** (budget-lean): notif neutral; `widget_advanced` = canonical `CommonAppBar` + the embed-check (the only thing precedent didn't cover) passed by code.

**Deferred to budget reset:** S3 profile-hub Pro-card benefits grid (heavy, 1503 LOC).
