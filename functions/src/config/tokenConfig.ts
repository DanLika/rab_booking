/**
 * Centralized configuration for booking access tokens
 *
 * SECURITY CONFIGURATION:
 * - Token generation uses cryptographically secure random bytes
 * - SHA-256 hashing for storage (prevents token leakage from DB)
 * - Strict validation rules to minimize attack surface
 */

export const TOKEN_CONFIG = {
  // ========================================================================
  // TOKEN GENERATION
  // ========================================================================

  /**
   * Number of random bytes for token generation
   * 32 bytes = 256 bits of entropy (cryptographically secure)
   */
  TOKEN_BYTES: 32,

  /**
   * Encoding for token output
   * base64url = URL-safe, no padding, filesystem-safe
   */
  TOKEN_ENCODING: "base64url" as const,

  /**
   * Expected token length after encoding
   * 32 bytes in base64url = exactly 43 characters
   * Formula: ceil(bytes * 8 / 6) = ceil(32 * 8 / 6) = 43
   */
  EXPECTED_TOKEN_LENGTH: 43,

  // ========================================================================
  // TOKEN EXPIRATION
  // ========================================================================

  /**
   * Token expiration period (days after checkout)
   * Default: 30 days
   * Rationale: Balance between security and guest convenience
   */
  EXPIRATION_DAYS: 30,

  /**
   * Extended expiration for old bookings (days)
   * For bookings where checkout date is in the past
   * 3650 days = ~10 years (allows guests to access historical bookings)
   */
  EXTENDED_EXPIRATION_DAYS: 3650,

  // ========================================================================
  // HASH CONFIGURATION
  // ========================================================================

  /**
   * Hashing algorithm
   * SHA-256 provides strong security without excessive performance cost
   */
  HASH_ALGORITHM: "sha256" as const,

  /**
   * Expected hash length in hexadecimal
   * SHA-256 = 256 bits = 64 hex characters
   */
  HASH_LENGTH: 64,

  /**
   * Regex for validating hex hash format
   * Must be exactly 64 hexadecimal characters [0-9a-f]
   */
  HASH_REGEX: /^[0-9a-f]{64}$/i,

  // ========================================================================
  // VALIDATION
  // ========================================================================

  /**
   * Regex for validating base64url token format
   * base64url charset: A-Z, a-z, 0-9, -, _
   * No padding (=) characters
   */
  BASE64URL_REGEX: /^[A-Za-z0-9_-]+$/,

  /**
   * Minimum token length (strict validation)
   * Set equal to EXPECTED_TOKEN_LENGTH to reject malformed tokens early
   */
  MIN_TOKEN_LENGTH: 43,

  /**
   * Maximum token length (strict validation)
   * Set equal to EXPECTED_TOKEN_LENGTH to reject malformed tokens early
   */
  MAX_TOKEN_LENGTH: 43,
} as const;

/**
 * Type-safe access to token config values
 */
export type TokenConfig = typeof TOKEN_CONFIG;
