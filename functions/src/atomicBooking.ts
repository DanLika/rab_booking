import {onCall, HttpsError} from "firebase-functions/v2/https";
import {admin, db} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import {
  generateBookingAccessToken,
  calculateTokenExpiration,
} from "./bookingAccessToken";
import {sendBookingConfirmationEmail} from "./emailService";

/**
 * Cloud Function: Create Booking with Atomic Availability Check
 *
 * This function uses Firestore transaction to ATOMICALLY check availability
 * and create booking, preventing race conditions where two users book same dates.
 *
 * CRITICAL: This prevents double bookings by ensuring only ONE booking can
 * succeed when multiple users try to book the same dates simultaneously.
 */
export const createBookingAtomic = onCall(async (request) => {
  const userId = request.auth?.uid || null;
  const data = request.data;

  const {
    unitId,
    propertyId,
    ownerId,
    checkIn,
    checkOut,
    guestName,
    guestEmail,
    guestPhone,
    guestCount,
    totalPrice,
    paymentOption, // 'deposit', 'full', or 'none'
    paymentMethod, // 'stripe', 'bank_transfer', or 'none'
    requireOwnerApproval = false,
    notes,
  } = data;

  // Validate required fields
  if (!unitId || !propertyId || !ownerId || !checkIn || !checkOut ||
      !guestName || !guestEmail || !totalPrice) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required booking fields"
    );
  }

  try {
    logInfo("[AtomicBooking] Starting atomic booking creation", {
      unitId,
      checkIn,
      checkOut,
      guestEmail,
    });

    const checkInDate = admin.firestore.Timestamp.fromDate(new Date(checkIn));
    const checkOutDate = admin.firestore.Timestamp.fromDate(new Date(checkOut));

    // Generate unique booking ID and reference
    const bookingId = db.collection("bookings").doc().id;
    const bookingRef = `BK-${Date.now()}-${Math.floor(Math.random() * 10000)}`;

    // Calculate deposit amount
    const depositAmount = paymentOption === "none"
      ? 0.0
      : paymentOption === "deposit"
        ? totalPrice * 0.2
        : totalPrice;

    // Determine booking status
    let status: string;
    let paymentStatus: string;

    if (requireOwnerApproval || paymentMethod === "none") {
      status = "pending";
      paymentStatus = "not_required";
    } else if (paymentMethod === "bank_transfer") {
      status = "pending";
      paymentStatus = "pending";
    } else {
      status = "pending"; // Stripe payment pending
      paymentStatus = "pending";
    }

    // ========================================================================
    // CRITICAL: Use Firestore transaction for ATOMIC availability check + create
    // ========================================================================
    const result = await db.runTransaction(async (transaction) => {
      // Step 1: Query conflicting bookings INSIDE transaction
      // Bug #62 Fix: Changed "check_out" > to >= to properly detect same-day turnover conflicts
      // This ensures checkout day = checkin day is treated as conflict (no same-day turnover)
      const conflictingBookingsQuery = db
        .collection("bookings")
        .where("unit_id", "==", unitId)
        .where("status", "in", ["pending", "confirmed"])
        .where("check_in", "<", checkOutDate)
        .where("check_out", ">=", checkInDate);

      const conflictingBookings = await transaction.get(conflictingBookingsQuery);

      // Step 2: Check for conflicts
      if (!conflictingBookings.empty) {
        logError("[AtomicBooking] Date conflict detected", null, {
          unitId,
          requestedCheckIn: checkIn,
          requestedCheckOut: checkOut,
          conflictingBookings: conflictingBookings.docs.map((doc) => ({
            id: doc.id,
            checkIn: doc.data().check_in,
            checkOut: doc.data().check_out,
            status: doc.data().status,
          })),
        });

        throw new HttpsError(
          "already-exists",
          "Selected dates are no longer available. Please select different dates."
        );
      }

      // Step 3: No conflict - create booking atomically
      // Generate secure access token for booking lookup
      const {token: accessToken, hashedToken} = generateBookingAccessToken();
      const tokenExpiration = calculateTokenExpiration(checkOutDate);

      const bookingData = {
        user_id: userId,
        unit_id: unitId,
        property_id: propertyId,
        owner_id: ownerId,
        guest_name: guestName,
        guest_email: guestEmail,
        guest_phone: guestPhone || null,
        check_in: checkInDate,
        check_out: checkOutDate,
        guest_count: guestCount,
        total_price: totalPrice,
        advance_amount: depositAmount,
        deposit_amount: depositAmount, // For Stripe Cloud Function
        remaining_amount: totalPrice - depositAmount,
        paid_amount: 0,
        payment_method: paymentMethod,
        payment_status: paymentStatus,
        status,
        booking_reference: bookingRef,
        source: "widget",
        notes: notes || null,
        require_owner_approval: requireOwnerApproval,
        payment_deadline: paymentMethod === "bank_transfer"
          ? admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 3 * 24 * 60 * 60 * 1000) // 3 days
          )
          : null,
        // Booking lookup security
        access_token: hashedToken,
        token_expires_at: tokenExpiration,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };

      const bookingDocRef = db.collection("bookings").doc(bookingId);
      transaction.set(bookingDocRef, bookingData);

      logSuccess("[AtomicBooking] Booking created atomically", {
        bookingId,
        bookingRef,
        unitId,
        guestEmail,
      });

      return {
        bookingId,
        bookingReference: bookingRef,
        depositAmount,
        status,
        paymentStatus,
        accessToken, // Include plaintext token for email
      };
    });

    // Transaction successful - booking created
    logSuccess("[AtomicBooking] Transaction completed successfully", result);

    // Send confirmation email with access token (only for bank transfer)
    if (paymentMethod === "bank_transfer") {
      try {
        // Fetch property and unit data for email
        const propertyDoc = await db.collection("properties").doc(propertyId).get();
        const unitDoc = await db.collection("units").doc(unitId).get();
        const propertyData = propertyDoc.data();
        const unitData = unitDoc.data();

        await sendBookingConfirmationEmail(
          guestEmail,
          guestName,
          result.bookingReference,
          checkInDate.toDate(),
          checkOutDate.toDate(),
          totalPrice,
          depositAmount,
          unitData?.name || "Unit",
          propertyData?.name || "Property",
          result.accessToken, // Plaintext token for email link
          propertyData?.contact_email
        );

        logSuccess("[AtomicBooking] Confirmation email sent", {
          email: guestEmail,
        });
      } catch (emailError) {
        // Log error but don't fail the booking
        logError("[AtomicBooking] Failed to send confirmation email", emailError);
      }
    }

    return {
      success: true,
      ...result,
      message: paymentMethod === "bank_transfer"
        ? "Booking created. Awaiting bank transfer payment."
        : requireOwnerApproval
          ? "Booking request submitted. Awaiting owner approval."
          : "Booking created. Please complete payment.",
    };
  } catch (error: any) {
    // Check if it's our "already-exists" error
    if (error.code === "already-exists") {
      logInfo("[AtomicBooking] Booking rejected - dates unavailable", {
        unitId,
        checkIn,
        checkOut,
      });
      throw error; // Re-throw to client
    }

    logError("[AtomicBooking] Unexpected error creating booking", error, {
      unitId,
      guestEmail,
    });

    throw new HttpsError(
      "internal",
      error.message || "Failed to create booking. Please try again."
    );
  }
});
