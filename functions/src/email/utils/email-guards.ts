/**
 * Email header-injection + recipient-shape guards.
 *
 * Mirrors the LDS `src/integrations/email_sender.py` boundary (see
 * `tests/test_crlf_injection.py` for the locked-in payload corpus).
 *
 * Today bookbed sends through the Resend HTTPS API, which serializes
 * field values through JSON — so CR/LF inside a string value cannot
 * directly become a SMTP header on the current wire path. The guards
 * still hold for three reasons:
 *
 *  1. A future direct-SMTP swap (`nodemailer`, a self-hosted MTA) would
 *     reintroduce header smuggling instantly. The guard means that swap
 *     doesn't have to also remember to add the regex.
 *  2. Operator logs frequently include the subject + recipient verbatim
 *     (`logSuccess(..., {email})`); a CR/LF-bearing subject smuggles a
 *     fake log line at attacker-chosen level — see
 *     `src/utils/logging_config._CRLFScrubFilter` for the LDS pattern.
 *  3. A hypothetical Resend bug that re-encodes a JSON string as a raw
 *     MIME header value is contained by the same guard.
 *
 * Mental model: these are header-bound free-text fields. CR/LF MUST NOT
 * appear in them regardless of how they happen to be transmitted today.
 */

// Anchored, no @, no whitespace on either side of the @ — same shape as
// LDS `^[^@\s]+@[^@\s]+\.[^@\s]+\Z`. JS regex differs from Python in one
// useful way: with the `m` flag OFF (the default for `/.../`), `$`
// matches strict end-of-input and does NOT match before a trailing `\n`
// the way Python `$` does. So `victim@x.com\n` is rejected even with
// `$`. We still write the regex defensively (anchored, no `m`) so a
// future maintainer who adds `m` for unrelated reasons doesn't open the
// hole.
const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

// CR, LF, VT, FF, plus the rare Unicode line terminators NEL (U+0085),
// LS (U+2028), PS (U+2029). Some HTTP libs split on VT/FF. Built from a
// string literal so the Unicode codepoints stay as escapes in source
// instead of becoming raw line terminators (which would itself be a
// parse error).
const HEADER_FORBIDDEN = new RegExp(
  "[\\r\\n\\v\\f\\u0085\\u2028\\u2029]",
  "u"
);

export class EmailHeaderInjectionError extends Error {
  constructor(fieldName: string) {
    super(
      `${fieldName} contains a forbidden newline / control character — ` +
        "possible header injection."
    );
    this.name = "EmailHeaderInjectionError";
  }
}

export class InvalidRecipientError extends Error {
  constructor(fieldName: string, value: unknown) {
    super(
      `${fieldName} is not a valid recipient email: ` +
        JSON.stringify(String(value))
    );
    this.name = "InvalidRecipientError";
  }
}

/**
 * Throw on any CR / LF / VT / FF / NEL / LS / PS in a header-bound
 * free-text field. Use on Subject, From (when display-formatted),
 * from-name, reply-to display, X-* custom headers, etc.
 *
 * Treats empty / non-string as a violation too — a falsy header value
 * almost certainly indicates a programmer error upstream, and silently
 * passing `undefined` to Resend would emit a `undefined` MIME header.
 */
export function assertSafeHeader(value: unknown, fieldName: string): void {
  if (typeof value !== "string" || value.length === 0) {
    throw new EmailHeaderInjectionError(fieldName);
  }
  if (HEADER_FORBIDDEN.test(value)) {
    throw new EmailHeaderInjectionError(fieldName);
  }
}

/**
 * Validate a bare email address (no display name, no angle brackets).
 * Use on `to`, `replyTo` when those are bare emails.
 *
 * For a `From` field formatted as `"Display Name" <email@host>`, use
 * `assertSafeHeader` on the whole string instead — display-name +
 * angle-bracket format is a header value, not a recipient.
 */
export function validateRecipient(value: unknown, fieldName: string): void {
  if (typeof value !== "string") {
    throw new InvalidRecipientError(fieldName, value);
  }
  // NEL (U+0085) is NOT in JS regex `\s` (unlike Python's Unicode `\s`
  // which DOES include it). Strip every header-forbidden codepoint
  // explicitly before falling through to the email shape check, so the
  // exclusion class is identical regardless of which surface a guard
  // call lands on.
  if (HEADER_FORBIDDEN.test(value)) {
    throw new InvalidRecipientError(fieldName, value);
  }
  if (!EMAIL_PATTERN.test(value)) {
    throw new InvalidRecipientError(fieldName, value);
  }
}

/**
 * Validate every recipient in an array. Resend accepts `to: string[]`
 * as well as `to: string`. Empty arrays are rejected — a programmer
 * almost never wants to send to zero recipients.
 */
export function validateRecipientList(
  values: unknown,
  fieldName: string
): void {
  if (!Array.isArray(values) || values.length === 0) {
    throw new InvalidRecipientError(fieldName, values);
  }
  for (let i = 0; i < values.length; i++) {
    validateRecipient(values[i], `${fieldName}[${i}]`);
  }
}
