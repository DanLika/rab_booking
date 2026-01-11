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
import {logInfo, logWarn, logError} from "../logger";
import {logPriceMismatch} from "./securityMonitoring";

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
 * FALLBACK: If daily_prices don't exist for some dates, falls back to
 * unit's base price (price_per_night / weekend_base_price), matching
 * the client-side calculation in price_calculator_provider.dart.
 *
 * @param unitId - The unit ID to calculate price for
 * @param checkInDate - Check-in date (Firestore Timestamp)
 * @param checkOutDate - Check-out date (Firestore Timestamp)
 * @param propertyId - The property ID (REQUIRED for subcollection path)
 * @param transaction - Optional Firestore transaction for atomic reads
 * @return Price calculation result with total and breakdown
 * @throws HttpsError if pricing not configured or invalid
 */
export async function calculateBookingPrice(
  unitId: string,
  checkInDate: admin.firestore.Timestamp,
  checkOutDate: admin.firestore.Timestamp,
  propertyId: string,
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
  // NEW STRUCTURE: Use subcollection path
  const dailyPricesQuery = db
    .collection("properties")
    .doc(propertyId)
    .collection("units")
    .doc(unitId)
    .collection("daily_prices")
    .where("date", ">=", checkInDate)
    .where("date", "<", checkOutDate)
    .orderBy("date", "asc");

  // Execute query (inside or outside transaction)
  const snapshot = transaction ?
    await transaction.get(dailyPricesQuery) :
    await dailyPricesQuery.get();

  // Create a map of existing daily prices (date string -> price data)
  const dailyPricesMap = new Map<string, admin.firestore.DocumentData>();
  for (const doc of snapshot.docs) {
    const priceData = doc.data();
    const dateTimestamp = priceData.date as admin.firestore.Timestamp;
    const dateStr = dateTimestamp.toDate().toISOString().split("T")[0];
    dailyPricesMap.set(dateStr, priceData);
  }

  // Fetch unit data for fallback pricing (if we don't have all daily_prices)
  let fallbackPrice = 100.0; // Default fallback
  let weekendBasePrice: number | null = null;
  let weekendDays: number[] = [5, 6]; // Default: Friday (5), Saturday (6) - JS uses 0=Sun

  if (dailyPricesMap.size < expectedNights) {
    // Need fallback - fetch unit data
    const unitRef = db
      .collection("properties")
      .doc(propertyId)
      .collection("units")
      .doc(unitId);

    const unitDoc = transaction ?
      await transaction.get(unitRef) :
      await unitRef.get();

    if (unitDoc.exists) {
      const unitData = unitDoc.data();
      fallbackPrice = unitData?.price_per_night ?? 100.0;
      weekendBasePrice = unitData?.weekend_base_price ?? null;
      // Convert weekend_days from [6, 7] (Mon=1 format) to JS format [5, 6] (Sun=0 format)
      if (unitData?.weekend_days && Array.isArray(unitData.weekend_days)) {
        weekendDays = unitData.weekend_days.map((d: number) => {
          // Convert from Mon=1,Sun=7 to Sun=0,Mon=1 format
          return d === 7 ? 0 : d;
        });
      }

      logInfo("[PriceValidation] Using unit base price as fallback", {
        unitId,
        fallbackPrice,
        weekendBasePrice,
        weekendDays,
      });
    }
  }

  // Build price breakdown for ALL nights (using daily_prices or fallback)
  const breakdown: Array<{date: string; price: number}> = [];
  let totalPrice = 0;

  // Iterate through each night in the booking range
  const currentDate = new Date(checkInDate.toDate());
  currentDate.setUTCHours(0, 0, 0, 0);

  for (let i = 0; i < expectedNights; i++) {
    const dateStr = currentDate.toISOString().split("T")[0];
    const dayOfWeek = currentDate.getDay(); // 0=Sun, 1=Mon, ..., 6=Sat

    let nightPrice: number;

    // Check if we have a daily_price for this date
    const dailyPriceData = dailyPricesMap.get(dateStr);

    if (dailyPriceData) {
      // Use daily_price
      nightPrice = dailyPriceData.price;

      // Check if it's a weekend and weekend_price is set in daily_prices
      if (dailyPriceData.weekend_price != null) {
        const isWeekendDay = weekendDays.includes(dayOfWeek);
        if (isWeekendDay) {
          nightPrice = dailyPriceData.weekend_price;
        }
      }
    } else {
      // FALLBACK: Use unit's base price
      const isWeekendDay = weekendDays.includes(dayOfWeek);
      if (isWeekendDay && weekendBasePrice != null) {
        nightPrice = weekendBasePrice;
      } else {
        nightPrice = fallbackPrice;
      }

      logInfo("[PriceValidation] Using fallback price for date", {
        unitId,
        date: dateStr,
        fallbackPrice: nightPrice,
        isWeekend: isWeekendDay,
      });
    }

    // Validate price is a positive number
    if (typeof nightPrice !== "number" || nightPrice < 0 || !Number.isFinite(nightPrice)) {
      logError("[PriceValidation] Invalid price calculated", null, {
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

    // Move to next day
    currentDate.setDate(currentDate.getDate() + 1);
  }

  // Round to 2 decimal places to avoid floating point issues
  totalPrice = Math.round(totalPrice * 100) / 100;

  logInfo("[PriceValidation] Price calculated successfully", {
    unitId,
    nights: expectedNights,
    totalPrice,
    usedFallback: dailyPricesMap.size < expectedNights,
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
 * The validation formula is:
 *   serverNightlyPrice + servicesTotal ≈ clientTotalPrice (within tolerance)
 *
 * This accounts for additional services (cleaning, pets, etc.) that are
 * calculated on the client and passed separately for validation.
 *
 * @param unitId - The unit ID
 * @param checkInDate - Check-in date (Firestore Timestamp)
 * @param checkOutDate - Check-out date (Firestore Timestamp)
 * @param clientTotalPrice - Total price provided by client (nightly + services)
 * @param propertyId - The property ID (REQUIRED for subcollection path)
 * @param servicesTotal - Additional services total from client (default 0)
 * @param transaction - Optional Firestore transaction for atomic validation
 * @throws HttpsError if price mismatch detected
 */
export async function validateBookingPrice(
  unitId: string,
  checkInDate: admin.firestore.Timestamp,
  checkOutDate: admin.firestore.Timestamp,
  clientTotalPrice: number,
  propertyId: string,
  servicesTotal = 0,
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

  // Validate servicesTotal is a valid number (default 0 if not provided)
  const validatedServicesTotal = (
    typeof servicesTotal === "number" &&
    Number.isFinite(servicesTotal) &&
    servicesTotal >= 0
  ) ? servicesTotal : 0;

  // Calculate server-side nightly price (with fallback support)
  const {totalPrice: serverNightlyPrice} = await calculateBookingPrice(
    unitId,
    checkInDate,
    checkOutDate,
    propertyId,
    transaction
  );

  // Server expected total = nightly prices + additional services
  const serverExpectedTotal = Math.round((serverNightlyPrice + validatedServicesTotal) * 100) / 100;

  // Allow small tolerance for floating point rounding (max €0.01)
  const tolerance = 0.01;
  const difference = Math.abs(serverExpectedTotal - clientTotalPrice);

  if (difference > tolerance) {
    // Calculate percentage difference for smart alerting
    const percentageDifference = (difference / serverExpectedTotal) * 100;

    // SMART THRESHOLD: Only send Sentry alert for SUSPICIOUS mismatches
    // - Absolute difference > €10 (prevents small price changes from spamming)
    // - OR percentage difference > 5% (catches relative manipulation)
    // This avoids false positives from:
    // - Cached prices (€2-5 difference is normal)
    // - Floating-point rounding (< €0.10 is benign)
    // - Price updates while user was on page
    const isSuspicious = difference > 10 || percentageDifference > 5;

    logWarn("[PriceValidation] Price mismatch detected", {
      unitId,
      serverNightlyPrice,
      servicesTotal: validatedServicesTotal,
      serverExpectedTotal,
      clientPrice: clientTotalPrice,
      difference,
      percentageDifference: percentageDifference.toFixed(2),
      isSuspicious,
    });

    // Log security event to Firestore + Sentry (fire-and-forget)
    // IMPORTANT: Only send to Sentry if truly suspicious (prevents false positive spam)
    if (isSuspicious) {
      logPriceMismatch(unitId, clientTotalPrice, serverExpectedTotal, {
        propertyId,
        checkIn: checkInDate.toDate().toISOString(),
        checkOut: checkOutDate.toDate().toISOString(),
        serverNightlyPrice,
        servicesTotal: validatedServicesTotal,
        percentageDifference: percentageDifference.toFixed(2),
      }).catch(() => {});
    } else {
      // Small mismatch - log to Cloud Logs only (no Sentry spam)
      logInfo("[PriceValidation] Small price mismatch (cached/floating-point) - using server price", {
        unitId,
        difference,
        percentageDifference: percentageDifference.toFixed(2),
      });
    }

    throw new HttpsError(
      "invalid-argument",
      `Price mismatch. Expected €${serverExpectedTotal.toFixed(2)}, received €${clientTotalPrice.toFixed(2)}. ` +
      "Please refresh the page to see current pricing."
    );
  }

  logInfo("[PriceValidation] Price validated successfully", {
    unitId,
    nightlyPrice: serverNightlyPrice,
    servicesTotal: validatedServicesTotal,
    totalPrice: serverExpectedTotal,
  });
}
