import * as crypto from "crypto";

/**
 * IP Handling Utilities
 *
 * Provides consistent IP extraction and privacy-preserving hashing
 * for rate limiting and security monitoring.
 */

/**
 * Extract client IP from request headers
 *
 * Firebase Functions provide the client IP via:
 * 1. x-forwarded-for header (when behind load balancer)
 * 2. rawRequest.ip (direct connection)
 *
 * @param request - Cloud Function request (onRequest or onCall)
 * @return Client IP address or "unknown"
 */
export function getClientIp(request: any): string {
  // Case 1: onRequest (Express-like request)
  // Case 2: onCall (CallableRequest has rawRequest)
  const rawReq = request.rawRequest || request;

  // Try x-forwarded-for first (most common in production)
  const forwardedFor = rawReq.headers?.["x-forwarded-for"];
  if (forwardedFor) {
    // x-forwarded-for can be comma-separated list, take first IP
    const firstIp = Array.isArray(forwardedFor) ?
      forwardedFor[0] :
      forwardedFor.split(",")[0]?.trim();
    if (firstIp) return firstIp;
  }

  // Fall back to direct IP
  if (rawReq.ip) {
    return rawReq.ip;
  }

  return "unknown";
}

/**
 * Hash IP address for privacy (don't store raw IPs)
 *
 * Uses SHA-256 for one-way hashing.
 *
 * @param ip - Client IP address
 * @return Hashed IP string (truncated for use as key)
 */
export function hashIp(ip: string): string {
  return crypto
    .createHash("sha256")
    .update(ip)
    .digest("hex")
    .substring(0, 16);
}
