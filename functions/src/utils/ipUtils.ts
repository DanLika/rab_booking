import * as crypto from "crypto";

/**
 * IP Utilities
 *
 * Provides utilities for extracting and hashing client IP addresses.
 *
 * SECURITY: Always hash IP addresses before storing them or using them as keys
 * to protect user privacy.
 */

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
export function getClientIp(request: any): string {
  // Handle both onCall (has rawRequest) and onRequest (is the request itself)
  const req = request.rawRequest || request;

  // Try x-forwarded-for first (most common in production)
  const forwardedFor = req.headers?.["x-forwarded-for"];
  if (forwardedFor) {
    // x-forwarded-for can be comma-separated list, take first IP
    const firstIp = Array.isArray(forwardedFor) ?
      forwardedFor[0] :
      forwardedFor.split(",")[0]?.trim();
    if (firstIp) return firstIp;
  }

  // Fall back to direct IP
  if (req.ip) {
    return req.ip;
  }

  return "unknown";
}

/**
 * Hash IP address for privacy (don't store raw IPs)
 *
 * Uses SHA-256 for privacy-preserving rate-limit keys.
 * Truncated to 16 characters for efficiency.
 *
 * @param ip - Client IP address
 * @return Hashed IP string
 */
export function hashIp(ip: string): string {
  return crypto
    .createHash("sha256")
    .update(ip)
    .digest("base64")
    .substring(0, 16);
}
