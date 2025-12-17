import * as crypto from "crypto";
import {admin} from "./firebase";
import {checkRateLimit} from "./utils/rateLimit";
import {logWarn, logError} from "./logger";

/**
 * Token Configuration
 * Used for generating secure access tokens for booking lookup
 */
// Token generation constants
const TOKEN_BYTES = 32; // 256 bits of entropy
const TOKEN_ENCODING = "base64url" as const; // URL-safe, no padding
const HASH_ALGORITHM = "sha256" as const; // SHA-256 for storage

// Token expiration constants
const EXPIRATION_DAYS = 30; // Standard expiration after checkout
const EXTENDED_EXPIRATION_DAYS = 3650; // 10 years for old bookings

// Token validation constants
const EXPECTED_TOKEN_LENGTH = 43; // 32 bytes base64url = 43 chars (EXACT)
const HASH_LENGTH = 64; // SHA-256 = 64 hex chars
const BASE64URL_REGEX = /^[A-Za-z0-9_-]+$/; // base64url charset
const HASH_REGEX = /^[0-9a-f]{64}$/i; // 64 hex chars

/**
 * Generate a secure access token for booking lookup
 * Token is a random 32-byte (256-bit) string that is hashed before storage
 *
 * SECURITY:
 * - 32 bytes = 256 bits of entropy (cryptographically secure)
 * - base64url encoding = URL-safe, no padding
 * - SHA-256 hashing for storage (prevents token leakage from DB)
 *
 * @returns Object with plaintext token (for email) and hashed token (for DB)
 */
export function generateBookingAccessToken(): {
  token: string;
  hashedToken: string;
} {
  // Generate random token using configured entropy
  // base64url encoding produces 43 characters (32 bytes → 43 chars)
  const token = crypto
    .randomBytes(TOKEN_BYTES)
    .toString(TOKEN_ENCODING);

  // Hash token for secure storage
  const hashedToken = crypto
    .createHash(HASH_ALGORITHM)
    .update(token)
    .digest("hex");

  return {token, hashedToken};
}

/**
 * Calculate token expiration date
 *
 * EXPIRATION RULES:
 * - Future bookings: checkout + 30 days (standard)
 * - Past bookings: checkout + 10 years (extended access for historical records)
 *
 * This ensures guests can access old booking confirmations even years later
 *
 * @param checkOutDate - Can be Date or Firestore Timestamp
 */
export function calculateTokenExpiration(
  checkOutDate: Date | admin.firestore.Timestamp
): admin.firestore.Timestamp {
  const now = new Date();

  // Handle both Date and Timestamp inputs
  let checkOut: Date;
  if (checkOutDate instanceof Date) {
    checkOut = checkOutDate;
  } else if (typeof (checkOutDate as any).toDate === "function") {
    checkOut = (checkOutDate as admin.firestore.Timestamp).toDate();
  } else {
    // Fallback: try to parse as date
    checkOut = new Date(checkOutDate as any);
  }

  // Determine if this is an old booking (checkout already passed)
  const isOldBooking = checkOut < now;

  // Use extended expiration for old bookings to allow historical access
  const expirationDays = isOldBooking ?
    EXTENDED_EXPIRATION_DAYS :
    EXPIRATION_DAYS;

  const expiration = new Date(checkOut);
  expiration.setDate(expiration.getDate() + expirationDays);

  return admin.firestore.Timestamp.fromDate(expiration);
}

/**
 * Verify if access token matches stored hash
 *
 * SECURITY:
 * - Rate limiting prevents brute-force attacks (10 attempts/min per IP)
 * - Input validation prevents invalid data from reaching crypto operations
 * - Format validation rejects malformed tokens early
 * - Constant-time comparison prevents timing attacks
 * - Minimal logging to prevent information leakage
 *
 * @param providedToken - Token from user (plaintext from URL/email)
 * @param storedHash - SHA-256 hash from database
 * @param clientIp - Client IP address for rate limiting (optional)
 * @returns true if token matches hash, false otherwise
 */
export function verifyAccessToken(
  providedToken: string | null | undefined,
  storedHash: string | null | undefined,
  clientIp?: string
): boolean {
  // ========================================================================
  // STEP 0: RATE LIMITING (prevent brute-force attacks)
  // ========================================================================
  if (clientIp && !checkRateLimit(`token_verify:${clientIp}`, 10, 60)) {
    logWarn("[Security] Token verification rate limit exceeded");
    return false;
  }

  // ========================================================================
  // STEP 1: VALIDATE INPUT PARAMETERS
  // ========================================================================

  // Check: Is providedToken valid?
  if (!providedToken || typeof providedToken !== "string") {
    logWarn("[Security] Token verification failed");
    return false;
  }

  // Check: Is storedHash valid?
  if (!storedHash || typeof storedHash !== "string") {
    logWarn("[Security] Token verification failed");
    return false;
  }

  // ========================================================================
  // STEP 2: VALIDATE TOKEN FORMAT (base64url characters only)
  // ========================================================================
  if (!BASE64URL_REGEX.test(providedToken)) {
    logWarn("[Security] Token verification failed");
    return false;
  }

  // ========================================================================
  // STEP 3: VALIDATE TOKEN LENGTH (exact match, prevents timing leak)
  // ========================================================================
  // SECURITY: Use strict equality (43 chars ONLY) to reject malformed tokens
  // This prevents timing attacks - all invalid lengths fail at same point
  if (providedToken.length !== EXPECTED_TOKEN_LENGTH) {
    logWarn("[Security] Token verification failed");
    return false;
  }

  // ========================================================================
  // STEP 4: VALIDATE HASH FORMAT
  // ========================================================================
  // SHA-256 hash must be exactly 64 hexadecimal characters
  if (storedHash.length !== HASH_LENGTH || !HASH_REGEX.test(storedHash)) {
    logWarn("[Security] Token verification failed");
    return false;
  }

  // ========================================================================
  // STEP 5: HASH PROVIDED TOKEN
  // ========================================================================
  // After validation, this cannot fail (validated string input)
  // No try-catch needed - unreachable error path removed
  const hashedProvidedToken = crypto
    .createHash(HASH_ALGORITHM)
    .update(providedToken)
    .digest("hex");

  // ========================================================================
  // STEP 6: CONSTANT-TIME COMPARISON (prevents timing attacks)
  // ========================================================================
  try {
    const result = crypto.timingSafeEqual(
      Buffer.from(hashedProvidedToken, "hex"),
      Buffer.from(storedHash, "hex")
    );

    // Log failures only (minimal information for audit trail)
    if (!result) {
      logWarn("[Security] Token verification failed (hash mismatch)");
    }

    return result;
  } catch (error) {
    // This should be unreachable after validation (hash lengths are validated)
    // Keep as final safety net
    logError("[Security] Token comparison error", error);
    return false;
  }
}
