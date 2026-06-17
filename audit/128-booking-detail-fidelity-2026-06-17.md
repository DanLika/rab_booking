# audit/128 — owner_booking_detail premium fidelity + hygiene (recon)

**Status:** 🔄 recon COMPLETE (read-only) → apply queued (A + scope below)
**Date:** 2026-06-17
**Branch:** `design/128-booking-detail-fidelity` (off `origin/main b58a60bf`, rebased onto post-127 main at apply)
**Scope:** `lib/features/owner_dashboard/presentation/screens/owner_booking_detail_screen.dart` (1461 lines) + its action-gate test
**Target:** `design_handoff/source/booking-detail.jsx §201 BookingDetailDesktop`
**Renders (visual target, this pass):** `audit-shots/bd-desktop-light.png` · `audit-shots/bd-desktop-dark.png` (harness `.theme-dark` token-swap on the 1440 frame)

---

## TL;DR

The screen is **NOT** the mixed-hygiene straggler the backlog implied — it is **already premium-composed** against its own dedicated handoff (`booking-detail.jsx`, cited in the file header) and matches the target closely in **both** themes. This is a light **fidelity + hygiene** pass, not a redesign. No hero wash to flatten. One architectural item (`shellBg`) has an **ordering dependency on audit/127** and drives the decision below.

---

## §1 — Current-state map

| Aspect | State |
|---|---|
| Page bg | `Scaffold` body `context.gradients.pageBackground` (`:51`) ✓ wired — **but covered** (see §3) |
| Tokens | Heavy `BBColor`/`BBSpace`/`BBRadius`/`BBType`/`BbRedesignTokens` + redesign primitives (`BbCard`/`BbButton`/`BbIcon`/`BbAvatar`/`BbStatusBadge`/`BbEmptyState`) |
| Sections | Cover · pending-alert · guest · stay (Boravak) · notes · status+actions · price (Plaćanje) · activity timeline · meta · mobile sticky bar |
| Layout | `isDesktop ≥1024` → 2-col grid (flex2 / 320); else single column. **No tablet-specific layout.** |
| Double-header | ✅ none — bespoke `_DetailAppBar` inside body Column; `Scaffold` has no `appBar:`. `CommonAppBar`/`showTitle:false` pattern N/A. |
| Reached via | go_router from Rezervacije ledger (audit/124 lean-ledger gate-fix re-home target) |

---

## §2 — Flatten compliance: CLEAN

Per `[[flat-chrome-decision]]` "kept on purpose" (fade scrims, status/error chips, 4px accent rail). The screen's only gradient-ish surfaces are exactly those legit kept ones:
- Cover photo scrim (`:362-365`, `Color(0x9E10121C)→0x0010121C`) — **legit scrim, keep**
- AmountTile paid/remaining tints + timeline-dot tints (`rd.status*Tint/Deep`) — **legit status, keep**
- Pending accent-left rail (tertiary/amber) — **legit, keep**

→ **Zero hero washes. No flatten work.** Mint-wash grep = 0.

---

## §3 — `shellBg` covers `pageBackground` (the crux; ordering dep on audit/127)

`:51` paints `pageBackground` ✓ — then `:120` `Container(color: rd.shellBg)` **covers it entirely** in the data path → `:51` is dead paint; visible body = `shellBg`.

| | visible (shellBg) | pageBackground @main b58a60bf (dead) | handoff target | post-127 pageBackground |
|---|---|---|---|---|
| Light | `#F0F1F5` | `#ECEDF2` | `#F0F1F5` | `#F0F1F5` |
| Dark | **`#000` OLED** | `#1A1A1A` | **`#000` OLED** | OLED `#000` |

**Twist:** `shellBg`'s current values already equal the audit/127 convergence target AND the rendered handoff. So the screen is visually *more* faithful now than a naive "consume pageBackground" swap (which on pre-127 main is still transitional `#ECEDF2`/`#1A1A1A` → dark would regress OLED→`#1A1A1A`). This is **architecture hygiene** (dead paint + non-canonical token vs the audit/126 "consume pageBackground" pattern), not a visual bug.

**Decision → A (sequenced):** land audit/127 palette re-point on main first (`pageBackground`→`#F0F1F5`/OLED `#000`; verified `cbf9e355`: `_lightStart=#F0F1F5`, `_darkStart=#000000`, `_darkCard=#1E1E1E`), rebase `design/128` onto it, **then** drop the dead `:120` `shellBg` fill → inherits correct light+dark automatically, zero per-screen literals. C-fallback (leave as-is) only if 127 is held; **never B** (dark regression).

---

## §4 — Fidelity divergences (app vs handoff)

| # | Element | Handoff | App | Verdict | In scope |
|---|---|---|---|---|---|
| F1 | Odbij / Otkaži | `destructive-soft` (error-tint, pink) | `BbButtonVariant.destructive` (solid) — `:829`/`:882`/`:999` (**3 sites**) | **Real gap** — `destructiveSoft` exists (`bb_button.dart:13`) | ✅ |
| F2 | Secondary-row `…` overflow | present (Poruka·Uredi·…) | dropped; explicit complete/cancel below | Intentional gate-fix, **keep** | — |
| F3 | Appbar notif bell (6) | present | omitted | Odd on a back-button detail route; **skip** | ❌ |
| F4 | Persistent sidebar/rail | yes | drawer + full-route | **Global 3B** (audit/126) out of scope | — |
| F5 | Activity timeline | 3 static incl. "Potvrda poslana" | real events only | **Data-honest**, keep | — |
| F6 | Tablet (600–1023) | dedicated nested 2-col grid | falls to single column | Real gap | ✅ (defer if lean) |
| F7 | Cover boxShadow | `shadow-sm` | border only | Minor | ⚪ optional |
| F8 | Guest mail/call icons | `BBButton asIcon` | bespoke `_RoundIconButton` | Minor (≈) | — |
| F9 | Mobile stack gap | 12 | 14 (single-col 14 for mobile+tablet) | Fold into hygiene → 12; **only fully correct once F6 lands** | ✅ |

Matched well ✓: cover scrim hex (faithful rgba), pending accent (defaults tertiary), price tiles, KV rows, status badge, title, parked print/share (`onPressed:null` honest).

---

## §5 — Hygiene

- **Raw hex 2** (`:365`/`:383` scrim+dot) + **3 `Colors.white/black`** (`:373`/`:392` over-photo, `:987` shadow) — contextually **legit**; optional name scrim consts.
- **Off-grid `14` ×8** + magic layout consts `1100`/`320`/`124`/`200` → name in-file consts. `14`→`12` (`BBSpace.xs2`, on-scale + handoff mobile-faithful) [F9].
- **6 `fontSize:` overrides** — handoff-specific, low priority.
- **l10n debt:** ~40 hardcoded **Croatian** UI strings (labels/buttons/snackbars/tooltips); 3 use `l10n.*`. **Not English** — un-localized only. **Separate sweep**, not this pass.
- **`dynamic booking`** (`:1025`/`:1185`, "avoid import") — `BookingModel` already imported `:14` → type it + drop redundant `as` casts.

---

## §6 — FROZEN / preserve (assert, don't touch)

- **Navigator.push confirmation (FROZEN)** = widget tree (`booking_widget_screen.dart`), NOT here. This owner screen uses `approveBooking`/`rejectBooking` **CF callables** + go_router `pop/go` — no Navigator.push confirm. File header `:26-31` documents the guard. ✅ untouched.
- **`detailActionVisibility`** (`@visibleForTesting`, `:651-661`) — pure gate pinned by `owner_booking_detail_actions_test.dart` (5 cases: past→complete, upcoming→cancel, in-progress→neither, pending→approve/reject, no-strand). Audit/124 lean-ledger re-home landing. **Preserve fn + signature + `build()` consumption + test green** (per operator pref: move coverage, never break). F1 is a variant-only change → gate stays green.
- §2 scrim/status-tints/accent-rail; F2 overflow + F5 timeline (intentional divergences).

---

## §7 — Apply plan (A + scope) — queued

0. **Base:** merge audit/127 (`design/127-handoff-palette-apply` → main; **not** clean FF — identical add/add audit-127 doc auto-resolved; payload `cbf9e355`+`f2cc7623`), rebase `design/128`, base-verify `app_gradients` → `#F0F1F5`/OLED `#000`. (C-fallback if 127 held → skip step 2, leave shellBg.)
1. **F1** destructive → `destructiveSoft` ×3 (`:829`/`:882`/`:999`). Gate untouched.
2. **§3** drop `:120` `shellBg` fill → consume `:51` `pageBackground` (A only).
3. **Hygiene** name off-grid/layout consts (`14`→`12` [F9], `1100`/`320`/`124`/`200`); type 2 `dynamic`→`BookingModel`; optional F7 cover shadow.
4. **F6** tablet 2-col (`booking-detail.jsx:222-237`) — include for full responsive fidelity; defer if lean (then single-col→12 tightens tablet slightly, acceptable).
5. **Attest:** `flutter analyze` 0 · `dart format .` · action test 5 green · live light+dark+responsive vs renders (run via `run_in_background` only) → **operator eyeball gate** before commit.
6. **Ship:** CHANGELOG **7.25** (127 took 7.24) + audit/128 §sections + memory pointer. Post-127 cleanup: `git worktree remove /tmp/bb-127-wt` + `firebase use bookbed-dev`.

---

## §8 — APPLIED (SHIPPED `design/128`)

Base: audit/127 merged to main (`29f44b3b`; non-FF — identical add/add audit-127 doc auto-resolved `-X ours`; payload `cbf9e355` palette + `f2cc7623` changelog), `design/128` rebased; base-verified `app_gradients` → light `#F0F1F5`, dark OLED `#000`, card `#1E1E1E`.

**Landed (screen `+193/−73` + new test):**
- **F1** — `BbButtonVariant.destructive`→`destructiveSoft` ×3 (Odbij `:829`, Otkaži `:882`, mobile Odbij `:999`). Soft-pink confirmed in live render. Gate logic untouched.
- **§2** — dropped the body `Container(color: rd.shellBg)`; Scaffold `pageBackground` shows. **Visually neutral** (old shellBg light `#F0F1F5`/dark `#000` == post-127 pageBackground), removes dead paint, single-source per audit/126.
- **§3** — named consts `_kContentMaxWidth`/`_kSidebarWidth`/`_kKvLabelWidth`/`_kCoverHeight{Desktop,Tablet,Mobile}`/`_kTabletGap`/`_kMobileGap`/`_kTabletGridMinWidth`. Off-grid `14`→`_kMobileGap`=12 (NOT `BBSpace.xs2` — **deprecated-on-use**, see `[[bbspace-xs2-deprecated-use-named-const]]`). 2×`dynamic booking`→`BookingModel` + redundant `as` casts dropped (freezed types verified).
- **F6** — new `_TabletGrid` (handoff `BookingDetailTablet`): full-width cover/pending/guest + 2-col [stay·notes·activity | status·price·meta] (kept all cards — data over mock). Engages ≥`_kTabletGridMinWidth`=720; 600–719 → wide single column (293px columns at 600 were cramped + overflowed).

**Robustness (overflow test surfaced 3 pre-existing latent overflows; 0 visual change for real content):**
- `_BDCover` property eyebrow non-`Flexible` → `Flexible`+ellipsis (long property names overflowed the cover Row).
- `_TimelineRow` text non-`Expanded` → `Expanded`+ellipsis (overflowed at narrow widths).
- 2-col threshold 720 (vs naive 600).

**Test:** `@visibleForTesting buildBookingDetailContentForTest(ownerBooking, width)` seam + `owner_booking_detail_layout_test.dart` — 8 breakpoints × light/dark × {normal, long-string} + 4 status variants = **44 cells**, `tester.takeException` overflow gate. `detailActionVisibility` + its 5-case test untouched (preserve). Navigator.push FROZEN (widget tree) untouched.

**Verification:** `flutter analyze` 0 · `dart format` · gate **5/5** · overflow **44/44** · live Flutter light render desktop+tablet (`audit-shots/bd-flutter-*.png`, uncommitted) — F1 soft-pink + F6 2-col + layout fidelity confirmed. Dark = the 127 token ladder (operator-verified on 127 branch; scratch-harness dark unreliable, not a screen bug). **Deferred:** owner PROD deploy batch (still 0 in PROD); F3 notif bell; l10n debt (~40 hardcoded HR strings).

---

## §9 — Re-compare pass (operator-requested "what did I miss")

Re-read `booking-detail.jsx` vs the applied screen. Applied (analyze 0, overflow 44/44, gate 5/5 still green):
- **F7 cover shadow** — handoff `BDCover` has `shadow-sm`; the app cover had border only. Added `BBShadow.resting(context)` via a `DecoratedBox` **outside** the `ClipRRect` (a shadow on the clipped child clips away — same pattern as the Timeline grid card).
- **Cover scrim hex → consts** — `_kCoverScrimStrong`/`_kCoverScrimClear`/`_kCoverDotColor` (the 3 raw `Color(0x…)` over-photo scrim values; legit "kept" scrim, now named).

**Flagged, NOT applied (needs a product call):**
- **Dead guest mail/call buttons** — `_RoundIconButton(icon: 'mail'/'call', onPressed: null)` render but do nothing. `url_launcher ^6.3.1` is available → could wire call→`tel:`, mail→`mailto:` (or the existing `showSendEmailDialog`). The handoff shows them but is a static mock, so the wiring target is a UX decision, not handoff-mandated. Awaiting operator.

**Re-confirmed deliberate keeps:** F3 notif bell (odd on a back-button detail route), print/share parked (`onPressed: null`, honest — no PDF/share generator), F2 `…` overflow replaced by explicit complete/cancel, F5 data-honest timeline.

**Render matrix** (operator-requested): `audit-shots/bd-{light,dark}-{desktop,tablet,mobile}.png` (6 frames; dark via explicit `theme: AppTheme.darkTheme` — `themeMode` didn't propagate brightness through the seam context). Native sim smoke: **Android blocked** (no AVD), **iOS iPhone-only** (no iPad sim → can't test F6 tablet natively); web `:8091` covers all breakpoints live.
