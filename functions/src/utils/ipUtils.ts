import * as crypto from "crypto";

/**
 * IP Utilities
 *
 * Provides helpers for extracting and processing client IP addresses.
 *
 * @module ipUtils
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
export function getClientIp(request: {rawRequest?: {ip?: string; headers?: Record<string, string | string[] | undefined>}}): string {
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
 * Hash IP address for privacy and rate-limit key generation.
 *
 * Uses SHA-256 to create a one-way hash of the IP address.
 *
 * @param ip - Client IP address
 * @return Hashed IP string (first 16 chars of hex)
 */
export function hashIp(ip: string): string {
  return crypto
    .createHash("sha256")
    .update(ip)
    .digest("hex")
    .substring(0, 16);
}
