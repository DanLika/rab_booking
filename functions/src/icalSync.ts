import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as https from 'https';
import * as http from 'http';
import {admin} from "./firebase";
import {logInfo, logError, logWarn, logSuccess} from "./logger";

// NOTE: Scheduled sync (syncAllIcalFeeds) has been removed due to deployment timeout issues
// with node-ical package. To enable automatic syncing:
// 1. Set up Cloud Scheduler in GCP Console
// 2. Point it to the syncIcalFeedNow endpoint
// 3. Schedule it to run hourly

/**
 * Callable function to sync a specific iCal feed immediately
 * Called from Owner Dashboard when user clicks "Sync Now"
 */
export const syncIcalFeedNow = onCall(async (request) => {
  // Check authentication
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { feedId } = request.data;

  if (!feedId) {
    throw new HttpsError('invalid-argument', 'feedId is required');
  }

  const db = admin.firestore();

  try {
    logInfo("[iCal Sync] Manual sync requested for feed", {feedId});

    // Get feed document
    const feedDoc = await db.collection('ical_feeds').doc(feedId).get();

    if (!feedDoc.exists) {
      throw new HttpsError('not-found', 'Feed not found');
    }

    // Verify user owns this feed
    const feedData = feedDoc.data()!;
    const propertyDoc = await db.collection('properties').doc(feedData.property_id).get();

    if (!propertyDoc.exists || propertyDoc.data()?.owner_id !== request.auth.uid) {
      throw new HttpsError('permission-denied', 'You do not own this feed');
    }

    // Sync the feed
    const bookingsCreated = await syncSingleFeed(db, feedId, feedData);

    logSuccess("[iCal Sync] Manual sync completed for feed", {feedId, bookingsCreated});

    return {
      success: true,
      message: 'Feed synced successfully',
      bookingsCreated: bookingsCreated
    };
  } catch (error) {
    logError("[iCal Sync] Error in manual sync", error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    throw new HttpsError('internal', 'Sync failed: ' + errorMessage);
  }
});

/**
 * Sync a single iCal feed
 * Returns number of bookings created
 */
async function syncSingleFeed(
  db: FirebaseFirestore.Firestore,
  feedId: string,
  feedData: any
): Promise<number> {
  const { unit_id, ical_url, platform } = feedData;

  logInfo("[iCal Sync] Syncing feed", {feedId, unitId: unit_id, platform});

  try {
    // Fetch iCal data
    const icalData = await fetchIcalData(ical_url);

    // Parse iCal data
    const events = await parseIcalData(icalData);

    logInfo("[iCal Sync] Parsed events from platform", {platform, eventCount: events.length});

    // Delete old events for this feed
    await deleteOldEvents(db, feedId);

    // Insert new events
    const insertedCount = await insertNewEvents(db, feedId, unit_id, platform, events);

    // Update feed metadata
    await db.collection('ical_feeds').doc(feedId).update({
      last_synced: admin.firestore.Timestamp.now(),
      sync_count: admin.firestore.FieldValue.increment(1),
      event_count: insertedCount,
      status: 'active',
      last_error: null,
      updated_at: admin.firestore.Timestamp.now(),
    });

    logSuccess("[iCal Sync] Successfully synced feed", {feedId, eventCount: insertedCount});

    return insertedCount; // Return number of bookings created
  } catch (error) {
    logError("[iCal Sync] Error syncing feed", error, {feedId});

    const errorMessage = error instanceof Error ? error.message : 'Unknown error';

    // Update feed with error status
    await db.collection('ical_feeds').doc(feedId).update({
      status: 'error',
      last_error: errorMessage,
      updated_at: admin.firestore.Timestamp.now(),
    });

    throw error;
  }
}

/**
 * Fetch iCal data from URL
 */
function fetchIcalData(url: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const protocol = url.startsWith('https') ? https : http;

    protocol
      .get(url, (response) => {
        if (response.statusCode !== 200) {
          reject(new Error(`HTTP ${response.statusCode}: ${response.statusMessage}`));
          return;
        }

        let data = '';

        response.on('data', (chunk) => {
          data += chunk;
        });

        response.on('end', () => {
          resolve(data);
        });
      })
      .on('error', (error) => {
        reject(error);
      });
  });
}

/**
 * Parse iCal data and extract events
 */
async function parseIcalData(icalData: string): Promise<any[]> {
  return new Promise((resolve, reject) => {
    try {
      // Lazy load node-ical only when function is called (not at module load time)
      const ical = require('node-ical');
      const parsed = ical.parseICS(icalData);
      const events: any[] = [];

      for (const [uid, event] of Object.entries(parsed)) {
        if ((event as any).type === 'VEVENT') {
          const vevent = event as any;

          // Extract start and end dates
          const startDate = vevent.start ? new Date(vevent.start) : null;
          const endDate = vevent.end ? new Date(vevent.end) : null;

          if (!startDate || !endDate) {
            logWarn("[iCal Sync] Skipping event with missing dates", {uid});
            continue;
          }

          // Skip events in the past (older than 30 days)
          const thirtyDaysAgo = new Date();
          thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

          if (endDate < thirtyDaysAgo) {
            logInfo("[iCal Sync] Skipping past event", {uid});
            continue;
          }

          events.push({
            externalId: uid,
            startDate: startDate,
            endDate: endDate,
            summary: vevent.summary || 'Rezervacija',
            description: vevent.description || null,
          });
        }
      }

      resolve(events);
    } catch (error) {
      reject(error);
    }
  });
}

/**
 * Delete old events for a feed
 */
async function deleteOldEvents(
  db: FirebaseFirestore.Firestore,
  feedId: string
): Promise<void> {
  const eventsSnapshot = await db
    .collection('ical_events')
    .where('feed_id', '==', feedId)
    .get();

  const batch = db.batch();

  eventsSnapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();

  logInfo("[iCal Sync] Deleted old events for feed", {feedId, count: eventsSnapshot.size});
}

/**
 * Insert new events for a feed
 */
async function insertNewEvents(
  db: FirebaseFirestore.Firestore,
  feedId: string,
  unitId: string,
  platform: string,
  events: any[]
): Promise<number> {
  if (events.length === 0) {
    return 0;
  }

  // Firestore batch can handle max 500 operations
  const batchSize = 500;
  let insertedCount = 0;

  for (let i = 0; i < events.length; i += batchSize) {
    const batch = db.batch();
    const batchEvents = events.slice(i, i + batchSize);

    batchEvents.forEach((event) => {
      const docRef = db.collection('ical_events').doc();

      batch.set(docRef, {
        feed_id: feedId,
        unit_id: unitId,
        source: platform,
        external_id: event.externalId,
        start_date: admin.firestore.Timestamp.fromDate(event.startDate),
        end_date: admin.firestore.Timestamp.fromDate(event.endDate),
        guest_name: event.summary || `${capitalizeFirstLetter(platform)} Gost`,
        description: event.description,
        created_at: admin.firestore.Timestamp.now(),
        updated_at: admin.firestore.Timestamp.now(),
      });
    });

    await batch.commit();
    insertedCount += batchEvents.length;
  }

  logInfo("[iCal Sync] Inserted new events for feed", {feedId, count: insertedCount});

  return insertedCount;
}

/**
 * Helper function to capitalize first letter
 */
function capitalizeFirstLetter(str: string): string {
  if (!str) return str;

  // Handle special cases
  if (str === 'booking_com') return 'Booking.com';
  if (str === 'airbnb') return 'Airbnb';

  return str.charAt(0).toUpperCase() + str.slice(1);
}
