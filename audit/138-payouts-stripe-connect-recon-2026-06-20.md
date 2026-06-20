# audit/138 — Payouts / Stripe Connect setup fidelity recon

**READ-ONLY recon → ledger.** Anchor: origin/main `54f0820a` (worktree).
Target: `lib/features/owner_dashboard/presentation/screens/stripe_connect_setup_screen.dart` (1390 LOC).
Handoff: `design_handoff/source/payouts.jsx`.
Method: code-first (3 read-only Explore agents + firsthand read of load-bearing ranges). Colors/chrome already done (127/126) → flags **LAYOUT / COMPOSITION / DATA**, not re-color.

> Note: since the recon, origin/main advanced `54f0820a → bbbcb9a3` (PR #763, Unit Wizard progress-bar — does not touch this screen). C2 work is pinned to `54f0820a` (an ancestor of the new tip), so the target is byte-identical to what was reconned.

---

## Headline verdict

**The handoff and the screen depict different things — the gap is ~85% backend, ~15% presentation.**

- `payouts.jsx` = a **connected payouts dashboard** (Stripe-status w/ 3 granular ✓ checks → balance tiles → bank card → payout schedule → recent-payouts history). It shows **only** the connected/active end-state.
- The Flutter screen is primarily an **onboarding funnel** (not-connected → benefits → steps → FAQ → "Connect" CTA → external Stripe URL), **plus** a debug-gated, pixel-faithful replica of the handoff dashboard that is **correctly hidden in production**.

The dashboard UI already matches the handoff (mock data lifted from it, screen l.966–967) and is gated off pending Cloud Functions that don't exist (`getStripeBalance`/`listStripePayouts`). This is an **existing, intentional data-honesty decision** (screen l.955–960), not a bug. **Do not un-gate or wire fabricated balances.** The onboarding funnel has **no** handoff counterpart, so it is not a fidelity target.

## 🔒 FROZEN — do not touch (UI-only recon)

| Logic | file:line | Why |
|---|---|---|
| `getStripeAccountStatus` fetch | 49–93 | LIVE account-state callable |
| `createStripeConnectAccount` + onboarding launch | 95–169 | LIVE; opens external Stripe onboarding |
| return/refresh URL construction | 104–113 | Hardcoded prod `app.bookbed.io/owner/stripe-{return,refresh}` — LIVE redirect contract |
| `disconnectStripeAccount` | disconnect handler | LIVE state reset + Firestore invalidation |
| `_StripePayoutsDashboard` gate `STRIPE_PAYOUTS \|\| kDebugMode` | 964, 994 | The data-honesty guard — keep gated |

## 🚩 DATA-HONESTY flags — handoff fields the model lacks (feature, don't invent)

| Handoff field (payouts.jsx) | Backing data today | Verdict |
|---|---|---|
| Balance: available / in-processing / monthly (l.62–79) | none | **FEATURE → H1** |
| Recent payouts: `po_…`/date/dest/status (l.121–145) | none | **FEATURE → H2** |
| Payout schedule: frequency / min €50 / notif toggle (l.107–116) | none | **FEATURE → H3** |
| 3 granular ✓ checks: identity/charges/payouts (l.45–54) | not queried (only `onboarded` bool) | **FEATURE → H4** |
| "Upravljaj na Stripe-u" manage link (l.38) | no login-link CF | **FEATURE → H5** |
| BankCard: bank/IBAN/owner (l.84–102) | — | **OUT OF SCOPE** → `bank_account_screen` (audit/129) |

---

## CHEAP BUNDLE — ship-now, zero-backend

**C1 — connected-state hero → handoff `StripeStatusCard` composition** *(LAYOUT/COMPOSITION; MED; render-worthy)*
Flutter connected hero = vertical card (tinted icon box + badge + description + ID pill + stacked full-width buttons); handoff = horizontal header (56×56 r14 indigo `#635BFF` brand tile + gap 14 + inline `bb-h3` + "Povezano" badge + caption subtitle + 11px mono ID), card padding 20. Uses only `{accountId}` → no new data; partial match (✓-checks strip needs H4).
**Decision: HOLD C1 — bundle with H4** so the hero is recomposed once, fully (no double recompose). Per operator 2026-06-20.
⚠ `#635BFF` is the Stripe **brand** tile (handoff l.5–7) — the one legit non-token hex; do not let a 127-palette sweep strip it.

**C2 — hygiene sweep** *(must be byte-identical per operator gate — see caveat below)*

> **C2 byte-identical caveat (discovered at apply-time).** The marquee item `withAlpha((k*255).toInt())` → `withValues(alpha: k)` is **NOT byte-identical**: `toInt()` truncates, `withValues`'s 8-bit getter rounds, so they diverge by 1/255 whenever `frac(k*255) ≥ 0.5`. Of the 9 `withAlpha` sites, **7 shift** (0.1→25/26, 0.5→127/128, 0.7×5→178/179) and **2 match** (0.15→38, 0.6→153). A blanket `→withValues(0.X)` therefore **fails** the no-pixel-move gate. See [[withalpha-toint-vs-withvalues-rounding]].
>
> Under the strict gate, C2 reduces to:
> - **Divider-DRY** (l.661–662 / 753–754 / 811–812): extract the repeated `isDark ? sectionDividerDark : sectionDividerLight` into one in-file helper → **provably byte-identical**. ✓
> - **Alpha-9 conversion**: operator-gated — drop / `withAlpha(int)` (exact+clean) / `withValues(int/255)` (exact+withValues) / `withValues(0.X)` (clean, ≤1/255 shift). Recommended `withAlpha(int)` (kills the inline-math drift, byte-identical, zero pixel move).
> - **emoji `❓`→BbIcon** (l.839): glyph change = pixel move; FAQ has no handoff → **deferred to a visual pass**, not byte-identical C2.
> - **`monospace`→token** (l.501): inside the hero (C1/H4 hold-zone) → **excluded from C2**.
> - **named consts**: pure churn, no value change; **skipped** to keep C2 minimal.

### C2 OUTCOME — APPLIED on `design/138-stripe-c2` (uncommitted, awaiting approval)
Operator chose **`withAlpha(int)`**. Applied via IEEE-754-safe `perl` (`int(k*255)`, not hand-typed — `0.6*255`→**153** by round-to-nearest, see [[withalpha-toint-vs-withvalues-rounding]]). Divider-DRY done (file-private `_sectionDividerColor` helper + 3 call-sites; 2 orphaned `isDark`/`theme` decls removed). emoji/monospace deferred as planned.
- diff **19+/39−**, one file; 9 alpha literals == reference `[25,178,38,178,127,178,178,153,178]`.
- Gates: `dart format` ✓ · target-file `analyze` = 0 · **0 new analyze issues** (baseline 97 == post 97, all pre-existing `info` in untouched files) · **suite green** (`flutter test` exit 0) · **0 frozen anchors** in diff (CF/URL/gate ranges byte-identical).

## HEAVY — backend feature epic (product/eng decision; do NOT auto-proceed)

Dashboard **UI already built** (gated). Each = CF + provider, then un-gate + swap mock for `ref.watch(...)`; then apply spacing deltas in one pass.

| # | Work | Notes |
|---|---|---|
| **H1** | `getStripeBalance` CF + provider → BalanceTiles | named in code comment l.958 |
| **H2** | `listStripePayouts` CF + provider → RecentPayouts | mock l.968–990 |
| **H3** | Payout-schedule read/write (freq / **min €50** / notif) | min-floor ties to `stripe.md` F-86-03 |
| **H4** | Extend `getStripeAccountStatus` → `charges_enabled`/`payouts_enabled`/`details_submitted` → ✓-checks strip + completes C1 hero | small CF extension |
| **H5** | `createStripeLoginLink` (Express dashboard) → "Upravljaj na Stripe-u" | screen currently only offers Disconnect |

**Dashboard spacing deltas (apply only when un-gated):** section gap 24→16 (l.1003/1005); balance grid gap 12→16 (l.1068); recent-row padding h:BBSpace.md(24)/v:12 → h:20/v:14; balance-tile icon radius BBRadius.sm(12)→10; dashboard column max-width 1000→760. Do **not** force the global screen max-width to 760 (breaks the 2-col desktop onboarding funnel).

## Live-render plan (only where code-diff shows a real gap)
- **C1** (held) is the only render-worthy item; needs the connected state → render via a `@visibleForTesting buildHeroForTest(state)` seam goldened across not-connected/incomplete/connected + a live wiring eyeball ([[seam-test-proves-fn-not-wiring]]).
- **C2** = neutral hygiene → no render.

## Verification (C2, when greenlit)
- `flutter analyze` = 0; `dart format .`; suite green.
- Frozen guard: diff shows **zero** lines changed in 49–169, 104–113, and the gate at 964/994.
- Alpha: per chosen option, confirm resulting 8-bit alpha byte-identical to the pre-change `(k*255).toInt()` value at each site.

## Status
- Recon complete. C1 held for H4. **C2 APPLIED + verified** (`withAlpha(int)` + divider-DRY; all gates green; awaiting commit approval). emoji/monospace deferred.
- H1–H5 = separate Stripe Payouts backend epic (product call: does the connected dashboard ship near-term?). Current gated-off honesty is correct until then.
