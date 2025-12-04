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
  // Matches: <any-tag>, <any-tag attr="value">, </any-tag>
  sanitized = sanitized.replace(/<[^>]*>/g, "");

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

  // Remove HTML tags
  sanitized = sanitized.replace(/<[^>]*>/g, "");

  // Remove control characters
  sanitized = sanitized.replace(/[\x00-\x1F\x7F]/g, "");

  // Remove ALL whitespace (emails can't contain spaces)
  sanitized = sanitized.replace(/\s/g, "");

  return sanitized.length > 0 ? sanitized : null;
}

/**
 * Sanitize phone number
 *
 * Keeps only valid phone characters:
 * - Digits: 0-9
 * - Plus sign: + (for country code)
 * - Hyphens: - (separator)
 * - Parentheses: ( ) (area code)
 * - Spaces: (separator)
 *
 * Removes:
 * - Letters
 * - Special characters (except above)
 * - Control characters
 * - HTML tags
 *
 * ## Use Cases
 * - Guest phone: `sanitizePhone(guestPhone)`
 * - Owner phone: `sanitizePhone(ownerPhone)`
 * - Contact phone: `sanitizePhone(contactPhone)`
 *
 * @param input - Phone number to sanitize (can be null/undefined)
 * @returns Sanitized phone number or null if empty
 *
 * @example
 * sanitizePhone('+1 (555) 123-4567')
 * // Returns: '+1 (555) 123-4567' (preserved)
 *
 * sanitizePhone('+385 91 234 5678')
 * // Returns: '+385 91 234 5678' (preserved)
 *
 * sanitizePhone('call me: 555-1234')
 * // Returns: ' 555-1234' (letters removed)
 *
 * sanitizePhone('<script>123</script>')
 * // Returns: '123' (HTML removed)
 */
export function sanitizePhone(
  input: string | null | undefined
): string | null {
  if (!input || typeof input !== "string") return null;

  let sanitized = input.trim();

  // Remove HTML tags
  sanitized = sanitized.replace(/<[^>]*>/g, "");

  // Remove control characters
  sanitized = sanitized.replace(/[\x00-\x1F\x7F]/g, "");

  // Keep ONLY valid phone characters: digits, spaces, +, -, (, )
  sanitized = sanitized.replace(/[^\d\s+()-]/g, "");

  // Normalize whitespace (multiple spaces → single space)
  sanitized = sanitized.replace(/\s+/g, " ");

  // Trim again
  sanitized = sanitized.trim();

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
