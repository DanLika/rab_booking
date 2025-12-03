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
// BUG #2 FIX: Removed shouldSendEmailNotification import
// Owner email is now ALWAYS sent for new bookings (user requirement B1: 1)

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

  const {
    unitId,
    propertyId,
    ownerId,
    checkIn,
    checkOut,
    guestName,
    guestEmail,
    guestPhone,
    guestCount,
    totalPrice,
    paymentOption, // 'deposit', 'full', or 'none'
    paymentMethod, // 'stripe', 'bank_transfer', or 'none'
    requireOwnerApproval = false,
    notes,
    taxLegalAccepted,
  } = data;

  // Validate required fields
  if (!unitId || !propertyId || !ownerId || !checkIn || !checkOut ||
    !guestName || !guestEmail || !totalPrice) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required booking fields"
    );
  }

  try {
    logInfo("[AtomicBooking] Starting atomic booking creation", {
      unitId,
      checkIn,
      checkOut,
      guestEmail,
    });

    const checkInDate = admin.firestore.Timestamp.fromDate(new Date(checkIn));
    const checkOutDate = admin.firestore.Timestamp.fromDate(new Date(checkOut));

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

    // ========================================================================
    // STEP 1.5: Validate guest count against unit's max_guests
    // NOTE: Units are stored as subcollection: properties/{propertyId}/units/{unitId}
    // ========================================================================
    const unitDoc = await db
      .collection("properties")
      .doc(propertyId)
      .collection("units")
      .doc(unitId)
      .get();
    if (!unitDoc.exists) {
      throw new HttpsError("not-found", "Unit not found");
    }
    const unitData = unitDoc.data();
    const maxGuests = unitData?.max_guests ?? 10; // Default max 10 if not set

    // Validate guest count is a valid positive integer
    const guestCountNum = Number(guestCount);
    if (!guestCount || !Number.isInteger(guestCountNum) || guestCountNum < 1) {
      throw new HttpsError(
        "invalid-argument",
        "Guest count must be at least 1"
      );
    }

    if (guestCountNum > maxGuests) {
      throw new HttpsError(
        "invalid-argument",
        `Maximum ${maxGuests} guests allowed for this unit. You requested ${guestCountNum}.`
      );
    }

    // Validate payment method is enabled in settings
    const isStripeDisabled =
      paymentMethod === "stripe" && (!stripeConfig || !stripeConfig.enabled);
    const isBankTransferDisabled = paymentMethod === "bank_transfer" &&
      (!bankTransferConfig || !bankTransferConfig.enabled);
    const isPayOnArrivalDisabled =
      paymentMethod === "none" && !allowPayOnArrival;

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

    // Generate unique booking ID and reference
    const bookingId = db.collection("bookings").doc().id;
    const bookingRef = `BK-${Date.now()}-${Math.floor(Math.random() * 10000)}`;

    // Calculate deposit amount using settings
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
        // Percentage-based deposit
        const calculated = totalPrice * (depositPercentage / 100);
        depositAmount = parseFloat(calculated.toFixed(2));
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
    // STRIPE PAYMENT: Do NOT create booking here!
    // For Stripe payments, we only validate availability and return success.
    // The actual booking will be created by the webhook after payment confirms.
    // This prevents "ghost bookings" that block calendar but were never paid.
    // ========================================================================
    if (paymentMethod === "stripe") {
      // For Stripe, we need to validate availability within transaction
      // but NOT create the booking yet
      await db.runTransaction(async (transaction) => {
        // Query conflicting bookings
        const conflictingBookingsQuery = db
          .collection("bookings")
          .where("unit_id", "==", unitId)
          .where("status", "in", ["pending", "confirmed"])
          .where("check_in", "<", checkOutDate)
          .where("check_out", ">", checkInDate);

        const conflictingBookings =
          await transaction.get(conflictingBookingsQuery);

        if (!conflictingBookings.empty) {
          throw new HttpsError(
            "already-exists",
            "Dates no longer available. Select different dates."
          );
        }

        // Validate daily_prices restrictions (same as below)
        const bookingNights = Math.ceil(
          (checkOutDate.toDate().getTime() - checkInDate.toDate().getTime()) /
            (1000 * 60 * 60 * 24)
        );

        const dailyPricesQuery = db
          .collection("daily_prices")
          .where("unit_id", "==", unitId)
          .where("date", ">=", checkInDate)
          .where("date", "<", checkOutDate);

        const dailyPricesSnapshot = await transaction.get(dailyPricesQuery);

        for (const doc of dailyPricesSnapshot.docs) {
          const priceData = doc.data();
          const dateTimestamp = priceData.date as admin.firestore.Timestamp;
          const dateStr = dateTimestamp.toDate().toISOString().split("T")[0];

          if (priceData.available === false) {
            throw new HttpsError(
              "failed-precondition",
              `Date ${dateStr} is not available for booking.`
            );
          }

          const isCheckInDate =
            dateTimestamp.toMillis() === checkInDate.toMillis();
          if (isCheckInDate && priceData.block_checkin === true) {
            throw new HttpsError(
              "failed-precondition",
              `Check-in is not allowed on ${dateStr}.`
            );
          }

          if (
            isCheckInDate &&
            priceData.min_nights_on_arrival != null &&
            priceData.min_nights_on_arrival > 0 &&
            bookingNights < priceData.min_nights_on_arrival
          ) {
            throw new HttpsError(
              "failed-precondition",
              `Minimum ${priceData.min_nights_on_arrival} nights required.`
            );
          }
        }

        // Validate unit's base minStayNights
        // NOTE: Units are stored as subcollection: properties/{propertyId}/units/{unitId}
        const unitDocRef = db
          .collection("properties")
          .doc(propertyId)
          .collection("units")
          .doc(unitId);
        const unitSnapshot = await transaction.get(unitDocRef);

        if (unitSnapshot.exists) {
          const unitData = unitSnapshot.data();
          const unitMinStayNights = unitData?.min_stay_nights ?? 1;

          if (bookingNights < unitMinStayNights) {
            throw new HttpsError(
              "failed-precondition",
              `Minimum ${unitMinStayNights} nights required.`
            );
          }
        }

        return { valid: true, bookingNights };
      });

      logSuccess("[AtomicBooking] Stripe validation passed - no booking created yet", {
        unitId,
        checkIn,
        checkOut,
        guestEmail,
      });

      // Return validation success with all data needed for Stripe checkout
      // The actual booking will be created by handleStripeWebhook after payment
      return {
        success: true,
        isStripeValidation: true, // Flag to indicate this is just validation
        bookingData: {
          unitId,
          propertyId,
          ownerId,
          checkIn,
          checkOut,
          guestName,
          guestEmail,
          guestPhone: guestPhone || null,
          guestCount,
          totalPrice,
          depositAmount,
          paymentOption,
          notes: notes || null,
          taxLegalAccepted: taxLegalAccepted || null,
          icalExportEnabled,
        },
        message: "Dates available. Proceed to Stripe payment.",
      };
    }

    // Determine booking status for NON-STRIPE payments
    // pending = awaiting owner approval (BLOCKS calendar dates)
    // confirmed = auto-confirmed (no approval needed)
    let status: string;
    let paymentStatus: string;

    if (requireOwnerApproval) {
      // Requires manual owner approval
      // pending status BLOCKS calendar dates until owner approves or rejects
      status = "pending";
      paymentStatus = paymentMethod === "none" ? "not_required" : "pending";
    } else {
      // Auto-confirmed (no approval needed, non-Stripe payment)
      status = "confirmed";

      if (paymentMethod === "bank_transfer") {
        paymentStatus = "pending"; // Awaiting bank transfer
      } else {
        paymentStatus = "not_required"; // Pay on arrival or no payment
      }
    }

    // ====================================================================
    // CRITICAL: Use Firestore transaction for atomic availability
    // ====================================================================
    const result = await db.runTransaction(async (transaction) => {
      // Step 1: Query conflicting bookings INSIDE transaction
      // Bug #77 Fix: Changed "check_out" >= to > to allow same-day turnover
      // (checkout = 15 should allow new checkin = 15, no conflict)
      //
      // NOTE: pending bookings BLOCK calendar dates (awaiting owner approval)
      // Only pending and confirmed statuses block - cancelled does not.
      const conflictingBookingsQuery = db
        .collection("bookings")
        .where("unit_id", "==", unitId)
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

      // Calculate booking nights for min/max validation
      const bookingNights = Math.ceil(
        (checkOutDate.toDate().getTime() - checkInDate.toDate().getTime()) /
          (1000 * 60 * 60 * 24)
      );

      // Calculate days in advance for min/max advance booking validation
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const checkInDateObj = checkInDate.toDate();
      checkInDateObj.setHours(0, 0, 0, 0);
      const daysInAdvance = Math.floor(
        (checkInDateObj.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)
      );

      // Query daily_prices for all dates in the booking range
      // (check-in date to check-out date - 1, as check-out is exclusive)
      const dailyPricesQuery = db
        .collection("daily_prices")
        .where("unit_id", "==", unitId)
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
      const checkOutPriceQuery = db
        .collection("daily_prices")
        .where("unit_id", "==", unitId)
        .where("date", "==", checkOutDate);

      const checkOutPriceSnapshot = await transaction.get(checkOutPriceQuery);

      if (!checkOutPriceSnapshot.empty) {
        const checkOutData = checkOutPriceSnapshot.docs[0].data();
        if (checkOutData.block_checkout === true) {
          const dateStr = checkOutDate.toDate().toISOString().split("T")[0];
          logError("[AtomicBooking] Check-out blocked on this date", null, {
            unitId,
            checkOutDate: dateStr,
          });

          throw new HttpsError(
            "failed-precondition",
            `Check-out is not allowed on ${dateStr}.`
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

      if (unitSnapshot.exists) {
        const unitData = unitSnapshot.data();
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
      }

      // Step 3: No conflict - create booking atomically
      // Generate secure access token for booking lookup
      const { token: accessToken, hashedToken } = generateBookingAccessToken();
      const tokenExpiration = calculateTokenExpiration(checkOutDate);

      const bookingData = {
        user_id: userId,
        unit_id: unitId,
        property_id: propertyId,
        owner_id: ownerId,
        guest_name: guestName,
        guest_email: guestEmail,
        guest_phone: guestPhone || null,
        check_in: checkInDate,
        check_out: checkOutDate,
        guest_count: guestCount,
        total_price: totalPrice,
        advance_amount: depositAmount,
        deposit_amount: depositAmount, // For Stripe Cloud Function
        remaining_amount: totalPrice - depositAmount,
        paid_amount: 0,
        payment_method: paymentMethod,
        payment_status: paymentStatus,
        status,
        booking_reference: bookingRef,
        source: "widget",
        notes: notes || null,
        require_owner_approval: requireOwnerApproval,
        tax_legal_accepted: taxLegalAccepted || null,
        payment_deadline: paymentMethod === "bank_transfer" ?
          admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 3 * 24 * 60 * 60 * 1000) // 3 days
          ) :
          null,
        // Booking lookup security
        access_token: hashedToken,
        token_expires_at: tokenExpiration,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };

      const bookingDocRef = db.collection("bookings").doc(bookingId);
      transaction.set(bookingDocRef, bookingData);

      logSuccess("[AtomicBooking] Booking created atomically", {
        bookingId,
        bookingRef,
        unitId,
        guestEmail,
      });

      return {
        bookingId,
        bookingReference: bookingRef,
        depositAmount,
        status,
        paymentStatus,
        accessToken, // Include plaintext token for email
        icalExportEnabled, // For widget to show "Add to Calendar" button
        booking: bookingData, // Include full booking data for confirmation screen
      };
    });

    // Transaction successful - booking created
    logSuccess("[AtomicBooking] Transaction completed successfully", result);

    // Send emails for ALL payment methods (not just bank_transfer)
    try {
      // Fetch property and unit data for email
      // NOTE: Units are stored as subcollection: properties/{propertyId}/units/{unitId}
      const propertyDoc =
        await db.collection("properties").doc(propertyId).get();
      const unitDoc =
        await db
          .collection("properties")
          .doc(propertyId)
          .collection("units")
          .doc(unitId)
          .get();
      const propertyData = propertyDoc.data();
      const unitData = unitDoc.data();

      if (requireOwnerApproval) {
        // Manual approval flow - send "Booking Request Received" email to guest
        await sendPendingBookingRequestEmail(
          guestEmail,
          guestName,
          result.bookingReference,
          checkInDate.toDate(),
          checkOutDate.toDate(),
          totalPrice,
          unitData?.name || "Unit",
          propertyData?.name || "Property"
        );

        logSuccess("[AtomicBooking] Pending booking request email sent to guest", {
          email: guestEmail,
        });

        // Send "New Booking Needs Approval" email to owner
        const ownerDoc = await db.collection("users").doc(ownerId).get();
        const ownerData = ownerDoc.data();
        if (ownerData?.email) {
          await sendPendingBookingOwnerNotification(
            ownerData.email,
            ownerData.displayName || "Owner",
            guestName,
            guestEmail,
            guestPhone || "",
            result.bookingReference,
            checkInDate.toDate(),
            checkOutDate.toDate(),
            totalPrice,
            unitData?.name || "Unit",
            guestCount,
            notes
          );

          logSuccess("[AtomicBooking] Pending booking owner notification sent", {
            email: ownerData.email,
          });
        }
      } else {
        // Auto-confirmed flow - send "Booking Confirmed" email to guest
        await sendBookingConfirmationEmail(
          guestEmail,
          guestName,
          result.bookingReference,
          checkInDate.toDate(),
          checkOutDate.toDate(),
          totalPrice,
          depositAmount,
          unitData?.name || "Unit",
          propertyData?.name || "Property",
          result.accessToken, // Plaintext token for email link
          propertyData?.contact_email,
          propertyId // For subdomain in email links
        );

        logSuccess("[AtomicBooking] Booking confirmation email sent to guest", {
          email: guestEmail,
        });

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
          // BUG #2 FIX: Owner email is ALWAYS sent for new bookings
          // Removed conditional check - owner must always know about new reservations
          // User requirement (B1: 1): "DA - uvijek, bez obzira na settings"
          logInfo("[AtomicBooking] Sending owner notification to", {
            email: ownerData.email,
          });

          await sendOwnerNotificationEmail(
            ownerData.email,
            ownerData.displayName || ownerData.first_name || "Owner",
            guestName,
            guestEmail,
            result.bookingReference,
            checkInDate.toDate(),
            checkOutDate.toDate(),
            totalPrice,
            depositAmount,
            unitData?.name || "Unit",
            guestPhone || undefined, // Pass guest phone to owner
            guestCount, // Pass guest count to owner
            notes || undefined // Pass notes to owner
          );

          logSuccess("[AtomicBooking] Owner notification email sent", {
            email: ownerData.email,
          });
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
        requireOwnerApproval ?
          "Booking request submitted. Awaiting owner approval." :
          "Booking created. Please complete payment.",
    };
  } catch (error: any) {
    // Check if it's our "already-exists" error
    if (error.code === "already-exists") {
      logInfo("[AtomicBooking] Booking rejected - dates unavailable", {
        unitId,
        checkIn,
        checkOut,
      });
      throw error; // Re-throw to client
    }

    logError("[AtomicBooking] Unexpected error creating booking", error, {
      unitId,
      guestEmail,
    });

    throw new HttpsError(
      "internal",
      error.message || "Failed to create booking. Please try again."
    );
  }
});
