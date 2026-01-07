# BookBed Pre-Production Testing Plan (v1.0)

**Last Updated**: 2025-12-18

> **Note**: This document covers the plan for **manual, end-to-end testing**. For instructions on running unit, widget, and integration tests, please refer to the [Automated Testing Guide](./AUTOMATED_TESTING.md).
**Target Platforms**: iOS Simulator, Android Samsung Device, Web (Chrome, Safari Desktop, Safari iOS, Chrome Mobile)
**Testing Scope**: Owner Dashboard + Booking Widget
**Bug Tracking**: Sentry (automated) + Manual UI Issue Log

---

## 📋 Table of Contents

1. [Pre-Testing Setup](#1-pre-testing-setup)
2. [Test Data Preparation](#2-test-data-preparation)
3. [Platform-Specific Setup](#3-platform-specific-setup)
4. [Testing Strategy](#4-testing-strategy)
5. [Owner Dashboard Test Cases](#5-owner-dashboard-test-cases)
6. [Booking Widget Test Cases](#6-booking-widget-test-cases)
7. [Cloud Functions Test Cases](#7-cloud-functions-test-cases)
8. [Cross-Platform Validation](#8-cross-platform-validation)
9. [Bug Tracking & Reporting](#9-bug-tracking--reporting)
10. [Production Readiness Checklist](#10-production-readiness-checklist)

---

## 1. Pre-Testing Setup

### 1.1 Environment Configuration

**Current Setup** (based on user answers):
- **Firebase Environment**: Development project (same as current)
- **Stripe Mode**: Test mode only (no real payments)
- **Test Accounts**: Single owner account - needs expansion
- **Web Browsers**: Chrome/Edge, Safari (macOS + iOS), Mobile browsers

### 1.2 Required Tools

```bash
# Ensure Flutter is up-to-date
flutter doctor -v

# Ensure all dependencies are installed
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Verify Firebase CLI
firebase --version  # Should be 13.x+

# Verify connected devices
flutter devices
```

### 1.3 Sentry Configuration Verification

**Check Sentry DSN is configured**:
```dart
// lib/main.dart & lib/widget_main.dart
// Verify SentryFlutter.init() is present
```

**Verify Cloud Functions Sentry**:
```typescript
// functions/src/sentry.ts
// Ensure Sentry.init() is called in index.ts
```

**Sentry Dashboard Access**:
- URL: https://sentry.io/organizations/bookbed/projects/
- Create test issue to verify connection: `Sentry.captureMessage("Pre-production test start")`

---

## 2. Test Data Preparation

### 2.1 Owner Account Setup

**Expand from single account to comprehensive test scenarios**:

| Account Type | Email | Purpose | Data State |
|--------------|-------|---------|------------|
| **Primary Test Owner** | `test-owner@bookbed.io` | Full feature testing | Multiple properties, units, bookings |
| **Empty Owner** | `empty-owner@bookbed.io` | Onboarding flow | No properties |
| **Single Property Owner** | `single-property@bookbed.io` | Basic functionality | 1 property, 2 units |
| **Stripe Connected** | `stripe-owner@bookbed.io` | Payment testing | Stripe Connect setup complete |
| **Bank Transfer Only** | `bank-only@bookbed.io` | Bank transfer flow | No Stripe, bank details configured |

### 2.2 Property & Unit Test Data

**For Primary Test Owner Account**:

```yaml
Properties:
  - Property 1: "Villa Marija" (subdomain: villa-marija)
    Units:
      - Apartman 1 (slug: apartman-1)
        - Calendar: Mix of confirmed, pending, cancelled bookings
        - Price rules: Base price + seasonal pricing
        - Availability: Some blocked dates
      - Apartman 2 (slug: apartman-2)
        - Calendar: Turnover days (partialBoth status)
        - Custom pricing: Different weekend/weekday rates

  - Property 2: "Kuća Rab" (subdomain: kuca-rab)
    Units:
      - Studio (slug: studio-apartman)
        - External bookings: iCal sync (Booking.com, Airbnb)
        - Platform icons visible
      - Deluxe Room (slug: deluxe-room)
        - Direct bookings only
        - Widget settings: Calendar-only mode

  - Property 3: "Test Property" (subdomain: test-bookbed)
    Units:
      - Unit Alpha (slug: unit-alpha)
        - Empty calendar (for new booking tests)
      - Unit Beta (slug: unit-beta)
        - Fully booked for next month
```

### 2.3 Booking Test Scenarios

**Create bookings covering all states**:

| Booking Type | Status | Payment Method | Check-in Date | Purpose |
|--------------|--------|----------------|---------------|---------|
| Future Confirmed | `confirmed` | Stripe (test card) | +14 days | Email reminders test |
| Pending Payment | `pending` | Bank Transfer | +21 days | Payment deadline tracking |
| Cancelled by Guest | `cancelled` | N/A | +30 days | Cancellation flow |
| Past Booking | `confirmed` | Stripe | -7 days (past) | Analytics data |
| Today Check-in | `confirmed` | Bank Transfer | Today | Check-in notification |
| Turnover Day | Two bookings same day | Mixed | +5 days | Timeline calendar conflict |
| External (Airbnb) | `confirmed` | N/A | +10 days | Platform icon display |
| External (Booking.com) | `confirmed` | N/A | +12 days | iCal sync validation |

### 2.4 Stripe Test Cards

**Use Stripe test mode cards**:
```
Success: 4242 4242 4242 4242
Decline: 4000 0000 0000 0002
3D Secure: 4000 0025 0000 3155
Insufficient Funds: 4000 0000 0000 9995

Expiry: Any future date
CVC: Any 3 digits
ZIP: Any 5 digits
```

### 2.5 Firebase Data Seeding Script

**Create a script to populate test data** (optional but recommended):

```bash
# Script location: scripts/seed_test_data.sh
# TODO: Create this script to automate test data creation
```

---

## 3. Platform-Specific Setup

### 3.1 iOS Simulator

```bash
# List available simulators
xcrun simctl list devices available

# Boot specific simulator (iPhone 15 Pro recommended)
open -a Simulator --args -CurrentDeviceUDID <DEVICE_UDID>

# Run Owner Dashboard
flutter run -d <iOS_DEVICE_ID> --target lib/main.dart

# Run Widget (separate terminal)
flutter run -d <iOS_DEVICE_ID> --target lib/widget_main.dart
```

**Testing Focus**:
- Safari WebView behavior (for embedded widget iframe)
- iOS keyboard dismissal (landscape mode)
- Touch gestures (swipe, pinch-to-zoom on calendar)
- PWA installation prompt (Safari only)

### 3.2 Android Samsung Device

```bash
# Enable USB debugging on device:
# Settings → About Phone → tap Build Number 7 times
# Settings → Developer Options → USB Debugging

# Verify device connected
adb devices

# Run in RELEASE mode (debug mode has firebase_storage bug)
flutter run -d <ANDROID_DEVICE_ID> --release --target lib/main.dart

# Run Widget
flutter run -d <ANDROID_DEVICE_ID> --release --target lib/widget_main.dart
```

**Testing Focus**:
- Android Chrome keyboard dismiss bug (BACK button)
- Samsung-specific UI quirks
- Physical keyboard behavior
- Chrome Custom Tabs for Stripe redirect
- PWA installation (Chrome prompt)

### 3.3 Web - Desktop (Chrome/Edge)

```bash
# Run Owner Dashboard
flutter run -d chrome --web-port 8080 --target lib/main.dart

# Run Widget (separate terminal)
flutter run -d chrome --web-port 8081 --target lib/widget_main.dart
```

**Test URLs**:
```
Owner Dashboard: http://localhost:8080
Widget (subdomain simulation):
  - http://localhost:8081/?property=xxx&unit=yyy
  - http://localhost:8081/apartman-1 (slug routing)
```

**Testing Focus**:
- Responsive breakpoints (resize browser window)
- Desktop-specific layouts (EndDrawer on desktop)
- Clipboard API (copy booking reference)
- Browser back/forward navigation
- Multi-tab behavior (cross-tab messaging for Stripe)

### 3.4 Web - Desktop (Safari)

**Same setup as Chrome, but open in Safari**:
```bash
# Build web first
flutter build web --release --target lib/main.dart -o build/web_owner
flutter build web --release --target lib/widget_main.dart -o build/web_widget

# Serve locally
cd build/web_owner && python3 -m http.server 8080
cd build/web_widget && python3 -m http.server 8081
```

**Safari-Specific Testing**:
- Iframe clipboard restrictions
- Date picker rendering
- PWA behavior (limited on macOS Safari)
- WebKit rendering differences

### 3.5 Web - Mobile (Safari iOS)

**Deploy to Firebase Hosting for real mobile testing**:
```bash
# Build production builds
flutter build web --release --target lib/main.dart -o build/web_owner
flutter build web --release --target lib/widget_main.dart -o build/web_widget

# Deploy to Firebase
firebase deploy --only hosting

# Test on iPhone Safari
# Owner: https://app.bookbed.io
# Widget: https://villa-marija.view.bookbed.io
```

**Mobile Safari Testing Focus**:
- Touch interactions (tap, swipe)
- Viewport meta tag behavior
- Keyboard covering input fields
- iOS-specific date picker
- PWA installation (iOS 16.4+)

### 3.6 Web - Mobile (Chrome Mobile Android)

**Use same Firebase deployment URLs on Android Chrome**:
- Owner: https://app.bookbed.io
- Widget: https://villa-marija.view.bookbed.io

**Chrome Mobile Testing Focus**:
- Android keyboard behavior
- Chrome Custom Tabs for Stripe
- PWA installation (more robust than iOS)
- Touch gesture responsiveness

---

## 4. Testing Strategy

### 4.1 Testing Approach

**Execution Order**:
1. **Owner Dashboard** (Day 1-2): Complete all Owner features first
2. **Booking Widget** (Day 3-4): Test widget with Owner data already configured
3. **Integration Tests** (Day 5): Cross-app flows (booking → owner notification)
4. **Regression Tests** (Day 6): Re-test critical paths after fixes

**Testing Methodology**:
- **Exploratory Testing**: Manual exploration of each feature
- **Scenario-Based Testing**: Follow user journeys (e.g., "New owner onboarding")
- **Edge Case Testing**: Invalid inputs, network failures, concurrent users
- **Cross-Platform Validation**: Same test on all platforms

### 4.2 Test Execution Tracking

**Use a Google Sheet for tracking** (or similar):

| Test ID | Feature | Test Case | Platform | Status | Bug ID | Notes |
|---------|---------|-----------|----------|--------|--------|-------|
| OD-001 | Login | Valid credentials | iOS | ✅ Pass | - | - |
| OD-001 | Login | Valid credentials | Android | ❌ Fail | BUG-001 | Keyboard doesn't dismiss |
| OD-001 | Login | Valid credentials | Web Chrome | ✅ Pass | - | - |

**Status Legend**:
- ✅ **Pass**: Feature works as expected
- ❌ **Fail**: Bug found, needs fixing
- ⚠️ **Warning**: Works but has minor UI issue
- ⏭️ **Skip**: Not applicable for this platform
- 🔄 **Retest**: Bug fixed, needs verification

---

## 5. Owner Dashboard Test Cases

### 5.1 Authentication & Onboarding

#### 5.1.1 Registration Flow
**Test ID**: `OD-AUTH-001`

**Steps**:
1. Navigate to registration screen
2. Fill form with valid data:
   - Email: `new-owner-test@example.com`
   - Password: `SecureP@ss123`
   - Confirm password: `SecureP@ss123`
   - First name: `Test`
   - Last name: `Owner`
3. Submit registration
4. Verify email verification screen appears
5. Check email inbox for verification link
6. Click verification link
7. Verify redirect to dashboard

**Expected Results**:
- ✅ Form validation shows errors for invalid inputs
- ✅ Password strength indicator works
- ✅ Email sent successfully
- ✅ Verification link works on all platforms
- ✅ Keyboard dismisses correctly (Android Chrome BACK button)

**Platform-Specific Checks**:
- **Android**: Keyboard dismiss on BACK button (uses `AndroidKeyboardDismissFix` mixin)
- **iOS**: Keyboard toolbar appears with "Done" button
- **Web**: Enter key submits form

---

#### 5.1.2 Login Flow
**Test ID**: `OD-AUTH-002`

**Steps**:
1. Navigate to login screen
2. Enter valid credentials
3. Submit login
4. Verify redirect to dashboard

**Test Variations**:
- Invalid email format
- Wrong password
- Account not verified
- Rate limiting (10+ failed attempts)

**Expected Results**:
- ✅ Error messages appear correctly
- ✅ Rate limiting triggers after 10 attempts (check Sentry for `logRateLimitExceeded` event)
- ✅ "Forgot Password" link works

---

#### 5.1.3 Password Reset
**Test ID**: `OD-AUTH-003`

**Steps**:
1. Click "Forgot Password"
2. Enter registered email
3. Submit
4. Check email for reset link
5. Click link
6. Enter new password (test password validation)
7. Submit
8. Login with new password

**Expected Results**:
- ✅ Email sent successfully
- ✅ Reset link expires after 1 hour
- ✅ Password validation enforces rules (min 8 chars, uppercase, number, special char)
- ✅ Cannot reuse last 5 passwords (check `passwordHistory` Cloud Function)

---

### 5.2 Profile Management

#### 5.2.1 View Profile
**Test ID**: `OD-PROFILE-001`

**Steps**:
1. Navigate to Profile screen from drawer
2. Verify all fields display correctly:
   - First name
   - Last name
   - Email
   - Phone (optional)
   - Language preference
   - Theme (Light/Dark)

**Expected Results**:
- ✅ Data loads from Firestore
- ✅ Skeleton loader appears during loading
- ✅ Error handling if network fails

---

#### 5.2.2 Edit Profile
**Test ID**: `OD-PROFILE-002`

**Steps**:
1. Click "Edit Profile"
2. Modify fields:
   - First name: `UpdatedName`
   - Phone: `+385 91 234 5678`
   - Language: Switch from English to Croatian
3. Save changes
4. Verify snackbar confirmation
5. Navigate away and back to verify persistence

**Expected Results**:
- ✅ Form validation (phone format, required fields)
- ✅ Firestore update succeeds
- ✅ `ref.invalidate(ownerProvider)` called after save
- ✅ Language change updates UI immediately

**Platform-Specific Checks**:
- **Android**: Keyboard dismiss on save
- **iOS**: Keyboard toolbar "Done" button
- **Web**: Tab navigation between fields

---

#### 5.2.3 Change Password
**Test ID**: `OD-PROFILE-003`

**Steps**:
1. Navigate to "Change Password" screen
2. Enter current password
3. Enter new password (must differ from current)
4. Confirm new password
5. Submit

**Test Variations**:
- Wrong current password
- New password same as current
- Passwords don't match
- Weak password (fails validation)

**Expected Results**:
- ✅ Current password verified
- ✅ Cannot reuse last 5 passwords
- ✅ Password strength indicator shows
- ✅ Success snackbar after change
- ✅ Logged out and redirected to login (re-authenticate with new password)

---

### 5.3 Property Management

#### 5.3.1 Create Property
**Test ID**: `OD-PROPERTY-001`

**Steps**:
1. Navigate to Dashboard → "Add Property"
2. Fill property form:
   - Name: `Test Villa`
   - Subdomain: `test-villa` (validate uniqueness)
   - Address: Full address fields
   - Description: Brief property description
3. Upload property images (test multiple files)
4. Save property

**Expected Results**:
- ✅ Subdomain validation (3-30 chars, lowercase, alphanumeric + hyphens)
- ✅ Subdomain uniqueness check (Firestore query)
- ✅ Image upload to Firebase Storage
- ✅ Property document created in Firestore: `/properties/{propertyId}`
- ✅ Navigation to property details screen

**Platform-Specific Checks**:
- **iOS**: Photo picker UI
- **Android**: File picker integration
- **Web**: File upload dialog

---

#### 5.3.2 Edit Property
**Test ID**: `OD-PROPERTY-002`

**Steps**:
1. Navigate to existing property
2. Click "Edit Property"
3. Modify fields:
   - Name: `Updated Villa Name`
   - Description: Longer text
4. Replace one image
5. Save changes

**Expected Results**:
- ✅ Pre-populated form with existing data
- ✅ Image replacement deletes old Firebase Storage file
- ✅ Firestore update succeeds
- ✅ `ref.invalidate(propertiesProvider)` called

---

#### 5.3.3 Delete Property
**Test ID**: `OD-PROPERTY-003`

**Steps**:
1. Navigate to property with NO units
2. Click "Delete Property"
3. Confirm deletion in dialog

**Test Variations**:
- Attempt delete property WITH units (should fail with error)

**Expected Results**:
- ✅ Warning dialog appears
- ✅ Cannot delete if units exist
- ✅ Firestore document deleted
- ✅ Images deleted from Storage
- ✅ Subdomain freed for reuse

---

### 5.4 Unit Management

#### 5.4.1 Create Unit (Wizard Flow)
**Test ID**: `OD-UNIT-001`

**Steps**:

**Step 1 - Basic Info**:
1. Navigate to Property → "Add Unit"
2. Fill basic info:
   - Unit name: `Apartman 1`
   - Slug: `apartman-1` (auto-generated, test manual edit)
   - Unit type: Apartment
   - Description: Unit details
3. Click "Next"

**Step 2 - Capacity**:
4. Set capacity:
   - Adults: 4
   - Children: 2
   - Beds: 2 double beds
   - Bathrooms: 1
5. Click "Next"

**Step 3 - Pricing**:
6. Set pricing:
   - Base price: €100
   - Currency: EUR
   - Cleaning fee: €30
   - Deposit: €200
   - Min nights: 2
   - Max nights: 30
   - Min advance booking: 1 day
   - Max advance booking: 365 days
7. Click "Publish"

**Expected Results**:
- ✅ Slug auto-generated from unit name (lowercase, hyphens)
- ✅ `_isManualSlugEdit` flag prevents auto-regeneration after manual edit
- ✅ **CRITICAL**: 3 Firestore documents created in ORDER:
  1. `/properties/{propertyId}/units/{unitId}` (unit data)
  2. `/properties/{propertyId}/units/{unitId}/widget_settings/{default}` (widget config)
  3. `/daily_prices/{unitId}` subcollection (price calendar)
- ✅ Navigation to Unit Hub screen
- ✅ `ref.invalidate(unitsProvider)` called

**Validation Tests**:
- Min nights > Max nights (should show warning)
- Min advance > Max advance (should show warning)
- Negative price (should fail validation)

---

#### 5.4.2 Edit Unit
**Test ID**: `OD-UNIT-002`

**Steps**:
1. Navigate to Unit Hub → "Edit Unit"
2. Modify fields:
   - Unit name: `Updated Apartman Name`
   - Slug: Leave unchanged (test stability)
   - Base price: €120
3. Save changes

**Expected Results**:
- ✅ Slug does NOT regenerate (unless manually edited)
- ✅ Price update reflects in calendar
- ✅ Widget displays updated info immediately

---

#### 5.4.3 Delete Unit
**Test ID**: `OD-UNIT-003`

**Steps**:
1. Navigate to Unit Hub
2. Click "Delete Unit"
3. Confirm deletion

**Test Variations**:
- Unit with active bookings (should warn but allow deletion)
- Unit with only cancelled bookings

**Expected Results**:
- ✅ Warning dialog if active bookings exist
- ✅ Firestore documents deleted:
  - `/properties/{propertyId}/units/{unitId}`
  - All subcollections (widget_settings, daily_prices, bookings)
- ✅ Images deleted from Storage

---

### 5.5 Pricing & Calendar

#### 5.5.1 Base Pricing Configuration
**Test ID**: `OD-PRICING-001`

**Steps**:
1. Navigate to Unit Hub → "Cjenovnik" tab
2. Verify base pricing display:
   - Base price per night
   - Cleaning fee
   - Deposit
3. Click "Edit Pricing"
4. Modify values:
   - Base price: €150
   - Cleaning fee: €40
5. Save

**Expected Results**:
- ✅ Changes update Firestore: `/properties/{propertyId}/units/{unitId}/pricing`
- ✅ Calendar recalculates prices
- ✅ Widget reflects new prices immediately

---

#### 5.5.2 Price Calendar - Seasonal Pricing
**Test ID**: `OD-PRICING-002`

**Steps**:
1. Navigate to "Calendar" tab
2. Select date range (e.g., July 1-31 for summer pricing)
3. Click "Edit Price"
4. Set custom price: €200 per night
5. Save

**Expected Results**:
- ✅ Price override created in `/daily_prices/{unitId}` subcollection
- ✅ Calendar cells show updated price
- ✅ Widget booking form calculates with seasonal price

**Test Variations**:
- Overlapping date ranges (should replace old price)
- Partial month selection
- Single day selection

---

#### 5.5.3 Price Calendar - Bulk Availability Block
**Test ID**: `OD-PRICING-003`

**Steps**:
1. Select date range (e.g., December 20-27 for personal use)
2. Click "Mark as Unavailable"
3. Confirm action

**Expected Results**:
- ✅ Dates marked as `available: false` in `/daily_prices/{unitId}`
- ✅ Calendar cells show blocked status (gray)
- ✅ Widget hides dates from available selection

**Reverse Test**:
4. Select same date range
5. Click "Mark as Available"
6. Verify dates unblocked

**Expected Results**:
- ✅ Permission-denied bug FIX verified (Changelog 6.3 - `platform_connections` query succeeds)
- ✅ Dates available in widget again

---

#### 5.5.4 Price Calendar - Min/Max Validation
**Test ID**: `OD-PRICING-004`

**Steps**:
1. Edit pricing for date range
2. Set Min nights: 5
3. Set Max nights: 3 (invalid)
4. Save

**Expected Results**:
- ✅ Warning snackbar: "Min nights cannot exceed max nights"
- ✅ Save blocked until fixed

**Repeat for advance booking days**:
5. Set Min advance: 30 days
6. Set Max advance: 7 days (invalid)
7. Verify same warning appears

---

### 5.6 Bookings Management

#### 5.6.1 View Bookings List
**Test ID**: `OD-BOOKINGS-001`

**Steps**:
1. Navigate to "Bookings" screen
2. Verify booking list displays:
   - Guest name
   - Check-in / Check-out dates
   - Status badge (confirmed/pending/cancelled)
   - Total price
   - Platform icon (if external booking)

**Filter Tests**:
3. Filter by status: "Confirmed"
4. Filter by date range: Next 30 days
5. Search by guest name

**Expected Results**:
- ✅ Bookings load from Firestore: `collectionGroup('bookings').where('owner_id', '==', ownerId)`
- ✅ Platform icons visible for external bookings (Airbnb, Booking.com, iCal)
- ✅ Filters update query in real-time
- ✅ Skeleton loader during data fetch

---

#### 5.6.2 View Booking Details
**Test ID**: `OD-BOOKINGS-002`

**Steps**:
1. Click on a booking from list
2. Verify dialog displays:
   - **Guest Information**:
     - Name, Email, Phone
     - Country
     - Number of guests
     - Source/Platform (for external bookings - Changelog 6.9)
   - **Booking Information**:
     - Check-in / Check-out dates
     - Number of nights
     - Status
     - Booking reference
   - **Pricing**:
     - Price per night
     - Cleaning fee
     - Deposit
     - Total price
   - **Payment**:
     - Payment method
     - Payment status

**Expected Results**:
- ✅ Platform icon visible in Guest Information section for external bookings
- ✅ "Izvor/Source" field shows platform name (Booking.com, Airbnb, Direct, iCal)
- ✅ All data matches Firestore booking document

---

#### 5.6.3 Create Manual Booking
**Test ID**: `OD-BOOKINGS-003`

**Steps**:
1. Navigate to Timeline Calendar or Bookings screen
2. Click "Add Booking"
3. Fill booking form:
   - Select unit
   - Select dates (check-in/check-out)
   - Guest details:
     - Name: `Manual Test Guest`
     - Email: `manual-guest@example.com`
     - Phone: `+385 91 111 2222`
     - Country: Croatia
   - Number of guests: 2 adults, 1 child
   - Payment method: Bank Transfer
   - Mark as "Paid" (or leave pending)
4. Save booking

**Expected Results**:
- ✅ Booking created in Firestore: `/properties/{propertyId}/units/{unitId}/bookings/{bookingId}`
- ✅ Booking reference auto-generated (6 chars, alphanumeric)
- ✅ Calendar updates with new booking
- ✅ Email sent to guest (if email notifications enabled)
- ✅ Email sent to owner (always - `forceIfCritical=true`)

**Validation Tests**:
- Overlapping dates (should warn about overbooking)
- Invalid email format
- Check-out before check-in date

---

#### 5.6.4 Edit Existing Booking
**Test ID**: `OD-BOOKINGS-004`

**Steps**:
1. Open booking details dialog
2. Click "Edit Booking"
3. Modify fields:
   - Change check-out date (extend by 2 days)
   - Update guest phone number
4. Save changes

**Expected Results**:
- ✅ **Warning dialog** appears (Changelog 5.7 - `UpdateBookingWarningDialog`)
- ✅ Firestore update succeeds
- ✅ Calendar reflects new dates
- ✅ Price recalculates if dates changed
- ✅ Email sent to guest about changes (if enabled)

---

#### 5.6.5 Cancel Booking
**Test ID**: `OD-BOOKINGS-005`

**Steps**:
1. Open booking details
2. Click "Cancel Booking"
3. Confirm cancellation

**Expected Results**:
- ✅ Status updated to `cancelled`
- ✅ Calendar freed (dates available again)
- ✅ Cancellation email sent to guest
- ✅ Notification sent to owner

---

#### 5.6.6 Timeline Calendar View
**Test ID**: `OD-BOOKINGS-006`

**Steps**:
1. Navigate to "Timeline Calendar" screen
2. Verify display:
   - All units listed vertically
   - Bookings displayed as horizontal blocks
   - Date headers at top
3. Scroll horizontally to view future months
4. Click on a booking block → details dialog opens

**Test Scenarios**:
- **Turnover Day**: Two bookings on same day (one check-out, one check-in)
  - ✅ Both blocks visible
  - ✅ No overlap (check-out ends at 12:00, check-in starts at 14:00)
- **Conflict Warning**: Overlapping bookings (overbooking)
  - ✅ Warning icon visible on block
  - ✅ Tooltip shows conflict details with platform name (Changelog 6.9)
- **External Bookings**: Platform icon visible
  - ✅ Icon in top-right corner of block (Changelog 6.9)
  - ✅ Auto-offset if conflict warning icon also present (28px offset)

**Platform-Specific Checks**:
- **Z-index rendering**: Cancelled bookings FIRST, confirmed LAST
- **Performance**: Smooth scrolling with 100+ bookings
- **Mobile**: Horizontal scroll works with touch gestures

---

### 5.7 Widget Settings

#### 5.7.1 View Widget Settings
**Test ID**: `OD-WIDGET-001`

**Steps**:
1. Navigate to Unit Hub → "Widget" tab
2. Verify all settings sections display:
   - **Basic Settings**:
     - Widget mode (Full booking / Calendar-only)
     - Custom URL (subdomain + slug)
   - **Contact Information**:
     - Email
     - Phone
     - WhatsApp
   - **Payment Settings**:
     - Accepted methods (Stripe / Bank Transfer)
     - Stripe Connect account status
   - **Email Notifications**:
     - Owner email
     - Guest confirmation email
     - Reminder emails
   - **Localization**:
     - Supported languages
     - Default language
     - Currency

**Expected Results**:
- ✅ Data loads from `/properties/{propertyId}/units/{unitId}/widget_settings/default`
- ✅ Preview URL displayed: `https://{subdomain}.view.bookbed.io/{slug}`
- ✅ Stripe Connect status badge (Connected / Not Connected)

---

#### 5.7.2 Configure Widget Mode
**Test ID**: `OD-WIDGET-002`

**Steps**:
1. Edit widget settings
2. Switch mode to "Calendar-only"
3. Save
4. Open widget in browser (use preview URL)
5. Verify:
   - Calendar visible
   - Booking form HIDDEN
   - Contact information banner visible
   - "Contact Owner" button works

**Reverse Test**:
6. Switch back to "Full booking"
7. Verify booking form appears in widget

**Expected Results**:
- ✅ Mode saved to Firestore: `widget_settings.general.widgetMode`
- ✅ Widget UI updates based on mode
- ✅ No booking form fields in calendar-only mode

---

#### 5.7.3 Stripe Connect Setup
**Test ID**: `OD-WIDGET-003`

**Steps**:
1. Navigate to "Payment Settings"
2. Click "Connect Stripe"
3. Complete Stripe onboarding flow:
   - Business details
   - Bank account info (test data)
   - Identity verification (test mode - auto-approved)
4. Return to BookBed after onboarding
5. Verify "Connected" badge appears

**Expected Results**:
- ✅ Redirect to Stripe Connect OAuth
- ✅ Stripe account ID saved to Firestore: `widget_settings.payment.stripeAccountId`
- ✅ Account verified (`charges_enabled`, `card_payments`, `transfers` - Changelog 5.4)
- ✅ Widget payment form shows Stripe option

**Error Tests**:
- Incomplete Stripe onboarding (account not verified)
  - ✅ Error message: "Stripe account not fully set up"
  - ✅ Widget hides Stripe payment option

---

#### 5.7.4 Bank Transfer Configuration
**Test ID**: `OD-WIDGET-004`

**Steps**:
1. Navigate to "Bank Account" screen (from drawer)
2. Fill bank details:
   - Account holder: `Test Owner`
   - IBAN: `HR1234567890123456789`
   - Bank name: `Test Bank`
3. Save
4. Navigate to widget settings
5. Enable "Bank Transfer" payment method
6. Save

**Expected Results**:
- ✅ Bank details saved to `/owners/{ownerId}/bank_account`
- ✅ Widget payment form shows "Bank Transfer" option
- ✅ Bank details displayed after payment selection

---

#### 5.7.5 Email Notifications Configuration
**Test ID**: `OD-WIDGET-005`

**Steps**:
1. Navigate to "Email Settings" in widget config
2. Configure:
   - Owner notification email: Enable
   - Guest confirmation email: Enable
   - Payment reminder: Enable (sent Day 6 before deadline - Changelog 5.5)
   - Check-in reminder: Enable (sent 7 days before - Changelog 5.5)
3. Save

**Expected Results**:
- ✅ Settings saved to `widget_settings.emailConfig`
- ✅ Cloud Function `sendBookingEmail` uses these settings
- ✅ Owner email ALWAYS sent (`forceIfCritical=true` - Changelog 5.3)

---

### 5.8 Platform Connections (External Bookings)

#### 5.8.1 iCal Sync Setup
**Test ID**: `OD-PLATFORM-001`

**Steps**:
1. Navigate to "Platform Connections" screen
2. Click "Add Connection"
3. Select platform: Airbnb
4. Paste iCal URL: `https://www.airbnb.com/calendar/ical/xxx.ics`
5. Save

**Expected Results**:
- ✅ Connection saved to Firestore: `/platform_connections/{connectionId}`
- ✅ Cloud Function `syncIcalFeed` triggered (scheduled, every 6 hours)
- ✅ Airbnb bookings imported as `ical_events` subcollection
- ✅ Timeline calendar shows Airbnb bookings with platform icon

**Test Variations**:
- Booking.com iCal URL
- VRBO iCal URL
- Invalid iCal URL (should show error)

---

#### 5.8.2 iCal Export
**Test ID**: `OD-PLATFORM-002`

**Steps**:
1. Navigate to Unit Hub → "Platform Connections"
2. Click "Generate iCal Export URL"
3. Copy URL
4. Paste into Airbnb/Booking.com import field (simulation - don't actually do this in test mode)

**Expected Results**:
- ✅ Export URL format: `https://us-central1-{project}.cloudfunctions.net/icalExport?unitId={unitId}&token={token}`
- ✅ URL works (returns .ics file)
- ✅ Contains all confirmed bookings
- ✅ Updates when new bookings created

---

### 5.9 Analytics

#### 5.9.1 View Analytics Dashboard
**Test ID**: `OD-ANALYTICS-001`

**Steps**:
1. Navigate to "Analytics" screen
2. Verify widgets display:
   - Total bookings (current month)
   - Total revenue (current month)
   - Occupancy rate (%)
   - Average booking value
3. Select date range: Last 3 months
4. Verify charts update:
   - Revenue over time (line chart)
   - Bookings by unit (bar chart)
   - Booking sources (pie chart - Direct vs External)

**Expected Results**:
- ✅ Data queries use `collectionGroup('bookings')` with proper filters (Changelog 5.8 - security rules fix)
- ✅ No `permission-denied` errors
- ✅ Charts render correctly on all platforms
- ✅ Skeleton loaders during data fetch

**Platform-Specific Checks**:
- **Mobile**: Charts responsive (stacked vertically)
- **Desktop**: Charts side-by-side
- **Web**: Interactive tooltips on hover

---

### 5.10 Notifications

#### 5.10.1 View Notifications List
**Test ID**: `OD-NOTIF-001`

**Steps**:
1. Navigate to "Notifications" screen
2. Verify notifications display:
   - Unread badge count
   - Notification types:
     - New booking
     - Booking cancellation
     - Payment received
     - Check-in reminder
   - Timestamps (relative time)

**Expected Results**:
- ✅ Notifications load from Firestore: `/owners/{ownerId}/notifications`
- ✅ Unread count updates in drawer menu
- ✅ Mark as read functionality works

---

#### 5.10.2 Notification Interaction
**Test ID**: `OD-NOTIF-002`

**Steps**:
1. Click on notification (e.g., "New booking for Apartman 1")
2. Verify navigation:
   - Redirects to relevant screen (Bookings screen)
   - Booking details dialog opens automatically
   - Notification marked as read

**Expected Results**:
- ✅ Deep linking works (Changelog 5.9 - race condition fix)
- ✅ Dialog opens ONCE (no double/triple opens)
- ✅ URL query params cleaned after dialog shown

---

### 5.11 UI/UX & Theming

#### 5.11.1 Dark Mode
**Test ID**: `OD-UI-001`

**Steps**:
1. Navigate to Profile → Theme Settings
2. Switch to "Dark Mode"
3. Navigate through all screens
4. Verify:
   - Gradients use dark theme colors (Changelog 6.0+)
   - Text readable (sufficient contrast)
   - Dialogs use `AppColors.dialogFooterDark`
   - Cards use `AppShadows.elevation1`

**Expected Results**:
- ✅ No pure white backgrounds (use `veryDarkGray` #1A1A1A)
- ✅ Consistent color scheme across all screens
- ✅ Icons use primary color with 10-12% opacity background

---

#### 5.11.2 Responsive Design
**Test ID**: `OD-UI-002`

**Steps**:
1. Test on each platform size:
   - **Mobile** (<600px): Drawer navigation, stacked layouts
   - **Tablet** (600-1199px): Mixed layouts
   - **Desktop** (≥1200px): EndDrawer, side-by-side layouts

**Expected Results**:
- ✅ Breakpoints trigger correct layouts
- ✅ Desktop uses EndDrawer (not Drawer)
- ✅ Mobile cards stack vertically
- ✅ No horizontal overflow

---

#### 5.11.3 Skeleton Loaders
**Test ID**: `OD-UI-003`

**Steps**:
1. Slow down network (Chrome DevTools → Network → Slow 3G)
2. Navigate to screens with async data:
   - Dashboard
   - Bookings list
   - Analytics
3. Verify skeleton loaders appear

**Expected Results**:
- ✅ Skeletons use `SkeletonColors.baseColor/highlightColor`
- ✅ Shimmer animation smooth
- ✅ Layout matches final content (no layout shift)

---

### 5.12 PWA (Progressive Web App)

#### 5.12.1 PWA Installation - Desktop
**Test ID**: `OD-PWA-001`

**Steps**:
1. Open Owner Dashboard in Chrome (desktop)
2. Verify install button appears in address bar
3. Click install
4. Verify PWA icon appears on desktop
5. Launch PWA from desktop icon
6. Verify standalone mode (no browser UI)

**Expected Results**:
- ✅ `canInstallPwa()` returns true before install
- ✅ `isPwaInstalled()` returns true after install
- ✅ PWA runs in standalone window
- ✅ Manifest icons load correctly

---

#### 5.12.2 PWA Installation - Mobile
**Test ID**: `OD-PWA-002`

**Steps**:
1. Open Owner Dashboard on Safari iOS
2. Tap Share → "Add to Home Screen"
3. Verify PWA icon appears on home screen
4. Launch from home screen
5. Verify full-screen mode

**Android Chrome**:
6. Open in Chrome Mobile
7. Tap menu → "Add to Home Screen"
8. Verify install banner appears
9. Install and launch

**Expected Results**:
- ✅ iOS PWA uses correct icons (from `web/icons/`)
- ✅ Android PWA uses maskable icons
- ✅ Splash screen displays correctly
- ✅ Offline fallback (if network lost)

---

#### 5.12.3 PWA Custom Install Button
**Test ID**: `OD-PWA-003`

**Steps**:
1. Open Owner Dashboard in browser
2. Verify custom install button appears (if not already installed)
3. Click button
4. Verify native install prompt appears
5. Complete installation

**Expected Results**:
- ✅ `PwaInstallButton` widget visible
- ✅ `promptPwaInstall()` triggers native prompt
- ✅ Button hides after installation

---

### 5.13 Error Handling & Edge Cases

#### 5.13.1 Network Failure
**Test ID**: `OD-ERROR-001`

**Steps**:
1. Disconnect internet (Airplane mode or disable Wi-Fi)
2. Navigate to any screen with async data
3. Verify error handling:
   - Error message displayed
   - Retry button available
4. Reconnect internet
5. Tap retry
6. Verify data loads

**Expected Results**:
- ✅ Graceful degradation (no crash)
- ✅ Connectivity banner appears (PWA feature)
- ✅ Retry succeeds after reconnection
- ✅ Sentry logs error (check dashboard)

---

#### 5.13.2 Firestore Permission Denied
**Test ID**: `OD-ERROR-002`

**Steps**:
1. Manually modify Firestore rules to deny read on `/properties`
2. Navigate to Dashboard
3. Verify error handling:
   - User-friendly error message
   - No sensitive error details exposed

**Expected Results**:
- ✅ Error caught in provider `try-catch`
- ✅ `LoggingService.logError()` called (sends to Sentry)
- ✅ Empty state UI shown (not crash)

**Cleanup**: Restore Firestore rules

---

#### 5.13.3 Concurrent Booking Conflict
**Test ID**: `OD-ERROR-003`

**Steps**:
1. Open Timeline Calendar in two browser tabs
2. In Tab 1: Select dates and start creating booking
3. In Tab 2: Create booking for SAME dates (complete first)
4. In Tab 1: Complete booking
5. Verify conflict detection:
   - Warning dialog appears
   - User can choose to proceed or cancel

**Expected Results**:
- ✅ Overbooking detection triggers
- ✅ Cloud Function logs security event (`logOverbookingDetection`)
- ✅ Owner receives notification about conflict

---

## 6. Booking Widget Test Cases

### 6.1 Widget Discovery & Loading

#### 6.1.1 Subdomain Resolution
**Test ID**: `WIDGET-LOAD-001`

**Steps**:
1. Navigate to: `https://villa-marija.view.bookbed.io`
2. Verify:
   - Subdomain resolves to correct property
   - Default unit loads (if only one unit)
   - Calendar displays

**Test Variations**:
- Invalid subdomain: `https://nonexistent.view.bookbed.io`
  - ✅ "Subdomain Not Found" screen appears
- Multiple units: `https://kuca-rab.view.bookbed.io`
  - ✅ Unit selection dropdown appears

**Expected Results**:
- ✅ `SubdomainService.resolveFullContext()` succeeds
- ✅ Property/unit data loads from Firestore
- ✅ Hybrid progressive loading (Changelog 6.0):
  - UI appears immediately with skeleton calendar
  - `hideNativeSplash()` called in initState
  - Loading time ~4s (not 10-14s)

---

#### 6.1.2 Slug-Based Routing
**Test ID**: `WIDGET-LOAD-002`

**Steps**:
1. Navigate to: `https://villa-marija.view.bookbed.io/apartman-1`
2. Verify:
   - Slug resolves to correct unit
   - Calendar loads for that specific unit
   - URL is clean (no query params)

**Test Variations**:
- Invalid slug: `/nonexistent-unit`
  - ✅ 404 or redirect to subdomain root

**Expected Results**:
- ✅ `fullSlugContextProvider(slug)` resolves unit
- ✅ Direct link shareable (no need for query params)

---

#### 6.1.3 Query Parameter Fallback
**Test ID**: `WIDGET-LOAD-003`

**Steps**:
1. Navigate to: `https://villa-marija.view.bookbed.io/?property=XXX&unit=YYY`
2. Verify calendar loads correctly

**Expected Results**:
- ✅ Supports both URL formats (query params + slug)
- ✅ Query params useful for iframe embeds

---

### 6.2 Calendar Interaction

#### 6.2.1 Date Selection - Valid Range
**Test ID**: `WIDGET-CAL-001`

**Steps**:
1. Open widget
2. Click on available check-in date (e.g., +7 days from today)
3. Click on available check-out date (e.g., +10 days from today)
4. Verify:
   - Date range highlights
   - Night count displays
   - Price calculation updates

**Expected Results**:
- ✅ Minimum stay enforced (e.g., 2 nights)
- ✅ Selected dates valid (not blocked, not booked)
- ✅ Price fetched from `daily_prices` collection (includes seasonal rates)

---

#### 6.2.2 Date Selection - Invalid Range
**Test ID**: `WIDGET-CAL-002`

**Steps**:
1. Click on check-in date
2. Click on check-out date that's BEFORE check-in
3. Verify error message

**Test Variations**:
- Check-in = Check-out (same day)
  - ✅ Error: "Minimum stay is X nights"
- Check-out on booked date
  - ✅ Date unselectable (grayed out)

**Expected Results**:
- ✅ Validation prevents invalid selections
- ✅ Snackbar shows error message

---

#### 6.2.3 Calendar Status Display
**Test ID**: `WIDGET-CAL-003`

**Steps**:
1. View calendar
2. Verify status colors:
   - **Available**: Green (`#10B981` light, `#34D399` dark)
   - **Booked**: Red (`#EF4444` light, `#F87171` dark)
   - **Pending**: Amber (`#F59E0B` light, `#FBBF24` dark) + diagonal pattern
   - **Blocked**: Gray (not selectable)
   - **Turnover Day**: Two colors (check-out AM, check-in PM)

**Expected Results**:
- ✅ Colors match calendar status enum
- ✅ Pending dates show diagonal pattern (`#6B4C00` @ 60%)
- ✅ Turnover days display both bookings

---

#### 6.2.4 Calendar Navigation
**Test ID**: `WIDGET-CAL-004`

**Steps**:
1. Click "Next Month" button
2. Verify calendar advances to next month
3. Click "Previous Month"
4. Verify calendar goes back

**Test Variations**:
- Scroll to view multiple months (lazy calendar)
- Jump to specific month (date picker)

**Expected Results**:
- ✅ Month navigation buttons work (Changelog 6.4 - fixed 2-click bug)
- ✅ Smooth animation (no excessive rebuilds)
- ✅ Performance optimized (cached date range, dynamic threshold)

---

### 6.3 Booking Form

#### 6.3.1 Guest Information - Valid Input
**Test ID**: `WIDGET-FORM-001`

**Steps**:
1. Select valid date range
2. Proceed to booking form
3. Fill guest details:
   - First name: `John`
   - Last name: `Doe`
   - Email: `john.doe@example.com`
   - Phone: `+385 91 123 4567`
   - Country: Croatia
4. Number of guests:
   - Adults: 2
   - Children: 1
5. Click "Next"

**Expected Results**:
- ✅ Form validation passes
- ✅ Email format validated
- ✅ Phone format validated
- ✅ Guest count within unit capacity
- ✅ Proceed to payment step

---

#### 6.3.2 Guest Information - Invalid Input
**Test ID**: `WIDGET-FORM-002`

**Steps**:
1. Fill form with invalid data:
   - Email: `invalid-email`
   - Phone: `123` (too short)
   - Adults: 0
2. Click "Next"

**Expected Results**:
- ✅ Form validation errors display
- ✅ Cannot proceed until fixed
- ✅ Input sanitization applied (`sanitizeEmail`, `sanitizeText`)

---

#### 6.3.3 Email Verification (Optional Feature)
**Test ID**: `WIDGET-FORM-003`

**Setup**: Enable email verification in widget settings

**Steps**:
1. Enter email: `verify-test@example.com`
2. Click "Verify Email" button
3. Check email inbox for verification code
4. Enter code in widget
5. Verify success badge appears

**Expected Results**:
- ✅ Verification email sent (Cloud Function `sendEmailVerificationCode`)
- ✅ Code valid for 10 minutes
- ✅ Verified badge shown (Changelog 6.2 - height 50px)
- ✅ Cannot edit email after verification

**Test Variations**:
- Wrong verification code (should show error)
- Expired code (should allow resend)

---

### 6.4 Payment Flow

#### 6.4.1 Payment Method Selection
**Test ID**: `WIDGET-PAY-001`

**Steps**:
1. Proceed to payment step
2. Verify available payment methods:
   - Stripe (if owner configured)
   - Bank Transfer (if owner configured)
3. Select each method and verify UI updates

**Expected Results**:
- ✅ Only configured methods shown
- ✅ Stripe option shows card form
- ✅ Bank Transfer shows bank details
- ✅ Button text updated (Changelog 6.2):
  - "Credit Card" (not "Credit Card (Stripe)")
  - "Bank Transfer" (not "Continue to Bank Transfer")

---

#### 6.4.2 Stripe Payment - Success Flow
**Test ID**: `WIDGET-PAY-002`

**Steps**:
1. Select "Credit Card" payment method
2. Click "Pay with Card"
3. **CRITICAL**: Verify placeholder booking created:
   - Status: `pending`
   - Dates blocked in calendar
4. Redirect to Stripe Checkout (same tab)
5. Enter test card: `4242 4242 4242 4242`
6. Complete payment
7. Return to widget (return URL with `?stripe_status=success&session_id=cs_xxx`)
8. **CRITICAL**: Verify polling behavior:
   - Widget polls `fetchBookingByStripeSessionId()` (max 30s)
   - Status updates from `pending` → `confirmed`
9. Verify confirmation screen displays:
   - Booking reference
   - Guest details
   - Booking dates
   - Total paid
   - Email confirmation sent

**Expected Results**:
- ✅ Placeholder booking prevents race condition (two users can't book same dates)
- ✅ Stripe webhook updates booking status (Cloud Function `handleStripeWebhook`)
- ✅ Polling timeout 30s (not infinite)
- ✅ Cross-tab messaging works (BroadcastChannel + postMessage with `sessionId`)
- ✅ Navigation to confirmation screen (Navigator.push - not state-based)
- ✅ Emails sent:
  - Guest confirmation (if enabled)
  - Owner notification (ALWAYS - `forceIfCritical=true`)

---

#### 6.4.3 Stripe Payment - Failure Flow
**Test ID**: `WIDGET-PAY-003`

**Steps**:
1. Select "Credit Card"
2. Click "Pay with Card"
3. Enter declined card: `4000 0000 0000 0002`
4. Attempt payment
5. Verify error handling

**Expected Results**:
- ✅ Stripe shows decline error
- ✅ User can retry with different card
- ✅ Placeholder booking remains `pending` (not confirmed)
- ✅ After 7 days, booking auto-cancelled (payment deadline - Changelog 5.5)

---

#### 6.4.4 Stripe Payment - 3D Secure
**Test ID**: `WIDGET-PAY-004`

**Steps**:
1. Select "Credit Card"
2. Enter 3D Secure test card: `4000 0025 0000 3155`
3. Complete 3D Secure challenge
4. Verify payment succeeds

**Expected Results**:
- ✅ 3D Secure modal appears
- ✅ Authentication succeeds
- ✅ Booking confirmed after authentication

---

#### 6.4.5 Bank Transfer Flow
**Test ID**: `WIDGET-PAY-005`

**Steps**:
1. Select "Bank Transfer" payment method
2. Verify bank details displayed:
   - Account holder
   - IBAN
   - Bank name
   - Booking reference (MUST include in transfer description)
3. Click "Confirm Booking"
4. Verify confirmation screen:
   - Status: `pending` (awaiting payment)
   - Payment deadline: 7 days (Changelog 5.5)
   - Bank transfer instructions card
   - Copy IBAN button works

**Expected Results**:
- ✅ Booking created with `status: pending`
- ✅ Email sent with bank details
- ✅ Payment reminder sent on Day 6 (Changelog 5.5)
- ✅ Auto-cancellation if not paid in 7 days

---

#### 6.4.6 Price Validation (Security)
**Test ID**: `WIDGET-PAY-006`

**Steps**:
1. Open browser DevTools
2. Select dates in widget (note displayed price)
3. Intercept payment request
4. Modify price in request payload (e.g., reduce by 50%)
5. Submit payment

**Expected Results**:
- ✅ Cloud Function `validateBookingPrice()` detects mismatch
- ✅ Booking rejected with error
- ✅ Security event logged (`logPriceMismatch` - Changelog 5.4)
- ✅ Sentry alert triggered (high severity - Changelog 6.6)

---

### 6.5 Booking Confirmation

#### 6.5.1 Confirmation Screen Display
**Test ID**: `WIDGET-CONFIRM-001`

**Steps**:
1. Complete successful booking
2. Verify confirmation screen shows:
   - Success message
   - Booking reference (large, bold)
   - Guest details
   - Property/unit name
   - Check-in / Check-out dates
   - Total price paid
   - Copy booking reference button
   - Email confirmation sent message

**Expected Results**:
- ✅ All data matches booking document
- ✅ Copy button works (Changelog 6.7 - try-catch for Safari iframe)
- ✅ Visual confirmation (checkmark icon, green colors)

---

#### 6.5.2 Email Confirmation Delivery
**Test ID**: `WIDGET-CONFIRM-002`

**Steps**:
1. After booking, check guest email inbox
2. Verify email received:
   - Subject: "Booking Confirmation - {Property Name}"
   - Body contains:
     - Booking reference
     - Guest name
     - Check-in/check-out dates
     - Total price
     - Payment method
     - View booking URL
3. Click "View Booking" link in email

**Expected Results**:
- ✅ Email sent via Cloud Function `sendBookingEmail`
- ✅ Template uses localized text (Croatian/English)
- ✅ View booking URL format: `https://{subdomain}.view.bookbed.io/view?ref=XXX&email=YYY`
- ✅ Link opens booking view screen

---

### 6.6 Booking View (Guest Portal)

#### 6.6.1 Access Booking View
**Test ID**: `WIDGET-VIEW-001`

**Steps**:
1. Navigate to view URL (from email): `https://villa-marija.view.bookbed.io/view?ref=ABC123&email=guest@example.com`
2. Verify access granted:
   - Booking details displayed
   - Guest can view full information

**Security Tests**:
3. Modify URL with wrong email: `...&email=wrong@example.com`
4. Verify access denied

**Expected Results**:
- ✅ Cloud Function `verifyBookingAccess` validates ref + email match
- ✅ Access token generated (valid 24 hours)
- ✅ Token stored in Firestore: `/booking_access_tokens/{tokenId}`
- ✅ Unauthorized access blocked

---

#### 6.6.2 Guest Cancellation
**Test ID**: `WIDGET-VIEW-002`

**Steps**:
1. Access booking view (authenticated)
2. Click "Cancel Booking" button
3. Confirm cancellation in dialog
4. Verify:
   - Status updates to `cancelled`
   - Cancellation email sent to guest
   - Owner notified

**Test Variations**:
- Attempt cancel booking in the past (check-in date passed)
  - ✅ Error: "Cannot cancel past bookings"

**Expected Results**:
- ✅ Cloud Function `guestCancelBooking` processes cancellation
- ✅ Calendar dates freed (available again)
- ✅ Refund initiated if paid via Stripe (test mode - no actual refund)

---

### 6.7 Widget Modes

#### 6.7.1 Full Booking Mode
**Test ID**: `WIDGET-MODE-001`

**Steps**:
1. Configure widget settings: Mode = "Full booking"
2. Open widget
3. Verify:
   - Calendar visible
   - Booking form accessible after date selection
   - Payment methods available

**Expected Results**:
- ✅ Complete booking flow enabled
- ✅ All payment options visible

---

#### 6.7.2 Calendar-Only Mode
**Test ID**: `WIDGET-MODE-002`

**Steps**:
1. Configure widget settings: Mode = "Calendar-only"
2. Open widget
3. Verify:
   - Calendar visible
   - NO booking form
   - Contact information banner visible
   - "Contact Owner" button present
4. Click "Contact Owner"
5. Verify:
   - Email/phone/WhatsApp links work
   - Opens in new tab/app

**Expected Results**:
- ✅ Booking form hidden
- ✅ Banner text updated (Changelog 6.2 - shorter text)
- ✅ Contact pill bar visible (Changelog 6.2 - 8px bottom padding)

---

### 6.8 Widget UI/UX

#### 6.8.1 Responsive Design - Mobile
**Test ID**: `WIDGET-UI-001`

**Steps**:
1. Open widget on mobile (≤600px)
2. Verify:
   - Calendar cells visible (not too small)
   - Form fields tap-friendly (50px height - Changelog 6.2)
   - No horizontal scroll
   - Proper spacing (8px padding - Changelog 6.2)

**Expected Results**:
- ✅ Mobile-first design
- ✅ Touch targets ≥44px (Apple HIG, Android Material)
- ✅ Keyboard doesn't cover input fields

---

#### 6.8.2 Responsive Design - Desktop
**Test ID**: `WIDGET-UI-002`

**Steps**:
1. Open widget on desktop (≥1200px)
2. Verify:
   - Calendar and form side-by-side (if space allows)
   - Wider layout (max-width constraint)
   - Hover effects on buttons

**Expected Results**:
- ✅ Desktop layout optimized for larger screens
- ✅ No wasted space

---

#### 6.8.3 Keyboard Dismiss Fix (Android Chrome)
**Test ID**: `WIDGET-UI-003`

**Platform**: Android physical device + Chrome browser

**Steps**:
1. Open booking form in widget
2. Tap on email input field → keyboard appears
3. Press Android BACK button to close keyboard
4. Verify layout recalculates correctly (no white space)

**Expected Results**:
- ✅ JavaScript "jiggle" fix triggers (Changelog 4.9)
- ✅ Dart mixin `AndroidKeyboardDismissFix` forces rebuild
- ✅ No white space where keyboard was
- ✅ `resizeToAvoidBottomInset: true` works in combination with mixin

---

#### 6.8.4 Snackbar Colors
**Test ID**: `WIDGET-UI-004`

**Steps**:
1. Trigger different snackbar types:
   - Success: Complete booking
   - Error: Invalid form submission
   - Warning: Select invalid date range
   - Info: General information
2. Verify colors match calendar statuses (Changelog 4.8):
   - Success = Available (green)
   - Error = Booked (red)
   - Warning = Pending (amber)
   - Info = Blue

**Expected Results**:
- ✅ Light theme: `#10B981`, `#EF4444`, `#F59E0B`, `#3B82F6`
- ✅ Dark theme: `#34D399`, `#F87171`, `#FBBF24`, `#60A5FA`
- ✅ Snackbars auto-hide after 3s
- ✅ Previous snackbar dismissed when new one appears

---

#### 6.8.5 Clipboard API Error Handling
**Test ID**: `WIDGET-UI-005`

**Platform**: Safari iOS (in iframe - restrictive environment)

**Steps**:
1. Embed widget in iframe (simulate restrictive context)
2. Complete booking
3. Click "Copy Booking Reference" button
4. Verify:
   - If clipboard access denied, error snackbar appears
   - Reference remains visible on screen (copy manually)

**Expected Results**:
- ✅ Try-catch around `Clipboard.setData()` (Changelog 6.7)
- ✅ Graceful degradation (no crash)
- ✅ User can still see reference to copy manually

---

### 6.9 External Bookings (iCal Sync)

#### 6.9.1 iCal Imported Booking Display
**Test ID**: `WIDGET-ICAL-001`

**Steps**:
1. Configure iCal sync (Owner Dashboard)
2. Wait for sync to complete (or trigger manually)
3. Open widget calendar
4. Verify external bookings visible:
   - Dates marked as booked
   - Cannot select for new booking

**Expected Results**:
- ✅ iCal events imported to `ical_events` subcollection
- ✅ Calendar query includes iCal events
- ✅ Dates blocked from selection

---

#### 6.9.2 Platform Icon Display
**Test ID**: `WIDGET-ICAL-002`

**Steps**:
1. View booking details for external booking (Owner Dashboard)
2. Verify platform icon visible:
   - **B** (blue #003580) = Booking.com
   - **A** (red #FF5A5F) = Airbnb
   - **🔗** (orange) = iCal/External
3. Verify "Source" field shows platform name (Changelog 6.9)

**Expected Results**:
- ✅ `PlatformIcon` widget renders correct icon
- ✅ Tooltip shows full platform name
- ✅ Icon visible in Timeline Calendar (top-right corner)

---

## 7. Cloud Functions Test Cases

### 7.1 Booking Creation (`atomicBooking`)

#### 7.1.1 Successful Booking Creation
**Test ID**: `CF-BOOK-001`

**Steps**:
1. Trigger booking creation from widget (Stripe payment)
2. Monitor Cloud Function logs:
   - Cloud Logging: https://console.cloud.google.com/logs
   - Filter: `resource.type="cloud_function" resource.labels.function_name="atomicBooking"`
3. Verify log entries:
   - `logInfo`: Booking creation started
   - Price validation passed
   - Firestore transaction succeeded
   - Emails queued

**Expected Results**:
- ✅ Structured logging (`logInfo`, `logError` from `logger.ts`)
- ✅ User context set (`setUser(uid)` - Changelog 6.8)
- ✅ Sentry breadcrumbs captured
- ✅ No errors in logs

---

#### 7.1.2 Price Mismatch Detection
**Test ID**: `CF-BOOK-002`

**Steps**:
1. Modify widget code to send wrong price (temporary test)
2. Attempt booking
3. Verify Cloud Function rejects:
   - Error message: "Price mismatch detected"
   - Security event logged (`logPriceMismatch`)
   - Sentry alert triggered (high severity)

**Expected Results**:
- ✅ `priceValidation.ts` detects mismatch
- ✅ Firestore `/security_events` document created
- ✅ Sentry receives error (Changelog 6.6)

---

### 7.2 Email Sending

#### 7.2.1 Booking Confirmation Email
**Test ID**: `CF-EMAIL-001`

**Steps**:
1. Create booking
2. Check guest email inbox (use real email in test mode)
3. Verify email received with correct template

**Expected Results**:
- ✅ Email sent via `sendBookingEmail` Cloud Function
- ✅ Template localized (Croatian/English based on guest language)
- ✅ All dynamic fields populated (booking ref, dates, price)
- ✅ View booking URL correct

---

#### 7.2.2 Payment Reminder Email
**Test ID**: `CF-EMAIL-002`

**Steps**:
1. Create booking with Bank Transfer (status: pending)
2. Wait for Day 6 (simulate by modifying booking `created_at` timestamp in Firestore)
3. Trigger scheduled function `sendPaymentReminders` (manually or wait for cron)
4. Verify email sent to guest

**Expected Results**:
- ✅ Reminder sent 1 day before deadline (Day 6 - Changelog 5.5)
- ✅ Email includes payment deadline date
- ✅ Bank transfer details included

---

#### 7.2.3 Check-in Reminder Email
**Test ID**: `CF-EMAIL-003`

**Steps**:
1. Create booking with check-in date 7 days in future
2. Trigger scheduled function `sendCheckInReminders`
3. Verify email sent to guest

**Expected Results**:
- ✅ Reminder sent 7 days before check-in (Changelog 5.5)
- ✅ Email includes check-in instructions (if configured)

---

### 7.3 Stripe Webhook

#### 7.3.1 Checkout Session Completed
**Test ID**: `CF-STRIPE-001`

**Steps**:
1. Complete Stripe payment in widget
2. Monitor Cloud Function logs for `handleStripeWebhook`
3. Verify:
   - Event type: `checkout.session.completed`
   - Webhook signature validated
   - Booking status updated: `pending` → `confirmed`

**Expected Results**:
- ✅ Signature validation (`stripe.webhooks.constructEvent`)
- ✅ Firestore transaction updates booking
- ✅ Confirmation email triggered
- ✅ No duplicate processing (idempotency)

---

#### 7.3.2 Webhook Signature Failure
**Test ID**: `CF-STRIPE-002`

**Steps**:
1. Send invalid webhook request (simulate with Postman)
2. Verify Cloud Function rejects:
   - Error: "Webhook signature verification failed"
   - Security event logged
   - Sentry alert

**Expected Results**:
- ✅ Request rejected (401/403)
- ✅ `logWebhookSignatureFailure` called (Changelog 5.4)
- ✅ Sentry receives critical alert (Changelog 6.6)

---

### 7.4 Rate Limiting

#### 7.4.1 Login Rate Limit
**Test ID**: `CF-RATE-001`

**Steps**:
1. Attempt login 10 times with wrong password (same IP)
2. Verify rate limit triggered on 11th attempt:
   - Error message: "Too many attempts. Try again later."
   - Sentry event logged

**Expected Results**:
- ✅ `enforceRateLimit()` blocks request (Firestore-backed)
- ✅ `logRateLimitExceeded` called (Changelog 6.6)
- ✅ Block duration: 15 minutes

---

#### 7.4.2 Booking Rate Limit
**Test ID**: `CF-RATE-002`

**Steps**:
1. Attempt multiple rapid bookings from same IP (simulate bot)
2. Verify rate limit:
   - Limit: 10 bookings per 5 minutes
   - Error message: "Too many booking attempts"

**Expected Results**:
- ✅ `checkRateLimit()` blocks (in-memory, fast)
- ✅ Security event logged

---

### 7.5 Sentry Integration

#### 7.5.1 Error Tracking
**Test ID**: `CF-SENTRY-001`

**Steps**:
1. Trigger Cloud Function error (e.g., invalid Firestore path)
2. Check Sentry dashboard: https://sentry.io
3. Verify error captured:
   - Error message
   - Stack trace
   - User context (if authenticated)
   - Breadcrumbs (navigation, network requests)

**Expected Results**:
- ✅ `captureException()` called by `logError()`
- ✅ Error visible in Sentry dashboard within 1 minute
- ✅ User ID attached (if applicable - Changelog 6.8)

---

#### 7.5.2 Security Event Alerts
**Test ID**: `CF-SENTRY-002`

**Steps**:
1. Trigger security event (e.g., webhook signature failure)
2. Check Sentry dashboard
3. Verify alert created:
   - Severity: Critical or High
   - Tagged as security event

**Expected Results**:
- ✅ `captureMessage()` called with `fatal` or `error` level
- ✅ Email/Slack notification sent (if configured)

---

## 8. Cross-Platform Validation

### 8.1 Feature Parity Matrix

**For each major feature, verify works on ALL platforms**:

| Feature | iOS Simulator | Android Device | Chrome Desktop | Safari Desktop | Safari iOS | Chrome Mobile |
|---------|---------------|----------------|----------------|----------------|------------|---------------|
| **Owner Dashboard** |
| Login/Register | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Create Property | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Create Unit | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Timeline Calendar | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Edit Booking | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Analytics | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Stripe Connect | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **Booking Widget** |
| Calendar Display | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Date Selection | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Stripe Payment | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Bank Transfer | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Email Verification | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Confirmation Screen | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| **PWA** |
| Install Prompt | N/A | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Offline Mode | N/A | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

**Legend**:
- ⬜ Not tested
- ✅ Pass
- ❌ Fail
- ⚠️ Warning (works with minor issues)
- N/A Not applicable

---

### 8.2 Platform-Specific Issues Checklist

**iOS Simulator**:
- [ ] Keyboard toolbar "Done" button appears
- [ ] Date picker uses iOS native picker
- [ ] Safari WebView iframe behavior correct
- [ ] Gestures (swipe back) work

**Android Physical Device**:
- [ ] Keyboard dismiss on BACK button (uses fix mixin)
- [ ] Chrome Custom Tabs for Stripe redirect
- [ ] Samsung-specific UI quirks (One UI)
- [ ] Physical keyboard support

**Chrome Desktop**:
- [ ] Responsive breakpoints (resize window)
- [ ] EndDrawer on desktop layout
- [ ] Clipboard API works
- [ ] Browser back/forward navigation

**Safari Desktop**:
- [ ] WebKit rendering differences
- [ ] Date picker compatibility
- [ ] Iframe restrictions (if embedded)

**Safari iOS**:
- [ ] Touch interactions smooth
- [ ] Viewport meta tag behavior
- [ ] Keyboard covering fields (fixed)
- [ ] PWA installation (iOS 16.4+)

**Chrome Mobile Android**:
- [ ] Touch gesture responsiveness
- [ ] PWA installation robust
- [ ] Keyboard behavior (Android-specific)

---

## 9. Bug Tracking & Reporting

### 9.1 Sentry Dashboard Monitoring

**Sentry Project URL**: https://sentry.io/organizations/bookbed/projects/

**Daily Monitoring**:
1. Check "Issues" tab for new errors
2. Filter by:
   - Environment: production (after deploy)
   - Date: Last 24 hours
   - Severity: Error, Fatal

**Key Metrics to Watch**:
- Error rate (errors per minute)
- Affected users count
- Crash-free rate (target: >99.5%)

**Triage Process**:
1. **Critical** (P0): Crashes, payment failures → Fix immediately
2. **High** (P1): Major features broken → Fix within 24h
3. **Medium** (P2): Minor bugs → Fix within 1 week
4. **Low** (P3): UI tweaks, edge cases → Backlog

---

### 9.2 Manual Bug Reporting Template

**Use this template for UI/UX issues not caught by Sentry**:

```markdown
## Bug Report

**Bug ID**: BUG-XXX
**Date**: YYYY-MM-DD
**Reporter**: Your Name
**Severity**: Critical / High / Medium / Low

### Environment
- Platform: iOS / Android / Web
- Device: iPhone 15 Pro Simulator / Samsung Galaxy S23 / Chrome Desktop
- OS Version: iOS 18.1 / Android 14 / macOS 15.1
- Browser: Safari 18.1 / Chrome 131 (if web)
- App Version: Owner Dashboard / Booking Widget

### Steps to Reproduce
1. Navigate to...
2. Click...
3. Enter...
4. Observe...

### Expected Behavior
What should happen...

### Actual Behavior
What actually happens...

### Screenshots/Videos
[Attach if applicable]

### Logs
- Sentry Event ID (if available): XXX
- Console errors (if web): [paste]

### Workaround
If any temporary workaround exists...

### Notes
Additional context...
```

**Example**:
```markdown
## Bug Report

**Bug ID**: BUG-042
**Date**: 2025-12-18
**Reporter**: Duško Ličanin
**Severity**: Medium

### Environment
- Platform: Android
- Device: Samsung Galaxy S23
- OS Version: Android 14
- Browser: Chrome 131
- App Version: Booking Widget

### Steps to Reproduce
1. Open widget in Chrome Mobile
2. Tap email input field
3. Keyboard appears
4. Press Android BACK button to dismiss keyboard
5. Observe white space remains where keyboard was

### Expected Behavior
Layout should recalculate and fill the space.

### Actual Behavior
White space persists at bottom of screen.

### Screenshots/Videos
[Video of keyboard dismiss behavior]

### Logs
- Sentry Event ID: N/A (UI issue)
- Console errors: None

### Workaround
Rotate device to landscape and back to portrait (forces layout recalculation).

### Notes
This is the Changelog 4.9 Android Chrome keyboard bug. Verify fix is applied.
```

---

### 9.3 Bug Tracking Spreadsheet

**Create a Google Sheet** (or use GitHub Issues) with columns:

| Bug ID | Date | Platform | Severity | Feature | Description | Status | Fixed In | Verified | Notes |
|--------|------|----------|----------|---------|-------------|--------|----------|----------|-------|
| BUG-001 | 2025-12-18 | Android | High | Widget Form | Keyboard doesn't dismiss | Fixed | v1.1.0 | ✅ | Applied mixin fix |
| BUG-002 | 2025-12-18 | Safari iOS | Medium | Clipboard | Copy fails in iframe | Fixed | v1.1.0 | ✅ | Added try-catch |

**Status Values**:
- New
- In Progress
- Fixed
- Verified
- Closed
- Wont Fix

---

### 9.4 Regression Testing After Fixes

**After fixing a bug**:
1. Deploy fix to development environment
2. Re-test the exact steps from bug report
3. Verify fix works on all platforms (if cross-platform bug)
4. Check for regressions (did fix break something else?)
5. Update bug status to "Verified"
6. Close bug

---

## 10. Production Readiness Checklist

### 10.1 Pre-Deployment Checklist

**Code Quality**:
- [ ] `flutter analyze` returns 0 issues
- [ ] No `TODO` comments for critical features
- [ ] All debug print statements removed (or commented)
- [ ] No hardcoded API keys in code (use environment variables)

**Testing**:
- [ ] All Owner Dashboard test cases passed on all platforms
- [ ] All Booking Widget test cases passed on all platforms
- [ ] Cloud Functions tested (manual triggers + production simulation)
- [ ] Stripe test mode payments successful
- [ ] Email delivery confirmed (all templates)

**Security**:
- [ ] Firestore security rules deployed and tested
- [ ] Rate limiting active on all endpoints
- [ ] Input sanitization applied (email, phone, text)
- [ ] Price validation enforced (server-side)
- [ ] Webhook signature verification active
- [ ] Sentry monitoring active (errors tracked)

**Performance**:
- [ ] Widget loads in <4s (hybrid progressive loading)
- [ ] Timeline calendar smooth with 100+ bookings
- [ ] No excessive rebuilds (checked with Flutter DevTools)
- [ ] Image optimization (compressed, lazy loaded)

**Accessibility**:
- [ ] Semantic labels on interactive elements
- [ ] Sufficient color contrast (WCAG AA)
- [ ] Keyboard navigation works (tab order logical)
- [ ] Screen reader friendly (TalkBack/VoiceOver tested)

**SEO & Meta Tags** (if applicable):
- [ ] Meta tags configured in `web/index.html`
- [ ] Open Graph tags for social sharing
- [ ] Sitemap.xml generated (for public pages)

**Documentation**:
- [ ] [CLAUDE.md](../CLAUDE.md) updated with latest changes
- [ ] API documentation current (if public API)
- [ ] User guides written (for owner onboarding)

---

### 10.2 Firebase Deployment

**Firestore Indexes**:
```bash
# Verify all indexes deployed
firebase deploy --only firestore:indexes

# Check index status in Firebase Console
# https://console.firebase.google.com/project/bookbed/firestore/indexes
```

**Firestore Security Rules**:
```bash
# Deploy rules
firebase deploy --only firestore:rules

# Test rules with Firebase Emulator
firebase emulators:start --only firestore
# Run test suite against emulator
```

**Cloud Functions**:
```bash
# Deploy all functions
firebase deploy --only functions

# Monitor deployment
firebase functions:log
```

**Hosting**:
```bash
# Build production builds
flutter build web --release --target lib/main.dart -o build/web_owner
flutter build web --release --target lib/widget_main.dart -o build/web_widget

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

**Verify Deployment**:
- [ ] Owner Dashboard: https://app.bookbed.io
- [ ] Booking Widget: https://villa-marija.view.bookbed.io
- [ ] All domains resolve correctly
- [ ] SSL certificates active

---

### 10.3 Monitoring Setup

**Sentry**:
- [ ] Production DSN configured
- [ ] Email alerts enabled for critical errors
- [ ] Slack integration configured (optional)
- [ ] User identification active (`setUser()`)

**Firebase Console**:
- [ ] Cloud Function logs monitored
- [ ] Firestore usage tracked
- [ ] Storage usage tracked
- [ ] Authentication metrics monitored

**Stripe Dashboard**:
- [ ] Webhook endpoint registered
- [ ] Payment success rate monitored
- [ ] Refund requests tracked

**Google Analytics** (if integrated):
- [ ] Tracking ID configured
- [ ] Key events defined (booking completed, payment, etc.)
- [ ] Conversion goals set

---

### 10.4 Rollback Plan

**If critical bug discovered in production**:

1. **Immediate**: Rollback hosting deployment
   ```bash
   # Firebase Hosting maintains previous versions
   # Rollback in Firebase Console → Hosting → Release History
   ```

2. **Cloud Functions**: Redeploy previous version
   ```bash
   # Cloud Functions also version automatically
   # Rollback in Firebase Console → Functions → Version History
   ```

3. **Firestore Rules**: Redeploy previous rules
   ```bash
   # Keep backup of firestore.rules in git history
   git checkout <previous_commit> firestore.rules
   firebase deploy --only firestore:rules
   ```

4. **Communication**:
   - Post status update (if status page exists)
   - Email affected users (if data corruption)
   - Log incident in postmortem doc

---

### 10.5 Post-Production Monitoring (First 48 Hours)

**Hour 1-2** (Critical Window):
- [ ] Monitor Sentry for new errors (check every 15 min)
- [ ] Verify first production booking succeeds (end-to-end test)
- [ ] Check Cloud Function logs for errors
- [ ] Test Stripe webhook delivery

**Hour 2-12**:
- [ ] Monitor error rate (should be <1%)
- [ ] Check user feedback (support emails, social media)
- [ ] Verify email delivery (check spam folder reports)
- [ ] Review Firestore performance metrics

**Day 2**:
- [ ] Full regression test on production
- [ ] Review Sentry issues (triage any new bugs)
- [ ] Analyze user behavior (Google Analytics)
- [ ] Plan hotfix deployment (if needed)

---

### 10.6 Success Criteria

**Production deployment successful if**:
- ✅ Zero critical errors in first 48 hours
- ✅ Crash-free rate >99%
- ✅ First 10 bookings complete successfully
- ✅ Email delivery rate >95%
- ✅ Stripe payment success rate >98%
- ✅ Average widget load time <5s
- ✅ No data corruption or loss
- ✅ No security incidents reported

---

## 11. Test Execution Timeline

**Recommended Schedule** (6-7 days):

### Day 1: Owner Dashboard - Core Features
**Platform**: iOS Simulator + Chrome Desktop

- [ ] Authentication (login, register, password reset)
- [ ] Profile management
- [ ] Property creation/editing
- [ ] Unit wizard (full flow)
- [ ] Basic pricing setup

**Estimated Time**: 6-8 hours

---

### Day 2: Owner Dashboard - Bookings & Calendar
**Platform**: Android Physical Device + Safari Desktop

- [ ] Timeline Calendar (scrolling, booking blocks, conflicts)
- [ ] Bookings list (filtering, search)
- [ ] Create manual booking
- [ ] Edit/cancel bookings
- [ ] Price calendar (seasonal rates, bulk blocking)

**Estimated Time**: 6-8 hours

---

### Day 3: Owner Dashboard - Advanced Features
**Platform**: Web (Chrome + Safari) + Mobile Browsers

- [ ] Widget settings configuration
- [ ] Stripe Connect setup
- [ ] Bank transfer configuration
- [ ] Platform connections (iCal sync)
- [ ] Analytics dashboard
- [ ] Notifications

**Estimated Time**: 6-8 hours

---

### Day 4: Booking Widget - Full Flow
**Platform**: All platforms (prioritize mobile)

- [ ] Widget loading (subdomain, slug routing)
- [ ] Calendar interaction (date selection, status display)
- [ ] Booking form (guest info, validation)
- [ ] Stripe payment flow (test cards)
- [ ] Bank transfer flow
- [ ] Confirmation screen
- [ ] Booking view (guest portal)

**Estimated Time**: 6-8 hours

---

### Day 5: Widget Modes & Edge Cases
**Platform**: Cross-platform validation

- [ ] Calendar-only mode
- [ ] Email verification
- [ ] External bookings display
- [ ] Keyboard dismiss fix (Android)
- [ ] Clipboard API (Safari iframe)
- [ ] PWA installation (all browsers)
- [ ] Responsive design (resize tests)

**Estimated Time**: 6-8 hours

---

### Day 6: Cloud Functions & Integration
**Platform**: Cloud Functions logs + Sentry

- [ ] Email delivery (all templates)
- [ ] Stripe webhook handling
- [ ] Rate limiting
- [ ] Security monitoring
- [ ] Sentry error tracking
- [ ] Cross-tab messaging (Stripe return)

**Estimated Time**: 4-6 hours

---

### Day 7: Regression Testing & Bug Fixes
**Platform**: Prioritize platforms where bugs found

- [ ] Re-test failed test cases
- [ ] Verify all bug fixes
- [ ] Final cross-platform validation
- [ ] Performance testing (load 100+ bookings)
- [ ] Production readiness checklist

**Estimated Time**: 6-8 hours

---

**Total Estimated Time**: 40-54 hours (1-1.5 weeks full-time)

---

## 12. Next Steps After Testing

### 12.1 Bug Triage Meeting

**After completing all tests**:
1. Review all bugs in tracking spreadsheet
2. Prioritize by severity (P0 → P3)
3. Estimate fix time for each bug
4. Create fix plan (which bugs to fix pre-production)

**Decision Criteria**:
- **P0 (Critical)**: MUST fix before production (crashes, payment failures, data loss)
- **P1 (High)**: SHOULD fix before production (major features broken)
- **P2 (Medium)**: CAN fix post-production (minor bugs, workarounds exist)
- **P3 (Low)**: Backlog (UI polish, edge cases)

---

### 12.2 Production Deployment

**Once all P0/P1 bugs fixed**:
1. Final regression test (all fixed bugs)
2. Deploy to production (following checklist in section 10.2)
3. Monitor first 48 hours (section 10.5)
4. Plan hotfix release for P2 bugs

---

### 12.3 User Acceptance Testing (UAT)

**Optional but recommended**:
1. Invite 2-3 beta users (real property owners)
2. Provide test accounts + instructions
3. Collect feedback on UX, clarity, pain points
4. Address critical UX issues before public launch

---

### 12.4 Documentation & Training

**For end users**:
- Create video tutorials (screen recordings)
  - "How to add your first property"
  - "How to configure your booking widget"
  - "How to manage bookings"
- Write FAQ page (common questions)
- Set up support email (support@bookbed.io)

**For developers**:
- Update [CLAUDE.md](../CLAUDE.md) with final changes
- Document known limitations
- Create runbook for common production issues

---

## 13. Appendix

### A. Test Data Seed Script (TODO)

**Create this script to automate test data setup**:

```bash
# scripts/seed_test_data.sh

#!/bin/bash
# BookBed Test Data Seeder
# Usage: ./scripts/seed_test_data.sh

echo "Creating test owner accounts..."
# Use Firebase Auth Admin SDK to create accounts

echo "Creating test properties..."
# Use Firestore Admin SDK to populate data

echo "Creating test bookings..."
# Mix of confirmed, pending, cancelled bookings

echo "Test data seeding complete!"
```

---

### B. Platform Test URLs

**Owner Dashboard**:
- Local: http://localhost:8080
- Development: https://app.bookbed.io (after Firebase deploy)

**Booking Widget**:
- Local: http://localhost:8081
- Development: https://villa-marija.view.bookbed.io

**Cloud Functions**:
- Local (Emulator): http://localhost:5001/bookbed-dev/us-central1/
- Production: https://us-central1-bookbed.cloudfunctions.net/

---

### C. Useful Commands Reference

**Flutter**:
```bash
# Clean build artifacts
flutter clean && flutter pub get

# Run on specific device
flutter devices
flutter run -d <device_id> --target lib/main.dart

# Build production web
flutter build web --release --target lib/main.dart -o build/web_owner

# Analyze code
flutter analyze
```

**Firebase**:
```bash
# Deploy all
firebase deploy

# Deploy specific targets
firebase deploy --only hosting
firebase deploy --only functions
firebase deploy --only firestore:rules,firestore:indexes

# View logs
firebase functions:log
firebase functions:log --only atomicBooking
```

**Git**:
```bash
# Create testing branch
git checkout -b pre-production-testing

# Commit fixes
git add .
git commit -m "fix: Android keyboard dismiss issue (BUG-042)"

# Merge back to main after testing
git checkout main
git merge pre-production-testing
```

---

### D. Contact & Support

**Sentry Dashboard**: https://sentry.io/organizations/bookbed/
**Firebase Console**: https://console.firebase.google.com/project/bookbed
**Stripe Dashboard**: https://dashboard.stripe.com/test

**Documentation**:
- [CLAUDE.md](../CLAUDE.md) - Main project docs
- [CLAUDE_BUGS_ARCHIVE.md](./bugs-archive/CLAUDE_BUGS_ARCHIVE.md) - Historical bug fixes
- [EMAIL_SYSTEM.md](./features/email-templates/EMAIL_SYSTEM.md) - Email templates

---

**Last Updated**: 2025-12-18
**Version**: 1.0
**Next Review**: After Day 7 testing completion

---

**Good luck with testing! 🚀**

Remember:
- Test systematically (follow the day-by-day plan)
- Document everything (screenshots, videos, logs)
- Prioritize critical bugs (payment, bookings, data integrity)
- Don't rush production (better to delay than deploy broken features)
