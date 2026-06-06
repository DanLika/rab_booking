import {onCall, HttpsError} from "firebase-functions/v2/https";
import {db} from "./firebase";
import {logInfo, logError, logWarn} from "./logger";
import {verifyAccessToken} from "./bookingAccessToken";
import {setUser} from "./sentry";
import {safeToDate, calculateBookingNights} from "./utils/dateValidation";
import {admin} from "./firebase";
import {getClientIp, hashIp} from "./utils/ipUtils";
import {checkRateLimit} from "./utils/rateLimit";
import {getCorsAllowlist} from "./utils/corsAllowlist";

/**
 * Cloud Function: Verify Booking Access
 *
 * Verifies user access to booking details using:
 * 1. Booking reference + Email + Access token (from email link)
 * 2. Booking reference + Email only (manual lookup)
 *
 * Returns sanitized booking details if verification succeeds.
 */
export const verifyBookingAccess = onCall({cors: getCorsAllowlist()}, async (request) => {
  // SECURITY: IP-based rate limiting to prevent brute-force (30 requests per hour per IP)
  const clientIp = getClientIp(request);
  const ipHash = hashIp(clientIp);
  if (!checkRateLimit(`verify_access_${ipHash}`, 30, 3600)) {
    logWarn("[VerifyBookingAccess] Rate limit exceeded", {ipHash});
    throw new HttpsError(
      "resource-exhausted",
      "Too many attempts. Please try again in an hour."
    );
  }

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
      // Use same reason as email-mismatch to prevent booking-ref enumeration.
      return {success: false, reason: "invalid_credentials"};
    }

    const bookingDoc = bookingsSnapshot.docs[0];
    const booking = bookingDoc.data();

    // Verify email matches (case-insensitive)
    // Guard against null guest_email (e.g., admin-created bookings without guest email)
    if (!booking.guest_email || booking.guest_email.toLowerCase() !== email.toLowerCase()) {
      logWarn("[VerifyBookingAccess] Email mismatch", {
        bookingReference,
        attemptedEmail: email.substring(0, 3) + "***",
      });
      return {success: false, reason: "invalid_credentials"};
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
          return {success: false, reason: "invalid_token"};
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
            return {success: false, reason: "expired_token"};
          }
        }
      }
    }

    // Guard against corrupted booking docs missing required refs.
    // `db.collection().doc(undefined)` throws sync inside Promise.all and
    // surfaces as `internal` HTTP 500, polluting Sentry with a path that
    // any guest can trigger via a malformed seed. Match the email-mismatch
    // reason to keep the response anti-enumeration.
    if (typeof booking.property_id !== "string" || !booking.property_id ||
        typeof booking.unit_id !== "string" || !booking.unit_id) {
      logWarn(
        "[VerifyBookingAccess] Booking missing property_id/unit_id (data corruption)",
        {
          bookingReference,
          bookingId: bookingDoc.id,
          hasPropertyId: typeof booking.property_id === "string" && !!booking.property_id,
          hasUnitId: typeof booking.unit_id === "string" && !!booking.unit_id,
        }
      );
      return {success: false, reason: "invalid_credentials"};
    }

    // Same guard class for owner_id on the bank_transfer path. Falsy
    // owner_id is fine (short-circuits `needsBankDetails` below), but a
    // truthy non-string (e.g. legacy seed wrote a number) crashes
    // `doc(<non-string>)` sync inside Promise.all.
    if (booking.payment_method === "bank_transfer" &&
        booking.owner_id && typeof booking.owner_id !== "string") {
      logWarn(
        "[VerifyBookingAccess] Booking owner_id corrupted on bank_transfer path",
        {
          bookingReference,
          bookingId: bookingDoc.id,
          ownerIdType: typeof booking.owner_id,
        }
      );
      return {success: false, reason: "invalid_credentials"};
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

    // Calculate nights — SF-026: use canonical helper so result matches
    // the count derived on every other surface (Dart client + email + iCal).
    const checkIn = safeToDate(booking.check_in, "check_in");
    const checkOut = safeToDate(booking.check_out, "check_out");
    const nights = calculateBookingNights(
      admin.firestore.Timestamp.fromDate(checkIn),
      admin.firestore.Timestamp.fromDate(checkOut)
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
      roomPrice: booking.room_price ?? null,
      extraGuestFees: booking.extra_guest_fees ?? null,
      petFees: booking.pet_fees ?? null,
      servicesTotal: booking.services_total ?? null,
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

    // Log unexpected errors. Pass the Error instance directly so logger →
    // Sentry sees the real type + stack instead of a plain object captured
    // as "Object captured as exception with keys: error, stack".
    if (error instanceof Error) {
      logError("[VerifyBookingAccess] Unexpected error", error);
    } else {
      // Preserve original payload instead of stringifying a plain object to
      // "[object Object]". Attach as `cause` so Sentry keeps the raw value
      // alongside the synthetic stack.
      let payload: string;
      try {
        payload = typeof error === "object" && error !== null ?
          JSON.stringify(error) :
          String(error);
      } catch {
        payload = String(error);
      }
      const wrapped = new Error(payload);
      (wrapped as Error & {cause?: unknown}).cause = error;
      logError("[VerifyBookingAccess] Unexpected non-Error throw", wrapped);
    }

    throw new HttpsError(
      "internal",
      "Failed to verify booking access. Please try again."
    );
  }
});
