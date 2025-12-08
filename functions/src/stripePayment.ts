import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import Stripe from "stripe";
import { defineSecret } from "firebase-functions/params";
import {
  sendBookingApprovedEmail,
  sendOwnerNotificationEmail,
} from "./emailService";
import { sendEmailIfAllowed } from "./emailNotificationHelper";
import { admin, db } from "./firebase";
import { getStripeClient, stripeSecretKey } from "./stripe";
import { createPaymentNotification } from "./notificationService";
import {
  generateBookingAccessToken,
  calculateTokenExpiration,
} from "./bookingAccessToken";
import { generateBookingReference } from "./utils/bookingReferenceGenerator";
import {
  validateAndConvertBookingDates,
  calculateBookingNights,
} from "./utils/dateValidation";
import { sanitizeText, sanitizeEmail, sanitizePhone } from "./utils/inputSanitization";
import { logInfo, logError, logWarn } from "./logger";

// Define webhook secret
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

// Allowed domains for return URL (security whitelist)
const ALLOWED_RETURN_DOMAINS = [
  "https://bookbed.io",
  "https://app.bookbed.io",
  "https://rab-booking-248fc.web.app",  // Legacy fallback
  "https://bookbed.io", // Legacy fallback
  "http://localhost",
  "http://127.0.0.1",
];

/**
 * Cloud Function: Create Stripe Checkout Session
 *
 * NEW FLOW (2025-12-02):
 * - Booking is NOT created before Stripe checkout
 * - All booking data is passed in session metadata
 * - Booking is created by webhook AFTER successful payment
 * - This prevents "ghost bookings" that block dates but were never paid
 *
 * Security: Validates return URL against whitelist
 */
export const createStripeCheckoutSession = onCall({ secrets: [stripeSecretKey] }, async (request) => {
  const {
    // Booking data (from atomicBooking validation result)
    bookingData,
    returnUrl,
  } = request.data;

  // Debug logging
  logInfo("createStripeCheckoutSession called", {
    hasBookingData: !!bookingData,
    returnUrl: returnUrl ? "provided" : "not provided",
    hasAuth: !!request.auth,
  });

  if (!bookingData) {
    throw new HttpsError("invalid-argument", "Booking data is required");
  }

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
    depositAmount,
    paymentOption,
    notes,
    taxLegalAccepted,
  } = bookingData;

  // Validate required fields
  if (!unitId || !propertyId || !ownerId || !checkIn || !checkOut ||
    !guestName || !guestEmail || !totalPrice) {
    throw new HttpsError("invalid-argument", "Missing required booking fields");
  }

  // SECURITY: Validate return URL against whitelist
  if (returnUrl) {
    const isAllowedDomain = ALLOWED_RETURN_DOMAINS.some((domain) =>
      returnUrl.startsWith(domain)
    );
    if (!isAllowedDomain) {
      logError(`Invalid return URL attempted: ${returnUrl}`);
      throw new HttpsError("invalid-argument", "Invalid return URL");
    }
  }

  try {
    // Fetch unit and property details
    // NOTE: Units are stored as subcollection: properties/{propertyId}/units/{unitId}
    const propertyDoc = await db.collection("properties").doc(propertyId).get();
    const propertyData = propertyDoc.data();
    const unitDoc = await db
      .collection("properties")
      .doc(propertyId)
      .collection("units")
      .doc(unitId)
      .get();
    const unitData = unitDoc.data();

    // Get owner's Stripe Connect account ID
    const ownerDoc = await db.collection("users").doc(ownerId).get();
    const ownerStripeAccountId = ownerDoc.data()?.stripe_account_id;

    if (!ownerStripeAccountId) {
      throw new HttpsError(
        "failed-precondition",
        "Owner has not connected their Stripe account. Please contact the property owner."
      );
    }

    const depositAmountInCents = Math.round(depositAmount * 100);

    // ========================================================================
    // CRITICAL SECURITY FIX: Create placeholder booking BEFORE Stripe redirect
    // ========================================================================
    // This prevents race condition where 2 users can both pay for same dates.
    // Placeholder booking BLOCKS dates until payment completes or expires.
    //
    // FLOW:
    // 1. Transaction checks availability (fails if dates booked)
    // 2. Create placeholder booking with `stripe_pending` status (expires 15 min)
    // 3. Create Stripe session with placeholder booking ID in metadata
    // 4. Webhook updates placeholder to `confirmed` after successful payment
    // 5. Cleanup job deletes expired placeholders (if user abandons payment)

    // Sanitize inputs (security)
    const sanitizedGuestName = sanitizeText(guestName);
    const sanitizedGuestEmail = sanitizeEmail(guestEmail);
    const sanitizedGuestPhone = guestPhone ? sanitizePhone(guestPhone) : null;
    const sanitizedNotes = notes ? sanitizeText(notes) : null;

    if (!sanitizedGuestName || !sanitizedGuestEmail) {
      throw new HttpsError(
        "invalid-argument",
        "Invalid guest name or email after sanitization"
      );
    }

    // Validate and convert dates
    const { checkInDate, checkOutDate } = validateAndConvertBookingDates(
      checkIn,
      checkOut
    );

    // Calculate booking nights for validation
    const bookingNights = calculateBookingNights(checkInDate, checkOutDate);

    // SECURITY: Validate booking duration
    const MAX_BOOKING_NIGHTS = 365;
    if (bookingNights > MAX_BOOKING_NIGHTS) {
      throw new HttpsError(
        "invalid-argument",
        `Maximum booking duration is ${MAX_BOOKING_NIGHTS} nights`
      );
    }

    // ========================================================================
    // ATOMIC TRANSACTION: Create placeholder booking with availability check
    // ========================================================================
    const placeholderResult = await db.runTransaction(async (transaction) => {
      // Check for conflicting bookings (including stripe_pending placeholders)
      const conflictingBookingsQuery = db
        .collection("bookings")
        .where("unit_id", "==", unitId)
        .where("status", "in", ["pending", "confirmed", "stripe_pending"])
        .where("check_in", "<", checkOutDate)
        .where("check_out", ">", checkInDate);

      const conflictingBookings =
        await transaction.get(conflictingBookingsQuery);

      if (!conflictingBookings.empty) {
        throw new HttpsError(
          "already-exists",
          "Dates no longer available. Another booking is in progress or confirmed."
        );
      }

      // Create placeholder booking
      const placeholderBookingId = db.collection("bookings").doc().id;
      const bookingRef = generateBookingReference(placeholderBookingId);

      // Generate access token for future "View my reservation" link
      const { token: accessToken, hashedToken } =
        generateBookingAccessToken();
      const tokenExpiration = calculateTokenExpiration(checkOutDate);

      // Placeholder expires in 15 minutes (Stripe session expires in 24h, but we're stricter)
      const expiresAt = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 15 * 60 * 1000)
      );

      const placeholderData = {
        user_id: null, // Widget bookings are unauthenticated
        unit_id: unitId,
        property_id: propertyId,
        owner_id: ownerId,
        guest_name: sanitizedGuestName,
        guest_email: sanitizedGuestEmail,
        guest_phone: sanitizedGuestPhone,
        check_in: checkInDate,
        check_out: checkOutDate,
        guest_count: Number(guestCount),
        total_price: Number(totalPrice),
        advance_amount: Number(depositAmount),
        deposit_amount: Number(depositAmount),
        remaining_amount: Number(totalPrice) - Number(depositAmount),
        paid_amount: 0,
        payment_method: "stripe",
        payment_option: paymentOption,
        payment_status: "pending",
        status: "stripe_pending", // NEW STATUS: Blocks dates until payment
        booking_reference: bookingRef,
        source: "widget",
        notes: sanitizedNotes,
        require_owner_approval: false,
        tax_legal_accepted: taxLegalAccepted || false,
        // Booking lookup security
        access_token: hashedToken,
        token_expires_at: tokenExpiration,
        // Placeholder expiration
        stripe_pending_expires_at: expiresAt,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };

      transaction.set(
        db.collection("bookings").doc(placeholderBookingId),
        placeholderData
      );

      return {
        placeholderBookingId,
        bookingRef,
        accessToken,
      };
    });

    logInfo(
      `Placeholder booking created: ${placeholderResult.placeholderBookingId} (${placeholderResult.bookingRef})`
    );

    // Create Stripe checkout session with destination charge
    const stripeClient = getStripeClient();

    // Build success/cancel URLs properly
    // Widget sends returnUrl with query params (e.g., ?property=x&unit=y&payment=stripe#/calendar)
    // We need to append session_id as a query parameter BEFORE the hash fragment
    //
    // IMPORTANT: Flutter Web uses hash routing (#/calendar), so hash must be at the END
    let successUrl: string;
    let cancelUrl: string;

    if (returnUrl) {
      const hashIndex = returnUrl.indexOf("#");
      let baseUrl: string;
      let hashFragment: string;

      if (hashIndex !== -1) {
        baseUrl = returnUrl.substring(0, hashIndex);
        hashFragment = returnUrl.substring(hashIndex);
      } else {
        baseUrl = returnUrl;
        hashFragment = "";
      }

      const separator = baseUrl.includes("?") ? "&" : "?";
      successUrl = `${baseUrl}${separator}stripe_status=success&session_id={CHECKOUT_SESSION_ID}${hashFragment}`;
      cancelUrl = `${baseUrl}${separator}stripe_status=cancelled${hashFragment}`;
    } else {
      successUrl = "https://rab-booking-248fc.web.app/booking-success?session_id={CHECKOUT_SESSION_ID}";
      cancelUrl = "https://rab-booking-248fc.web.app/booking-cancelled";
    }

    // Use booking reference from placeholder booking (guaranteed unique)
    const bookingRef = placeholderResult.bookingRef;

    const session = await stripeClient.checkout.sessions.create({
      payment_method_types: ["card"],
      mode: "payment",
      // Stripe session expires in 24 hours (default, user approved)
      line_items: [
        {
          price_data: {
            currency: "eur",
            unit_amount: depositAmountInCents,
            product_data: {
              name: `Booking Deposit - ${bookingRef}`,
              description: `${propertyData?.name || "Property"} - ${unitData?.name || "Unit"}`,
              images: propertyData?.images?.[0] ?
                [propertyData.images[0]] :
                undefined,
            },
          },
          quantity: 1,
        },
      ],
      payment_intent_data: {
        on_behalf_of: ownerStripeAccountId,
        transfer_data: {
          destination: ownerStripeAccountId,
        },
      },
      success_url: successUrl,
      cancel_url: cancelUrl,
      // CRITICAL: Store placeholder booking ID for webhook to UPDATE (not create)
      metadata: {
        // Placeholder booking (webhook will update this to confirmed)
        placeholder_booking_id: placeholderResult.placeholderBookingId,
        // Access token for "View my reservation" email link (plaintext)
        access_token_plaintext: placeholderResult.accessToken,
        // Booking identifiers
        booking_reference: bookingRef,
        unit_id: unitId,
        property_id: propertyId,
        owner_id: ownerId,
        // Dates (ISO strings)
        check_in: checkIn,
        check_out: checkOut,
        // Guest info - SECURITY: Use sanitized values to prevent XSS/injection
        guest_name: sanitizedGuestName,
        guest_email: sanitizedGuestEmail,
        guest_phone: sanitizedGuestPhone || "",
        guest_count: String(guestCount),
        // Payment info
        total_price: String(totalPrice),
        deposit_amount: String(depositAmount),
        payment_option: paymentOption,
        // Optional fields - SECURITY: Use sanitized notes
        notes: sanitizedNotes || "",
        tax_legal_accepted: taxLegalAccepted ? "true" : "false",
      },
      customer_email: guestEmail,
    });

    logInfo(`Stripe checkout session created: ${session.id}`);
    logInfo(`Booking will be created by webhook after payment success`);

    return {
      success: true,
      sessionId: session.id,
      checkoutUrl: session.url,
      bookingReference: bookingRef, // Return for UI display
    };
  } catch (error: any) {
    logError("Error creating Stripe checkout session", error);
    throw new HttpsError(
      "internal",
      error.message || "Failed to create checkout session"
    );
  }
});

/**
 * Cloud Function: Handle Stripe Webhook
 *
 * NEW FLOW (2025-12-02):
 * - Creates booking AFTER successful Stripe payment
 * - Reads all booking data from session metadata
 * - Uses atomic transaction to prevent race conditions
 * - No more "ghost bookings" - only paid bookings exist
 */
export const handleStripeWebhook = onRequest({ secrets: [stripeSecretKey, stripeWebhookSecret] }, async (req, res) => {
  const sig = req.headers["stripe-signature"];

  if (!sig) {
    logError("Missing stripe-signature header");
    res.status(400).send("Missing signature");
    return;
  }

  const webhookSecret = stripeWebhookSecret.value();
  if (!webhookSecret) {
    logError("STRIPE_WEBHOOK_SECRET not configured");
    res.status(500).send("Webhook secret not configured");
    return;
  }

  let event: Stripe.Event;

  try {
    const stripeClient = getStripeClient();
    event = stripeClient.webhooks.constructEvent(
      req.rawBody,
      sig as string,
      webhookSecret
    );
  } catch (error: any) {
    logError("Webhook signature verification failed", error);
    res.status(400).send(`Webhook Error: ${error.message}`);
    return;
  }

  // Handle the event
  if (event.type === "checkout.session.completed") {
    const session = event.data.object as Stripe.Checkout.Session;
    const metadata = session.metadata;

    // Validate required metadata
    if (!metadata?.unit_id || !metadata?.property_id || !metadata?.owner_id) {
      logError("Missing required metadata in session", null, {
        has_unit_id: !!metadata?.unit_id,
        has_property_id: !!metadata?.property_id,
        has_owner_id: !!metadata?.owner_id,
        has_guest_email: !!metadata?.guest_email,
        has_guest_phone: !!metadata?.guest_phone,
      });
      res.status(400).send("Missing required booking metadata");
      return;
    }

    try {
      // ========================================================================
      // NEW FLOW: Update placeholder booking (not create new booking)
      // ========================================================================
      const placeholderBookingId = metadata.placeholder_booking_id;

      if (!placeholderBookingId) {
        logError("Missing placeholder_booking_id in webhook metadata");
        res.status(400).send("Missing placeholder booking ID - outdated checkout session");
        return;
      }

      logInfo(`Processing Stripe webhook for placeholder booking: ${placeholderBookingId}`);

      // Fetch placeholder booking
      const placeholderBookingRef = db.collection("bookings").doc(placeholderBookingId);
      const placeholderBookingSnap = await placeholderBookingRef.get();

      if (!placeholderBookingSnap.exists) {
        logError(`Placeholder booking not found: ${placeholderBookingId}`);
        res.status(404).send("Placeholder booking not found - may have expired");
        return;
      }

      const placeholderData = placeholderBookingSnap.data();

      // IDEMPOTENCY CHECK: Check if placeholder already updated (webhook fired twice)
      if (placeholderData?.status === "confirmed" && placeholderData?.stripe_session_id === session.id) {
        logInfo(`Webhook already processed - booking ${placeholderBookingId} already confirmed`);
        res.json({
          received: true,
          booking_id: placeholderBookingId,
          booking_reference: placeholderData.booking_reference,
          status: "already_processed",
          message: "Booking already confirmed for this session",
        });
        return;
      }

      // Validate placeholder is actually stripe_pending status
      if (placeholderData?.status !== "stripe_pending") {
        logError(`Placeholder booking has invalid status: ${placeholderData?.status}`);
        res.status(400).send(`Invalid placeholder status: ${placeholderData?.status}`);
        return;
      }

      logInfo(`Updating placeholder booking ${placeholderBookingId} to confirmed status`);

      // Update placeholder booking to confirmed
      await placeholderBookingRef.update({
        status: "confirmed", // Stripe payments are always confirmed (paid)
        payment_status: "paid",
        paid_amount: Number(placeholderData.deposit_amount),
        // Stripe payment details
        stripe_session_id: session.id,
        payment_intent_id: session.payment_intent as string,
        paid_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        // Remove placeholder expiration field (no longer needed)
        stripe_pending_expires_at: admin.firestore.FieldValue.delete(),
      });

      logInfo(`Placeholder booking ${placeholderBookingId} confirmed after Stripe payment`);

      // Extract plaintext access token from metadata (for email "View my reservation" link)
      const accessTokenPlaintext = metadata.access_token_plaintext;

      if (!accessTokenPlaintext) {
        logWarn("Missing access_token_plaintext in metadata - email link may not work");
      }

      // Prepare result for email sending (match old structure)
      const result = {
        bookingId: placeholderBookingId,
        bookingData: placeholderData,
        accessToken: accessTokenPlaintext || "", // Plaintext token for email link
      };

      // Extract booking details for emails
      const unitId = placeholderData.unit_id;
      const propertyId = placeholderData.property_id;
      const ownerId = placeholderData.owner_id;
      const guestName = placeholderData.guest_name;
      const guestEmail = placeholderData.guest_email;
      const guestPhone = placeholderData.guest_phone;
      const guestCount = placeholderData.guest_count;
      const bookingReference = placeholderData.booking_reference;
      const checkIn = placeholderData.check_in.toDate();
      const checkOut = placeholderData.check_out.toDate();
      const totalPrice = placeholderData.total_price;
      const depositAmount = placeholderData.deposit_amount;

      // Fetch unit and property details for emails
      // NOTE: Units are stored as subcollection: properties/{propertyId}/units/{unitId}
      const propertyDoc = await db.collection("properties").doc(propertyId).get();
      const propertyData = propertyDoc.data();
      const unitDoc = await db
        .collection("properties")
        .doc(propertyId)
        .collection("units")
        .doc(unitId)
        .get();
      const unitData = unitDoc.data();

      // Send confirmation email to guest (with "View my reservation" button)
      try {
        await sendBookingApprovedEmail(
          guestEmail,
          guestName,
          bookingReference,
          checkIn,
          checkOut,
          propertyData?.name || "Property",
          propertyData?.contact_email,
          result.accessToken, // Plaintext token for email link
          totalPrice,
          depositAmount,
          propertyId // For subdomain in email links
        );
        logInfo("Confirmation email sent to guest");
      } catch (error) {
        logError("Failed to send confirmation email to guest", error);
      }

      // Send notification email to owner (respect preferences)
      try {
        const ownerDoc = await db.collection("users").doc(ownerId).get();
        const ownerData = ownerDoc.data();

        if (ownerData?.email) {
          await sendEmailIfAllowed(
            ownerId,
            "payments",
            async () => {
              await sendOwnerNotificationEmail(
                ownerData.email,
                bookingReference,
                guestName,
                guestEmail,
                guestPhone || undefined,
                propertyData?.name || "Property",
                unitData?.name || "Unit",
                checkIn,
                checkOut,
                guestCount,
                totalPrice,
                depositAmount
              );
            },
            false // Respect preferences: owner can opt-out of payment notifications
          );
          logInfo(`Owner payment notification processed (sent if preferences allow): ${ownerData.email}`);
        }
      } catch (error) {
        logError("Failed to send notification email to owner", error);
      }

      // Create in-app payment notification for owner
      try {
        await createPaymentNotification(
          ownerId,
          result.bookingId,
          guestName,
          depositAmount
        );
        logInfo(`In-app payment notification created for owner ${ownerId}`);
      } catch (notificationError) {
        logError("Failed to create in-app payment notification", notificationError);
      }

      res.json({
        received: true,
        booking_id: result.bookingId,
        booking_reference: bookingReference,
        status: "confirmed",
      });
    } catch (error: any) {
      logError("Error processing webhook", error);
      res.status(500).send(`Error: ${error.message}`);
    }
  } else {
    // Unexpected event type
    logInfo(`Unhandled event type: ${event.type}`);
    res.json({ received: true });
  }
});
