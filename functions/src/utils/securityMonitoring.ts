/**
 * Security Monitoring Utilities
 *
 * Provides logging and tracking of security-related events for monitoring and alerting.
 *
 * Events are logged to:
 * 1. Firestore `security_events` collection (for analysis)
 * 2. Structured logs (for Cloud Logging)
 * 3. Sentry (for critical/high severity events - real-time alerting)
 *
 * @module securityMonitoring
 */

import {logError, logWarn, logInfo} from "../logger";
import * as admin from "firebase-admin";
import {captureMessage} from "../sentry";

/**
 * Security Event Types
 */
export enum SecurityEventType {
  /** Webhook signature verification failed */
  WEBHOOK_SIGNATURE_FAILED = "webhook_signature_failed",
  /** Price mismatch between client and server */
  PRICE_MISMATCH_DETECTED = "price_mismatch_detected",
  /** Rate limit exceeded */
  RATE_LIMIT_EXCEEDED = "rate_limit_exceeded",
  /** Invalid access token used */
  INVALID_ACCESS_TOKEN = "invalid_access_token",
  /** Stripe account not verified for payments */
  STRIPE_ACCOUNT_NOT_VERIFIED = "stripe_account_not_verified",
  /** Suspicious booking attempt detected */
  SUSPICIOUS_BOOKING_ATTEMPT = "suspicious_booking_attempt",
  /** Invalid return URL attempted */
  INVALID_RETURN_URL = "invalid_return_url",
  /** Unauthorized access attempt */
  UNAUTHORIZED_ACCESS = "unauthorized_access",
}

/**
 * Security event severity levels
 */
export type SecuritySeverity = "low" | "medium" | "high" | "critical";

/**
 * Log security event for monitoring
 *
 * @param eventType - Type of security event
 * @param details - Additional details about the event
 * @param severity - Severity level (default: medium)
 *
 * @example
 * await logSecurityEvent(
 *   SecurityEventType.RATE_LIMIT_EXCEEDED,
 *   { ip: clientIp, action: "stripe_checkout" },
 *   "medium"
 * );
 */
export async function logSecurityEvent(
  eventType: SecurityEventType,
  details: Record<string, unknown>,
  severity: SecuritySeverity = "medium"
): Promise<void> {
  const event = {
    type: eventType,
    severity: severity,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    details: details,
  };

  // Log to Firestore for analysis (fire-and-forget, don't block)
  try {
    // Use set with auto-generated ID for better performance
    const db = admin.firestore();
    db.collection("security_events").add(event).catch((err) => {
      // Silently fail - don't let monitoring failure affect main flow
      logWarn("[SecurityMonitoring] Failed to write to Firestore", {error: err.message});
    });
  } catch (error) {
    // Fallback to console logging if Firestore fails
    logWarn(`[SecurityMonitoring] Firestore write failed: ${eventType}`, details);
  }

  // Always log to structured logs based on severity
  const logMessage = `[Security:${severity.toUpperCase()}] ${eventType}`;

  switch (severity) {
  case "critical":
  case "high":
    logError(logMessage, null, details);
    break;
  case "medium":
    logWarn(logMessage, details);
    break;
  case "low":
    logInfo(logMessage, details);
    break;
  }

  // Sentry integration for critical/high severity events
  // This provides real-time alerting for security incidents
  if (severity === "critical" || severity === "high") {
    const sentryLevel = severity === "critical" ? "fatal" : "error";
    captureMessage(
      `[Security] ${eventType}`,
      sentryLevel,
      {
        eventType,
        severity,
        ...details,
      }
    );
  }
}

/**
 * Quick helper for rate limit events
 */
export async function logRateLimitExceeded(
  identifier: string,
  action: string,
  details?: Record<string, unknown>
): Promise<void> {
  await logSecurityEvent(
    SecurityEventType.RATE_LIMIT_EXCEEDED,
    {
      identifier,
      action,
      ...details,
    },
    "medium"
  );
}

/**
 * Quick helper for webhook signature failures
 */
export async function logWebhookSignatureFailure(
  error: string,
  hasSignature: boolean,
  details?: Record<string, unknown>
): Promise<void> {
  await logSecurityEvent(
    SecurityEventType.WEBHOOK_SIGNATURE_FAILED,
    {
      error,
      hasSignature,
      ...details,
    },
    "critical"
  );
}

/**
 * Quick helper for price mismatch detection
 */
export async function logPriceMismatch(
  unitId: string,
  clientPrice: number,
  serverPrice: number,
  details?: Record<string, unknown>
): Promise<void> {
  await logSecurityEvent(
    SecurityEventType.PRICE_MISMATCH_DETECTED,
    {
      unitId,
      clientPrice,
      serverPrice,
      difference: Math.abs(serverPrice - clientPrice),
      ...details,
    },
    "high"
  );
}
