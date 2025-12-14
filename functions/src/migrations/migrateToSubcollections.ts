import * as functions from "firebase-functions/v2/https";
import { db } from "../firebase";
import { logInfo, logError, logSuccess } from "../logger";

/**
 * Migration Function: Migriraj bookings i ical_events u subcollections
 * 
 * Ova funkcija KOPIRA podatke iz stare strukture u novu:
 * - bookings → properties/{propertyId}/units/{unitId}/bookings
 * - ical_events → properties/{propertyId}/ical_events
 * 
 * ⚠️ VAŽNO: Stara struktura OSTAJE - ne briše se automatski!
 * Obriši staru strukturu SAMO nakon što se potvrdi da sve radi.
 * 
 * Pokreni: firebase functions:call migrateToSubcollections
 */
export const migrateToSubcollections = functions.onCall(async (request) => {
  const batchSize = 500;
  let bookingsProcessed = 0;
  let bookingsErrors = 0;
  let icalEventsProcessed = 0;
  let icalEventsErrors = 0;

  logInfo("[Migration] Starting migration to subcollections...");

  try {
    // ============================================
    // 1. MIGRIRAJ BOOKINGS
    // ============================================
    logInfo("[Migration] Step 1: Migrating bookings...");
    const bookingsSnapshot = await db.collection("bookings").get();
    const totalBookings = bookingsSnapshot.size;
    logInfo(`[Migration] Found ${totalBookings} bookings to migrate`);

    if (totalBookings === 0) {
      logInfo("[Migration] No bookings to migrate");
    } else {
      for (let i = 0; i < bookingsSnapshot.docs.length; i += batchSize) {
        const batch = db.batch();
        const batchDocs = bookingsSnapshot.docs.slice(i, i + batchSize);

        for (const bookingDoc of batchDocs) {
          try {
            const bookingData = bookingDoc.data();
            const propertyId = bookingData.property_id;
            const unitId = bookingData.unit_id;

            if (!propertyId || !unitId) {
              logError(
                `[Migration] Skipping booking ${bookingDoc.id}: missing property_id or unit_id`,
                { bookingId: bookingDoc.id, propertyId, unitId }
              );
              bookingsErrors++;
              continue;
            }

            // Verify property exists
            const propertyDoc = await db
              .collection("properties")
              .doc(propertyId)
              .get();
            if (!propertyDoc.exists) {
              logError(
                `[Migration] Skipping booking ${bookingDoc.id}: property ${propertyId} not found`,
                { bookingId: bookingDoc.id, propertyId }
              );
              bookingsErrors++;
              continue;
            }

            // Verify unit exists
            const unitDoc = await db
              .collection("properties")
              .doc(propertyId)
              .collection("units")
              .doc(unitId)
              .get();

            if (!unitDoc.exists) {
              logError(
                `[Migration] Skipping booking ${bookingDoc.id}: unit ${unitId} not found`,
                { bookingId: bookingDoc.id, propertyId, unitId }
              );
              bookingsErrors++;
              continue;
            }

            // ✅ KOPIRAJ u novu strukturu (ne briše staru!)
            const newRef = db
              .collection("properties")
              .doc(propertyId)
              .collection("units")
              .doc(unitId)
              .collection("bookings")
              .doc(bookingDoc.id);

            batch.set(newRef, bookingData);
            bookingsProcessed++;
          } catch (error) {
            logError(
              `[Migration] Error processing booking ${bookingDoc.id}`,
              { error, bookingId: bookingDoc.id }
            );
            bookingsErrors++;
          }
        }

        // Commit batch
        await batch.commit();
        logInfo(
          `[Migration] Processed ${bookingsProcessed}/${totalBookings} bookings...`
        );
      }
    }

    // ============================================
    // 2. MIGRIRAJ ICAL EVENTS
    // ============================================
    logInfo("[Migration] Step 2: Migrating ical_events...");
    const icalEventsSnapshot = await db.collection("ical_events").get();
    const totalIcalEvents = icalEventsSnapshot.size;
    logInfo(`[Migration] Found ${totalIcalEvents} ical_events to migrate`);

    if (totalIcalEvents === 0) {
      logInfo("[Migration] No ical_events to migrate");
    } else {
      for (let i = 0; i < icalEventsSnapshot.docs.length; i += batchSize) {
        const batch = db.batch();
        const batchDocs = icalEventsSnapshot.docs.slice(i, i + batchSize);

        for (const eventDoc of batchDocs) {
          try {
            const eventData = eventDoc.data();
            const propertyId = eventData.property_id;

            if (!propertyId) {
              logError(
                `[Migration] Skipping ical_event ${eventDoc.id}: missing property_id`,
                { eventId: eventDoc.id }
              );
              icalEventsErrors++;
              continue;
            }

            // Verify property exists
            const propertyDoc = await db
              .collection("properties")
              .doc(propertyId)
              .get();
            if (!propertyDoc.exists) {
              logError(
                `[Migration] Skipping ical_event ${eventDoc.id}: property ${propertyId} not found`,
                { eventId: eventDoc.id, propertyId }
              );
              icalEventsErrors++;
              continue;
            }

            // ✅ KOPIRAJ u novu strukturu (ne briše staru!)
            const newRef = db
              .collection("properties")
              .doc(propertyId)
              .collection("ical_events")
              .doc(eventDoc.id);

            batch.set(newRef, eventData);
            icalEventsProcessed++;
          } catch (error) {
            logError(
              `[Migration] Error processing ical_event ${eventDoc.id}`,
              { error, eventId: eventDoc.id }
            );
            icalEventsErrors++;
          }
        }

        // Commit batch
        await batch.commit();
        logInfo(
          `[Migration] Processed ${icalEventsProcessed}/${totalIcalEvents} ical_events...`
        );
      }
    }

    // ============================================
    // 3. VALIDACIJA
    // ============================================
    logInfo("[Migration] Step 3: Validating migration...");

    // Count old structure
    const oldBookingsCount = (await db.collection("bookings").get()).size;
    const oldIcalEventsCount = (
      await db.collection("ical_events").get()
    ).size;

    // Count new structure (collection group query)
    const newBookingsSnapshot = await db.collectionGroup("bookings").get();
    const newBookingsCount = newBookingsSnapshot.size;

    // Count ical_events manually (query all properties)
    let newIcalEventsCount = 0;
    const propertiesSnapshot = await db.collection("properties").get();
    for (const propertyDoc of propertiesSnapshot.docs) {
      const eventsSnapshot = await db
        .collection("properties")
        .doc(propertyDoc.id)
        .collection("ical_events")
        .get();
      newIcalEventsCount += eventsSnapshot.size;
    }

    const bookingsValid = bookingsProcessed === newBookingsCount;
    const icalEventsValid = icalEventsProcessed === newIcalEventsCount;

    logInfo("[Migration] Validation Results:");
    logInfo(
      `  Bookings: ${bookingsProcessed} migrated, ${newBookingsCount} in new structure (${bookingsValid ? "✅" : "❌"})`
    );
    logInfo(
      `  iCal Events: ${icalEventsProcessed} migrated, ${newIcalEventsCount} in new structure (${icalEventsValid ? "✅" : "❌"})`
    );

    const success = bookingsValid && icalEventsValid;

    if (success) {
      logSuccess(
        "[Migration] Migration completed successfully!",
        {
          bookings: {
            old: oldBookingsCount,
            migrated: bookingsProcessed,
            new: newBookingsCount,
            errors: bookingsErrors,
          },
          icalEvents: {
            old: oldIcalEventsCount,
            migrated: icalEventsProcessed,
            new: newIcalEventsCount,
            errors: icalEventsErrors,
          },
        }
      );
    } else {
      logError(
        "[Migration] Migration completed with validation errors",
        {
          bookings: {
            old: oldBookingsCount,
            migrated: bookingsProcessed,
            new: newBookingsCount,
            errors: bookingsErrors,
            valid: bookingsValid,
          },
          icalEvents: {
            old: oldIcalEventsCount,
            migrated: icalEventsProcessed,
            new: newIcalEventsCount,
            errors: icalEventsErrors,
            valid: icalEventsValid,
          },
        }
      );
    }

    return {
      success,
      bookings: {
        old: oldBookingsCount,
        migrated: bookingsProcessed,
        new: newBookingsCount,
        errors: bookingsErrors,
        valid: bookingsValid,
      },
      icalEvents: {
        old: oldIcalEventsCount,
        migrated: icalEventsProcessed,
        new: newIcalEventsCount,
        errors: icalEventsErrors,
        valid: icalEventsValid,
      },
      message: success
        ? "✅ Migration completed successfully! Old structure still exists - delete it after confirming everything works."
        : "⚠️ Migration completed with validation errors. Check logs for details.",
    };
  } catch (error) {
    logError("[Migration] Migration failed", { error });
    throw new functions.HttpsError(
      "internal",
      "Migration failed",
      error instanceof Error ? error.message : String(error)
    );
  }
});

/**
 * Cleanup Function: Obriši staru strukturu
 * 
 * ⚠️ UPOZORENJE: Ova funkcija BRIŠE podatke iz stare strukture!
 * Pokreni SAMO nakon što se potvrdi da sve radi sa novom strukturom.
 * 
 * Pokreni: firebase functions:call deleteOldStructures
 */
export const deleteOldStructures = functions.onCall(async (request) => {
  logInfo("[Cleanup] Starting cleanup of old structures...");

  try {
    const batchSize = 500;

    // ============================================
    // 1. OBRISI STARE BOOKINGS
    // ============================================
    logInfo("[Cleanup] Deleting old bookings collection...");
    const bookingsSnapshot = await db.collection("bookings").get();
    const totalBookings = bookingsSnapshot.size;
    logInfo(`[Cleanup] Found ${totalBookings} bookings to delete`);

    let bookingsDeleted = 0;
    for (let i = 0; i < bookingsSnapshot.docs.length; i += batchSize) {
      const batch = db.batch();
      const batchDocs = bookingsSnapshot.docs.slice(i, i + batchSize);

      for (const doc of batchDocs) {
        batch.delete(doc.ref);
        bookingsDeleted++;
      }

      await batch.commit();
      logInfo(`[Cleanup] Deleted ${bookingsDeleted}/${totalBookings} bookings...`);
    }

    // ============================================
    // 2. OBRISI STARE ICAL EVENTS
    // ============================================
    logInfo("[Cleanup] Deleting old ical_events collection...");
    const icalEventsSnapshot = await db.collection("ical_events").get();
    const totalIcalEvents = icalEventsSnapshot.size;
    logInfo(`[Cleanup] Found ${totalIcalEvents} ical_events to delete`);

    let icalEventsDeleted = 0;
    for (let i = 0; i < icalEventsSnapshot.docs.length; i += batchSize) {
      const batch = db.batch();
      const batchDocs = icalEventsSnapshot.docs.slice(i, i + batchSize);

      for (const doc of batchDocs) {
        batch.delete(doc.ref);
        icalEventsDeleted++;
      }

      await batch.commit();
      logInfo(
        `[Cleanup] Deleted ${icalEventsDeleted}/${totalIcalEvents} ical_events...`
      );
    }

    logSuccess("[Cleanup] Cleanup completed successfully!", {
      bookingsDeleted,
      icalEventsDeleted,
    });

    return {
      success: true,
      bookingsDeleted,
      icalEventsDeleted,
      message: "✅ Old structures deleted successfully!",
    };
  } catch (error) {
    logError("[Cleanup] Cleanup failed", { error });
    throw new functions.HttpsError(
      "internal",
      "Cleanup failed",
      error instanceof Error ? error.message : String(error)
    );
  }
});
