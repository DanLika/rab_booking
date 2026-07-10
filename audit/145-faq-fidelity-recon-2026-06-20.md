# audit/145 — FAQ / Help fidelity recon

**Date:** 2026-06-20 · **Status:** RECON ONLY — read-only, **no code changed**. Every row is a separate future GO.
**Anchor:** `origin/main` `feae40fe` (#771). **Terminal:** recon-w1 (Wave-1 cheap cluster).
**Scope:** LAYOUT / COMPOSITION / DATA only. Color/chrome settled by audit/126 + audit/127 — out of scope.

**Screen:** `lib/features/owner_dashboard/presentation/screens/guides/faq_screen.dart` (576 LOC).
**Handoff:** `design_handoff/source/faq.jsx` (187 LOC).

---

## Current-state map (code)

- `Scaffold` + `CommonAppBar(menu→drawer)` + `context.gradients.pageBackground` + `SafeArea`.
- `LayoutBuilder` centers a body column: `constraints.maxWidth >= 1024 ? 800 : >= 600 ? 620 : ∞` (`:273-277`).
- `ListView`: `_FaqPremiumHeader` (eyebrow "POMOĆ · FAQ" + title + subtitle) → `BbInput`(search, `lg`, with clear button) → category chips `Wrap` (all/bookings/payments/widget/icalSync/support) → results-count line (when filtered) → **one `BbCard` per item** (`ExpansionTile`: 36px tinted icon disc, question `h3` title, category-label caption subtitle, answer body) **or** empty state → contact card.
- **28 real FAQs** across 6 categories, all l10n.

## Handoff ground-truth (`faq.jsx`)

- Centered column (desktop 800 / tablet 620 / mobile edge). Header `h1`/`display` + subtitle.
- Search (`BBInput`). Category chips: Sve / Rezervacije / Plaćanja / Widget / Sinkronizacija / **Račun**.
- Accordion = **ONE `BBCard(padded=false)`**, `FaqItem` rows with dividers: 36 disc (**flips to filled-primary when open**, icon white fill=1), question, expand chevron; expanded → answer + **"Je li ovo bilo korisno?" thumb_up / thumb_down vote row**.
- Contact card: disc + "Niste pronašli odgovor?" + caption + **[E-pošta] [Razgovor uživo]** buttons.
- List sliced to a limit (5 / 6 / 8) — **artboard cap**, not a product rule.

---

## Diff ledger

| ID | Sev | Type | Finding | Recommendation |
|----|-----|------|---------|----------------|
| **F1** | Low | INT | **Per-item `BbCard`s vs one outer card + dividers.** Code comment (`:401-403`) already records this as deliberate per the per-item-card mandate. | Keep (INT). |
| **F2** | Low | LAYOUT | **Accordion leading disc does not flip to filled-primary when expanded** (handoff: open → bg primary, icon `#fff` fill=1). Code disc is a static tint (`:421-431`). | Optional: drive disc bg/icon color off `ExpansionTile` expansion state. Low. |
| **F3** | Low | COMP | **Contact card has no action buttons**; handoff has [E-pošta] [Razgovor uživo]. Code `_buildContactCard` is static (`:467-504`). | Add an "E-pošta" mailto CTA — **buildable** (mailto precedent: `profile_screen:373`, `about_screen:397`). Live-chat → see D2. |
| **F4** | — | code-ahead | Code adds eyebrow "POMOĆ · FAQ", a results-count line, and a category-label subtitle under each Q (handoff has none). | Keep — premium-header consistency; net-positive. |
| **F5** | — | NOTE | Handoff slices to 5/6/8 items (artboard cap). Code shows **all** filtered results with real search + category filter. | Code correct — no cap to add. |
| **F6** | Low | DATA | **Category taxonomy differs.** Handoff 6th cat = "Račun" (account: password/email/subscription Qs); code 6th = "support" (Tehnička podrška, 4 Qs). Icons differ accordingly (handoff `racun`→person; code `support`→support_agent, `:240-247`). | Content decision, not a bug — code has the richer set (28 vs 10 sample). Align the icon **only if** a "Račun" category is reintroduced. |

## Data-honesty (flag handoff fields the model lacks — do NOT invent)

| ID | Handoff field | Reality (grep-verified) | Verdict |
|----|---------------|-------------------------|---------|
| **D1** | "Je li ovo bilo korisno?" thumb_up / thumb_down vote | 0 hits for `thumb_up` / `helpful` / `wasThisHelpful` anywhere in `lib/` | **Omit — honest.** Voting needs a feedback backend; don't fake. |
| **D2** | "Razgovor uživo" (live chat) button | 0 hits for `liveChat` / `razgovor uživo` anywhere | **Omit — honest.** |
| **D3** | "E-pošta" button | `mailto:` precedent exists (profile/about screens) | **Buildable** — *not* a data-honesty omit; see F3. |

## Breakpoint (per breakpoint-decide discriminator)

- Body width gate `LayoutBuilder` `constraints.maxWidth >= 1024 ? 800 : >= 600 ? 620 : ∞` (`:273-277`) reads the **box** (`constraints.maxWidth`), gates **column max-width** → **content-fit reflow** → per discriminator **KEEP the value, just name it** (e.g. `_kFaqDesktopColMin = 1024`, `_kFaqTabletColMin = 600`). **Do NOT migrate 1024→1200** — it is not a device-class pivot.
- `_FaqPremiumHeader` `MediaQuery.sizeOf().width < 600` (`:524`) gates **only font-size** (typography); 600 = settled mobile floor → keep.
- **Net: no device-class migration on FAQ.** Optional naming hygiene only.

---

## Recommendation / packaging

FAQ is **already high-fidelity**. The only buildable gaps are **F3** (E-pošta CTA) and **F2** (disc active-state) — both Low. Everything else is INT / note / data-honest omit. → **Very light pass**, ideally folded into a "guides cluster" PR rather than its own. l10n debt: premium-header copy is hardcoded HR (consistent with sibling premium headers — flag, don't fix here).

## FROZEN

None.

## Gates

Read-only recon — gates **n/a**. A fix PR runs the standard ladder.
