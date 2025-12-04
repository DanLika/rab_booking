# Email Verification Pre-Check & Safety Check - Test Plan

**Datum**: 2025-12-04
**Feature**: OPCIJA B Implementation - checkEmailVerificationStatus integration

---

## ✅ AUTOMATED TESTS - PASS

| Test | Status | Details |
|------|--------|---------|
| Flutter Compilation | ✅ PASS | `flutter analyze` - No issues found |
| TypeScript Build | ✅ PASS | `npm run build` - Compiled successfully |
| Build Output | ✅ PASS | emailVerification.js (11K) generated |
| Import Paths | ✅ PASS | EmailVerificationService imported correctly |
| Service Usage | ✅ PASS | Used in 2 places (_openVerificationDialog, _validateEmailVerificationBeforeBooking) |
| Dependencies | ✅ PASS | cloud_functions: ^5.2.2 available |
| Functions Export | ✅ PASS | emailVerification module exported in index.ts |

**Conclusion**: Code compiles and builds successfully. Ready for manual testing.

---

## 🧪 MANUAL TEST PLAN

### Prerequisites

1. **Deploy Functions First**:
   ```bash
   cd functions
   firebase deploy --only functions:sendEmailVerificationCode,functions:verifyEmailCode,functions:checkEmailVerificationStatus
   ```

2. **Run Flutter Widget**:
   ```bash
   flutter run -d chrome --web-port 5000
   ```

3. **Enable Email Verification** in widget settings:
   - Firestore: `properties/{propertyId}/widget_settings/{unitId}`
   - Set: `emailConfig.requireEmailVerification = true`

---

## TEST CASE 1: Pre-Check Happy Path ✅

**Goal**: Verify that pre-check skips dialog when email is already verified

**Steps**:
1. Open booking widget
2. Select dates (check-in/check-out)
3. Fill guest form
4. Enter email: `test@example.com`
5. Click **"Verify"** button
6. Enter 6-digit code from email
7. **Wait 2-3 minutes** (don't close browser!)
8. Click **"Verify"** button again

**Expected Result**:
- ✅ Dialog does NOT open
- ✅ Success message appears: **"Email already verified ✓ (valid for ~27 min)"**
- ✅ Green checkmark icon appears next to email field
- ✅ No new verification email sent

**Logs to Check** (browser console):
```
[BookingWidget] Pre-checking email verification status
[EmailVerificationService] Status: verified=true, expired=false, remaining=27min
[BookingWidget] Email already verified (expires in 27min)
```

**Status**: 🟡 PENDING

---

## TEST CASE 2: Verification Expired During Booking ⚠️

**Goal**: Verify that safety check blocks booking when verification expires

**Setup for Testing** (TEMPORARY):
```typescript
// functions/src/emailVerification.ts:10
const VERIFICATION_TTL_MINUTES = 1; // Change to 1 minute for testing
```

**Steps**:
1. Deploy functions with TTL = 1 minute
2. Open booking widget
3. Fill guest form and verify email
4. ✅ Wait 2 minutes (verification should expire)
5. Try to click **"Confirm Booking"**

**Expected Result**:
- ❌ Booking is BLOCKED
- ❌ Error message appears: **"Email verification expired. Please verify again before booking."**
- ❌ Green checkmark icon disappears
- ❌ `_emailVerified` state resets to `false`

**Logs to Check** (browser console):
```
[BookingWidget] Final email verification check before booking
[EmailVerificationService] Status: verified=true, expired=true, remaining=0min
[BookingWidget] Email verification expired during booking flow
```

**IMPORTANT**: ⚠️ Restore TTL after testing:
```typescript
const VERIFICATION_TTL_MINUTES = 30; // Restore to 30 minutes
```

**Status**: 🟡 PENDING

---

## TEST CASE 3: Network Failure Fallback 🔌

**Goal**: Verify graceful fallback when pre-check fails

**Steps**:
1. Open booking widget
2. Fill guest form
3. **Disconnect internet** (turn off WiFi)
4. Try to click **"Verify"** button
5. **Reconnect internet** after dialog opens
6. Enter code and verify

**Expected Result**:
- ⚠️ Pre-check fails silently (network error)
- ✅ Dialog opens normally (fallback behavior)
- ✅ User can send code and verify after reconnecting
- ✅ No crash or UI freeze

**Logs to Check** (browser console):
```
[BookingWidget] Pre-checking email verification status
[BookingWidget] Pre-check failed, showing dialog anyway: <network error>
```

**Status**: 🟡 PENDING

---

## TEST CASE 4: Pre-Check for Expired Verification 🔄

**Goal**: Verify that pre-check detects expired verification

**Setup**: Use TEST CASE 2 setup (TTL = 1 minute)

**Steps**:
1. Verify email
2. Wait 2 minutes (verification expires)
3. Click **"Verify"** button again

**Expected Result**:
- ⚠️ Pre-check detects `status.expired = true`
- ✅ Dialog opens (because verification expired)
- ✅ New code is sent
- ✅ Log shows: "Verification expired, sending new code"

**Logs to Check**:
```
[BookingWidget] Pre-checking email verification status
[EmailVerificationService] Status: verified=true, expired=true, remaining=0min
[BookingWidget] Verification expired, sending new code
```

**Status**: 🟡 PENDING

---

## TEST CASE 5: Session Tracking (Informative) 🔍

**Goal**: Verify that backend stores session tracking data

**Steps**:
1. Verify email from Browser A
2. Check Firestore document: `email_verifications/{emailHash}`

**Expected Firestore Document**:
```json
{
  "code": "123456",
  "email": "test@example.com",
  "expiresAt": "2025-12-04T13:15:00Z",
  "verified": true,
  "verifiedAt": "2025-12-04T12:45:00Z",
  "sessionId": "abc123...",  // ✨ NEW
  "deviceFingerprint": {     // ✨ NEW
    "userAgent": "Mozilla/5.0...",
    "ipAddress": "192.168.1.100"
  }
}
```

**Expected Result**:
- ✅ `sessionId` field exists (64-char hex string)
- ✅ `deviceFingerprint.userAgent` contains browser info
- ✅ `deviceFingerprint.ipAddress` contains IP address

**Note**: Session tracking is **informative only** - we don't enforce cross-device restrictions yet.

**Status**: 🟡 PENDING

---

## TEST CASE 6: Safety Check on Valid Verification ✅

**Goal**: Verify that safety check allows booking when verification is valid

**Steps**:
1. Verify email (fresh verification)
2. Immediately click **"Confirm Booking"** (within 1 minute)

**Expected Result**:
- ✅ Safety check passes
- ✅ Booking proceeds normally
- ✅ No error messages
- ✅ Confirmation screen appears

**Logs to Check**:
```
[BookingWidget] Final email verification check before booking
[EmailVerificationService] Status: verified=true, expired=false, remaining=29min
[BookingWidget] Email verification valid (29min remaining)
```

**Status**: 🟡 PENDING

---

## TEST CASE 7: Multiple Browser Tabs (Session Isolation) 📑

**Goal**: Verify that verification is shared across tabs (same email hash)

**Steps**:
1. **Tab A**: Open booking widget, verify email
2. **Tab B**: Open same booking widget (same unit), enter SAME email
3. **Tab B**: Click **"Verify"** button

**Expected Result**:
- ✅ Tab B detects verification from Tab A
- ✅ Tab B shows: "Email already verified ✓"
- ✅ Both tabs share same `email_verifications/{emailHash}` document

**Note**: This is expected behavior - verification is tied to EMAIL, not SESSION.

**Status**: 🟡 PENDING

---

## TEST CASE 8: Verify Button Disabled Logic (Edge Case) 🚫

**Goal**: Verify that safety check handles unexpected state

**Steps**:
1. Verify email normally
2. **Manually** clear localStorage (Chrome DevTools → Application → Local Storage → Clear)
3. Refresh page
4. Try to click **"Confirm Booking"** (button should be disabled, but test safety net)

**Expected Result**:
- 🛡️ Safety check catches `_emailVerified = false` state
- ❌ Error: "Please verify your email before booking"
- ❌ Booking is blocked

**Note**: This tests the safety net for race conditions or manual state manipulation.

**Status**: 🟡 PENDING

---

## 🐛 EDGE CASES TO WATCH

### Edge Case 1: Clock Skew
**Scenario**: User's device clock is 10 minutes ahead
**Expected**: Backend uses server time, so client time doesn't matter
**Risk**: ⚠️ LOW

### Edge Case 2: Multiple Verifications
**Scenario**: User verifies email, then requests new code before expiry
**Expected**: New code replaces old one, verification resets to `false`
**Risk**: ✅ HANDLED (by design)

### Edge Case 3: Concurrent Requests
**Scenario**: User clicks "Verify" twice rapidly
**Expected**: Rate limiting (60s cooldown) prevents duplicate emails
**Risk**: ✅ HANDLED (backend rate limiting)

---

## 📊 TEST RESULTS SUMMARY

| Test Case | Status | Notes |
|-----------|--------|-------|
| TC1: Pre-Check Happy Path | 🟡 PENDING | - |
| TC2: Expired During Booking | 🟡 PENDING | Requires TTL=1min setup |
| TC3: Network Failure Fallback | 🟡 PENDING | - |
| TC4: Pre-Check Expired | 🟡 PENDING | Requires TTL=1min setup |
| TC5: Session Tracking | 🟡 PENDING | Check Firestore manually |
| TC6: Safety Check Valid | 🟡 PENDING | - |
| TC7: Multiple Tabs | 🟡 PENDING | - |
| TC8: Disabled Button Safety | 🟡 PENDING | Manual state manipulation |

---

## 🚀 DEPLOYMENT CHECKLIST (After Testing)

- [ ] All test cases pass
- [ ] Restore `VERIFICATION_TTL_MINUTES = 30` (if changed for testing)
- [ ] Deploy Functions: `firebase deploy --only functions`
- [ ] Deploy Flutter: `firebase deploy --only hosting:web_widget`
- [ ] Monitor logs for first 24h: `firebase functions:log`
- [ ] Update CLAUDE.md with new feature notes

---

## 📞 REPORT TEMPLATE

After testing, fill this out:

```
TEST RESULTS - Email Verification Pre-Check (OPCIJA B)

Tester: [Your Name]
Date: [Test Date]
Environment: [Production/Staging/Local]

PASSED: [X/8] test cases
FAILED: [X/8] test cases

FAILURES:
- TC#: [Description]
  Issue: [What went wrong]
  Logs: [Relevant console/Firebase logs]

NOTES:
[Any additional observations]
```

---

**Last Updated**: 2025-12-04
