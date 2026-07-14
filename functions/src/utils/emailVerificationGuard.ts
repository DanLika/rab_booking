import {createHash} from "crypto";

/**
 * Server-side enforcement of the owner's "require email verification" widget
 * setting.
 *
 * The setting was previously enforced ONLY in the widget UI (the guest form
 * gated the Send button behind a verified code). `createBookingAtomic` never
 * checked it, so a direct callable request — or any non-widget client — could
 * create a booking with a completely unverified/fake email on a unit whose
 * owner had turned verification on, defeating the anti-spam protection.
 * Same class as the advance-window (#903) and max-stay (#906) client-only gates.
 */

/**
 * SHA-256 of the normalized email. MUST stay byte-identical to
 * `hashEmail` in emailVerification.ts (that CF writes the doc id this reads).
 */
export function hashEmailForVerification(email: string): string {
  return createHash("sha256").update(email.toLowerCase().trim()).digest("hex");
}

/**
 * True when the owner's widget settings require guest email verification.
 * Absent/false config = no requirement.
 */
export function emailVerificationRequired(
  widgetSettings: {email_config?: {require_email_verification?: boolean}} | undefined
): boolean {
  return widgetSettings?.email_config?.require_email_verification === true;
}

/**
 * Decide whether an `email_verifications/{hash}` doc counts as verified right
 * now. Pure (no I/O) so it is unit-testable. Mirrors the rule
 * `checkEmailVerificationStatus` returns to the client (verified AND not past
 * the code's `expiresAt` freshness bound), so a legit guest who just passed the
 * client gate always satisfies this too. A verified record with no `expiresAt`
 * is treated as valid.
 */
export function isEmailVerificationValid(
  data: {verified?: boolean; expiresAt?: {toDate: () => Date}} | undefined,
  now: Date
): boolean {
  if (!data || data.verified !== true) return false;
  const expiresAt = data.expiresAt?.toDate();
  if (!expiresAt) return true;
  return now <= expiresAt;
}
