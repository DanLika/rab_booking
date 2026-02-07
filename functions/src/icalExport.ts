import { onRequest } from "firebase-functions/v2/https";
import * as crypto from "crypto";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "./firebase";
import { logInfo, logError } from "./logger";
import { getClientIp, hashIp } from "./utils/ipUtils";
import { checkRateLimit } from "./utils/rateLimit";

// =============================================================================
// CONFIGURATION
// =============================================================================
const ICAL_CONFIG = {
  // DoS Protection: Maximum bookings to include in feed
  MAX_BOOKINGS: 500,
  // DoS Protection: Maximum imported events to include in feed
  MAX_ICAL_EVENTS: 500,
  // DoS Protection: Maximum blocked days to include in feed
  MAX_BLOCKED_DAYS: 1000,
  // Date range: How far back to include past bookings (days)
  PAST_DAYS: 90,
  // Date range: How far ahead to include future bookings (days)
  FUTURE_DAYS: 365,
  // Cache TTL in seconds (5 minutes)
  CACHE_TTL_SECONDS: 300,
};

/**
 * Verify iCal export token using timing-safe comparison
 * SECURITY: Prevents timing attacks when comparing tokens
 */
function verifyIcalToken(providedToken: string, storedToken: string): boolean {
  // Ensure both are strings and have reasonable length
  if (typeof providedToken !== "string" || typeof storedToken !== "string") {
    return false;
  }

  // Use Buffer comparison for timing-safe check
  // Pad to same length to prevent length-based timing attacks
  const maxLength = Math.max(providedToken.length, storedToken.length);
  const paddedProvided = providedToken.padEnd(maxLength, "\0");
  const paddedStored = storedToken.padEnd(maxLength, "\0");

  try {
    return crypto.timingSafeEqual(
      Buffer.from(paddedProvided, "utf8"),
      Buffer.from(paddedStored, "utf8")
    );
  } catch {
    return false;
  }
}

/**
 * Generate content hash for ETag
 * Uses SHA-256 truncated to 16 chars for compact ETag
 */
function generateContentHash(content: string): string {
  return crypto
    .createHash("sha256")
    .update(content, "utf8")
    .digest("hex")
    .substring(0, 16);
}

/**
 * Set HTTP cache headers for iCal response
 */
function setCacheHeaders(
  response: { set: (name: string, value: string) => void },
  etag: string,
  maxAge: number
): void {
  response.set("ETag", etag);
  response.set("Cache-Control", `public, max-age=${maxAge}`);
  response.set("Vary", "Accept-Encoding");
}

/**
 * Public iCal Feed Endpoint
 *
 * GET /api/ical/{propertyId}/{unitId}/{token}
 *
 * Returns iCal feed for a specific unit with all bookings.
 * Secured by secret token stored in widget_settings.
 *
 * Compatible with:
 * - Google Calendar
 * - Apple Calendar
 * - Outlook
 * - Any RFC 5545 compatible calendar app
 */
export const getUnitIcalFeed = onRequest(async (request, response) => {
  // Set CORS headers
  response.set("Access-Control-Allow-Origin", "*");
  response.set("Access-Control-Allow-Methods", "GET");

  // SECURITY: IP-based rate limiting to prevent DoS (60 requests per hour per IP)
  const clientIp = getClientIp(request);
  const ipHash = hashIp(clientIp);
  if (!checkRateLimit(`ical_feed_${ipHash}`, 60, 3600)) {
    logError("[iCal Feed] Rate limit exceeded", {ipHash});
    response.status(429).send("Too many requests. Please try again later.");
    return;
  }

  if (request.method === "OPTIONS") {
    response.status(204).send("");
    return;
  }

  if (request.method !== "GET") {
    response.status(405).send("Method Not Allowed");
    return;
  }

  try {
    // Extract parameters from URL path
    // Expected format: /getUnitIcalFeed/{propertyId}/{unitId}/{token}
    const pathParts = request.path.split("/").filter((p) => p);

    if (pathParts.length < 3) {
      response.status(400).send("Invalid URL format. Expected: /{propertyId}/{unitId}/{token}");
      return;
    }

    const propertyId = pathParts[0];
    const unitId = pathParts[1];
    // Strip .ics extension if present (some calendar apps require URL to end in .ics)
    const token = pathParts[2].replace(/\.ics$/i, "");

    // Parse exclude parameter for circular sync prevention
    // Usage: ?exclude=booking_com (excludes Booking.com imported events from export)
    // This prevents re-importing same events back to the origin platform
    const excludeSource = (request.query.exclude as string)?.toLowerCase() || null;

    logInfo("[iCal Feed] Request received", { propertyId, unitId, excludeSource });

    // 1. Verify token against widget_settings
    const widgetSettingsDoc = await db
      .collection("properties")
      .doc(propertyId)
      .collection("widget_settings")
      .doc(unitId)
      .get();

    if (!widgetSettingsDoc.exists) {
      logError("[iCal Feed] Widget settings not found", { propertyId, unitId });
      response.status(404).send("Unit not found");
      return;
    }

    const widgetSettings = widgetSettingsDoc.data();

    // Check if iCal export is enabled
    if (!widgetSettings?.ical_export_enabled) {
      logError("[iCal Feed] iCal export disabled", { propertyId, unitId });
      response.status(403).send("iCal export is disabled for this unit");
      return;
    }

    // Verify token using timing-safe comparison (prevents timing attacks)
    if (!verifyIcalToken(token, widgetSettings.ical_export_token || "")) {
      logError("[iCal Feed] Invalid token", { propertyId, unitId });
      response.status(403).send("Invalid token");
      return;
    }

    // 2. Check cache - return cached content if still valid
    const cachedContent = widgetSettings.ical_cache_content;
    const cachedAt = widgetSettings.ical_cache_generated_at?.toDate();
    const cachedETag = widgetSettings.ical_cache_etag;

    const now = new Date();
    const cacheExpiry = cachedAt ?
      new Date(cachedAt.getTime() + ICAL_CONFIG.CACHE_TTL_SECONDS * 1000) :
      null;
    const cacheValid = cacheExpiry && now < cacheExpiry && cachedContent;

    // 3. Handle ETag/If-None-Match for bandwidth optimization
    const clientETag = request.headers["if-none-match"];
    if (cacheValid && clientETag && clientETag === cachedETag) {
      logInfo("[iCal Feed] 304 Not Modified (ETag match)", { propertyId, unitId });
      response.status(304).send("");
      return;
    }

    // 4. Return cached content if still valid
    // IMPORTANT: Skip cache when excludeSource is specified - each platform needs different filtered content
    if (cacheValid && cachedContent && !excludeSource) {
      logInfo("[iCal Feed] Serving cached content", { propertyId, unitId });
      setCacheHeaders(response, cachedETag, ICAL_CONFIG.CACHE_TTL_SECONDS);
      response.set("Content-Type", "text/calendar; charset=utf-8");
      const unitName = widgetSettings.ical_cache_unit_name || "Unit";
      response.set("Content-Disposition", `attachment; filename="${sanitizeFilename(unitName)}.ics"`);
      response.status(200).send(cachedContent);
      return;
    }

    // 5. Fetch unit data
    const unitDoc = await db
      .collection("properties")
      .doc(propertyId)
      .collection("units")
      .doc(unitId)
      .get();

    if (!unitDoc.exists) {
      response.status(404).send("Unit not found");
      return;
    }

    const unitData = unitDoc.data();
    const unitName = unitData?.name || "Unit";
    const minStayNights = unitData?.min_stay_nights || 1;

    // 6. Calculate date range for DoS protection
    const pastDate = new Date();
    pastDate.setDate(pastDate.getDate() - ICAL_CONFIG.PAST_DAYS);
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + ICAL_CONFIG.FUTURE_DAYS);

    // 7a. Fetch bookings using collection group query
    const bookingsSnapshot = await db
      .collectionGroup("bookings")
      .where("unit_id", "==", unitId)
      .where("status", "in", ["confirmed", "pending", "completed"])
      .where("check_in", ">=", Timestamp.fromDate(pastDate))
      .where("check_in", "<=", Timestamp.fromDate(futureDate))
      .orderBy("check_in", "asc")
      .limit(ICAL_CONFIG.MAX_BOOKINGS)
      .get();

    // 7b. Fetch blocked days (available = false) from daily_prices
    // CRITICAL: Without this, Booking.com/Airbnb will show blocked days as available!
    const blockedDaysSnapshot = await db
      .collectionGroup("daily_prices")
      .where("unit_id", "==", unitId)
      .where("available", "==", false)
      .where("date", ">=", Timestamp.fromDate(pastDate))
      .where("date", "<=", Timestamp.fromDate(futureDate))
      .orderBy("date", "asc")
      .limit(ICAL_CONFIG.MAX_BLOCKED_DAYS)
      .get();

    // 7c. Group consecutive blocked days into ranges for efficiency
    // truncateTime normalizes Firestore timezone (UTC+1/+2) to correct UTC calendar date
    const blockedRanges = groupConsecutiveBlockedDays(
      blockedDaysSnapshot.docs.map((doc) => truncateTime(doc.data().date?.toDate() || new Date()))
    );

    // 7d. Fetch imported ical_events for cross-platform sync (hub-and-spoke)
    // Industry standard: All major channel managers (Smoobu, Lodgify, Guesty, Hostaway)
    // use hub-and-spoke with per-channel filtered re-export.
    //
    // These events from other platforms MUST be exported so ALL platforms see ALL unavailability.
    // The excludeSource filter prevents circular sync:
    // - Export to Booking.com: exclude events where source = 'booking_com'
    // - Export to Airbnb: exclude events where source = 'airbnb'
    // - Export to Adriagate: exclude events where source = 'adriagate'
    //
    // Example: Adriagate booking → BookBed imports → BookBed exports to Booking.com
    //          (but NOT back to Adriagate, thanks to ?exclude=adriagate)
    const icalEventsSnapshot = await db
      .collection("properties")
      .doc(propertyId)
      .collection("ical_events")
      .where("unit_id", "==", unitId)
      .where("start_date", ">=", Timestamp.fromDate(pastDate))
      .where("start_date", "<=", Timestamp.fromDate(futureDate))
      .orderBy("start_date", "asc")
      .limit(ICAL_CONFIG.MAX_ICAL_EVENTS)
      .get();

    // Filter by excludeSource to prevent circular sync
    const icalEvents = icalEventsSnapshot.docs
      .filter((doc) => {
        if (!excludeSource) return true;
        const source = (doc.data().source || "").toLowerCase();
        return source !== excludeSource;
      })
      .map((doc) => ({...doc.data(), id: doc.id, isExternal: true}));

    logInfo("[iCal Feed] Fetched data", {
      propertyId,
      unitId,
      bookingCount: bookingsSnapshot.size,
      blockedDaysCount: blockedDaysSnapshot.size,
      blockedRangesCount: blockedRanges.length,
      icalEventsCount: icalEvents.length,
      excludeSource,
      minStayNights,
    });

    // 7e. Calculate gap blocks based on minimum stay
    // Prevents OTAs from showing availability for gaps shorter than min_stay
    const bookings = bookingsSnapshot.docs.map((doc) => ({
      ...doc.data(),
      id: doc.id,
    }));

    // Combine native bookings + imported events for gap calculation
    const allBookingsForGapCalc = [
      ...bookings,
      ...icalEvents.map((evt: any) => ({
        check_in: evt.start_date,
        check_out: evt.end_date,
      })),
    ];

    const gapBlocks = calculateMinStayGapBlocks(
      allBookingsForGapCalc,
      blockedRanges,
      minStayNights,
      pastDate,
      futureDate
    );

    if (gapBlocks.length > 0) {
      logInfo("[iCal Feed] Generated gap blocks", {
        propertyId,
        unitId,
        gapBlocksCount: gapBlocks.length,
      });
    }

    // 8. Generate iCal content (bookings + imported events + blocked days + gap blocks)
    const icalContent = generateIcalCalendar(
      unitName,
      bookings,
      icalEvents,
      [...blockedRanges, ...gapBlocks]
    );

    // 9. Generate ETag from content hash
    const etag = `"${generateContentHash(icalContent)}"`;

    // 10. Store in cache ONLY if not filtering by source
    // IMPORTANT: Filtered content should NOT be cached, otherwise the generic URL
    // would serve filtered content to other platforms
    if (!excludeSource) {
      await widgetSettingsDoc.ref.update({
        ical_export_last_generated: Timestamp.now(),
        ical_cache_content: icalContent,
        ical_cache_generated_at: Timestamp.now(),
        ical_cache_etag: etag,
        ical_cache_unit_name: unitName,
      });
    }

    // 11. Return fresh iCal file with cache headers
    setCacheHeaders(response, etag, ICAL_CONFIG.CACHE_TTL_SECONDS);
    response.set("Content-Type", "text/calendar; charset=utf-8");
    response.set("Content-Disposition", `attachment; filename="${sanitizeFilename(unitName)}.ics"`);
    response.status(200).send(icalContent);

    logInfo("[iCal Feed] Feed generated and cached", {
      propertyId,
      unitId,
      bookingCount: bookingsSnapshot.size,
      icalEventsCount: icalEvents.length,
      blockedDaysCount: blockedDaysSnapshot.size,
      blockedRangesCount: blockedRanges.length,
      excludeSource,
      cacheTTL: ICAL_CONFIG.CACHE_TTL_SECONDS,
    });
  } catch (error) {
    logError("[iCal Feed] Error generating feed", error);
    response.status(500).send("Internal server error");
  }
});

/**
 * Represents a range of consecutive blocked days
 */
interface BlockedRange {
  startDate: Date;
  endDate: Date; // Inclusive
}

/**
 * Group consecutive blocked days into ranges
 * This creates fewer VEVENT entries (more efficient for OTAs to parse)
 *
 * Example: [Jan 1, Jan 2, Jan 3, Jan 10, Jan 11]
 *       -> [{Jan 1 - Jan 3}, {Jan 10 - Jan 11}]
 */
function groupConsecutiveBlockedDays(dates: Date[]): BlockedRange[] {
  if (dates.length === 0) return [];

  // Sort dates chronologically
  const sortedDates = [...dates].sort((a, b) => a.getTime() - b.getTime());

  const ranges: BlockedRange[] = [];
  let rangeStart = sortedDates[0];
  let rangeEnd = sortedDates[0];

  for (let i = 1; i < sortedDates.length; i++) {
    const currentDate = sortedDates[i];
    const prevDate = sortedDates[i - 1];

    // Check if current date is consecutive (next day)
    const diffMs = currentDate.getTime() - prevDate.getTime();
    const diffDays = diffMs / (1000 * 60 * 60 * 24);

    if (diffDays <= 1.5) {
      // Consecutive - extend the range (allow small tolerance for timezone issues)
      rangeEnd = currentDate;
    } else {
      // Gap found - save current range and start new one
      ranges.push({ startDate: rangeStart, endDate: rangeEnd });
      rangeStart = currentDate;
      rangeEnd = currentDate;
    }
  }

  // Don't forget the last range
  ranges.push({ startDate: rangeStart, endDate: rangeEnd });

  return ranges;
}

/**
 * Calculate gaps between unavailable periods that are shorter than min_stay
 * These gaps effectively become blocked because they cannot be booked
 */
function calculateMinStayGapBlocks(
  bookings: any[],
  blockedRanges: BlockedRange[],
  minStayNights: number,
  startDate: Date,
  endDate: Date
): BlockedRange[] {
  if (minStayNights <= 1) return [];

  // 1. Combine all unavailable ranges (bookings + blocked days)
  const unavailableRanges: { start: number; end: number }[] = [];

  // Add bookings
  bookings.forEach((booking) => {
    const checkIn = booking.check_in?.toDate();
    const checkOut = booking.check_out?.toDate();
    if (checkIn && checkOut) {
      unavailableRanges.push({
        start: truncateTime(checkIn).getTime(),
        end: truncateTime(checkOut).getTime(),
      });
    }
  });

  // Add blocked days
  blockedRanges.forEach((range) => {
    // blockedRanges represent full blocked days (inclusive)
    // For gap calculation logic, we treat user blocks as:
    // Start: 00:00 of start date
    // End: 00:00 of day AFTER end date (like checkout)
    const rangeEnd = new Date(range.endDate);
    rangeEnd.setUTCDate(rangeEnd.getUTCDate() + 1);

    unavailableRanges.push({
      start: truncateTime(range.startDate).getTime(),
      end: truncateTime(rangeEnd).getTime(),
    });
  });

  // Sort by start date
  unavailableRanges.sort((a, b) => a.start - b.start);

  // 2. Find gaps
  const gapBlocks: BlockedRange[] = [];
  const oneDayMs = 1000 * 60 * 60 * 24;

  // Check gap from "now" (or pastDate) to first booking
  // We skip this usually as users might want last minute bookings
  // Only check gaps betwen ranges

  for (let i = 0; i < unavailableRanges.length - 1; i++) {
    const currentRangeEnd = unavailableRanges[i].end;
    const nextRangeStart = unavailableRanges[i + 1].start;

    // Check if there is a gap
    if (nextRangeStart > currentRangeEnd) {
      const gapMs = nextRangeStart - currentRangeEnd;
      const gapDays = Math.round(gapMs / oneDayMs);

      // If gap is smaller than min stay, block it
      if (gapDays > 0 && gapDays < minStayNights) {
        // Create a block for this gap
        // BlockedRange expects startDate and endDate (inclusive)
        // currentRangeEnd is like "Checkout", so the gap starts that day
        // nextRangeStart is like "Checkin", so gap ends the day before

        const gapStart = new Date(currentRangeEnd);
        const gapEnd = new Date(nextRangeStart);
        gapEnd.setUTCDate(gapEnd.getUTCDate() - 1); // Make inclusive

        gapBlocks.push({
          startDate: gapStart,
          endDate: gapEnd,
        });
      }
    }
  }

  return gapBlocks;
}

/**
 * Truncate time to midnight UTC for consistent comparisons
 *
 * TIMEZONE FIX: Firestore stores dates as midnight local time (UTC+1/+2 for Europe/Zagreb).
 * When converted to JS Date via .toDate(), these appear as 22:00/23:00 PREVIOUS day in UTC.
 * Example: "May 28, 00:00 UTC+2" → "May 27, 22:00 UTC" → getUTCDate() = 27 (WRONG!)
 * Adding 12h before truncating ensures we land on the correct calendar date:
 * "May 27, 22:00 UTC" + 12h → "May 28, 10:00 UTC" → setUTCHours(0) → "May 28, 00:00 UTC" ✓
 * This works for any timezone offset from UTC-12 to UTC+14.
 */
function truncateTime(date: Date): Date {
  const d = new Date(date.getTime() + 12 * 60 * 60 * 1000);
  d.setUTCHours(0, 0, 0, 0);
  return d;
}

/**
 * Generate iCal calendar content (RFC 5545)
 * Includes native bookings, imported events, AND blocked days
 *
 * IMPORTANT: Booking.com rejects empty iCal feeds (those without any VEVENT).
 * If there are no events, we generate a placeholder event to ensure acceptance.
 */
function generateIcalCalendar(
  unitName: string,
  bookings: any[],
  icalEvents: any[],
  blockedRanges: BlockedRange[] = []
): string {
  const lines: string[] = [];

  // Calendar header
  lines.push("BEGIN:VCALENDAR");
  lines.push("VERSION:2.0");
  lines.push("PRODID:-//BookBed//NONSGML Event Calendar//EN");
  lines.push("CALSCALE:GREGORIAN");
  lines.push("METHOD:PUBLISH");
  lines.push(`X-WR-CALNAME:${escapeIcal(unitName)} - Bookings`);
  lines.push("X-WR-TIMEZONE:Europe/Zagreb");
  lines.push(`X-WR-CALDESC:Booking calendar for ${escapeIcal(unitName)}`);

  // Add each native booking as an event
  for (const booking of bookings) {
    lines.push(...generateBookingEvent(booking, unitName));
  }

  // Add each imported event (from other platforms like Adriagate)
  // CRITICAL: This ensures cross-platform sync works (Adriagate → BookBed → Booking.com)
  for (const event of icalEvents) {
    lines.push(...generateIcalEventEntry(event, unitName));
  }

  // Add blocked day ranges as events
  // CRITICAL: This ensures Booking.com/Airbnb see these dates as unavailable!
  for (let i = 0; i < blockedRanges.length; i++) {
    lines.push(...generateBlockedEvent(blockedRanges[i], unitName, i));
  }

  // BOOKING.COM FIX: If no events exist, add a placeholder event
  // Booking.com rejects iCal feeds without at least one VEVENT
  const totalEvents = bookings.length + icalEvents.length + blockedRanges.length;
  if (totalEvents === 0) {
    lines.push(...generatePlaceholderEvent(unitName));
  }

  // Calendar footer
  lines.push("END:VCALENDAR");

  return lines.join("\r\n");
}

/**
 * Generate VEVENT for a booking
 */
function generateBookingEvent(booking: any, unitName: string): string[] {
  const lines: string[] = [];

  lines.push("BEGIN:VEVENT");

  // UID - Unique identifier
  lines.push(`UID:booking-${booking.id}@bookbed.io`);

  // DTSTAMP - Creation timestamp
  const created = booking.created_at?.toDate() || new Date();
  lines.push(`DTSTAMP:${formatTimestamp(created)}`);

  // DTSTART - Start date (all-day event)
  // truncateTime normalizes Firestore timezone (UTC+1/+2) to correct UTC calendar date
  const checkIn = truncateTime(booking.check_in?.toDate() || new Date());
  lines.push(`DTSTART;VALUE=DATE:${formatDate(checkIn)}`);

  // DTEND - End date (exclusive)
  // check_out IS the departure day. In iCal, DTEND is exclusive (up to but not including).
  // So if check_out = July 5, guests stayed nights 1,2,3,4 and July 5 is FREE for new check-in.
  // Do NOT add +1 day here - that would block the check-out day incorrectly.
  const checkOut = truncateTime(booking.check_out?.toDate() || new Date());
  lines.push(`DTEND;VALUE=DATE:${formatDate(checkOut)}`);

  // SUMMARY - Event title (GDPR compliant - no guest PII)
  // Industry standard: Airbnb, Booking.com, agencies all use generic "Reserved"/"Unavailable"
  lines.push(`SUMMARY:${escapeIcal("Reserved")}`);

  // DESCRIPTION - Minimal info (no guest PII for privacy/GDPR)
  const description = `${unitName}\\nManaged by BookBed`;
  lines.push(`DESCRIPTION:${escapeIcal(description)}`);

  // STATUS - Booking status
  const status = mapBookingStatus(booking.status);
  lines.push(`STATUS:${status}`);

  // TRANSP - OPAQUE means this blocks out time (important for OTA availability)
  lines.push("TRANSP:OPAQUE");

  // SEQUENCE - Event version (0 = original, increment on updates)
  lines.push("SEQUENCE:0");

  // Microsoft Outlook compatibility - mark as all-day busy event
  lines.push("X-MICROSOFT-CDO-ALLDAYEVENT:TRUE");
  lines.push("X-MICROSOFT-CDO-BUSYSTATUS:BUSY");

  // LOCATION - Unit name
  lines.push(`LOCATION:${escapeIcal(unitName)}`);

  // LAST-MODIFIED - Use updated_at if available, fallback to created_at
  const lastModified = booking.updated_at?.toDate() || created;
  lines.push(`LAST-MODIFIED:${formatTimestamp(lastModified)}`);

  // CREATED
  lines.push(`CREATED:${formatTimestamp(created)}`);

  lines.push("END:VEVENT");

  return lines;
}

/**
 * Generate VEVENT for imported iCal events (from Adriagate, other PMSs, etc.)
 * These events originated from external platforms and are being re-exported
 */
function generateIcalEventEntry(event: any, unitName: string): string[] {
  const lines: string[] = [];

  lines.push("BEGIN:VEVENT");

  // UID - Use external_id to maintain consistency with the original event
  // Prefix with "ical-" to distinguish from native bookings
  const externalId = event.external_id || event.id;
  lines.push(`UID:ical-${sanitizeUid(externalId)}@bookbed.io`);

  // DTSTAMP - Creation timestamp
  const created = event.created_at?.toDate() || new Date();
  lines.push(`DTSTAMP:${formatTimestamp(created)}`);

  // DTSTART - Start date (all-day event)
  const startDate = truncateTime(event.start_date?.toDate() || new Date());
  lines.push(`DTSTART;VALUE=DATE:${formatDate(startDate)}`);

  // DTEND - End date (exclusive in iCal)
  // Same logic as bookings: end_date IS the checkout day, DTEND is exclusive
  const endDate = truncateTime(event.end_date?.toDate() || new Date());
  lines.push(`DTEND;VALUE=DATE:${formatDate(endDate)}`);

  // SUMMARY - Generic "Reserved" (GDPR compliant, no PII)
  lines.push(`SUMMARY:${escapeIcal("Reserved")}`);

  // DESCRIPTION - Minimal info (source platform for reference)
  const source = event.source || "external";
  const description = `${unitName}\\nImported from ${capitalizeSource(source)}\\nManaged by BookBed`;
  lines.push(`DESCRIPTION:${escapeIcal(description)}`);

  // STATUS - CONFIRMED (these block dates)
  lines.push("STATUS:CONFIRMED");

  // TRANSP - OPAQUE means this blocks out time
  lines.push("TRANSP:OPAQUE");

  // SEQUENCE - Event version (0 = original)
  lines.push("SEQUENCE:0");

  // Microsoft Outlook compatibility
  lines.push("X-MICROSOFT-CDO-ALLDAYEVENT:TRUE");
  lines.push("X-MICROSOFT-CDO-BUSYSTATUS:BUSY");

  // LOCATION - Unit name
  lines.push(`LOCATION:${escapeIcal(unitName)}`);

  // LAST-MODIFIED and CREATED
  const lastModified = event.updated_at?.toDate() || created;
  lines.push(`LAST-MODIFIED:${formatTimestamp(lastModified)}`);
  lines.push(`CREATED:${formatTimestamp(created)}`);

  lines.push("END:VEVENT");

  return lines;
}

/**
 * Sanitize UID for iCal (remove special characters that might cause issues)
 */
function sanitizeUid(uid: string): string {
  return uid
    .replace(/[^a-zA-Z0-9@._-]/g, "-")
    .replace(/-+/g, "-");
}

/**
 * Capitalize source name for display
 */
function capitalizeSource(source: string): string {
  if (source === "booking_com") return "Booking.com";
  if (source === "airbnb") return "Airbnb";
  return source.charAt(0).toUpperCase() + source.slice(1);
}

/**
 * Generate VEVENT for blocked days
 * Creates a "Not Available" event that OTAs (Booking.com, Airbnb) will respect
 */
function generateBlockedEvent(
  range: BlockedRange,
  unitName: string,
  index: number
): string[] {
  const lines: string[] = [];

  lines.push("BEGIN:VEVENT");

  // UID - Unique identifier (includes date range to ensure uniqueness)
  // truncateTime normalizes Firestore timezone (UTC+1/+2) to correct UTC calendar date
  const start = truncateTime(range.startDate);
  const end = truncateTime(range.endDate);
  const startStr = formatDate(start);
  const endStr = formatDate(end);
  lines.push(`UID:blocked-${startStr}-${endStr}-${index}@bookbed.io`);

  // DTSTAMP - Creation timestamp (now)
  lines.push(`DTSTAMP:${formatTimestamp(new Date())}`);

  // DTSTART - Start date (all-day event)
  lines.push(`DTSTART;VALUE=DATE:${startStr}`);

  // DTEND - End date (exclusive in iCal, so add 1 day)
  const endDateExclusive = new Date(end);
  endDateExclusive.setUTCDate(endDateExclusive.getUTCDate() + 1);
  lines.push(`DTEND;VALUE=DATE:${formatDate(endDateExclusive)}`);

  // SUMMARY - Event title (standard "Not Available" format recognized by OTAs)
  lines.push(`SUMMARY:${escapeIcal("Not Available")}`);

  // DESCRIPTION - Additional context
  const dayCount = Math.round(
    (end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)
  ) + 1;
  const description = `Blocked dates for ${unitName}\\n` +
    `${dayCount} day${dayCount > 1 ? "s" : ""} unavailable\\n` +
    "Managed by BookBed";
  lines.push(`DESCRIPTION:${escapeIcal(description)}`);

  // STATUS - CONFIRMED means these dates are definitely blocked
  lines.push("STATUS:CONFIRMED");

  // TRANSP - OPAQUE means this blocks out time (important for availability!)
  lines.push("TRANSP:OPAQUE");

  // SEQUENCE - Event version (0 = original)
  lines.push("SEQUENCE:0");

  // Microsoft Outlook compatibility - mark as all-day busy event
  lines.push("X-MICROSOFT-CDO-ALLDAYEVENT:TRUE");
  lines.push("X-MICROSOFT-CDO-BUSYSTATUS:BUSY");

  // LOCATION - Unit name
  lines.push(`LOCATION:${escapeIcal(unitName)}`);

  // LAST-MODIFIED and CREATED
  lines.push(`LAST-MODIFIED:${formatTimestamp(new Date())}`);
  lines.push(`CREATED:${formatTimestamp(new Date())}`);

  lines.push("END:VEVENT");

  return lines;
}

/**
 * Generate placeholder VEVENT for empty calendars
 *
 * BOOKING.COM REQUIREMENT: iCal feeds must contain at least one VEVENT.
 * This placeholder event:
 * - Uses TRANSP:TRANSPARENT so it doesn't block any dates
 * - Creates an "Available" event for today
 * - Has minimal visibility in calendar apps
 *
 * This is a workaround for Booking.com's validation requirement.
 */
function generatePlaceholderEvent(unitName: string): string[] {
  const lines: string[] = [];
  const now = new Date();

  lines.push("BEGIN:VEVENT");

  // UID - Unique identifier for this placeholder
  lines.push(`UID:placeholder-${formatDate(now)}@bookbed.io`);

  // DTSTAMP - Creation timestamp (required by RFC 5545)
  lines.push(`DTSTAMP:${formatTimestamp(now)}`);

  // DTSTART/DTEND - Today as an all-day event
  lines.push(`DTSTART;VALUE=DATE:${formatDate(now)}`);
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  lines.push(`DTEND;VALUE=DATE:${formatDate(tomorrow)}`);

  // SUMMARY - Minimal placeholder text
  lines.push(`SUMMARY:${escapeIcal(`${unitName} - Calendar Active`)}`);

  // DESCRIPTION - Explain this is a placeholder
  lines.push(`DESCRIPTION:${escapeIcal("This calendar is synced with BookBed. No bookings yet.")}`);

  // STATUS - CONFIRMED for valid event
  lines.push("STATUS:CONFIRMED");

  // TRANSP - TRANSPARENT means this does NOT block time (important!)
  // This ensures dates remain available for booking
  lines.push("TRANSP:TRANSPARENT");

  // SEQUENCE - Event version (0 = original)
  lines.push("SEQUENCE:0");

  // Microsoft Outlook compatibility - mark as all-day free event
  lines.push("X-MICROSOFT-CDO-ALLDAYEVENT:TRUE");
  lines.push("X-MICROSOFT-CDO-BUSYSTATUS:FREE");

  // CREATED
  lines.push(`CREATED:${formatTimestamp(now)}`);

  lines.push("END:VEVENT");

  return lines;
}

// buildDescription removed - GDPR compliance
// iCal export now uses minimal "Reserved" summary with no guest PII
// Industry standard: Airbnb, Booking.com, agencies all hide guest info

/**
 * Map booking status to iCal STATUS
 *
 * NOTE: Pending bookings are exported as CONFIRMED (not TENTATIVE) because:
 * 1. In our system, pending bookings DO block dates (prevent overbooking)
 * 2. Airbnb only reliably imports CONFIRMED events — TENTATIVE may be ignored
 * 3. If we export pending as TENTATIVE, OTAs might allow double-bookings
 */
function mapBookingStatus(status: string): string {
  switch (status) {
    case "confirmed": return "CONFIRMED";
    case "pending": return "CONFIRMED";
    case "cancelled": return "CANCELLED";
    case "completed": return "CONFIRMED";
    default: return "CONFIRMED";
  }
}

/**
 * Format date as YYYYMMDD (UTC)
 * IMPORTANT: Uses UTC methods to ensure consistent dates regardless of server timezone
 */
function formatDate(date: Date): string {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  const day = String(date.getUTCDate()).padStart(2, "0");
  return `${year}${month}${day}`;
}

/**
 * Format timestamp as YYYYMMDDTHHMMSSZ (UTC)
 */
function formatTimestamp(date: Date): string {
  const utc = new Date(date.toISOString());
  const year = utc.getUTCFullYear();
  const month = String(utc.getUTCMonth() + 1).padStart(2, "0");
  const day = String(utc.getUTCDate()).padStart(2, "0");
  const hour = String(utc.getUTCHours()).padStart(2, "0");
  const minute = String(utc.getUTCMinutes()).padStart(2, "0");
  const second = String(utc.getUTCSeconds()).padStart(2, "0");
  return `${year}${month}${day}T${hour}${minute}${second}Z`;
}

/**
 * Escape special characters for iCal (RFC 5545)
 */
function escapeIcal(text: string): string {
  return text
    .replace(/\\/g, "\\\\")
    .replace(/,/g, "\\,")
    .replace(/;/g, "\\;")
    .replace(/\n/g, "\\n");
}

/**
 * Sanitize filename
 */
function sanitizeFilename(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
}
