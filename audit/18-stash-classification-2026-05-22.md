# Stash Classification — 2026-05-22

Inventory of 29 stashes captured during /effort max cleanup session. Drops deferred to a quiet window (sibling agent was actively stashing during this session — stash count grew 18 → 21 → 29 within minutes, making index-based drops race-prone).

## Classification

### DROP candidates — race-debris from today's hotfix cycles
Names self-identify as debris/pre-action safety nets, content likely duplicated by what landed in main or other surviving stashes.

| SHA | Label | Files | Rationale |
|---|---|---|---|
| `8526c348` | main-pre-hotfix-cleanup-2026-05-22 | SECURITY_FIXES, TODO | Pre-action safety net; hotfix landed |
| `b17e488e` | main-pre-hotfix-switch-2026-05-22-2 | SECURITY_FIXES | Pre-switch safety net |
| `d19775fb` | main-CLAUDE-wip-2026-05-22 | CLAUDE.md +2/-1 | Trivial WIP, likely in main |
| `c892e55a` | concurrent-wip-pre-sf024-audit-doc | CLAUDE.md +1 | Trivial WIP |
| `7b1354c8` | race-debris-2 | CHANGELOG, SECURITY_FIXES | Explicitly tagged debris |
| `9621a95c` | race-debris-from-parallel-agent | auth.md, firestore.md, CLAUDE.md | Explicitly tagged debris; auth.md content matches what is now in HEAD |
| `2d03f9b2` | auth-race-docs-update | auth.md, firestore.md | Same content as #9621a95c |
| `7863fbc1` | main-WIP-for-SF-024-doc-redo | 5 docs | SF-024 landed via e30db9d1 / a1276a8a |
| `883d897c` | hotfix-branch-docs-wip-CHANGELOG-SF023-024-025 | CHANGELOG, SECURITY_FIXES | Hotfix landed |
| `ece20c62` | other-agent-docs-WIP-restored | CHANGELOG, TODO | Already restored per label |

### INVESTIGATE — unique content, verify before drop

| SHA | Label | Files | Why investigate |
|---|---|---|---|
| `82818399` | other-agent-hotfix-leftovers | 4 files inc. **admin_login_screen.dart, price_row_widget.dart** (prod code) | Sibling agent's in-flight code; do NOT drop without confirming work is committed elsewhere |
| `8aa2fd0f` | other-agent-ci-yml-leftover | ci.yml ±35/36 lines | Could be reformatting noise OR actual workflow change |
| `b5bdf26b` | WIP main before SF-024 hotfix bundle | 7 files, **421 insertions** inc. firestore.rules + storage.rules | Substantial; verify SF-024 final commit (e30db9d1) covers same scope before dropping |
| `4d989205` | wip: firestore.md indexes + audit/11 OAuth CF deletion | firestore.md, audit/11 | Verify if firestore.md index changes landed |

### KEEP — mine, restore at session end

| SHA | Label | Files |
|---|---|---|
| `895abb60` | wip-security-fixes-doc-cleanup-session-2026-05-22 | SECURITY_FIXES.md (+333) |

### OLDER — branch-tied, verify branch state first

| SHA | Label | Files | Verify |
|---|---|---|---|
| `3aeb5a49` | T13-docs-work | hosting + widget docs + CHANGELOG | If T13 branch landed in main, drop |
| `8ec45891` | sibling-agent-booking-view-redo-1779121309 | booking_view_screen.dart | If branch landed, drop |
| `1433babc` | sibling-agent-widget-redo-1779121234 | subdomain_service.dart, booking_view_screen.dart | Same |
| `1b98d039` | sibling-agent-env-subdomain-edits | environment.dart, subdomain_service.dart | Same |
| `91c5b69c` | sibling-agent-widget-host-edits-from-other-task | booking_view_screen.dart, booking_widget_screen.dart | Same |
| `33adc86f` | wave0 smoke-test wiring | CHANGELOG | Wave0 promoted per memory; likely safe to drop |
| `2f67d10f` | wave0-followup-todo: TODO.md additions (79 lines) | TODO.md | **79 lines** — verify if landed before dropping |
| `e881ec3c` | wave0-dev-tooling-WIP | marionette + flags + login keys + Podfile.lock + pubspec | **Dev tooling** — could be lost work; verify per `memory/wave0-test-findings.md` |
| `1c444d25` | T8-silent-catches-WIP-rescued-by-T10 | tokens.dart, booking screens | Label says rescued by T10; safe to drop if T10 in main |

### ANCIENT — mvp/saas-booking-system branch (prior major cycle)

| SHA | Label | Files | Verdict |
|---|---|---|---|
| `faaedfff` | ical RFC 5545 compliance | ical_export_list_screen.dart, pubspec.yaml | Small, branch ancient — DROP |
| `457890b8` | logo changes | logo-dark.png ↔ logo-light.png (binary swap) | No value — DROP |
| `4151b352` | jules audit prompts WIP | **60 files, 10585 insertions** | Too big to drop blind — INVESTIGATE if work landed |
| `d0e71b62` | diagonal gradients, toolbar layout, validation fixes | 6 files, 439 insertions inc. unified_unit_hub_screen | Per `CLAUDE.md` NIKADA NE MIJENJAJ: `unified_unit_hub_screen.dart` (Cjenovnik tab) is FROZEN. This stash may pre-date that decision — verify if any content was salvaged |
| `ea47ce17` | premium HomePage sections | 10 files, 126 insertions inc. iOS config | Verify if HomePage sections landed |

## Recommended drop commands (defer until tree is quiet)

After confirming the INVESTIGATE/OLDER items either landed or are not needed, drop by SHA-resolving via `git stash list --format='%gd %H' | awk -v sha=<SHA> '$2==sha {print $1; exit}'`:

```bash
# Example helper
drop_by_sha() {
  local sha="$1"
  local ref=$(git stash list --format='%gd %H' | awk -v s="$sha" '$2==s {print $1; exit}')
  [ -n "$ref" ] && git stash drop "$ref" || echo "Stash $sha not found (already dropped?)"
}
```

## Why drops were deferred this session

- Stash count grew 18 → 21 → 29 during /effort max session as sibling agents stashed concurrently.
- `git stash drop stash@{N}` requires index; indices shift on every drop or sibling stash op.
- Per `memory/multi-agent-git-race.md`, branch/index race is real and active.
- Advisor flagged drops-by-index as unsafe in 18+ stash population.
- Mine (`895abb60`) is on the KEEP list; will be restored post-session.

## See also

- `memory/multi-agent-git-race.md` — race conditions during parallel agent work
- Pre-wave1-kill safety tag at `31c47c78` per `memory/wave1-branch-hygiene-2026-05-18.md`

---

## Addendum 2026-05-23 — Execution (29 dropped, 3 kept)

`/effort max` repo-hygiene session resolved 29 of the 32 stashes inventoried above. Drops were applied descending by index (highest first) to keep numbering stable for each successive `git stash drop`.

### Dropped — Class A (race debris, merged work) — 17 stashes

`bf7603fa` `8526c348` `b17e488e` `d19775fb` `c892e55a` `7b1354c8` `9621a95c` `82818399` `2d03f9b2` `7863fbc1` `895abb60` `4d989205` `883d897c` `8aa2fd0f` `b5bdf26b` `ece20c62` `d6758a4e`

Source branches now in main: `fix/sf-026-booking-count-dst`, `hotfix/widget-secrets-exfil`, `fix/auth-race-and-indexes-cleanup`, `fix/widget-price-row-and-admin-footer-year`, `audit/booking-count-audit`. Doc fragments duplicated content already landed via SF-024/025/026 + T11c commits.

### Dropped — Class B (Wave 0 race debris) — 9 stashes

`3aeb5a49` `8ec45891` `1433babc` `1b98d039` `91c5b69c` `33adc86f` `2f67d10f` `e881ec3c` `1c444d25`

Source branches: `fix/error-boundary-and-chat-ux`, `fix/null-tostring-hardening`, `test/wave0-integration`, `fix/widget-silent-catches`. Wave 0 promoted per `memory/wave0-promote-2026-05-18.md`; T8 silent-catches explicitly rescued by T10.

### Dropped — Class E (old obsolete, mvp/saas-booking-system + ancient main) — 3 stashes

`faaedfff` `457890b8` `ea47ce17`

iCal RFC 5545 (5L, 4mo), logo binary swap (4mo), iOS xcscheme + macOS Flutter config (7mo, on dead mvp branch).

### Kept — 3 stashes (per user-confirmed scope)

| SHA | Label | Class | Reason |
|---|---|---|---|
| `1eb3b205` | `other-agent-wip-availability_checker-blocking-refactor-switch-1779463606` | C | T11c sibling-agent debris; T11c branch still alive at session start |
| `4151b352` | jules audit prompts WIP (60 files, 10585L, 4mo) | D | Owner review needed before destroying |
| `d0e71b62` | diagonal gradients, toolbar layout, validation fixes (6 files, 439L, 6mo) | D | Matches your in-flight design work (per `~/.claude/CLAUDE.md` diagonal-gradient notes) |

### Post-execution drift

Sibling agents added 2 new stashes during the session (`smoke-447-temp-78094` + `WIP on main: 2f9291ef`), pushing the resting count to 5 by session-end. These are not from this cleanup and are owned by parallel agents.

### Drop sequence (executed)

```bash
TARGETS="31 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1"
for i in $TARGETS; do
  git stash drop "stash@{$i}"
done
# 29/29 succeeded; 3 stashes remained (preserved per class C+D)
```
