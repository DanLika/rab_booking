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
import { validateBookingPrice, calculateBookingPrice } from "./utils/priceValidation";
import { checkRateLimit } from "./utils/rateLimit";
import {
  logSecurityEvent,
  logWebhookSignatureFailure,
  SecurityEventType,
} from "./utils/securityMonitoring";

// Define webhook secret
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

// Allowed domains for return URL (security whitelist)
// DOMAIN STRUCTURE:
// - bookbed.io = Marketing/Landing page (NOT for widget)
// - app.bookbed.io = Owner Dashboard
// - view.bookbed.io = Booking Widget (main domain)
// - *.view.bookbed.io = Client subdomains (e.g., jasko-rab.view.bookbed.io)
const ALLOWED_RETURN_DOMAINS = [
  "https://bookbed.io",           // Marketing site (for future use)
  "https://app.bookbed.io",       // Owner dashboard
  "https://view.bookbed.io",      // Booking widget (main domain)
  "https://rab-booking-248fc.web.app",  // Legacy fallback
  "http://localhost",             // Local development
  "http://127.0.0.1",             // Local development
];

// Allowed wildcard domains for custom client subdomains
// Widget uses view.bookbed.io subdomain structure: {client}.view.bookbed.io
const ALLOWED_WILDCARD_DOMAINS = [
  ".view.bookbed.io", // Client subdomains (e.g., jasko-rab.view.bookbed.io, villa-marija.view.bookbed.io)
];

/**
 * Validates if a return URL is allowed based on whitelist and wildcard rules
 * @param returnUrl - The full return URL to validate
 * @returns true if URL is allowed, false otherwise
 *
 * SECURITY: Uses split-based validation to prevent attacks like "evil-bookbed.io"
 * which would pass endsWith() check but should be blocked
 */
function isAllowedReturnUrl(returnUrl: string): boolean {
  // Check exact domain matches first
  const exactMatch = ALLOWED_RETURN_DOMAINS.some((domain) =>
    returnUrl.startsWith(domain)
  );

  if (exactMatch) return true;

  // Check wildcard domain matches (e.g., *.view.bookbed.io)
  try {
    const url = new URL(returnUrl);
    const hostname = url.hostname; // e.g., "jasko-rab.view.bookbed.io"

    return ALLOWED_WILDCARD_DOMAINS.some((wildcardDomain) => {
      // FIXED BUG #17: Secure wildcard validation using domain split
      // wildcardDomain = ".view.bookbed.io" → domainWithoutDot = "view.bookbed.io"
      const domainWithoutDot = wildcardDomain.slice(1); // Remove leading dot

      // Split both into parts
      const hostnameParts = hostname.split("."); // ["jasko-rab", "view", "bookbed", "io"]
      const wildcardParts = domainWithoutDot.split("."); // ["view", "bookbed", "io"]

      // SECURITY: Hostname must have MORE parts than wildcard domain
      // This blocks: "evil-view.bookbed.io" (3 parts) vs "view.bookbed.io" (3 parts)
      // This allows: "jasko-rab.view.bookbed.io" (4 parts) vs "view.bookbed.io" (3 parts)
      if (hostnameParts.length <= wildcardParts.length) {
        return false;
      }

      // Check if last N parts of hostname match wildcard domain
      // ["jasko-rab", "view", "bookbed", "io"] → last 3 parts: ["view", "bookbed", "io"]
      const lastParts = hostnameParts.slice(-wildcardParts.length);
      const matches = lastParts.join(".") === domainWithoutDot;

      return matches;
    });
  } catch {
    return false;
  }
}

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
  // ========================================================================
  // SECURITY: Rate Limiting - BEFORE any business logic
  // ========================================================================
  // Prevents DoS attacks and excessive Stripe API calls
  // Limits: 10 calls per 5 minutes per IP (in-memory, per-instance)
  const rawRequest = request.rawRequest as { ip?: string; headers?: Record<string, string> } | undefined;
  const clientIp = rawRequest?.ip ||
    rawRequest?.headers?.["x-forwarded-for"]?.split(",")[0]?.trim() ||
    "unknown";

  if (!checkRateLimit(`stripe_checkout:${clientIp}`, 10, 300)) {
    // Log security event (fire-and-forget)
    logSecurityEvent(
      SecurityEventType.RATE_LIMIT_EXCEEDED,
      { ip: clientIp, action: "stripe_checkout" },
      "medium"
    ).catch(() => {}); // Don't block on logging

    logWarn("createStripeCheckoutSession: Rate limit exceeded", { ip: clientIp });
    throw new HttpsError(
      "resource-exhausted",
      "Too many checkout attempts. Please wait a few minutes before trying again."
    );
  }

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
    logError("createStripeCheckoutSession: Booking data is missing");
    throw new HttpsError("invalid-argument", "Booking data is required");
  }

  let {
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

  // Validate required fields with detailed logging
  const missingFields: string[] = [];
  if (!unitId) missingFields.push("unitId");
  if (!propertyId) missingFields.push("propertyId");
  if (!ownerId) missingFields.push("ownerId");
  if (!checkIn) missingFields.push("checkIn");
  if (!checkOut) missingFields.push("checkOut");
  if (!guestName) missingFields.push("guestName");
  if (!guestEmail) missingFields.push("guestEmail");
  if (!totalPrice) missingFields.push("totalPrice");

  if (missingFields.length > 0) {
    // SECURITY: Log details internally, return generic message to client
    logError("createStripeCheckoutSession: Missing required booking fields", null, {
      bookingDataKeys: Object.keys(bookingData),
      missingFields: missingFields,
    });
    throw new HttpsError(
      "invalid-argument",
      "Invalid booking data. Please refresh the page and try again."
    );
  }

  // SECURITY: Validate return URL format and against whitelist
  if (returnUrl) {
    // Validate URL format first
    try {
      const url = new URL(returnUrl);
      logInfo("createStripeCheckoutSession: Return URL parsed", {
        origin: url.origin,
        pathname: url.pathname,
        hash: url.hash,
        search: url.search,
      });
    } catch (urlError) {
      // SECURITY: Log details internally, don't expose URL structure to client
      logError(`createStripeCheckoutSession: Invalid return URL format: ${returnUrl}`, urlError);
      logSecurityEvent(
        SecurityEventType.INVALID_RETURN_URL,
        { returnUrl, error: "Invalid format" },
        "medium"
      ).catch(() => {});
      throw new HttpsError("invalid-argument", "Invalid return URL format.");
    }

    // FIXED BUG #15: Check against whitelist with wildcard subdomain support
    if (!isAllowedReturnUrl(returnUrl)) {
      // SECURITY: Log details internally, generic message to client
      logError(`createStripeCheckoutSession: Invalid return URL (not in whitelist): ${returnUrl}`, null, {
        returnUrl: returnUrl,
        allowedDomains: ALLOWED_RETURN_DOMAINS,
        allowedWildcards: ALLOWED_WILDCARD_DOMAINS,
      });
      logSecurityEvent(
        SecurityEventType.INVALID_RETURN_URL,
        { returnUrl, error: "Not in whitelist" },
        "high"
      ).catch(() => {});
      throw new HttpsError(
        "invalid-argument",
        "Invalid return URL. Please try again from the booking page."
      );
    }
  } else {
    logWarn("createStripeCheckoutSession: No return URL provided, will use default");
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
      logError(`createStripeCheckoutSession: Owner ${ownerId} has not connected Stripe account`, null, {
        ownerId: ownerId,
        propertyId: propertyId,
      });
      throw new HttpsError(
        "failed-precondition",
        "Owner has not connected their Stripe account. Please contact the property owner."
      );
    }

    // ========================================================================
    // SECURITY: Verify Stripe Connect account status before checkout
    // ========================================================================
    // Ensures account can receive payments and has required capabilities
    const stripeVerifyClient = getStripeClient();
    try {
      const account = await stripeVerifyClient.accounts.retrieve(ownerStripeAccountId);

      // Check if account is enabled for charges (can receive payments)
      if (!account.charges_enabled) {
        logSecurityEvent(
          SecurityEventType.STRIPE_ACCOUNT_NOT_VERIFIED,
          {
            ownerId,
            stripeAccountId: ownerStripeAccountId,
            chargesEnabled: account.charges_enabled,
            payoutsEnabled: account.payouts_enabled,
            detailsSubmitted: account.details_submitted,
          },
          "high"
        ).catch(() => {}); // Fire-and-forget

        logError("createStripeCheckoutSession: Stripe account not enabled for charges", null, {
          ownerId,
          stripeAccountId: ownerStripeAccountId,
          chargesEnabled: account.charges_enabled,
        });
        throw new HttpsError(
          "failed-precondition",
          "Property owner's payment account is not fully set up. Please contact the property owner."
        );
      }

      // Check if account has required capabilities (card payments and transfers)
      const hasCardPayments = account.capabilities?.card_payments === "active";
      const hasTransfers = account.capabilities?.transfers === "active";

      if (!hasCardPayments || !hasTransfers) {
        logWarn("createStripeCheckoutSession: Stripe account missing capabilities", {
          ownerId,
          stripeAccountId: ownerStripeAccountId,
          hasCardPayments,
          hasTransfers,
          capabilities: account.capabilities,
        });
        throw new HttpsError(
          "failed-precondition",
          "Property owner's payment account is not fully configured. Please contact the property owner."
        );
      }

      logInfo("createStripeCheckoutSession: Stripe Connect account verified", {
        ownerId,
        stripeAccountId: ownerStripeAccountId,
        chargesEnabled: account.charges_enabled,
        payoutsEnabled: account.payouts_enabled,
      });
    } catch (error: unknown) {
      // Re-throw HttpsError (our own errors)
      if (error instanceof HttpsError) {
        throw error;
      }

      // Stripe API error - log and throw generic error
      const stripeError = error as { message?: string };
      logError("createStripeCheckoutSession: Error verifying Stripe account", error, {
        ownerId,
        stripeAccountId: ownerStripeAccountId,
        errorMessage: stripeError?.message,
      });
      throw new HttpsError(
        "internal",
        "Failed to verify payment account. Please try again later."
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
    // 2. Create placeholder booking with `pending` status (expires 15 min)
    // 3. Create Stripe session with placeholder booking ID in metadata
    // 4. Webhook updates placeholder to `confirmed` after successful payment
    // 5. Cleanup job deletes expired placeholders (if user abandons payment)

    // Sanitize inputs (security)
    const sanitizedGuestName = sanitizeText(guestName);
    const sanitizedGuestEmail = sanitizeEmail(guestEmail);
    const sanitizedGuestPhone = guestPhone ? sanitizePhone(guestPhone) : null;
    const sanitizedNotes = notes ? sanitizeText(notes) : null;

    if (!sanitizedGuestName || !sanitizedGuestEmail) {
      logError("createStripeCheckoutSession: Invalid guest name or email after sanitization", null, {
        originalGuestName: guestName,
        originalGuestEmail: guestEmail,
        sanitizedGuestName: sanitizedGuestName,
        sanitizedGuestEmail: sanitizedGuestEmail,
      });
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
    // SECURITY: Validate price BEFORE creating placeholder booking
    // ========================================================================
    // CRITICAL: Client may send locked price (€102.00) but server calculates
    // current price (€200.00). We must validate to prevent price manipulation.
    // However, if price changed, we should use server-calculated price, not client's locked price.
    try {
      await validateBookingPrice(
        unitId,
        checkInDate,
        checkOutDate,
        Number(totalPrice),
        propertyId
      );
      logInfo("createStripeCheckoutSession: Price validated successfully", {
        unitId,
        clientPrice: totalPrice,
      });
    } catch (priceError: any) {
      // If price mismatch, use server-calculated price instead of client's locked price
      if (priceError.code === "invalid-argument" && priceError.message?.includes("Price mismatch")) {
        logWarn("createStripeCheckoutSession: Price mismatch - using server-calculated price", {
          unitId,
          clientPrice: totalPrice,
          error: priceError.message,
        });
        
        // Calculate server-side price and use it instead
        const { totalPrice: serverPrice } = await calculateBookingPrice(
          unitId,
          checkInDate,
          checkOutDate,
          propertyId
        );
        
        logInfo("createStripeCheckoutSession: Using server-calculated price", {
          unitId,
          oldPrice: totalPrice,
          newPrice: serverPrice,
        });
        
        // Update totalPrice and depositAmount to use server-calculated price
        totalPrice = serverPrice;
        if (paymentOption === "deposit") {
          const depositPercentage = 20; // Default, should match config
          depositAmount = Math.round(serverPrice * (depositPercentage / 100) * 100) / 100;
        } else {
          depositAmount = serverPrice;
        }
      } else {
        // Other validation errors - rethrow
        throw priceError;
      }
    }

    // ========================================================================
    // ATOMIC TRANSACTION: Create placeholder booking with availability check
    // ========================================================================
    const placeholderResult = await db.runTransaction(async (transaction) => {
      // Check for conflicting bookings (including pending placeholders from Stripe checkout)
      // NEW STRUCTURE: Use direct subcollection path (faster than collection group in transaction)
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

      // Filter out expired placeholder bookings (stripe_pending_expires_at < now)
      // These are abandoned Stripe checkout sessions that haven't been cleaned up yet
      const now = admin.firestore.Timestamp.now();
      const activeConflicts = conflictingBookings.docs.filter((doc) => {
        const data = doc.data();
        // If booking has stripe_pending_expires_at, check if it's expired
        if (data.stripe_pending_expires_at) {
          const expiresAt = data.stripe_pending_expires_at as admin.firestore.Timestamp;
          // Exclude expired placeholders (expiresAt < now)
          if (expiresAt.toMillis() < now.toMillis()) {
            logInfo("createStripeCheckoutSession: Ignoring expired placeholder", {
              bookingId: doc.id,
              expiresAt: expiresAt.toDate().toISOString(),
            });
            return false; // Exclude expired placeholder
          }
        }
        return true; // Include confirmed bookings and non-expired pending bookings
      });

      if (activeConflicts.length > 0) {
        const conflicts = activeConflicts.map((doc) => ({
          id: doc.id,
          status: doc.data().status,
          checkIn: doc.data().check_in,
          checkOut: doc.data().check_out,
        }));
        logError("createStripeCheckoutSession: Date conflict detected", null, {
          unitId: unitId,
          checkIn: checkIn,
          checkOut: checkOut,
          conflicts: conflicts,
        });
        throw new HttpsError(
          "already-exists",
          "Dates no longer available. Another booking is in progress or confirmed."
        );
      }

      // Create placeholder booking
      // NEW STRUCTURE: Generate ID from subcollection path
      const placeholderBookingId = db
        .collection("properties")
        .doc(propertyId)
        .collection("units")
        .doc(unitId)
        .collection("bookings")
        .doc().id;
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
        status: "pending", // Use standard pending status (blocks dates until payment)
        booking_reference: bookingRef,
        source: "widget",
        notes: sanitizedNotes,
        require_owner_approval: false,
        tax_legal_accepted: taxLegalAccepted || false,
        // Booking lookup security
        access_token: hashedToken,
        token_expires_at: tokenExpiration,
        // Placeholder expiration (for cleanup of expired Stripe checkout attempts)
        stripe_pending_expires_at: expiresAt,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };

      // NEW STRUCTURE: Write to subcollection path
      transaction.set(
        db
          .collection("properties")
          .doc(propertyId)
          .collection("units")
          .doc(unitId)
          .collection("bookings")
          .doc(placeholderBookingId),
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

      logInfo("createStripeCheckoutSession: Built success/cancel URLs", {
        returnUrl,
        baseUrl,
        hashFragment,
        separator,
        successUrl,
        cancelUrl,
      });
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
    // If it's already an HttpsError, re-throw it (preserves status code and message)
    if (error instanceof HttpsError) {
      throw error;
    }

    // Log detailed error information
    logError("Error creating Stripe checkout session", error, {
      errorName: error?.name,
      errorMessage: error?.message,
      errorStack: error?.stack,
      hasBookingData: !!bookingData,
      returnUrl: returnUrl,
    });

    // Return user-friendly error message
    throw new HttpsError(
      "internal",
      error.message || "Failed to create checkout session. Please try again."
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
    // SECURITY: Log webhook signature failure (potential attack)
    logWebhookSignatureFailure(
      error.message || "Unknown error",
      !!sig,
      { hasRawBody: !!req.rawBody }
    ).catch(() => {}); // Fire-and-forget

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

      // Extract property_id and unit_id from metadata to construct direct path
      // This is more reliable than collection group query with documentId()
      const propertyIdFromMeta = metadata.property_id;
      const unitIdFromMeta = metadata.unit_id;

      if (!propertyIdFromMeta || !unitIdFromMeta) {
        logError("Missing property_id or unit_id in session metadata");
        res.status(400).send("Missing property/unit ID in session metadata");
        return;
      }

      // NEW STRUCTURE: Fetch placeholder booking using direct subcollection path
      const placeholderBookingRef = db
        .collection("properties")
        .doc(propertyIdFromMeta)
        .collection("units")
        .doc(unitIdFromMeta)
        .collection("bookings")
        .doc(placeholderBookingId);

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

      // Validate placeholder is actually pending status (created before Stripe checkout)
      if (placeholderData?.status !== "pending") {
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
