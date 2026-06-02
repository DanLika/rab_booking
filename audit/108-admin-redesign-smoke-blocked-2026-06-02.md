# Audit/108 — Admin Redesign Smoke BLOCKED on PR Gate (2026-06-02)

**Trigger:** Tier 3 smoke run requested against admin redesign surface to verify `BbCard` resolves to `BbAdminDarkTokens.panelBg` (`#2A2342`) visibly lighter than admin page bg (`#161621`), with owner surfaces unchanged (`#121212` dark / `#FFFFFF` light).

**Outcome:** **ABORTED at PRECONDITION.** Required PRs not yet merged to `main`.

## PR Gate State

`gh pr view` on `main @ 4d81e106`:

| PR  | Title | State | Merged |
|-----|-------|-------|--------|
| #646 | `redesign(admin): canonicalize admin shell surface to BbAdminDarkTokens.panelBg (#2A2342)` | OPEN | null |
| #647 | `redesign(primitive): BbCard resolves admin panelBg via context extension` | OPEN | null |

`main` HEAD carries:
- `866cc823` PR #643 — `BbAdminDarkTokens` ThemeExtension foundation (additive, NOT consumed by `BbCard` yet — that is #647's job).
- `47cc66f5` PR #645 — Admin Dashboard onto `Bb*` foundation (UI chrome only; sits ON #643's tokens but predates the canonical `panelBg` exposure on the primitive).

Neither commit puts `#2A2342` on `BbCard` in admin context. Sampling pixels now would assert against the wrong palette (whatever `BbCard` resolves to today: most likely owner `#1E1E1E` / `#FAFAFA` ThemeExtension defaults).

## What This Smoke Was Going To Check

1. **Admin elevation:** `BbCard` background in admin shell = `#2A2342` (panel), visibly distinct from shell `#161621` (`BbAdminDarkTokens.shellBg`). The whole point of #646+#647 is exposing card surface as a distinct elevation token rather than collapsing to shell bg.
2. **Owner non-regression:** `BbCard` in owner light = `#FFFFFF`, owner dark = `#121212`. No `BbAdminDarkTokens` bleed into owner trees (isolation-guard tests in PR #643 already enforce at unit level; smoke confirms at runtime).
3. **Functional regression:** `user_detail` grant → revoke (confirm dialog) → save → error banner (4s auto-dismiss). Independent of palette; tests admin shell still wires action flows correctly post-redesign.

All three checks require #646 + #647 on `main`.

## Unblock

When PRs merge:
1. `git pull --ff-only` on `main`, re-verify `git log --oneline -8 | grep -E "#64[67]\)"` returns both.
2. Re-run smoke per task spec — build web, apply Tier-3 admin auth bypass per [[canvaskit-tier3-screenshot-policy]] (JS-SDK direct `signInWithEmailAndPassword`), capture admin Dashboard / users_list / user_detail + one owner control screen, pixel-sample inside `BbCard` regions.
3. Assert: admin card == `#2A2342` AND owner card == `#FFFFFF` (light) / `#121212` (dark). Hex equality, not just "looks lighter."

## See Also

- `audit/103-redesign-tokens-primitives-shell.md` §Amendment Phase 1.7 — `BbAdminDarkTokens` design intent
- [[redesign-phase17-admin-dark-foundation]] memory — foundation merged PR #643, not yet consumed
- [[canvaskit-tier3-screenshot-policy]] — Tier-3 bypass recipe for post-login admin smoke
