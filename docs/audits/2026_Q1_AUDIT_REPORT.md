# Quarterly Full Regression & Integrity Check Report [Q1 2026]

**Date:** 2026-03-02
**Version Analyzed:** 1.0.10+20
**Scope:** Full application integrity, architecture drift, git hygiene, and dependency consistency.

## 1. Critical Flow Verification

| Flow | Status | Findings |
|---|---|---|
| **Booking Flow** | ✅ Intact | Widget screens, `atomicBooking.ts`, Stripe, and FCM logic are correctly wired. Handled by rigorous Cloud Functions tests (passing). |
| **iCal Sync Flow** | ✅ Intact | The hub-and-spoke models in `icalSync.ts`, `echoDetection.ts`, and `icalExport.ts` map perfectly. The tests for these functions run successfully. |
| **Auth Flow** | ✅ Intact | Apple Sign-In fix applied properly. Native and Web configurations correspond well to the intended flows. |
| **Trial/Subscription Flow** | ✅ Intact | `checkTrialExpiration.ts` and `sendTrialExpirationWarning.ts` align with definitions in `index.ts`. Lifetime license configuration is correct. |

## 2. Cross-File Reference Integrity

- **Dead Imports:** None found in `router_owner.dart` or `router_widget.dart` (only `package:` and standard Dart libraries resolved externally).
- **Exported Cloud Functions:** `functions/src/index.ts` accurately maps to the `.ts` files inside `functions/src/`. No missing exports detected.
- **Provider References:** Generated `.g.dart` Riverpod providers correctly resolve internal references; no 'does not exist' errors discovered.

## 3. Configuration Consistency

- **`pubspec.yaml`**: Points to App Version `1.0.10+20`. All configurations appear updated and correctly target modern stable dependency thresholds as expected for the release.
- **`firebase.json`**: Accurate targeting for `owner`, `widget`, and `admin` hosting deployments. Emulators are explicitly set up.
- **Android Configurations (`build.gradle.kts`)**: App properly reflects the configured Flutter Gradle versions and targets. Explicitly uses plugin `8.9.1` and `Kotlin 2.1.0` per memory rules.
- **iOS Configurations (`Podfile` / `project.pbxproj`)**: `IPHONEOS_DEPLOYMENT_TARGET` perfectly aligns at `15.0`.
- **Web PWA Manifest (`manifest.json`)**: Configured correctly with `display: "standalone"` and relevant icons.

## 4. Documentation vs. Code Drift

- **Frozen Files:** `CLAUDE.md` accurately tracks the frozen state. Files like `unified_unit_hub_screen.dart` and `firebase_booking_calendar_repository.dart` were properly identified and ignored during refactors.
- **Firestore Collections Structure:** `firestore.rules` mirrors the collections strategy precisely, including subcollection setups and clear notes regarding legacy deprecated structure elements. No unexpected rules found.

## 5. Git Hygiene

- **Merge Conflict Markers:** Clean. No unresolved `<<<<<<<`, `=======`, or `>>>>>>>` tokens found in the codebase.
- **Debug Statements:** Minimal `print()` statements exist, and those present are correctly documented as parts of debugging services or wrapped securely.
- **TODOs:** Routine codebase scan yielded one active TODO debug artifact (`lib/features/owner_dashboard/presentation/providers/ai_chat_provider.dart:475`), which was safely removed by applying a standard, localized error message response for users.

---

## Conclusion
The application is strictly conforming to architectural requirements and constraints. All tests assert intended logic correctly, and web target release builds are operational. The single found UX glitch (TODO artifact string logged to users) was successfully fixed. The overall health of the codebase is **EXCELLENT**.