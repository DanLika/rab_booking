/**
 * PII redaction helpers for Cloud Logging.
 *
 * Cloud Logging surfaces are queryable across the org — full PII (email,
 * phone, etc.) in `jsonPayload.*` becomes a stored credential-class artifact.
 * Use these helpers in any `logInfo/logSuccess/logError` call that would
 * otherwise embed user identifiers. Correlation is preserved via the leading
 * prefix; full values live in Firestore (e.g., `emails_sent.*.email`) and
 * stay subject to Firestore rules + retention policy.
 *
 * Established pattern (3-char prefix + ***) matches authRateLimit.ts,
 * verifyBookingAccess.ts, passwordReset.ts.
 */

/**
 * Return a redacted form of an email safe to embed in logs.
 * - null/undefined/empty → "unknown"
 * - non-empty → first 3 chars + "***"
 */
export function redactEmail(email: string | null | undefined): string {
  if (!email) return "unknown";
  return `${email.substring(0, 3)}***`;
}
