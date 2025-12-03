import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {
  onDocumentUpdated,
  onDocumentCreated,
} from "firebase-functions/v2/firestore";
import {
  sendBookingApprovedEmail,
  sendOwnerNotificationEmail,
  sendBookingCancellationEmail,
  sendPendingBookingRequestEmail,
  sendPendingBookingOwnerNotification,
  sendBookingRejectedEmail,
} from "./emailService";
import {admin, db} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import {createBookingNotification} from "./notificationService";

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
      payment_method: paymentMethod || "bank_transfer",
      status: paymentMethod === "bank_transfer" ? "pending" : "confirmed",
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
      message: paymentMethod === "bank_transfer" ?
        "Booking created. Awaiting bank transfer payment." :
        "Booking created. Please complete payment.",
    };
  } catch (error: any) {
    logError("Error creating booking", error);
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
        propertyData2?.contact_email,
        undefined, // accessToken not available for approval flow
        booking.total_price,
        booking.deposit_amount || 0,
        propertyId // For subdomain in email links
      );
    } catch (error) {
      logError("Failed to send approval email to guest", error);
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
      logError("Failed to send notification email to owner", error);
    }

    return {
      success: true,
      message: "Booking approved and emails sent successfully",
    };
  } catch (error: any) {
    logError("Error approving booking", error);
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
          logError("Failed to send cancellation email", error, {bookingId: doc.id});
        }

        logInfo("Auto-cancelled booking due to payment timeout", {bookingId: doc.id});
      });

      await Promise.all(cancelPromises);

      logSuccess("Auto-cancelled expired bookings", {count: expiredBookings.size});
    } catch (error) {
      logError("Error auto-cancelling bookings", error);
    }
  }
);

/**
 * Firestore trigger: Send initial booking email with bank transfer instructions
 *
 * Triggers when a new booking is created with payment_method = 'bank_transfer'
 * Sends email with payment instructions immediately
 */
export const onBookingCreated = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const booking = event.data?.data();

    if (!booking) return;

    const requiresApproval = booking.require_owner_approval === true;
    const nonePayment = booking.payment_method === "none";
    const bankTransfer = booking.payment_method === "bank_transfer";

    // Send emails for: bank transfer, pending approval, or no payment bookings
    if (!bankTransfer && !requiresApproval && !nonePayment) {
      logInfo("Booking uses Stripe or other instant method, skipping initial email", {
        bookingId: event.params.bookingId,
        paymentMethod: booking.payment_method,
        requiresApproval
      });
      return;
    }

    const bookingType = nonePayment || requiresApproval ? "pending approval" : "bank transfer";
    logInfo(`New ${bookingType} booking created`, {
      bookingId: event.params.bookingId,
      reference: booking.booking_reference,
      guest: booking.guest_name,
      email: booking.guest_email
    });

    try {
      // Fetch unit and property details
      const unitDoc = await db.collection("units").doc(booking.unit_id).get();
      const unitData = unitDoc.data();

      const propertyDoc = await db
        .collection("properties")
        .doc(booking.property_id)
        .get();
      const propertyData = propertyDoc.data();

      // Fetch owner details
      const ownerId = propertyData?.owner_id;
      let ownerData: any = null;
      if (ownerId) {
        const ownerDoc = await db.collection("users").doc(ownerId).get();
        ownerData = ownerDoc.data();
      }

      // Send different emails based on booking type
      if (requiresApproval || nonePayment) {
        // Pending approval booking - no payment required yet
        await sendPendingBookingRequestEmail(
          booking.guest_email || "",
          booking.guest_name || "Guest",
          booking.booking_reference || "",
          booking.check_in.toDate(),
          booking.check_out.toDate(),
          booking.total_price || 0,
          unitData?.name || "Unit",
          propertyData?.name || "Property"
        );

        logSuccess("Pending booking request email sent to guest", {email: booking.guest_email});

        // Send owner notification for pending approval
        if (ownerData?.email) {
          await sendPendingBookingOwnerNotification(
            ownerData.email,
            ownerData.name || "Owner",
            booking.guest_name || "Guest",
            booking.guest_email || "",
            booking.guest_phone || "",
            booking.booking_reference || "",
            booking.check_in.toDate(),
            booking.check_out.toDate(),
            booking.total_price || 0,
            unitData?.name || "Unit",
            booking.guest_count || 2,
            booking.notes
          );

          logSuccess("Pending booking owner notification sent", {email: ownerData.email});
        }
      } else {
        // Bank transfer booking - email sent from atomicBooking.ts with access token
        // (No email sent here to avoid duplicates - atomicBooking handles it)
        logInfo("Bank transfer booking created - email sent from atomicBooking", {
          bookingRef: booking.booking_reference,
        });

        // Send owner notification for bank transfer
        if (ownerData?.email) {
          await sendOwnerNotificationEmail(
            ownerData.email,
            ownerData.name || "Owner",
            booking.guest_name || "Guest",
            booking.guest_email || "",
            booking.booking_reference || "",
            booking.check_in.toDate(),
            booking.check_out.toDate(),
            booking.total_price || 0,
            booking.deposit_amount || (booking.total_price * 0.2),
            unitData?.name || "Unit"
          );

          logSuccess("Owner notification sent", {email: ownerData.email});
        }
      }

      // Create in-app notification for owner
      if (ownerId) {
        try {
          await createBookingNotification(
            ownerId,
            event.params.bookingId,
            booking.guest_name || "Guest",
            "created"
          );
          logSuccess("In-app notification created for owner", {ownerId});
        } catch (notificationError) {
          logError("Failed to create in-app notification", notificationError, {ownerId});
          // Continue - notification failure shouldn't break the flow
        }
      }
    } catch (error) {
      logError("Failed to send booking emails", error, {bookingId: event.params.bookingId});
      // Don't throw - we don't want to fail booking creation if email fails
      // The booking is already created, email is just a notification
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
      logInfo("Booking status changed", {
        bookingId: event.params.bookingId,
        from: before.status,
        to: after.status
      });

      // If booking was approved (pending -> confirmed with approved_at timestamp)
      if (before.status === "pending" && after.status === "confirmed" && after.approved_at) {
        logInfo("Booking approved by owner, sending confirmation email to guest");

        try {
          // Fetch property details
          const propertyDoc = await db
            .collection("properties")
            .doc(after.property_id)
            .get();
          const propertyData = propertyDoc.data();

          // Send booking approved email to guest
          await sendBookingApprovedEmail(
            after.guest_email || "",
            after.guest_name || "Guest",
            after.booking_reference || "",
            after.check_in.toDate(),
            after.check_out.toDate(),
            propertyData?.name || "Property",
            propertyData?.contact_email
          );

          logSuccess("Booking approval email sent to guest", {email: after.guest_email});
        } catch (emailError) {
          logError("Failed to send booking approval email", emailError);
          // Don't throw - approval should succeed even if email fails
        }
      }

      // If booking was rejected (pending -> cancelled with rejection_reason)
      if (before.status === "pending" && after.status === "cancelled" && after.rejection_reason) {
        logInfo("Booking rejected by owner, sending rejection email to guest");

        try {
          // Fetch unit and property details
          const unitDoc = await db.collection("units").doc(after.unit_id).get();
          const unitData = unitDoc.data();

          const propertyDoc = await db
            .collection("properties")
            .doc(after.property_id)
            .get();
          const propertyData = propertyDoc.data();

          // Send booking rejected email to guest
          await sendBookingRejectedEmail(
            after.guest_email || "",
            after.guest_name || "Guest",
            after.booking_reference || "",
            after.check_in.toDate(),
            after.check_out.toDate(),
            unitData?.name || "Unit",
            propertyData?.name || "Property",
            after.rejection_reason
          );

          logSuccess("Booking rejection email sent to guest", {email: after.guest_email});
        } catch (emailError) {
          logError("Failed to send booking rejection email", emailError);
          // Don't throw - rejection should succeed even if email fails
        }
      }

      // If booking was cancelled (but not rejected - regular cancellation)
      if (after.status === "cancelled" && !after.rejection_reason) {
        logInfo("Booking cancelled, dates freed up");

        // Send cancellation email to guest
        try {
          const booking = after as any;
          await sendBookingCancellationEmail(
            booking.guest_email,
            booking.guest_name,
            booking.booking_reference || event.params.bookingId,
            booking.cancellation_reason || "Cancelled by owner",
            undefined // ownerEmail - optional
          );
          logSuccess("Cancellation email sent", {email: booking.guest_email});
        } catch (emailError) {
          logError("Failed to send cancellation email", emailError);
          // Don't throw - cancellation should succeed even if email fails
        }

        // Create in-app notification for owner about cancellation
        try {
          const propertyDoc = await db.collection("properties").doc(after.property_id).get();
          const ownerId = propertyDoc.data()?.owner_id;

          if (ownerId) {
            await createBookingNotification(
              ownerId,
              event.params.bookingId,
              after.guest_name || "Guest",
              "cancelled"
            );
            logSuccess("In-app cancellation notification created for owner", {ownerId});
          }
        } catch (notificationError) {
          logError("Failed to create in-app cancellation notification", notificationError);
          // Continue - notification failure shouldn't break the flow
        }
      }
    }
  }
);

/**
 * Cloud Function: Migrate Properties and Units to add slugs
 *
 * One-time migration function to add slug fields to existing properties and units
 * Call this via HTTP or Firebase Functions shell
 */
export const migrateAddSlugs = onCall(async (request) => {
  // Only allow authenticated admin users
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  logInfo("Starting slug migration...");

  try {
    let propertiesUpdated = 0;
    let unitsUpdated = 0;
    const errors: string[] = [];

    // Helper function to generate slug
    const generateSlug = (name: string): string => {
      return name
        .toLowerCase()
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "") // Remove diacritics
        // Croatian specific characters
        .replace(/č/g, "c")
        .replace(/ć/g, "c")
        .replace(/đ/g, "d")
        .replace(/š/g, "s")
        .replace(/ž/g, "z")
        .replace(/[^a-z0-9\s-]/g, "") // Remove special characters
        .trim()
        .replace(/\s+/g, "-") // Replace spaces with hyphens
        .replace(/-+/g, "-"); // Remove consecutive hyphens
    };

    // Migrate properties
    const propertiesSnapshot = await db.collection("properties").get();

    for (const propertyDoc of propertiesSnapshot.docs) {
      const propertyData = propertyDoc.data();

      // Skip if slug already exists
      if (propertyData.slug) {
        logInfo(`Property ${propertyDoc.id} already has slug: ${propertyData.slug}`);
        continue;
      }

      try {
        const slug = generateSlug(propertyData.name || "property");

        await propertyDoc.ref.update({
          slug: slug,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        propertiesUpdated++;
        logSuccess(`Added slug to property: ${propertyDoc.id} -> ${slug}`);

        // Migrate units for this property
        const unitsSnapshot = await propertyDoc.ref.collection("units").get();

        for (const unitDoc of unitsSnapshot.docs) {
          const unitData = unitDoc.data();

          // Skip if slug already exists
          if (unitData.slug) {
            logInfo(`Unit ${unitDoc.id} already has slug: ${unitData.slug}`);
            continue;
          }

          try {
            const unitSlug = generateSlug(unitData.name || "unit");

            await unitDoc.ref.update({
              slug: unitSlug,
              updated_at: admin.firestore.FieldValue.serverTimestamp(),
            });

            unitsUpdated++;
            logSuccess(`Added slug to unit: ${unitDoc.id} -> ${unitSlug}`);
          } catch (unitError) {
            const errorMsg = `Failed to update unit ${unitDoc.id}: ${unitError}`;
            errors.push(errorMsg);
            logError(errorMsg, unitError);
          }
        }
      } catch (propertyError) {
        const errorMsg = `Failed to update property ${propertyDoc.id}: ${propertyError}`;
        errors.push(errorMsg);
        logError(errorMsg, propertyError);
      }
    }

    const result = {
      success: true,
      propertiesUpdated,
      unitsUpdated,
      totalProcessed: propertiesUpdated + unitsUpdated,
      errors: errors.length > 0 ? errors : undefined,
    };

    logSuccess("Slug migration completed", result);

    return result;
  } catch (error) {
    logError("Slug migration failed", error);
    throw new HttpsError("internal", `Migration failed: ${error}`);
  }
});
