import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as https from "https";
import * as http from "http";
import * as dns from "dns/promises";
import {LookupAddress} from "dns";
import * as net from "net";
import {admin} from "./firebase";
import {logInfo, logError, logWarn, logSuccess} from "./logger";
import {setUser, captureMessage} from "./sentry";
import {analyzeEvent, ExistingBooking} from "./utils/echoDetection";

/**
 * F-NEW-05: SSRF defence for owner-supplied iCal URLs.
 *
 * Pre-fix the validator was a substring blocklist on `hostname` that bypassed
 * trivially via IP encodings (decimal `2130706433`, hex `0x7f000001`, octal
 * `0177.0.0.1`, IPv4-mapped IPv6 `[::ffff:169.254.169.254]`) plus
 * DNS rebinding (validation host resolves to public IP, fetch host
 * re-resolves to metadata IP).
 *
 * New approach:
 *   1. Reject non-http(s) protocol.
 *   2. Resolve hostname via `dns.lookup(all: true)`.
 *   3. Reject if ANY resolved address is private/loopback/link-local/
 *      multicast/IPv4-mapped-into-private-IPv6.
 *   4. Return the pinned address.
 *   5. `fetchIcalData` passes a custom `lookup` to http(s).get that returns
 *      ONLY the pinned address, defeating DNS rebinding between validate
 *      and fetch.
 */

/** RFC1918 + loopback + link-local + multicast + IPv4-mapped-IPv6 + IPv6 ULA. */
function isPrivateOrUnsafeIp(ip: string): boolean {
  if (!ip) return true;

  // IPv4-mapped IPv6: ::ffff:a.b.c.d → strip prefix, check as IPv4.
  const v4Mapped = ip.match(/^::ffff:(\d+\.\d+\.\d+\.\d+)$/i);
  if (v4Mapped) return isPrivateOrUnsafeIp(v4Mapped[1]);

  if (net.isIPv4(ip)) {
    const parts = ip.split(".").map((p) => Number(p));
    if (parts.length !== 4 || parts.some((p) => Number.isNaN(p))) return true;
    const [a, b] = parts;
    if (a === 10) return true; // 10.0.0.0/8
    if (a === 127) return true; // loopback
    if (a === 0) return true; // 0.0.0.0/8 (this-network)
    if (a === 169 && b === 254) return true; // link-local + GCP/AWS metadata
    if (a === 172 && b >= 16 && b <= 31) return true; // 172.16.0.0/12
    if (a === 192 && b === 168) return true; // 192.168.0.0/16
    if (a === 100 && b >= 64 && b <= 127) return true; // CGNAT 100.64.0.0/10
    if (a >= 224) return true; // multicast (224.0.0.0/4) + reserved (240.0.0.0/4)
    return false;
  }

  if (net.isIPv6(ip)) {
    const lower = ip.toLowerCase();
    if (lower === "::1") return true; // loopback
    if (lower === "::") return true; // unspecified
    if (lower.startsWith("fe80:")) return true; // link-local
    if (lower.startsWith("fc") || lower.startsWith("fd")) return true; // ULA fc00::/7
    if (lower.startsWith("ff")) return true; // multicast
    return false;
  }

  // Not a valid IP literal (URL.hostname can still return a name here for
  // exotic encodings); refuse — DNS resolution downstream will handle the
  // real address check.
  return false;
}

/**
 * F-NEW-05 result: validated + resolved address pin.
 */
export interface IcalUrlValidation {
  valid: boolean;
  error?: string;
  /** Resolved address to pin in the actual fetch (defeats DNS rebinding). */
  pinnedAddress?: string;
  /** Address family for net.connect lookup callback. */
  pinnedFamily?: 4 | 6;
}

/**
 * Detect transient third-party fetch failures we should NOT alert on.
 * iCal feeds fail intermittently (provider 503s, network blips, DNS hiccups);
 * the next 15-min cron tick retries automatically. Persistent failures show
 * up in the feed doc's `status: "error"` + `last_error` fields and via the
 * `errorCount` summary in the scheduled-sync logSuccess line — operators
 * monitor those, not per-tick Sentry alerts.
 */
const TRANSIENT_NET_CODES = new Set([
  "ECONNRESET",
  "ETIMEDOUT",
  "ENOTFOUND",
  "ENETUNREACH",
  "EAI_AGAIN",
  "ECONNREFUSED",
  "EHOSTUNREACH",
]);

function isTransientFetchError(error: unknown): boolean {
  if (!error) return false;
  const code = (error as {code?: unknown}).code;
  if (typeof code === "string" && TRANSIENT_NET_CODES.has(code)) return true;
  const message = error instanceof Error ? error.message : String(error);
  // HTTP 5xx from upstream (formatted by fetchIcalData)
  if (/^HTTP 5\d\d:/.test(message)) return true;
  // Generic socket timeouts that don't carry a .code
  if (/^Request timeout/i.test(message)) return true;
  return false;
}

/**
 * F-NEW-05: SECURITY — validate + resolve iCal URL to prevent SSRF.
 *
 * Async because we DNS-resolve the hostname and check ALL returned addresses
 * against the private-IP set. The resolved address is returned for the
 * caller to pin in the actual fetch via a custom `lookup` callback —
 * without pinning, DNS rebinding lets an attacker re-resolve the host to
 * 169.254.169.254 (metadata server) between validation and fetch.
 *
 * SF-002 REVISED: domain whitelist removed (too restrictive for real owners
 * importing from PMS / agencies). Security is now DNS-based, not string-based.
 */
async function validateIcalUrl(url: string): Promise<IcalUrlValidation> {
  let parsedUrl: URL;
  try {
    parsedUrl = new URL(url);
  } catch {
    return {valid: false, error: "Invalid URL format."};
  }

  // Only http(s) — blocks file:, gopher:, ftp:, data:, etc.
  if (!["http:", "https:"].includes(parsedUrl.protocol)) {
    return {
      valid: false,
      error: `Invalid protocol: ${parsedUrl.protocol}. Only HTTP/HTTPS allowed.`,
    };
  }

  // Reject empty / numeric-only hostnames that could bypass IP encoding
  // attacks. URL.hostname normalises decimal/hex/octal IP encodings to
  // dotted form via WHATWG URL parser in many cases, but defensive: any
  // hostname that resolves directly to an IP literal still goes through
  // the post-DNS check below.
  const hostname = parsedUrl.hostname.toLowerCase();
  if (!hostname) {
    return {valid: false, error: "URL must have a hostname."};
  }

  // Resolve hostname → list of addresses. Reject if ANY is private/unsafe.
  let addresses: LookupAddress[];
  try {
    addresses = await dns.lookup(hostname, {all: true, verbatim: true});
  } catch (err) {
    return {
      valid: false,
      error: `Hostname does not resolve: ${(err as Error).message || "unknown"}`,
    };
  }

  if (addresses.length === 0) {
    return {valid: false, error: "Hostname returned no addresses."};
  }

  for (const addr of addresses) {
    if (isPrivateOrUnsafeIp(addr.address)) {
      logWarn("[iCal Sync] SSRF guard blocked private IP", {
        hostname,
        address: addr.address,
      });
      return {
        valid: false,
        error: "Hostname resolves to a private or reserved IP address.",
      };
    }
  }

  // Pin the FIRST resolved address (typically IPv4 first when verbatim:false,
  // OS order when verbatim:true). Caller MUST pass this address as the
  // pinned lookup to defeat DNS rebinding between this check and the fetch.
  const pinned = addresses[0];

  // Telemetry-only domain log (SF-002).
  const knownDomains = [
    "booking.com", "airbnb.com", "calendar.google.com",
    "outlook.live.com", "outlook.office365.com", "yahoo.com",
  ];
  const isKnown = knownDomains.some((domain) =>
    hostname === domain || hostname.endsWith(`.${domain}`)
  );
  if (!isKnown) {
    logInfo("[iCal Sync] New iCal domain used (allowed)", {hostname});
  }

  return {
    valid: true,
    pinnedAddress: pinned.address,
    pinnedFamily: pinned.family === 4 ? 4 : 6,
  };
}

/**
 * Scheduled function to automatically sync all active iCal feeds
 * Runs every 15 minutes to keep external calendar data up to date
 *
 * This syncs reservations from:
 * - Booking.com (via iCal URL)
 * - Airbnb (via iCal URL)
 * - Adriagate, Smoobu, and other platforms that provide iCal feeds
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
      // Get all active feeds using collectionGroup
      // Path: properties/{propertyId}/ical_feeds/{feedId}
      const feedsSnapshot = await db
        .collectionGroup("ical_feeds")
        .where("status", "in", ["active", "error"]) // Include error feeds to retry
        .get();

      if (feedsSnapshot.empty) {
        logInfo("[Scheduled iCal Sync] No active feeds to sync");
        return;
      }

      logInfo("[Scheduled iCal Sync] Found feeds to sync", {
        count: feedsSnapshot.size,
      });

      let successCount = 0;
      let errorCount = 0;
      let totalEventsImported = 0;

      // Process feeds sequentially to avoid overwhelming external APIs
      for (const feedDoc of feedsSnapshot.docs) {
        const feedId = feedDoc.id;
        const feedData = feedDoc.data();

        // Extract propertyId from document path
        // Path: properties/{propertyId}/ical_feeds/{feedId}
        const pathSegments = feedDoc.ref.path.split("/");
        const propertyId = pathSegments[1]; // properties/[propertyId]/ical_feeds/feedId

        if (!propertyId) {
          logError("[Scheduled iCal Sync] Could not extract propertyId from path", null, {
            feedId,
            path: feedDoc.ref.path,
          });
          errorCount++;
          continue;
        }

        // Skip if import is disabled (export-only mode)
        // Used for platforms that re-export imported data (e.g., Holiday-Home)
        if (feedData.import_enabled === false) {
          logInfo("[Scheduled iCal Sync] Skipping feed - import disabled (export-only mode)", {
            feedId,
            propertyId,
            platform: feedData.platform,
          });
          continue;
        }

        // Skip if sync interval hasn't elapsed (check last_synced)
        const lastSynced = feedData.last_synced?.toDate();
        const syncIntervalMinutes = feedData.sync_interval_minutes || 15;

        if (lastSynced) {
          const nextSyncTime = new Date(lastSynced.getTime() + syncIntervalMinutes * 60 * 1000);
          if (new Date() < nextSyncTime) {
            logInfo("[Scheduled iCal Sync] Skipping feed - sync interval not elapsed", {
              feedId,
              propertyId,
              lastSynced: lastSynced.toISOString(),
              nextSync: nextSyncTime.toISOString(),
            });
            continue;
          }
        }

        try {
          const eventsImported = await syncSingleFeed(db, feedId, propertyId, feedData);
          successCount++;
          totalEventsImported += eventsImported;

          logInfo("[Scheduled iCal Sync] Feed synced successfully", {
            feedId,
            propertyId,
            platform: feedData.platform,
            eventsImported,
          });
        } catch (error) {
          errorCount++;
          // syncSingleFeed already logged the failure (WARN for transient,
          // ERROR for actionable). Avoid double-capturing in Sentry by
          // logging the outer-loop context at the same severity tier.
          if (isTransientFetchError(error)) {
            logWarn("[Scheduled iCal Sync] Feed sync skipped (transient)", {
              feedId,
              propertyId,
              platform: feedData.platform,
            });
          } else {
            logError("[Scheduled iCal Sync] Failed to sync feed", error, {
              feedId,
              propertyId,
              platform: feedData.platform,
            });
          }
          // Continue with next feed even if one fails
        }

        // Small delay between feeds to be nice to external APIs
        await new Promise((resolve) => setTimeout(resolve, 1000));
      }

      logSuccess("[Scheduled iCal Sync] Automatic sync completed", {
        totalFeeds: feedsSnapshot.size,
        successCount,
        errorCount,
        totalEventsImported,
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
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // Set user context for Sentry error tracking
  setUser(request.auth.uid);

  const {feedId, propertyId} = request.data;

  if (!feedId || !propertyId) {
    throw new HttpsError("invalid-argument", "feedId and propertyId are required");
  }

  const db = admin.firestore();

  try {
    logInfo("[iCal Sync] Manual sync requested for feed", {feedId, propertyId});

    // Verify user owns this property
    const propertyDoc = await db.collection("properties").doc(propertyId).get();

    if (!propertyDoc.exists || propertyDoc.data()?.owner_id !== request.auth.uid) {
      throw new HttpsError("permission-denied", "You do not own this property");
    }

    // Get feed document from subcollection
    // Path: properties/{propertyId}/ical_feeds/{feedId}
    const feedDoc = await db
      .collection("properties")
      .doc(propertyId)
      .collection("ical_feeds")
      .doc(feedId)
      .get();

    if (!feedDoc.exists) {
      throw new HttpsError("not-found", "Feed not found");
    }

    const feedData = feedDoc.data()!;

    // Check if import is disabled (export-only mode)
    // Used for platforms that re-export imported data (e.g., Holiday-Home)
    if (feedData.import_enabled === false) {
      logInfo("[iCal Sync] Manual sync skipped - import disabled (export-only mode)", {
        feedId,
        propertyId,
        platform: feedData.platform,
      });
      return {
        success: true,
        message: "Import is disabled for this feed (export-only mode)",
        bookingsCreated: 0,
        skipped: true,
      };
    }

    // Sync the feed
    const bookingsCreated = await syncSingleFeed(db, feedId, propertyId, feedData);

    logSuccess("[iCal Sync] Manual sync completed for feed", {feedId, bookingsCreated});

    return {
      success: true,
      message: "Feed synced successfully",
      bookingsCreated: bookingsCreated,
    };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logError("[iCal Sync] Error in manual sync", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    throw new HttpsError("internal", "Sync failed: " + errorMessage);
  }
});

/**
 * Sync a single iCal feed
 * Returns number of bookings created
 * Path: properties/{propertyId}/ical_feeds/{feedId}
 */
async function syncSingleFeed(
  db: FirebaseFirestore.Firestore,
  feedId: string,
  propertyId: string,
  feedData: any
): Promise<number> {
  const {unit_id, ical_url, platform, custom_platform_name} = feedData;

  logInfo("[iCal Sync] Syncing feed", {feedId, propertyId, unitId: unit_id, platform, customPlatformName: custom_platform_name});

  // Helper to get feed reference
  const feedRef = db
    .collection("properties")
    .doc(propertyId)
    .collection("ical_feeds")
    .doc(feedId);

  try {
    // SECURITY: Validate URL before fetching (SSRF prevention).
    // F-NEW-05: now async — DNS-resolves hostname + checks each address
    // against private/loopback/IPv4-mapped-IPv6 ranges. Returns a pinned
    // address that we pass to fetchIcalData to defeat DNS rebinding.
    const urlValidation = await validateIcalUrl(ical_url);
    if (!urlValidation.valid) {
      throw new Error(`Invalid iCal URL: ${urlValidation.error}`);
    }

    // Fetch iCal data using the pinned address (DNS rebinding defence)
    const icalData = await fetchIcalData(
      ical_url,
      5,
      urlValidation.pinnedAddress,
      urlValidation.pinnedFamily,
    );

    // BUG-009 FIX: Validate fetched iCal data before processing
    // Prevents accidental deletion of all events if the fetched data is empty/malformed
    // Every valid iCal file MUST contain "BEGIN:VCALENDAR" per RFC 5545
    if (!icalData || !icalData.includes("BEGIN:VCALENDAR")) {
      // SECURITY (audit/31 HIGH-1): do NOT echo response body in error —
      // if an SSRF redirect ever lands on a credential-bearing endpoint
      // (metadata server, internal API), echoing chars 0-100 leaks secrets
      // into logs/Sentry. Report only size + a non-secret-bearing prefix
      // class.
      const sizeBytes = icalData ? icalData.length : 0;
      throw new Error(
        `Fetched iCal data is empty or invalid for feed: ${feedId} ` +
        `(received ${sizeBytes} bytes, missing BEGIN:VCALENDAR header)`
      );
    }

    // Parse iCal data
    const events = await parseIcalData(icalData);

    logInfo("[iCal Sync] Parsed events from platform", {platform, eventCount: events.length});

    // Fetch existing bookings/events for echo detection BEFORE deleting old events
    // We need to compare against native bookings + events from OTHER feeds
    const existingBookings = await fetchExistingBookingsForUnit(db, propertyId, unit_id, feedId);

    // Delete old events for this feed
    await deleteOldEvents(db, feedId, propertyId);

    // Insert new events with echo detection
    const source = (platform === "other" && custom_platform_name)
      ? sanitizeSource(custom_platform_name)
      : platform;

    const result = await insertNewEventsWithEchoDetection(
      db, feedId, unit_id, propertyId, source, events, existingBookings
    );

    // Update feed metadata in subcollection
    await feedRef.update({
      last_synced: admin.firestore.Timestamp.now(),
      sync_count: admin.firestore.FieldValue.increment(1),
      event_count: result.insertedCount,
      status: "active",
      last_error: null,
      updated_at: admin.firestore.Timestamp.now(),
    });

    logSuccess("[iCal Sync] Successfully synced feed", {
      feedId,
      eventCount: result.insertedCount,
      skippedEchoes: result.skippedEchoes,
      flaggedForReview: result.flaggedForReview,
      trimmedCount: result.trimmedCount,
    });

    return result.insertedCount; // Return number of bookings created
  } catch (error) {
    // Transient upstream failures (5xx, network, DNS) are not actionable for
    // us — log as WARN, skip Sentry. The feed doc's `status: "error"` carries
    // the persistent signal for the UI.
    if (isTransientFetchError(error)) {
      logWarn("[iCal Sync] Transient upstream failure", {
        feedId,
        message: error instanceof Error ? error.message : String(error),
      });
    } else {
      logError("[iCal Sync] Error syncing feed", error, {feedId});
    }

    const errorMessage = error instanceof Error ? error.message : "Unknown error";

    // Update feed with error status in subcollection
    await feedRef.update({
      status: "error",
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

function fetchIcalData(
  url: string,
  maxRedirects: number = 5,
  pinnedAddress?: string,
  pinnedFamily?: 4 | 6,
): Promise<string> {
  return new Promise((resolve, reject) => {
    if (maxRedirects <= 0) {
      reject(new Error("Too many redirects"));
      return;
    }

    const protocol = url.startsWith("https") ? https : http;

    // F-NEW-05: pinned lookup defeats DNS rebinding between validateIcalUrl
    // and the actual fetch. If a pin is provided, ALL DNS resolutions inside
    // this request use it — the OS resolver is bypassed.
    const requestOptions: https.RequestOptions = pinnedAddress
      ? {
          lookup: (
            _hostname: string,
            _options: unknown,
            callback: (err: Error | null, address: string, family: number) => void,
          ) => {
            callback(null, pinnedAddress, pinnedFamily || 4);
          },
        }
      : {};

    const request = protocol
      .get(url, requestOptions, (response) => {
        // Handle redirects (301, 302, 303, 307, 308)
        if (response.statusCode && [301, 302, 303, 307, 308].includes(response.statusCode)) {
          let redirectUrl = response.headers.location;
          if (!redirectUrl) {
            reject(new Error(`Redirect ${response.statusCode} without Location header`));
            return;
          }

          // Handle relative URLs by constructing absolute URL
          if (redirectUrl.startsWith("/")) {
            const urlObj = new URL(url);
            redirectUrl = `${urlObj.protocol}//${urlObj.host}${redirectUrl}`;
          }

          // SECURITY (audit/31 HIGH-1 + F-NEW-05): re-validate redirect target
          // to prevent SSRF via attacker-controlled 302. validateIcalUrl is
          // now async (DNS lookup + private-IP rejection) and returns a fresh
          // pin for the redirect destination — we use it to fetch the next
          // hop, defeating DNS rebinding on the redirect chain too.
          validateIcalUrl(redirectUrl)
            .then((redirectValidation) => {
              if (!redirectValidation.valid) {
                reject(new Error(
                  `Redirect blocked by SSRF guard: ${redirectValidation.error}`
                ));
                return;
              }
              logInfo("[iCal Sync] Following redirect", {
                from: url.substring(0, 50) + "...",
                to: (redirectUrl as string).substring(0, 50) + "...",
                statusCode: response.statusCode,
              });
              fetchIcalData(
                redirectUrl as string,
                maxRedirects - 1,
                redirectValidation.pinnedAddress,
                redirectValidation.pinnedFamily,
              )
                .then(resolve)
                .catch(reject);
            })
            .catch(reject);
          return;
        }

        if (response.statusCode !== 200) {
          // Include truncated URL for debugging (hide full URL for security)
          const urlHost = new URL(url).host;
          reject(new Error(`HTTP ${response.statusCode}: ${response.statusMessage} (host: ${urlHost})`));
          return;
        }

        let data = "";

        response.on("data", (chunk) => {
          data += chunk;
        });

        response.on("end", () => {
          resolve(data);
        });
      })
      .on("error", (error) => {
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
      const ical = require("node-ical");
      const parsed = ical.parseICS(icalData);
      const events: any[] = [];

      for (const [uid, event] of Object.entries(parsed)) {
        if ((event as any).type === "VEVENT") {
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

          // Extract original creation date from iCal event
          // Priority: CREATED > DTSTAMP > startDate (fallback)
          let originalCreatedAt: Date | null = null;
          if (vevent.created) {
            originalCreatedAt = new Date(vevent.created);
          } else if (vevent.dtstamp) {
            originalCreatedAt = new Date(vevent.dtstamp);
          }

          events.push({
            externalId: uid,
            startDate: startDate,
            endDate: endDate,
            summary: vevent.summary || "Rezervacija",
            description: vevent.description || null,
            // Use original booking date, fallback to check-in date
            createdAt: originalCreatedAt || startDate,
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
    .collection("properties")
    .doc(propertyId)
    .collection("ical_events")
    .where("feed_id", "==", feedId)
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
 * Fetch existing bookings and ical_events for a unit (for echo detection)
 * Returns all bookings + events from OTHER feeds (not the one being synced)
 */
async function fetchExistingBookingsForUnit(
  db: FirebaseFirestore.Firestore,
  propertyId: string,
  unitId: string,
  currentFeedId: string
): Promise<ExistingBooking[]> {
  const existingBookings: ExistingBooking[] = [];

  // Date range: only check recent/future bookings
  const pastDate = new Date();
  pastDate.setDate(pastDate.getDate() - 90);
  const futureDate = new Date();
  futureDate.setDate(futureDate.getDate() + 365);

  const maxAttempts = 3;
  const baseDelayMs = 1000;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      // 1. Fetch native bookings for this unit
      const bookingsSnapshot = await db
        .collectionGroup("bookings")
        .where("unit_id", "==", unitId)
        .where("status", "in", ["confirmed", "pending", "completed"])
        .where("check_in", ">=", admin.firestore.Timestamp.fromDate(pastDate))
        .where("check_in", "<=", admin.firestore.Timestamp.fromDate(futureDate))
        .limit(500)
        .get();

      for (const doc of bookingsSnapshot.docs) {
        const data = doc.data();
        const checkIn = data.check_in?.toDate();
        const checkOut = data.check_out?.toDate();
        if (checkIn && checkOut) {
          existingBookings.push({
            id: doc.id,
            type: "booking",
            checkIn,
            checkOut,
            source: data.source || "direct",
            importedAt: data.created_at?.toDate() || checkIn,
          });
        }
      }

      // 2. Fetch ical_events from OTHER feeds (not the current feed being synced)
      const icalEventsSnapshot = await db
        .collection("properties")
        .doc(propertyId)
        .collection("ical_events")
        .where("unit_id", "==", unitId)
        .where("start_date", ">=", admin.firestore.Timestamp.fromDate(pastDate))
        .where("start_date", "<=", admin.firestore.Timestamp.fromDate(futureDate))
        .limit(500)
        .get();

      for (const doc of icalEventsSnapshot.docs) {
        const data = doc.data();
        // Skip events from the current feed (they'll be deleted and re-imported)
        if (data.feed_id === currentFeedId) continue;

        const startDate = data.start_date?.toDate();
        const endDate = data.end_date?.toDate();
        if (startDate && endDate) {
          existingBookings.push({
            id: doc.id,
            type: "ical_event",
            checkIn: startDate,
            checkOut: endDate,
            source: data.source || "other",
            importedAt: data.created_at?.toDate() || startDate,
          });
        }
      }

      logInfo("[iCal Sync] Fetched existing bookings for echo detection", {
        propertyId,
        unitId,
        nativeBookings: bookingsSnapshot.size,
        otherIcalEvents: existingBookings.length - bookingsSnapshot.size,
        total: existingBookings.length,
        ...(attempt > 1 ? {retriedAttempts: attempt} : {}),
      });

      return existingBookings;
    } catch (error) {
      const isLastAttempt = attempt === maxAttempts;
      const errorStr = String(error).toLowerCase();
      const isTransient = errorStr.includes("unavailable") ||
        errorStr.includes("deadline") ||
        errorStr.includes("internal") ||
        errorStr.includes("failed_precondition") ||
        errorStr.includes("resource_exhausted");

      if (!isTransient || isLastAttempt) {
        logWarn("[iCal Sync] Error fetching existing bookings for echo detection (fallback: skip echo detection)", {
          propertyId,
          unitId,
          error: String(error),
          attempts: attempt,
        });
        // Return empty array — echo detection will fall back to saving all events
        return existingBookings;
      }

      // Exponential backoff before retry
      const delayMs = baseDelayMs * (attempt - 1);
      if (delayMs > 0) {
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    }
  }

  return existingBookings;
}

/**
 * Insert new events with echo detection
 * For each event: run echo detection, then skip/flag/save accordingly
 */
async function insertNewEventsWithEchoDetection(
  db: FirebaseFirestore.Firestore,
  feedId: string,
  unitId: string,
  propertyId: string,
  source: string,
  events: any[],
  existingBookings: ExistingBooking[]
): Promise<{insertedCount: number; skippedEchoes: number; flaggedForReview: number; trimmedCount: number}> {
  if (events.length === 0) {
    return {insertedCount: 0, skippedEchoes: 0, flaggedForReview: 0, trimmedCount: 0};
  }

  let insertedCount = 0;
  let skippedEchoes = 0;
  let flaggedForReview = 0;
  let trimmedCount = 0;

  // Firestore batch can handle max 500 operations
  const batchSize = 500;
  const eventsToInsert: any[] = [];

  for (const event of events) {
    // Run echo detection
    const echoResult = analyzeEvent(
      {
        checkIn: event.startDate,
        checkOut: event.endDate,
        source: source,
        importedAt: new Date(),
      },
      existingBookings
    );

    if (echoResult.recommendedAction === "auto_skip") {
      // High confidence echo — skip entirely
      logInfo("[iCal Sync] Auto-skipped probable echo", {
        feedId,
        confidence: echoResult.confidence.toFixed(2),
        reasons: echoResult.reasons.join("; "),
        matchedId: echoResult.matchedEventId || echoResult.matchedBookingId,
        eventDates: `${event.startDate.toISOString()} - ${event.endDate.toISOString()}`,
      });
      skippedEchoes++;
      continue;
    }

    if (echoResult.recommendedAction === "save_trimmed" && echoResult.trimmedRanges) {
      // Partial echo — save only the new date ranges
      logInfo("[iCal Sync] Trimming partial echo to new ranges", {
        feedId,
        originalDates: `${event.startDate.toISOString()} - ${event.endDate.toISOString()}`,
        trimmedCount: echoResult.trimmedRanges.length,
        ranges: echoResult.trimmedRanges.map((r: {startDate: Date; endDate: Date}) =>
          `${r.startDate.toISOString().slice(0, 10)} to ${r.endDate.toISOString().slice(0, 10)}`
        ).join("; "),
        containmentRatio: (echoResult.containmentRatio ?? 0).toFixed(2),
        matchConfidence: echoResult.confidence.toFixed(2),
        newNights: echoResult.trimmedRanges.reduce((sum: number, r: {startDate: Date; endDate: Date}) => {
          const days = Math.round((r.endDate.getTime() - r.startDate.getTime()) / (24 * 60 * 60 * 1000));
          return sum + days;
        }, 0),
        echoReasons: echoResult.reasons.join("; "),
      });
      // Create one ical_event per trimmed range
      for (let j = 0; j < echoResult.trimmedRanges.length; j++) {
        const range = echoResult.trimmedRanges[j];
        eventsToInsert.push({
          ...event,
          startDate: range.startDate,
          endDate: range.endDate,
          externalId: event.externalId,
          eventStatus: "active",
          echoConfidence: echoResult.containmentRatio ?? echoResult.confidence,
          echoReason: echoResult.reasons.join("; "),
          parentEventId: echoResult.matchedEventId || null,
          parentBookingId: echoResult.matchedBookingId || null,
        });
      }
      trimmedCount += echoResult.trimmedRanges.length;
      continue;
    }

    // Determine event status based on echo detection
    const eventStatus = echoResult.recommendedAction === "flag_review"
      ? "needs_review"
      : "active";

    if (echoResult.recommendedAction === "flag_review") {
      flaggedForReview++;
      logInfo("[iCal Sync] Flagged event for review", {
        feedId,
        confidence: echoResult.confidence.toFixed(2),
        reasons: echoResult.reasons.join("; "),
        matchedId: echoResult.matchedEventId || echoResult.matchedBookingId,
        eventDates: `${event.startDate.toISOString()} - ${event.endDate.toISOString()}`,
      });
      captureMessage("[iCal Sync] Event flagged for review — possible overbooking", "warning", {
        feedId,
        unitId,
        eventDates: `${event.startDate.toISOString()} - ${event.endDate.toISOString()}`,
        containmentRatio: echoResult.containmentRatio != null ? echoResult.containmentRatio.toFixed(2) : "N/A",
        confidence: echoResult.confidence.toFixed(2),
        reasons: echoResult.reasons.join("; "),
      });
    }

    eventsToInsert.push({
      ...event,
      eventStatus,
      echoConfidence: echoResult.confidence,
      echoReason: echoResult.reasons.join("; "),
      parentEventId: echoResult.matchedEventId || null,
      parentBookingId: echoResult.matchedBookingId || null,
    });
  }

  // Batch insert events that passed echo detection
  for (let i = 0; i < eventsToInsert.length; i += batchSize) {
    const batch = db.batch();
    const batchEvents = eventsToInsert.slice(i, i + batchSize);

    batchEvents.forEach((event) => {
      const docRef = db
        .collection("properties")
        .doc(propertyId)
        .collection("ical_events")
        .doc();

      batch.set(docRef, {
        feed_id: feedId,
        unit_id: unitId,
        property_id: propertyId,
        source: source,
        external_id: event.externalId,
        start_date: admin.firestore.Timestamp.fromDate(event.startDate),
        end_date: admin.firestore.Timestamp.fromDate(event.endDate),
        guest_name: event.summary || `${capitalizeFirstLetter(source)} Gost`,
        description: event.description,
        // Echo detection fields
        status: event.eventStatus,
        echo_confidence: event.echoConfidence > 0 ? event.echoConfidence : null,
        echo_reason: event.echoReason || null,
        parent_event_id: event.parentEventId,
        parent_booking_id: event.parentBookingId,
        // Use original booking date from iCal (CREATED/DTSTAMP), not import time
        created_at: admin.firestore.Timestamp.fromDate(event.createdAt),
        updated_at: admin.firestore.Timestamp.now(),
      });
    });

    await batch.commit();
    insertedCount += batchEvents.length;
  }

  logInfo("[iCal Sync] Inserted events with echo detection", {
    feedId,
    propertyId,
    source,
    inserted: insertedCount,
    skippedEchoes,
    flaggedForReview,
    trimmedCount,
  });

  return {insertedCount, skippedEchoes, flaggedForReview, trimmedCount};
}

// Legacy insertNewEvents removed — replaced by insertNewEventsWithEchoDetection above

/**
 * Sanitize custom platform name for use as source identifier
 * "Adriagate" -> "adriagate"
 * "Smoobu PMS" -> "smoobu-pms"
 * "My Calendar 123" -> "my-calendar-123"
 */
function sanitizeSource(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "") || "other";
}

/**
 * Helper function to capitalize first letter
 */
function capitalizeFirstLetter(str: string): string {
  if (!str) return str;

  // Handle special cases
  if (str === "booking_com") return "Booking.com";
  if (str === "airbnb") return "Airbnb";

  return str.charAt(0).toUpperCase() + str.slice(1);
}
