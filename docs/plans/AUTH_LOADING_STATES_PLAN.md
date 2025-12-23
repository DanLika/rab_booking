# Authentication Loading States Implementation Plan

**Created**: 2024-12-21
**Completed**: 2025-12-23
**Status**: ✅ IMPLEMENTED
**Estimated Time**: 8-12 hours (1-2 days)

---

## 1. Feature Overview

### Problem Statement
Trenutno auth flow ima tri kritična UX problema:

1. **Avatar Upload** - Kada korisnik odabere sliku u registration screenu, ne prikazuje se loader dok se slika procesira (resize, quality reduction). Čini se kao da aplikacija "ne reaguje".

2. **Login Redirect** - Nakon klika na "Login", korisnik se automatski redirectuje na login page umjesto da vidi loader, pa tek 2-3 sekunde kasnije ide na dashboard.

3. **Register Redirect** - Nakon klika na "Create Account", isti problem - direktan redirect bez loadera.

### Who is it for?
- Property owners koji kreiraju račune i loguju se na BookBed Owner Dashboard
- Posebno važno za Android Chrome korisnike (trenutni test environment)

### Key Functionality
1. **Inline Avatar Upload Loader** - CircularProgressIndicator preko avatara dok se slika procesira
2. **Full-Screen Auth Loader** - Overlay loader tokom login/register operacija koji ostaje vidljiv do potpunog završetka navigacije
3. **Better Error Messages** - User-friendly poruke za Firebase Auth errore (već djelimično implementirano)
4. **Remember Me** functionality - Persistent login (iz prethodnog plana - Phase 5)

---

## 2. Current State Analysis

### Enhanced Login Screen (`enhanced_login_screen.dart`)
```dart
✅ Has _isLoading state variable (line 41)
✅ Has LoadingOverlay widget (line 370)
✅ Sets _isLoading = true at start of login (line 106)
❌ Problem: _isLoading = false is set BEFORE navigation (line 140)
❌ LoadingOverlay disappears before dashboard loads
```

### Enhanced Register Screen (`enhanced_register_screen.dart`)
```dart
✅ Has _isLoading state variable (line 47)
✅ GradientAuthButton shows loading state (line 230)
❌ NO LoadingOverlay widget (missing!)
❌ Sets _isLoading = false before navigation (lines 129, 134)
```

### ProfileImagePicker Widget (`profile_image_picker.dart`)
```dart
❌ NO loading state during image processing
❌ Silent try-catch hides errors (lines 46-48)
❌ Image.memory() widget može biti spor za velike slike
```

---

## 3. Technical Design

### Architecture Flow

```
USER ACTION                  STATE UPDATE              UI FEEDBACK
────────────────────────────────────────────────────────────────────

Avatar Click
    │
    ├─> Pick Image (async)
    │       │
    │       ├─> _isUploading = true ──> CircularProgressIndicator
    │       │                            overlay on avatar
    │       ├─> Resize/compress image
    │       │
    │       └─> _isUploading = false ─> Show new image
    │
    │
Login Button Click
    │
    ├─> _isLoading = true ────────────> LoadingOverlay appears
    │       │
    │       ├─> Firebase signIn()
    │       │
    │       ├─> Success?
    │       │   ├─> YES: Navigate to dashboard
    │       │   │        │
    │       │   │        └─> Loader stays visible until
    │       │   │             new screen mounts (widget disposes)
    │       │   │
    │       │   └─> NO: _isLoading = false
    │       │           Show error snackbar
    │
    │
Register Button Click
    │
    ├─> _isLoading = true ────────────> Full-screen LoadingOverlay
    │       │
    │       ├─> Firebase createUser()
    │       ├─> Upload avatar (if selected)
    │       ├─> Create Firestore document
    │       │
    │       ├─> Success?
    │       │   ├─> YES: Navigate to dashboard/verification
    │       │   │        Loader stays until navigation completes
    │       │   │
    │       │   └─> NO: _isLoading = false
    │       │           Show error
```

### State Management Strategy

**Riverpod Providers**:
- `enhancedAuthProvider` (existing) - main auth state
- NO new providers needed - component-level state je dovoljan

**Component State Variables**:
```dart
// ProfileImagePicker
bool _isUploading = false;  // NEW

// Login/Register Screens
bool _isLoading = false;    // EXISTING - keep behavior but DON'T set to false before navigation
```

---

## 4. Implementation Plan

### **Phase 1: Avatar Upload Loader** (2-3 hours)

**Goal**: Show inline loader during image selection/processing

#### Tasks:
- [x] Add `_isUploading` state variable to `ProfileImagePicker`
- [x] Set `_isUploading = true` when picker opens
- [x] Show `CircularProgressIndicator` overlay during upload
- [x] Set `_isUploading = false` after image loads
- [x] Test on Android Chrome (verify loader appears for 1-2 seconds)

#### Modified Files:
```
lib/features/auth/presentation/widgets/profile_image_picker.dart
```

#### Implementation Details:
```dart
class _ProfileImagePickerState extends State<ProfileImagePicker> {
  Uint8List? _imageBytes;
  bool _isHovered = false;
  bool _isUploading = false;  // NEW

  Future<void> _pickImage() async {
    setState(() => _isUploading = true);  // NEW

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _isUploading = false;  // NEW
        });
        widget.onImageSelected(bytes, image.name);
      } else {
        setState(() => _isUploading = false);  // NEW - cancelled
      }
    } catch (e) {
      setState(() => _isUploading = false);  // NEW - error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... existing code ...

    return Stack(
      children: [
        // Existing avatar content
        _buildImageContent(),

        // NEW: Loading overlay
        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withAlpha((0.6 * 255).toInt()),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

**Success Criteria**:
- ✅ Loader appears immediately when user picks image
- ✅ Loader disappears when image is ready
- ✅ Error handling shows snackbar instead of silent fail
- ✅ Works on Android Chrome physical device

---

### **Phase 2: Login Screen Loading Fix** (2-3 hours)

**Goal**: Keep loader visible during entire login → dashboard navigation

#### Problem Analysis:
```dart
// CURRENT CODE (enhanced_login_screen.dart:140)
if (authState.requiresEmailVerification) {
  setState(() => _isLoading = false);  // ❌ Removes loader too early!
  context.go(OwnerRoutes.emailVerification);
  return;
}

// Line 152 - same problem for dashboard navigation
```

#### Solution:
**DON'T set `_isLoading = false` before navigation on success.**
Let the widget dispose naturally when new screen mounts.

#### Tasks:
- [x] Remove `setState(() => _isLoading = false)` from success paths
- [x] Keep error paths that set `_isLoading = false`
- [x] Verify LoadingOverlay stays visible until dashboard loads
- [x] Test on Android Chrome

#### Modified Files:
```
lib/features/auth/presentation/screens/enhanced_login_screen.dart
```

#### Code Changes:
```dart
Future<void> _handleLogin() async {
  // ... validation code ...

  setState(() => _isLoading = true);

  try {
    await ref.read(enhancedAuthProvider.notifier).signInWithEmail(
      email: email,
      password: password,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 100));

    final authState = ref.read(enhancedAuthProvider);

    if (authState.error != null) {
      setState(() => _isLoading = false);  // ✅ Keep - error case
      _shakeForm();
      ErrorDisplayUtils.showErrorSnackBar(context, ...);
      return;
    }

    if (authState.requiresEmailVerification) {
      // ❌ REMOVE: setState(() => _isLoading = false);
      // ✅ Keep loader visible during navigation
      context.go(OwnerRoutes.emailVerification);
      return;
    }

    // Success - navigate to dashboard
    // ❌ REMOVE: setState(() => _isLoading = false);
    // ✅ Loader stays visible until widget disposes
    context.go(OwnerRoutes.overview);

  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;  // ✅ Keep - error case
      // ... error handling ...
    });

    _shakeForm();
    ErrorDisplayUtils.showErrorSnackBar(context, ...);
  }
}
```

**Success Criteria**:
- ✅ LoadingOverlay remains visible from login click to dashboard mount
- ✅ No flash of login screen before dashboard appears
- ✅ Error cases still remove loader correctly
- ✅ Android Chrome shows smooth transition

---

### **Phase 3: Register Screen Loading Fix** (2-3 hours)

**Goal**: Add full-screen loader + keep visible during navigation

#### Problems:
1. NO LoadingOverlay widget (only button loader)
2. Sets `_isLoading = false` before navigation (lines 129, 134)

#### Tasks:
- [x] Add `LoadingOverlay` widget to Scaffold Stack
- [x] Remove `setState(() => _isLoading = false)` from success paths
- [x] Keep error paths that set `_isLoading = false`
- [x] Test avatar upload + registration flow together

#### Modified Files:
```
lib/features/auth/presentation/screens/enhanced_register_screen.dart
```

#### Code Changes:
```dart
@override
Widget build(BuildContext context) {
  // ... existing code ...

  return Scaffold(
    resizeToAvoidBottomInset: true,
    body: Stack(
      children: [
        // Existing AuthBackground + form content
        AuthBackground(
          child: SafeArea(
            child: /* ... existing form ... */
          ),
        ),

        // NEW: Loading overlay
        if (_isLoading)
          const LoadingOverlay(
            message: 'Creating your account...',
          ),
      ],
    ),
  );
}

Future<void> _handleRegister() async {
  // ... validation ...

  setState(() => _isLoading = true);

  try {
    await ref.read(enhancedAuthProvider.notifier).registerWithEmail(
      email: sanitizedEmail,
      password: _passwordController.text,
      firstName: sanitizedFirstName,
      lastName: sanitizedLastName,
      phone: sanitizedPhone,
      acceptedTerms: _acceptedTerms,
      acceptedPrivacy: _acceptedPrivacy,
      newsletterOptIn: _newsletterOptIn,
      profileImageBytes: _profileImageBytes,
      profileImageName: _profileImageName,
    );

    if (!mounted) return;

    final authState = ref.read(enhancedAuthProvider);

    if (authState.error != null) {
      setState(() => _isLoading = false);  // ✅ Keep - error case
      ErrorDisplayUtils.showErrorSnackBar(context, authState.error);
      return;
    }

    if (authState.requiresEmailVerification) {
      // ❌ REMOVE: setState(() => _isLoading = false);
      // ✅ Keep loader visible
      context.go(OwnerRoutes.emailVerification);
      return;
    }

    // Success - navigate to dashboard
    // ❌ REMOVE: setState(() => _isLoading = false);
    context.go(OwnerRoutes.overview);

  } catch (e) {
    if (!mounted) return;

    final authState = ref.read(enhancedAuthProvider);
    final errorMessage = authState.error ?? e.toString();

    if (_isEmailError(errorMessage)) {
      setState(() {
        _emailErrorFromServer = /* ... */;
        _isLoading = false;  // ✅ Keep - error case
      });
      _formKey.currentState!.validate();
    } else {
      setState(() => _isLoading = false);  // ✅ Keep - error case
      ErrorDisplayUtils.showErrorSnackBar(context, errorMessage);
    }
  }
}
```

**Success Criteria**:
- ✅ Full-screen LoadingOverlay appears on register click
- ✅ Loader stays visible during avatar upload → account creation → navigation
- ✅ No premature loader dismissal
- ✅ Error cases properly remove loader

---

### **Phase 4: Error Message Improvements** (1-2 hours)

**Goal**: Ensure all Firebase Auth errors are user-friendly

#### Tasks:
- [x] Verify localization keys exist for all error codes
- [x] Add missing translations (HR + EN)
- [x] Test wrong password, wrong email, network errors
- [x] Ensure snackbar + inline field errors work together

#### Files to Check:
```
lib/l10n/app_en.arb
lib/l10n/app_hr.arb
lib/features/auth/presentation/screens/enhanced_login_screen.dart (lines 207-247)
```

#### Localization Keys Needed:
```json
// app_en.arb
{
  "errorWrongPassword": "Incorrect password. Please try again.",
  "errorUserNotFound": "No account found with this email.",
  "errorInvalidEmail": "Invalid email address.",
  "errorUserDisabled": "This account has been disabled.",
  "errorTooManyRequests": "Too many failed attempts. Please try again later.",
  "errorNetworkFailed": "Network error. Check your connection.",
  "errorPermissionDenied": "Permission denied.",
  "errorNotFound": "Resource not found.",
  "errorTimeout": "Request timed out.",
  "errorEmailInUse": "An account already exists with this email.",
  "pleaseFixErrors": "Please fix the errors above"
}
```

```json
// app_hr.arb
{
  "errorWrongPassword": "Pogrešna lozinka. Molimo pokušajte ponovo.",
  "errorUserNotFound": "Nije pronađen račun sa ovim emailom.",
  "errorInvalidEmail": "Nevažeća email adresa.",
  "errorUserDisabled": "Ovaj račun je onemogućen.",
  "errorTooManyRequests": "Previše neuspješnih pokušaja. Pokušajte kasnije.",
  "errorNetworkFailed": "Greška u mreži. Provjerite konekciju.",
  "errorPermissionDenied": "Pristup odbijen.",
  "errorNotFound": "Resurs nije pronađen.",
  "errorTimeout": "Zahtjev je istekao.",
  "errorEmailInUse": "Račun sa ovim emailom već postoji.",
  "pleaseFixErrors": "Molimo ispravite greške gore"
}
```

**Success Criteria**:
- ✅ All error codes have localized messages
- ✅ Both snackbar and inline errors show correct text
- ✅ HR and EN translations are accurate

---

### **Phase 5: Remember Me Functionality** (2-3 hours)

**Goal**: Save credentials securely when "Remember Me" is checked

#### Tasks:
- [x] Add `flutter_secure_storage` dependency
- [x] Create `SecureStorageService` singleton
- [x] Save credentials on successful login (if rememberMe = true)
- [x] Load credentials in `initState()` and auto-fill fields
- [x] Clear credentials on logout
- [x] Test persistence across app restarts

#### New Files:
```
lib/core/services/secure_storage_service.dart
lib/features/auth/models/saved_credentials.dart
lib/features/auth/models/saved_credentials.freezed.dart
```

#### Modified Files:
```
pubspec.yaml (add flutter_secure_storage: ^9.0.0)
lib/features/auth/presentation/screens/enhanced_login_screen.dart
lib/features/auth/presentation/providers/auth_provider.dart
```

#### Implementation:
See **Changelog 6.0** section in main CLAUDE.md for detailed code examples.

**Success Criteria**:
- ✅ Credentials saved only when checkbox is checked
- ✅ Auto-fill works on app restart
- ✅ Logout clears stored credentials
- ✅ Encrypted storage on Android (EncryptedSharedPreferences)

---

## 5. File Changes Summary

### New Files
```
lib/core/services/secure_storage_service.dart
lib/features/auth/models/saved_credentials.dart
lib/features/auth/models/saved_credentials.freezed.dart
```

### Modified Files
```
pubspec.yaml
  - Add flutter_secure_storage: ^9.0.0

lib/features/auth/presentation/widgets/profile_image_picker.dart
  - Add _isUploading state
  - Add loader overlay during image processing
  - Improve error handling

lib/features/auth/presentation/screens/enhanced_login_screen.dart
  - Remove _isLoading = false before successful navigation
  - Add auto-fill from secure storage (Phase 5)
  - Verify error messages use localization

lib/features/auth/presentation/screens/enhanced_register_screen.dart
  - Add LoadingOverlay widget to Stack
  - Remove _isLoading = false before successful navigation

lib/l10n/app_en.arb
  - Add error message keys (if missing)

lib/l10n/app_hr.arb
  - Add error message keys (if missing)
```

---

## 6. Dependencies

### Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

### Run after adding:
```bash
flutter pub get
```

---

## 7. Testing Strategy

### Manual Testing Checklist

#### Avatar Upload (Phase 1):
- [ ] Click avatar → picker opens
- [ ] Select large image (5MB+) → loader appears for 1-2 seconds
- [ ] Image loads → loader disappears, new image shows
- [ ] Cancel picker → no loader, no error
- [ ] Permission denied → error snackbar shows

#### Login Loading (Phase 2):
- [ ] Enter credentials → click Login → loader appears
- [ ] Successful login → loader stays until dashboard mounts
- [ ] Wrong password → loader disappears, error shows
- [ ] Network error → loader disappears, error shows
- [ ] No flash of login screen during navigation

#### Register Loading (Phase 3):
- [ ] Fill form + avatar → click Create Account → full-screen loader
- [ ] Loader stays visible during: avatar upload → account creation → navigation
- [ ] Email exists → loader disappears, inline error shows
- [ ] Network error → loader disappears, snackbar shows

#### Error Messages (Phase 4):
- [ ] Wrong password → "Pogrešna lozinka" (HR) / "Incorrect password" (EN)
- [ ] Email not found → "Nije pronađen račun" (HR) / "No account found" (EN)
- [ ] Invalid email → "Nevažeća email adresa" (HR) / "Invalid email" (EN)
- [ ] Too many attempts → "Previše pokušaja" (HR) / "Too many attempts" (EN)

#### Remember Me (Phase 5):
- [ ] Check "Remember Me" → login → close app → reopen → fields auto-filled
- [ ] Uncheck → login → close app → reopen → fields empty
- [ ] Logout → credentials cleared
- [ ] Change password while remembered → login fails with clear error

### Test Environments:
- **Primary**: Android Chrome (physical device)
- **Secondary**: iOS Simulator, Web Chrome
- **Edge Cases**: Slow network (throttle to 3G), airplane mode

---

## 8. Risk Assessment

### Technical Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Avatar upload timeout** | High | Add 10s timeout, show error if exceeded |
| **LoadingOverlay blocks UI during error** | Medium | Ensure _isLoading = false in ALL catch blocks |
| **Secure storage fails on some devices** | Low | Wrap in try-catch, graceful fallback to no persistence |
| **Navigation completes before loader appears** | Low | Test on slow devices, add small delay if needed |

### Time Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Underestimated freezed code generation** | Low | Run `dart run build_runner build` first |
| **Android testing takes longer** | Medium | Use `--release` mode, keep device connected |
| **Localization edge cases** | Low | Focus on EN/HR only, skip other languages |

### Data Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Stored credentials compromised** | Medium | Use encrypted storage, warn user in tooltip |
| **Migration from existing users** | None | New feature, no existing data to migrate |

---

## 9. Estimation

### Time Breakdown:
- **Phase 1**: Avatar Upload Loader → 2-3 hours
- **Phase 2**: Login Screen Fix → 2-3 hours
- **Phase 3**: Register Screen Fix → 2-3 hours
- **Phase 4**: Error Messages → 1-2 hours
- **Phase 5**: Remember Me → 2-3 hours

**Total**: 9-14 hours
**Realistic Estimate** (with testing): **12-16 hours** (2 work days)

---

## 10. Success Criteria

### Must Have (MVP):
- ✅ Avatar upload shows loader (no "frozen" state)
- ✅ Login shows loader from click to dashboard mount
- ✅ Register shows loader from click to dashboard mount
- ✅ Error messages are user-friendly (localized)
- ✅ No premature loader dismissal on success

### Should Have:
- ✅ Remember Me functionality works
- ✅ Auto-fill credentials on app restart
- ✅ Logout clears stored credentials

### Nice to Have (Future):
- ⏳ Biometric auth (fingerprint/face unlock)
- ⏳ Social login loading states (Google/Apple)
- ⏳ Forgot Password loader improvements

---

## 11. Rollout Plan

### Pre-Deployment:
1. Test on Android Chrome (primary use case)
2. Test on iOS Simulator (secondary)
3. Test on Web Chrome (tertiary)
4. Run `flutter analyze` → 0 issues
5. Review CLAUDE.md for conflicts

### Deployment:
```bash
# 1. Clean build
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 2. Test builds
flutter run -d chrome --release          # Web
flutter run -d <ANDROID_ID> --release    # Android
flutter run -d <iOS_ID> --release        # iOS

# 3. Deploy
firebase deploy --only hosting:owner
```

### Post-Deployment:
- Monitor Sentry for new auth-related errors
- Check Firebase Auth logs for unusual patterns
- Collect user feedback on loading experience

### Rollback Plan:
If critical bug discovered:
1. Git revert to previous commit
2. Redeploy previous version: `firebase deploy --only hosting:owner`
3. Fix issue in separate branch
4. Re-test before second attempt

---

## 12. Next Steps

1. **Review this plan** - Confirm approach with team/solo dev
2. **Set up environment** - Install `flutter_secure_storage`
3. **Start with Phase 1** - Avatar upload (quick win, visible improvement)
4. **Test incrementally** - Don't wait until all phases done
5. **Update CLAUDE.md** - Document any new patterns discovered

---

## Appendix A: Related Documentation

- **CLAUDE.md** - Main project documentation
- **Changelog 6.0-6.16** - Recent auth improvements
- **Android Chrome Keyboard Fix** - Existing mixin used in auth screens
- **Firebase Auth Errors** - Official Firebase error code reference

---

## Appendix B: Design Decisions

### Why NOT use a separate loading provider?
- Component-level state is simpler
- No risk of stale state across screens
- Easier to debug (state is local to widget)

### Why keep LoadingOverlay visible during navigation?
- Prevents "flash" of old screen before new screen mounts
- User perceives action as "in progress" until completion
- Android Chrome is slower than iOS - needs visual feedback

### Why secure storage instead of SharedPreferences?
- Passwords must be encrypted (security requirement)
- Android EncryptedSharedPreferences is platform standard
- iOS Keychain is Apple's recommended approach

---

**END OF PLAN**
