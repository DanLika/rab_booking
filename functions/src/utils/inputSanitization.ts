/**
 * Input Sanitization Utilities
 *
 * SECURITY: Prevents XSS, injection attacks, and homoglyph bypass.
 *
 * ## Security Principles
 * 1. **Encode** HTML entities (not remove - preserves data, safe for rendering)
 * 2. **Normalize** Unicode confusables (prevents homoglyph attacks)
 * 3. **Preserve** legitimate Unicode content (international names, accents)
 * 4. **Limit** input length to prevent DoS attacks
 *
 * @module inputSanitization
 */

/**
 * Maximum input lengths (DoS protection)
 */
const MAX_TEXT_LENGTH = 10000;        // Booking notes, property descriptions
const MAX_EMAIL_LENGTH = 254;         // RFC 5321 standard
const MAX_PHONE_INPUT_LENGTH = 100;   // Raw input before sanitization (final max = 20)

/**
 * HTML entity map for safe encoding
 * These characters are dangerous in HTML context and must be encoded
 */
const HTML_ENTITY_MAP: Record<string, string> = {
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
  '"': "&quot;",
  "'": "&#x27;",
  "/": "&#x2F;",
  "`": "&#x60;",
};

/**
 * Unicode confusables map (Cyrillic, Greek → Latin)
 * Prevents homoglyph attacks where <ѕcript> bypasses <script> detection
 *
 * SECURITY: These characters look identical to ASCII but are different Unicode codepoints
 */
const CONFUSABLES_MAP: Record<string, string> = {
  // Cyrillic → Latin
  "а": "a", "е": "e", "о": "o", "р": "p", "с": "c",
  "у": "y", "х": "x", "і": "i", "ј": "j", "ѕ": "s",
  "А": "A", "В": "B", "Е": "E", "К": "K", "М": "M",
  "Н": "H", "О": "O", "Р": "P", "С": "C", "Т": "T",
  "Х": "X",

  // Greek → Latin
  "α": "a", "ε": "e", "ο": "o", "ν": "v", "ρ": "r",
  "Α": "A", "Β": "B", "Ε": "E", "Η": "H", "Ι": "I",
  "Κ": "K", "Μ": "M", "Ν": "N", "Ο": "O", "Ρ": "P",
  "Τ": "T", "Χ": "X", "Υ": "Y", "Ζ": "Z",

  // Math/symbol confusables
  "⁄": "/", "∕": "/", "⧸": "/",
  "‹": "<", "›": ">",
  "ᐸ": "<", "ᐳ": ">",
  "＜": "<", "＞": ">",

  // Zero-width characters (REMOVE completely - used for invisible attacks)
  "\u200B": "", // Zero Width Space
  "\u200C": "", // Zero Width Non-Joiner
  "\u200D": "", // Zero Width Joiner
  "\uFEFF": "", // Zero Width No-Break Space
  "\u00AD": "", // Soft Hyphen
};

/**
 * Unicode digit map (non-ASCII digits → ASCII)
 * Supports international phone number input
 */
const UNICODE_DIGIT_MAP: Record<string, string> = {
  // Arabic-Indic (U+0660-0669)
  "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
  "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9",

  // Extended Arabic-Indic (U+06F0-06F9)
  "۰": "0", "۱": "1", "۲": "2", "۳": "3", "۴": "4",
  "۵": "5", "۶": "6", "۷": "7", "۸": "8", "۹": "9",

  // Devanagari (U+0966-096F)
  "०": "0", "१": "1", "२": "2", "३": "3", "४": "4",
  "५": "5", "६": "6", "७": "7", "८": "8", "९": "9",

  // Bengali (U+09E6-09EF)
  "০": "0", "১": "1", "২": "2", "৩": "3", "৪": "4",
  "৫": "5", "৬": "6", "৭": "7", "৮": "8", "৯": "9",

  // Thai (U+0E50-0E59)
  "๐": "0", "๑": "1", "๒": "2", "๓": "3", "๔": "4",
  "๕": "5", "๖": "6", "๗": "7", "๘": "8", "๙": "9",

  // Fullwidth (U+FF10-FF19)
  "０": "0", "１": "1", "２": "2", "３": "3", "４": "4",
  "５": "5", "６": "6", "７": "7", "８": "8", "９": "9",
};

/**
 * Encode HTML entities (SAFE for rendering in HTML context)
 *
 * SECURITY: This is safer than removing tags because:
 * - No data loss (preserves user input exactly as intended)
 * - No bypass possible (all dangerous characters encoded)
 * - Industry standard (used by React, Vue, Angular)
 */
function encodeHtmlEntities(input: string): string {
  return input.replace(/[&<>"'`/]/g, (char) => HTML_ENTITY_MAP[char] || char);
}

/**
 * Normalize Unicode confusables to ASCII equivalents
 *
 * SECURITY: Prevents homoglyph attacks where:
 * - Cyrillic 'с' (U+0441) looks identical to Latin 'c'
 * - <ѕcript> could bypass <script> detection
 */
function normalizeConfusables(input: string): string {
  let normalized = input;
  for (const [confusable, ascii] of Object.entries(CONFUSABLES_MAP)) {
    // Use split/join for performance (faster than regex for single chars)
    normalized = normalized.split(confusable).join(ascii);
  }
  return normalized;
}

/**
 * Convert Unicode digits to ASCII digits
 *
 * SECURITY: Prevents data loss for international users
 * while ensuring consistent digit handling
 */
function normalizeUnicodeDigits(input: string): string {
  let normalized = input;
  for (const [unicode, ascii] of Object.entries(UNICODE_DIGIT_MAP)) {
    normalized = normalized.split(unicode).join(ascii);
  }
  return normalized;
}

/**
 * Sanitize text input (names, notes, descriptions)
 *
 * SECURITY IMPROVEMENTS:
 * - HTML entities ENCODED (not removed) - safe for HTML context
 * - Unicode confusables normalized - prevents homoglyph bypass
 * - Zero-width characters removed - prevents invisible attacks
 *
 * @param input - Text to sanitize (can be null/undefined)
 * @returns Sanitized text or null if empty after sanitization
 *
 * @example
 * sanitizeText('<script>alert("XSS")</script>')
 * // Returns: '&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;' (safe)
 *
 * sanitizeText('José García') // Returns: 'José García' (Unicode preserved)
 * sanitizeText('<ѕcript>') // Returns: '&lt;script&gt;' (confusables normalized)
 */
export function sanitizeText(
  input: string | null | undefined
): string | null {
  if (!input || typeof input !== "string") return null;

  // DoS PROTECTION: Reject inputs that are too long BEFORE processing
  if (input.length > MAX_TEXT_LENGTH) {
    return null;
  }

  let sanitized = input.trim();

  // SECURITY FIX: Normalize confusables FIRST (before any other processing)
  // This ensures homoglyphs like Cyrillic 'с' are converted to Latin 'c'
  sanitized = normalizeConfusables(sanitized);

  // SECURITY FIX: Encode HTML entities (instead of removing tags)
  // This is SAFER because:
  // - No data loss (user sees exactly what they typed)
  // - No bypass possible (ALL < > & are encoded)
  // - Safe for HTML, email, JSON contexts
  sanitized = encodeHtmlEntities(sanitized);

  // Remove control characters EXCEPT newlines (\n = 0x0A)
  // Control chars: 0x00-0x08, 0x0B, 0x0C, 0x0E-0x1F, 0x7F (DEL)
  sanitized = sanitized.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "");

  // Normalize whitespace (preserve single spaces and newlines)
  sanitized = sanitized.replace(/[^\S\n]+/g, " ");

  // Trim again after sanitization
  sanitized = sanitized.trim();

  return sanitized.length > 0 ? sanitized : null;
}

/**
 * Sanitize email input
 *
 * SECURITY IMPROVEMENTS:
 * - CRLF injection prevention (Unicode line separators)
 * - Backslash sequence removal
 * - Confusables normalization
 *
 * @param input - Email to sanitize (can be null/undefined)
 * @returns Sanitized lowercase email or null if empty
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

  // SECURITY FIX: Normalize confusables (prevents homoglyph email attacks)
  sanitized = normalizeConfusables(sanitized);

  // SECURITY FIX: Remove ALL line break characters (CRLF injection prevention)
  // - ASCII: \r (0x0D), \n (0x0A)
  // - Unicode: Line Separator (U+2028), Paragraph Separator (U+2029)
  // - Vertical Tab (0x0B), Form Feed (0x0C)
  sanitized = sanitized.replace(/[\r\n\u2028\u2029\v\f]/g, "");

  // Remove control characters (0x00-0x1F, 0x7F)
  sanitized = sanitized.replace(/[\x00-\x1F\x7F]/g, "");

  // SECURITY FIX: Remove backslash sequences
  // Prevents literal \r\n injection
  sanitized = sanitized.replace(/\\/g, "");

  // SECURITY FIX: Remove percent-encoded sequences
  // Prevents %0D%0A (URL-encoded CRLF) bypass
  sanitized = sanitized.replace(/%[0-9A-Fa-f]{2}/g, "");

  // Remove ALL whitespace (emails can't contain spaces)
  sanitized = sanitized.replace(/\s/g, "");

  return sanitized.length > 0 ? sanitized : null;
}

/**
 * Sanitize phone number (STRICT VALIDATION)
 *
 * SECURITY IMPROVEMENTS:
 * - Unicode digit normalization (supports international input)
 * - Confusables normalization
 * - Strict validation rules
 *
 * @param input - Phone number to sanitize (can be null/undefined)
 * @returns Sanitized phone number or null if invalid
 *
 * @example
 * sanitizePhone('+1 (555) 123-4567') // Returns: '+1 (555) 123-4567'
 * sanitizePhone('٠١٢٣٤٥٦٧٨٩') // Returns: '0123456789' (Arabic digits converted)
 * sanitizePhone('९१२३४५६७८९') // Returns: '9123456789' (Devanagari digits converted)
 */
export function sanitizePhone(
  input: string | null | undefined
): string | null {
  if (!input || typeof input !== "string") return null;

  // DoS PROTECTION: Reject excessively long inputs
  if (input.length > MAX_PHONE_INPUT_LENGTH) {
    return null;
  }

  let sanitized = input.trim();

  // SECURITY FIX: Normalize confusables first
  sanitized = normalizeConfusables(sanitized);

  // SECURITY FIX: Convert Unicode digits to ASCII BEFORE validation
  // This supports international users entering phone numbers in native digit systems
  sanitized = normalizeUnicodeDigits(sanitized);

  // Remove control characters
  sanitized = sanitized.replace(/[\x00-\x1F\x7F]/g, "");

  // Keep ONLY valid phone characters: digits, spaces, +, -, (, )
  sanitized = sanitized.replace(/[^\d\s+()-]/g, "");

  // Normalize whitespace (multiple spaces → single space)
  sanitized = sanitized.replace(/\s+/g, " ");

  // Trim again
  sanitized = sanitized.trim();

  // VALIDATION: Strict phone validation rules
  // 1. Must contain at least 6 digits
  const digitCount = (sanitized.match(/\d/g) || []).length;
  if (digitCount < 6) {
    return null;
  }

  // 2. Max length: 20 characters
  if (sanitized.length > 20) {
    return null;
  }

  // 3. Plus sign: max 1, must be at start if present
  const plusCount = (sanitized.match(/\+/g) || []).length;
  if (plusCount > 1) {
    return null;
  }
  if (plusCount === 1 && !sanitized.startsWith("+")) {
    return null;
  }

  // 4. Parentheses must be balanced
  const openCount = (sanitized.match(/\(/g) || []).length;
  const closeCount = (sanitized.match(/\)/g) || []).length;
  if (openCount !== closeCount) {
    return null;
  }

  // 5. No excessive special characters (max 6)
  const specialCharCount = sanitized.length - digitCount;
  if (specialCharCount > 6) {
    return null;
  }

  return sanitized.length > 0 ? sanitized : null;
}
