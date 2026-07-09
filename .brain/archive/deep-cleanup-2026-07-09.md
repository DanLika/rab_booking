# Archived: project deep cleanup — 2026-07-09

Working-tree + branch + dead-code sweep. Record so the knowledge survives.

## Disk 955 → 762 MB
Removed regenerable junk (`node-compile-cache`, `.firebase`, logs, empty dirs, `.DS_Store`); `.git` repacked −20 MB after branch deletions. Kept build deps.

## Branches
225 remote + 128 local stale branches deleted (squash-merged copies). Remote 249→24, local 136→8.

## Dead code — TESTED before delete (operator rule)
Dead-code manifests are candidates, not proof. Verify: remove-in-throwaway-worktree + `build_runner` + `flutter analyze` (main baseline = 0 errors → any new error = the file is USED). **Caught a false-positive:** `constraints_tokens.dart` reported "0 consumers" but `ConstraintTokens` used 16× via barrel export.

- ✅ proven dead (build clean without them): `error_handler.dart`, `cache_service.dart`, `auth_background.dart`, `line_art_icons.dart`, `saved_credentials.dart`(+freezed), `booking_details_dialog_v2.dart`, `lib/l10n/app_en.arb.bak`
- ❌ keep (used): `constraints_tokens.dart`
- ⚠️ dead-but-barrel-coupled: `glassmorphism_tokens.dart`

Deletion of the 7 proven-dead awaits operator GO. See memory `deadcode-verify-before-delete`.
