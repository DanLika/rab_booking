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
import {invalidateIcalCache} from "./utils/icalCache";
import {redactEmail} from "./utils/logRedaction";

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
 * Convert a Firestore Timestamp-like value to milliseconds, or 0 on
 * missing/invalid input. Used to compare check_in/check_out across a
 * trigger's before/after snapshots without throwing on stale data.
 *
 * @param {unknown} t - Value that may be a Firestore Timestamp
 * @return {number} ms epoch, or 0 if input lacks toMillis()
 */
function toMillisOrZero(t: unknown): number {
  if (t && typeof t === "object" && "toMillis" in t) {
    const fn = (t as {toMillis: () => number}).toMillis;
    if (typeof fn === "function") {
      try {
        return fn.call(t);
      } catch {
        return 0;
      }
    }
  }
  return 0;
}

/**
 * Cloud Function: Auto-cancel expired pending bookings
 *
 * Runs daily to check for bookings that exceeded payment deadline
 */
export const autoCancelExpiredBookings = onSchedule(
  {
    schedule: "every 24 hours",
    timeZone: "Europe/Zagreb",
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

      // SF-NNN F-95-03: skip external/iCal-imported bookings. Mirrors filter
      // in autoCompleteCheckedOutBookings.ts:127-140. External platforms
      // (Booking.com / Airbnb / Adriagate) manage their own lifecycle.
      const filteredBookings = expiredBookings.docs.filter((doc) => {
        const data = doc.data();
        if (data.source && ["booking_com", "airbnb", "ical", "external"].includes(String(data.source).toLowerCase())) {
          logInfo("[AutoCancel] Skipping external booking", {bookingId: doc.id, source: data.source});
          return false;
        }
        if (doc.id.startsWith("ical_")) {
          logInfo("[AutoCancel] Skipping iCal-imported booking", {bookingId: doc.id});
          return false;
        }
        return true;
      });

      const cancelPromises = filteredBookings.map(async (doc) => {
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

      logSuccess("Auto-cancelled expired bookings", {
        candidates: expiredBookings.size,
        cancelled: filteredBookings.length,
        externalSkipped: expiredBookings.size - filteredBookings.length,
      });
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

    // audit/34 §5: idempotency guard for retry storms. Event delivery on
    // onDocumentCreated may be redelivered (network, deploy, transient
    // failure); without a marker each redelivery re-flushes the iCal cache
    // and re-creates the in-app notification. The marker is per-trigger,
    // not per-email (atomicBooking.ts handles initial-email idempotency
    // via emails_sent.pending_request / .confirmation etc.).
    const emailTracking = booking.emails_sent as BookingEmailTracking | undefined;
    if (emailTracking?.initial_trigger_processed) {
      logInfo("onBookingCreated already processed for this booking, skipping retry", {
        bookingId: event.params.bookingId,
        processedAt: emailTracking.initial_trigger_processed.sent_at,
      });
      return;
    }

    // Flush iCal export cache for this unit so external calendars see the
    // new booking on next pull instead of waiting up to 5 min for TTL expiry.
    // Fires for ALL payment methods (Stripe-confirmed and pending alike).
    await invalidateIcalCache(event.params.propertyId, event.params.unitId);

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
      emailRedacted: redactEmail(booking.guest_email),
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

      // audit/34 §5: write per-trigger idempotency marker. Reuses emails_sent
      // map (dot-notation never clobbers atomicBooking's pending_request /
      // confirmation entries; both writers append distinct keys).
      await event.data?.ref.update({
        "emails_sent.initial_trigger_processed": {
          sent_at: admin.firestore.FieldValue.serverTimestamp(),
          email: booking.guest_email || "",
          booking_id: event.params.bookingId,
          provider_id: null,
        },
      });
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

    // Detect feed-affecting changes: status flip OR date edit. Either alters
    // the iCal export so the cached feed must be flushed. The two are gated
    // independently because date-only edits (owner drags a confirmed booking
    // on the calendar) preserve status, and the status-change block below
    // carries email/notification side effects that must NOT fire on a
    // pure date move.
    const statusChanged = before.status !== after.status;
    const datesChanged =
      toMillisOrZero(before.check_in) !== toMillisOrZero(after.check_in) ||
      toMillisOrZero(before.check_out) !== toMillisOrZero(after.check_out);

    if (statusChanged || datesChanged) {
      await invalidateIcalCache(event.params.propertyId, event.params.unitId);
    }

    // Check if status changed
    if (statusChanged) {
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
            emailRedacted: redactEmail(emailTracking.approval.email),
          });
          return;
        }

        try {
          const booking = after as any;

          // FLUTTER-7E: AUTO-HEAL missing booking_reference before email send so
          // sendBookingApprovedEmail never receives "" and the CF doesn't throw
          // (which would trigger 4× Functions retry storm). Mirrors the
          // cancellation branch (~:514).
          if (!booking.booking_reference) {
            const newRef = generateBookingReference(event.params.bookingId);
            await event.data?.after.ref.update({
              booking_reference: newRef,
              updated_at: admin.firestore.FieldValue.serverTimestamp(),
            });
            booking.booking_reference = newRef;
            logWarn(
              "[onStatusChange] Restored missing booking_reference (approval)",
              {
                bookingId: event.params.bookingId,
                newReference: newRef,
                propertyId: booking.property_id,
                unitId: booking.unit_id,
              }
            );
          }

          // Fetch property details
          const propertyDoc = await db
            .collection("properties")
            .doc(booking.property_id)
            .get();
          const propertyData = propertyDoc.data();

          // Generate new access token for "View my reservation" link
          // The plaintext token is only available at generation time,
          // so we must create a new one when approving the booking
          const {token: accessToken, hashedToken} = generateBookingAccessToken();
          const checkOutDate = safeToDate(booking.check_out, "check_out");
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
          const providerId = await sendEmailWithRetry(
            () =>
              sendBookingApprovedEmail(
                booking.guest_email || "",
                booking.guest_name || "Guest",
                booking.booking_reference,
                safeToDate(booking.check_in, "check_in"),
                checkOutDate,
                propertyData?.name || "Property",
                propertyData?.contact_email,
                accessToken, // Plaintext token for "View my reservation" link
                booking.total_price,
                booking.deposit_amount || booking.advance_amount,
                booking.property_id // For subdomain URL generation
              ),
            "Booking Approved",
            booking.guest_email || ""
          );

          // PII redaction via redactEmail helper — full email available in
          // emails_sent.approval doc below; Cloud Logging needs only correlation.
          logSuccess("Booking approval email sent to guest", {
            emailRedacted: redactEmail(after.guest_email as string | undefined),
          });

          // ✅ MARK EMAIL AS SENT: Prevents duplicate sends on retry
          await event.data?.after.ref.update({
            "emails_sent.approval": {
              sent_at: admin.firestore.FieldValue.serverTimestamp(),
              email: after.guest_email,
              booking_id: event.params.bookingId,
              provider_id: providerId ?? null,
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
            emailRedacted: redactEmail(emailTracking.rejection.email),
          });
          return;
        }

        try {
          const booking = after as any;

          // FLUTTER-7E: AUTO-HEAL missing booking_reference before email send so
          // sendBookingRejectedEmail never receives "" and the CF doesn't throw
          // (which would trigger 4× Functions retry storm). Mirrors the
          // cancellation branch (~:514).
          if (!booking.booking_reference) {
            const newRef = generateBookingReference(event.params.bookingId);
            await event.data?.after.ref.update({
              booking_reference: newRef,
              updated_at: admin.firestore.FieldValue.serverTimestamp(),
            });
            booking.booking_reference = newRef;
            logWarn(
              "[onStatusChange] Restored missing booking_reference (rejection)",
              {
                bookingId: event.params.bookingId,
                newReference: newRef,
                propertyId: booking.property_id,
                unitId: booking.unit_id,
              }
            );
          }

          // Fetch unit and property details
          // NOTE: Units are stored as subcollection: properties/{propertyId}/units/{unitId}
          const propertyDoc = await db
            .collection("properties")
            .doc(booking.property_id)
            .get();
          const propertyData = propertyDoc.data();

          // Send booking rejected email to guest with retry
          const providerId = await sendEmailWithRetry(
            () =>
              sendBookingRejectedEmail(
                booking.guest_email || "",
                booking.guest_name || "Guest",
                booking.booking_reference,
                propertyData?.name || "Property",
                booking.rejection_reason
              ),
            "Booking Rejected",
            booking.guest_email || ""
          );

          // PII redaction via redactEmail helper (see approval branch).
          logSuccess("Booking rejection email sent to guest", {
            emailRedacted: redactEmail(after.guest_email as string | undefined),
          });

          // ✅ MARK EMAIL AS SENT: Prevents duplicate sends on retry
          await event.data?.after.ref.update({
            "emails_sent.rejection": {
              sent_at: admin.firestore.FieldValue.serverTimestamp(),
              email: after.guest_email,
              booking_id: event.params.bookingId,
              provider_id: providerId ?? null,
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
            emailRedacted: redactEmail(emailTracking.cancellation.email),
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

            const providerId = await sendEmailWithRetry(
              () =>
                sendBookingCancellationEmail(
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
                ),
              "Booking Cancellation",
              booking.guest_email || ""
            );
            logSuccess("Cancellation email sent", {emailRedacted: redactEmail(booking.guest_email)});

            // ✅ MARK EMAIL AS SENT: Prevents duplicate sends on retry
            await event.data?.after.ref.update({
              "emails_sent.cancellation": {
                sent_at: admin.firestore.FieldValue.serverTimestamp(),
                email: after.guest_email,
                booking_id: event.params.bookingId,
                provider_id: providerId ?? null,
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

