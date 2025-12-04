import * as crypto from "crypto";
import {admin} from "./firebase";

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
  // Generate random 32-byte token (256 bits of entropy)
  // base64url encoding produces 43 characters (32 bytes → 43 chars)
  const token = crypto.randomBytes(32).toString("base64url");

  // Hash token for secure storage (SHA-256)
  const hashedToken = crypto.createHash("sha256").update(token).digest("hex");

  return {token, hashedToken};
}

/**
 * Calculate token expiration date (checkout date + 30 days)
 */
export function calculateTokenExpiration(
  checkOutDate: admin.firestore.Timestamp
): admin.firestore.Timestamp {
  const checkOut = checkOutDate.toDate();
  const expiration = new Date(checkOut);
  expiration.setDate(expiration.getDate() + 30); // 30 days after checkout

  return admin.firestore.Timestamp.fromDate(expiration);
}

/**
 * Verify if access token matches stored hash
 *
 * SECURITY:
 * - Input validation prevents invalid data from reaching crypto operations
 * - Constant-time comparison prevents timing attacks
 * - Detailed logging for security audit trail (failures only)
 *
 * @param providedToken - Token from user (plaintext from URL/email)
 * @param storedHash - SHA-256 hash from database
 * @returns true if token matches hash, false otherwise
 */
export function verifyAccessToken(
  providedToken: string | null | undefined,
  storedHash: string | null | undefined
): boolean {
  // ========================================================================
  // STEP 1: VALIDATE INPUT PARAMETERS
  // ========================================================================

  // Check: Is providedToken valid?
  if (!providedToken || typeof providedToken !== "string") {
    console.warn("[Security] Token verification failed: invalid providedToken (empty or not string)");
    return false;
  }

  // Check: Is storedHash valid?
  if (!storedHash || typeof storedHash !== "string") {
    console.warn("[Security] Token verification failed: invalid storedHash (empty or not string)");
    return false;
  }

  // Check: Token length (base64url: 16-64 characters is reasonable)
  if (providedToken.length < 16 || providedToken.length > 128) {
    console.warn("[Security] Token verification failed: invalid token length", {
      length: providedToken.length,
      expectedRange: "16-128",
    });
    return false;
  }

  // Check: Is storedHash valid hex string? (SHA-256 = exactly 64 hex chars)
  if (storedHash.length !== 64 || !/^[0-9a-f]{64}$/i.test(storedHash)) {
    console.warn("[Security] Token verification failed: invalid hash format", {
      hashLength: storedHash.length,
      expectedLength: 64,
      isValidHex: /^[0-9a-f]+$/i.test(storedHash),
    });
    return false;
  }

  // ========================================================================
  // STEP 2: HASH PROVIDED TOKEN
  // ========================================================================
  let hashedProvidedToken: string;
  try {
    hashedProvidedToken = crypto
      .createHash("sha256")
      .update(providedToken)
      .digest("hex");
  } catch (error) {
    // This should never happen with valid strings, but catch just in case
    console.error("[Security] Token hashing failed", {
      error: error instanceof Error ? error.message : "Unknown error",
      providedTokenLength: providedToken.length,
    });
    return false;
  }

  // ========================================================================
  // STEP 3: CONSTANT-TIME COMPARISON (prevents timing attacks)
  // ========================================================================
  try {
    const result = crypto.timingSafeEqual(
      Buffer.from(hashedProvidedToken, "hex"),
      Buffer.from(storedHash, "hex")
    );

    // Log ONLY failures for security audit (success is expected, no need to log)
    if (!result) {
      console.warn("[Security] Token verification failed: hash mismatch", {
        providedTokenLength: providedToken.length,
        timestamp: new Date().toISOString(),
      });
    }

    return result;
  } catch (error) {
    // This catch should be unreachable now (we validated lengths above)
    // but keep it as final safety net
    console.error("[Security] Token comparison error", {
      error: error instanceof Error ? error.message : "Unknown error",
      hashedTokenLength: hashedProvidedToken.length,
      storedHashLength: storedHash.length,
    });
    return false;
  }
}
