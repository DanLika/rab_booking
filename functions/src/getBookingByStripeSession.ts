import {onCall, HttpsError} from "firebase-functions/v2/https";
import {db, admin} from "./firebase";
import {logInfo, logError, logWarn} from "./logger";
import {setUser} from "./sentry";
import {safeToDate, calculateBookingNights} from "./utils/dateValidation";
import {getClientIp, hashIp} from "./utils/ipUtils";
import {checkRateLimit} from "./utils/rateLimit";
import {getCorsAllowlist} from "./utils/corsAllowlist";

/**
 * Cloud Function: Get Booking by Stripe Session ID
 *
 * Polled by the widget after a Stripe checkout success redirect (and from
 * cross-tab postMessage / BroadcastChannel callbacks) to hydrate the
 * confirmation screen once the Stripe webhook has flipped the placeholder
 * booking to `status=confirmed`.
 *
 * Replaces the previous direct collectionGroup read on
 * `bookings.where('stripe_session_id', '==', sessionId)` which depended on
 * the public-read clause removed in firestore.rules (T11-hotfix-partial).
 *
 * SECURITY: Looks up by stripe_session_id only. The Stripe session id itself
 * is the proof-of-purchase capability — anyone who completed checkout
 * legitimately knows it; anyone who guesses one cannot brute force the
 * `cs_xxx` keyspace at the IP-rate-limit ceiling.
 */
export const getBookingByStripeSession = onCall({cors: getCorsAllowlist()}, async (request) => {
  const clientIp = getClientIp(request);
  const ipHash = hashIp(clientIp);
  if (!checkRateLimit(`stripe_session_${ipHash}`, 60, 3600)) {
    logWarn("[getBookingByStripeSession] Rate limit exceeded", {ipHash});
    throw new HttpsError(
      "resource-exhausted",
      "Too many attempts. Please try again in an hour."
    );
  }

  const {sessionId} = request.data ?? {};
  setUser(null);

  if (!sessionId || typeof sessionId !== "string") {
    throw new HttpsError("invalid-argument", "Session ID is required.");
  }
  if (!sessionId.startsWith("cs_") || sessionId.length > 200) {
    logWarn("[getBookingByStripeSession] Invalid session ID format", {
      sessionIdPrefix: sessionId.substring(0, 6),
    });
    throw new HttpsError("invalid-argument", "Invalid session ID format.");
  }

  try {
    logInfo("[getBookingByStripeSession] Looking up booking", {
      sessionIdPrefix: sessionId.substring(0, 10),
    });

    const snapshot = await db
      .collectionGroup("bookings")
      .where("stripe_session_id", "==", sessionId)
      .limit(1)
      .get();

    if (snapshot.empty) {
      logInfo("[getBookingByStripeSession] No booking yet for session", {
        sessionIdPrefix: sessionId.substring(0, 10),
      });
      // Polling pattern: webhook race is expected, not an error.
      // Caller polls until success=true. See booking_lookup_provider.dart.
      return {success: false, pending: true};
    }

    const bookingDoc = snapshot.docs[0];
    const booking = bookingDoc.data();

    const [propertyDoc, unitDoc] = await Promise.all([
      booking.property_id ?
        db.collection("properties").doc(booking.property_id).get() :
        Promise.resolve(null),
      booking.property_id && booking.unit_id ?
        db.collection("properties")
          .doc(booking.property_id)
          .collection("units")
          .doc(booking.unit_id)
          .get() :
        Promise.resolve(null),
    ]);
    const property = propertyDoc?.data();
    const unit = unitDoc?.data();

    // SF-026: canonical nights helper — see verifyBookingAccess.ts for rationale.
    const checkIn = safeToDate(booking.check_in, "check_in");
    const checkOut = safeToDate(booking.check_out, "check_out");
    const nights = calculateBookingNights(
      admin.firestore.Timestamp.fromDate(checkIn),
      admin.firestore.Timestamp.fromDate(checkOut)
    );

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
      bankDetails: null,
    };

    logInfo("[getBookingByStripeSession] Booking resolved", {
      bookingId: bookingDoc.id,
      status: booking.status,
    });

    return {success: true, booking: bookingDetails};
  } catch (error: unknown) {
    if (error instanceof HttpsError) {
      throw error;
    }
    if (error instanceof Error) {
      logError("[getBookingByStripeSession] Unexpected error", {
        error: error.message,
        stack: error.stack,
      });
    }
    throw new HttpsError(
      "internal",
      "Failed to look up booking by Stripe session."
    );
  }
});
