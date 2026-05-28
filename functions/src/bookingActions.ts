// Owner booking actions (approve / reject) — F-67-01.
//
// Background: prior to this CF the owner dashboard called
// `bookingDoc.reference.update({status: ...})` directly via the Firestore SDK.
// That produced a silent no-op for the user (see audit/67 §G) and gave no
// server-side audit point. We move the state transition behind these
// callables so the UI gets a clear success/error contract and the rules
// surface can deny client status writes in a follow-up.

import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {db} from "./firebase";
import {logInfo, logSuccess, logWarn} from "./logger";
import {setUser} from "./sentry";
import {findBookingById} from "./utils/bookingLookup";

const REGION = "europe-west1";

interface BookingActionInput {
  bookingId?: unknown;
  reason?: unknown;
}

interface BookingActionOutput {
  success: boolean;
  bookingId: string;
  status: string;
}

/**
 * Validate that `value` is a non-empty trimmed string or throw HttpsError.
 *
 * @param {unknown} value - raw input from the callable request.
 * @param {string} field - field name, used in the error message.
 * @return {string} the trimmed string.
 */
function requireString(value: unknown, field: string): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${field} must be a string.`);
  }
  const trimmed = value.trim();
  if (!trimmed) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return trimmed;
}

/**
 * Resolve a booking owned by `uid` and ensure it is still pending. Throws
 * the appropriate HttpsError on missing booking, ownership mismatch, or
 * non-pending status so callable handlers can stay focused on the state
 * transition itself.
 *
 * @param {string} uid - authenticated owner UID.
 * @param {string} bookingId - booking document ID.
 * @return {Promise} reference + data of the located booking.
 */
async function loadOwnedPendingBooking(
  uid: string,
  bookingId: string
): Promise<{
  ref: FirebaseFirestore.DocumentReference;
  data: FirebaseFirestore.DocumentData;
}> {
  const lookup = await findBookingById(bookingId, uid);
  if (!lookup) {
    throw new HttpsError("not-found", "Booking not found.");
  }
  const {doc, data, propertyId} = lookup;
  if (!propertyId || typeof propertyId !== "string") {
    logWarn("[bookingActions] booking missing property_id", {
      bookingId,
      path: doc.ref.path,
    });
    throw new HttpsError(
      "failed-precondition",
      "Booking is missing property_id."
    );
  }
  const propDoc = await db.collection("properties").doc(propertyId).get();
  const ownerId = propDoc.data()?.owner_id;
  if (!propDoc.exists || ownerId !== uid) {
    logWarn("[bookingActions] ownership mismatch", {
      bookingId,
      propertyId,
      uid,
      ownerId,
    });
    throw new HttpsError(
      "permission-denied",
      "You do not own this booking."
    );
  }
  if (data.status !== "pending") {
    throw new HttpsError(
      "failed-precondition",
      `Booking is not pending (current status: ${data.status}).`
    );
  }
  return {ref: doc.ref, data};
}

/**
 * Require an authenticated caller. Sets the Sentry user context as a side
 * effect so downstream errors carry the owner UID.
 *
 * @param {CallableRequest<BookingActionInput>} request - callable request.
 * @return {string} authenticated UID.
 */
function requireAuth(request: CallableRequest<BookingActionInput>): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  setUser(uid);
  return uid;
}

/**
 * approveBooking — transitions a pending booking to `confirmed` and stamps
 * `approved_at`. Guests receive the confirmation email via the existing
 * `onBookingStatusChange` Firestore trigger (bookingManagement.ts).
 */
export const approveBooking = onCall<
  BookingActionInput,
  Promise<BookingActionOutput>
>(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
    maxInstances: 50,
    cors: true,
  },
  async (request) => {
    const uid = requireAuth(request);
    const bookingId = requireString(request.data?.bookingId, "bookingId");

    logInfo("[approveBooking] start", {bookingId, uid});
    const {ref} = await loadOwnedPendingBooking(uid, bookingId);
    await ref.update({
      status: "confirmed",
      approved_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    logSuccess("[approveBooking] booking confirmed", {
      bookingId,
      uid,
      path: ref.path,
    });
    return {success: true, bookingId, status: "confirmed"};
  }
);

/**
 * rejectBooking — transitions a pending booking to `cancelled` with a
 * rejection_reason. Email + iCal/availability fan-out runs in the existing
 * onBookingStatusChange trigger.
 */
export const rejectBooking = onCall<
  BookingActionInput,
  Promise<BookingActionOutput>
>(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
    maxInstances: 50,
    cors: true,
  },
  async (request) => {
    const uid = requireAuth(request);
    const bookingId = requireString(request.data?.bookingId, "bookingId");

    const rawReason = request.data?.reason;
    let reason = "Rejected by owner";
    if (rawReason !== undefined && rawReason !== null) {
      if (typeof rawReason !== "string") {
        throw new HttpsError("invalid-argument", "reason must be a string.");
      }
      const trimmed = rawReason.trim();
      if (trimmed.length > 500) {
        throw new HttpsError(
          "invalid-argument",
          "reason exceeds 500 characters."
        );
      }
      if (trimmed.length > 0) {
        reason = trimmed;
      }
    }

    logInfo("[rejectBooking] start", {bookingId, uid});
    const {ref} = await loadOwnedPendingBooking(uid, bookingId);
    await ref.update({
      status: "cancelled",
      rejection_reason: reason,
      rejected_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    logSuccess("[rejectBooking] booking rejected", {
      bookingId,
      uid,
      path: ref.path,
    });
    return {success: true, bookingId, status: "cancelled"};
  }
);
