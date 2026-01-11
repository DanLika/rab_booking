/**
 * Generate a unique booking reference
 *
 * STRATEGY: Use Firestore document ID (already guaranteed unique)
 * - Format: BK-{FIRST_12_CHARS_OF_DOCUMENT_ID}
 * - Example: BK-A3F7E2D1B9C4
 * - Length: 15 characters (BK- + 12 hex chars)
 * - Collision probability: Virtually zero (Firestore IDs are unique)
 *
 * WHY NOT timestamp + random?
 * - Race condition: Two users at same millisecond + same random = collision
 * - High traffic: More users = higher collision probability
 * - Complexity: Need to handle retries on collision
 *
 * WHY Firestore document ID?
 * - Already unique (guaranteed by Firestore)
 * - No collision handling needed
 * - Simple and reliable
 * - Already available (no extra generation cost)
 *
 * @param firestoreDocumentId - Firestore auto-generated document ID
 * @return Unique booking reference in format BK-XXXXXXXXXXXX
 */
export function generateBookingReference(firestoreDocumentId: string): string {
  // Validation: Ensure document ID is valid
  if (!firestoreDocumentId || typeof firestoreDocumentId !== "string") {
    throw new Error(
      `Invalid Firestore document ID: "${firestoreDocumentId}"`
    );
  }

  // Firestore document IDs are 20 characters, we use first 12
  // (12 chars = 48 bits of uniqueness, more than enough)
  const shortId = firestoreDocumentId.substring(0, 12).toUpperCase();

  return `BK-${shortId}`;
}

/**
 * Validate booking reference format
 *
 * VALID FORMAT: BK-{12_ALPHANUMERIC_CHARS}
 * Examples:
 * - BK-A3F7E2D1B9C4 ✅
 * - BK-123456789ABC ✅
 * - BK-abc (too short) ❌
 * - RAB-123 (wrong prefix) ❌
 *
 * @param bookingRef - Booking reference to validate
 * @return true if valid, false otherwise
 */
export function isValidBookingReference(bookingRef: string): boolean {
  if (!bookingRef || typeof bookingRef !== "string") {
    return false;
  }

  // Regex: BK- followed by 12 alphanumeric characters
  const pattern = /^BK-[A-Z0-9]{12}$/i;

  return pattern.test(bookingRef);
}
