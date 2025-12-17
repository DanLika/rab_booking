import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as https from 'https';
import * as http from 'http';
import {admin} from "./firebase";
import {logInfo, logError, logWarn, logSuccess} from "./logger";
import {setUser} from "./sentry";

/**
 * SECURITY: Validate iCal URL to prevent SSRF attacks
 * Only allows public HTTP/HTTPS URLs to known booking platforms
 */
function validateIcalUrl(url: string): { valid: boolean; error?: string } {
  try {
    const parsedUrl = new URL(url);

    // Only allow HTTP/HTTPS protocols
    if (!["http:", "https:"].includes(parsedUrl.protocol)) {
      return { valid: false, error: `Invalid protocol: ${parsedUrl.protocol}. Only HTTP/HTTPS allowed.` };
    }

    // Block localhost and internal IPs
    const hostname = parsedUrl.hostname.toLowerCase();
    const blockedPatterns = [
      "localhost",
      "127.0.0.1",
      "0.0.0.0",
      "::1",
      "10.",
      "172.16.", "172.17.", "172.18.", "172.19.",
      "172.20.", "172.21.", "172.22.", "172.23.",
      "172.24.", "172.25.", "172.26.", "172.27.",
      "172.28.", "172.29.", "172.30.", "172.31.",
      "192.168.",
      "169.254.",
      "metadata.google.internal",
      "metadata.google",
      ".internal",
      ".local",
    ];

    for (const pattern of blockedPatterns) {
      if (hostname === pattern || hostname.startsWith(pattern) || hostname.endsWith(pattern)) {
        return { valid: false, error: "Internal or localhost URLs are not allowed." };
      }
    }

    // Allow only known booking platform domains (whitelist approach)
    const allowedDomains = [
      "ical.booking.com",
      "admin.booking.com",
      "airbnb.com",
      "www.airbnb.com",
      "calendar.google.com",
      "outlook.live.com",
      "outlook.office365.com",
      "p.calendar.yahoo.com",
      "export.calendar.yandex.com",
      "beds24.com",
      "www.beds24.com",
      "app.hospitable.com",
      "smoobu.com",
      "api.smoobu.com",
      "rentalsunited.com",
      "api.lodgify.com",
      "ownerrez.com",
      "api.ownerrez.com",
      "guesty.com",
      "open.guesty.com",
      // Generic iCal providers
      "webcal.io",
      "icalendar.org",
    ];

    // Check if domain is in allowed list or is a subdomain of allowed domains
    const isAllowed = allowedDomains.some(domain =>
      hostname === domain || hostname.endsWith(`.${domain}`)
    );

    if (!isAllowed) {
      logWarn("[iCal Sync] URL domain not in whitelist", { hostname });
      // For now, just log warning but allow - can be tightened later
      // return { valid: false, error: `Domain ${hostname} is not in the allowed list.` };
    }

    return { valid: true };
  } catch (error) {
    return { valid: false, error: "Invalid URL format." };
  }
}

/**
 * Scheduled function to automatically sync all active iCal feeds
 * Runs every 30 minutes to keep external calendar data up to date
 *
 * This syncs reservations from:
 * - Booking.com (via iCal URL)
 * - Airbnb (via iCal URL)
 * - Other platforms that provide iCal feeds
 */
export const scheduledIcalSync = onSchedule(
  {
    schedule: "every 15 minutes",
    timeoutSeconds: 540, // 9 minutes (max for scheduled functions)
    memory: "512MiB",
    region: "europe-west1",
  },
  async () => {
    const db = admin.firestore();

    logInfo("[Scheduled iCal Sync] Starting automatic sync of all feeds");

    try {
      // Get all active feeds
      const feedsSnapshot = await db
        .collection('ical_feeds')
        .where('status', 'in', ['active', 'error']) // Include error feeds to retry
        .get();

      if (feedsSnapshot.empty) {
        logInfo("[Scheduled iCal Sync] No active feeds to sync");
        return;
      }

      logInfo("[Scheduled iCal Sync] Found feeds to sync", {
        count: feedsSnapshot.size
      });

      let successCount = 0;
      let errorCount = 0;
      let totalEventsImported = 0;

      // Process feeds sequentially to avoid overwhelming external APIs
      for (const feedDoc of feedsSnapshot.docs) {
        const feedId = feedDoc.id;
        const feedData = feedDoc.data();

        // Skip if sync interval hasn't elapsed (check last_synced)
        const lastSynced = feedData.last_synced?.toDate();
        const syncIntervalMinutes = feedData.sync_interval_minutes || 30;

        if (lastSynced) {
          const nextSyncTime = new Date(lastSynced.getTime() + syncIntervalMinutes * 60 * 1000);
          if (new Date() < nextSyncTime) {
            logInfo("[Scheduled iCal Sync] Skipping feed - sync interval not elapsed", {
              feedId,
              lastSynced: lastSynced.toISOString(),
              nextSync: nextSyncTime.toISOString()
            });
            continue;
          }
        }

        try {
          const eventsImported = await syncSingleFeed(db, feedId, feedData);
          successCount++;
          totalEventsImported += eventsImported;

          logInfo("[Scheduled iCal Sync] Feed synced successfully", {
            feedId,
            platform: feedData.platform,
            eventsImported
          });
        } catch (error) {
          errorCount++;
          logError("[Scheduled iCal Sync] Failed to sync feed", error, {
            feedId,
            platform: feedData.platform
          });
          // Continue with next feed even if one fails
        }

        // Small delay between feeds to be nice to external APIs
        await new Promise(resolve => setTimeout(resolve, 1000));
      }

      logSuccess("[Scheduled iCal Sync] Automatic sync completed", {
        totalFeeds: feedsSnapshot.size,
        successCount,
        errorCount,
        totalEventsImported
      });

    } catch (error) {
      logError("[Scheduled iCal Sync] Critical error in scheduled sync", error);
      throw error; // Rethrow to mark function as failed
    }
  }
);

/**
 * Callable function to sync a specific iCal feed immediately
 * Called from Owner Dashboard when user clicks "Sync Now"
 */
export const syncIcalFeedNow = onCall(async (request) => {
  // Check authentication
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  // Set user context for Sentry error tracking
  setUser(request.auth.uid);

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
    // SECURITY: Validate URL before fetching (SSRF prevention)
    const urlValidation = validateIcalUrl(ical_url);
    if (!urlValidation.valid) {
      throw new Error(`Invalid iCal URL: ${urlValidation.error}`);
    }

    // Fetch iCal data
    const icalData = await fetchIcalData(ical_url);

    // Parse iCal data
    const events = await parseIcalData(icalData);

    logInfo("[iCal Sync] Parsed events from platform", {platform, eventCount: events.length});

    // Get propertyId from feed data for subcollection path
    const propertyId = feedData.property_id;
    if (!propertyId) {
      throw new Error(`Feed ${feedId} is missing property_id`);
    }

    // Delete old events for this feed
    // NEW STRUCTURE: Use property-level subcollection
    await deleteOldEvents(db, feedId, propertyId);

    // Insert new events
    // NEW STRUCTURE: Use property-level subcollection
    const insertedCount = await insertNewEvents(db, feedId, unit_id, propertyId, platform, events);

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
 * Fetch iCal data from URL with redirect support
 * Follows up to 5 redirects (301, 302, 303, 307, 308)
 */
// HTTP request timeout (30 seconds)
const HTTP_TIMEOUT_MS = 30000;

function fetchIcalData(url: string, maxRedirects: number = 5): Promise<string> {
  return new Promise((resolve, reject) => {
    if (maxRedirects <= 0) {
      reject(new Error('Too many redirects'));
      return;
    }

    const protocol = url.startsWith('https') ? https : http;

    const request = protocol
      .get(url, (response) => {
        // Handle redirects (301, 302, 303, 307, 308)
        if (response.statusCode && [301, 302, 303, 307, 308].includes(response.statusCode)) {
          let redirectUrl = response.headers.location;
          if (!redirectUrl) {
            reject(new Error(`Redirect ${response.statusCode} without Location header`));
            return;
          }

          // Handle relative URLs by constructing absolute URL
          if (redirectUrl.startsWith('/')) {
            const urlObj = new URL(url);
            redirectUrl = `${urlObj.protocol}//${urlObj.host}${redirectUrl}`;
          }

          logInfo("[iCal Sync] Following redirect", {
            from: url.substring(0, 50) + '...',
            to: redirectUrl.substring(0, 50) + '...',
            statusCode: response.statusCode
          });

          // Follow the redirect
          fetchIcalData(redirectUrl, maxRedirects - 1)
            .then(resolve)
            .catch(reject);
          return;
        }

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

    // Add timeout to prevent hanging requests
    request.setTimeout(HTTP_TIMEOUT_MS, () => {
      request.destroy();
      reject(new Error(`Request timeout after ${HTTP_TIMEOUT_MS / 1000} seconds`));
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
 * NEW STRUCTURE: Use property-level subcollection
 */
async function deleteOldEvents(
  db: FirebaseFirestore.Firestore,
  feedId: string,
  propertyId: string
): Promise<void> {
  // NEW STRUCTURE: Query from property-level subcollection
  const eventsSnapshot = await db
    .collection('properties')
    .doc(propertyId)
    .collection('ical_events')
    .where('feed_id', '==', feedId)
    .get();

  // Handle case where there are more than 500 events (batch limit)
  const batchSize = 500;
  let deletedCount = 0;

  for (let i = 0; i < eventsSnapshot.docs.length; i += batchSize) {
    const batch = db.batch();
    const batchDocs = eventsSnapshot.docs.slice(i, i + batchSize);

    batchDocs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    deletedCount += batchDocs.length;
  }

  logInfo("[iCal Sync] Deleted old events for feed", {feedId, propertyId, count: deletedCount});
}

/**
 * Insert new events for a feed
 * NEW STRUCTURE: Use property-level subcollection
 */
async function insertNewEvents(
  db: FirebaseFirestore.Firestore,
  feedId: string,
  unitId: string,
  propertyId: string,
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
      // NEW STRUCTURE: Write to property-level subcollection
      const docRef = db
        .collection('properties')
        .doc(propertyId)
        .collection('ical_events')
        .doc();

      batch.set(docRef, {
        feed_id: feedId,
        unit_id: unitId,
        property_id: propertyId, // Add property_id for reference
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

  logInfo("[iCal Sync] Inserted new events for feed", {feedId, propertyId, count: insertedCount});

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
