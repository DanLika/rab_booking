# Quiet Hours (Tihi sati) — build the data-honest omit

**Date:** 2026-07-10 · **Branch:** `feat/quiet-hours` · **Scope:** DEV-ONLY (bookbed-dev), NO PROD deploy · **Operator GO:** backend-for-omits.

## Context

The handoff `settings/notifications` shows a "Tihi sati" (quiet hours) control — a
daily start–end window during which push notifications are suppressed. It was a
**data-honest omit** in `notification_settings_screen.dart`: no backing
model/field, no enforcement. This audit builds the full vertical slice so the
toggle actually suppresses (data-honesty: a fake toggle is not shipped).

## Recon (pre-build)

- **UI:** `lib/features/owner_dashboard/presentation/screens/notification_settings_screen.dart`
  — `ConsumerStatefulWidget`, reads `notificationPreferencesProvider` (stream),
  writes via `userProfileNotifierProvider.notifier.updateNotificationPreferences`,
  `ref.invalidate` after save.
- **Model:** `lib/shared/models/notification_preferences_model.dart` — freezed
  `NotificationPreferences` at Firestore `users/{uid}/data/preferences`.
  `toFirestore()` serializes nested configs via `.toJson()`.
- **Repository:** `lib/shared/repositories/user_profile_repository.dart` —
  `updateNotificationPreferences` writes `data/preferences` with
  `SetOptions(merge: true)`.
- **Timezone:** NONE stored anywhere (`UserProfile` has no tz; app is UTC-naive;
  only crons hardcode `Europe/Zagreb`). → Decision: store an IANA `timezone`
  inside the quiet-hours config, default `Europe/Zagreb`, so the window is
  interpretable server-side.
- **Enforcement gate:** `functions/src/notificationPreferences.ts`
  `shouldSendPushNotification(userId, category)` is the single push gate — every
  push sender in `fcmService.ts` routes through it (line 105). → the honest hook.
- **Rules:** `firestore.rules` `users/{uid}/data/{document}` already permits the
  owner to write arbitrary keys (only a status/role/stripe blocklist bites);
  quiet-hours keys are NOT blocked → no rules edit needed, but a rules test was
  added to prove it (owner-write ALLOW, stranger DENY, blocklist still bites).

## Model / enforcement decisions

- **Model:** new freezed `QuietHours { enabled:bool, start:'HH:mm', end:'HH:mm',
  timezone:IANA }` nested in `NotificationPreferences` (default disabled,
  22:00→07:00, Europe/Zagreb). copyWith on the nested config — never
  reconstructed (CLAUDE.md).
- **Enforcement (PUSH ONLY):** in `shouldSendPushNotification`, after the
  category/master checks, `isQuietNow(prefs.quietHours)` suppresses the push.
  **Email + in-app/DB records are untouched** — nothing is lost, only the device
  buzz is withheld (data-preservation).
- **Time logic (no new dep):** pure predicates —
  `parseHhmmToMinutes`, `nowMinutesInTz` (DST-correct via `Intl.DateTimeFormat`
  with `timeZone`, fail-open to UTC on bad tz), `isWithinQuietWindow`
  (handles cross-midnight `start>end`; `start==end` = empty window, never quiet),
  `isQuietNow` (disabled/malformed = fail-open = NOT suppressed → never silently
  drop on bad config).
- **UI:** a "Tihi sati" `BbSectionHeader` + card — enable `BbSwitch` + start/end
  tappable time fields (native `showTimePicker`, 12px-radius inputs per CLAUDE.md)
  gated to show only when enabled + a cross-midnight hint line. Extracted
  `@visibleForTesting buildQuietHoursCard` seam. Saves via existing repository +
  `ref.invalidate`.
- **l10n:** 8 new keys `quietHours*` in `app_en.arb` + `app_hr.arb`.

## Verification

- `dart format` clean; `flutter analyze lib test` — 0 net-new (pre-existing
  golden-fixture infos only).
- Full `flutter test` — **1757 passed** (golden included; no baseline moved —
  this screen has no golden seam, nothing to re-bless).
- Widget seam: `notification_settings_screen_test.dart` +2 (section renders on
  screen via scroll; builder-seam proves time-fields hidden-when-disabled /
  shown-when-enabled + switch/start callbacks dispatch).
- CF unit: `functions/test/quietHours.test.ts` — **12 passed** (HH:mm parse,
  same-day + cross-midnight windows, tz shift + DST, disabled/malformed
  fail-open).
- Functions jest full — **475 passed / 24 suites**.
- Rules emulator full — **245 passed / 16 suites** (incl. 4 new
  `quiet_hours_prefs.test.ts` cases).
- Web eyeball: bookbed-dev owner, test-owner-2026-07-10, Tihi sati section
  screenshotted.

## FROZEN

None touched. `atomicBooking.ts` owner-email, timeline dims, Cjenovnik, publish
flow all untouched. Push gate change is additive after the existing category gate.

## Deferred

- PROD deploy (DEV-ONLY per operator GO). Deploying enforcement to PROD requires
  `firebase deploy --only functions` + the model/UI hosting deploy.
- Per-user timezone capture at onboarding (currently defaults Europe/Zagreb; a
  user in another tz keeps the default until we add a tz picker). Honest today
  because the config carries the tz and defaults to the app's home tz.
