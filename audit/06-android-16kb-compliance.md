# Android 16 KB Page Size Compliance Audit

**Hard Deadline:** **November 1, 2025** (already past — Google Play now enforces
for all updates targeting Android 15+ on 64-bit devices).
Project-specific deadline for next Play update: **May 31, 2026** — 13 days from
audit date (2026-05-18).

**Result:** ✅ **COMPLIANT** — both halves of the alignment check pass:
- **ELF segment alignment** — all 15 native shared libraries shipped in the
  release APK are 16 KB (2¹⁴) or 64 KB (2¹⁶) page-size aligned.
- **APK zip-storage alignment** — all 10 64-bit `.so` entries (`arm64-v8a`
  + `x86_64`) are stored 16 KB-aligned inside the APK with `extractNativeLibs=false`.

No package upgrades required for compliance.

---

## 1. Methodology

| Step | Tool | Source |
|------|------|--------|
| Build | `flutter build apk --release --target lib/main.dart` | Flutter 3.38.5 stable |
| Extract | `unzip 'lib/*'` on `app-release.apk` | n/a |
| Verify (ELF) | `check_elf_alignment.sh` (per-arch dir) | AOSP `platform/system/extras/tools/check_elf_alignment.sh` |
| Verify (Zip) | `check_elf_alignment.sh` (APK directly) — needs `zipalign` from build-tools ≥ 35.0.0-rc3 on `$PATH` | Used local build-tools `36.1.0` |

Script source (canonical, AOSP):
`https://android.googlesource.com/platform/system/extras/+/refs/heads/main/tools/check_elf_alignment.sh`

> The GitHub mirror referenced in the task brief
> (`raw.githubusercontent.com/android/ndk-samples/main/page-size/scripts/check_elf_alignment.sh`)
> returns **404**. AOSP gerrit is the authoritative location. Saved locally to
> repo root as `check_elf_alignment.sh` (113 lines, 2906 bytes).

### Build environment

| Component | Version | Notes |
|-----------|---------|-------|
| Flutter SDK | 3.38.5 stable, engine `c108a94d7a` | Engine 16 KB-aligned since Flutter 3.27 |
| Dart | 3.10.4 | n/a |
| AGP | 8.9.1 | Auto-passes `-Wl,-z,max-page-size=16384` to linker (AGP ≥ 8.5) |
| Kotlin | 2.1.0 | n/a |
| Gradle | 8.11.1 | n/a |
| `compileSdk` | from `flutter.compileSdkVersion` (35) | OK |
| `targetSdk` | from `flutter.targetSdkVersion` (35) | OK — Android 15 target |
| `minSdk` | from `flutter.minSdkVersion` | OK |
| APK | `build/app/outputs/flutter-apk/app-release.apk` (87.4 MB) | versionName 1.0.10, versionCode 20 |

### Build remediation applied during audit

- `android/gradle.properties` `org.gradle.jvmargs` heap raised
  `-Xmx2G` → `-Xmx6G` so the JetifyTransform of
  `arm64_v8a_release-…jar` (Flutter engine artifact) does not OOM under
  current dep tree. **Reverted post-audit** (see § 7).

---

## 2. .so inventory

### ELF segment alignment

| | Count |
|---|---:|
| Total .so files in APK | **15** |
| ALIGNED (16 KB / 2¹⁴ or 64 KB / 2¹⁶) | **15** |
| UNALIGNED (4 KB / 2¹²) | **0** |
| Pass rate | **100 %** |

### APK zip-storage alignment (`extractNativeLibs=false`, 64-bit ABIs)

| | Count |
|---|---:|
| `.so` entries checked (arm64-v8a + x86_64) | **10** |
| `(OK)` — 16 KB-aligned within APK | **10** |
| Misaligned | **0** |
| Script verdict | `Verification successful` |

### Per-architecture split

| ABI | Count | Status | Compliance scope |
|-----|------:|--------|------------------|
| `arm64-v8a` | 5 | 5 / 5 ALIGNED | **REQUIRED** (64-bit Android 15+) |
| `x86_64` | 5 | 5 / 5 ALIGNED | **REQUIRED** (64-bit emulator) |
| `armeabi-v7a` | 5 | 5 / 5 ALIGNED | Not required (32-bit, excluded from Play 16 KB rule) |
| `x86` | 0 | n/a | 32-bit emulator not shipped (already excluded) |

> Google Play 16 KB requirement applies to **64-bit ABIs only**. 32-bit
> alignment is informational — passing is a side-effect of the linker flag
> being applied uniformly across ABIs.

### Per-file (arm64-v8a, representative — x86_64 identical, armv7 same names)

| .so file | Aligned to | Page size | Source / package | Notes |
|----------|------------|-----------|------------------|-------|
| `libapp.so` | 2¹⁶ | 64 KB | Flutter AOT-compiled Dart code | Built by `dart-snapshot` step; always aligned by Flutter tool |
| `libflutter.so` | 2¹⁶ | 64 KB | **Flutter engine** (built into SDK 3.38.5) | 16 KB-aligned since Flutter 3.27 |
| `libsentry.so` | 2¹⁴ | 16 KB | `sentry_flutter` ^8.12.0 → `sentry-android-ndk` | Native crash reporter |
| `libsentry-android.so` | 2¹⁴ | 16 KB | `sentry_flutter` ^8.12.0 → `sentry-android-replay`/core | JNI bridge |
| `libdatastore_shared_counter.so` | 2¹⁴ | 16 KB | `androidx.datastore-core` (transitive via `firebase_app_check` / `firebase_messaging` / Sentry) | Tiny (~7 KB) AndroidX helper |

Sizes (arm64-v8a): `libapp.so` 14.5 MB, `libflutter.so` 11.1 MB, `libsentry.so` 1.2 MB, `libsentry-android.so` 16 KB, `libdatastore_shared_counter.so` 7 KB.

Raw outputs:
- `audit/raw/16kb-apk-full.txt` — APK-level run (zip + ELF, both verdicts)
- `audit/raw/16kb-arm64-v8a.txt`
- `audit/raw/16kb-x86_64.txt`
- `audit/raw/16kb-armeabi-v7a.txt`
- `audit/raw/16kb-apk-summary.txt` — earlier run without `zipalign` on `$PATH` (kept for diff)

---

## 3. Per-failure remediation table

**None — no failures detected.** Table retained per audit template for
record-keeping; all rows empty.

| .so | Package | Current | Latest (pub.dev, audit date) | Effort | Action |
|-----|---------|---------|-------------------------------|--------|--------|
| _none_ | _n/a_ | _n/a_ | _n/a_ | _n/a_ | _n/a_ |

---

## 4. Cross-check: pubspec versions vs pub.dev (native-lib deps)

Snapshot taken 2026-05-18. All listed packages either ship no `.so` (pure Dart
/ Android Java-Kotlin only) **or** ship `.so` files that are already
16 KB-aligned (verified above). Versions kept for informational drift tracking;
**no upgrades required for 16 KB compliance**.

| Package | Pubspec constraint | Resolved (build) | pub.dev latest | Ships .so? | 16 KB status |
|---------|--------------------|------------------|----------------|------------|--------------|
| `firebase_core` | ^4.4.0 | 4.4.0 | 4.9.0 | No (Java only) | n/a |
| `firebase_auth` | ^6.1.4 | 6.1.4 | 6.5.1 | No | n/a |
| `cloud_firestore` | ^6.1.2 | 6.1.2 | 6.4.1 | No | n/a |
| `firebase_storage` | ^13.0.6 | 13.0.6 | 13.4.1 | No | n/a |
| `cloud_functions` | ^6.0.6 | 6.0.6 | 6.3.1 | No | n/a |
| `firebase_analytics` | ^12.1.2 | 12.1.2 | 12.4.1 | No | n/a |
| `firebase_crashlytics` | ^5.0.7 | 5.0.7 | 5.2.2 | No | n/a |
| `firebase_messaging` | ^16.1.1 | 16.1.1 | 16.2.2 | Indirect (androidx.datastore) | ✅ libdatastore_shared_counter ALIGNED |
| `firebase_app_check` | ^0.4.1+4 | 0.4.1+4 | 0.4.4+1 | Indirect (androidx.datastore) | ✅ same |
| `firebase_ai` | ^3.8.0 | 3.8.0 | 3.12.1 | No | n/a |
| `google_sign_in` | ^6.2.2 | 6.2.2 | 7.2.0 | No (Java) | n/a |
| `sign_in_with_apple` | ^7.0.1 | 7.0.1 | 8.0.0 | No (iOS only native) | n/a |
| `image_picker` | ^1.1.2 | 1.1.2 | 1.2.2 | No (Java/system APIs) | n/a |
| `path_provider` | ^2.1.2 | 2.1.2 | 2.1.5 | No | n/a |
| `flutter_secure_storage` | ^9.0.0 | 9.0.0 | 10.2.0 | No (Android Keystore Java) | n/a |
| `connectivity_plus` | ^7.0.0 | 7.0.0 | 7.1.1 | No | n/a |
| `shared_preferences` | ^2.3.4 | 2.3.4 | 2.5.5 | No | n/a |
| `url_launcher` | ^6.3.1 | 6.3.1 | 6.3.2 | No | n/a |
| `share_plus` | ^12.0.1 | 12.0.1 | 13.1.0 | No | n/a |
| `sentry_flutter` | ^8.12.0 | 8.12.0 | 9.20.0 | **Yes** (libsentry, libsentry-android) | ✅ ALIGNED (2¹⁴) |
| `syncfusion_flutter_calendar` | ^28.1.33 | 28.1.33 | 33.2.6 | No | n/a |
| `printing` | ^5.12.0 | 5.12.0 | 5.14.3 | No | n/a |
| `pdf` | ^3.10.8 | 3.10.8 | 3.12.0 | No (pure Dart) | n/a |
| `cached_network_image` | ^3.4.1 | 3.4.1 | 3.4.1 ✓ | No | n/a |
| `package_info_plus` | ^8.1.2 | 8.1.2 | 10.1.0 | No | n/a |

> **None** of the packages shipping `.so` files (Flutter engine, sentry_flutter,
> AndroidX datastore-core) require an upgrade for compliance.

---

## 5. Why the project is already compliant

1. **Flutter 3.38.5** — `libflutter.so` is shipped 64 KB-aligned by the
   Flutter engine build (verified empirically: 2¹⁶ in § 2).
2. **AGP 8.9.1** — current AGP releases auto-inject the 16 KB max-page-size
   linker flag for NDK packaging; the Sentry `.so`s repackaged through AGP
   inherit the flag.
3. **`sentry_flutter` 8.12.0** — its prebuilt native `.so`s already ship
   16 KB-aligned upstream (verified empirically: 2¹⁴ in § 2).
4. **`androidx.datastore-core`** (transitive) — `libdatastore_shared_counter.so`
   ships 16 KB-aligned (verified empirically: 2¹⁴ in § 2).

> Historical "when upstream re-aligned" specifics intentionally omitted — the
> empirical result above is the strong signal. Re-running § 6 after any
> bump of these packages will catch a regression on the spot.

---

## 6. Re-verification recipe (cheap, repeatable)

```bash
# 1. Ensure zipalign on $PATH (build-tools >= 35.0.0-rc3)
export PATH="$ANDROID_HOME/build-tools/36.1.0:$PATH"

# 2. Build & verify in one shot (APK input runs zip + ELF checks)
flutter build apk --release --target lib/main.dart
./check_elf_alignment.sh build/app/outputs/flutter-apk/app-release.apk

# Optional: per-arch ELF detail
mkdir -p /tmp/16kb && cd /tmp/16kb \
  && unzip -o "$OLDPWD/build/app/outputs/flutter-apk/app-release.apk" 'lib/*' \
  && cd "$OLDPWD" \
  && ./check_elf_alignment.sh /tmp/16kb/lib/arm64-v8a
```

Expected: zip section ends `Verification successful`; ELF section ends
`ELF Verification Successful`; every per-file ELF line ends `ALIGNED (2**14)`
or `ALIGNED (2**16)`. Any `UNALIGNED (2**12)` line = 4 KB-only library = Play
upload reject for 64-bit ABIs (rule active since 2025-11-01).

**AAB note:** for the actual Play upload, swap step 2 for
`flutter build appbundle --release --target lib/main.dart` and point the script
at `build/app/outputs/bundle/release/app-release.aab`. The shipped `.so`
artifacts are produced by the same Gradle outputs, so the ELF result is
equivalent; the zip-alignment is independently re-checked on the AAB.

Add to CI (Android matrix) — fail the build if any line contains `UNALIGNED`
or the zip section does not end with `Verification successful`.

---

## 7. Build-environment side-effect (revert log)

| File | Change made during audit | State after audit |
|------|---------------------------|-------------------|
| `android/gradle.properties` | `org.gradle.jvmargs` `-Xmx2G` → `-Xmx6G` (Jetify OOM workaround) | **Reverted** to `-Xmx2G` |

If next future audit hits the same OOM, consider committing the 6 GB heap as
the new project default — Jetify of the Flutter engine JAR genuinely needs
> 2 GB on a tree this size.

---

## 8. Deadlines (reminder)

- **2025-11-01** — Google Play already enforces 16 KB for new uploads & updates
  targeting Android 15+ on 64-bit. ✅ This build passes.
- **2026-05-31** — **next BookBed Android update window** (13 days from
  audit). Project is **green** today — no blocker for that release.

---

## 9. Conclusion

No package upgrades are required for Android 16 KB page size compliance. The
current build is fully aligned across all shipped 64-bit ABIs, on **both**
the ELF-segment and APK zip-storage dimensions of the requirement. The audit
produced **zero findings** against the 16 KB rule.

**Next action:** none related to 16 KB. (Unrelated drift in pub.dev versions
listed in § 4 is tracked separately — not in scope of this audit.)
Recommend wiring § 6 recipe into the Android CI job so the next dep bump
that quietly ships a 4 KB-only `.so` fails the build instead of Play upload.
