/**
 * Sentry Configuration for Cloud Functions
 *
 * Centralized error tracking and performance monitoring.
 * Initialize once at module load, use throughout functions.
 */

import * as Sentry from "@sentry/node";
import {logInfo, logError} from "./logger";

// Sentry DSN for Cloud Functions error tracking
const SENTRY_DSN =
  "https://2d78b151017ba853ff8b097914b92633@o4510516866908160.ingest.de.sentry.io/4510516869464144";

// Track initialization state
let isInitialized = false;

/**
 * Initialize Sentry for Cloud Functions
 * Call this at the top of index.ts
 */
export function initSentry(): void {
  if (isInitialized) {
    return;
  }

  try {
    Sentry.init({
      dsn: SENTRY_DSN,
      environment: process.env.FUNCTIONS_EMULATOR === "true"
        ? "local"
        : (process.env.GCP_PROJECT === "rab-booking-248fc" ? "production" : "development"),
      tracesSampleRate: 0.1, // 10% of transactions for performance monitoring
      // Tag all events as coming from cloud functions
      initialScope: {
        tags: {
          app_type: "cloud_functions",
        },
      },
      // Drop HttpsError events with client-fault codes — these are expected
      // 4xx-equivalent responses, not server bugs. Otel auto-instrumentation
      // captures every thrown HttpsError from callables; filter the noise.
      beforeSend(event, hint) {
        const err = hint?.originalException as
          | {code?: string; httpErrorCode?: unknown} | undefined;
        const clientFaultCodes = new Set([
          "invalid-argument",
          "unauthenticated",
          "permission-denied",
          "not-found",
          "already-exists",
          "failed-precondition",
          "out-of-range",
          "resource-exhausted",
          "cancelled",
        ]);
        if (err && err.httpErrorCode !== undefined && typeof err.code === "string" &&
            clientFaultCodes.has(err.code)) {
          return null;
        }
        return event;
      },
    });

    isInitialized = true;
    logInfo("Sentry initialized for Cloud Functions");
  } catch (error) {
    logError("Failed to initialize Sentry", error);
  }
}

/**
 * Capture an exception and send to Sentry
 */
export function captureException(
  error: unknown,
  context?: Record<string, unknown>
): void {
  if (!isInitialized) {
    return;
  }

  Sentry.withScope((scope) => {
    if (context) {
      scope.setExtras(context);
    }
    Sentry.captureException(error);
  });
}

/**
 * Capture a message and send to Sentry
 */
export function captureMessage(
  message: string,
  level: Sentry.SeverityLevel = "info",
  context?: Record<string, unknown>
): void {
  if (!isInitialized) {
    return;
  }

  Sentry.withScope((scope) => {
    if (context) {
      scope.setExtras(context);
    }
    Sentry.captureMessage(message, level);
  });
}

/**
 * Set user context for Sentry events
 */
export function setUser(userId: string | null, email?: string): void {
  if (!isInitialized) {
    return;
  }

  if (userId) {
    Sentry.setUser({id: userId, email});
  } else {
    Sentry.setUser(null);
  }
}

/**
 * Add breadcrumb for debugging
 */
export function addBreadcrumb(
  message: string,
  category: string,
  data?: Record<string, unknown>
): void {
  if (!isInitialized) {
    return;
  }

  Sentry.addBreadcrumb({
    message,
    category,
    data,
    level: "info",
  });
}

/**
 * Wrapper to capture errors in async functions
 * Use this to wrap your function handlers
 */
export async function withSentry<T>(
  functionName: string,
  userId: string | null,
  fn: () => Promise<T>
): Promise<T> {
  // Set user context
  setUser(userId);

  // Add function name as breadcrumb
  addBreadcrumb(`Executing ${functionName}`, "function");

  try {
    return await fn();
  } catch (error) {
    captureException(error, {
      functionName,
      userId,
    });
    throw error;
  }
}

// Re-export Sentry for advanced usage
export {Sentry};
