# audit/146 — Legal trio (Terms / Privacy / Cookies) fidelity recon

**Date:** 2026-06-20 · **Status:** RECON ONLY — read-only, **no code changed**. Every row is a separate future GO.
**Anchor:** `origin/main` `feae40fe` (#771). **Terminal:** recon-w1 (Wave-1 cheap cluster).
**Scope:** LAYOUT / COMPOSITION / DATA + **the raw-900 breakpoint classification** the task explicitly asked for. Color/chrome settled by audit/126 + audit/127 — out of scope.

**Screens** (three structurally-identical templates):
- `lib/features/auth/presentation/screens/terms_conditions_screen.dart` (596) — read in full (representative)
- `…/privacy_policy_screen.dart` (613) · `…/cookies_policy_screen.dart` (651) — **parity confirmed via grep**: same private widget classes (`_LegalDocHeader`/`_LegalFlatSection`/`_LegalTocCard`/`_LegalTocSidebar`/`_LegalNoticeCard`), same breakpoint literals, same `maxWidth: 980` clamp, same `LegalTabsRow` usage (privacy `:83-85`/`:137`, cookies `:77-79`/`:124` mirror terms `:79-81`/`:128`).
- `…/widgets/legal_tabs_row.dart` (65) — the segmented switch.

**Handoff:** `design_handoff/source/legal.jsx` (106 LOC).

---

## Composition note (set expectations first)

Handoff = **ONE unified reader**: a segmented switch swaps the doc **in-place** (React state, `selected`). Code = **THREE separate screens**; `LegalTabsRow` does `Navigator.pushReplacement` to swap. Net visual result is **equivalent** (chips at top, tap → switch doc) and the 3-screen split is required to work in **both** nav contexts (pre-auth modal push from register **and** post-auth `OwnerRoutes.*` go_router). → **INT**, not a gap.

## Current-state map (each screen, identical skeleton)

- `CommonAppBar(arrow_back, per-doc title)` + `pageBackground` + `SafeArea` + `Stack`.
- `ConstrainedBox(maxWidth: 980)` wrapping `isDesktop ? _buildDesktop : _buildMobile`.
- **`_buildDesktop` (≥900):** `Row` [ 240px **sticky** `_LegalTocSidebar` (eyebrow + jump-links + last-modified surface) | 48 gap | `Expanded` `SingleChildScrollView`(controller): `LegalTabsRow` + `_LegalDocHeader`(eyebrow + display + last-updated) + 10× `_LegalFlatSection` + `_LegalNoticeCard` ].
- **`_buildMobile` (<900):** single `SingleChildScrollView`: `LegalTabsRow` + `_LegalDocHeader` + `_LegalTocCard` (TOC-as-card) + sections + notice card.
- Scroll-to-top FAB after 300px; jump-links via `Scrollable.ensureVisible` + `GlobalKey`s.

## Handoff ground-truth (`legal.jsx`)

- `LegalTopbar` (56px): back + **"Pravni dokumenti"** (generic) + **"Preuzmi PDF"** (secondary, desktop-only).
- `LegalTabsRow` (chips). Desktop grid `240px 1fr` gap 48 (container **980**): `LegalToc` (sticky, **active item-0 highlighted** = primary text + tint bg + 2px left border) + doc col (`LegalDocHeader` + 8 `LegalSection`).
- Mobile: compact topbar + horizontal-scroll tabs + first-4 sections + **"Pomaknite za više"** hint.
- **Artboards defined: `LegalDesktop` (1440) + `LegalMobile` (390) only** — handoff is **silent on 768–1199**.

---

## Diff ledger

| ID | Sev | Type | Finding | Recommendation |
|----|-----|------|---------|----------------|
| **LG1** | **BP** / High | BREAKPOINT | **`>=900` is a device-class pivot** (all 3: `final screenWidth = MediaQuery.of(context).size.width; final isDesktop = screenWidth >= 900` — terms `:79-81`, privacy `:83-85`, cookies `:77-79`). Reads MediaQuery width; gates the whole desktop 2-col-sidebar vs stacked layout + the `horizontalPadding` tier (16/24/32). | **See breakpoint analysis below.** Migrate→1200 *or* reclassify content-fit — a genuine ~1100 eyeball call. Bundle with breakpoint-decide §4 Wave-2 strays. |
| **LG2** | — | COMP | Generic "Pravni dokumenti" topbar title (handoff) vs **per-doc** `CommonAppBar` title (code) — natural given the 3-screen model. | Keep (composition consequence). No action. |
| **LG3** | Low | LAYOUT | **TOC has no active-section highlight / scroll-spy.** Handoff `LegalToc` highlights the current section (item-0: primary + tint bg + 2px left border); code `_LegalTocSidebar` renders all items uniformly (`textSecondary`, `:488-505`). | Static "highlight first item" = cheap. True scroll-spy (highlight-on-scroll) = a **feature** → defer. Operator call. |
| **LG4** | Low | COMP | **Scroll-to-top FAB added** (code, after 300px) — not in handoff. Handoff mobile **"Pomaknite za više"** scroll hint is **absent** in code. | FAB = net-positive, keep. "Pomaknite za više" = trivial optional add. |
| **LG5** | — | INT | Unified-reader (1 screen, state swap) vs 3-screen `pushReplacement`. | Keep (INT) — equivalent UX; required for dual nav contexts. |
| **LG6** | — | code-ahead | Code adds `_LegalNoticeCard` (info accent-left card) + **dynamic** last-updated year + **10** real sections (handoff: 8 sample). Richer / more correct. | Keep. |

## Data-honesty (flag handoff fields the model lacks — do NOT invent)

| ID | Handoff field | Reality | Verdict |
|----|---------------|---------|---------|
| **D1** | "Preuzmi PDF" download button | No PDF export of legal docs anywhere — docs are in-app l10n strings, no PDF asset/generator | **Omit — honest.** Don't fake a download. |

---

## Breakpoint analysis (the §-the-task-asked-for)

The legal `>=900` reads `MediaQuery.of(context).size.width` and gates (a) the desktop 2-col TOC-sidebar layout vs stacked **and** (b) the padding tier — both "desktop look." By the discriminator's **reliable signal** (reads MediaQuery width, *not* `LayoutBuilder constraints`), it classifies as a **device-class pivot → migrate to 1200**, consistent with breakpoint-decide §4 Wave-2 ("legal-page 900 ≈ device-class reading-width → 1200").

**But flag the genuine tension for the band-eyeball:** the 2-col reader is *content-shaped* — the whole `Row` is clamped to `maxWidth: 980` (terms `:128`), so sidebar(240) + gap(48) + doc(≈692) **always fits from ~900 up**; it never needs "desktop width." Migrating 900→1200 removes the premium 2-col reader for the entire **1024–1199 band — including iPad-landscape (1024)**, which drops to the stacked single-column (TOC-as-card) layout. The handoff defines **only Desktop (1440) + Mobile (390)** artboards for legal — it does **not** adjudicate 768–1199.

**Two defensible resolutions (decide at ~1100 eyeball):**

- **(A) Migrate → 1200** (treat as device-class, per discriminator + breakpoint-decide §4): one consistent threshold; iPad-landscape gets the clean stacked reader. Mechanically `>=900` → `isDesktopWide`/1200; keep the 980 clamp (or unify → `BBContentMaxWidth`).
- **(B) Reclassify as content-fit → keep 900, name it** (`_kLegalTwoColMin = 900`) and ideally convert the `MediaQuery.width` read to a `LayoutBuilder constraints.maxWidth` read so it is a true box-driven reflow: **preserves the premium 2-col reader on iPad-landscape.** Same class as `booking_detail`'s deliberate `_kTabletGridMinWidth = 720` / dashboard's `_kStatGridMin = 900` (breakpoint-decide §3b).

**Recon lean:** **(B)** on visual merit — the reader fits and looks premium at 900 (nothing is cramped, thanks to the 980 clamp), so forcing it up to 1200 *loses* polish on iPad-landscape for the sake of threshold uniformity. This contradicts breakpoint-decide §4's provisional "→1200," which is exactly why it is a **~1100px eyeball call**, not a desk decision. Whichever wins, **apply uniformly across all 3 screens** and treat the three raw `980` clamps consistently. Bundle with the other Wave-2 raw-900 strays (`profile_screen:1322`, `step_4_review:24`) per breakpoint-decide §4 — small PR, med risk, mandatory **600 / 900 / 1100 / 1300 light + dark** eyeball.

---

## Recommendation / packaging

The legal trio is **already faithful** to the handoff (sticky TOC sidebar, tabs row, doc header, flat sections, notice card, 980 clamp all present). The only substantive open item is **LG1** (breakpoint classification — needs the band eyeball). LG3 (TOC active highlight) and LG4 ("Pomaknite za više" hint) are optional polish. D1 (PDF) is a confirmed data-honest omit. → Fold the breakpoint decision into the breakpoint-decide §4 Wave-2 misc PR; legal needs no standalone fidelity pass.

## FROZEN

None. The `LegalTabsRow` `pushReplacement` nav contract must survive **both** pre-auth and post-auth contexts — preserve it on any refactor.

## Gates

Read-only recon — gates **n/a**. A fix PR runs the standard ladder + the band eyeball.
