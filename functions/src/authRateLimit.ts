/**
 * Authentication Rate Limiting
 *
 * Provides IP-based rate limiting for login attempts to prevent distributed attacks.
 * Works alongside existing email-based rate limiting in Dart code.
 *
 * Defense in depth:
 * - Email-based rate limiting (Dart): Prevents brute force on single account
 * - IP-based rate limiting (Cloud Function): Prevents distributed attacks from single IP
 *
 * @module authRateLimit
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {checkRateLimit} from "./utils/rateLimit";
import {logRateLimitExceeded} from "./utils/securityMonitoring";
import {logInfo, logWarn, logError} from "./logger";
import {admin, db} from "./firebase";

/**
 * Rate limit configuration for login attempts
 */
const LOGIN_RATE_LIMIT = {
  maxCalls: 15, // 15 login attempts per IP per 15 minutes
  windowSeconds: 15 * 60, // 15 minutes
};

/**
 * Rate limit configuration for registration attempts
 */
const REGISTER_RATE_LIMIT = {
  maxCalls: 5, // 5 registration attempts per IP per hour
  windowSeconds: 60 * 60, // 1 hour
};

/**
 * Extract client IP from request headers
 *
 * Firebase Functions provide the client IP via:
 * 1. x-forwarded-for header (when behind load balancer)
 * 2. rawRequest.ip (direct connection)
 *
 * @param request - Cloud Function request
 * @return Client IP address or "unknown"
 */
function getClientIp(request: {rawRequest?: {ip?: string; headers?: Record<string, string | string[] | undefined>}}): string {
  // Try x-forwarded-for first (most common in production)
  const forwardedFor = request.rawRequest?.headers?.["x-forwarded-for"];
  if (forwardedFor) {
    // x-forwarded-for can be comma-separated list, take first IP
    const firstIp = Array.isArray(forwardedFor) ?
      forwardedFor[0] :
      forwardedFor.split(",")[0]?.trim();
    if (firstIp) return firstIp;
  }

  // Fall back to direct IP
  if (request.rawRequest?.ip) {
    return request.rawRequest.ip;
  }

  return "unknown";
}

/**
 * Hash IP address for privacy (don't store raw IPs)
 *
 * Uses simple base64 encoding - not cryptographically secure but
 * sufficient for rate limiting key generation.
 *
 * @param ip - Client IP address
 * @return Hashed IP string
 */
function hashIp(ip: string): string {
  return Buffer.from(ip).toString("base64").substring(0, 16);
}

/**
 * Sanitize email for use as Firestore document ID
 * Matches Dart implementation in RateLimitService
 */
function sanitizeEmailForId(email: string): string {
  return email.trim().toLowerCase().replace(/[^a-z0-9@._-]/g, "_");
}

/**
 * Check login rate limit before authentication
 *
 * Call this Cloud Function from Dart before attempting Firebase Auth sign in.
 * Returns success if within rate limit, throws HttpsError if exceeded.
 *
 * @param email - Email being used for login (for logging only)
 * @returns {allowed: true} if within rate limit
 * @throws HttpsError with code "resource-exhausted" if rate limit exceeded
 *
 * @example
 * // Dart code:
 * final callable = FirebaseFunctions.instance.httpsCallable('checkLoginRateLimit');
 * await callable.call({'email': email});
 * // If no error, proceed with Firebase Auth sign in
 */
export const checkLoginRateLimit = onCall(
  {
    region: "europe-west1",
    // No authentication required - this is called BEFORE login
  },
  async (request) => {
    const {email} = request.data as {email?: string};
    const clientIp = getClientIp(request);
    const ipHash = hashIp(clientIp);

    // Check IP-based rate limit
    const isAllowed = checkRateLimit(
      `login_ip_${ipHash}`,
      LOGIN_RATE_LIMIT.maxCalls,
      LOGIN_RATE_LIMIT.windowSeconds
    );

    if (!isAllowed) {
      logWarn("[AuthRateLimit] Login rate limit exceeded", {
        ipHash,
        email: email ? email.substring(0, 3) + "***" : "unknown", // Partial email for logging
      });

      // Log security event (fire-and-forget)
      logRateLimitExceeded(ipHash, "login", {
        email: email ? email.substring(0, 3) + "***" : "unknown",
      }).catch(() => {}); // Don't block on logging

      throw new HttpsError(
        "resource-exhausted",
        "Too many login attempts from your location. Please wait 15 minutes before trying again."
      );
    }

    logInfo("[AuthRateLimit] Login rate limit check passed", {
      ipHash,
    });

    return {allowed: true};
  }
);

/**
 * Record a failed login attempt for an email
 * Secured: IP-rate limited and uses server-side logic
 */
export const recordFailedLoginAttempt = onCall(
  {
    region: "europe-west1",
  },
  async (request) => {
    const {email} = request.data as { email: string };
    if (!email || typeof email !== "string") {
      throw new HttpsError("invalid-argument", "Valid email is required");
    }

    const clientIp = getClientIp(request);
    const ipHash = hashIp(clientIp);

    // Rate limit the reporting itself to prevent abuse of Firestore writes
    if (!checkRateLimit(`report_failure_ip_${ipHash}`, 20, 600)) {
      throw new HttpsError("resource-exhausted", "Too many attempts from this location.");
    }

    const sanitizedEmail = sanitizeEmailForId(email);
    const docRef = db.collection("loginAttempts").doc(sanitizedEmail);

    try {
      await db.runTransaction(async (transaction) => {
        const doc = await transaction.get(docRef);
        const now = new Date();
        const lockoutDurationMs = 15 * 60 * 1000; // 15 minutes
        const attemptResetDurationMs = 60 * 60 * 1000; // 1 hour
        const maxAttempts = 5;

        if (!doc.exists) {
          transaction.set(docRef, {
            email,
            attemptCount: 1,
            lastAttemptAt: admin.firestore.Timestamp.fromDate(now),
          });
        } else {
          const data = doc.data()!;
          const lastAttemptAt = data.lastAttemptAt.toDate();

          if (now.getTime() - lastAttemptAt.getTime() > attemptResetDurationMs) {
            // Reset if last attempt was long ago
            transaction.update(docRef, {
              attemptCount: 1,
              lockedUntil: null,
              lastAttemptAt: admin.firestore.Timestamp.fromDate(now),
            });
          } else {
            const newCount = (data.attemptCount || 0) + 1;
            const lockedUntil = newCount >= maxAttempts ?
              admin.firestore.Timestamp.fromDate(new Date(now.getTime() + lockoutDurationMs)) :
              null;

            transaction.update(docRef, {
              attemptCount: newCount,
              lockedUntil,
              lastAttemptAt: admin.firestore.Timestamp.fromDate(now),
            });
          }
        }
      });

      return {success: true};
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logError("[AuthRateLimit] Error recording failed attempt", error);
      throw new HttpsError("internal", "Failed to record login attempt.");
    }
  }
);

/**
 * Reset login attempts after successful login
 * Secured: Requires authentication and email must match user
 */
export const resetLoginAttempts = onCall(
  {
    region: "europe-west1",
  },
  async (request) => {
    // Authentication required
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be logged in to reset attempts.");
    }

    const {email} = request.data as { email: string };
    if (!email || typeof email !== "string") {
      throw new HttpsError("invalid-argument", "Valid email is required");
    }

    // Security check: verify email matches authenticated user
    const authEmail = request.auth.token.email;
    if (!authEmail || authEmail.toLowerCase() !== email.toLowerCase()) {
      // Log suspicious activity
      logWarn("[AuthRateLimit] Unauthorized reset attempt", {
        uid: request.auth.uid,
        providedEmail: email,
        authEmail: authEmail,
      });
      throw new HttpsError("permission-denied", "You can only reset login attempts for your own email.");
    }

    const sanitizedEmail = sanitizeEmailForId(email);
    try {
      await db.collection("loginAttempts").doc(sanitizedEmail).delete();
      logInfo("[AuthRateLimit] Login attempts reset", {email: sanitizedEmail});
      return {success: true};
    } catch (error) {
      logError("[AuthRateLimit] Error resetting attempts", error);
      throw new HttpsError("internal", "Failed to reset login attempts.");
    }
  }
);

/**
 * Check registration rate limit before account creation
 *
 * Call this Cloud Function from Dart before attempting Firebase Auth registration.
 * Stricter limits than login to prevent spam account creation.
 *
 * @param email - Email being registered (for logging only)
 * @returns {allowed: true} if within rate limit
 * @throws HttpsError with code "resource-exhausted" if rate limit exceeded
 *
 * @example
 * // Dart code:
 * final callable = FirebaseFunctions.instance.httpsCallable('checkRegistrationRateLimit');
 * await callable.call({'email': email});
 * // If no error, proceed with Firebase Auth registration
 */
export const checkRegistrationRateLimit = onCall(
  {
    region: "europe-west1",
    // No authentication required - this is called BEFORE registration
  },
  async (request) => {
    const {email} = request.data as {email?: string};
    const clientIp = getClientIp(request);
    const ipHash = hashIp(clientIp);

    // Check IP-based rate limit
    const isAllowed = checkRateLimit(
      `register_ip_${ipHash}`,
      REGISTER_RATE_LIMIT.maxCalls,
      REGISTER_RATE_LIMIT.windowSeconds
    );

    if (!isAllowed) {
      logWarn("[AuthRateLimit] Registration rate limit exceeded", {
        ipHash,
        email: email ? email.substring(0, 3) + "***" : "unknown",
      });

      // Log security event (fire-and-forget)
      logRateLimitExceeded(ipHash, "registration", {
        email: email ? email.substring(0, 3) + "***" : "unknown",
      }).catch(() => {}); // Don't block on logging

      throw new HttpsError(
        "resource-exhausted",
        "Too many registration attempts from your location. Please wait 1 hour before trying again."
      );
    }

    logInfo("[AuthRateLimit] Registration rate limit check passed", {
      ipHash,
    });

    return {allowed: true};
  }
);
