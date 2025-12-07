# BookBed Rebranding Plan
## Complete Project Rename from "rab-booking" to "BookBed"

**Version:** 1.0
**Created:** 2025-12-07
**Estimated Time:** 3-5 days (solo developer)
**Risk Level:** MEDIUM (requires careful testing)

---

## TABLE OF CONTENTS

1. [Executive Summary](#executive-summary)
2. [What CAN vs CANNOT Change](#what-can-vs-cannot-change)
3. [Pre-Work (CRITICAL)](#pre-work-critical)
4. [Implementation Phases](#implementation-phases)
5. [File-by-File Changes](#file-by-file-changes)
6. [Testing Checklist](#testing-checklist)
7. [Deployment Strategy](#deployment-strategy)
8. [Rollback Procedure](#rollback-procedure)
9. [Post-Rebrand Checklist](#post-rebrand-checklist)

---

## EXECUTIVE SUMMARY

This plan covers the complete rebranding of the application from "rab-booking" / "RabBooking" to "BookBed", including package names, display names, domains, and all code references.

**Key Changes:**
- Flutter package: `rab_booking` → `bookbed`
- Android package: `com.example.rab_booking` → `io.bookbed.app`
- iOS bundle ID: Update to match Android
- Domain: `rab-booking-widget.web.app` → `bookbed.io`
- All code imports and references
- Documentation and branding materials

**What Stays:**
- Firebase Project ID: `rab-booking-248fc` (PERMANENT)
- Cloud Functions URLs (tied to project ID)
- Existing Firestore data (no migration needed)

---

## WHAT CAN vs CANNOT CHANGE

### ❌ CANNOT CHANGE (Permanent/Risky)

| Item | Why | Workaround |
|------|-----|------------|
| **Firebase Project ID** | `rab-booking-248fc` is PERMANENT. Firebase doesn't allow renaming project IDs after creation. | Use Firebase Console to change the display name only. Keep project ID as-is. |
| **Cloud Functions URLs** | Functions are deployed to `https://us-central1-rab-booking-248fc.cloudfunctions.net/...`. Cannot change without new project. | Use custom domains or accept the URLs as-is. |
| **Firebase Hosting URLs** | Default URLs like `rab-booking-248fc.web.app` and `rab-booking-widget.web.app` are tied to project ID. | Connect custom domain `bookbed.io` via Firebase Console. |
| **Existing Firestore Data** | Data structures contain references to the old naming. | No migration needed - data agnostic to project name. |
| **Deep link references** | If users have bookmarked `rabbooking://` or `https://rabbooking.com` | Add new schemes while keeping old for backward compatibility. |

### ✅ CAN CHANGE

| Item | Scope | Files Affected |
|------|-------|----------------|
| **Flutter Package Name** | `rab_booking` → `bookbed` | `pubspec.yaml`, all Dart imports, folder structure |
| **Android Package** | `com.example.rab_booking` → `io.bookbed.app` | `android/app/build.gradle.kts`, `AndroidManifest.xml` |
| **iOS Bundle ID** | Update to `io.bookbed.app` | `ios/Runner.xcodeproj`, `Info.plist` |
| **App Display Names** | "Rab Booking" → "BookBed" | iOS `Info.plist`, Android `AndroidManifest.xml` |
| **Firebase Display Name** | Change in Firebase Console | Firebase Console only |
| **Custom Domains** | `rabbooking.com` → `bookbed.io` | Firebase Hosting, DNS settings |
| **Widget Base URL** | Update constants in code | Dart code constants |
| **Deep Link Schemes** | `rabbooking://` → `bookbed://` | Android `AndroidManifest.xml`, iOS `Info.plist` |
| **Email Templates** | Update branding | Cloud Functions email service |
| **Privacy Policy** | Update contact emails | Localization files |
| **Documentation** | All `.md` files | README, CLAUDE.md, etc. |

---

## PRE-WORK (CRITICAL)

### 1. Backups

```bash
# Full git backup
git branch rebrand-backup-$(date +%Y%m%d)
git push origin rebrand-backup-$(date +%Y%m%d)

# Tag current state
git tag -a v1.0.0-pre-rebrand -m "State before BookBed rebrand"
git push origin v1.0.0-pre-rebrand

# Backup Firebase data (optional but recommended)
# Via Firebase Console: Firestore → Import/Export
```

### 2. Create Rebrand Branch

```bash
git checkout -b feature/bookbed-rebrand
```

### 3. Environment Preparation

- [ ] Ensure all dependencies are installed (`flutter pub get`)
- [ ] Clean build folders: `flutter clean`
- [ ] Verify Firebase emulators work: `firebase emulators:start`
- [ ] Document current deep link testing URLs

### 4. Third-Party Services Audit

Check which services need updating:
- [ ] Stripe (webhook URLs if using old domain)
- [ ] Email service (SendGrid, Mailgun, etc.)
- [ ] Analytics services
- [ ] App Store listings (if published)
- [ ] Google Play listings (if published)

---

## IMPLEMENTATION PHASES

### PHASE 1: Configuration Files (Day 1 - Morning)

**Estimated Time:** 2-3 hours

#### 1.1 Flutter Package Name (`pubspec.yaml`)

**File:** `pubspec.yaml`

```yaml
# BEFORE
name: rab_booking
description: "Booking application for vacation rentals on island Rab, Croatia."

# AFTER
name: bookbed
description: "BookBed - Modern booking management platform for vacation rentals."
```

**Impact:** ALL Dart imports will break until we fix them in Phase 2.

#### 1.2 Android Configuration

**File:** `android/app/build.gradle.kts`

```kotlin
// BEFORE (lines 11, 26)
namespace = "com.example.rab_booking"
applicationId = "com.example.rab_booking"

// AFTER
namespace = "io.bookbed.app"
applicationId = "io.bookbed.app"
```

**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<!-- BEFORE (line 3) -->
android:label="rab_booking"

<!-- AFTER -->
android:label="BookBed"

<!-- BEFORE (line 33) - Deep link scheme -->
<data android:scheme="rabbooking" />

<!-- AFTER - Keep BOTH for backward compatibility -->
<data android:scheme="rabbooking" /> <!-- Legacy support -->
<data android:scheme="bookbed" /> <!-- New scheme -->

<!-- BEFORE (lines 42-46) - HTTPS hosts -->
<data android:scheme="https" android:host="rabbooking.com" />
<data android:scheme="https" android:host="www.rabbooking.com" />

<!-- AFTER - Keep BOTH for backward compatibility -->
<data android:scheme="https" android:host="rabbooking.com" /> <!-- Legacy -->
<data android:scheme="https" android:host="www.rabbooking.com" /> <!-- Legacy -->
<data android:scheme="https" android:host="bookbed.io" /> <!-- New domain -->
<data android:scheme="https" android:host="www.bookbed.io" /> <!-- New domain -->
```

**Rebuild Android folder:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### 1.3 iOS Configuration

**File:** `ios/Runner/Info.plist`

```xml
<!-- BEFORE (line 8) -->
<key>CFBundleDisplayName</key>
<string>Rab Booking</string>

<!-- AFTER -->
<key>CFBundleDisplayName</key>
<string>BookBed</string>

<!-- BEFORE (line 16) -->
<key>CFBundleName</key>
<string>rab_booking</string>

<!-- AFTER -->
<key>CFBundleName</key>
<string>bookbed</string>
```

**File:** `ios/Runner.xcodeproj/project.pbxproj`

Search for `PRODUCT_BUNDLE_IDENTIFIER` and update:
```
// BEFORE
PRODUCT_BUNDLE_IDENTIFIER = com.example.rabBooking;

// AFTER
PRODUCT_BUNDLE_IDENTIFIER = io.bookbed.app;
```

**OR** Use Xcode:
1. Open `ios/Runner.xcodeproj` in Xcode
2. Select Runner target
3. General tab → Bundle Identifier → Change to `io.bookbed.app`

#### 1.4 Web Manifest

**File:** `web/manifest.json`

```json
{
  "name": "BookBed - Vacation Rental Management",
  "short_name": "BookBed",
  "description": "Modern booking management platform for property owners and vacation rentals.",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#FF6B35",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

---

### PHASE 2: Code Refactoring (Day 1 - Afternoon & Day 2)

**Estimated Time:** 4-6 hours

#### 2.1 Automated Import Renaming

**WARNING:** This will modify hundreds of files. Ensure git branch and backup first.

```bash
# Find all Dart files with rab_booking imports
find lib test -name "*.dart" -type f -exec grep -l "package:rab_booking" {} \;

# Automated replacement (DRY RUN first)
find lib test -name "*.dart" -type f -print0 | \
  xargs -0 sed -i '' 's/package:rab_booking/package:bookbed/g'

# Verify changes
git diff --stat
git diff lib/main.dart # Spot check
```

#### 2.2 Update Constants in Dart Code

**Files to modify:**

1. **`lib/features/owner_dashboard/presentation/widgets/embed_code_generator_dialog.dart`**

```dart
// BEFORE (line 40)
static const String _defaultWidgetBaseUrl = 'https://rab-booking-widget.web.app';
static const String _subdomainBaseDomain = 'bookbed.io';

// AFTER
static const String _defaultWidgetBaseUrl = 'https://bookbed.io';
static const String _subdomainBaseDomain = 'bookbed.io';
```

2. **`lib/features/owner_dashboard/presentation/screens/guides/embed_widget_guide_screen.dart`**

```dart
// BEFORE
static const String _defaultWidgetBaseUrl = 'https://rab-booking-widget.web.app';

// AFTER
static const String _defaultWidgetBaseUrl = 'https://bookbed.io';
```

3. **`lib/firebase_options.dart`** (READ-ONLY - DO NOT MODIFY)

```dart
// KEEP AS-IS (Firebase Project ID is permanent)
authDomain: 'rab-booking-248fc.firebaseapp.com',
```

**Note:** You CANNOT change `authDomain` without breaking Firebase Auth. This is tied to the Firebase Project ID.

#### 2.3 Update Subdomain Service (If Needed)

**File:** `lib/features/widget/domain/services/subdomain_service.dart`

Check if there are any hardcoded references to old domain. Based on previous read, it uses constants correctly. No changes needed unless testing with specific domains.

---

### PHASE 3: Cloud Functions (Day 2 - Afternoon)

**Estimated Time:** 2-3 hours

#### 3.1 Update Environment Variables

**File:** `functions/.env.example` and `functions/.env`

```bash
# BEFORE
WIDGET_URL=https://rab-booking-widget.web.app

# AFTER
WIDGET_URL=https://bookbed.io
```

#### 3.2 Update TypeScript Source Files

**File:** `functions/src/emailService.ts` (line 12)

```typescript
// BEFORE
const WIDGET_URL = process.env.WIDGET_URL || "https://rab-booking-widget.web.app";

// AFTER
const WIDGET_URL = process.env.WIDGET_URL || "https://bookbed.io";
```

**File:** `functions/src/stripePayment.ts`

```typescript
// BEFORE (lines 13-15)
const ALLOWED_ORIGINS = [
  "https://rab-booking-248fc.web.app",
  "https://rab-booking-owner.web.app",
  "https://rab-booking-widget.web.app",
  // ... other origins
];

// AFTER (add new domains, KEEP old for backward compatibility)
const ALLOWED_ORIGINS = [
  // Old domains (backward compatibility)
  "https://rab-booking-248fc.web.app",
  "https://rab-booking-owner.web.app",
  "https://rab-booking-widget.web.app",

  // New domains
  "https://bookbed.io",
  "https://www.bookbed.io",
  "https://owner.bookbed.io", // If using subdomains for owner dashboard

  // ... other origins
];

// BEFORE (lines in createStripeCheckoutSession for success/cancel URLs)
successUrl = "https://rab-booking-248fc.web.app/booking-success?session_id={CHECKOUT_SESSION_ID}";
cancelUrl = "https://rab-booking-248fc.web.app/booking-cancelled";

// AFTER
successUrl = "https://bookbed.io/booking-success?session_id={CHECKOUT_SESSION_ID}";
cancelUrl = "https://bookbed.io/booking-cancelled";
```

**File:** `functions/src/icalExport.ts` (line ~50)

```typescript
// BEFORE
lines.push(`UID:booking-${booking.id}@rab-booking.com`);

// AFTER
lines.push(`UID:booking-${booking.id}@bookbed.io`);
```

**File:** `functions/src/stripeConnect.ts`

```typescript
// BEFORE
platform: "rab-booking",

// AFTER
platform: "bookbed",
```

#### 3.3 Rebuild Cloud Functions

```bash
cd functions
npm run build
npm run lint
cd ..
```

#### 3.4 Update JavaScript Output (If Needed)

If you deploy from `functions/lib/*.js` instead of TypeScript source:

```bash
# Rebuild automatically updates lib/ folder
cd functions
npm run build
```

**File:** `functions/add_test_prices.js` (line 3)

```javascript
// BEFORE
projectId: 'rab-booking-248fc'

// AFTER
// KEEP AS-IS - This is the Firebase Project ID, cannot change
projectId: 'rab-booking-248fc'
```

---

### PHASE 4: Localization & Branding (Day 3 - Morning)

**Estimated Time:** 2-3 hours

#### 4.1 Update Privacy Policy Email References

**Files:**
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_hr.dart`
- Generated file: `lib/l10n/app_localizations.dart` (auto-generated, update source ARB files)

**Source ARB files to modify:**
```bash
# Find ARB source files
find lib/l10n assets/translations -name "*.arb" -o -name "*.json"
```

**Typical location:** `lib/l10n/app_en.arb`, `lib/l10n/app_hr.arb`

**Changes:**

```json
// BEFORE
"privacy@rabbooking.com"
"[subdomain].rabbooking.com"

// AFTER
"privacy@bookbed.io"
"[subdomain].bookbed.io"
```

After modifying ARB files:
```bash
flutter pub get
flutter gen-l10n # Regenerate localizations
```

#### 4.2 Update Documentation

**Files to modify:**

1. **README.md**

```markdown
# BEFORE
# RabBooking

RabBooking omogućava vlasnićima smještaja...

# AFTER
# BookBed

BookBed is a modern booking management platform...
```

2. **CLAUDE.md**

Update project name references:
```markdown
# BEFORE
**RabBooking** - Booking management platforma za property owner-e na otoku Rabu.

# AFTER
**BookBed** - Modern booking management platform for property owners.
```

3. **CLAUDE_WIDGET_SYSTEM.md**

Search and replace project name references.

4. **CLAUDE_MCP_TOOLS.md**

Update any project-specific references.

5. **.claude/plans/RabBooking-Architecture-Plan-v2.md**

```markdown
# BEFORE
# RabBooking - Arhitekturni Plan

# AFTER
# BookBed - Architecture Plan
```

---

### PHASE 5: Firebase Console Changes (Day 3 - Afternoon)

**Estimated Time:** 1-2 hours

#### 5.1 Update Firebase Project Display Name

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project `rab-booking-248fc`
3. Click gear icon → Project Settings
4. Update "Public-facing name" to: **BookBed**
5. Click "Save"

**Note:** Project ID `rab-booking-248fc` CANNOT be changed.

#### 5.2 Update Firebase Hosting Sites

**Option A: Rename existing sites (if Firebase allows)**

1. Firebase Console → Hosting
2. For `rab-booking-widget` site:
   - Click settings
   - Try to rename to `bookbed-widget` (may not be possible)
   - If rename not allowed, add custom domain instead

**Option B: Add custom domains (RECOMMENDED)**

1. Firebase Console → Hosting → `rab-booking-widget` site
2. Click "Add custom domain"
3. Enter: `bookbed.io`
4. Follow DNS verification steps (see Phase 6)

#### 5.3 Update `.firebaserc`

**File:** `.firebaserc`

```json
{
  "projects": {
    "default": "rab-booking-248fc"
  },
  "targets": {
    "rab-booking-248fc": {
      "hosting": {
        "widget": [
          "rab-booking-widget"
        ],
        "owner": [
          "rab-booking-248fc"
        ]
      }
    }
  },
  "etags": {}
}
```

**NO CHANGES NEEDED** - Firebase project ID stays the same. Hosting site names may stay the same (hidden by custom domain).

---

### PHASE 6: Domain & Hosting Setup (Day 4)

**Estimated Time:** 2-4 hours (includes DNS propagation wait)

#### 6.1 Purchase Domain

1. Purchase `bookbed.io` from domain registrar (Namecheap, Google Domains, etc.)
2. Access domain DNS settings

#### 6.2 Connect Custom Domain to Firebase Hosting

**For Widget (Main Site):**

1. Firebase Console → Hosting → Select `rab-booking-widget` site
2. Click "Add custom domain"
3. Enter: `bookbed.io`
4. Firebase provides TXT record for verification:
   ```
   Type: TXT
   Name: @
   Value: [Firebase verification string]
   ```
5. Add TXT record to DNS
6. After verification, Firebase provides A records:
   ```
   Type: A
   Name: @
   Value: 151.101.1.195  # Example IP

   Type: A
   Name: @
   Value: 151.101.65.195 # Example IP
   ```
7. Add A records to DNS
8. Wait for DNS propagation (15 mins - 24 hours)
9. Firebase automatically provisions SSL certificate

**For Owner Dashboard (Optional Subdomain):**

1. Repeat process for `owner.bookbed.io`
2. Point to `rab-booking-248fc` hosting site

#### 6.3 Update Code Constants (After Domain Active)

Once `bookbed.io` is live, update Dart constants:

**File:** `lib/features/owner_dashboard/presentation/widgets/embed_code_generator_dialog.dart`

```dart
// Update from Firebase default to custom domain
static const String _defaultWidgetBaseUrl = 'https://bookbed.io';
```

---

### PHASE 7: Folder Structure Rename (Day 4 - Afternoon)

**Estimated Time:** 1-2 hours

**WARNING:** This is OPTIONAL and HIGH-RISK. Only do this if you want the folder name to match the new branding.

#### 7.1 Rename Project Folder

```bash
# From outside the project directory
cd /Users/duskolicanin/git/
mv rab_booking bookbed

# Update git remote if needed
cd bookbed
git remote -v # Verify remote URL still works
```

#### 7.2 Update IDE Project References

- **VS Code:** Reopen folder (`File > Open Folder > bookbed`)
- **Xcode:** Close and reopen project
- **Android Studio:** Close and reopen project

---

## FILE-BY-FILE CHANGES

### Complete Change List

| File | Line(s) | Before | After |
|------|---------|--------|-------|
| `pubspec.yaml` | 1 | `name: rab_booking` | `name: bookbed` |
| `pubspec.yaml` | 2 | "...island Rab, Croatia" | "BookBed - Modern booking management..." |
| `android/app/build.gradle.kts` | 11 | `namespace = "com.example.rab_booking"` | `namespace = "io.bookbed.app"` |
| `android/app/build.gradle.kts` | 26 | `applicationId = "com.example.rab_booking"` | `applicationId = "io.bookbed.app"` |
| `android/app/src/main/AndroidManifest.xml` | 3 | `android:label="rab_booking"` | `android:label="BookBed"` |
| `android/app/src/main/AndroidManifest.xml` | 33 | `android:scheme="rabbooking"` | Add: `android:scheme="bookbed"` (keep old too) |
| `android/app/src/main/AndroidManifest.xml` | 42-46 | `android:host="rabbooking.com"` | Add: `android:host="bookbed.io"` (keep old too) |
| `ios/Runner/Info.plist` | 8 | `<string>Rab Booking</string>` | `<string>BookBed</string>` |
| `ios/Runner/Info.plist` | 16 | `<string>rab_booking</string>` | `<string>bookbed</string>` |
| `ios/Runner.xcodeproj/project.pbxproj` | Multiple | `PRODUCT_BUNDLE_IDENTIFIER = com.example.rabBooking` | `io.bookbed.app` |
| `web/manifest.json` | 2-3 | "RAB Booking - Luxury..." | "BookBed - Vacation Rental..." |
| All `*.dart` files | Imports | `package:rab_booking/...` | `package:bookbed/...` |
| `lib/features/owner_dashboard/presentation/widgets/embed_code_generator_dialog.dart` | 40 | `https://rab-booking-widget.web.app` | `https://bookbed.io` |
| `lib/features/owner_dashboard/presentation/screens/guides/embed_widget_guide_screen.dart` | Similar | `https://rab-booking-widget.web.app` | `https://bookbed.io` |
| `functions/src/emailService.ts` | 12 | `https://rab-booking-widget.web.app` | `https://bookbed.io` |
| `functions/src/stripePayment.ts` | 13-15 | Old Firebase URLs | Add `https://bookbed.io` to ALLOWED_ORIGINS |
| `functions/src/stripePayment.ts` | Success/cancel URLs | `rab-booking-248fc.web.app` | `bookbed.io` |
| `functions/src/icalExport.ts` | ~50 | `@rab-booking.com` | `@bookbed.io` |
| `functions/src/stripeConnect.ts` | Platform field | `"rab-booking"` | `"bookbed"` |
| `lib/l10n/*.arb` (source) | Multiple | `privacy@rabbooking.com` | `privacy@bookbed.io` |
| `lib/l10n/*.arb` (source) | Multiple | `[subdomain].rabbooking.com` | `[subdomain].bookbed.io` |
| `README.md` | 1 | `# RabBooking` | `# BookBed` |
| `CLAUDE.md` | Multiple | "RabBooking" | "BookBed" |
| Other `.md` files | Multiple | Project name references | "BookBed" |

### Files That Should NOT Change

| File | Reason |
|------|--------|
| `lib/firebase_options.dart` | Contains Firebase Project ID - CANNOT change |
| `.firebaserc` | Firebase Project ID is permanent |
| `functions/add_test_prices.js` | Project ID reference - keep as-is |
| Any Firebase config JSONs | Generated by Firebase CLI, tied to project ID |

---

## TESTING CHECKLIST

### Pre-Deployment Testing (Local & Emulators)

#### 1. Flutter Build Tests

```bash
# Clean everything
flutter clean
rm -rf ios/Pods ios/Podfile.lock
cd android && ./gradlew clean && cd ..

# Get dependencies
flutter pub get
cd ios && pod install && cd ..

# Test builds
flutter build apk --debug # Android
flutter build ios --debug --no-codesign # iOS
flutter build web # Web
```

**Expected:** All builds succeed without errors.

#### 2. Import Resolution Test

```bash
# Check for any remaining old imports
grep -r "package:rab_booking" lib test
```

**Expected:** No results (all imports updated).

#### 3. Constant References Test

```bash
# Check for hardcoded URLs
grep -r "rab-booking-widget.web.app" lib functions
grep -r "rabbooking.com" lib functions --exclude-dir=l10n
```

**Expected:** Only in backward-compatibility contexts (e.g., ALLOWED_ORIGINS).

#### 4. Firebase Emulators Test

```bash
firebase emulators:start
```

**Test cases:**
- [ ] Owner dashboard loads
- [ ] Widget loads
- [ ] Booking creation works
- [ ] Email sending works (check emulator logs)
- [ ] Stripe webhook simulation (if applicable)

#### 5. Deep Link Testing

**Android:**
```bash
# Test old scheme (should still work)
adb shell am start -W -a android.intent.action.VIEW \
  -d "rabbooking://booking/12345" \
  com.example.rab_booking

# Test new scheme
adb shell am start -W -a android.intent.action.VIEW \
  -d "bookbed://booking/12345" \
  io.bookbed.app
```

**iOS:** Use Xcode Simulator or physical device with deep link test app.

---

### Post-Deployment Testing (Production)

#### 1. Domain Resolution

```bash
# Check DNS propagation
dig bookbed.io +short
dig www.bookbed.io +short

# Check SSL certificate
curl -I https://bookbed.io
```

**Expected:** Shows Firebase hosting IPs, SSL valid.

#### 2. Widget Embed Test

Create test HTML page:
```html
<!DOCTYPE html>
<html>
<head>
  <title>BookBed Widget Test</title>
</head>
<body>
  <h1>Embed Test</h1>
  <iframe
    src="https://bookbed.io/?property=TEST_PROPERTY_ID&unit=TEST_UNIT_ID&language=en"
    width="100%"
    height="900px"
    frameborder="0"
  ></iframe>
</body>
</html>
```

**Test:**
- [ ] Widget loads in iframe
- [ ] No CORS errors in console
- [ ] Booking flow completes

#### 3. Email Links Test

Trigger booking confirmation email:
- [ ] Email received
- [ ] Links point to `bookbed.io` (not old domain)
- [ ] Links work and load booking details

#### 4. Stripe Integration Test

- [ ] Create test booking with Stripe
- [ ] Webhook fires (check Firebase Functions logs)
- [ ] Booking status updated to confirmed
- [ ] Confirmation email sent

#### 5. Subdomain Test

If using property subdomains:
- [ ] `test-property.bookbed.io` loads widget
- [ ] Branding applies correctly
- [ ] Booking flow works

---

## DEPLOYMENT STRATEGY

### Deployment Order (CRITICAL)

**DO NOT deploy all at once.** Use phased rollout:

### Step 1: Deploy Code (No Traffic Yet)

```bash
# Commit all changes
git add .
git commit -m "feat: Rebrand to BookBed - all code changes"

# Deploy Cloud Functions (with new constants)
firebase deploy --only functions

# Build Flutter apps with new package name
flutter build web --web-renderer canvaskit --dart-define=FLUTTER_WEB_USE_SKIA=true

# Deploy to Firebase Hosting (still on old URLs)
firebase deploy --only hosting:widget
firebase deploy --only hosting:owner
```

**Verify:**
- Old URLs still work: `https://rab-booking-widget.web.app`
- Functions updated (check logs)

### Step 2: Connect Custom Domain

1. Firebase Console → Hosting → Add custom domain: `bookbed.io`
2. Add DNS records (A and TXT)
3. Wait for SSL provisioning (30 mins - 2 hours)

**Verify:**
- `https://bookbed.io` loads and shows widget
- SSL certificate valid
- Old URL still works (parallel operation)

### Step 3: Update External Services

- [ ] Update Stripe webhook URLs (if needed)
- [ ] Update any external API callbacks
- [ ] Update email service sender domain (if applicable)
- [ ] Update analytics tracking (GA, Mixpanel, etc.)

### Step 4: Monitor & Validate

**Monitor for 24-48 hours:**
- Firebase Functions logs (errors?)
- Firebase Analytics (traffic on new domain?)
- Error tracking (Crashlytics, Sentry, etc.)
- User reports

### Step 5: Publish New App Versions

**Once stable:**

```bash
# Tag release
git tag -a v2.0.0-bookbed -m "BookBed rebrand release"
git push origin v2.0.0-bookbed

# Build release apps
flutter build apk --release
flutter build ios --release
flutter build web --release

# Submit to stores
# - Google Play: New package name = new app listing (or update existing)
# - App Store: New bundle ID = new app listing (or update existing)
```

**Decision:**
- **New listing:** Cleaner, but loses existing users/reviews
- **Update existing:** Keep users, but package name change may require uninstall/reinstall

---

## ROLLBACK PROCEDURE

### If Things Go Wrong

#### Scenario 1: Build Failures After Package Rename

**Symptoms:** Flutter builds fail, import errors everywhere

**Rollback:**
```bash
# Restore from backup branch
git checkout rebrand-backup-$(date +%Y%m%d)

# Or revert specific commits
git log --oneline # Find commit hash
git revert <commit-hash>

# Clean and rebuild
flutter clean
flutter pub get
flutter build web
```

#### Scenario 2: Firebase Functions Errors

**Symptoms:** Webhooks failing, email not sending, Stripe errors

**Rollback:**
```bash
# Redeploy previous functions version
firebase deploy --only functions --version <previous-version>

# Or from git
git checkout HEAD~1 functions/
cd functions && npm run build && cd ..
firebase deploy --only functions
```

#### Scenario 3: Domain Issues

**Symptoms:** New domain not loading, SSL errors, DNS problems

**Rollback:**
Not needed - old URLs still work in parallel. Just:
1. Remove custom domain from Firebase Console
2. Update code constants back to `rab-booking-widget.web.app`
3. Redeploy hosting

#### Scenario 4: Complete Rollback

**Nuclear option - restore everything:**

```bash
# Restore from backup tag
git reset --hard v1.0.0-pre-rebrand
git push origin feature/bookbed-rebrand --force

# Redeploy old version
flutter clean && flutter pub get
flutter build web
firebase deploy

# Update DNS back to old domain (if changed)
```

---

## POST-REBRAND CHECKLIST

### Week 1

- [ ] Monitor Firebase Functions logs daily
- [ ] Check error tracking dashboards
- [ ] Verify booking flows working
- [ ] Test email delivery
- [ ] Monitor user feedback channels
- [ ] Check analytics for traffic patterns

### Week 2-4

- [ ] Update marketing materials (if any)
- [ ] Update social media profiles
- [ ] Update business cards / printed materials
- [ ] Notify existing property owners of rebrand
- [ ] Update any partner integrations
- [ ] Archive old documentation

### Long-term

- [ ] Keep old domain redirects for 1-2 years (SEO)
- [ ] Monitor for old deep links in the wild
- [ ] Plan deprecation timeline for old URLs
- [ ] Eventually remove backward-compatibility code

---

## ADDITIONAL CONSIDERATIONS

### 1. SEO Impact

If old domain had SEO value:
- Set up 301 redirects from `rabbooking.com` → `bookbed.io`
- Submit new sitemap to Google Search Console
- Update Google My Business (if applicable)

### 2. App Store Considerations

**Google Play:**
- New package name = new app listing (recommended for clean break)
- OR update existing app (users must uninstall/reinstall)

**Apple App Store:**
- New bundle ID = new app listing
- Easier to create new listing than update existing

**Recommendation:** Create new listings, cross-promote from old apps with sunset notice.

### 3. User Communication

**Email template for existing users:**

```
Subject: Exciting News: We're Now BookBed!

Hi [Property Owner],

We're thrilled to announce that RabBooking is now BookBed!

What's changing:
✅ New domain: bookbed.io
✅ Modern branding
✅ Same great features you love

What's NOT changing:
✅ Your data (all bookings, settings safe)
✅ Your subdomain (property.bookbed.io)
✅ Your Stripe integration

Action needed:
1. Update any bookmarks to bookbed.io
2. Download new mobile app from [store link] (if applicable)

Your old links will continue working, but we recommend updating.

Questions? Reply to this email or contact support@bookbed.io

Best regards,
The BookBed Team
```

### 4. Legal Considerations

- [ ] Update Terms of Service with new company name
- [ ] Update Privacy Policy contact info
- [ ] Update GDPR data controller info
- [ ] Register "BookBed" trademark (if planning commercial use)
- [ ] Update business registration (if applicable)

---

## TIMELINE SUMMARY

| Day | Phase | Tasks | Hours |
|-----|-------|-------|-------|
| **Day 1 AM** | Pre-work + Config | Backups, branch, pubspec, Android, iOS, web manifest | 3h |
| **Day 1 PM** | Code refactor | Automated import renaming, constant updates | 3h |
| **Day 2 AM** | Code refactor cont. | Verify all imports, test builds | 2h |
| **Day 2 PM** | Cloud Functions | Update .env, TypeScript, rebuild | 3h |
| **Day 3 AM** | Localization | ARB files, regenerate l10n | 2h |
| **Day 3 PM** | Documentation + Firebase Console | Update MD files, Firebase display name | 2h |
| **Day 4 AM** | Domain setup | Purchase domain, DNS config, wait | 2h |
| **Day 4 PM** | Testing | Local tests, emulators, builds | 3h |
| **Day 5** | Deployment | Phased rollout, monitoring | 4h |

**Total:** ~24 hours (3-5 days for solo developer with breaks)

---

## RISK ASSESSMENT

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Build failures | **Medium** | High | Backups, git branch, test locally first |
| Deep link breakage | **Low** | Medium | Keep old schemes for backward compatibility |
| DNS propagation delays | **High** | Low | Deploy in phases, old URL works in parallel |
| Email delivery issues | **Low** | High | Test email functions in emulators first |
| Stripe webhook failures | **Medium** | High | Update webhook URLs, test thoroughly |
| SEO loss | **Low** | Medium | Set up 301 redirects, submit new sitemap |
| User confusion | **High** | Low | Communication plan, keep old URLs active |
| Data loss | **Very Low** | Critical | Firestore data unaffected by rename |

---

## SUPPORT & TROUBLESHOOTING

### Common Issues

**Issue:** "Package 'rab_booking' not found"
**Solution:** Run `flutter clean && flutter pub get`

**Issue:** Android build fails with namespace error
**Solution:** Ensure `android/app/build.gradle.kts` has correct namespace

**Issue:** iOS build fails with bundle ID error
**Solution:** Update Xcode project settings or `ios/Runner.xcodeproj/project.pbxproj`

**Issue:** Firebase Functions return 404 after deploy
**Solution:** Functions URL didn't change (still uses project ID). Check CORS settings.

**Issue:** Emails still reference old domain
**Solution:** Rebuild and redeploy Cloud Functions: `cd functions && npm run build && cd .. && firebase deploy --only functions`

**Issue:** Widget won't load in iframe
**Solution:** Check `firebase.json` hosting headers allow frame-ancestors

---

## CONCLUSION

This rebrand from "rab-booking" to "BookBed" is comprehensive but manageable with careful planning. The key is:

1. **Backup everything** before starting
2. **Work in a branch** for easy rollback
3. **Deploy in phases** (code → domain → monitoring)
4. **Keep old URLs working** during transition
5. **Test thoroughly** before production deploy

The Firebase Project ID (`rab-booking-248fc`) will remain unchanged, but this is hidden from end users by the custom domain `bookbed.io`. All user-facing branding will reflect "BookBed".

**Estimated total time:** 24-30 hours of focused work over 3-5 days.

**Risk level:** MEDIUM (mitigated by backups and phased rollout)

**Recommendation:** Proceed with rebrand. The effort is justified for a clean, professional brand identity.

---

**Document Version:** 1.0
**Last Updated:** 2025-12-07
**Next Review:** After Phase 5 completion
