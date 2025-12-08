import {onSchedule} from "firebase-functions/v2/scheduler";
import {
  onDocumentUpdated,
  onDocumentCreated,
} from "firebase-functions/v2/firestore";
import {
  sendBookingApprovedEmail,
  sendBookingCancellationEmail,
  sendBookingRejectedEmail,
} from "./emailService";
import {sendEmailWithRetry} from "./utils/emailRetry";
import {admin, db} from "./firebase";
import {logInfo, logError, logSuccess, logWarn} from "./logger";
import {createBookingNotification} from "./notificationService";
import {
  fetchPropertyAndUnitDetails,
  BookingEmailTracking,
} from "./utils/bookingHelpers";

// ==========================================
// EMAIL ERROR TRACKING
// ==========================================

/**
 * Track email sending failure for monitoring/alerting
 *
 * This creates a record that can be:
 * - Monitored via Cloud Monitoring
 * - Used to trigger alerts
 * - Picked up by a retry job
 *
 * @param bookingId - Booking ID
 * @param emailType - Type of email that failed
 * @param recipient - Email recipient
 * @param error - Error that occurred
 */
async function trackEmailFailure(
  bookingId: string,
  emailType: string,
  recipient: string,
  error: unknown
): Promise<void> {
  try {
    await db.collection("email_failures").add({
      booking_id: bookingId,
      email_type: emailType,
      recipient,
      error_message: error instanceof Error ? error.message : String(error),
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      retry_count: 0,
      resolved: false,
    });

    logWarn("[BookingManagement] Email failure tracked for monitoring", {
      bookingId,
      emailType,
      recipient,
    });
  } catch (trackError) {
    // Don't fail if tracking fails - just log
    logError("[BookingManagement] Failed to track email failure", trackError, {
      bookingId,
      emailType,
    });
  }
}

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

        // Send cancellation email to guest with retry
        if (booking.guest_email) {
          try {
            // Fetch property and unit names using shared utility
            const {propertyName, unitName} = await fetchPropertyAndUnitDetails(
              booking.property_id,
              booking.unit_id,
              "autoCancelExpired"
            );

            await sendEmailWithRetry(
              async () => {
                await sendBookingCancellationEmail(
                  booking.guest_email,
                  booking.guest_name || "Guest",
                  booking.booking_reference,
                  propertyName,
                  unitName,
                  booking.check_in.toDate(),
                  booking.check_out.toDate()
                );
              },
              "Auto-Cancel Notification",
              booking.guest_email
            );
          } catch (error) {
            logError("Failed to send cancellation email after retries", error, {bookingId: doc.id});
            // Track failure for monitoring/alerting
            await trackEmailFailure(
              doc.id,
              "auto_cancel_notification",
              booking.guest_email,
              error
            );
          }
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
    const shouldSendInitialEmail = bankTransfer || requiresApproval || nonePayment;

    if (!shouldSendInitialEmail) {
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
      // Fetch property details for owner_id (we only need propertyData here)
      // NOTE: Units are stored as subcollection: properties/{propertyId}/units/{unitId}
      const {propertyData} = await fetchPropertyAndUnitDetails(
        booking.property_id,
        booking.unit_id,
        "onBookingCreated",
        true // fetchFullData = true (we need owner_id from propertyData)
      );

      // Get owner ID for in-app notification
      const ownerId = propertyData?.owner_id;

      // NOTE: Guest confirmation and owner notification emails are handled by atomicBooking.ts
      // This trigger only handles:
      // 1. Logging for audit purposes
      // 2. In-app notifications (see below)
      //
      // DO NOT send duplicate emails here - atomicBooking.ts already handles:
      // - sendPendingBookingRequestEmail (to guest)
      // - sendPendingBookingOwnerNotification (to owner for pending)
      // - sendBookingConfirmationEmail (to guest for confirmed)
      // - sendOwnerNotificationEmail (to owner for confirmed)
      if (requiresApproval || nonePayment) {
        logInfo("Pending booking created - emails sent from atomicBooking", {
          bookingRef: booking.booking_reference,
          status: booking.status,
        });
      } else {
        logInfo("Bank transfer booking created - emails sent from atomicBooking", {
          bookingRef: booking.booking_reference,
          status: booking.status,
        });
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

        // ✅ IDEMPOTENCY CHECK: Prevent duplicate emails on function retry
        const emailTracking = after.emails_sent as BookingEmailTracking | undefined;
        if (emailTracking?.approval) {
          logInfo("Approval email already sent, skipping (idempotency check)", {
            bookingId: event.params.bookingId,
            sentAt: emailTracking.approval.sent_at,
            email: emailTracking.approval.email,
          });
          return;
        }

        try {
          // Fetch property details
          const propertyDoc = await db
            .collection("properties")
            .doc(after.property_id)
            .get();
          const propertyData = propertyDoc.data();

          // Send booking approved email to guest with retry
          await sendEmailWithRetry(
            async () => {
              await sendBookingApprovedEmail(
                after.guest_email || "",
                after.guest_name || "Guest",
                after.booking_reference || "",
                after.check_in.toDate(),
                after.check_out.toDate(),
                propertyData?.name || "Property",
                propertyData?.contact_email,
                after.property_id
              );
            },
            "Booking Approved",
            after.guest_email || ""
          );

          logSuccess("Booking approval email sent to guest", {email: after.guest_email});

          // ✅ MARK EMAIL AS SENT: Prevents duplicate sends on retry
          await event.data?.after.ref.update({
            "emails_sent.approval": {
              sent_at: admin.firestore.FieldValue.serverTimestamp(),
              email: after.guest_email,
              booking_id: event.params.bookingId,
            },
          });
        } catch (emailError) {
          logError("Failed to send booking approval email after retries", emailError);
          // Track failure for monitoring/alerting
          await trackEmailFailure(
            event.params.bookingId,
            "booking_approved",
            after.guest_email || "",
            emailError
          );
          // Don't throw - approval should succeed even if email fails
        }
      }

      // If booking was rejected (pending -> cancelled with rejection_reason)
      if (before.status === "pending" && after.status === "cancelled" && after.rejection_reason) {
        logInfo("Booking rejected by owner, sending rejection email to guest");

        // ✅ IDEMPOTENCY CHECK: Prevent duplicate emails on function retry
        const emailTracking = after.emails_sent as BookingEmailTracking | undefined;
        if (emailTracking?.rejection) {
          logInfo("Rejection email already sent, skipping (idempotency check)", {
            bookingId: event.params.bookingId,
            sentAt: emailTracking.rejection.sent_at,
            email: emailTracking.rejection.email,
          });
          return;
        }

        try {
          // Fetch unit and property details
          // NOTE: Units are stored as subcollection: properties/{propertyId}/units/{unitId}
          const propertyDoc = await db
            .collection("properties")
            .doc(after.property_id)
            .get();
          const propertyData = propertyDoc.data();

          // Send booking rejected email to guest with retry
          await sendEmailWithRetry(
            async () => {
              await sendBookingRejectedEmail(
                after.guest_email || "",
                after.guest_name || "Guest",
                after.booking_reference || "",
                propertyData?.name || "Property",
                after.rejection_reason
              );
            },
            "Booking Rejected",
            after.guest_email || ""
          );

          logSuccess("Booking rejection email sent to guest", {email: after.guest_email});

          // ✅ MARK EMAIL AS SENT: Prevents duplicate sends on retry
          await event.data?.after.ref.update({
            "emails_sent.rejection": {
              sent_at: admin.firestore.FieldValue.serverTimestamp(),
              email: after.guest_email,
              booking_id: event.params.bookingId,
            },
          });
        } catch (emailError) {
          logError("Failed to send booking rejection email after retries", emailError);
          // Track failure for monitoring/alerting
          await trackEmailFailure(
            event.params.bookingId,
            "booking_rejected",
            after.guest_email || "",
            emailError
          );
          // Don't throw - rejection should succeed even if email fails
        }
      }

      // If booking was cancelled (but not rejected - regular cancellation)
      if (after.status === "cancelled" && !after.rejection_reason) {
        logInfo("Booking cancelled, dates freed up");

        // ✅ IDEMPOTENCY CHECK: Prevent duplicate emails on function retry
        const emailTracking = after.emails_sent as BookingEmailTracking | undefined;
        if (emailTracking?.cancellation) {
          logInfo("Cancellation email already sent, skipping (idempotency check)", {
            bookingId: event.params.bookingId,
            sentAt: emailTracking.cancellation.sent_at,
            email: emailTracking.cancellation.email,
          });
          // Don't return here - we still need to create owner notification
        } else {
          // Send cancellation email to guest (only if not sent before)
          try {
            const booking = after as any;

            // Validate booking reference exists (data integrity check)
            if (!booking.booking_reference) {
              logError(
                "[onStatusChange] CRITICAL: booking_reference missing - possible data corruption",
                null,
                {
                  bookingId: event.params.bookingId,
                  propertyId: booking.property_id,
                  unitId: booking.unit_id,
                }
              );
            }

            // Fetch property and unit names using shared utility
            const {propertyName, unitName} = await fetchPropertyAndUnitDetails(
              booking.property_id,
              booking.unit_id,
              "onStatusChange"
            );

            // Send cancellation email with retry
            // If cancellation_reason exists, it was cancelled by owner
            const cancellationReason = booking.cancellation_reason as string | undefined;
            const cancelledByOwner = !!cancellationReason;

            await sendEmailWithRetry(
              async () => {
                await sendBookingCancellationEmail(
                  booking.guest_email,
                  booking.guest_name,
                  booking.booking_reference || `ERR-${event.params.bookingId}`,
                  propertyName,
                  unitName,
                  booking.check_in.toDate(),
                  booking.check_out.toDate(),
                  undefined, // refundAmount
                  booking.property_id,
                  cancellationReason,
                  cancelledByOwner
                );
              },
              "Booking Cancellation",
              booking.guest_email || ""
            );
            logSuccess("Cancellation email sent", {email: booking.guest_email});

            // ✅ MARK EMAIL AS SENT: Prevents duplicate sends on retry
            await event.data?.after.ref.update({
              "emails_sent.cancellation": {
                sent_at: admin.firestore.FieldValue.serverTimestamp(),
                email: after.guest_email,
                booking_id: event.params.bookingId,
              },
            });
          } catch (emailError) {
            logError("Failed to send cancellation email after retries", emailError);
            // Track failure for monitoring/alerting
            await trackEmailFailure(
              event.params.bookingId,
              "booking_cancellation",
              after.guest_email || "",
              emailError
            );
            // Don't throw - cancellation should succeed even if email fails
          }
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

