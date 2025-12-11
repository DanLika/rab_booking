/**
 * Price Validation Utilities
 *
 * SECURITY CRITICAL: Server-side price calculation and validation
 *
 * Prevents price manipulation attacks where malicious users could:
 * - Book a €1000/night unit for €1 by manipulating totalPrice parameter
 * - Bypass deposit calculations
 * - Cause financial loss to property owners
 *
 * @module priceValidation
 */

import {admin, db} from "../firebase";
import {HttpsError} from "firebase-functions/v2/https";
import {logInfo, logError} from "../logger";

/**
 * Price calculation result
 */
interface PriceCalculationResult {
  /** Total price calculated from daily_prices */
  totalPrice: number;
  /** Number of nights in the booking */
  nights: number;
  /** Breakdown of prices per night */
  breakdown: Array<{date: string; price: number}>;
}

/**
 * Calculate total booking price from daily_prices collection (SERVER-SIDE ONLY)
 *
 * SECURITY: This is the ONLY source of truth for booking prices.
 * Client-provided prices MUST be validated against this calculation.
 *
 * @param unitId - The unit ID to calculate price for
 * @param checkInDate - Check-in date (Firestore Timestamp)
 * @param checkOutDate - Check-out date (Firestore Timestamp)
 * @param transaction - Optional Firestore transaction for atomic reads
 * @returns Price calculation result with total and breakdown
 * @throws HttpsError if pricing not configured or invalid
 */
export async function calculateBookingPrice(
  unitId: string,
  checkInDate: admin.firestore.Timestamp,
  checkOutDate: admin.firestore.Timestamp,
  transaction?: admin.firestore.Transaction
): Promise<PriceCalculationResult> {
  // Calculate expected number of nights
  const checkInMs = checkInDate.toMillis();
  const checkOutMs = checkOutDate.toMillis();
  const msPerDay = 24 * 60 * 60 * 1000;
  const expectedNights = Math.round((checkOutMs - checkInMs) / msPerDay);

  if (expectedNights <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Check-out must be after check-in"
    );
  }

  // Query daily_prices for the booking range
  // NOTE: We query check-in to check-out (exclusive) because
  // check-out day is not charged (guest leaves)
  const dailyPricesQuery = db
    .collection("daily_prices")
    .where("unit_id", "==", unitId)
    .where("date", ">=", checkInDate)
    .where("date", "<", checkOutDate)
    .orderBy("date", "asc");

  // Execute query (inside or outside transaction)
  const snapshot = transaction ?
    await transaction.get(dailyPricesQuery) :
    await dailyPricesQuery.get();

  // Build price breakdown
  const breakdown: Array<{date: string; price: number}> = [];
  let totalPrice = 0;

  for (const doc of snapshot.docs) {
    const priceData = doc.data();
    const dateTimestamp = priceData.date as admin.firestore.Timestamp;
    const dateStr = dateTimestamp.toDate().toISOString().split("T")[0];

    // Get effective price for this date
    // Priority: weekend_price (if weekend) > price
    let nightPrice = priceData.price;

    // Check if it's a weekend and weekend_price is set
    if (priceData.weekend_price != null) {
      const dayOfWeek = dateTimestamp.toDate().getDay();
      // Default weekend: Friday (5) and Saturday (6)
      const isWeekend = dayOfWeek === 5 || dayOfWeek === 6;
      if (isWeekend) {
        nightPrice = priceData.weekend_price;
      }
    }

    // Validate price is a positive number
    if (typeof nightPrice !== "number" || nightPrice < 0 || !Number.isFinite(nightPrice)) {
      logError("[PriceValidation] Invalid price in daily_prices", null, {
        unitId,
        date: dateStr,
        price: nightPrice,
      });

      throw new HttpsError(
        "internal",
        `Invalid pricing configuration for ${dateStr}. Please contact property owner.`
      );
    }

    totalPrice += nightPrice;
    breakdown.push({date: dateStr, price: nightPrice});
  }

  // Validate: Must have price for EVERY night
  if (breakdown.length !== expectedNights) {
    logError("[PriceValidation] Missing prices for some dates", null, {
      unitId,
      expectedNights,
      foundNights: breakdown.length,
      checkIn: checkInDate.toDate().toISOString(),
      checkOut: checkOutDate.toDate().toISOString(),
    });

    throw new HttpsError(
      "failed-precondition",
      `Pricing not configured for all dates. Expected ${expectedNights} nights, found ${breakdown.length}. ` +
      `Please contact property owner or select different dates.`
    );
  }

  // Round to 2 decimal places to avoid floating point issues
  totalPrice = Math.round(totalPrice * 100) / 100;

  logInfo("[PriceValidation] Price calculated successfully", {
    unitId,
    nights: expectedNights,
    totalPrice,
  });

  return {
    totalPrice,
    nights: expectedNights,
    breakdown,
  };
}

/**
 * Validate client-provided price matches server calculation
 *
 * SECURITY: Prevents price manipulation attacks.
 * Call this BEFORE creating any booking.
 *
 * @param unitId - The unit ID
 * @param checkInDate - Check-in date (Firestore Timestamp)
 * @param checkOutDate - Check-out date (Firestore Timestamp)
 * @param clientTotalPrice - Price provided by client
 * @param transaction - Optional Firestore transaction for atomic validation
 * @throws HttpsError if price mismatch detected
 */
export async function validateBookingPrice(
  unitId: string,
  checkInDate: admin.firestore.Timestamp,
  checkOutDate: admin.firestore.Timestamp,
  clientTotalPrice: number,
  transaction?: admin.firestore.Transaction
): Promise<void> {
  // Validate clientTotalPrice is a valid number
  if (
    typeof clientTotalPrice !== "number" ||
    !Number.isFinite(clientTotalPrice) ||
    clientTotalPrice < 0
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid total price provided"
    );
  }

  // Calculate server-side price
  const {totalPrice: serverTotalPrice} = await calculateBookingPrice(
    unitId,
    checkInDate,
    checkOutDate,
    transaction
  );

  // Allow small tolerance for floating point rounding (max €0.01)
  const tolerance = 0.01;
  const difference = Math.abs(serverTotalPrice - clientTotalPrice);

  if (difference > tolerance) {
    logError("[PriceValidation] Price mismatch detected - possible manipulation", null, {
      unitId,
      serverPrice: serverTotalPrice,
      clientPrice: clientTotalPrice,
      difference,
    });

    throw new HttpsError(
      "invalid-argument",
      `Price mismatch. Expected €${serverTotalPrice.toFixed(2)}, received €${clientTotalPrice.toFixed(2)}. ` +
      `Please refresh the page to see current pricing.`
    );
  }

  logInfo("[PriceValidation] Price validated successfully", {
    unitId,
    price: serverTotalPrice,
  });
}
