# Implementation Plan - Compliance & Permissions Audit

## Goal Description
Integrate changes from two feature branches to ensure App Store compliance and robust permission handling.
1.  **Image Picker Permissions** (`feat/PERM-001`): Explicit permission requests/rationale (Android 13+, iOS).
2.  **App Store Compliance** (`jules-app-store-compliance`): Privacy Manifests, EULA-compatible profile links, and build configuration updates.

## User Review Required
- **Account Deletion**: The compliance branch seems to *miss* a dedicated Account Deletion flow, which is **mandatory** for App Store compliance. I have added this to the plan as a [NEW] feature.
- **Privacy Manifest**: `PrivacyInfo.xcprivacy` will be added.
- **Android Gradle**: `minSdk` might be updated.

## Proposed Changes

### 1. Image Picker Permissions (from `feat/PERM-001`)

#### [NEW] [permission_service.dart](file:///Users/duskolicanin/git/bookbed/lib/core/services/permission_service.dart)
#### [NEW] [platform_service.dart](file:///Users/duskolicanin/git/bookbed/lib/core/services/platform_service.dart)
#### [NEW] [service_providers.dart](file:///Users/duskolicanin/git/bookbed/lib/shared/providers/service_providers.dart)
#### [NEW] [permission_rationale_dialog.dart](file:///Users/duskolicanin/git/bookbed/lib/shared/widgets/permission_rationale_dialog.dart)
#### [NEW] [permission_denied_dialog.dart](file:///Users/duskolicanin/git/bookbed/lib/shared/widgets/permission_denied_dialog.dart)

#### [MODIFY] [profile_image_picker.dart](file:///Users/duskolicanin/git/bookbed/lib/features/auth/presentation/widgets/profile_image_picker.dart)
- Integrate permission flow.

#### [MODIFY] [unit_form_screen.dart](file:///Users/duskolicanin/git/bookbed/lib/features/owner_dashboard/presentation/screens/unit_form_screen.dart)
- Integrate permission flow for units.

### 2. App Store Compliance (from `jules-app-store-compliance`)

#### [NEW] [PrivacyInfo.xcprivacy](file:///Users/duskolicanin/git/bookbed/ios/Runner/PrivacyInfo.xcprivacy)
- Apple-required privacy manifest declaring data usage (Analytics, Crashlytics).

#### [MODIFY] [Info.plist](file:///Users/duskolicanin/git/bookbed/ios/Runner/Info.plist)
- Add usage description strings (`NSPhotoLibraryUsageDescription`, etc.) in Croatian/default.
- Ensure `ITSAppUsesNonExemptEncryption` is set to `false` (standard for standard encryption).

#### [MODIFY] [profile_screen.dart](file:///Users/duskolicanin/git/bookbed/lib/features/owner_dashboard/presentation/screens/profile_screen.dart)
- Add "Legal Documents" section: Terms, Privacy, Cookies.
- **[NEW] Add "Delete Account" button/flow (Critical for compliance).**

#### [MODIFY] [build.gradle.kts](file:///Users/duskolicanin/git/bookbed/android/app/build.gradle.kts)
- Standardize SDK versions if needed.

### 3. Localization
#### [MODIFY] [app_en.arb](file:///Users/duskolicanin/git/bookbed/lib/l10n/app_en.arb)
#### [MODIFY] [app_hr.arb](file:///Users/duskolicanin/git/bookbed/lib/l10n/app_hr.arb)
- Add permission strings.
- Add legal section strings.
- Add delete account strings.

## Verification Plan
- **Compliance**: Verify `PrivacyInfo.xcprivacy` exists in Xcode. verify "Delete Account" button appears in Profile.
- **Permissions**: Test Camera/Gallery access on Android/iOS.
