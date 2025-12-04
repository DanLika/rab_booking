# ULTRA-DEEP ANALYSIS: bookingAccessToken.ts

**Date**: 2025-12-04
**File**: functions/src/bookingAccessToken.ts (140 lines)
**Status**: MEDIUM-SEVERITY ISSUES FOUND

---

## 🚨 CRITICAL ISSUES

### ISSUE #1: Token Length Validation TOO WIDE (Security Risk)
**Location**: Lines 74-81
**Severity**: CRITICAL (Security)

**Problem**:
```typescript
// LINE 20: Comment says 43 characters
// base64url encoding produces 43 characters (32 bytes → 43 chars)
const token = crypto.randomBytes(32).toString("base64url");

// LINE 74-81: But validation allows 16-128 characters! (3x wider!)
if (providedToken.length < 16 || providedToken.length > 128) {
  console.warn("[Security] Token verification failed: invalid token length", {
    length: providedToken.length,
    expectedRange: "16-128", // ❌ WRONG!
  });
  return false;
}
```

**Security Impact**:
- ✅ Our tokens = **exactly 43 characters**
- ❌ We accept tokens = **16 to 128 characters**
- **Range is 3x wider than necessary!**

**Attack Vector**:
1. Attacker crafts **16-character token** (short brute-force attack)
2. Attacker crafts **128-character token** (SQL injection attempt, path traversal)
3. Our validation **ACCEPTS both** even though neither matches our generation logic

**Fix**:
```typescript
// Strict validation: ONLY accept exact length
const EXPECTED_TOKEN_LENGTH = 43; // 32 bytes base64url = 43 chars

if (providedToken.length !== EXPECTED_TOKEN_LENGTH) {
  console.warn("[Security] Token verification failed: invalid token length");
  return false;
}
```

**Why This Matters**:
- Defense in depth: Reject malformed tokens EARLY
- Prevents non-standard tokens from reaching crypto operations
- Reduces attack surface (can't try tokens outside our format)

---

### ISSUE #2: Hardcoded Constants (Not Configurable)
**Location**: Multiple lines
**Severity**: HIGH (Maintainability + Security)

**Problem**:
```typescript
// LINE 21: Token size hardcoded
const token = crypto.randomBytes(32).toString("base64url");

// LINE 37: Expiration period hardcoded
expiration.setDate(expiration.getDate() + 30); // 30 days

// LINE 75: Token length limits hardcoded
if (providedToken.length < 16 || providedToken.length > 128) {

// LINE 84: Hash length hardcoded
if (storedHash.length !== 64 || !/^[0-9a-f]{64}$/i.test(storedHash)) {
```

**Impact**:
- **Not configurable**: Can't change token security without code changes
- **No A/B testing**: Can't test different expiration periods
- **Compliance risk**: Some industries require 60-day retention, not 30
- **Emergency response**: If 32-byte tokens are compromised, can't quickly switch to 64-byte

**Fix**: Extract to centralized constants file:
```typescript
// security/tokenConfig.ts
export const TOKEN_CONFIG = {
  // Token generation
  TOKEN_BYTES: 32,              // 256-bit entropy
  TOKEN_ENCODING: "base64url",  // URL-safe, no padding
  EXPECTED_TOKEN_LENGTH: 43,    // 32 bytes → 43 chars in base64url

  // Token expiration
  EXPIRATION_DAYS: 30,          // Days after checkout

  // Validation
  HASH_ALGORITHM: "sha256",     // SHA-256
  HASH_LENGTH: 64,              // 64 hex characters
  HASH_REGEX: /^[0-9a-f]{64}$/i,

  // Security
  MIN_TOKEN_LENGTH: 43,         // Reject shorter tokens
  MAX_TOKEN_LENGTH: 43,         // Reject longer tokens
} as const;
```

---

## ⚠️ HIGH PRIORITY ISSUES

### ISSUE #3: No base64url Format Validation (Input Validation Gap)
**Location**: Lines 74-81 (token validation)
**Severity**: HIGH (Security)

**Problem**:
We validate token **LENGTH** but NOT token **FORMAT**:
```typescript
// LINE 74-81: Only checks length
if (providedToken.length < 16 || providedToken.length > 128) {
  return false;
}

// MISSING: base64url format check!
// base64url = [A-Za-z0-9_-]+ (no padding)
```

**Attack Vector**:
1. Attacker sends token with **invalid characters**: `"abc!@#$%^&*()"`
2. Our validation **PASSES** (length is 16-128)
3. Token reaches `crypto.createHash()` (line 98-101)
4. Crypto operation **SUCCEEDS** (can hash any string)
5. Hash comparison **FAILS** (wrong hash)
6. **Result**: Wasted CPU cycles on invalid tokens

**Why This Matters**:
- **DoS risk**: Attacker floods with invalid tokens → CPU exhaustion
- **Timing leaks**: Invalid tokens take different time to process
- **Log pollution**: Every invalid token generates warning log

**Fix**:
```typescript
// Validate base64url format (BEFORE length check)
const BASE64URL_REGEX = /^[A-Za-z0-9_-]+$/;
if (!BASE64URL_REGEX.test(providedToken)) {
  console.warn("[Security] Token verification failed: invalid format");
  return false;
}
```

---

### ISSUE #4: Token Length Leak Through Timing Attack
**Location**: Lines 74-81
**Severity**: HIGH (Security)

**Problem**:
```typescript
// LINE 74-81: Length check is NOT constant-time
if (providedToken.length < 16 || providedToken.length > 128) {
  console.warn("[Security] Token verification failed: invalid token length", {
    length: providedToken.length, // ❌ LEAKS LENGTH!
    expectedRange: "16-128",
  });
  return false;
}

// LINE 115-118: Hash comparison IS constant-time ✅
const result = crypto.timingSafeEqual(
  Buffer.from(hashedProvidedToken, "hex"),
  Buffer.from(storedHash, "hex")
);
```

**Timing Attack**:
1. Attacker measures response time for different token lengths
2. **Short tokens** (15 chars): Rejected FAST (early return)
3. **Valid tokens** (43 chars): Processed SLOW (hash + comparison)
4. **Long tokens** (129 chars): Rejected FAST (early return)
5. **Result**: Attacker learns valid token length = **43 characters**

**Why This Matters**:
- Reduces brute-force search space from `[A-Za-z0-9_-]{16-128}` to `[A-Za-z0-9_-]{43}`
- Search space reduction: `64^128` → `64^43` (massive improvement for attacker)

**Fix**: Constant-time length check:
```typescript
// Use constant-time comparison for length
const isValidLength = providedToken.length === EXPECTED_TOKEN_LENGTH;
if (!isValidLength) {
  // Don't log actual length (information leak)
  console.warn("[Security] Token verification failed: invalid token");
  return false;
}
```

---

### ISSUE #5: Error Messages Too Verbose (Information Disclosure)
**Location**: Lines 76-79, 86-89, 122-125
**Severity**: MEDIUM (Security)

**Problem**:
```typescript
// LINE 76-79: Leaks actual token length
console.warn("[Security] Token verification failed: invalid token length", {
  length: providedToken.length,       // ❌ LEAKS LENGTH
  expectedRange: "16-128",            // ❌ LEAKS VALID RANGE
});

// LINE 86-89: Leaks hash details
console.warn("[Security] Token verification failed: invalid hash format", {
  hashLength: storedHash.length,      // ❌ LEAKS HASH LENGTH
  expectedLength: 64,                 // ❌ LEAKS EXPECTED LENGTH
  isValidHex: /^[0-9a-f]+$/i.test(storedHash), // ❌ LEAKS FORMAT
});

// LINE 122-125: Leaks token length AGAIN
console.warn("[Security] Token verification failed: hash mismatch", {
  providedTokenLength: providedToken.length, // ❌ LEAKS LENGTH
  timestamp: new Date().toISOString(),
});
```

**Security Best Practice**:
- **Vague error messages** prevent attackers from learning system internals
- **Don't leak**: token length, expected formats, validation logic
- **Only log**: failure event (for audit trail)

**Fix**:
```typescript
// Generic error message (no details)
console.warn("[Security] Token verification failed", {
  timestamp: new Date().toISOString(),
  // NO providedTokenLength, hashLength, expectedRange, etc.
});
```

---

### ISSUE #6: Expiration Calculation Doesn't Handle Past Dates
**Location**: Lines 32-40
**Severity**: MEDIUM (Edge Case)

**Problem**:
```typescript
// LINE 32-40: Assumes checkout date is in FUTURE
export function calculateTokenExpiration(
  checkOutDate: admin.firestore.Timestamp
): admin.firestore.Timestamp {
  const checkOut = checkOutDate.toDate();
  const expiration = new Date(checkOut);
  expiration.setDate(expiration.getDate() + 30); // checkout + 30 days

  return admin.firestore.Timestamp.fromDate(expiration);
}
```

**Edge Case**:
1. Old booking from 2023 (checkout = 2023-06-01)
2. Token expiration = 2023-07-01 (checkout + 30 days)
3. **Current date** = 2025-12-04
4. **Token is expired!** (2023-07-01 < 2025-12-04)
5. Guest can't access booking details via email link

**When This Happens**:
- Guest receives email in 2023
- Guest opens email in 2025 (2 years later)
- Token is expired → "Access denied"
- **Poor UX**: Guest can't review old booking

**Fix Options**:
```typescript
// Option A: Extend expired tokens
const now = new Date();
const checkOut = checkOutDate.toDate();
const expiration = new Date(Math.max(checkOut.getTime(), now.getTime()));
expiration.setDate(expiration.getDate() + 30);

// Option B: Never expire tokens (if booking exists, allow access)
// Remove expiration check entirely

// Option C: Longer expiration for old bookings
const isOldBooking = checkOut < now;
const expirationDays = isOldBooking ? 3650 : 30; // 10 years for old bookings
```

---

## 📊 MEDIUM PRIORITY ISSUES

### ISSUE #7: No Integration with Rate Limiting
**Location**: Lines 54-139 (verifyAccessToken function)
**Severity**: MEDIUM (Security)

**Problem**:
`verifyAccessToken()` has **NO rate limiting**:
```typescript
// LINE 54-57: No rate limiting check
export function verifyAccessToken(
  providedToken: string | null | undefined,
  storedHash: string | null | undefined
): boolean {
  // No rate limiting here!
  // Attacker can call this 1000x/second
}
```

**Brute-Force Attack**:
1. Attacker guesses tokens: `aaaaa...`, `aaaab...`, `aaaac...`
2. Each guess calls `verifyAccessToken()`
3. **No rate limiting** → attacker can try millions of tokens
4. Eventually finds valid token (if entropy is weak)

**Fix**: Integrate with rate limiting:
```typescript
import {checkRateLimit} from "./utils/rateLimit";

export function verifyAccessToken(
  providedToken: string | null | undefined,
  storedHash: string | null | undefined,
  clientIp?: string // NEW: IP for rate limiting
): boolean {
  // Rate limiting check (BEFORE validation)
  if (clientIp && !checkRateLimit(`token_verify:${clientIp}`, 10, 60)) {
    console.warn("[Security] Token verification rate limit exceeded", {clientIp});
    return false;
  }

  // Rest of validation...
}
```

---

### ISSUE #8: Try-Catch Block is Unreachable
**Location**: Lines 102-109
**Severity**: LOW (Dead Code)

**Problem**:
```typescript
// LINE 96-109: This try-catch should NEVER trigger
try {
  hashedProvidedToken = crypto
    .createHash("sha256")
    .update(providedToken) // providedToken is validated string
    .digest("hex");
} catch (error) {
  // This should never happen with valid strings, but catch just in case
  console.error("[Security] Token hashing failed", {
    error: error instanceof Error ? error.message : "Unknown error",
    providedTokenLength: providedToken.length,
  });
  return false;
}
```

**Why Unreachable**:
- Line 63-66: `providedToken` is validated as non-empty string
- Line 74-81: `providedToken` length is validated
- `crypto.createHash().update()` **NEVER throws** for valid strings
- **Dead code**: Catch block is unreachable

**Fix Options**:
```typescript
// Option A: Remove try-catch (it's unreachable)
const hashedProvidedToken = crypto
  .createHash("sha256")
  .update(providedToken)
  .digest("hex");

// Option B: Keep as defensive programming (paranoid safety net)
// Current code is OK, just document that it's unreachable
```

---

### ISSUE #9: Magic Numbers Scattered in Code
**Location**: Lines 21, 37, 75, 84
**Severity**: LOW (Code Quality)

**Problem**:
```typescript
// LINE 21: 32 (token bytes)
const token = crypto.randomBytes(32).toString("base64url");

// LINE 37: 30 (expiration days)
expiration.setDate(expiration.getDate() + 30);

// LINE 75: 16, 128 (token length limits)
if (providedToken.length < 16 || providedToken.length > 128) {

// LINE 84: 64 (hash length)
if (storedHash.length !== 64 || !/^[0-9a-f]{64}$/i.test(storedHash)) {
```

**Impact**:
- **Magic numbers**: Hard to understand what `32`, `30`, `64` mean
- **No single source of truth**: Change `32` to `64` → must update 3+ places
- **Hard to test**: Can't easily mock constants

**Fix**: Extract to named constants:
```typescript
// At top of file
const TOKEN_BYTES = 32;              // 256-bit entropy
const TOKEN_LENGTH = 43;             // base64url(32 bytes) = 43 chars
const EXPIRATION_DAYS = 30;          // Days after checkout
const SHA256_HEX_LENGTH = 64;        // SHA-256 hash in hex

// Use constants
const token = crypto.randomBytes(TOKEN_BYTES).toString("base64url");
expiration.setDate(expiration.getDate() + EXPIRATION_DAYS);
if (providedToken.length !== TOKEN_LENGTH) { ... }
if (storedHash.length !== SHA256_HEX_LENGTH) { ... }
```

---

## 📋 SUMMARY OF ISSUES

| Issue | Severity | Type | Lines | Fix Complexity |
|-------|----------|------|-------|----------------|
| #1 Token length validation too wide | CRITICAL | Security | 74-81 | EASY (change 16-128 → 43) |
| #2 Hardcoded constants | HIGH | Maintainability | Multiple | EASY (extract constants) |
| #3 No base64url format validation | HIGH | Security | 74-81 | EASY (add regex check) |
| #4 Token length timing leak | HIGH | Security | 74-81 | MEDIUM (constant-time check) |
| #5 Error messages too verbose | MEDIUM | Security | Multiple | EASY (remove details) |
| #6 Expiration doesn't handle past dates | MEDIUM | Edge Case | 32-40 | MEDIUM (add date logic) |
| #7 No rate limiting integration | MEDIUM | Security | 54-139 | MEDIUM (add rate limit) |
| #8 Unreachable try-catch | LOW | Dead Code | 102-109 | EASY (remove or document) |
| #9 Magic numbers scattered | LOW | Code Quality | Multiple | EASY (extract constants) |

**TOTAL**: 9 issues (1 CRITICAL, 3 HIGH, 3 MEDIUM, 2 LOW)

---

## 🎯 RECOMMENDED FIX ORDER

### Phase 1: Quick Security Wins (30 min)
1. **ISSUE #1** (Token length validation) - Change `16-128` → `43`
2. **ISSUE #3** (Base64url validation) - Add regex check
3. **ISSUE #5** (Verbose error messages) - Remove leaked details
4. **ISSUE #9** (Magic numbers) - Extract constants

### Phase 2: Medium Complexity (1-2 hours)
5. **ISSUE #2** (Hardcoded constants) - Create tokenConfig.ts
6. **ISSUE #4** (Timing leak) - Constant-time length check
7. **ISSUE #6** (Expiration edge case) - Handle past dates

### Phase 3: Integration (2-3 hours)
8. **ISSUE #7** (Rate limiting) - Integrate with rateLimit.ts
9. **ISSUE #8** (Dead code) - Remove unreachable catch block

---

## 🔒 SECURITY IMPROVEMENTS SUMMARY

**Current State**:
- ❌ Accepts tokens 16-128 chars (3x wider than needed)
- ❌ No format validation (accepts non-base64url chars)
- ❌ Length check leaks timing information
- ❌ Error messages leak token/hash details
- ❌ No rate limiting (brute-force attack risk)

**After Fixes**:
- ✅ Accepts ONLY 43-char tokens (exact match)
- ✅ Validates base64url format ([A-Za-z0-9_-]+)
- ✅ Constant-time length validation
- ✅ Vague error messages (no information leak)
- ✅ Rate limiting integration (10 attempts/min)

---

## 📝 CODE QUALITY IMPROVEMENTS

**Current State**:
- ❌ Magic numbers scattered (32, 30, 16, 128, 64)
- ❌ Constants not configurable (hard to test)
- ❌ Unreachable catch block (dead code)

**After Fixes**:
- ✅ Named constants (TOKEN_BYTES, EXPIRATION_DAYS, etc.)
- ✅ Centralized config (tokenConfig.ts)
- ✅ Cleaned up dead code

---

**Analysis completed**: 2025-12-04 17:30 UTC
**Estimated fix time**: 4-6 hours total
**Risk level**: LOW (changes are isolated to 1 file)
**Breaking changes**: NONE (API stays the same)
