import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin, db } from "./firebase";
import { logInfo, logError, logSuccess } from "./logger";
import {
  generateBookingAccessToken,
  calculateTokenExpiration,
} from "./bookingAccessToken";
import {
  sendBookingConfirmationEmail,
  sendPendingBookingRequestEmail,
  sendOwnerNotificationEmail,
  sendPendingBookingOwnerNotification,
} from "./emailService";
import {sendEmailIfAllowed} from "./emailNotificationHelper";
import {validateEmail} from "./utils/emailValidation";
import {
  sanitizeText,
  sanitizeEmail,
  sanitizePhone,
} from "./utils/inputSanitization";
import {
  validateAndConvertBookingDates,
  calculateBookingNights,
  calculateDaysInAdvance,
} from "./utils/dateValidation";
import {
  calculateDepositAmount,
  calculateRemainingAmount,
} from "./utils/depositCalculation";
import {generateBookingReference} from "./utils/bookingReferenceGenerator";
import {sendEmailWithRetry} from "./utils/emailRetry";
import {enforceRateLimit, checkRateLimit} from "./utils/rateLimit";
import {logRateLimitExceeded} from "./utils/securityMonitoring";
import {validateBookingPrice, calculateBookingPrice} from "./utils/priceValidation";
import {setUser} from "./sentry";
// NOTIFICATION PREFERENCES: Owner can now opt-out of emails in Notification Settings
// Pending bookings FORCE send (critical - requires owner approval)
// Instant bookings RESPECT preferences (owner can opt-out)

// CONSTANTS
const MAX_BOOKING_NIGHTS = 365; // 1 year maximum (DoS protection)

/**
 * Cloud Function: Create Booking with Atomic Availability Check
 *
 * This function uses Firestore transaction to check availability
 * and create booking, preventing race conditions.
 *
 * CRITICAL: Prevents double bookings by ensuring only ONE booking
 * succeeds when multiple users try to book same dates simultaneously.
 */
export const createBookingAtomic = onCall(async (request) => {
  const userId = request.auth?.uid || null;
  const data = request.data;

  // Set user context for Sentry error tracking
  setUser(userId, data?.email || null);

  // Log incoming request data for debugging (before validation)
  logInfo("[AtomicBooking] Received request", {
    hasData: !!data,
    dataKeys: data ? Object.keys(data) : [],
    userId: userId || "anonymous",
  });

  // ========================================================================
  // SECURITY FIX: Rate limiting to prevent spam/DoS attacks
  // Different limits for authenticated vs unauthenticated (widget) users
  // ========================================================================
  if (userId) {
    // Authenticated users (owner dashboard bookings) - higher limits
    await enforceRateLimit(userId, "create_booking_authenticated", {
      maxCalls: 30,
      windowMs: 60000, // 30 bookings per minute
      errorMessage: "Too many booking attempts. Please wait a moment and try again.",
    });
  } else {
    // Unauthenticated widget bookings - use in-memory IP-based limiting
    // Note: Cloud Functions v2 provides IP via request.rawRequest
    const clientIp = (request as any).rawRequest?.ip ||
      (request as any).rawRequest?.headers?.["x-forwarded-for"]?.split(",")[0]?.trim() ||
      "unknown";

    // In-memory check first (fast, per-instance)
    if (!checkRateLimit(`widget_booking:${clientIp}`, 5, 300)) {
      // Log security event (fire-and-forget)
      const ipHash = Buffer.from(clientIp).toString("base64").substring(0, 16);
      logRateLimitExceeded(ipHash, "widget_booking").catch(() => {});

      throw new HttpsError(
        "resource-exhausted",
        "Too many booking attempts from your location. Please wait 5 minutes before trying again."
      );
    }

    // Firestore-backed check for persistence across instances
    // Use IP hash for privacy (don't store raw IPs)
    const ipHash = Buffer.from(clientIp).toString("base64").substring(0, 16);
    await enforceRateLimit(`ip_${ipHash}`, "widget_booking", {
      maxCalls: 10,
      windowMs: 600000, // 10 bookings per 10 minutes per IP
      errorMessage: "Too many booking attempts. Please wait a few minutes before trying again.",
    });
  }

  const {
    unitId,
    propertyId,
    ownerId: clientOwnerId, // SECURITY SF-001: Renamed - will be validated against property
    checkIn,
    checkOut,
    guestName,
    guestEmail,
    guestPhone,
    guestCount,
    totalPrice,
    servicesTotal = 0, // Additional services total for price validation
    paymentOption, // 'deposit', 'full', or 'none'
    paymentMethod, // 'stripe', 'bank_transfer', or 'none'
    requireOwnerApproval = false,
    notes,
    taxLegalAccepted,
    idempotencyKey, // Optional: prevents double bookings on double-click
  } = data;

  // Validate required fields with detailed error logging
  // Check for null, undefined, or empty string
  // NOTE: ownerId is NOT validated here - it will be fetched from property document (SF-001)
  const missingFields: string[] = [];
  if (!unitId || (typeof unitId === 'string' && unitId.trim() === '')) missingFields.push('unitId');
  if (!propertyId || (typeof propertyId === 'string' && propertyId.trim() === '')) missingFields.push('propertyId');
  // SECURITY SF-001: ownerId validation removed - we fetch it from property document
  if (!checkIn || (typeof checkIn === 'string' && checkIn.trim() === '')) missingFields.push('checkIn');
  if (!checkOut || (typeof checkOut === 'string' && checkOut.trim() === '')) missingFields.push('checkOut');
  if (!guestName || (typeof guestName === 'string' && guestName.trim() === '')) missingFields.push('guestName');
  if (!guestEmail || (typeof guestEmail === 'string' && guestEmail.trim() === '')) missingFields.push('guestEmail');
  if (totalPrice === null || totalPrice === undefined || (typeof totalPrice === 'string' && totalPrice.trim() === '')) missingFields.push('totalPrice');
  if (guestCount === null || guestCount === undefined || (typeof guestCount === 'string' && guestCount.trim() === '')) missingFields.push('guestCount');
  if (!paymentMethod || (typeof paymentMethod === 'string' && paymentMethod.trim() === '')) missingFields.push('paymentMethod');

  if (missingFields.length > 0) {
    logError("Missing required booking fields", null, {
      missingFields,
      receivedData: {
        unitId: !!unitId,
        propertyId: !!propertyId,
        clientOwnerId: !!clientOwnerId, // SF-001: Renamed for clarity
        checkIn: !!checkIn,
        checkOut: !!checkOut,
        guestName: !!guestName,
        guestEmail: !!guestEmail,
        totalPrice: totalPrice,
        totalPriceType: typeof totalPrice,
        guestCount: guestCount,
        guestCountType: typeof guestCount,
        paymentMethod: paymentMethod,
        paymentMethodType: typeof paymentMethod,
        paymentOption: paymentOption,
        paymentOptionType: typeof paymentOption,
      },
    });
    // SECURITY: Return generic message to client, details are in logs
    throw new HttpsError(
      "invalid-argument",
      "Invalid booking data. Please check all fields and try again."
    );
  }

  // ========================================================================
  // SECURITY FIX SF-001: Validate ownerId from property document
  // Don't trust client-provided ownerId - fetch from Firestore
  // This prevents malicious users from setting arbitrary owner_id values
  // ========================================================================
  const propertyDocForOwner = await db.collection("properties").doc(propertyId).get();

  if (!propertyDocForOwner.exists) {
    logError("[AtomicBooking] SECURITY SF-001: Property not found", null, {
      propertyId,
      clientOwnerId: clientOwnerId ? String(clientOwnerId).substring(0, 8) + "..." : "none",
    });
    throw new HttpsError("not-found", "Property not found. Please try again.");
  }

  const propertyDataForOwner = propertyDocForOwner.data();
  const ownerId = propertyDataForOwner?.owner_id as string | undefined;

  if (!ownerId) {
    logError("[AtomicBooking] SECURITY SF-001: Property has no owner_id", null, {
      propertyId,
    });
    throw new HttpsError(
      "failed-precondition",
      "Property configuration error. Please contact support."
    );
  }

  // Log if client sent different ownerId (potential attack attempt or stale data)
  if (clientOwnerId && clientOwnerId !== ownerId) {
    logInfo("[AtomicBooking] SECURITY SF-001: Client ownerId mismatch - using validated owner", {
      clientOwnerId: String(clientOwnerId).substring(0, 8) + "...",
      validatedOwnerId: ownerId.substring(0, 8) + "...",
      propertyId,
    });
  }

  // ========================================================================
  // SECURITY FIX: Type confusion prevention
  // Ensures numeric fields are actual numbers, not strings like "100" or "NaN"
  // ========================================================================
  const numericTotalPrice = Number(totalPrice);
  const numericGuestCount = Number(guestCount);

  if (!Number.isFinite(numericTotalPrice) || numericTotalPrice < 0) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid total price. Must be a positive number."
    );
  }

  if (!Number.isInteger(numericGuestCount) || numericGuestCount < 1 || numericGuestCount > 50) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid guest count. Must be between 1 and 50."
    );
  }

  // ========================================================================
  // SECURITY FIX: Idempotency protection
  // Prevents double bookings when user double-clicks or network retries
  // ========================================================================
  if (idempotencyKey && typeof idempotencyKey === "string" && idempotencyKey.length >= 16) {
    const idempotencyRef = db.collection("idempotency_keys").doc(idempotencyKey);
    const idempotencyDoc = await idempotencyRef.get();

    if (idempotencyDoc.exists) {
      const existingData = idempotencyDoc.data();
      // If booking was already created with this key, return the existing booking ID
      if (existingData?.bookingId) {
        logInfo("[AtomicBooking] Idempotency key already used, returning existing booking", {
          idempotencyKey: idempotencyKey.substring(0, 8) + "...",
          existingBookingId: existingData.bookingId,
        });
        return {
          success: true,
          bookingId: existingData.bookingId,
          idempotent: true, // Flag that this was a duplicate request
        };
      }
    }
  }

  // Validate paymentMethod is one of the allowed values
  // NOTE: "pay_on_arrival" is the client-side value, "none" is legacy - both mean pay on arrival
  const allowedPaymentMethods = ["stripe", "bank_transfer", "none", "pay_on_arrival"];

  // DEBUG: Log payment method validation
  logInfo("[AtomicBooking] Validating payment method", {
    paymentMethod,
    paymentMethodType: typeof paymentMethod,
    allowedMethods: allowedPaymentMethods,
    isAllowed: allowedPaymentMethods.includes(paymentMethod),
  });

  if (!allowedPaymentMethods.includes(paymentMethod)) {
    logError("[AtomicBooking] Invalid payment method rejected", null, {
      paymentMethod,
      paymentMethodType: typeof paymentMethod,
      paymentMethodValue: JSON.stringify(paymentMethod),
    });
    throw new HttpsError(
      "invalid-argument",
      `Invalid payment method: "${paymentMethod}". Must be one of: ${allowedPaymentMethods.join(", ")}`
    );
  }

  // ========================================================================
  // SECURITY: Sanitize all user inputs before processing
  // ========================================================================
  const sanitizedGuestName = sanitizeText(guestName);
  const sanitizedGuestEmail = sanitizeEmail(guestEmail);
  const sanitizedGuestPhone = guestPhone ? sanitizePhone(guestPhone) : null;
  const sanitizedNotes = notes ? sanitizeText(notes) : null;

  // Validate sanitized email with RFC-compliance
  if (!sanitizedGuestEmail || !validateEmail(sanitizedGuestEmail)) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid email address. Please provide a valid email with a proper domain (e.g., example@domain.com)."
    );
  }

  // Ensure sanitization didn't remove critical data
  if (!sanitizedGuestName || sanitizedGuestName.length < 2) {
    throw new HttpsError(
      "invalid-argument",
      "Guest name is required and must be at least 2 characters after sanitization."
    );
  }

  // SECURITY FIX: Validate phone number after sanitization
  // If sanitization removed all valid digits, set to null
  const finalGuestPhone =
    sanitizedGuestPhone && sanitizedGuestPhone.length >= 7 ?
      sanitizedGuestPhone :
      null;

  try {
    // SECURITY FIX: Removed guestEmail from log (PII reduction)
    logInfo("[AtomicBooking] Starting atomic booking creation", {
      unitId,
      checkIn,
      checkOut,
    });

    // ========================================================================
    // STEP 0.5: VALIDATE AND CONVERT DATES (with comprehensive validation)
    // ========================================================================
    const {checkInDate, checkOutDate} = validateAndConvertBookingDates(
      checkIn,
      checkOut
    );

    // ========================================================================
    // STEP 1: Fetch and validate widget settings
    // ========================================================================
    const widgetSettingsDoc = await db
      .collection("properties")
      .doc(propertyId)
      .collection("widget_settings")
      .doc(unitId)
      .get();

    if (!widgetSettingsDoc.exists) {
      throw new HttpsError(
        "not-found",
        "Widget settings not found. Please contact property owner."
      );
    }

    const widgetSettings = widgetSettingsDoc.data();
    const stripeConfig = widgetSettings?.stripe_config;
    const bankTransferConfig = widgetSettings?.bank_transfer_config;
    const allowPayOnArrival =
      widgetSettings?.allow_pay_on_arrival ?? false;
    const icalExportEnabled =
      widgetSettings?.ical_export_enabled ?? false;

    // Validate payment method is enabled in settings
    const isStripeDisabled =
      paymentMethod === "stripe" && (!stripeConfig || !stripeConfig.enabled);
    const isBankTransferDisabled = paymentMethod === "bank_transfer" &&
      (!bankTransferConfig || !bankTransferConfig.enabled);
    const isPayOnArrivalDisabled =
      (paymentMethod === "none" || paymentMethod === "pay_on_arrival") && !allowPayOnArrival;

    if (isStripeDisabled) {
      throw new HttpsError(
        "permission-denied",
        "Stripe payment not enabled. Select another payment method."
      );
    }

    if (isBankTransferDisabled) {
      throw new HttpsError(
        "permission-denied",
        "Bank transfer not enabled. Select another payment method."
      );
    }

    if (isPayOnArrivalDisabled) {
      throw new HttpsError(
        "permission-denied",
        "Pay on arrival not enabled. Select another payment method."
      );
    }

    logInfo("[AtomicBooking] Widget settings validated", {
      paymentMethod,
      stripeEnabled: stripeConfig?.enabled ?? false,
      bankTransferEnabled: bankTransferConfig?.enabled ?? false,
      allowPayOnArrival,
    });

    // ========================================================================
    // STEP 2: GENERATE UNIQUE BOOKING ID AND REFERENCE
    // ========================================================================
    // NEW STRUCTURE: Generate Firestore document ID in new subcollection path
    const bookingId = db
      .collection("properties")
      .doc(propertyId)
      .collection("units")
      .doc(unitId)
      .collection("bookings")
      .doc().id;

    // Generate booking reference using document ID (no collision possible)
    const bookingRef = generateBookingReference(bookingId);

    // ========================================================================
    // STEP 3: CALCULATE DEPOSIT AMOUNT (using integer arithmetic)
    // ========================================================================
    let depositAmount = 0.0;
    let depositPercentage = 20; // Default fallback

    if (paymentOption !== "none") {
      // Get deposit percentage from appropriate config
      if (paymentMethod === "stripe") {
        depositPercentage = stripeConfig?.deposit_percentage ?? 20;
      } else if (paymentMethod === "bank_transfer") {
        depositPercentage = bankTransferConfig?.deposit_percentage ?? 20;
      }

      // Calculate deposit
      if (paymentOption === "deposit") {
        // Percentage-based deposit (uses integer arithmetic to avoid floating point errors)
        depositAmount = calculateDepositAmount(totalPrice, depositPercentage);
      } else {
        // Full payment
        depositAmount = totalPrice;
      }
    }

    logInfo("[AtomicBooking] Deposit calculated", {
      paymentOption,
      depositPercentage,
      depositAmount,
      totalPrice,
    });

    // ========================================================================
    // STRIPE PAYMENT: Skip price validation - stripePayment.ts will handle it
    // ========================================================================
    // CRITICAL FIX: Price validation moved to stripePayment.ts to allow
    // server-calculated price to be used if client's locked price doesn't match.
    //
    // NEW FLOW:
    // - atomicBooking.ts: Returns booking data with client's price (no validation)
    // - stripePayment.ts: Validates price and uses server-calculated price if mismatch
    // - This ensures dates are blocked BEFORE Stripe redirect (no race condition)
    // ========================================================================
    if (paymentMethod === "stripe") {
      // SECURITY FIX: Removed guestEmail from log (PII reduction)
      logInfo("[AtomicBooking] Stripe payment - skipping validation, passing to stripePayment.ts", {
        unitId,
        checkIn,
        checkOut,
      });

      // Return booking data without validation
      // stripePayment.ts will do atomic validation when creating placeholder
      return {
        success: true,
        isStripeValidation: true,
        bookingData: {
          unitId,
          propertyId,
          ownerId,
          checkIn,
          checkOut,
          guestName: sanitizedGuestName,
          guestEmail: sanitizedGuestEmail,
          guestPhone: finalGuestPhone,
          guestCount: numericGuestCount, // Use validated numeric value
          totalPrice: numericTotalPrice, // Use validated numeric value (includes services)
          servicesTotal, // Additional services total for price validation in stripePayment.ts
          depositAmount,
          paymentOption,
          notes: sanitizedNotes,
          taxLegalAccepted: taxLegalAccepted || null,
          icalExportEnabled,
        },
        message: "Proceed to Stripe payment.",
      };
    }

    // ========================================================================
    // NON-STRIPE PAYMENT: Validate price BEFORE creating booking
    // ========================================================================
    // SECURITY: For non-Stripe payments, validate price here since booking
    // is created immediately. For Stripe, validation happens in stripePayment.ts.
    //
    // GRACEFUL HANDLING: If price mismatch (client locked price differs from
    // server-calculated current price), use server-calculated price instead
    // of blocking the booking. This matches Stripe flow behavior.
    // ========================================================================
    let finalTotalPrice = numericTotalPrice;
    let finalDepositAmount = depositAmount;

    // Validate servicesTotal is a valid number
    const numericServicesTotal = (
      typeof servicesTotal === "number" &&
      Number.isFinite(servicesTotal) &&
      servicesTotal >= 0
    ) ? servicesTotal : 0;

    try {
      await validateBookingPrice(
        unitId,
        checkInDate,
        checkOutDate,
        numericTotalPrice, // Use validated numeric price (includes services)
        propertyId, // Pass propertyId for fallback to unit base price
        numericServicesTotal // Pass services total for accurate validation
      );

      logInfo("[AtomicBooking] Price validated against server calculation", {
        unitId,
        totalPrice: numericTotalPrice,
      });
    } catch (priceError: any) {
      // If price mismatch, use server-calculated price instead of client's locked price
      if (priceError.code === "invalid-argument" && priceError.message?.includes("Price mismatch")) {
        logInfo("[AtomicBooking] Price mismatch - using server-calculated price", {
          unitId,
          clientPrice: numericTotalPrice,
          error: priceError.message,
        });

        // Calculate server-side nightly price and add services total
        const {totalPrice: serverNightlyPrice} = await calculateBookingPrice(
          unitId,
          checkInDate,
          checkOutDate,
          propertyId
        );

        // Server total = nightly prices + services (services from client are trusted)
        const serverTotalPrice = Math.round((serverNightlyPrice + numericServicesTotal) * 100) / 100;

        logInfo("[AtomicBooking] Using server-calculated price for booking", {
          unitId,
          oldPrice: numericTotalPrice,
          serverNightlyPrice,
          servicesTotal: numericServicesTotal,
          newPrice: serverTotalPrice,
        });

        // Update prices to use server-calculated total price
        finalTotalPrice = serverTotalPrice;

        // Recalculate deposit based on new price
        if (paymentOption === "deposit") {
          finalDepositAmount = calculateDepositAmount(serverTotalPrice, depositPercentage);
        } else if (paymentOption === "full") {
          finalDepositAmount = serverTotalPrice;
        }
        // paymentOption === "none" keeps depositAmount as 0
      } else {
        // Other validation errors - rethrow
        throw priceError;
      }
    }

    // Determine booking status for NON-STRIPE payments
    // pending = awaiting owner approval (BLOCKS calendar dates)
    // confirmed = auto-confirmed (only for Stripe payments via webhook)
    //
    // BUSINESS LOGIC: bank_transfer and pay_on_arrival ALWAYS require owner approval
    // because there's no automatic payment verification. Owner confirmation = payment received.
    // Only Stripe can auto-confirm because webhook provides payment verification.
    let status: string;
    let paymentStatus: string;

    // Force owner approval for non-instant payment methods
    // This ensures owner must manually confirm when payment is received
    const forceApprovalForPaymentMethod =
      paymentMethod === "bank_transfer" || paymentMethod === "pay_on_arrival";

    if (requireOwnerApproval || forceApprovalForPaymentMethod) {
      // Requires manual owner approval
      // pending status BLOCKS calendar dates until owner approves or rejects
      status = "pending";
      paymentStatus = (paymentMethod === "none" || paymentMethod === "pay_on_arrival") ? "not_required" : "pending";
    } else {
      // Auto-confirmed (no approval needed, non-Stripe payment)
      // Note: This branch is now only for paymentMethod === "none" with requireOwnerApproval === false
      status = "confirmed";
      paymentStatus = "not_required";
    }

    // ====================================================================
    // STEP 4: GENERATE ACCESS TOKEN (BEFORE transaction to avoid waste)
    // ====================================================================
    // Generate token OUTSIDE transaction so we don't waste generated tokens
    // if the transaction fails or retries due to date conflicts.
    const {token: accessToken, hashedToken} = generateBookingAccessToken();
    const tokenExpiration = calculateTokenExpiration(checkOutDate);

    logInfo("[AtomicBooking] Access token generated", {
      tokenLength: accessToken.length,
      tokenExpiration: tokenExpiration.toDate().toISOString(),
    });

    // ====================================================================
    // CRITICAL: Use Firestore transaction for atomic availability
    // ====================================================================
    const result = await db.runTransaction(async (transaction) => {
      // Step 1: Query conflicting bookings INSIDE transaction
      // Bug #77 Fix: Changed "check_out" >= to > to allow same-day turnover
      // (checkout = 15 should allow new checkin = 15, no conflict)
      //
      // NOTE: pending bookings BLOCK calendar dates (awaiting owner approval or payment)
      // This includes both regular pending bookings and Stripe checkout placeholders
      //
      // NEW STRUCTURE: Use direct subcollection path (faster than collection group)
      const conflictingBookingsQuery = db
        .collection("properties")
        .doc(propertyId)
        .collection("units")
        .doc(unitId)
        .collection("bookings")
        .where("status", "in", ["pending", "confirmed"])
        .where("check_in", "<", checkOutDate)
        .where("check_out", ">", checkInDate);

      const conflictingBookings =
        await transaction.get(conflictingBookingsQuery);

      // Step 2: Check for conflicts
      if (!conflictingBookings.empty) {
        logError("[AtomicBooking] Date conflict detected", null, {
          unitId,
          requestedCheckIn: checkIn,
          requestedCheckOut: checkOut,
          conflictingBookings: conflictingBookings.docs.map((doc) => ({
            id: doc.id,
            checkIn: doc.data().check_in,
            checkOut: doc.data().check_out,
            status: doc.data().status,
          })),
        });

        throw new HttpsError(
          "already-exists",
          "Dates no longer available. Select different dates."
        );
      }

      // ====================================================================
      // STEP 2.5: Validate daily_prices restrictions
      // (available, blockCheckIn, blockCheckOut, min/maxNightsOnArrival,
      //  min/maxDaysAdvance - SECURITY FIX 2025-11-27)
      // ====================================================================

      // Calculate booking nights for min/max validation (using helper functions)
      const bookingNights = calculateBookingNights(checkInDate, checkOutDate);

      // SECURITY FIX: Validate booking duration (already validated in dateValidation helper)
      // But add max nights validation here for DoS protection
      if (bookingNights > MAX_BOOKING_NIGHTS) {
        throw new HttpsError(
          "invalid-argument",
          `Maximum booking duration is ${MAX_BOOKING_NIGHTS} nights (1 year). ` +
            `You requested ${bookingNights} nights. For longer stays, please contact the property owner directly.`
        );
      }

      // Calculate days in advance for min/max advance booking validation
      const daysInAdvance = calculateDaysInAdvance(checkInDate);

      // Query daily_prices for all dates in the booking range
      // (check-in date to check-out date - 1, as check-out is exclusive)
      // NEW STRUCTURE: Use subcollection path (faster than collection group)
      const dailyPricesQuery = db
        .collection("properties")
        .doc(propertyId)
        .collection("units")
        .doc(unitId)
        .collection("daily_prices")
        .where("date", ">=", checkInDate)
        .where("date", "<", checkOutDate);

      const dailyPricesSnapshot = await transaction.get(dailyPricesQuery);

      // Validate each date in the booking range
      for (const doc of dailyPricesSnapshot.docs) {
        const priceData = doc.data();
        const dateTimestamp = priceData.date as admin.firestore.Timestamp;
        const dateStr = dateTimestamp.toDate().toISOString().split("T")[0];

        // Check 1: Is this date marked as unavailable?
        if (priceData.available === false) {
          logError("[AtomicBooking] Date unavailable (blocked by owner)", null, {
            unitId,
            blockedDate: dateStr,
          });

          throw new HttpsError(
            "failed-precondition",
            `Date ${dateStr} is not available for booking.`
          );
        }

        // Check 2: Is check-in blocked on the check-in date?
        const isCheckInDate =
          dateTimestamp.toMillis() === checkInDate.toMillis();
        if (isCheckInDate && priceData.block_checkin === true) {
          logError("[AtomicBooking] Check-in blocked on this date", null, {
            unitId,
            checkInDate: dateStr,
          });

          throw new HttpsError(
            "failed-precondition",
            `Check-in is not allowed on ${dateStr}.`
          );
        }

        // Check 3: minNightsOnArrival on check-in date
        if (
          isCheckInDate &&
          priceData.min_nights_on_arrival != null &&
          priceData.min_nights_on_arrival > 0
        ) {
          if (bookingNights < priceData.min_nights_on_arrival) {
            logError(
              "[AtomicBooking] Minimum nights requirement not met",
              null,
              {
                unitId,
                checkInDate: dateStr,
                minNightsRequired: priceData.min_nights_on_arrival,
                bookingNights,
              }
            );

            throw new HttpsError(
              "failed-precondition",
              `Minimum ${priceData.min_nights_on_arrival} nights required for ` +
                `check-in on ${dateStr}. You selected ${bookingNights} nights.`
            );
          }
        }

        // Check 4: maxNightsOnArrival on check-in date
        if (
          isCheckInDate &&
          priceData.max_nights_on_arrival != null &&
          priceData.max_nights_on_arrival > 0
        ) {
          if (bookingNights > priceData.max_nights_on_arrival) {
            logError(
              "[AtomicBooking] Maximum nights requirement exceeded",
              null,
              {
                unitId,
                checkInDate: dateStr,
                maxNightsAllowed: priceData.max_nights_on_arrival,
                bookingNights,
              }
            );

            throw new HttpsError(
              "failed-precondition",
              `Maximum ${priceData.max_nights_on_arrival} nights allowed for ` +
                `check-in on ${dateStr}. You selected ${bookingNights} nights.`
            );
          }
        }

        // Check 5: minDaysAdvance on check-in date (SECURITY FIX)
        if (
          isCheckInDate &&
          priceData.min_days_advance != null &&
          priceData.min_days_advance > 0
        ) {
          if (daysInAdvance < priceData.min_days_advance) {
            logError(
              "[AtomicBooking] Minimum days in advance requirement not met",
              null,
              {
                unitId,
                checkInDate: dateStr,
                minDaysAdvanceRequired: priceData.min_days_advance,
                daysInAdvance,
              }
            );

            throw new HttpsError(
              "failed-precondition",
              `Must book at least ${priceData.min_days_advance} days in advance ` +
                `for check-in on ${dateStr}. You are booking ${daysInAdvance} days ahead.`
            );
          }
        }

        // Check 6: maxDaysAdvance on check-in date (SECURITY FIX)
        if (
          isCheckInDate &&
          priceData.max_days_advance != null &&
          priceData.max_days_advance > 0
        ) {
          if (daysInAdvance > priceData.max_days_advance) {
            logError(
              "[AtomicBooking] Maximum days in advance requirement exceeded",
              null,
              {
                unitId,
                checkInDate: dateStr,
                maxDaysAdvanceAllowed: priceData.max_days_advance,
                daysInAdvance,
              }
            );

            throw new HttpsError(
              "failed-precondition",
              `Can only book up to ${priceData.max_days_advance} days in advance ` +
                `for check-in on ${dateStr}. You are booking ${daysInAdvance} days ahead.`
            );
          }
        }
      }

      // Check 7: Is check-out blocked on the check-out date?
      // (Check-out date is not in the range query above, need separate check)
      // NEW STRUCTURE: Use subcollection path with date as document ID
      const checkOutDateStr = `${checkOutDate.toDate().getUTCFullYear()}-${String(checkOutDate.toDate().getUTCMonth() + 1).padStart(2, "0")}-${String(checkOutDate.toDate().getUTCDate()).padStart(2, "0")}`;
      const checkOutPriceDocRef = db
        .collection("properties")
        .doc(propertyId)
        .collection("units")
        .doc(unitId)
        .collection("daily_prices")
        .doc(checkOutDateStr);

      const checkOutPriceSnapshot = await transaction.get(checkOutPriceDocRef);

      if (checkOutPriceSnapshot.exists) {
        const checkOutData = checkOutPriceSnapshot.data();
        if (checkOutData?.block_checkout === true) {
          logError("[AtomicBooking] Check-out blocked on this date", null, {
            unitId,
            checkOutDate: checkOutDateStr,
          });

          throw new HttpsError(
            "failed-precondition",
            `Check-out is not allowed on ${checkOutDateStr}.`
          );
        }
      }

      logInfo("[AtomicBooking] Daily price restrictions validated", {
        unitId,
        datesChecked: dailyPricesSnapshot.docs.length,
        bookingNights,
      });

      // ====================================================================
      // STEP 2.6: Validate unit's base minStayNights (if not overridden by daily_prices)
      // NOTE: Units are stored as subcollection: properties/{propertyId}/units/{unitId}
      // ====================================================================
      const unitDocRef = db
        .collection("properties")
        .doc(propertyId)
        .collection("units")
        .doc(unitId);
      const unitSnapshot = await transaction.get(unitDocRef);

      // Store unit data for email usage (avoid duplicate fetch after transaction)
      let unitDataFromTransaction: any = null;

      if (unitSnapshot.exists) {
        const unitData = unitSnapshot.data();
        unitDataFromTransaction = unitData; // Save for email sending
        const unitMinStayNights = unitData?.min_stay_nights ?? 1;

        if (bookingNights < unitMinStayNights) {
          logError("[AtomicBooking] Unit minimum stay requirement not met", null, {
            unitId,
            minStayNights: unitMinStayNights,
            bookingNights,
          });

          throw new HttpsError(
            "failed-precondition",
            `Minimum ${unitMinStayNights} nights required. You selected ${bookingNights} nights.`
          );
        }

        logInfo("[AtomicBooking] Unit minStayNights validated", {
          unitId,
          unitMinStayNights,
          bookingNights,
        });

        // RACE CONDITION FIX: Validate guest count INSIDE transaction
        // This prevents owner from changing max_guests between validation and booking
        const maxGuestsInTransaction = unitData?.max_guests ?? 10;
        const guestCountNum = Number(guestCount);

        // FIX: Validate that guestCount is a valid positive integer (prevents NaN)
        if (!Number.isInteger(guestCountNum) || guestCountNum <= 0) {
          logError("[AtomicBooking] Invalid guest count - not a positive integer", null, {
            unitId,
            guestCount,
            guestCountNum,
          });

          throw new HttpsError(
            "invalid-argument",
            `Guest count must be a positive integer. Received: ${guestCount}`
          );
        }

        if (guestCountNum > maxGuestsInTransaction) {
          logError("[AtomicBooking] Guest count exceeds unit capacity", null, {
            unitId,
            maxGuests: maxGuestsInTransaction,
            requestedGuests: guestCountNum,
          });

          throw new HttpsError(
            "invalid-argument",
            `Maximum ${maxGuestsInTransaction} guests allowed for this unit. You requested ${guestCountNum}.`
          );
        }

        logInfo("[AtomicBooking] Guest count validated", {
          unitId,
          maxGuests: maxGuestsInTransaction,
          requestedGuests: guestCountNum,
        });
      }

      // Step 3: No conflict - create booking atomically
      // (Access token already generated outside transaction to avoid waste)
      const bookingData = {
        user_id: userId,
        unit_id: unitId,
        property_id: propertyId,
        owner_id: ownerId,
        guest_name: sanitizedGuestName,
        guest_email: sanitizedGuestEmail,
        guest_phone: finalGuestPhone,
        check_in: checkInDate,
        check_out: checkOutDate,
        guest_count: numericGuestCount, // Use validated numeric value
        total_price: finalTotalPrice, // Use server-validated price (may differ from client)
        advance_amount: finalDepositAmount,
        deposit_amount: finalDepositAmount, // For Stripe Cloud Function
        remaining_amount: calculateRemainingAmount(finalTotalPrice, finalDepositAmount),
        paid_amount: 0,
        payment_method: paymentMethod,
        payment_status: paymentStatus,
        status,
        booking_reference: bookingRef,
        source: "widget",
        notes: sanitizedNotes,
        require_owner_approval: requireOwnerApproval || forceApprovalForPaymentMethod,
        tax_legal_accepted: taxLegalAccepted || null,
        // SECURITY FIX: Use server timestamp for payment deadline (not client time)
        payment_deadline: paymentMethod === "bank_transfer" ?
          admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days from server time
          ) :
          null,
        // Booking lookup security
        access_token: hashedToken,
        token_expires_at: tokenExpiration,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };

      // NEW STRUCTURE: Write to subcollection path
      const bookingDocRef = db
        .collection("properties")
        .doc(propertyId)
        .collection("units")
        .doc(unitId)
        .collection("bookings")
        .doc(bookingId);
      transaction.set(bookingDocRef, bookingData);

      // SECURITY FIX: Removed guestEmail from log (PII reduction)
      logSuccess("[AtomicBooking] Booking created atomically", {
        bookingId,
        bookingRef,
        unitId,
      });

      // MEMORY OPTIMIZATION: Return only essential data (not full booking object)
      // Client already has all booking details from request params
      return {
        bookingId,
        bookingReference: bookingRef,
        depositAmount: finalDepositAmount,
        totalPrice: finalTotalPrice, // Return server-calculated price for UI update
        status,
        paymentStatus,
        accessToken, // Plaintext token for email
        icalExportEnabled,
        // Pass only unit name (not entire unit object)
        unitName: unitDataFromTransaction?.name || "Unit",
      };
    });

    // Transaction successful - booking created
    logSuccess("[AtomicBooking] Transaction completed successfully", result);

    // SECURITY FIX: Store idempotency key AFTER successful booking
    // This prevents duplicate bookings on retry but allows new attempts if first fails
    if (idempotencyKey && typeof idempotencyKey === "string" && idempotencyKey.length >= 16) {
      try {
        await db.collection("idempotency_keys").doc(idempotencyKey).set({
          bookingId: result.bookingId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          // TTL: Auto-delete after 24 hours (idempotency window)
          expiresAt: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 24 * 60 * 60 * 1000)
          ),
        });
      } catch (idempotencyError) {
        // Non-critical: If idempotency storage fails, booking still succeeded
        logError("[AtomicBooking] Failed to store idempotency key (non-critical)", idempotencyError, {
          idempotencyKey: idempotencyKey.substring(0, 8) + "...",
          bookingId: result.bookingId,
        });
      }
    }

    // Send emails for ALL payment methods (not just bank_transfer)
    try {
      // Fetch property data for email (unitData already from transaction)
      const propertyDoc =
        await db.collection("properties").doc(propertyId).get();

      // RELIABILITY FIX: Handle missing property data
      if (!propertyDoc.exists) {
        logError(
          "[AtomicBooking] Property not found when sending emails - using fallback name",
          null,
          {
            propertyId,
            bookingId: result.bookingId,
          }
        );
      }

      const propertyData = propertyDoc.data();

      // MEMORY OPTIMIZATION: Use unit name from transaction (not entire unit object)
      const unitName = result.unitName;

      if (requireOwnerApproval) {
        // Manual approval flow - send "Booking Request Received" email to guest
        // For bank transfer: include bank details so guest knows where to pay

        // Fetch bank details for bank transfer payments
        let bankDetails: {
          bankName?: string;
          accountHolder?: string;
          iban?: string;
          swift?: string;
        } | undefined;

        if (paymentMethod === "bank_transfer" && bankTransferConfig) {
          // Try to get bank details from owner's company details first
          const ownerProfileDoc = await db
            .collection("users")
            .doc(ownerId)
            .collection("profile")
            .doc("company_details")
            .get();

          if (ownerProfileDoc.exists) {
            const companyDetails = ownerProfileDoc.data();
            if (companyDetails?.bankAccountIban) {
              bankDetails = {
                bankName: companyDetails.bankName,
                accountHolder: companyDetails.accountHolder,
                iban: companyDetails.bankAccountIban,
                swift: companyDetails.swift,
              };
            }
          }

          // Fallback to legacy bank details in widget settings
          if (!bankDetails?.iban && bankTransferConfig) {
            bankDetails = {
              bankName: bankTransferConfig.bank_name,
              accountHolder: bankTransferConfig.account_holder,
              iban: bankTransferConfig.iban,
              swift: bankTransferConfig.swift,
            };
          }
        }

        // Use retry mechanism for transient failures
        await sendEmailWithRetry(
          async () => {
            await sendPendingBookingRequestEmail(
              sanitizedGuestEmail,
              sanitizedGuestName,
              result.bookingReference,
              propertyData?.name || "Property",
              paymentMethod,
              result.depositAmount,
              bankDetails
            );
          },
          "Pending Booking Request",
          sanitizedGuestEmail
        );

        logSuccess(
          "[AtomicBooking] Pending booking request email sent to guest",
          {
            email: sanitizedGuestEmail,
          }
        );

        // Send "New Booking Needs Approval" email to owner
        const ownerDoc = await db.collection("users").doc(ownerId).get();
        const ownerData = ownerDoc.data();
        if (ownerData?.email) {
          // CRITICAL: Pending bookings FORCE send (owner must approve)
          await sendEmailIfAllowed(
            ownerId,
            "bookings",
            async () => {
              // Use retry mechanism for transient failures
              await sendEmailWithRetry(
                async () => {
                  await sendPendingBookingOwnerNotification(
                    ownerData.email,
                    result.bookingReference,
                    sanitizedGuestName,
                    propertyData?.name || "Property"
                  );
                },
                "Pending Booking Owner Notification",
                ownerData.email
              );
            },
            true // forceIfCritical: owner MUST be notified to approve booking
          );

          logSuccess(
            "[AtomicBooking] Pending booking owner notification sent",
            {
              email: ownerData.email,
            }
          );
        }
      } else {
        // Auto-confirmed flow - send "Booking Confirmed" email to guest
        // Use retry mechanism for transient failures
        await sendEmailWithRetry(
          async () => {
            await sendBookingConfirmationEmail(
              sanitizedGuestEmail,
              sanitizedGuestName,
              result.bookingReference,
              checkInDate.toDate(),
              checkOutDate.toDate(),
              result.totalPrice, // Use server-validated price
              result.depositAmount, // Use server-validated deposit
              unitName,
              propertyData?.name || "Property",
              result.accessToken, // Plaintext token for email link
              propertyData?.contact_email,
              propertyId // For subdomain in email links
            );
          },
          "Booking Confirmation",
          sanitizedGuestEmail
        );

        logSuccess(
          "[AtomicBooking] Booking confirmation email sent to guest",
          {
            email: sanitizedGuestEmail,
          }
        );

        // Send "New Booking Received" email to owner
        logInfo("[AtomicBooking] Attempting to send owner notification", {
          ownerId,
        });

        const ownerDoc = await db.collection("users").doc(ownerId).get();
        const ownerData = ownerDoc.data();

        if (!ownerDoc.exists) {
          logError("[AtomicBooking] Owner document not found", { ownerId });
        } else if (!ownerData?.email) {
          logError("[AtomicBooking] Owner email not found in document", {
            ownerId,
            ownerData: ownerData ? Object.keys(ownerData) : "null",
          });
        } else {
          // CRITICAL: Owner MUST receive email for every booking
          // Until push notifications are implemented, email is the only way
          // owner knows about new bookings. Missing this = missed revenue.
          // Bug Archive #2: Owner email ALWAYS sent (forceIfCritical=true)
          logInfo("[AtomicBooking] Sending owner notification (critical - always sent)", {
            ownerId,
            email: ownerData.email,
          });

          await sendEmailIfAllowed(
            ownerId,
            "bookings",
            async () => {
              // Use retry mechanism for transient failures
              await sendEmailWithRetry(
                async () => {
                  await sendOwnerNotificationEmail(
                    ownerData.email,
                    result.bookingReference,
                    sanitizedGuestName,
                    sanitizedGuestEmail,
                    finalGuestPhone || undefined,
                    propertyData?.name || "Property",
                    unitName,
                    checkInDate.toDate(),
                    checkOutDate.toDate(),
                    Number(guestCount), // Use validated numeric value
                    result.totalPrice, // Use server-validated price
                    result.depositAmount // Use server-validated deposit
                  );
                },
                "Owner Notification",
                ownerData.email
              );
            },
            true // CRITICAL: Always send - owner must know about every booking
          );

          logSuccess(
            "[AtomicBooking] Owner notification email sent (critical notification)",
            {
              email: ownerData.email,
            }
          );
        }
      }
    } catch (emailError) {
      // Log error but don't fail the booking
      logError(
        "[AtomicBooking] Failed to send email (guest or owner)",
        emailError
      );
    }

    return {
      success: true,
      ...result,
      message: paymentMethod === "bank_transfer" ?
        "Booking created. Awaiting bank transfer payment." :
        (paymentMethod === "none" || paymentMethod === "pay_on_arrival") ?
          "Booking confirmed. Payment will be collected on arrival." :
          requireOwnerApproval ?
            "Booking request submitted. Awaiting owner approval." :
            "Booking created. Please complete payment.",
    };
  } catch (error: any) {
    // ERROR HANDLING FIX: Properly handle different HttpsError codes
    // Don't convert all errors to "internal" - preserve specific error codes

    // Check if it's already an HttpsError with a specific code
    if (error instanceof HttpsError || error.code) {
      // Known error codes that should be passed through to client:
      // - already-exists: Dates not available
      // - invalid-argument: Guest count, booking duration, etc.
      // - failed-precondition: Daily prices restrictions
      // - not-found: Unit/property not found
      // - permission-denied: Payment method disabled
      const allowedErrorCodes = [
        "already-exists",
        "invalid-argument",
        "failed-precondition",
        "not-found",
        "permission-denied",
      ];

      if (allowedErrorCodes.includes(error.code)) {
        logInfo(`[AtomicBooking] Booking validation failed: ${error.code}`, {
          unitId,
          checkIn,
          checkOut,
          errorCode: error.code,
          errorMessage: error.message,
        });
        throw error; // Re-throw with original code
      }
    }

    // Unknown/unexpected error - log and convert to internal error
    logError("[AtomicBooking] Unexpected error creating booking", error, {
      unitId,
      guestEmail: sanitizedGuestEmail,
      errorType: error?.constructor?.name,
    });

    throw new HttpsError(
      "internal",
      error.message || "Failed to create booking. Please try again."
    );
  }
});
