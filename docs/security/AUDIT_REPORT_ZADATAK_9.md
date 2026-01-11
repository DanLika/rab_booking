# Security Audit Report (Zadatak 9)

## 9.1 Password Handling

### 1. Lozinka se NE sprema u local storage
**Status:** ✅ **PASS**
- **Verification:** The `SecureStorageService` (lib/core/services/secure_storage_service.dart) explicitly deletes any legacy passwords (`_storage.delete(key: 'saved_password')`) and refuses to store new ones (Security Fix SF-007).
- **Implementation:** The 'Remember Me' functionality only stores the email address, never the password.

### 2. Lozinka se NE logira u console
**Status:** ✅ **PASS**
- **Verification:** Review of `EnhancedLoginScreen.dart` and `EnhancedAuthNotifier.dart` confirms that logging statements only output boolean flags (e.g., `Is password error: $isPassError`) or generic error messages.
- **Redaction:** `EnhancedAuthNotifier` includes explicit logic to redact sensitive fields (password, token, iban, etc.) from debug logs.

### 3. Password field obscured
**Status:** ✅ **PASS**
- **Verification:** Both `EnhancedLoginScreen` and `EnhancedRegisterScreen` use `obscureText: true` (via `_obscurePassword` state variable) for password input fields.
- **UX:** A toggle is provided to users to briefly reveal the password, which is standard secure UX.

## 9.2 Token/Session Security

### 1. Firebase ID token refresh
**Status:** ✅ **PASS**
- **Verification:** The application relies on the standard Firebase Auth SDK which handles automatic ID token refreshment in the background. `EnhancedAuthNotifier` listens to `authStateChanges()` to maintain synchronization.

### 2. Session invalidation on logout
**Status:** ✅ **PASS**
- **Verification:** `EnhancedAuthNotifier.signOut()` calls `_auth.signOut()`, which properly invalidates the client session.
- **Enhanced Security:** A strict `signOutFromAllDevices()` method is implemented, which triggers a Cloud Function (`revokeAllRefreshTokens`) to invalidate all refresh tokens on the backend, effectively forcing a logout on all devices.

### 3. No sensitive data in URL parameters
**Status:** ✅ **PASS**
- **Verification:** Router configuration (`router_owner.dart`) does not pass passwords or persistent session tokens in URLs.
- **Access Tokens:** The `/view` route uses a `token` parameter. This is a dedicated `bookingAccessToken` (generated in `bookingAccessToken.ts`), which is:
    - Cryptographically secure (32 bytes random).
    - Hashed before storage (SHA-256).
    - Time-limited (expires after checkout).
    - Scope-limited (only allows viewing a specific booking).
    - This follows the standard "magic link" security pattern.

## 9.3 Rate Limiting

### 1. IP-based rate limiting (Cloud Function)
**Status:** ✅ **PASS**
- **Verification:**
    - `bookingAccessToken.ts`: `verifyAccessToken` calls `checkRateLimit` using the client IP (`token_verify:${clientIp}`).
    - `EnhancedAuthNotifier.dart`: Calls `checkLoginRateLimit` and `checkRegistrationRateLimit` Cloud Functions before authentication attempts, ensuring IP-based protection against brute-force attacks.

### 2. Email-based rate limiting (Firestore)
**Status:** ✅ **PASS**
- **Verification:**
    - `rateLimit.ts`: The `enforceRateLimit` function uses Firestore transactions (`users/{userId}/rate_limits/{action}`) to track and limit actions per user/email.
    - `EnhancedAuthNotifier.dart`: Checks `_rateLimit.checkRateLimit(email)` on the client side (backed by Firestore) to prevent spam attempts even before hitting Firebase Auth.

### 3. Lockout durations are reasonable
**Status:** ✅ **PASS**
- **Verification:**
    - Token verification: 10 attempts per 60 seconds (1 minute).
    - Login/Registration: Configurable windows (typically 1 minute to 1 hour depending on severity).
    - The implementation allows for both "fail-closed" (secure) and "fail-open" (availability) configurations depending on the criticality of the action.

## Conclusion
The application meets all security requirements specified in Zadatak 9. No critical vulnerabilities were found in the audited areas.
