# audit/trial-progress-bar — owner Subscription trial hero, real data (2026-07-10)

**Scope:** owner Subscription (Pretplata) `_TrialHero` — replace hardcoded fake
trial numbers with LIVE data derived from the persisted trial window. Dev-only,
worktree `feat/trial-progress-bar` off origin/main `394d95d8`. FROZEN: none.

## Problem
`subscription_screen.dart` `_TrialHero` was a `StatelessWidget` with hardcoded
`_totalDays=14 / _daysLeft=12 / _endDate='10. lipnja 2026.'` — a mock. The
gradient hero, progress bar and copy never reflected the actual trial.

## Source decision — DERIVE (zero schema/CF/rules change)
`functions/src/auth/onUserCreate.ts` already writes `trialStartDate` +
`trialExpiresAt` (`TRIAL_DURATION_DAYS=30`). `TrialStatus` +
`trialStatusProvider` (StreamProvider on `users/{uid}`) already stream them.
Added to `trial_status.dart`: `totalTrialDays` (derived from the two bounds,
rounded, null when unavailable) + `getDaysElapsed({now})` (clamped `[0,total]`).

## Change
- `_TrialHero` → `ConsumerWidget`, watches `trialStatusProvider`.
- **Honest hide:** provider null / `!isInTrial` / bounds unpersisted →
  `SizedBox.shrink()` (never fabricate a total).
- `@visibleForTesting TrialBarData` (daysLeft/totalDays/endDate +
  `elapsedFraction`) + `fromTrialStatus(status, localeName, {now})` derivation,
  and `buildTrialHeroForTest(...)` provider-free render seam.
- l10n: `subscriptionTrialEyebrow` / `...DaysRemaining(daysLeft,totalDays)` /
  `...EndsShort(date)` / `...EndsInline(date)` (en+hr). Date via
  `DateFormat('d. MMMM yyyy', localeName)` (HR month genitive, no trailing dot —
  the inline sentence supplies the period).

## Verification
- `flutter analyze` subscription lib+test = 0; lib baseline unchanged (65 pre-existing infos, 0 net-new).
- New `trial_hero_test.dart` (8 cells): derivation (30d/12-elapsed→18-left,
  clamp-at-0, HR date, null for active/expired/suspended, null when bounds
  missing) + visual (bar+days for data, hidden for null, compact no-throw). Green.
- Full suite green (~336+); subscription golden (native-fallback path) unchanged — no re-bless.
- **Live web eyeball** (bookbed-dev `:8099`, `test-owner-2026-07-10@bookbed.io`,
  UID `PYPG9qLbs9YZtOr7KfKwLyUPPuh2`, seeded `accountStatus:trial`
  `trialExpiresAt 2026-08-08`): hero renders "VAŠ PLAN / Probni period /
  29 od 30 dana preostalo / Uživate sve Pro mogućnosti. Završava 9. kolovoza
  2026." with a 1/30 progress sliver — real data, correct HR date. Spotted +
  fixed a cosmetic double-period (`yyyy.` pattern + sentence dot); test updated.

## Wiring note
Per CLAUDE.md seam-test rule, the seam proves the FUNCTION; the live web eyeball
above closes the wiring gate (`_TrialHero` build() consumes the provider on the
running app).
