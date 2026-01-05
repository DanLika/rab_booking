/**
 * Rate Limiting Utilities
 *
 * Provides both in-memory (synchronous) and Firestore-backed (async) rate limiting.
 *
 * - checkRateLimit: Simple in-memory check for hot paths (e.g., token verification)
 * - enforceRateLimit: Persistent Firestore-backed limiting for critical actions
 *
 * SECURITY: Default behavior is fail-closed (block on error).
 *
 * @module rateLimit
 */

import {db} from "../firebase";
import {HttpsError} from "firebase-functions/v2/https";
import {logError} from "../logger";

// ==========================================
// IN-MEMORY RATE LIMITING
// ==========================================

/**
 * In-memory rate limit store
 * Key: action identifier (e.g., "token_verify:192.168.1.1")
 * Value: array of timestamps
 */
const rateLimitStore = new Map<string, number[]>();

/**
 * Cleanup interval for in-memory store (5 minutes)
 */
const CLEANUP_INTERVAL_MS = 5 * 60 * 1000;

/**
 * Maximum entries in memory store (prevents memory leak)
 */
const MAX_MEMORY_ENTRIES = 10000;

// Periodic cleanup of old entries
setInterval(() => {
  const now = Date.now();
  const oldestAllowed = now - 3600000; // 1 hour

  for (const [key, timestamps] of rateLimitStore.entries()) {
    const recent = timestamps.filter(ts => ts > oldestAllowed);
    if (recent.length === 0) {
      rateLimitStore.delete(key);
    } else {
      rateLimitStore.set(key, recent);
    }
  }
}, CLEANUP_INTERVAL_MS);

/**
 * Simple in-memory rate limit check (synchronous)
 *
 * Use this for hot paths where Firestore latency is unacceptable.
 * Note: This is per-instance only - not shared across Cloud Function instances.
 *
 * @param key - Unique identifier (e.g., "token_verify:192.168.1.1")
 * @param maxCalls - Maximum calls allowed in window
 * @param windowSeconds - Time window in seconds
 * @returns true if within limit, false if exceeded
 *
 * @example
 * if (!checkRateLimit(`token_verify:${clientIp}`, 10, 60)) {
 *   return false; // Rate limited
 * }
 */
export function checkRateLimit(
  key: string,
  maxCalls: number,
  windowSeconds: number
): boolean {
  const now = Date.now();
  const windowMs = windowSeconds * 1000;
  const windowStart = now - windowMs;

  // Get existing timestamps
  const timestamps = rateLimitStore.get(key) || [];

  // Filter to recent timestamps only
  const recentTimestamps = timestamps.filter(ts => ts > windowStart);

  // Check if limit exceeded
  if (recentTimestamps.length >= maxCalls) {
    return false;
  }

  // Add current timestamp
  recentTimestamps.push(now);

  // Memory leak prevention
  if (rateLimitStore.size >= MAX_MEMORY_ENTRIES) {
    // Delete oldest entry
    const firstKey = rateLimitStore.keys().next().value;
    if (firstKey) {
      rateLimitStore.delete(firstKey);
    }
  }

  rateLimitStore.set(key, recentTimestamps);
  return true;
}

// ==========================================
// FIRESTORE-BACKED RATE LIMITING
// ==========================================

/**
 * Maximum timestamps to store per action in Firestore
 */
const MAX_TIMESTAMPS_STORED = 1000;

/**
 * Rate limit configuration
 */
interface RateLimitConfig {
  /** Maximum number of calls allowed */
  maxCalls: number;
  /** Time window in milliseconds */
  windowMs: number;
  /** Error message to show when limit exceeded */
  errorMessage?: string;
  /**
   * Fail-open behavior (default: false = fail-closed)
   *
   * - false (default): Block request if rate limit check fails (SECURE)
   * - true: Allow request if rate limit check fails (AVAILABILITY)
   *
   * Use failOpen: true ONLY for non-critical actions where
   * service availability is more important than security.
   */
  failOpen?: boolean;
}

/**
 * Check and enforce rate limit for a user
 *
 * Uses Firestore to track request timestamps in a sliding window.
 * Automatically cleans up old timestamps.
 *
 * @param userId - User ID to rate limit
 * @param action - Action name for rate limiting (e.g., "send_email", "security_alert")
 * @param config - Rate limit configuration
 * @throws HttpsError with code "resource-exhausted" if limit exceeded
 *
 * @example
 * // Allow 10 emails per minute
 * await enforceRateLimit(userId, "send_email", {
 *   maxCalls: 10,
 *   windowMs: 60000, // 1 minute
 * });
 *
 * @example
 * // Allow 5 security alerts per hour
 * await enforceRateLimit(userId, "security_alert", {
 *   maxCalls: 5,
 *   windowMs: 3600000, // 1 hour
 *   errorMessage: "Too many security alerts. Try again later."
 * });
 */
export async function enforceRateLimit(
  userId: string,
  action: string,
  config: RateLimitConfig
): Promise<void> {
  const {maxCalls, windowMs, errorMessage, failOpen = false} = config;
  const now = Date.now();
  const windowStart = now - windowMs;

  // NEW STRUCTURE: users/{userId}/rate_limits/{action}
  const rateLimitRef = db
    .collection("users")
    .doc(userId)
    .collection("rate_limits")
    .doc(action);

  try {
    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(rateLimitRef);

      if (!doc.exists) {
        // First call - initialize
        transaction.set(rateLimitRef, {
          timestamps: [now],
          last_reset: now,
        });
        return;
      }

      const data = doc.data()!;
      const allTimestamps = (data.timestamps || []) as number[];

      // Filter timestamps within the current window (sliding window)
      let recentTimestamps = allTimestamps.filter(
        (ts: number) => ts > windowStart
      );

      // MEMORY LEAK FIX: Cap array size to prevent unbounded growth
      // Keep only the most recent timestamps if array is too large
      if (recentTimestamps.length > MAX_TIMESTAMPS_STORED) {
        recentTimestamps = recentTimestamps
          .sort((a, b) => b - a) // Sort descending (newest first)
          .slice(0, MAX_TIMESTAMPS_STORED); // Keep newest
      }

      // Check if limit exceeded
      if (recentTimestamps.length >= maxCalls) {
        const oldestTimestamp = Math.min(...recentTimestamps);
        const waitTimeMs = oldestTimestamp + windowMs - now;
        const waitTimeSec = Math.ceil(waitTimeMs / 1000);

        throw new HttpsError(
          "resource-exhausted",
          errorMessage ||
            `Rate limit exceeded. Maximum ${maxCalls} requests per ${Math.ceil(
              windowMs / 1000
            )} seconds. Try again in ${waitTimeSec} seconds.`
        );
      }

      // Add current timestamp and update
      const updatedTimestamps = [...recentTimestamps, now];
      transaction.update(rateLimitRef, {
        timestamps: updatedTimestamps,
        last_reset: now,
      });
    });
  } catch (error: unknown) {
    // Re-throw HttpsError (rate limit exceeded)
    if (error instanceof HttpsError && error.code === "resource-exhausted") {
      throw error;
    }

    // SECURITY FIX: Default to fail-closed (block request on error)
    // This prevents attackers from bypassing rate limits by causing errors
    logError(`[RateLimit] Check failed for ${userId}:${action}`, error, {
      userId,
      action,
      failOpen,
    });

    if (!failOpen) {
      // Fail-closed: Block request when rate limit check fails (SECURE DEFAULT)
      throw new HttpsError(
        "unavailable",
        "Rate limit check temporarily unavailable. Please try again."
      );
    }
    // Fail-open: Allow request (only for non-critical actions)
    // Request proceeds without rate limiting
  }
}

/**
 * Get current rate limit status for a user
 *
 * Returns information about how many calls are remaining in the current window.
 * Useful for displaying rate limit status to users.
 *
 * @param userId - User ID to check
 * @param action - Action name
 * @param config - Rate limit configuration
 * @returns Rate limit status
 *
 * @example
 * const status = await getRateLimitStatus(userId, "send_email", {
 *   maxCalls: 10,
 *   windowMs: 60000,
 * });
 * console.log(`Calls remaining: ${status.remaining}`);
 */
export async function getRateLimitStatus(
  userId: string,
  action: string,
  config: RateLimitConfig
): Promise<{
  remaining: number;
  resetAt: Date;
  callsInWindow: number;
}> {
  const {maxCalls, windowMs} = config;
  const now = Date.now();
  const windowStart = now - windowMs;

  // NEW STRUCTURE: users/{userId}/rate_limits/{action}
  const rateLimitRef = db
    .collection("users")
    .doc(userId)
    .collection("rate_limits")
    .doc(action);

  const doc = await rateLimitRef.get();

  if (!doc.exists) {
    return {
      remaining: maxCalls,
      resetAt: new Date(now + windowMs),
      callsInWindow: 0,
    };
  }

  const data = doc.data()!;
  const allTimestamps = (data.timestamps || []) as number[];

  // Filter timestamps within window and apply cap for consistency
  let recentTimestamps = allTimestamps.filter((ts) => ts > windowStart);
  if (recentTimestamps.length > MAX_TIMESTAMPS_STORED) {
    recentTimestamps = recentTimestamps
      .sort((a, b) => b - a)
      .slice(0, MAX_TIMESTAMPS_STORED);
  }

  const remaining = Math.max(0, maxCalls - recentTimestamps.length);
  const oldestTimestamp =
    recentTimestamps.length > 0 ? Math.min(...recentTimestamps) : now;
  const resetAt = new Date(oldestTimestamp + windowMs);

  return {
    remaining,
    resetAt,
    callsInWindow: recentTimestamps.length,
  };
}
