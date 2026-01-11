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
import {logInfo, logWarn} from "./logger";

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
