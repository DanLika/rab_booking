import {HttpsError} from "firebase-functions/v2/https";
import {admin} from "../firebase";

/**
 * Safely convert any date-like value to JavaScript Date
 *
 * Handles:
 * - Firestore Timestamp (has .toDate() method)
 * - JavaScript Date objects
 * - ISO date strings
 * - Unix timestamps (milliseconds)
 *
 * @param value - Date-like value to convert
 * @param fieldName - Name of field for error messages
 * @return JavaScript Date object
 * @throws Error if value cannot be converted
 */
export function safeToDate(
  value: unknown,
  fieldName = "date"
): Date {
  if (!value) {
    throw new Error(`${fieldName} is required but was ${value}`);
  }

  // Handle Firestore Timestamp (has .toDate() method)
  if (
    typeof value === "object" &&
    value !== null &&
    "toDate" in value &&
    typeof (value as {toDate: () => Date}).toDate === "function"
  ) {
    return (value as {toDate: () => Date}).toDate();
  }

  // Handle Date object
  if (value instanceof Date) {
    if (isNaN(value.getTime())) {
      throw new Error(`${fieldName} is an invalid Date object`);
    }
    return value;
  }

  // Handle string (ISO format)
  if (typeof value === "string") {
    const date = new Date(value);
    if (isNaN(date.getTime())) {
      throw new Error(`${fieldName} string "${value}" is not a valid date`);
    }
    return date;
  }

  // Handle number (Unix timestamp in milliseconds)
  if (typeof value === "number") {
    const date = new Date(value);
    if (isNaN(date.getTime())) {
      throw new Error(`${fieldName} timestamp ${value} is not a valid date`);
    }
    return date;
  }

  throw new Error(
    `${fieldName} has unsupported type: ${typeof value}. ` +
    "Expected Timestamp, Date, string, or number."
  );
}

/**
 * Validate and convert booking dates to Firestore Timestamps
 *
 * VALIDATES:
 * - Date format (ISO string, timestamp, or Date object)
 * - Valid date objects (not Invalid Date)
 * - Date order (checkOut must be after checkIn)
 * - Check-in not in the past
 *
 * @param checkIn - Check-in date (string, number, or Date)
 * @param checkOut - Check-out date (string, number, or Date)
 * @return Object with validated Firestore Timestamps
 * @throws HttpsError if validation fails
 */
export function validateAndConvertBookingDates(
  checkIn: string | number | Date | null | undefined,
  checkOut: string | number | Date | null | undefined
): {
  checkInDate: admin.firestore.Timestamp;
  checkOutDate: admin.firestore.Timestamp;
} {
  // ========================================================================
  // STEP 1: VALIDATE REQUIRED FIELDS
  // ========================================================================
  if (!checkIn) {
    throw new HttpsError("invalid-argument", "Check-in date is required");
  }

  if (!checkOut) {
    throw new HttpsError("invalid-argument", "Check-out date is required");
  }

  // ========================================================================
  // STEP 2: PARSE DATES
  // ========================================================================
  let checkInDateObj: Date;
  let checkOutDateObj: Date;

  try {
    // Handle different input types
    if (typeof checkIn === "string" || typeof checkIn === "number") {
      checkInDateObj = new Date(checkIn);
    } else if (checkIn instanceof Date) {
      checkInDateObj = checkIn;
    } else {
      throw new HttpsError(
        "invalid-argument",
        `Invalid check-in date type: ${typeof checkIn}`
      );
    }

    if (typeof checkOut === "string" || typeof checkOut === "number") {
      checkOutDateObj = new Date(checkOut);
    } else if (checkOut instanceof Date) {
      checkOutDateObj = checkOut;
    } else {
      throw new HttpsError(
        "invalid-argument",
        `Invalid check-out date type: ${typeof checkOut}`
      );
    }
  } catch (error) {
    if (error instanceof HttpsError) throw error;

    throw new HttpsError(
      "invalid-argument",
      `Failed to parse dates: ${error instanceof Error ? error.message : "Unknown error"}`
    );
  }

  // ========================================================================
  // STEP 3: VALIDATE DATE OBJECTS
  // ========================================================================

  // Check: Is check-in date valid?
  if (isNaN(checkInDateObj.getTime())) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid check-in date: "${String(checkIn)}". Please provide a valid date.`
    );
  }

  // Check: Is check-out date valid?
  if (isNaN(checkOutDateObj.getTime())) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid check-out date: "${String(checkOut)}". Please provide a valid date.`
    );
  }

  // ========================================================================
  // STEP 4: VALIDATE DATE ORDER
  // ========================================================================

  // Check: checkOut MUST be after checkIn
  if (checkOutDateObj <= checkInDateObj) {
    throw new HttpsError(
      "invalid-argument",
      "Check-out date must be after check-in date"
    );
  }

  // ========================================================================
  // STEP 5: VALIDATE CHECK-IN IS NOT IN PAST
  // ========================================================================

  // BUG-010 FIX: Use Date.UTC() for consistent cross-timezone validation
  // Previous implementation used setUTCHours on local Date which could cause
  // inconsistent behavior depending on server timezone (europe-west1, us-central1, etc.)
  const now = new Date();
  const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

  // Normalize check-in to midnight UTC for comparison
  const checkInMidnight = new Date(Date.UTC(
    checkInDateObj.getUTCFullYear(),
    checkInDateObj.getUTCMonth(),
    checkInDateObj.getUTCDate()
  ));

  // Check: Is check-in in the past?
  if (checkInMidnight < today) {
    throw new HttpsError(
      "invalid-argument",
      "Check-in date cannot be in the past"
    );
  }

  // ========================================================================
  // STEP 6: NORMALIZE + CONVERT TO FIRESTORE TIMESTAMPS (SF-026)
  // ========================================================================
  // Persist Timestamps at UTC midnight of the Zagreb-civil-day they represent.
  // Why: (1) cross-language nights count must agree — `.difference().inDays`
  //   (Dart, floor) vs `Math.ceil(/86_400_000)` (TS, ceil) disagree when input
  //   has non-zero time component, especially across DST. UTC-midnight inputs
  //   make both return identical integer N.
  // Why Zagreb-civil-day (not UTC-day): widget sends ISO `YYYY-MM-DDT00:00+02:00`
  //   for Croatian clients, which parses to UTC `prevDay 22:00Z`. A naive
  //   `getUTCDate()`-based normalization would shift display backward by 1 day
  //   for every Zagreb-originated booking. Extracting the Zagreb civil day
  //   first preserves "which day did the guest book?" semantics.
  // Assumption: properties are in `Europe/Zagreb` (consistent with email
  //   templates per CLAUDE.md Critical Learning #1). Property-TZ field is a
  //   future extension if multi-region hosting becomes a product requirement.
  const checkInNormalized = normalizeToZagrebCivilDayUTC(checkInDateObj);
  const checkOutNormalized = normalizeToZagrebCivilDayUTC(checkOutDateObj);

  const checkInDate = admin.firestore.Timestamp.fromDate(checkInNormalized);
  const checkOutDate = admin.firestore.Timestamp.fromDate(checkOutNormalized);

  return {checkInDate, checkOutDate};
}

/**
 * Normalize an arbitrary Date to UTC midnight of the Zagreb civil day it falls
 * on, so persisted booking Timestamps yield the same integer nights count
 * regardless of derivation algorithm (`.difference().inDays` vs `Math.ceil`)
 * and preserve "day the guest selected" through Zagreb-TZ display.
 *
 * Exported for the SF-026 backfill migration script.
 */
export function normalizeToZagrebCivilDayUTC(date: Date): Date {
  const ymd = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Zagreb",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
  const [yStr, mStr, dStr] = ymd.split("-");
  return new Date(Date.UTC(Number(yStr), Number(mStr) - 1, Number(dStr)));
}

/**
 * Owner-side variant of `validateAndConvertBookingDates`.
 *
 * Reuses parsing + order validation + SF-026 Zagreb-civil-day normalization,
 * but SKIPS the "check-in not in past" guard so that owners may record
 * historical bookings (manual entry of past stays for the books).
 *
 * Why a sibling instead of `allowPast: boolean` flag on the original:
 * the guest/widget path must NEVER accept past dates — keeping the helpers
 * separate eliminates the risk of a stray `allowPast: true` slipping into a
 * widget-facing CF.
 */
export function validateOwnerBookingDates(
  checkIn: string | number | Date | null | undefined,
  checkOut: string | number | Date | null | undefined
): {
  checkInDate: admin.firestore.Timestamp;
  checkOutDate: admin.firestore.Timestamp;
} {
  if (!checkIn) {
    throw new HttpsError("invalid-argument", "Check-in date is required");
  }
  if (!checkOut) {
    throw new HttpsError("invalid-argument", "Check-out date is required");
  }

  let checkInDateObj: Date;
  let checkOutDateObj: Date;

  try {
    if (typeof checkIn === "string" || typeof checkIn === "number") {
      checkInDateObj = new Date(checkIn);
    } else if (checkIn instanceof Date) {
      checkInDateObj = checkIn;
    } else {
      throw new HttpsError(
        "invalid-argument",
        `Invalid check-in date type: ${typeof checkIn}`
      );
    }

    if (typeof checkOut === "string" || typeof checkOut === "number") {
      checkOutDateObj = new Date(checkOut);
    } else if (checkOut instanceof Date) {
      checkOutDateObj = checkOut;
    } else {
      throw new HttpsError(
        "invalid-argument",
        `Invalid check-out date type: ${typeof checkOut}`
      );
    }
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError(
      "invalid-argument",
      `Failed to parse dates: ${error instanceof Error ? error.message : "Unknown error"}`
    );
  }

  if (isNaN(checkInDateObj.getTime())) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid check-in date: "${String(checkIn)}". Please provide a valid date.`
    );
  }
  if (isNaN(checkOutDateObj.getTime())) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid check-out date: "${String(checkOut)}". Please provide a valid date.`
    );
  }

  if (checkOutDateObj <= checkInDateObj) {
    throw new HttpsError(
      "invalid-argument",
      "Check-out date must be after check-in date"
    );
  }

  // Past-date guard intentionally omitted. Normalize to Zagreb-civil-day UTC
  // for consistent SF-026 nights count across Dart/TS.
  const checkInNormalized = normalizeToZagrebCivilDayUTC(checkInDateObj);
  const checkOutNormalized = normalizeToZagrebCivilDayUTC(checkOutDateObj);

  return {
    checkInDate: admin.firestore.Timestamp.fromDate(checkInNormalized),
    checkOutDate: admin.firestore.Timestamp.fromDate(checkOutNormalized),
  };
}

/**
 * Calculate number of nights in a booking
 *
 * @param checkIn - Check-in Firestore Timestamp
 * @param checkOut - Check-out Firestore Timestamp
 * @return Number of nights (always >= 1)
 */
export function calculateBookingNights(
  checkIn: admin.firestore.Timestamp,
  checkOut: admin.firestore.Timestamp
): number {
  const nights = Math.ceil(
    (checkOut.toDate().getTime() - checkIn.toDate().getTime()) /
      (1000 * 60 * 60 * 24)
  );

  // Sanity check (should never happen if dates are validated)
  if (nights < 1) {
    throw new Error("Booking nights calculation resulted in < 1 night");
  }

  return nights;
}

/**
 * Calculate days in advance for booking
 *
 * Used for min/max days advance validation in daily_prices
 *
 * @param checkInDate - Check-in Firestore Timestamp
 * @return Number of days in advance (0 = today, 1 = tomorrow, etc.)
 */
export function calculateDaysInAdvance(
  checkInDate: admin.firestore.Timestamp
): number {
  // BUG-010 FIX: Use Date.UTC() for consistent cross-timezone calculation
  const now = new Date();
  const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

  const checkInDateObj = checkInDate.toDate();
  const checkInMidnight = new Date(Date.UTC(
    checkInDateObj.getUTCFullYear(),
    checkInDateObj.getUTCMonth(),
    checkInDateObj.getUTCDate()
  ));

  const daysInAdvance = Math.floor(
    (checkInMidnight.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)
  );

  return daysInAdvance;
}
