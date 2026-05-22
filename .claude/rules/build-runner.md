# Build Runner — fresh-clone + regen gotchas

## Why this exists

All `*.g.dart` files are gitignored (see `.gitignore`). They are generated from `@Riverpod`, `@freezed`, `@JsonSerializable`, etc. annotations by `build_runner`. A fresh clone has NO `.g.dart` files on disk, so the first `flutter build` / `flutter analyze` will report thousands of `uri_does_not_exist` / `undefined_identifier` errors — these are NOT real bugs.

## Fresh-clone fix

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Run from repo root. Takes 1-3 minutes the first time. Generates ~150 `.g.dart` files across `lib/`.

`--delete-conflicting-outputs` is required when:
- Stale `.g.dart` exists from a previous checkout of a different branch
- A `@Riverpod` provider was removed but its `.g.dart` still references it (also see CLAUDE.md Critical Learning #11 about `build_runner clean`)
- You see `[SEVERE] Conflicting outputs were detected...`

Without the flag, builder asks interactively whether to delete — which fails in non-TTY contexts (CI, agents).

## When to regenerate

| Trigger | Command |
|---------|---------|
| Fresh clone / `pubspec.yaml` dep change | `flutter pub get && dart run build_runner build --delete-conflicting-outputs` |
| Added/changed `@Riverpod`, `@freezed`, `@JsonSerializable` | Same |
| `flutter analyze` reports phantom errors after branch switch | Same |
| `build_runner build` reports `same` but you know code changed | `dart run build_runner clean` then build |

## Distinguishing phantom errors

If `flutter analyze` shows thousands of `uri_does_not_exist` errors targeting `~/.pub-cache/hosted/pub.dev/...`, the issue is **pub-cache desync**, not build_runner. Per CLAUDE.md TOOLING GOTCHA:

```bash
ls -d ~/.pub-cache/hosted/pub.dev/firebase_core-* 2>/dev/null
# If empty → run `flutter pub get` to re-download
```

build_runner errors target your `lib/**/*.g.dart` paths. Pub-cache errors target `~/.pub-cache/...`. Different fixes.

## CI

`.github/workflows/ci.yml` runs `dart run build_runner build --delete-conflicting-outputs` before `flutter analyze`. Mirror that locally on fresh checkouts to match CI signal.

## See also

- `CLAUDE.md` TOOLING GOTCHA section — `flutter analyze` phantom errors
- `CLAUDE.md` Critical Learning #11 — Syncfusion Calendar `build_runner clean` requirement
- `audit/04b-flutter-analyze-summary.md` — 6053 reported errors → 0 real
