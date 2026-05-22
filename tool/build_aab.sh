#!/usr/bin/env bash
#
# Build an Android App Bundle (AAB) for Play Store upload.
#
# Why this script exists:
#   `flutter build appbundle` fails because Flutter 3.38.5 still adds
#   flutter_native_splash (a dev-only dependency, build-time CLI tool) to
#   GeneratedPluginRegistrant.java despite its `dev_dependency: true` flag.
#   The package no longer ships a runtime Android plugin class, so Javac
#   blows up with:
#
#     error: package net.jonhanson.flutter_native_splash does not exist
#
#   `flutter build apk` does not exhibit this — only `bundleRelease` does.
#
# What this script does:
#   1. Runs `flutter pub get` (rewrites `.flutter-plugins-dependencies`).
#   2. Patches `.flutter-plugins-dependencies` to flip `native_build` to false
#      for the flutter_native_splash entry on every platform. This stops
#      Flutter's registrant generator from emitting the broken line.
#   3. Runs `flutter build appbundle` with whatever flags the caller passed.
#
# Usage:
#   tool/build_aab.sh                              # defaults to release + lib/main.dart
#   tool/build_aab.sh --release --target lib/main.dart
#   tool/build_aab.sh --debug   --target lib/main_dev.dart
#
# Reference:
#   - memory/aab-build-blocker.md
#   - audit/16-android-regression-full.md  Appendix C
#
set -euo pipefail

cd "$(dirname "$0")/.."

flutter pub get

python3 <<'PY'
import json, sys
path = ".flutter-plugins-dependencies"
with open(path) as f:
    data = json.load(f)
patched = 0
for platform in data.get("plugins", {}):
    for entry in data["plugins"][platform]:
        if entry["name"] == "flutter_native_splash" and entry.get("native_build"):
            entry["native_build"] = False
            patched += 1
with open(path, "w") as f:
    json.dump(data, f)
print(f"[build_aab] patched {patched} flutter_native_splash entries (native_build → false)", file=sys.stderr)
PY

if [[ $# -eq 0 ]]; then
    set -- --release --target lib/main.dart
fi

exec flutter build appbundle "$@"
