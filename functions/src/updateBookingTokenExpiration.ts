import {onCall, HttpsError} from "firebase-functions/v2/https";
import {admin} from "./firebase";
import {logInfo, logError} from "./logger";
import {calculateTokenExpiration} from "./bookingAccessToken";
import {findBookingById} from "./utils/bookingLookup";

/**
 * Cloud Function: Update Booking Token Expiration
 *
 * Recalculates and updates the token_expires_at field for a booking
 * when the check-out date is changed. This ensures that access tokens
 * remain valid for the correct duration based on the updated check-out date.
 *
 * SECURITY: Only updates token expiration, does not regenerate the token itself.
 * The token hash remains the same, only expiration date changes.
 */
export const updateBookingTokenExpiration = onCall(async (request) => {
  const data = request.data;
  const {bookingId} = data;

  // Validate required fields
  if (!bookingId) {
    throw new HttpsError(
      "invalid-argument",
      "bookingId is required"
    );
  }

  try {
    logInfo("[UpdateBookingTokenExpiration] Updating token expiration", {
      bookingId,
    });

    // Find booking using helper (avoids FieldPath.documentId bug with collectionGroup)
    const bookingResult = await findBookingById(bookingId);

    if (!bookingResult) {
      throw new HttpsError("not-found", "Booking not found");
    }

    const bookingRef = bookingResult.doc.ref;
    const booking = bookingResult.data;

    // Check if booking has check-out date and access token
    if (!booking.check_out) {
      throw new HttpsError(
        "failed-precondition",
        "Booking does not have a check-out date"
      );
    }

    if (!booking.access_token) {
      // If no access token exists, there's nothing to update
      logInfo("[UpdateBookingTokenExpiration] Booking has no access token, skipping update", {
        bookingId,
      });
      return {success: true, message: "No access token to update"};
    }

    // Recalculate token expiration based on current check-out date
    const newExpiration = calculateTokenExpiration(booking.check_out);

    // Update token expiration
    await bookingRef.update({
      token_expires_at: newExpiration,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    logInfo("[UpdateBookingTokenExpiration] Token expiration updated successfully", {
      bookingId,
      newExpiration: newExpiration.toDate().toISOString(),
    });

    return {
      success: true,
      message: "Token expiration updated successfully",
      newExpiration: newExpiration.toDate().toISOString(),
    };
  } catch (error: unknown) {
    // Re-throw HttpsError as-is
    if (error instanceof HttpsError) {
      throw error;
    }

    // Log unexpected errors
    if (error instanceof Error) {
      logError("[UpdateBookingTokenExpiration] Unexpected error", {
        error: error.message,
        stack: error.stack,
        bookingId,
      });
      throw new HttpsError(
        "internal",
        "An unexpected error occurred while updating token expiration"
      );
    }

    // Fallback for unknown error types
    logError("[UpdateBookingTokenExpiration] Unknown error type", {
      error: String(error),
      bookingId,
    });
    throw new HttpsError(
      "internal",
      "An unexpected error occurred while updating token expiration"
    );
  }
});

