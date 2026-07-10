# audit/admin-users-tabcounts — admin Users status TAB-COUNTS (data-honest omit built real)

**Date:** 2026-07-10 · **Scope:** DEV-ONLY (bookbed-dev), NO PROD deploy · **Branch:** `feat/admin-users-status-tabcounts`

## Context

Handoff `design_handoff/source/admin-users.jsx` `AU_TABS` shows status tabs
(All / Active / Trial / Suspended) each with a COUNT badge. #860 (list + cards +
pagination) and #864 (master-detail) shipped the screen but OMITTED the tab-counts
because they needed aggregation. Operator GO to build the omit for real, DEV only.

## Recon → count-source decision

- Screen loads owners via `ownersListProvider` (cursor-paginated, 20/page). A
  client-side count of the loaded set is PARTIAL → not data-honest for "of N".
- `admin_users_repository.getDashboardStats()` already proves Firestore `.count()`
  aggregation works over the whole `users` collection (7 existing `.count()`
  callers). Admin already reads full user docs under existing Firestore rules —
  **no callable, no rules change** → no emulator/jest needed.
- `accountStatus` is a REAL Firestore field (`trial` | `active` | `trial_expired`
  | `suspended`, set by `updateUserStatus` CF) but was NOT on `UserModel`
  (read-only via `getUserAccountStatus`). To filter the loaded list by status the
  field had to land on the model.

**Decision:** real per-status `.count()` aggregates (NOT a misleading partial).
Tab set = handoff AU_TABS. `trial_expired` (a real status with no handoff tab) is
FOLDED into the Trial tab — badge sums both keys, filter matches both.

## Build

- `UserModel.accountStatus` (`String?`, JSON key `accountStatus`) — raw, no enum
  coercion so an unrecognised value shows verbatim; missing → null. Regenerated
  `.freezed`/`.g` (diff = the one field only).
- `AdminUsersRepository.getStatusCounts()` → 5 `.count()` queries (all/active/
  trial/trial_expired/suspended). A failed query DROPS its key (no fabricated 0).
  New `ownerStatusCountsProvider` (FutureProvider).
- `users_list_screen.dart`: `_StatusTab` enum (All/Active/Trial/Suspended),
  `_StatusTabs` ConsumerWidget row above the search input (BbChip `tab` variant +
  count badge, dark console tokens via existing palette), single-select nav tab
  (`_selectedStatus`, default `all`). Wired into `_filterAndSortOwners`
  (accountStatus match), `_hasActiveFilters`, `_clearAllFilters`. Preserves #860
  pagination/cards, #862 search, #864 master-detail, #765 overflow (all untouched;
  full admin suite green).
- Badge honesty: no keys → no badge (null), never `0`. Trial badge = trial +
  trial_expired.

## Verify

- `dart format` clean; `flutter analyze lib/features/admin lib/shared/models` = 0.
- New `users_list_status_tabs_test.dart` — 12 cells: handoff tab-set order, badge
  counts from injected aggregate (incl. Trial fold 20+6=26), null-not-0 on empty,
  accountStatus filter matching, `_StatusTabs` widget render (labels + badges),
  tab-tap selection report. All green.
- Full admin suite 33 green; `user_model_test` 54 green; **full `flutter test`
  = +1769 all passed** (0 fails).
- No golden baselines touch this screen (nothing to re-bless).
- Web eyeball: seam-golden RepaintBoundary capture (Inter loaded) — renders
  All 248 / Active 210 / Trial 26 / Suspended 12, All selected, matches AU_TABS.

## Not done / deferred

- No PROD (rules unchanged, no callable). DEV admin site not auto-deployed —
  redeploy per `.claude/rules/admin.md` when smoking on bookbed-admin-dev.
- `_selectedStatus` counts as an active filter (disables Load-More auto per
  existing convention); the badge still shows the true aggregate total while the
  filtered LIST is the loaded matching subset (extendable via Load more) — honest:
  badge = real total, list = loaded rows.
