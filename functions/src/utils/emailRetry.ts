import {logError, logSuccess, logInfo} from "../logger";

/**
 * Retry configuration
 */
interface RetryConfig {
  /** Maximum number of retry attempts (default: 3) */
  maxRetries?: number;
  /** Initial delay in milliseconds (default: 1000ms = 1s) */
  initialDelay?: number;
  /** Backoff multiplier for exponential backoff (default: 2) */
  backoffMultiplier?: number;
}

/**
 * Send email with automatic retry on failure
 *
 * RETRY STRATEGY:
 * - Exponential backoff: 1s, 2s, 4s, 8s...
 * - Max 3 retries by default (4 total attempts)
 * - Logs all attempts for debugging
 *
 * USE CASES:
 * - Temporary network issues (retry helps)
 * - Rate limiting (backoff helps)
 * - Transient API errors (retry helps)
 *
 * DOES NOT RETRY:
 * - Invalid email addresses (permanent failure)
 * - Authentication errors (permanent failure)
 *
 * @param emailFunc - Async function that sends email
 * @param emailType - Type of email (for logging)
 * @param recipient - Email recipient (for logging)
 * @param config - Retry configuration
 * @returns Promise<void>
 * @throws Error if all retries fail
 */
export async function sendEmailWithRetry(
  emailFunc: () => Promise<void>,
  emailType: string,
  recipient: string,
  config: RetryConfig = {}
): Promise<void> {
  const {
    maxRetries = 3,
    initialDelay = 1000,
    backoffMultiplier = 2,
  } = config;

  let lastError: Error | unknown;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      // Attempt to send email
      logInfo(`[EmailRetry] Attempting to send ${emailType} email (attempt ${attempt + 1}/${maxRetries + 1})`, {
        recipient,
        emailType,
      });

      await emailFunc();

      // Success!
      if (attempt > 0) {
        logSuccess(
          `[EmailRetry] Email sent successfully after ${attempt} retries`,
          {
            recipient,
            emailType,
            attempt: attempt + 1,
          }
        );
      }

      return; // Success - exit function
    } catch (error) {
      lastError = error;

      // Check if this is a permanent failure (don't retry)
      if (isPermanentFailure(error)) {
        logError(
          `[EmailRetry] Permanent failure for ${emailType} email - not retrying`,
          error,
          {
            recipient,
            emailType,
            attempt: attempt + 1,
          }
        );
        throw error; // Don't retry permanent failures
      }

      // Check if we've exhausted retries
      if (attempt === maxRetries) {
        logError(
          `[EmailRetry] All retries exhausted for ${emailType} email`,
          error,
          {
            recipient,
            emailType,
            totalAttempts: attempt + 1,
          }
        );
        throw error; // Final failure
      }

      // Calculate backoff delay (exponential: 1s, 2s, 4s, 8s...)
      const delay = initialDelay * Math.pow(backoffMultiplier, attempt);

      logInfo(
        `[EmailRetry] ${emailType} email failed, retrying in ${delay}ms`,
        {
          recipient,
          emailType,
          attempt: attempt + 1,
          nextDelay: delay,
          error: error instanceof Error ? error.message : "Unknown error",
        }
      );

      // Wait before retry (exponential backoff)
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }

  // This should be unreachable, but TypeScript needs it
  throw lastError || new Error("Email sending failed for unknown reason");
}

/**
 * Check if error is a permanent failure (should not retry)
 *
 * PERMANENT FAILURES:
 * - Invalid email address (4xx errors)
 * - Authentication errors
 * - Missing API keys
 *
 * TEMPORARY FAILURES (should retry):
 * - Network timeout (5xx errors)
 * - Rate limiting
 * - Service unavailable
 *
 * @param error - Error object from email sending
 * @returns true if permanent failure, false if should retry
 */
function isPermanentFailure(error: unknown): boolean {
  if (!error) return false;

  const errorMessage =
    error instanceof Error ? error.message.toLowerCase() : String(error);

  // Permanent failures (don't retry)
  const permanentPatterns = [
    "invalid email",
    "invalid recipient",
    "authentication failed",
    "unauthorized",
    "forbidden",
    "api key",
    "bad request",
    "validation error",
  ];

  return permanentPatterns.some((pattern) => errorMessage.includes(pattern));
}
