import {onCall, HttpsError} from "firebase-functions/v2/https";
import {db} from "./firebase";
import {logInfo, logError, logWarn} from "./logger";
import {verifyAccessToken} from "./bookingAccessToken";
import {setUser} from "./sentry";
import {safeToDate} from "./utils/dateValidation";

/**
 * Cloud Function: Verify Booking Access
 *
 * Verifies user access to booking details using:
 * 1. Booking reference + Email + Access token (from email link)
 * 2. Booking reference + Email only (manual lookup)
 *
 * Returns sanitized booking details if verification succeeds.
 */
export const verifyBookingAccess = onCall(async (request) => {
  const data = request.data;

  const {
    bookingReference,
    email,
    accessToken,
    stripeSessionId,
  } = data;

  // Set user context for Sentry error tracking (guest action - use email)
  setUser(null, email || null);

  // Validate required fields
  // Allow access via:
  // 1. stripeSessionId (Payment return)
  // 2. bookingReference + email (Manual lookup)
  // 3. bookingReference + accessToken (Magic link)
  if (!stripeSessionId && (!bookingReference || (!email && !accessToken))) {
    throw new HttpsError(
      "invalid-argument",
      "Valid credentials required (Reference+Email, Reference+Token, or SessionID)"
    );
  }

  try {
    logInfo("[VerifyBookingAccess] Attempting to verify access", {
      bookingReference,
      email: email ? email.substring(0, 3) + "***" : "none", // Log partial email for privacy
      hasToken: !!accessToken,
      hasSessionId: !!stripeSessionId,
    });

    let bookingsSnapshot;

    if (stripeSessionId) {
      // Lookup by Stripe Session ID (Secure capability token)
      bookingsSnapshot = await db
        .collectionGroup("bookings")
        .where("stripe_session_id", "==", stripeSessionId)
        .limit(1)
        .get();
    } else {
      // Lookup by Reference
      bookingsSnapshot = await db
        .collectionGroup("bookings")
        .where("booking_reference", "==", bookingReference)
        .limit(1)
        .get();
    }

    if (bookingsSnapshot.empty) {
      logWarn("[VerifyBookingAccess] Booking not found", {
        bookingReference,
        hasSessionId: !!stripeSessionId,
      });
      // Generic error to prevent enumeration
      throw new HttpsError(
        "permission-denied",
        "Invalid credentials or booking not found."
      );
    }

    const bookingDoc = bookingsSnapshot.docs[0];
    const booking = bookingDoc.data();
    const isSessionAuth = !!stripeSessionId;
    let isTokenAuth = false;

    // AUTHENTICATION CHECK
    if (isSessionAuth) {
      // Stripe Session ID is sufficient proof of access (Capability Token)
      logInfo("[VerifyBookingAccess] Authenticated via Stripe Session ID");
    } else if (accessToken) {
      // Token Authentication (Magic Link)
      if (!booking.access_token) {
        logWarn("[VerifyBookingAccess] Booking has no access token configured", {bookingReference});
        // Fallback to email check if token system not active for this booking
      } else {
        const isTokenValid = verifyAccessToken(accessToken, booking.access_token);
        if (!isTokenValid) {
          logWarn("[VerifyBookingAccess] Invalid access token", {bookingReference});
          throw new HttpsError("permission-denied", "Invalid access link.");
        }

        // Check expiration
        if (booking.token_expires_at) {
          const now = new Date();
          const expiresAt = booking.token_expires_at.toDate();
          if (now > expiresAt) {
            logWarn("[VerifyBookingAccess] Token expired", {bookingReference});
            throw new HttpsError("permission-denied", "Access link expired.");
          }
        }
        isTokenAuth = true;
      }
    }

    // If not authenticated via Session or Token, enforce Email check
    if (!isSessionAuth && !isTokenAuth) {
      if (!email || booking.guest_email.toLowerCase() !== email.toLowerCase()) {
        logWarn("[VerifyBookingAccess] Email mismatch or missing", {
          bookingReference,
          attemptedEmail: email ? email.substring(0, 3) + "***" : "none",
        });
        // Generic error to prevent enumeration
        throw new HttpsError(
          "permission-denied",
          "Invalid credentials or booking not found."
        );
      }
    }

    // Get property and unit details for complete info
    const propertyDoc = await db.collection("properties")
      .doc(booking.property_id)
      .get();
    const property = propertyDoc.data();

    // NOTE: Units are stored as subcollection: properties/{propertyId}/units/{unitId}
    const unitDoc = await db
      .collection("properties")
      .doc(booking.property_id)
      .collection("units")
      .doc(booking.unit_id)
      .get();
    const unit = unitDoc.data();

    // Fetch owner company details for bank transfer payments
    let bankDetails = null;
    if (booking.payment_method === "bank_transfer" && booking.owner_id) {
      const companyDoc = await db
        .collection("users")
        .doc(booking.owner_id)
        .collection("data")
        .doc("company")
        .get();

      if (companyDoc.exists) {
        const company = companyDoc.data();
        // Only include bank details if owner has configured them
        if (company?.bankAccountIban) {
          bankDetails = {
            bankName: company.bankName || null,
            accountHolder: company.accountHolder || null,
            iban: company.bankAccountIban,
            swift: company.swift || null,
          };
        }
      }
    }

    // Calculate nights
    const checkIn = safeToDate(booking.check_in, "check_in");
    const checkOut = safeToDate(booking.check_out, "check_out");
    const nights = Math.ceil(
      (checkOut.getTime() - checkIn.getTime()) / (1000 * 60 * 60 * 24)
    );

    // Return sanitized booking details
    const bookingDetails = {
      bookingId: bookingDoc.id,
      bookingReference: booking.booking_reference,
      propertyId: booking.property_id || null,
      unitId: booking.unit_id || null,
      propertyName: property?.name || "Property",
      unitName: unit?.name || "Unit",
      guestName: booking.guest_name,
      guestEmail: booking.guest_email,
      guestPhone: booking.guest_phone || null,
      checkIn: checkIn.toISOString(),
      checkOut: checkOut.toISOString(),
      nights: nights,
      // Handle both formats: int (legacy) or object {adults, children}
      guestCount: typeof booking.guest_count === "number" ?
        {adults: booking.guest_count, children: 0} :
        (booking.guest_count || {adults: 1, children: 0}),
      totalPrice: booking.total_price,
      depositAmount: booking.deposit_amount || booking.advance_amount || 0,
      remainingAmount: booking.remaining_amount || 0,
      paidAmount: booking.paid_amount || 0,
      paymentStatus: booking.payment_status,
      paymentMethod: booking.payment_method,
      status: booking.status,
      ownerEmail: property?.owner_email || null,
      ownerPhone: property?.owner_phone || null,
      notes: booking.notes || null,
      createdAt: booking.created_at ?
        safeToDate(booking.created_at, "created_at").toISOString() : null,
      paymentDeadline: booking.payment_deadline ?
        safeToDate(booking.payment_deadline, "payment_deadline").toISOString() :
        null,
      bankDetails: bankDetails,
    };

    logInfo("[VerifyBookingAccess] Access verified successfully", {
      bookingReference,
      bookingId: bookingDoc.id,
    });

    return {
      success: true,
      booking: bookingDetails,
    };
  } catch (error: unknown) {
    // Re-throw HttpsError as-is
    if (error instanceof HttpsError) {
      throw error;
    }

    // Log unexpected errors
    if (error instanceof Error) {
      logError("[VerifyBookingAccess] Unexpected error", {
        error: error.message,
        stack: error.stack,
      });
    }

    throw new HttpsError(
      "internal",
      "Failed to verify booking access. Please try again."
    );
  }
});
