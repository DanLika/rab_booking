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
 *
 * @module inputSanitization
 */

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
 * - Minimum 7 digits (shortest valid phone)
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
 * sanitizePhone('123')
 * // Returns: null (too few digits)
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
  // 1. Must contain at least 7 digits (shortest valid international number)
  const digitCount = (sanitized.match(/\d/g) || []).length;
  if (digitCount < 7) {
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

/**
 * Check if text contains potentially dangerous patterns
 *
 * Detects:
 * - Script tags
 * - JavaScript event handlers (onclick, onerror, etc.)
 * - SQL keywords (SELECT, INSERT, UPDATE, DELETE, etc.)
 * - NoSQL operators ($where, $ne, $gt, etc.)
 *
 * ## Use Case
 * Use for additional validation AFTER sanitization:
 * ```typescript
 * const sanitized = sanitizeText(input);
 * if (containsDangerousContent(sanitized)) {
 *   throw new HttpsError('invalid-argument', 'Input contains dangerous patterns');
 * }
 * ```
 *
 * @param input - Text to check (can be null/undefined)
 * @returns true if dangerous patterns detected, false otherwise
 *
 * @example
 * containsDangerousContent('<script>alert("XSS")</script>')
 * // Returns: true (script tag detected)
 *
 * containsDangerousContent('onclick="alert(1)"')
 * // Returns: true (event handler detected)
 *
 * containsDangerousContent('SELECT * FROM users')
 * // Returns: true (SQL keyword detected)
 *
 * containsDangerousContent('Hello World')
 * // Returns: false (safe content)
 */
export function containsDangerousContent(
  input: string | null | undefined
): boolean {
  if (!input || typeof input !== "string") return false;

  const lower = input.toLowerCase();

  // Check for script tags
  if (/<script[^>]*>[\s\S]*?<\/script>/i.test(lower)) return true;

  // Check for JavaScript event handlers
  if (
    lower.includes("javascript:") ||
    lower.includes("onerror=") ||
    lower.includes("onload=") ||
    lower.includes("onclick=") ||
    lower.includes("onmouseover=")
  ) {
    return true;
  }

  // Check for SQL keywords (case-insensitive)
  if (
    /\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|EXECUTE|UNION|WHERE)\b/i.test(
      input
    )
  ) {
    return true;
  }

  // Check for NoSQL operators (MongoDB, Firestore)
  if (
    lower.includes("$where") ||
    lower.includes("$ne") ||
    lower.includes("$gt") ||
    lower.includes("$lt") ||
    lower.includes("$regex")
  ) {
    return true;
  }

  return false;
}
