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
  } = data;

  // Set user context for Sentry error tracking (guest action - use email)
  setUser(null, email || null);

  // Validate required fields
  if (!bookingReference || !email) {
    throw new HttpsError(
      "invalid-argument",
      "Booking reference and email are required"
    );
  }

  try {
    logInfo("[VerifyBookingAccess] Attempting to verify access", {
      bookingReference,
      email: email.substring(0, 3) + "***", // Log partial email for privacy
      hasToken: !!accessToken,
    });

    // NEW STRUCTURE: Query booking by reference using collection group
    const bookingsSnapshot = await db
      .collectionGroup("bookings")
      .where("booking_reference", "==", bookingReference)
      .limit(1)
      .get();

    if (bookingsSnapshot.empty) {
      logWarn("[VerifyBookingAccess] Booking not found", {
        bookingReference,
      });
      throw new HttpsError(
        "not-found",
        "Booking not found. Please check your booking reference."
      );
    }

    const bookingDoc = bookingsSnapshot.docs[0];
    const booking = bookingDoc.data();

    // Verify email matches (case-insensitive)
    // Guard against null/undefined guest_email (e.g., admin-created bookings without guest data)
    if (!booking.guest_email || booking.guest_email.toLowerCase() !== email.toLowerCase()) {
      logWarn("[VerifyBookingAccess] Email mismatch", {
        bookingReference,
        attemptedEmail: email.substring(0, 3) + "***",
        hasGuestEmail: !!booking.guest_email,
      });
      throw new HttpsError(
        "permission-denied",
        "Email does not match booking records."
      );
    }

    // If access token provided, verify it
    if (accessToken) {
      // Check if booking has access token
      if (!booking.access_token) {
        logWarn("[VerifyBookingAccess] Booking has no access token", {
          bookingReference,
        });
        // Allow fallback to email-only verification
      } else {
        // Verify token matches
        const isTokenValid = verifyAccessToken(
          accessToken,
          booking.access_token
        );

        if (!isTokenValid) {
          logWarn("[VerifyBookingAccess] Invalid access token", {
            bookingReference,
          });
          throw new HttpsError(
            "permission-denied",
            "Invalid or expired access link. Please try manual lookup."
          );
        }

        // Check token expiration
        if (booking.token_expires_at) {
          const now = new Date();
          const expiresAt = booking.token_expires_at.toDate();

          if (now > expiresAt) {
            logWarn("[VerifyBookingAccess] Token expired", {
              bookingReference,
              expiresAt: expiresAt.toISOString(),
            });
            throw new HttpsError(
              "permission-denied",
              "Access link has expired. Please use manual lookup."
            );
          }
        }
      }
    }

    // OPTIMIZED: Fetch property, unit, and company details in PARALLEL
    // Before: ~400-500ms (sequential)
    // After: ~100-150ms (parallel)
    const needsBankDetails =
      booking.payment_method === "bank_transfer" && booking.owner_id;

    const [propertyDoc, unitDoc, companyDoc] = await Promise.all([
      db.collection("properties").doc(booking.property_id).get(),
      db.collection("properties")
        .doc(booking.property_id)
        .collection("units")
        .doc(booking.unit_id)
        .get(),
      needsBankDetails ?
        db.collection("users")
          .doc(booking.owner_id)
          .collection("data")
          .doc("company")
          .get() :
        Promise.resolve(null),
    ]);

    const property = propertyDoc.data();
    const unit = unitDoc.data();

    // Extract bank details if fetched
    let bankDetails = null;
    if (companyDoc?.exists) {
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
      guestName: booking.guest_name || "Guest",
      guestEmail: booking.guest_email || "",
      guestPhone: booking.guest_phone || null,
      checkIn: checkIn.toISOString(),
      checkOut: checkOut.toISOString(),
      nights: nights,
      // Handle both formats: int (legacy) or object {adults, children}
      guestCount: typeof booking.guest_count === "number" ?
        {adults: booking.guest_count, children: 0} :
        (booking.guest_count || {adults: 1, children: 0}),
      totalPrice: booking.total_price || 0,
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
