/**
 * Email Validation Utilities
 *
 * RFC-compliant email validation with TLD (Top Level Domain) requirement.
 * Replaces weak validation patterns throughout the codebase.
 *
 * @module emailValidation
 */

/**
 * Robust email regex pattern (RFC-compliant with TLD requirement)
 *
 * Pattern breakdown:
 * - `^` - Start of string
 * - `[a-zA-Z0-9._%+-]+` - Local part (before @): alphanumeric + special chars
 * - `@` - Required @ symbol
 * - `[a-zA-Z0-9.-]+` - Domain part: alphanumeric + dots, hyphens
 * - `\.` - Required dot before TLD
 * - `[a-zA-Z]{2,}` - TLD: at least 2 letters (e.g., .com, .co, .museum)
 * - `$` - End of string
 *
 * Valid examples:
 * - test@example.com ✓
 * - user.name+tag@domain.co.uk ✓
 * - info@subdomain.example.org ✓
 *
 * Invalid examples:
 * - test@test (no TLD) ✗
 * - test@test.c (TLD too short) ✗
 * - test..name@test.com (consecutive dots) ✗
 * - test @test.com (space) ✗
 */
export const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

/**
 * Validate email address with RFC compliance
 *
 * Performs comprehensive validation:
 * 1. Type and null checks
 * 2. Regex pattern matching (structure, TLD requirement)
 * 3. Additional security checks (consecutive dots)
 *
 * @param email - Email address to validate
 * @returns true if email is valid, false otherwise
 *
 * @example
 * validateEmail('test@example.com')     // true
 * validateEmail('user@domain.co.uk')    // true
 * validateEmail('test@test')            // false (no TLD)
 * validateEmail('test..name@test.com')  // false (consecutive dots)
 * validateEmail('invalid@')             // false (incomplete domain)
 * validateEmail(null)                   // false
 * validateEmail('')                     // false
 */
export function validateEmail(email: string | null | undefined): boolean {
  // Null/undefined check
  if (!email || typeof email !== "string") {
    return false;
  }

  const trimmed = email.trim();

  // Empty string check
  if (trimmed.length === 0) {
    return false;
  }

  // Regex pattern check (structure + TLD)
  if (!EMAIL_REGEX.test(trimmed)) {
    return false;
  }

  // Security check: no consecutive dots (prevents attacks like test..@test.com)
  if (trimmed.includes("..")) {
    return false;
  }

  // Length validation (RFC 5321: max 254 characters)
  if (trimmed.length > 254) {
    return false;
  }

  return true;
}
