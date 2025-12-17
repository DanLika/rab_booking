/**
 * Booking Lookup Utility
 *
 * IMPORTANT: FieldPath.documentId() does NOT work with collectionGroup queries!
 * Firestore expects full document path, not just ID when using collectionGroup.
 *
 * This utility provides safe methods to find bookings by ID using alternative strategies.
 */

import * as admin from "firebase-admin";
import {logInfo, logWarn} from "../logger";

const db = admin.firestore();

export interface BookingLookupResult {
  doc: FirebaseFirestore.DocumentSnapshot;
  data: FirebaseFirestore.DocumentData;
  propertyId: string;
  unitId: string;
}

/**
 * Find a booking document by ID
 *
 * Strategy 1: Query by owner_id (requires owner_id in booking document)
 * Strategy 2: Search through all properties/units (slower but always works)
 *
 * @param bookingId - The booking document ID
 * @param ownerId - Optional owner ID to speed up lookup
 * @returns BookingLookupResult or null if not found
 */
export async function findBookingById(
  bookingId: string,
  ownerId?: string
): Promise<BookingLookupResult | null> {
  logInfo("[findBookingById] Looking for booking", {bookingId, ownerId});

  // Strategy 1: If we have owner_id, query by it (fast)
  if (ownerId) {
    const ownerBookingsSnapshot = await db
      .collectionGroup("bookings")
      .where("owner_id", "==", ownerId)
      .get();

    for (const doc of ownerBookingsSnapshot.docs) {
      if (doc.id === bookingId) {
        const data = doc.data();
        logInfo("[findBookingById] Found via owner_id query", {
          path: doc.ref.path,
        });
        return {
          doc,
          data,
          propertyId: data.property_id,
          unitId: data.unit_id,
        };
      }
    }
    logWarn("[findBookingById] Not found via owner_id query", {bookingId});
  }

  // Strategy 2: Search all properties (slower but comprehensive)
  logInfo("[findBookingById] Trying comprehensive search");
  const propertiesSnapshot = await db.collection("properties").get();

  for (const propDoc of propertiesSnapshot.docs) {
    const unitsSnapshot = await db
      .collection("properties")
      .doc(propDoc.id)
      .collection("units")
      .get();

    for (const unitDoc of unitsSnapshot.docs) {
      const bookingDoc = await db
        .collection("properties")
        .doc(propDoc.id)
        .collection("units")
        .doc(unitDoc.id)
        .collection("bookings")
        .doc(bookingId)
        .get();

      if (bookingDoc.exists) {
        const data = bookingDoc.data()!;
        logInfo("[findBookingById] Found via comprehensive search", {
          path: bookingDoc.ref.path,
        });
        return {
          doc: bookingDoc,
          data,
          propertyId: propDoc.id,
          unitId: unitDoc.id,
        };
      }
    }
  }

  // Strategy 3: Check legacy top-level bookings collection
  const legacyDoc = await db.collection("bookings").doc(bookingId).get();
  if (legacyDoc.exists) {
    const data = legacyDoc.data()!;
    logInfo("[findBookingById] Found in legacy collection", {
      path: legacyDoc.ref.path,
    });
    return {
      doc: legacyDoc,
      data,
      propertyId: data.property_id,
      unitId: data.unit_id,
    };
  }

  logWarn("[findBookingById] Booking not found", {bookingId});
  return null;
}

/**
 * Find a booking by booking_reference field
 *
 * @param bookingReference - The booking reference string (e.g., "BB-XXXX")
 * @returns BookingLookupResult or null if not found
 */
export async function findBookingByReference(
  bookingReference: string
): Promise<BookingLookupResult | null> {
  logInfo("[findBookingByReference] Looking for booking", {bookingReference});

  const snapshot = await db
    .collectionGroup("bookings")
    .where("booking_reference", "==", bookingReference)
    .limit(1)
    .get();

  if (snapshot.empty) {
    // Check legacy collection
    const legacySnapshot = await db
      .collection("bookings")
      .where("booking_reference", "==", bookingReference)
      .limit(1)
      .get();

    if (legacySnapshot.empty) {
      logWarn("[findBookingByReference] Not found", {bookingReference});
      return null;
    }

    const doc = legacySnapshot.docs[0];
    const data = doc.data();
    return {
      doc,
      data,
      propertyId: data.property_id,
      unitId: data.unit_id,
    };
  }

  const doc = snapshot.docs[0];
  const data = doc.data();
  logInfo("[findBookingByReference] Found", {path: doc.ref.path});
  return {
    doc,
    data,
    propertyId: data.property_id,
    unitId: data.unit_id,
  };
}
