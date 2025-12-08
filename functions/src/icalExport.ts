import {onRequest} from "firebase-functions/v2/https";
import * as crypto from "crypto";
import {admin} from "./firebase";
import {logInfo, logError} from "./logger";

// =============================================================================
// CONFIGURATION
// =============================================================================
const ICAL_CONFIG = {
  // DoS Protection: Maximum bookings to include in feed
  MAX_BOOKINGS: 500,
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
  response: {set: (name: string, value: string) => void},
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
    const pathParts = request.path.split("/").filter(p => p);

    if (pathParts.length < 3) {
      response.status(400).send("Invalid URL format. Expected: /{propertyId}/{unitId}/{token}");
      return;
    }

    const propertyId = pathParts[0];
    const unitId = pathParts[1];
    const token = pathParts[2];

    logInfo("[iCal Feed] Request received", {propertyId, unitId});

    const db = admin.firestore();

    // 1. Verify token against widget_settings
    const widgetSettingsDoc = await db
      .collection("properties")
      .doc(propertyId)
      .collection("widget_settings")
      .doc(unitId)
      .get();

    if (!widgetSettingsDoc.exists) {
      logError("[iCal Feed] Widget settings not found", {propertyId, unitId});
      response.status(404).send("Unit not found");
      return;
    }

    const widgetSettings = widgetSettingsDoc.data();

    // Check if iCal export is enabled
    if (!widgetSettings?.ical_export_enabled) {
      logError("[iCal Feed] iCal export disabled", {propertyId, unitId});
      response.status(403).send("iCal export is disabled for this unit");
      return;
    }

    // Verify token using timing-safe comparison (prevents timing attacks)
    if (!verifyIcalToken(token, widgetSettings.ical_export_token || "")) {
      logError("[iCal Feed] Invalid token", {propertyId, unitId});
      response.status(403).send("Invalid token");
      return;
    }

    // 2. Check cache - return cached content if still valid
    const cachedContent = widgetSettings.ical_cache_content;
    const cachedAt = widgetSettings.ical_cache_generated_at?.toDate();
    const cachedETag = widgetSettings.ical_cache_etag;

    const now = new Date();
    const cacheExpiry = cachedAt
      ? new Date(cachedAt.getTime() + ICAL_CONFIG.CACHE_TTL_SECONDS * 1000)
      : null;
    const cacheValid = cacheExpiry && now < cacheExpiry && cachedContent;

    // 3. Handle ETag/If-None-Match for bandwidth optimization
    const clientETag = request.headers["if-none-match"];
    if (cacheValid && clientETag && clientETag === cachedETag) {
      logInfo("[iCal Feed] 304 Not Modified (ETag match)", {propertyId, unitId});
      response.status(304).send("");
      return;
    }

    // 4. Return cached content if still valid
    if (cacheValid && cachedContent) {
      logInfo("[iCal Feed] Serving cached content", {propertyId, unitId});
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

    // 6. Calculate date range for DoS protection
    const pastDate = new Date();
    pastDate.setDate(pastDate.getDate() - ICAL_CONFIG.PAST_DAYS);
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + ICAL_CONFIG.FUTURE_DAYS);

    // 7. Fetch bookings with date filter and limit (DoS protection)
    const bookingsSnapshot = await db
      .collection("bookings")
      .where("unit_id", "==", unitId)
      .where("status", "in", ["confirmed", "pending", "completed"])
      .where("check_in", ">=", admin.firestore.Timestamp.fromDate(pastDate))
      .where("check_in", "<=", admin.firestore.Timestamp.fromDate(futureDate))
      .orderBy("check_in", "asc")
      .limit(ICAL_CONFIG.MAX_BOOKINGS)
      .get();

    // 8. Generate iCal content
    const icalContent = generateIcalCalendar(
      unitName,
      bookingsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }))
    );

    // 9. Generate ETag from content hash
    const etag = `"${generateContentHash(icalContent)}"`;

    // 10. Store in cache
    await widgetSettingsDoc.ref.update({
      ical_export_last_generated: admin.firestore.Timestamp.now(),
      ical_cache_content: icalContent,
      ical_cache_generated_at: admin.firestore.Timestamp.now(),
      ical_cache_etag: etag,
      ical_cache_unit_name: unitName,
    });

    // 11. Return fresh iCal file with cache headers
    setCacheHeaders(response, etag, ICAL_CONFIG.CACHE_TTL_SECONDS);
    response.set("Content-Type", "text/calendar; charset=utf-8");
    response.set("Content-Disposition", `attachment; filename="${sanitizeFilename(unitName)}.ics"`);
    response.status(200).send(icalContent);

    logInfo("[iCal Feed] Feed generated and cached", {
      propertyId,
      unitId,
      bookingCount: bookingsSnapshot.size,
      cacheTTL: ICAL_CONFIG.CACHE_TTL_SECONDS,
    });
  } catch (error) {
    logError("[iCal Feed] Error generating feed", error);
    response.status(500).send("Internal server error");
  }
});

/**
 * Generate iCal calendar content (RFC 5545)
 */
function generateIcalCalendar(unitName: string, bookings: any[]): string {
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

  // Add each booking as an event
  for (const booking of bookings) {
    lines.push(...generateEvent(booking, unitName));
  }

  // Calendar footer
  lines.push("END:VCALENDAR");

  return lines.join("\r\n");
}

/**
 * Generate single event (VEVENT)
 */
function generateEvent(booking: any, unitName: string): string[] {
  const lines: string[] = [];

  lines.push("BEGIN:VEVENT");
  
  // UID - Unique identifier
  lines.push(`UID:booking-${booking.id}@rab-booking.com`);
  
  // DTSTAMP - Creation timestamp
  const created = booking.created_at?.toDate() || new Date();
  lines.push(`DTSTAMP:${formatTimestamp(created)}`);
  
  // DTSTART - Start date (all-day event)
  const checkIn = booking.check_in?.toDate() || new Date();
  lines.push(`DTSTART;VALUE=DATE:${formatDate(checkIn)}`);
  
  // DTEND - End date (exclusive, day after checkout)
  const checkOut = booking.check_out?.toDate() || new Date();
  const endDate = new Date(checkOut);
  endDate.setDate(endDate.getDate() + 1);
  lines.push(`DTEND;VALUE=DATE:${formatDate(endDate)}`);
  
  // SUMMARY - Event title
  const guestName = booking.guest_name || "Guest";
  lines.push(`SUMMARY:${escapeIcal(`Booking: ${guestName} - ${unitName}`)}`);
  
  // DESCRIPTION - Event details
  const description = buildDescription(booking, unitName);
  lines.push(`DESCRIPTION:${escapeIcal(description)}`);
  
  // STATUS - Booking status
  const status = mapBookingStatus(booking.status);
  lines.push(`STATUS:${status}`);
  
  // LOCATION - Unit name
  lines.push(`LOCATION:${escapeIcal(unitName)}`);
  
  // LAST-MODIFIED
  if (booking.updated_at) {
    const updated = booking.updated_at.toDate();
    lines.push(`LAST-MODIFIED:${formatTimestamp(updated)}`);
  }
  
  // CREATED
  lines.push(`CREATED:${formatTimestamp(created)}`);
  
  lines.push("END:VEVENT");

  return lines;
}

/**
 * Build event description
 */
function buildDescription(booking: any, unitName: string): string {
  const parts: string[] = [];

  parts.push(`Unit: ${unitName}`);
  
  if (booking.guest_name) parts.push(`Guest: ${booking.guest_name}`);
  if (booking.guest_email) parts.push(`Email: ${booking.guest_email}`);
  if (booking.guest_phone) parts.push(`Phone: ${booking.guest_phone}`);
  
  parts.push(`Guests: ${booking.guest_count || 1}`);
  
  if (booking.check_in_time) parts.push(`Check-in: ${booking.check_in_time}`);
  if (booking.check_out_time) parts.push(`Check-out: ${booking.check_out_time}`);
  
  if (booking.total_price) {
    parts.push(`Total: €${booking.total_price.toFixed(2)}`);
  }
  
  if (booking.payment_status) {
    parts.push(`Payment: ${booking.payment_status}`);
  }
  
  if (booking.notes) parts.push(`Notes: ${booking.notes}`);
  
  parts.push(`Booking ID: ${booking.id}`);

  return parts.join("\\n");
}

/**
 * Map booking status to iCal STATUS
 */
function mapBookingStatus(status: string): string {
  switch (status) {
    case "confirmed": return "CONFIRMED";
    case "pending": return "TENTATIVE";
    case "cancelled": return "CANCELLED";
    case "completed": return "CONFIRMED";
    default: return "TENTATIVE";
  }
}

/**
 * Format date as YYYYMMDD
 */
function formatDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
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
