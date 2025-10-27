import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {
  sendBookingApprovedEmail,
  sendOwnerNotificationEmail,
  sendBookingCancellationEmail,
} from "./emailService";
import {admin, db} from "./firebase";

/**
 * Cloud Function: Create Pending Booking with Bank Transfer
 *
 * This function creates a booking in 'pending' status when
 * payment method is bank transfer. The booking will be disabled
 * in calendar until owner approves after receiving payment.
 */
export const createPendingBooking = onCall(async (request) => {
  // Get userId if authenticated, null for anonymous widget bookings
  const userId = request.auth?.uid || null;
  const data = request.data;

  const {
    unitId,
    propertyId,
    checkIn,
    checkOut,
    adults,
    children,
    totalAmount,
    depositAmount,
    remainingAmount,
    paymentMethod,
    guestDetails,
    additionalServices,
  } = data;

  // Validate required fields
  if (!unitId || !checkIn || !checkOut || !totalAmount) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required booking fields"
    );
  }

  // For anonymous bookings, require guest details
  if (!userId && (!guestDetails?.name || !guestDetails?.email)) {
    throw new HttpsError(
      "invalid-argument",
      "Guest name and email are required for widget bookings"
    );
  }

  try {
    const checkInDate = admin.firestore.Timestamp.fromDate(
      new Date(checkIn)
    );
    const checkOutDate = admin.firestore.Timestamp.fromDate(
      new Date(checkOut)
    );

    // Check date availability
    const conflictingBookings = await db
      .collection("bookings")
      .where("unit_id", "==", unitId)
      .where("status", "in", ["pending", "confirmed"])
      .where("check_in", "<", checkOutDate)
      .where("check_out", ">", checkInDate)
      .get();

    if (!conflictingBookings.empty) {
      throw new HttpsError(
        "already-exists",
        "Selected dates are no longer available"
      );
    }

    // Generate booking reference
    const bookingRef = `BK${Date.now()}${Math.floor(Math.random() * 1000)}`;

    // Create booking document
    const bookingData: any = {
      user_id: userId,
      unit_id: unitId,
      property_id: propertyId,
      check_in: checkInDate,
      check_out: checkOutDate,
      guest_count: adults + (children || 0),
      adults,
      children: children || 0,
      total_price: totalAmount,
      deposit_amount: depositAmount || 0,
      remaining_amount: remainingAmount || totalAmount,
      paid_amount: 0,
      payment_method: paymentMethod || "bankTransfer",
      status: paymentMethod === "bankTransfer" ? "pending" : "confirmed",
      booking_reference: bookingRef,
      source: "widget", // Mark as widget booking
      payment_deadline: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 3 * 24 * 60 * 60 * 1000) // 3 days from now
      ),
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Add guest details for anonymous bookings
    if (guestDetails) {
      bookingData.guest_name = guestDetails.name;
      bookingData.guest_email = guestDetails.email;
      bookingData.guest_phone = guestDetails.phone || null;
      bookingData.notes = guestDetails.notes || null;
    }

    // Add additional services if provided
    if (additionalServices && Object.keys(additionalServices).length > 0) {
      bookingData.additional_services = additionalServices;
    }

    const bookingDoc = await db.collection("bookings").add(bookingData);

    // IMPORTANT: DO NOT send emails here!
    // Emails will be sent ONLY after payment verification:
    // - For Stripe: handleStripeWebhook sends emails after successful payment
    // - For Bank Transfer: approvePendingBooking sends emails after owner approval
    //
    // This ensures we don't send booking confirmations before payment is verified.

    return {
      success: true,
      bookingId: bookingDoc.id,
      bookingReference: bookingRef,
      status: bookingData.status,
      paymentDeadline: bookingData.payment_deadline.toDate(),
      message: paymentMethod === "bankTransfer" ?
        "Booking created. Awaiting bank transfer payment." :
        "Booking created. Please complete payment.",
    };
  } catch (error: any) {
    console.error("Error creating booking:", error);
    throw new HttpsError(
      "internal",
      error.message || "Failed to create booking"
    );
  }
});

/**
 * Cloud Function: Approve Pending Booking
 *
 * Owner calls this function after receiving bank transfer payment
 */
export const approvePendingBooking = onCall(async (request) => {
  // Check authentication
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const {bookingId} = request.data;

  if (!bookingId) {
    throw new HttpsError(
      "invalid-argument",
      "Booking ID is required"
    );
  }

  try {
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw new HttpsError(
        "not-found",
        "Booking not found"
      );
    }

    const booking = bookingDoc.data()!;

    // Verify that current user is the property owner
    const unitDoc = await db.collection("units").doc(booking.unit_id).get();
    if (!unitDoc.exists) {
      throw new HttpsError("not-found", "Unit not found");
    }

    const propertyId = unitDoc.data()!.property_id;
    const propertyDoc = await db
      .collection("properties")
      .doc(propertyId)
      .get();

    if (!propertyDoc.exists) {
      throw new HttpsError("not-found", "Property not found");
    }

    const ownerId = propertyDoc.data()!.owner_id;
    if (ownerId !== request.auth.uid) {
      throw new HttpsError(
        "permission-denied",
        "Only property owner can approve bookings"
      );
    }

    // Check if booking is in pending status
    if (booking.status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        "Only pending bookings can be approved"
      );
    }

    // Update booking to confirmed
    await bookingRef.update({
      status: "confirmed",
      paid_amount: booking.deposit_amount,
      approved_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Fetch unit and property details for emails
    const unitData = unitDoc.data();
    const propertyDoc2 = await db
      .collection("properties")
      .doc(propertyId)
      .get();
    const propertyData2 = propertyDoc2.data();

    // Send confirmation email to guest
    try {
      await sendBookingApprovedEmail(
        booking.guest_email || "",
        booking.guest_name || "Guest",
        booking.booking_reference,
        booking.check_in.toDate(),
        booking.check_out.toDate(),
        propertyData2?.name || "Property",
        propertyData2?.contact_email
      );
    } catch (error) {
      console.error("Failed to send approval email to guest:", error);
    }

    // Send notification email to owner
    try {
      const ownerDoc = await db.collection("users").doc(ownerId).get();
      const ownerData = ownerDoc.data();

      if (ownerData?.email) {
        await sendOwnerNotificationEmail(
          ownerData.email,
          ownerData.name || "Owner",
          booking.guest_name || "Guest",
          booking.guest_email || "",
          booking.booking_reference,
          booking.check_in.toDate(),
          booking.check_out.toDate(),
          booking.total_price,
          booking.deposit_amount || 0,
          unitData?.name || "Unit"
        );
      }
    } catch (error) {
      console.error("Failed to send notification email to owner:", error);
    }

    return {
      success: true,
      message: "Booking approved and emails sent successfully",
    };
  } catch (error: any) {
    console.error("Error approving booking:", error);
    throw new HttpsError(
      "internal",
      error.message || "Failed to approve booking"
    );
  }
});

/**
 * Cloud Function: Auto-cancel expired pending bookings
 *
 * Runs daily to check for bookings that exceeded payment deadline
 */
export const autoCancelExpiredBookings = onSchedule(
  "every 24 hours",
  async () => {
    const now = admin.firestore.Timestamp.now();

    try {
      // Find all pending bookings with expired payment deadline
      const expiredBookings = await db
        .collection("bookings")
        .where("status", "==", "pending")
        .where("payment_deadline", "<", now)
        .get();

      const cancelPromises = expiredBookings.docs.map(async (doc) => {
        const booking = doc.data();

        await doc.ref.update({
          status: "cancelled",
          cancellation_reason: "Payment not received within deadline",
          cancelled_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Send cancellation email to guest
        try {
          if (booking.guest_email) {
            await sendBookingCancellationEmail(
              booking.guest_email,
              booking.guest_name || "Guest",
              booking.booking_reference,
              "Payment not received within 3-day deadline"
            );
          }
        } catch (error) {
          console.error(`Failed to send cancellation email for ${doc.id}`);
        }

        console.log(`Auto-cancelled booking ${doc.id} due to payment timeout`);
      });

      await Promise.all(cancelPromises);

      console.log(`Auto-cancelled ${expiredBookings.size} expired bookings`);
    } catch (error) {
      console.error("Error auto-cancelling bookings:", error);
    }
  }
);

/**
 * Firestore trigger: Update calendar when booking changes
 */
export const onBookingStatusChange = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    // Check if status changed
    if (before.status !== after.status) {
      console.log(
        `Booking ${event.params.bookingId} status changed: ` +
        `${before.status} -> ${after.status}`
      );

      // If booking was approved (pending -> confirmed), notify guest
      if (before.status === "pending" && after.status === "confirmed") {
        // Send confirmation email
        console.log("Sending booking confirmation email to guest");
        // TODO: Integrate email service
      }

      // If booking was cancelled, free up the dates
      if (after.status === "cancelled") {
        console.log("Booking cancelled, dates freed up");
        // Dates are automatically freed as query filters by status
      }
    }
  }
);
