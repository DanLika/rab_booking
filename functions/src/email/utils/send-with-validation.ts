/**
 * Resend Email Send with Result Validation
 *
 * The Resend SDK returns { data, error } - errors are NOT thrown as exceptions.
 * This helper ensures errors are properly detected and thrown.
 *
 * CRITICAL FIX: Without this validation, emails can silently fail (e.g., invalid API key)
 * while the code logs "success" because the SDK doesn't throw on API errors.
 */

import {Resend} from "resend";

export interface SendEmailOptions {
  from: string;
  to: string;
  subject: string;
  html: string;
  replyTo?: string;
}

/**
 * Send email via Resend with proper result validation
 *
 * @throws Error if Resend returns an error in the response
 * @returns The email ID from Resend on success
 */
export async function sendEmailWithValidation(
  resendClient: Resend,
  options: SendEmailOptions
): Promise<string | undefined> {
  const result = await resendClient.emails.send({
    from: options.from,
    to: options.to,
    subject: options.subject,
    html: options.html,
    ...(options.replyTo && {replyTo: options.replyTo}),
  });

  // Resend SDK returns { data, error } - check for error
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const typedResult = result as any;
  if (typedResult.error) {
    throw new Error(
      `Resend API error: ${typedResult.error.message || JSON.stringify(typedResult.error)}`
    );
  }

  // Return the email ID for logging/tracking
  return typedResult.data?.id;
}
