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
import {admin, db} from "./firebase";
import {checkRateLimit} from "./utils/rateLimit";
import {logRateLimitExceeded} from "./utils/securityMonitoring";
import {logInfo, logWarn, logError} from "./logger";
import {getClientIp, hashIp} from "./utils/ipUtils";
import {sanitizeEmail} from "./utils/inputSanitization";

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

/**
 * Get login rate limit status for an email
 *
 * Checks Firestore loginAttempts collection.
 * Automatically resets expired attempts (> 1 hour).
 */
export const getLoginRateLimitStatus = onCall(
  {region: "europe-west1"},
  async (request) => {
    const {email} = request.data as {email?: string};
    if (!email) {
      throw new HttpsError("invalid-argument", "Email is required");
    }

    const sanitizedEmail = sanitizeEmail(email);
    if (!sanitizedEmail) {
      throw new HttpsError("invalid-argument", "Invalid email format");
    }

    // Rate limit params (match Dart service)
    const MAX_ATTEMPTS = 5;
    const ATTEMPT_RESET_DURATION_MS = 60 * 60 * 1000; // 1 hour

    try {
      const docRef = db.collection("loginAttempts").doc(sanitizedEmail);
      const doc = await docRef.get();

      if (!doc.exists) {
        return {attemptCount: 0, isLocked: false, lockedUntil: null};
      }

      const data = doc.data()!;
      const lastAttemptAt = data.lastAttemptAt?.toDate()?.getTime() || 0;
      const now = Date.now();

      // Reset attempts if last attempt was > 1 hour ago
      if (now - lastAttemptAt > ATTEMPT_RESET_DURATION_MS) {
        await docRef.delete();
        return {attemptCount: 0, isLocked: false, lockedUntil: null};
      }

      const isLocked = data.attemptCount >= MAX_ATTEMPTS;
      const lockedUntil = data.lockedUntil?.toDate()?.toISOString() || null;

      // Check if lock expired
      const isActuallyLocked = isLocked && lockedUntil ? new Date(lockedUntil).getTime() > now : false;

      return {
        attemptCount: data.attemptCount,
        isLocked: isActuallyLocked,
        lockedUntil: lockedUntil,
      };
    } catch (error) {
      logError("Failed to get login rate limit status", error);
      throw new HttpsError("internal", "Failed to check rate limit status");
    }
  }
);

/**
 * Record a failed login attempt
 *
 * Increments attempt count in Firestore.
 * Sets lockedUntil if max attempts exceeded.
 */
export const recordFailedLoginAttempt = onCall(
  {region: "europe-west1"},
  async (request) => {
    const {email} = request.data as {email?: string};
    if (!email) {
      throw new HttpsError("invalid-argument", "Email is required");
    }

    const sanitizedEmail = sanitizeEmail(email);
    if (!sanitizedEmail) {
      throw new HttpsError("invalid-argument", "Invalid email format");
    }

    const MAX_ATTEMPTS = 5;
    const LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 minutes
    const ATTEMPT_RESET_DURATION_MS = 60 * 60 * 1000; // 1 hour

    try {
      const docRef = db.collection("loginAttempts").doc(sanitizedEmail);

      const result = await db.runTransaction(async (transaction) => {
        const doc = await transaction.get(docRef);
        const now = admin.firestore.Timestamp.now();
        const nowMs = now.toMillis();

        let newCount = 1;
        let lockedUntil: admin.firestore.Timestamp | null = null;

        if (!doc.exists) {
          // First attempt
          transaction.set(docRef, {
            email: email, // Store original email for reference
            attemptCount: 1,
            lastAttemptAt: now,
            lockedUntil: null,
          });
        } else {
          const data = doc.data()!;
          const lastAttemptAt = data.lastAttemptAt?.toDate()?.getTime() || 0;

          // Reset if last attempt was > 1 hour ago
          if (nowMs - lastAttemptAt > ATTEMPT_RESET_DURATION_MS) {
            newCount = 1;
            lockedUntil = null;
          } else {
            newCount = (data.attemptCount || 0) + 1;

            // Check if should lock
            // Lock if >= max attempts.
            // If already locked and lock expired, we re-lock because they failed again immediately.
            // (If they waited for lock to expire and then failed, they get locked again?
            //  Yes, standard brute force protection.)
            if (newCount >= MAX_ATTEMPTS) {
              lockedUntil = admin.firestore.Timestamp.fromMillis(nowMs + LOCKOUT_DURATION_MS);
            } else if (data.lockedUntil) {
              // Preserve existing lock if not expired and still < max (shouldn't happen)
              // or if we are refreshing
              // Actually, if newCount < MAX_ATTEMPTS, we shouldn't be locked.
              // So if previously locked (e.g. attempt 5), and we are now at attempt 6 (after expiry reset? No, count increases).
              // If attempt 5 locked it.
              // 16 mins later, attempt 6.
              // newCount = 6. >= MAX_ATTEMPTS.
              // lockedUntil = now + 15 mins.
              // Correct.
            }
          }

          transaction.update(docRef, {
            attemptCount: newCount,
            lastAttemptAt: now,
            lockedUntil: lockedUntil,
          });
        }

        return {
          attemptCount: newCount,
          lockedUntil: lockedUntil?.toDate()?.toISOString() || null,
          isLocked: lockedUntil ? lockedUntil.toMillis() > nowMs : false,
        };
      });

      return result;
    } catch (error) {
      logError("Failed to record login attempt", error);
      throw new HttpsError("internal", "Failed to record login attempt");
    }
  }
);

/**
 * Reset login attempts (after successful login)
 *
 * Requires authentication.
 */
export const resetLoginAttempts = onCall(
  {region: "europe-west1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const {email} = request.data as {email?: string};
    if (!email) {
      throw new HttpsError("invalid-argument", "Email is required");
    }

    const sanitizedEmail = sanitizeEmail(email);
    if (!sanitizedEmail) {
      throw new HttpsError("invalid-argument", "Invalid email format");
    }

    // Verify email matches authenticated user
    // This prevents User A from resetting User B's attempts
    const tokenEmail = request.auth.token.email;
    if (!tokenEmail || tokenEmail.toLowerCase() !== email.toLowerCase()) {
      logWarn("Unauthorized reset attempt", {
        uid: request.auth.uid,
        authEmail: tokenEmail,
        targetEmail: email,
      });
      throw new HttpsError("permission-denied", "Can only reset attempts for your own email");
    }

    try {
      await db.collection("loginAttempts").doc(sanitizedEmail).delete();
      logInfo("Login attempts reset", {email: sanitizedEmail});
      return {success: true};
    } catch (error) {
      logError("Failed to reset login attempts", error);
      throw new HttpsError("internal", "Failed to reset login attempts");
    }
  }
);
