import {db, admin} from "../firebase";
import {logError} from "../logger";

/**
 * Email tracking record for idempotency
 * Prevents duplicate emails on function retries or rapid status changes
 */
export interface EmailSent {
  sent_at: admin.firestore.Timestamp;
  email: string;
  booking_id?: string;
  // Resend message id captured from API response. null when SDK
  // returned success but no id (silent-drop signal). See audit/26 PR-B.
  provider_id?: string | null;
}

/**
 * Email tracking for booking document
 * Add this to booking schema to track which emails have been sent
 *
 * @example
 * interface BookingDocument {
 *   // ... other fields
 *   emails_sent?: {
 *     approval?: EmailSent;
 *     rejection?: EmailSent;
 *     cancellation?: EmailSent;
 *     confirmation?: EmailSent;
 *   }
 * }
 */
export interface BookingEmailTracking {
  approval?: EmailSent;
  rejection?: EmailSent;
  cancellation?: EmailSent;
  confirmation?: EmailSent;
  bank_transfer_instructions?: EmailSent;
  pending_request?: EmailSent;
  pending_owner_notification?: EmailSent;
  owner_notification?: EmailSent;
  // audit/34 §5 — per-trigger idempotency marker for onBookingCreated.
  // Reuses emails_sent map so existing dot-notation + read path stays
  // consistent; not an email send.
  initial_trigger_processed?: EmailSent;
}

/**
 * Property and unit names for booking emails
 */
export interface PropertyUnitNames {
  propertyName: string;
  propertyData?: any; // Full property doc if needed
  unitName?: string;
  unitData?: any; // Full unit doc if needed
}

/**
 * Fetch property and unit details for booking emails
 *
 * This is the SINGLE SOURCE OF TRUTH for all property/unit fetches
 * Used by: bookingManagement, guestCancelBooking, atomicBooking, stripePayment
 *
 * IMPORTANT: Always use this function instead of duplicating fetch logic
 * This ensures consistent error handling and fallback values across all functions
 *
 * @param propertyId - Property document ID
 * @param unitId - Unit document ID (optional)
 * @param context - Context for error logging (e.g., 'autoCancelExpired', 'onStatusChange')
 * @param fetchFullData - If true, returns full propertyData/unitData objects
 * @return PropertyUnitNames with safe fallback values
 *
 * @example
 * // Just names (for emails)
 * const { propertyName, unitName } = await fetchPropertyAndUnitDetails(
 *   booking.property_id,
 *   booking.unit_id,
 *   'autoCancelExpired'
 * );
 *
 * @example
 * // Full data (for complex logic)
 * const { propertyName, propertyData, unitData } = await fetchPropertyAndUnitDetails(
 *   booking.property_id,
 *   booking.unit_id,
 *   'onBookingCreated',
 *   true // fetchFullData
 * );
 */
export async function fetchPropertyAndUnitDetails(
  propertyId: string,
  unitId?: string,
  context: string = "unknown",
  fetchFullData: boolean = false
): Promise<PropertyUnitNames> {
  let propertyName = "Property"; // Safe fallback
  let propertyData: any = null;
  let unitName: string | undefined;
  let unitData: any = null;

  // Fetch property
  if (propertyId) {
    try {
      const propDoc = await db.collection("properties").doc(propertyId).get();

      if (!propDoc.exists) {
        logError(`[${context}] Property not found`, null, {propertyId});
        // Keep fallback value
      } else {
        propertyData = propDoc.data();
        propertyName = propertyData?.name || "Property";
      }
    } catch (error) {
      logError(`[${context}] Failed to fetch property`, error, {propertyId});
      // Keep fallback value
    }
  }

  // Fetch unit (if provided)
  if (propertyId && unitId) {
    try {
      const unitDoc = await db
        .collection("properties")
        .doc(propertyId)
        .collection("units")
        .doc(unitId)
        .get();

      if (!unitDoc.exists) {
        logError(`[${context}] Unit not found`, null, {propertyId, unitId});
        // unitName stays undefined
      } else {
        unitData = unitDoc.data();
        unitName = unitData?.name;
      }
    } catch (error) {
      logError(`[${context}] Failed to fetch unit`, error, {propertyId, unitId});
      // unitName stays undefined
    }
  }

  return {
    propertyName,
    propertyData: fetchFullData ? propertyData : undefined,
    unitName,
    unitData: fetchFullData ? unitData : undefined,
  };
}

/**
 * Persist a single `emails_sent.<key>` entry on a booking doc after a
 * successful send. Idempotent — caller passes the pre-read `existing` snapshot
 * so we can skip the write if the key is already present.
 *
 * `providerId` is the Resend message id when threaded through
 * `sendEmailWithValidation` (audit/26 §5 / PR-B); pass `null` (default) when
 * the send chain returns `Promise<void>` and the id is dropped at the wrapper.
 *
 * Errors are swallowed (logged) — a tracking write failure must not break the
 * booking flow itself.
 */
export async function persistEmailSent(
  bookingRef: admin.firestore.DocumentReference,
  key: keyof BookingEmailTracking,
  email: string,
  bookingId: string,
  providerId: string | null = null,
  existing?: BookingEmailTracking
): Promise<void> {
  if (existing?.[key]) {
    return;
  }
  try {
    await bookingRef.update({
      [`emails_sent.${key}`]: {
        sent_at: admin.firestore.FieldValue.serverTimestamp(),
        email,
        booking_id: bookingId,
        provider_id: providerId,
      },
    });
  } catch (err) {
    logError(
      `[persistEmailSent] Failed to write emails_sent.${key}`,
      err,
      {bookingId}
    );
  }
}
