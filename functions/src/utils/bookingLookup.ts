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

  // Strategy 2: Search all properties (OPTIMIZED with parallel queries)
  // OLD: O(N×M) sequential queries (~5s for 100 properties × 10 units)
  // NEW: Parallel queries (~500ms for same data)
  logInfo("[findBookingById] Trying optimized comprehensive search");
  const propertiesSnapshot = await db.collection("properties").get();

  if (propertiesSnapshot.empty) {
    logInfo("[findBookingById] No properties found");
  } else {
    // Step 1: Fetch all units for all properties IN PARALLEL
    const unitsPromises = propertiesSnapshot.docs.map(async (propDoc) => {
      const unitsSnapshot = await db
        .collection("properties")
        .doc(propDoc.id)
        .collection("units")
        .get();
      return {propDoc, unitsSnapshot};
    });

    const allUnits = await Promise.all(unitsPromises);

    // Step 2: Build list of all booking paths to check
    const bookingChecks: Array<{
      propId: string;
      unitId: string;
      bookingRef: FirebaseFirestore.DocumentReference;
    }> = [];

    for (const {propDoc, unitsSnapshot} of allUnits) {
      for (const unitDoc of unitsSnapshot.docs) {
        bookingChecks.push({
          propId: propDoc.id,
          unitId: unitDoc.id,
          bookingRef: db
            .collection("properties")
            .doc(propDoc.id)
            .collection("units")
            .doc(unitDoc.id)
            .collection("bookings")
            .doc(bookingId),
        });
      }
    }

    logInfo("[findBookingById] Checking paths in parallel", {
      totalPaths: bookingChecks.length,
    });

    // Step 3: Check all booking paths IN PARALLEL
    const bookingResults = await Promise.all(
      bookingChecks.map(async ({propId, unitId, bookingRef}) => {
        const bookingDoc = await bookingRef.get();
        return {propId, unitId, bookingDoc};
      })
    );

    // Step 4: Find first existing booking
    for (const {propId, unitId, bookingDoc} of bookingResults) {
      if (bookingDoc.exists) {
        const data = bookingDoc.data()!;
        logInfo("[findBookingById] Found via optimized search", {
          path: bookingDoc.ref.path,
        });
        return {
          doc: bookingDoc,
          data,
          propertyId: propId,
          unitId: unitId,
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
