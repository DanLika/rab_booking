# Jules AI Audit Prompts - Authentication Flow

Fokusirani promptovi za analizu authentication sistema.

**Kako koristiti:**
1. Kopiraj jedan prompt u Jules AI
2. Pričekaj analizu i kreiranje brancha
3. Pregledaj rezultate
4. Ponovi za sljedeći prompt

**Platforme za testiranje:**
- Web: Chrome, Safari, Firefox, Edge
- iOS: Safari, Chrome
- Android: Chrome, Samsung Internet
- Desktop: Windows, macOS, Linux

---

# 1. REGISTRATION FLOW

## REG-001: Registration Form Validation - Name Fields
```
Analyze name field validation in:
- lib/features/auth/presentation/screens/enhanced_register_screen.dart

Check for:
1. First name empty validation
2. First name minimum length (2 chars)
3. First name maximum length
4. First name special characters handling
5. Last name empty validation
6. Last name minimum length (2 chars)
7. Last name maximum length
8. Last name special characters handling
9. Real-time validation feedback
10. Error message clarity

Create fixes for any issues found.
Run: dart format . before committing.
```

## REG-002: Registration Form Validation - Email Field
```
Analyze email field validation in:
- lib/features/auth/presentation/screens/enhanced_register_screen.dart
- lib/shared/utils/validators/input_validators.dart

Check for:
1. Empty email validation
2. Invalid email format validation
3. Email with spaces handling
4. Email case sensitivity
5. Duplicate email check (Firebase)
6. Real-time validation feedback
7. Error message clarity
8. Autofill support (autocomplete attribute)

Create fixes for any issues found.
Run: dart format . before committing.
```

## REG-003: Registration Form Validation - Phone Field
```
Analyze phone field validation in:
- lib/features/auth/presentation/screens/enhanced_register_screen.dart
- lib/core/utils/profile_validators.dart

Check for:
1. Empty phone validation (if required)
2. Invalid phone format validation
3. Country code handling
4. Phone number length validation
5. Special characters handling (+, -, spaces)
6. Real-time validation feedback
7. Error message clarity
8. International format support

Create fixes for any issues found.
Run: dart format . before committing.
```

## REG-004: Registration Form Validation - Password Field
```
Analyze password field validation in:
- lib/features/auth/presentation/screens/enhanced_register_screen.dart
- lib/core/utils/password_validator.dart

Check for:
1. Empty password validation
2. Minimum length (8 chars)
3. Uppercase requirement
4. Lowercase requirement
5. Number requirement
6. Special character requirement
7. Sequential characters detection (abc, 123)
8. Common password blacklist
9. Password strength indicator accuracy
10. Real-time validation feedback
11. Error message clarity

Create fixes for any issues found.
Run: dart format . before committing.
```

## REG-005: Registration Form Validation - Confirm Password
```
Analyze confirm password validation in:
- lib/features/auth/presentation/screens/enhanced_register_screen.dart

Check for:
1. Empty confirm password validation
2. Password match validation
3. Real-time match checking
4. Error message when passwords don't match
5. Clear feedback when passwords match
6. Validation timing (on blur vs on change)

Create fixes for any issues found.
Run: dart format . before committing.
```

## REG-006: Registration Submit Button State
```
Analyze submit button behavior in:
- lib/features/auth/presentation/screens/enhanced_register_screen.dart

Check for:
1. Button disabled when form invalid
2. Button disabled during submission
3. Loading indicator during submission
4. Button enabled only when all fields valid
5. Prevent double submission
6. Clear visual state changes

Create fixes for any issues found.
Run: dart format . before committing.
```

## REG-007: Registration Error Handling
```
Analyze error handling in:
- lib/features/auth/presentation/screens/enhanced_register_screen.dart
- lib/core/providers/enhanced_auth_provider.dart

Check for:
1. Email already in use error
2. Weak password error
3. Network error handling
4. Firebase error mapping to user messages
5. Error message display (snackbar/inline)
6. Error state clearing on retry
7. No sensitive data in error messages

Create fixes for any issues found.
Run: dart format . before committing.
```

## REG-008: Registration Success Flow
```
Analyze success flow in:
- lib/features/auth/presentation/screens/enhanced_register_screen.dart
- lib/core/providers/enhanced_auth_provider.dart
- lib/core/config/router_owner.dart

Check for:
1. Success message display
2. Email verification email sent
3. Redirect destination after registration
4. User state after registration (logged in or not)
5. Email verification required before dashboard access
6. Clear success feedback to user

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 2. EMAIL VERIFICATION FLOW

## VERIFY-001: Email Verification Screen UI
```
Analyze email verification screen in:
- lib/features/auth/presentation/screens/email_verification_screen.dart

Check for:
1. Clear instructions displayed
2. Email address shown to user
3. Resend button available
4. Resend cooldown timer
5. Check verification status button
6. Loading states
7. Error handling

Create fixes for any issues found.
Run: dart format . before committing.
```

## VERIFY-002: Email Verification Backend
```
Analyze email verification backend in:
- functions/src/emailVerification.ts
- functions/src/emailService.ts

Check for:
1. Verification email sent on registration
2. Verification link expiration
3. Verification link security (token)
4. Resend rate limiting
5. Verification status check
6. Error handling

Create fixes for any issues found.
Run: dart format . before committing.
```

## VERIFY-003: Email Verification State Management
```
Analyze verification state in:
- lib/core/providers/enhanced_auth_provider.dart

Check for:
1. Email verified state tracking
2. Real-time verification status update
3. Redirect after verification
4. Unverified user restrictions
5. State persistence across app restart

Create fixes for any issues found.
Run: dart format . before committing.
```

## VERIFY-004: Unverified User Access Control
```
Analyze access control in:
- lib/core/config/router_owner.dart
- lib/core/providers/enhanced_auth_provider.dart

Check for:
1. Unverified user blocked from dashboard
2. Redirect to verification screen
3. Clear message about verification required
4. Allow logout for unverified users
5. Allow resend verification email

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 3. LOGIN FLOW

## LOGIN-001: Login Form Validation - Email
```
Analyze email validation in:
- lib/features/auth/presentation/screens/enhanced_login_screen.dart

Check for:
1. Empty email validation
2. Invalid email format validation
3. Real-time validation feedback
4. Error message clarity
5. Autofill support
6. Remember email option

Create fixes for any issues found.
Run: dart format . before committing.
```

## LOGIN-002: Login Form Validation - Password
```
Analyze password validation in:
- lib/features/auth/presentation/screens/enhanced_login_screen.dart

Check for:
1. Empty password validation
2. Password visibility toggle
3. Password visibility toggle tooltip
4. Real-time validation feedback
5. Error message clarity
6. Autofill support

Create fixes for any issues found.
Run: dart format . before committing.
```

## LOGIN-003: Login Submit Button State
```
Analyze submit button in:
- lib/features/auth/presentation/screens/enhanced_login_screen.dart

Check for:
1. Button disabled when form invalid
2. Button disabled during submission
3. Loading indicator during submission
4. Prevent double submission
5. Clear visual state changes

Create fixes for any issues found.
Run: dart format . before committing.
```

## LOGIN-004: Login Error Handling
```
Analyze error handling in:
- lib/features/auth/presentation/screens/enhanced_login_screen.dart
- lib/core/providers/enhanced_auth_provider.dart

Check for:
1. Wrong email error
2. Wrong password error
3. User not found error
4. Too many attempts error (rate limiting)
5. Network error handling
6. Error message display
7. No sensitive data in errors
8. Error state clearing on retry

Create fixes for any issues found.
Run: dart format . before committing.
```

## LOGIN-005: Login Success Flow
```
Analyze success flow in:
- lib/features/auth/presentation/screens/enhanced_login_screen.dart
- lib/core/providers/enhanced_auth_provider.dart
- lib/core/config/router_owner.dart

Check for:
1. Success message display
2. Redirect to dashboard
3. Email verification check before dashboard
4. Remember me functionality
5. Session persistence
6. Clear success feedback

Create fixes for any issues found.
Run: dart format . before committing.
```

## LOGIN-006: Login Rate Limiting
```
Analyze rate limiting in:
- lib/features/auth/presentation/screens/enhanced_login_screen.dart
- functions/src/authRateLimit.ts
- lib/core/services/rate_limit_service.dart

Check for:
1. Rate limit after failed attempts
2. Clear message about rate limit
3. Cooldown timer display
4. Rate limit bypass prevention
5. IP-based rate limiting
6. Account lockout handling

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 4. FORGOT PASSWORD FLOW

## FORGOT-001: Forgot Password Form Validation
```
Analyze form validation in:
- lib/features/auth/presentation/screens/forgot_password_screen.dart

Check for:
1. Empty email validation
2. Invalid email format validation
3. Real-time validation feedback
4. Error message clarity
5. Submit button state management

Create fixes for any issues found.
Run: dart format . before committing.
```

## FORGOT-002: Forgot Password Submit Flow
```
Analyze submit flow in:
- lib/features/auth/presentation/screens/forgot_password_screen.dart
- lib/core/providers/enhanced_auth_provider.dart

Check for:
1. Loading state during submission
2. Success message display
3. Email sent confirmation
4. Non-existent email handling
5. Rate limiting for reset requests
6. Clear instructions after submit

Create fixes for any issues found.
Run: dart format . before committing.
```

## FORGOT-003: Password Reset Email Backend
```
Analyze reset email in:
- functions/src/passwordReset.ts
- functions/src/emailService.ts

Check for:
1. Reset email sent correctly
2. Reset link expiration (1 hour)
3. Reset link security (token)
4. Rate limiting on reset requests
5. Email template clarity
6. Reset link URL correctness

Create fixes for any issues found.
Run: dart format . before committing.
```

## FORGOT-004: Password Reset Link Handling
```
Analyze reset link handling in:
- lib/core/config/router_owner.dart
- lib/features/auth/presentation/screens/forgot_password_screen.dart

Check for:
1. Deep link handling for reset URL
2. Token validation
3. Expired token handling
4. Invalid token handling
5. Redirect after successful reset

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 5. CHANGE PASSWORD FLOW

## CHANGE-001: Change Password Form Validation
```
Analyze form validation in:
- lib/features/owner_dashboard/presentation/screens/change_password_screen.dart

Check for:
1. Current password validation
2. New password validation (same as registration)
3. Confirm new password validation
4. New password different from current
5. Real-time validation feedback
6. Error message clarity

Create fixes for any issues found.
Run: dart format . before committing.
```

## CHANGE-002: Change Password Submit Flow
```
Analyze submit flow in:
- lib/features/owner_dashboard/presentation/screens/change_password_screen.dart
- lib/core/providers/enhanced_auth_provider.dart

Check for:
1. Current password verification
2. Loading state during submission
3. Success message display
4. Error handling (wrong current password)
5. Redirect after success
6. Session handling after password change

Create fixes for any issues found.
Run: dart format . before committing.
```

## CHANGE-003: Password History Check
```
Analyze password history in:
- functions/src/passwordHistory.ts
- lib/features/owner_dashboard/presentation/screens/change_password_screen.dart

Check for:
1. Password history enforcement
2. Number of previous passwords checked
3. Clear error message for reused password
4. Password history storage security

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 6. EDIT PROFILE FLOW

## PROFILE-001: Edit Profile Form Validation
```
Analyze form validation in:
- lib/features/owner_dashboard/presentation/screens/profile_screen.dart
- lib/core/utils/profile_validators.dart

Check for:
1. First name validation
2. Last name validation
3. Phone number validation
4. Profile image validation (size, format)
5. Real-time validation feedback
6. Error message clarity

Create fixes for any issues found.
Run: dart format . before committing.
```

## PROFILE-002: Edit Profile Submit Flow
```
Analyze submit flow in:
- lib/features/owner_dashboard/presentation/screens/profile_screen.dart
- lib/features/owner_dashboard/presentation/providers/user_profile_provider.dart

Check for:
1. Loading state during submission
2. Success message display
3. Error handling
4. Optimistic update with rollback
5. Image upload handling
6. Unsaved changes warning

Create fixes for any issues found.
Run: dart format . before committing.
```

## PROFILE-003: Profile Image Upload
```
Analyze image upload in:
- lib/features/auth/presentation/widgets/profile_image_picker.dart
- lib/shared/repositories/firebase/firebase_storage_repository.dart

Check for:
1. Image size limit
2. Image format validation
3. Upload progress indicator
4. Upload error handling
5. Image compression
6. Old image cleanup

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 7. SOCIAL LOGIN FLOW

## SOCIAL-001: Google Sign-In Flow
```
Analyze Google Sign-In in:
- lib/core/providers/enhanced_auth_provider.dart
- lib/features/auth/presentation/widgets/social_login_button.dart
- lib/features/auth/presentation/screens/enhanced_login_screen.dart
- lib/features/auth/presentation/screens/enhanced_register_screen.dart

Check for:
1. Google Sign-In button visibility
2. Loading state during sign-in
3. Error handling (cancelled, failed)
4. Account linking if email exists
5. New user creation flow
6. Success redirect
7. Works on iOS Safari
8. Works on Android Chrome

Create fixes for any issues found.
Run: dart format . before committing.
```

## SOCIAL-002: Apple Sign-In Flow
```
Analyze Apple Sign-In in:
- lib/core/providers/enhanced_auth_provider.dart
- lib/features/auth/presentation/widgets/social_login_button.dart
- lib/features/auth/presentation/screens/enhanced_login_screen.dart
- lib/features/auth/presentation/screens/enhanced_register_screen.dart

Check for:
1. Apple Sign-In button visibility (iOS/macOS only)
2. Loading state during sign-in
3. Error handling (cancelled, failed)
4. Account linking if email exists
5. New user creation flow
6. Success redirect
7. Hide email option handling
8. Works on iOS Safari

Create fixes for any issues found.
Run: dart format . before committing.
```

## SOCIAL-003: Social Login Account Linking
```
Analyze account linking in:
- lib/core/providers/enhanced_auth_provider.dart

Check for:
1. Email already exists handling
2. Link social account to existing email
3. Multiple social accounts per user
4. Unlink social account option
5. Clear error messages

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 8. SESSION MANAGEMENT

## SESSION-001: Session Persistence
```
Analyze session persistence in:
- lib/core/providers/enhanced_auth_provider.dart
- lib/core/services/secure_storage_service.dart

Check for:
1. Session persists across app restart
2. Session persists across browser refresh
3. Remember me functionality
4. Session timeout handling
5. Token refresh logic

Create fixes for any issues found.
Run: dart format . before committing.
```

## SESSION-002: Logout Flow
```
Analyze logout in:
- lib/core/providers/enhanced_auth_provider.dart
- lib/features/owner_dashboard/presentation/widgets/owner_app_drawer.dart

Check for:
1. Clear all session data
2. Clear cached credentials
3. Redirect to login screen
4. Logout from all devices option
5. Confirmation dialog before logout

Create fixes for any issues found.
Run: dart format . before committing.
```

## SESSION-003: Token Revocation
```
Analyze token revocation in:
- functions/src/revokeTokens.ts
- lib/core/providers/enhanced_auth_provider.dart

Check for:
1. Revoke all refresh tokens
2. Force re-authentication
3. Clear local tokens
4. Handle revoked token errors

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 9. REMEMBER ME & CREDENTIALS

## CRED-001: Remember Me Functionality
```
Analyze remember me in:
- lib/features/auth/presentation/screens/enhanced_login_screen.dart
- lib/core/services/secure_storage_service.dart
- lib/features/auth/models/saved_credentials.dart

Check for:
1. Remember me checkbox
2. Email saved securely
3. Password NOT saved (security)
4. Auto-fill on next login
5. Clear saved credentials on logout
6. Secure storage encryption

Create fixes for any issues found.
Run: dart format . before committing.
```

## CRED-002: Secure Storage
```
Analyze secure storage in:
- lib/core/services/secure_storage_service.dart

Check for:
1. Platform-specific encryption
2. iOS Keychain usage
3. Android EncryptedSharedPreferences
4. Web secure storage
5. No plaintext passwords
6. Clear on uninstall

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 10. CROSS-BROWSER COMPATIBILITY

## BROWSER-001: Safari Compatibility
```
Analyze Safari compatibility in:
- lib/features/auth/presentation/screens/enhanced_login_screen.dart
- lib/features/auth/presentation/screens/enhanced_register_screen.dart
- lib/core/providers/enhanced_auth_provider.dart

Check for:
1. Form autofill works
2. Password manager integration
3. Social login popups work
4. Keyboard handling
5. Input focus behavior
6. Touch events on iOS Safari

Create fixes for any issues found.
Run: dart format . before committing.
```

## BROWSER-002: Chrome Compatibility
```
Analyze Chrome compatibility in:
- lib/features/auth/presentation/screens/enhanced_login_screen.dart
- lib/features/auth/presentation/screens/enhanced_register_screen.dart

Check for:
1. Form autofill works
2. Password manager integration
3. Social login popups work
4. Android Chrome keyboard handling
5. Input focus behavior

Create fixes for any issues found.
Run: dart format . before committing.
```

## BROWSER-003: Mobile Browser Compatibility
```
Analyze mobile compatibility in:
- lib/features/auth/presentation/screens/enhanced_login_screen.dart
- lib/features/auth/presentation/screens/enhanced_register_screen.dart
- lib/core/utils/keyboard_dismiss_fix_mixin.dart

Check for:
1. Keyboard dismiss on tap outside
2. Keyboard doesn't cover inputs
3. Scroll when keyboard appears
4. Touch targets size (44x44 minimum)
5. Responsive layout on small screens

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 11. ACCESSIBILITY

## A11Y-001: Form Accessibility
```
Analyze form accessibility in:
- lib/features/auth/presentation/screens/enhanced_login_screen.dart
- lib/features/auth/presentation/screens/enhanced_register_screen.dart
- lib/features/auth/presentation/widgets/premium_input_field.dart

Check for:
1. Semantic labels on all inputs
2. Error messages announced by screen reader
3. Focus order logical
4. Color contrast WCAG AA
5. Touch targets 44x44 minimum
6. Keyboard navigation works

Create fixes for any issues found.
Run: dart format . before committing.
```

## A11Y-002: Button Accessibility
```
Analyze button accessibility in:
- lib/features/auth/presentation/widgets/gradient_auth_button.dart
- lib/features/auth/presentation/widgets/social_login_button.dart

Check for:
1. Semantic labels
2. Disabled state announced
3. Loading state announced
4. Focus indicator visible
5. Touch target size

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# 12. ERROR MESSAGES

## ERROR-001: Login Error Messages
```
Analyze login error messages in:
- lib/features/auth/presentation/screens/enhanced_login_screen.dart
- lib/l10n/app_en.arb
- lib/l10n/app_hr.arb

Check for:
1. "Wrong password" message clear
2. "User not found" message clear
3. "Too many attempts" message clear
4. "Network error" message clear
5. Messages in both languages
6. No technical jargon

Create fixes for any issues found.
Run: dart format . before committing.
```

## ERROR-002: Registration Error Messages
```
Analyze registration error messages in:
- lib/features/auth/presentation/screens/enhanced_register_screen.dart
- lib/l10n/app_en.arb
- lib/l10n/app_hr.arb

Check for:
1. "Email already in use" message clear
2. "Weak password" message clear
3. "Invalid email" message clear
4. "Passwords don't match" message clear
5. Messages in both languages
6. No technical jargon

Create fixes for any issues found.
Run: dart format . before committing.
```

---

# USAGE INSTRUCTIONS

## Recommended Order
1. REG-001 through REG-008 (Registration)
2. VERIFY-001 through VERIFY-004 (Email Verification)
3. LOGIN-001 through LOGIN-006 (Login)
4. FORGOT-001 through FORGOT-004 (Forgot Password)
5. CHANGE-001 through CHANGE-003 (Change Password)
6. PROFILE-001 through PROFILE-003 (Edit Profile)
7. SOCIAL-001 through SOCIAL-003 (Social Login)
8. SESSION-001 through SESSION-003 (Session)
9. CRED-001 through CRED-002 (Credentials)
10. BROWSER-001 through BROWSER-003 (Browser)
11. A11Y-001 through A11Y-002 (Accessibility)
12. ERROR-001 through ERROR-002 (Error Messages)

## Key Files Summary
**Flutter Auth Screens:**
- `lib/features/auth/presentation/screens/enhanced_login_screen.dart`
- `lib/features/auth/presentation/screens/enhanced_register_screen.dart`
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`
- `lib/features/auth/presentation/screens/email_verification_screen.dart`

**Flutter Auth Widgets:**
- `lib/features/auth/presentation/widgets/premium_input_field.dart`
- `lib/features/auth/presentation/widgets/gradient_auth_button.dart`
- `lib/features/auth/presentation/widgets/social_login_button.dart`

**Flutter Auth Provider:**
- `lib/core/providers/enhanced_auth_provider.dart`

**Flutter Validators:**
- `lib/core/utils/password_validator.dart`
- `lib/core/utils/profile_validators.dart`
- `lib/shared/utils/validators/input_validators.dart`

**Flutter Services:**
- `lib/core/services/secure_storage_service.dart`
- `lib/core/services/rate_limit_service.dart`

**Flutter Profile:**
- `lib/features/owner_dashboard/presentation/screens/profile_screen.dart`
- `lib/features/owner_dashboard/presentation/screens/change_password_screen.dart`

**Cloud Functions:**
- `functions/src/authRateLimit.ts`
- `functions/src/emailVerification.ts`
- `functions/src/passwordReset.ts`
- `functions/src/passwordHistory.ts`
- `functions/src/revokeTokens.ts`

**Localization:**
- `lib/l10n/app_en.arb`
- `lib/l10n/app_hr.arb`

---

**Total Prompts: 42**
- Registration: 8
- Email Verification: 4
- Login: 6
- Forgot Password: 4
- Change Password: 3
- Edit Profile: 3
- Social Login: 3
- Session Management: 3
- Credentials: 2
- Browser Compatibility: 3
- Accessibility: 2
- Error Messages: 2

**Created**: 2026-01-07
**For**: Jules AI (Google Labs)
**Project**: BookBed (rab_booking)
