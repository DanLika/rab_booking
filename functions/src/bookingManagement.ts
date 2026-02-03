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
import {safeToDate} from "./utils/dateValidation";
import {
  generateBookingAccessToken,
  calculateTokenExpiration,
} from "./bookingAccessToken";
import {generateBookingReference} from "./utils/bookingReferenceGenerator";

// ==========================================
// EMAIL ERROR TRACKING
// ==========================================

/**
 * Track email sending failure for monitoring/alerting
 *
 * Logs to Cloud Logging for:
 * - Monitoring via Cloud Monitoring dashboards
 * - Alerting via Log-based metrics
 * - Querying via Logs Explorer
 *
 * @param bookingId - Booking ID
 * @param emailType - Type of email that failed
 * @param recipient - Email recipient
 * @param error - Error that occurred
 */
function trackEmailFailure(
  bookingId: string,
  emailType: string,
  recipient: string,
  error: unknown
): void {
  // Log to Cloud Logging with structured data for monitoring/alerting
  // Can create Log-based metrics in GCP Console to trigger alerts
  logWarn("[EmailFailure] Failed to send email", {
    bookingId,
    emailType,
    recipient,
    errorMessage: error instanceof Error ? error.message : String(error),
    errorStack: error instanceof Error ? error.stack : undefined,
    // Structured labels for Cloud Monitoring queries
    severity: "WARNING",
    component: "email",
    action: "send_failure",
  });
}

/**
 * Cloud Function: Auto-cancel expired pending bookings
 *
 * Runs daily to check for bookings that exceeded payment deadline
 */
export const autoCancelExpiredBookings = onSchedule(
  {
    schedule: "every 24 hours",
    secrets: ["RESEND_API_KEY"],
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    try {
      // Only cancel PENDING bookings (awaiting owner approval or payment)
      // Confirmed bookings are NOT auto-cancelled - owner confirmation = payment received
      // This is intentional: bank_transfer and pay_on_arrival always require owner approval,
      // so they stay pending until owner confirms (which means payment was received)
      const expiredBookings = await db
        .collectionGroup("bookings")
        .where("status", "==", "pending")
        .where("payment_deadline", "<", now)
        .get();

      logInfo("Auto-cancel check completed", {
        expiredCount: expiredBookings.size,
      });

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
                  safeToDate(booking.check_in, "check_in"),
                  safeToDate(booking.check_out, "check_out"),
                  undefined, // refundAmount
                  booking.property_id, // propertyId
                  booking.cancellation_reason || "Payment not received within deadline", // cancellationReason
                  true // cancelledByOwner
                );
              },
              "Auto-Cancel Notification",
              booking.guest_email
            );
          } catch (error) {
            logError("Failed to send cancellation email after retries", error, {bookingId: doc.id});
            // Track failure for monitoring/alerting
            trackEmailFailure(
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
// NEW STRUCTURE: Wildcard path for subcollection triggers
export const onBookingCreated = onDocumentCreated(
  {
    document: "properties/{propertyId}/units/{unitId}/bookings/{bookingId}",
    secrets: ["RESEND_API_KEY"],
  },
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
        requiresApproval,
      });
      return;
    }

    const bookingType = nonePayment || requiresApproval ? "pending approval" : "bank transfer";
    logInfo(`New ${bookingType} booking created`, {
      bookingId: event.params.bookingId,
      reference: booking.booking_reference,
      guest: booking.guest_name,
      email: booking.guest_email,
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
// NEW STRUCTURE: Wildcard path for subcollection triggers
export const onBookingStatusChange = onDocumentUpdated(
  {
    document: "properties/{propertyId}/units/{unitId}/bookings/{bookingId}",
    secrets: ["RESEND_API_KEY"],
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    // Check if status changed
    if (before.status !== after.status) {
      logInfo("Booking status changed", {
        bookingId: event.params.bookingId,
        from: before.status,
        to: after.status,
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

          // Generate new access token for "View my reservation" link
          // The plaintext token is only available at generation time,
          // so we must create a new one when approving the booking
          const {token: accessToken, hashedToken} = generateBookingAccessToken();
          const checkOutDate = safeToDate(after.check_out, "check_out");
          const tokenExpiration = calculateTokenExpiration(checkOutDate);

          // Update booking with new access token (before sending email)
          await event.data?.after.ref.update({
            access_token: hashedToken,
            token_expires_at: tokenExpiration,
          });

          logInfo("Generated new access token for approved booking", {
            bookingId: event.params.bookingId,
          });

          // Send booking approved email to guest with retry
          await sendEmailWithRetry(
            async () => {
              await sendBookingApprovedEmail(
                after.guest_email || "",
                after.guest_name || "Guest",
                after.booking_reference || "",
                safeToDate(after.check_in, "check_in"),
                checkOutDate,
                propertyData?.name || "Property",
                propertyData?.contact_email,
                accessToken, // Plaintext token for "View my reservation" link
                after.total_price,
                after.deposit_amount || after.advance_amount,
                after.property_id // For subdomain URL generation
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
          trackEmailFailure(
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
          trackEmailFailure(
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
        } else if (after.guest_email) {
          // Send cancellation email to guest (only if not sent before and guest email exists)
          try {
            const booking = after as any;

            // Validate booking reference exists (data integrity check)
            if (!booking.booking_reference) {
              // AUTO-HEAL: Restore missing booking_reference
              const newRef = generateBookingReference(event.params.bookingId);
              await event.data?.after.ref.update({
                booking_reference: newRef,
                updated_at: admin.firestore.FieldValue.serverTimestamp(),
              });
              booking.booking_reference = newRef; // Update local object usage

              logWarn(
                "[onStatusChange] Restored missing booking_reference - data auto-healed",
                {
                  bookingId: event.params.bookingId,
                  newReference: newRef,
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
                  safeToDate(booking.check_in, "check_in"),
                  safeToDate(booking.check_out, "check_out"),
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
            trackEmailFailure(
              event.params.bookingId,
              "booking_cancellation",
              after.guest_email || "",
              emailError
            );
            // Don't throw - cancellation should succeed even if email fails
          }
        } else if (!emailTracking?.cancellation) {
          // No guest email and no previous email sent - skip email silently
          logInfo("Skipping cancellation email - no guest email on booking", {
            bookingId: event.params.bookingId,
          });
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

