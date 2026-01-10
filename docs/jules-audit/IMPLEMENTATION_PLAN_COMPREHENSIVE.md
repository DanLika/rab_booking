# Implementation Plan - Comprehensive Audit Integration

## Goal Description
Integrate critical improvements from three feature branches to prepare the app for production and app store submission.
1.  **Image Picker Permissions** (`feat/PERM-001`): Explicit permission requests/rationale (Android 13+, iOS).
2.  **App Store Compliance** (`jules-app-store-compliance`): Privacy Manifests, EULA-compatible profile links, and mandatory Account Deletion.
3.  **Infrastructure & Monitoring** (`feat/SENTRY-001`): Update Sentry/Crashlytics integration for robust error tracking.

## User Review Required
- **Account Deletion**: I have added a [NEW] task to implement "Delete Account" in the Profile screen, as it was missing from the compliance branch but is **mandatory** for App Store approval.
- **Sentry/Crashlytics**: The new logging service directs Web errors to Sentry and Mobile errors to Crashlytics. This hybrid approach is best practice.

## Proposed Changes

### 1. Image Picker Permissions

#### [NEW] [permission_service.dart](file:///Users/duskolicanin/git/bookbed/lib/core/services/permission_service.dart)
#### [NEW] [platform_service.dart](file:///Users/duskolicanin/git/bookbed/lib/core/services/platform_service.dart)
#### [NEW] [service_providers.dart](file:///Users/duskolicanin/git/bookbed/lib/shared/providers/service_providers.dart)
#### [NEW] [permission_rationale_dialog.dart](file:///Users/duskolicanin/git/bookbed/lib/shared/widgets/permission_rationale_dialog.dart)
#### [NEW] [permission_denied_dialog.dart](file:///Users/duskolicanin/git/bookbed/lib/shared/widgets/permission_denied_dialog.dart)

#### [MODIFY] [profile_image_picker.dart](file:///Users/duskolicanin/git/bookbed/lib/features/auth/presentation/widgets/profile_image_picker.dart)
- Integrate permission flow.

#### [MODIFY] [unit_form_screen.dart](file:///Users/duskolicanin/git/bookbed/lib/features/owner_dashboard/presentation/screens/unit_form_screen.dart)
- Integrate permission flow for units.

### 2. App Store Compliance

#### [NEW] [PrivacyInfo.xcprivacy](file:///Users/duskolicanin/git/bookbed/ios/Runner/PrivacyInfo.xcprivacy)
- Apple-required privacy manifest declaring data usage.

#### [MODIFY] [Info.plist](file:///Users/duskolicanin/git/bookbed/ios/Runner/Info.plist)
- Add usage description strings.
- Ensure encryption compliance.

#### [MODIFY] [profile_screen.dart](file:///Users/duskolicanin/git/bookbed/lib/features/owner_dashboard/presentation/screens/profile_screen.dart)
- Add "Legal Documents" section: Terms, Privacy, Cookies.
- **[NEW] Add "Delete Account" button and confirmation dialog.**

#### [MODIFY] [build.gradle.kts](file:///Users/duskolicanin/git/bookbed/android/app/build.gradle.kts)
- Standardize SDK versions.

### 3. Infrastructure & Monitoring (Sentry)

#### [MODIFY] [pubspec.yaml](file:///Users/duskolicanin/git/bookbed/pubspec.yaml)
- Update `sentry_flutter` to `^9.9.2`.
- Ensure `firebase_crashlytics` is present.

#### [MODIFY] [logging_service.dart](file:///Users/duskolicanin/git/bookbed/lib/core/services/logging_service.dart)
- Implement hybrid Sentry (Web) / Crashlytics (Mobile) logging.

#### [MODIFY] [error_handler.dart](file:///Users/duskolicanin/git/bookbed/lib/core/errors/error_handler.dart)
- Connect to updated LoggingService.

### 4. Localization
#### [MODIFY] [app_en.arb](file:///Users/duskolicanin/git/bookbed/lib/l10n/app_en.arb)
#### [MODIFY] [app_hr.arb](file:///Users/duskolicanin/git/bookbed/lib/l10n/app_hr.arb)
- Add permission strings.
- Add legal section strings.
- Add delete account strings.

## Verification Plan
1.  **Permissions**: Verify Camera/Gallery access prompt on mobile.
2.  **Compliance**: Verify Privacy Manifest exists in iOS build. Verify "Delete Account" button appears and functions (mocked or real).
3.  **Monitoring**: Trigger a test error and verify it's logged (Sentry on Web, Console/Crashlytics on Mobile).
