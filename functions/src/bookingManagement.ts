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
import {sendEmailIfAllowed} from "./emailNotificationHelper";
import {admin, db} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import {createBookingNotification} from "./notificationService";

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
            // Fetch property and unit names for email
            let propertyName = "Property";
            let unitName: string | undefined;
            if (booking.property_id) {
              try {
                const propDoc = await db.collection("properties").doc(booking.property_id).get();
                propertyName = propDoc.data()?.name || "Property";
              } catch (e) { /* ignore */ }
            }
            if (booking.property_id && booking.unit_id) {
              try {
                const unitDoc = await db
                  .collection("properties")
                  .doc(booking.property_id)
                  .collection("units")
                  .doc(booking.unit_id)
                  .get();
                unitName = unitDoc.data()?.name;
              } catch (e) { /* ignore */ }
            }

            await sendBookingCancellationEmail(
              booking.guest_email,
              booking.guest_name || "Guest",
              booking.booking_reference,
              propertyName,
              unitName,
              booking.check_in.toDate(),
              booking.check_out.toDate()
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
      // NOTE: Units are stored as subcollection: properties/{propertyId}/units/{unitId}
      const propertyDoc = await db
        .collection("properties")
        .doc(booking.property_id)
        .get();
      const propertyData = propertyDoc.data();

      const unitDoc = await db
        .collection("properties")
        .doc(booking.property_id)
        .collection("units")
        .doc(booking.unit_id)
        .get();
      const unitData = unitDoc.data();

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
          propertyData?.name || "Property"
        );

        logSuccess("Pending booking request email sent to guest", {email: booking.guest_email});

        // Send owner notification for pending approval
        if (ownerData?.email) {
          // CRITICAL: Pending bookings FORCE send (owner must approve)
          await sendEmailIfAllowed(
            ownerId,
            "bookings",
            async () => {
              await sendPendingBookingOwnerNotification(
                ownerData.email,
                booking.booking_reference || "",
                booking.guest_name || "Guest",
                propertyData?.name || "Property"
              );
            },
            true // forceIfCritical: owner MUST be notified to approve booking
          );

          logSuccess("Pending booking owner notification sent", {email: ownerData.email});
        }
      } else {
        // Bank transfer booking - email sent from atomicBooking.ts with access token
        // (No email sent here to avoid duplicates - atomicBooking handles it)
        logInfo("Bank transfer booking created - email sent from atomicBooking", {
          bookingRef: booking.booking_reference,
        });

        // Send owner notification for bank transfer (respect preferences)
        if (ownerData?.email) {
          await sendEmailIfAllowed(
            ownerId,
            "bookings",
            async () => {
              await sendOwnerNotificationEmail(
                ownerData.email,
                booking.booking_reference || "",
                booking.guest_name || "Guest",
                booking.guest_email || "",
                booking.guest_phone || undefined,
                propertyData?.name || "Property",
                unitData?.name || "Unit",
                booking.check_in.toDate(),
                booking.check_out.toDate(),
                booking.guest_count || 2,
                booking.total_price || 0,
                booking.deposit_amount || (booking.total_price * 0.2)
              );
            },
            false // Respect preferences: owner can opt-out of instant booking emails
          );

          logSuccess("Owner notification processed (sent if preferences allow)", {email: ownerData.email});
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
          // NOTE: Units are stored as subcollection: properties/{propertyId}/units/{unitId}
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

          // Fetch property and unit names for email
          let propertyName = "Property";
          let unitName: string | undefined;
          if (booking.property_id) {
            try {
              const propDoc = await db.collection("properties").doc(booking.property_id).get();
              propertyName = propDoc.data()?.name || "Property";
            } catch (e) { /* ignore */ }
          }
          if (booking.property_id && booking.unit_id) {
            try {
              const unitDoc = await db
                .collection("properties")
                .doc(booking.property_id)
                .collection("units")
                .doc(booking.unit_id)
                .get();
              unitName = unitDoc.data()?.name;
            } catch (e) { /* ignore */ }
          }

          await sendBookingCancellationEmail(
            booking.guest_email,
            booking.guest_name,
            booking.booking_reference || event.params.bookingId,
            propertyName,
            unitName,
            booking.check_in.toDate(),
            booking.check_out.toDate(),
            undefined, // refundAmount
            booking.property_id
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

