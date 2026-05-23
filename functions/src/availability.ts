/**
 * Cloud Function: getUnitAvailability
 *
 * Serves unit availability windows to the public widget without exposing PII.
 *
 * Unblocks SF-023 (locking `ical_events` public-read in `firestore.rules`) by
 * routing the widget calendar through this callable. Also lays the groundwork
 * for T11c (eventually locking the `bookings` `unit_id+status` public-read
 * clause once the widget bookings stream is migrated here too — out of scope
 * for this PR; see `audit/06-availability-cf-design.md`).
 *
 * Returns:
 *   - `windows: AvailabilityWindow[]` — sorted, PII-stripped blocked ranges
 *     with a `source` discriminator (`booking` | `manual_block` |
 *     `ical_external`). The widget filters by source today (ical_external
 *     only) and will consume the others when T11c lands.
 *
 * Security:
 *   - Anonymous callers allowed (widget is public). Inputs strictly validated.
 *   - No PII (guest_name / guest_email / payment fields) ever leaves the CF.
 *   - 30 requests/min/(unitId+IP-hash) in-memory rate limit. Fail-closed.
 *   - Range capped at 366 days to bound query cost.
 *
 * Region: europe-west1 (matches other heavy `collectionGroup` consumers —
 * `icalSync.ts`, `scheduledPushNotifications.ts`).
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {db, admin} from "./firebase";
import {logInfo, logError, logWarn} from "./logger";
import {getClientIp, hashIp} from "./utils/ipUtils";
import {checkRateLimit} from "./utils/rateLimit";

const MAX_RANGE_DAYS = 366;
const MAX_BOOKINGS_PER_QUERY = 500;
const MAX_PRICES_PER_QUERY = 400; // ~366 + slack
const MAX_ICAL_PER_QUERY = 500;
const RATE_LIMIT_MAX = 30;
const RATE_LIMIT_WINDOW_SECONDS = 60;
const CACHE_HINT_SECONDS = 30;

type WindowSource = "booking" | "manual_block" | "ical_external";

interface AvailabilityWindow {
  start: string; // ISO 8601 UTC, inclusive
  end: string; // ISO 8601 UTC, exclusive
  source: WindowSource;
  /**
   * Platform attribution for `ical_external` windows (e.g., "Airbnb",
   * "Booking.com"). Unset for `booking` / `manual_block`. NOT PII —
   * the owner explicitly subscribes their iCal feed to these platforms.
   */
  platform?: string;
}

interface GetUnitAvailabilityInput {
  propertyId?: unknown;
  unitId?: unknown;
  startDate?: unknown;
  endDate?: unknown;
}

interface GetUnitAvailabilityOutput {
  unitId: string;
  windows: AvailabilityWindow[];
  generatedAt: string;
  cacheHint: number;
}

function parseIsoDate(value: unknown, field: string): Date {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} must be a non-empty ISO 8601 string`);
  }
  const ms = Date.parse(value);
  if (Number.isNaN(ms)) {
    throw new HttpsError("invalid-argument", `${field} is not a valid date`);
  }
  return new Date(ms);
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${field} must be a non-empty string`);
  }
  return value;
}

function toIsoOrNull(value: unknown): string | null {
  if (!value) return null;
  // Firestore Timestamp
  if (
    typeof value === "object" &&
    value !== null &&
    "toDate" in value &&
    typeof (value as {toDate: () => Date}).toDate === "function"
  ) {
    try {
      return (value as {toDate: () => Date}).toDate().toISOString();
    } catch {
      return null;
    }
  }
  if (value instanceof Date) {
    return value.toISOString();
  }
  if (typeof value === "string") {
    const ms = Date.parse(value);
    return Number.isNaN(ms) ? null : new Date(ms).toISOString();
  }
  return null;
}

export const getUnitAvailability = onCall<GetUnitAvailabilityInput, Promise<GetUnitAvailabilityOutput>>(
  {
    region: "europe-west1",
    memory: "256MiB",
    timeoutSeconds: 30,
    maxInstances: 50,
    cors: true,
  },
  async (request): Promise<GetUnitAvailabilityOutput> => {
    const propertyId = requireNonEmptyString(request.data?.propertyId, "propertyId");
    const unitId = requireNonEmptyString(request.data?.unitId, "unitId");
    const startDate = parseIsoDate(request.data?.startDate, "startDate");
    const endDate = parseIsoDate(request.data?.endDate, "endDate");

    if (!(endDate.getTime() > startDate.getTime())) {
      throw new HttpsError("invalid-argument", "endDate must be after startDate");
    }
    const rangeDays = (endDate.getTime() - startDate.getTime()) / 86_400_000;
    if (rangeDays > MAX_RANGE_DAYS) {
      throw new HttpsError(
        "out-of-range",
        `Date range exceeds ${MAX_RANGE_DAYS} days`
      );
    }

    const clientIp = getClientIp(request);
    const ipKey = hashIp(clientIp);
    if (!checkRateLimit(`avail:${unitId}:${ipKey}`, RATE_LIMIT_MAX, RATE_LIMIT_WINDOW_SECONDS)) {
      logWarn("[GetUnitAvailability] Rate limit exceeded", {unitId, ipKey});
      throw new HttpsError("resource-exhausted", "Too many availability requests");
    }

    const startTs = admin.firestore.Timestamp.fromDate(startDate);
    const endTs = admin.firestore.Timestamp.fromDate(endDate);

    try {
      const [bookingsSnap, pricesSnap, icalSnap] = await Promise.all([
        db
          .collectionGroup("bookings")
          .where("unit_id", "==", unitId)
          .where("status", "in", ["pending", "confirmed"])
          .limit(MAX_BOOKINGS_PER_QUERY)
          .get(),
        db
          .collection("properties")
          .doc(propertyId)
          .collection("units")
          .doc(unitId)
          .collection("daily_prices")
          .where("date", ">=", startTs)
          .where("date", "<=", endTs)
          .where("available", "==", false)
          .limit(MAX_PRICES_PER_QUERY)
          .get(),
        db
          .collectionGroup("ical_events")
          .where("unit_id", "==", unitId)
          .limit(MAX_ICAL_PER_QUERY)
          .get(),
      ]);

      if (bookingsSnap.empty && pricesSnap.empty && icalSnap.empty) {
        const propertyDoc = await db.collection("properties").doc(propertyId).get();
        if (!propertyDoc.exists) {
          if (checkRateLimit(`avail_unknown_warn:${ipKey}`, 1, 3600)) {
            logWarn("[GetUnitAvailability] Unknown property/unit lookup", {
              propertyId,
              unitId,
              ipHash: hashIp(getClientIp(request)),
              timestamp: new Date().toISOString(),
              userAgent: (request.rawRequest?.headers?.["user-agent"] as string)?.slice(0, 120) ?? "n/a",
            });
          }
        }
      }

      const windows: AvailabilityWindow[] = [];

      for (const doc of bookingsSnap.docs) {
        const data = doc.data();
        const start = toIsoOrNull(data.check_in);
        const end = toIsoOrNull(data.check_out);
        if (!start || !end) continue;
        // Bound to requested range (overlap), and intentionally drop
        // every PII field. Only start/end/source survive.
        if (Date.parse(end) <= startDate.getTime()) continue;
        if (Date.parse(start) >= endDate.getTime()) continue;
        windows.push({start, end, source: "booking"});
      }

      for (const doc of pricesSnap.docs) {
        const data = doc.data();
        const dayStart = toIsoOrNull(data.date);
        if (!dayStart) continue;
        const dayMs = Date.parse(dayStart);
        const dayEnd = new Date(dayMs + 86_400_000).toISOString();
        windows.push({start: dayStart, end: dayEnd, source: "manual_block"});
      }

      for (const doc of icalSnap.docs) {
        const data = doc.data();
        // Echo events don't block availability — match client-side rule.
        if (data.status === "confirmed_echo") continue;
        const start = toIsoOrNull(data.start_date);
        const end = toIsoOrNull(data.end_date);
        if (!start || !end) continue;
        if (Date.parse(end) <= startDate.getTime()) continue;
        if (Date.parse(start) >= endDate.getTime()) continue;
        const platform =
          typeof data.source === "string" && data.source.length > 0 ?
            data.source :
            undefined;
        windows.push({start, end, source: "ical_external", platform});
      }

      windows.sort((a, b) => a.start.localeCompare(b.start));

      logInfo("[GetUnitAvailability] Served availability", {
        unitId,
        propertyId,
        windowCount: windows.length,
        rangeDays: Math.round(rangeDays),
      });

      return {
        unitId,
        windows,
        generatedAt: new Date().toISOString(),
        cacheHint: CACHE_HINT_SECONDS,
      };
    } catch (error: unknown) {
      if (error instanceof HttpsError) {
        throw error;
      }
      logError("[GetUnitAvailability] Internal error", error, {unitId, propertyId});
      throw new HttpsError("internal", "Failed to fetch availability");
    }
  }
);
