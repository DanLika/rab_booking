/**
 * Resend Email Send with Result Validation + Header Injection Guards
 *
 * The Resend SDK returns { data, error } - errors are NOT thrown as
 * exceptions. This helper ensures errors are properly detected and
 * thrown.
 *
 * Header-injection guards run BEFORE the HTTP call. See email-guards.ts
 * for the threat model + why CR/LF rejection still matters even though
 * the current wire format is HTTPS+JSON.
 *
 * CRITICAL FIX: Without this validation, emails can silently fail
 * (e.g., invalid API key) while the code logs "success" because the
 * SDK doesn't throw on API errors.
 */

import {Resend} from "resend";

import {
  assertSafeHeader,
  validateRecipient,
  validateRecipientList,
} from "./email-guards";

export interface SendEmailOptions {
  from: string;
  to: string | string[];
  subject: string;
  html: string;
  replyTo?: string;
}

/**
 * Send email via Resend with proper result validation
 *
 * @throws EmailHeaderInjectionError if subject / from / replyTo contain CR/LF
 * @throws InvalidRecipientError if `to` is not a syntactically clean address
 * @throws Error if Resend returns an error in the response
 * @return The email ID from Resend on success
 */
export async function sendEmailWithValidation(
  resendClient: Resend,
  options: SendEmailOptions
): Promise<string | undefined> {
  // ------------------------------------------------------------------
  // Header-injection guards (LDS parity — see email-guards.ts).
  // ------------------------------------------------------------------
  // `from` is the display-formatted `"Name" <email@host>` string built by
  // each template — header value, not a bare recipient. Reject CR/LF in
  // it; a bare-email shape check would over-reject the display form.
  assertSafeHeader(options.from, "from");

  // `to` is either a single bare email or an array. Bookbed templates
  // pass single guest emails (`params.guestEmail`) today; the array
  // branch covers a future bulk-send call site.
  if (Array.isArray(options.to)) {
    validateRecipientList(options.to, "to");
  } else {
    validateRecipient(options.to, "to");
  }

  // Subject is operator-controllable in some flows (`custom-email.ts`
  // passes `params.subject` straight from operator input). Always
  // CRLF-guard.
  assertSafeHeader(options.subject, "subject");

  // `replyTo` is optional. When present in current templates it's a
  // bare email (`params.ownerEmail || fromEmail`), so strict recipient
  // validation is right.
  if (options.replyTo !== undefined) {
    validateRecipient(options.replyTo, "replyTo");
  }

  // HTML body intentionally NOT scrubbed — it's the message payload,
  // not a header value. CR/LF inside <body> is rendered as whitespace.

  // ------------------------------------------------------------------
  // Resend dispatch + result validation.
  // ------------------------------------------------------------------
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
    const detail = typedResult.error.message ||
      JSON.stringify(typedResult.error);
    throw new Error(`Resend API error: ${detail}`);
  }

  // Return the email ID for logging/tracking
  return typedResult.data?.id;
}
