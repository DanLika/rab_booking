/**
 * Sentry Configuration for Cloud Functions
 *
 * Centralized error tracking and performance monitoring.
 * Initialize once at module load, use throughout functions.
 */

import * as Sentry from "@sentry/node";
import {defineString} from "firebase-functions/params";
import {logInfo, logError} from "./logger";

// Sentry DSN for Cloud Functions error tracking
const sentryDsn = defineString("SENTRY_DSN", {default: ""});

// Track initialization state
let isInitialized = false;

/**
 * Detect the Sentry environment tag from runtime env vars.
 *
 * Cloud Functions Gen 2 does not reliably populate GCP_PROJECT; GCLOUD_PROJECT
 * is the documented fallback. Returning explicit per-project labels prevents
 * dev/staging errors from polluting the production Sentry dashboard.
 * @return {string} the environment
 */
function detectEnvironment(): string {
  if (process.env.FUNCTIONS_EMULATOR === "true") return "local";
  const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
  if (projectId === "bookbed-dev") return "development";
  if (projectId === "bookbed-staging") return "staging";
  if (projectId === "rab-booking-248fc") return "production";
  return "unknown";
}

/**
 * Initialize Sentry for Cloud Functions
 * Call this at the top of index.ts
 */
export function initSentry(): void {
  if (isInitialized) {
    return;
  }

  const dsn = sentryDsn.value();
  if (!dsn) {
    logInfo("Sentry DSN not provided, skipping initialization");
    return;
  }

  try {
    Sentry.init({
      dsn,
      environment: detectEnvironment(),
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
        if (err && err.httpErrorCode !== undefined &&
            typeof err.code === "string" && clientFaultCodes.has(err.code)) {
          return null;
        }
        return event;
      },
    });

    isInitialized = true;
    logInfo("Sentry initialized for Cloud Functions", {
      environment: detectEnvironment(),
      gcpProject: process.env.GCP_PROJECT || null,
      gcloudProject: process.env.GCLOUD_PROJECT || null,
    });
  } catch (error) {
    logError("Failed to initialize Sentry", error);
  }
}

/**
 * Capture an exception and send to Sentry
 * @param {unknown} error the error to capture
 * @param {Record<string, unknown>} context the context
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
 * @param {string} message the message
 * @param {Sentry.SeverityLevel} level the level
 * @param {Record<string, unknown>} context the context
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
 * @param {string | null} userId the user id
 * @param {string} email the email
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
 * @param {string} message the message
 * @param {string} category the category
 * @param {Record<string, unknown>} data the data
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
 * @param {string} functionName the function name
 * @param {string | null} userId the user id
 * @param {Function} fn the function
 * @return {Promise<T>} the return value of the function
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
