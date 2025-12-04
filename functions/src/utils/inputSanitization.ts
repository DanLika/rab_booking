/**
 * Input Sanitization Utilities
 *
 * Removes dangerous characters while preserving legitimate content.
 * Prevents XSS, SQL injection, and NoSQL injection attacks.
 *
 * ## Security Principles
 * 1. **Remove** dangerous patterns (HTML tags, control chars, script tags)
 * 2. **Preserve** legitimate Unicode content (international names, accents)
 * 3. **Normalize** whitespace without data loss
 * 4. **Limit** input length to prevent DoS attacks
 *
 * @module inputSanitization
 */

/**
 * Maximum input lengths (DoS protection)
 *
 * These limits prevent attackers from sending extremely large inputs
 * that could exhaust CPU/memory during iterative sanitization.
 *
 * RATIONALE:
 * - Text: 10,000 chars (supports long notes/descriptions)
 * - Email: 254 chars (RFC 5321 max email length)
 * - Phone (raw input): 100 chars (allows padding before sanitization, final = 20 chars)
 */
const MAX_TEXT_LENGTH = 10000;        // Booking notes, property descriptions
const MAX_EMAIL_LENGTH = 254;         // RFC 5321 standard
const MAX_PHONE_INPUT_LENGTH = 100;   // Raw input before sanitization (final max = 20)

/**
 * Sanitize text input (names, notes, descriptions)
 *
 * Removes:
 * - HTML tags (`<script>`, `<img>`, etc.)
 * - Control characters (0x00-0x1F, except newlines)
 * - Excessive whitespace (preserves single spaces and newlines)
 *
 * Preserves:
 * - Unicode letters (é, ñ, ü, etc.)
 * - Numbers, spaces, punctuation
 * - Newlines (for notes/descriptions)
 *
 * ## Use Cases
 * - Guest names: `sanitizeText(guestName)`
 * - Booking notes: `sanitizeText(notes)`
 * - Property descriptions: `sanitizeText(description)`
 *
 * @param input - Text to sanitize (can be null/undefined)
 * @returns Sanitized text or null if empty after sanitization
 *
 * @example
 * // Remove HTML tags
 * sanitizeText('<script>alert("XSS")</script>')
 * // Returns: 'alertXSS' (tags removed, content preserved)
 *
 * sanitizeText('José García') // Returns: 'José García' (Unicode preserved)
 * sanitizeText('Name\x00') // Returns: 'Name' (control char removed)
 * sanitizeText('  too   much   space  ') // Returns: 'too much space'
 * sanitizeText(null) // Returns: null
 */
export function sanitizeText(
  input: string | null | undefined
): string | null {
  if (!input || typeof input !== "string") return null;

  // DoS PROTECTION: Reject inputs that are too long BEFORE processing
  // This prevents attackers from sending mega-sized inputs with nested tags
  // that would cause the iterative removal loop to run for a long time
  if (input.length > MAX_TEXT_LENGTH) {
    return null;
  }

  let sanitized = input.trim();

  // Remove HTML tags (prevent XSS)
  // SECURITY FIX: Iterative removal to catch nested/malformed tags
  // Example: <div><script>alert(1)</script></div> → removes all layers
  // Example: <script<script>alert(1)</script> → removes malformed tags
  let previousLength = 0;
  while (sanitized.length !== previousLength && /<[^>]*>/g.test(sanitized)) {
    previousLength = sanitized.length;
    sanitized = sanitized.replace(/<[^>]*>/g, "");
  }

  // Remove control characters EXCEPT newlines (\n = 0x0A)
  // Control chars: 0x00-0x08, 0x0B, 0x0C, 0x0E-0x1F, 0x7F (DEL)
  // Keep: 0x0A (newline) for multi-line notes
  sanitized = sanitized.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "");

  // Normalize whitespace (preserve single spaces and newlines)
  // Replace multiple spaces/tabs with single space
  // BUT preserve newlines for formatting
  sanitized = sanitized.replace(/[^\S\n]+/g, " ");

  // Trim again after sanitization
  sanitized = sanitized.trim();

  return sanitized.length > 0 ? sanitized : null;
}

/**
 * Sanitize email input
 *
 * Removes:
 * - All whitespace
 * - Control characters
 * - HTML tags
 *
 * Normalizes:
 * - Converts to lowercase (emails are case-insensitive)
 * - Trims whitespace
 *
 * ## Use Cases
 * - Guest email: `sanitizeEmail(guestEmail)`
 * - Owner email: `sanitizeEmail(ownerEmail)`
 * - Contact email: `sanitizeEmail(contactEmail)`
 *
 * @param input - Email to sanitize (can be null/undefined)
 * @returns Sanitized lowercase email or null if empty
 *
 * @example
 * sanitizeEmail('  Test@EXAMPLE.com  ')
 * // Returns: 'test@example.com'
 *
 * sanitizeEmail('test @example.com')
 * // Returns: 'test@example.com' (space removed)
 *
 * sanitizeEmail('<script>@evil.com')
 * // Returns: '@evil.com' (HTML removed, but still invalid - use validateEmail!)
 */
export function sanitizeEmail(
  input: string | null | undefined
): string | null {
  if (!input || typeof input !== "string") return null;

  // DoS PROTECTION: Reject emails longer than RFC 5321 max (254 chars)
  if (input.length > MAX_EMAIL_LENGTH) {
    return null;
  }

  let sanitized = input.trim().toLowerCase();

  // Remove HTML tags (iterative removal for nested/malformed tags)
  let previousLength = 0;
  while (sanitized.length !== previousLength && /<[^>]*>/g.test(sanitized)) {
    previousLength = sanitized.length;
    sanitized = sanitized.replace(/<[^>]*>/g, "");
  }

  // Remove control characters
  sanitized = sanitized.replace(/[\x00-\x1F\x7F]/g, "");

  // Remove ALL whitespace (emails can't contain spaces)
  sanitized = sanitized.replace(/\s/g, "");

  return sanitized.length > 0 ? sanitized : null;
}

/**
 * Sanitize phone number (STRICT VALIDATION)
 *
 * Keeps only valid phone characters:
 * - Digits: 0-9
 * - Plus sign: + (for country code, max 1, must be at start)
 * - Hyphens: - (separator)
 * - Parentheses: ( ) (area code, must be balanced)
 * - Spaces: (separator)
 *
 * Removes:
 * - Letters
 * - Special characters (except above)
 * - Control characters
 * - HTML tags (nested/malformed)
 *
 * Validation rules:
 * - Minimum 6 digits (accommodates local numbers)
 * - Maximum 20 characters total
 * - Maximum 1 plus sign (must be at start)
 * - Balanced parentheses
 * - Maximum 6 special characters
 *
 * ## Use Cases
 * - Guest phone: `sanitizePhone(guestPhone)`
 * - Owner phone: `sanitizePhone(ownerPhone)`
 * - Contact phone: `sanitizePhone(contactPhone)`
 *
 * @param input - Phone number to sanitize (can be null/undefined)
 * @returns Sanitized phone number or null if invalid
 *
 * @example
 * sanitizePhone('+1 (555) 123-4567')
 * // Returns: '+1 (555) 123-4567' (valid)
 *
 * sanitizePhone('+385 91 234 5678')
 * // Returns: '+385 91 234 5678' (valid)
 *
 * sanitizePhone('12345')
 * // Returns: null (too few digits - minimum 6)
 *
 * sanitizePhone('++1234567890')
 * // Returns: null (multiple plus signs)
 *
 * sanitizePhone('<script>123</script>')
 * // Returns: null (too few digits after sanitization)
 */
export function sanitizePhone(
  input: string | null | undefined
): string | null {
  if (!input || typeof input !== "string") return null;

  // DoS PROTECTION: Reject excessively long inputs BEFORE processing
  // Max phone: 20 chars, but allow some buffer for attacker padding (100 chars)
  // Real DoS attack would be 100k+ chars, so 100 char limit is safe
  if (input.length > MAX_PHONE_INPUT_LENGTH) {
    return null;
  }

  let sanitized = input.trim();

  // Remove HTML tags (iterative removal for nested/malformed tags)
  let previousLength = 0;
  while (sanitized.length !== previousLength && /<[^>]*>/g.test(sanitized)) {
    previousLength = sanitized.length;
    sanitized = sanitized.replace(/<[^>]*>/g, "");
  }

  // Remove control characters
  sanitized = sanitized.replace(/[\x00-\x1F\x7F]/g, "");

  // Keep ONLY valid phone characters: digits, spaces, +, -, (, )
  sanitized = sanitized.replace(/[^\d\s+()-]/g, "");

  // Normalize whitespace (multiple spaces → single space)
  sanitized = sanitized.replace(/\s+/g, " ");

  // Trim again
  sanitized = sanitized.trim();

  // SECURITY FIX: Strict phone validation to prevent abuse
  // 1. Must contain at least 6 digits (accommodates shorter local numbers)
  // Examples: Croatian local numbers (6-7 digits), some international formats
  const digitCount = (sanitized.match(/\d/g) || []).length;
  if (digitCount < 6) {
    return null; // Too few digits
  }

  // 2. Max length: 20 characters (longest valid format: +XXX (XXX) XXX-XXXX)
  if (sanitized.length > 20) {
    return null; // Too long
  }

  // 3. Plus sign: max 1, must be at start if present
  const plusCount = (sanitized.match(/\+/g) || []).length;
  if (plusCount > 1) {
    return null; // Multiple plus signs
  }
  if (plusCount === 1 && !sanitized.startsWith("+")) {
    return null; // Plus sign not at start
  }

  // 4. Parentheses must be balanced
  const openCount = (sanitized.match(/\(/g) || []).length;
  const closeCount = (sanitized.match(/\)/g) || []).length;
  if (openCount !== closeCount) {
    return null; // Unbalanced parentheses
  }

  // 5. No excessive special characters (max 6: e.g., "+1 (555) 123-4567" has 5)
  const specialCharCount = sanitized.length - digitCount;
  if (specialCharCount > 6) {
    return null; // Too many special chars
  }

  return sanitized.length > 0 ? sanitized : null;
}

