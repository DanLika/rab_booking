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
 * @returns JavaScript Date object
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
    `Expected Timestamp, Date, string, or number.`
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
 * @returns Object with validated Firestore Timestamps
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
  // STEP 6: CONVERT TO FIRESTORE TIMESTAMPS
  // ========================================================================
  const checkInDate = admin.firestore.Timestamp.fromDate(checkInDateObj);
  const checkOutDate = admin.firestore.Timestamp.fromDate(checkOutDateObj);

  return {checkInDate, checkOutDate};
}

/**
 * Calculate number of nights in a booking
 *
 * @param checkIn - Check-in Firestore Timestamp
 * @param checkOut - Check-out Firestore Timestamp
 * @returns Number of nights (always >= 1)
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
 * @returns Number of days in advance (0 = today, 1 = tomorrow, etc.)
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
