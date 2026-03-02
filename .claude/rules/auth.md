---
paths:
  - "lib/features/auth/**"
  - "lib/**/enhanced_auth_provider*"
  - "functions/src/auth*"
  - "functions/src/emailVerification*"
  - "functions/src/password*"
---

# Authentication System

## Apple Sign-In

- Apple only provides name on FIRST sign-in. Subsequent logins return null for name/email.
- Must save data on first login via `_createUserProfile()`.
- `profileCompleted` defaults to `true` for social sign-in (no forced form — Apple Guideline 4.0).
- Button label MUST be `'Sign in with Apple'` (Apple HIG).
- `_checkAppleCredentialState()` — fire-and-forget check on app launch (iOS only).
- Entitlements file MUST be referenced in `project.pbxproj` — having it on disk alone is not enough.

## Google Sign-In

- Uses `GoogleSignIn().signIn()` for native mobile (Android/iOS).
- Web flow uses `signInWithPopup(GoogleAuthProvider())`.
- `googleSignIn.signOut()` before `signIn()` to force account picker.
- `signOut()` clears cached account from Google SDK, does NOT log out from Firebase Auth.

## Email Verification

- Initial 30-second cooldown when screen opens (prevents Firebase rate limit).
- `updateEmail()` now also updates `userModel.email` in state.
- `resendEmailChangeVerification()` for re-sending to new email.
- Password dialog required for email change resend (`verifyBeforeUpdateEmail()` requires recent auth).

## Remember Me

- `SecureStorageService` saves only email (NOT password — SF-007).
- Platform-specific encryption: Android EncryptedSharedPreferences, iOS Keychain.

## Provider Cache Security — KRITIČNO

Providers with `keepAlive: true` MUST watch auth state (`ref.watch(enhancedAuthProvider)`) if they depend on current user. Otherwise data leaks between user sessions.

**Example**: Owner A logs out, Owner B logs in → sees Owner A's data if provider uses `FirebaseAuth.instance.currentUser` instead of `ref.watch(enhancedAuthProvider)`.

## Navigation Pattern

Always use `context.canPop()` check with GoRouter fallback instead of raw `Navigator.pop()`:
```dart
if (context.canPop()) {
  context.pop();
} else {
  context.go('/owner/properties');
}
```
