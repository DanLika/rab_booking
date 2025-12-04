import {onCall, onRequest, HttpsError} from "firebase-functions/v2/https";
import Stripe from "stripe";
import {defineSecret} from "firebase-functions/params";
import {
  sendBookingApprovedEmail,
  sendOwnerNotificationEmail,
} from "./emailService";
import {sendEmailIfAllowed} from "./emailNotificationHelper";
import {admin, db} from "./firebase";
import {getStripeClient, stripeSecretKey} from "./stripe";
import {createPaymentNotification} from "./notificationService";
import {
  generateBookingAccessToken,
  calculateTokenExpiration,
} from "./bookingAccessToken";

// Define webhook secret
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

// Allowed domains for return URL (security whitelist)
const ALLOWED_RETURN_DOMAINS = [
  "https://rab-booking-248fc.web.app",
  "https://rab-booking-owner.web.app",
  "https://rab-booking-widget.web.app",
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
export const createStripeCheckoutSession = onCall({secrets: [stripeSecretKey]}, async (request) => {
  const {
    // Booking data (from atomicBooking validation result)
    bookingData,
    returnUrl,
  } = request.data;

  // Debug logging
  console.log("createStripeCheckoutSession called with:", {
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
      console.error(`Invalid return URL attempted: ${returnUrl}`);
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

    // Generate booking reference for display
    const bookingRef = `BK-${Date.now()}-${Math.floor(Math.random() * 10000)}`;

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
      // CRITICAL: Store ALL booking data in metadata for webhook to create booking
      metadata: {
        // Booking identifiers
        booking_reference: bookingRef,
        unit_id: unitId,
        property_id: propertyId,
        owner_id: ownerId,
        // Dates (ISO strings)
        check_in: checkIn,
        check_out: checkOut,
        // Guest info
        guest_name: guestName,
        guest_email: guestEmail,
        guest_phone: guestPhone || "",
        guest_count: String(guestCount),
        // Payment info
        total_price: String(totalPrice),
        deposit_amount: String(depositAmount),
        payment_option: paymentOption,
        // Optional fields
        notes: notes || "",
        tax_legal_accepted: taxLegalAccepted ? "true" : "false",
      },
      customer_email: guestEmail,
    });

    console.log(`Stripe checkout session created: ${session.id}`);
    console.log(`Booking will be created by webhook after payment success`);

    return {
      success: true,
      sessionId: session.id,
      checkoutUrl: session.url,
      bookingReference: bookingRef, // Return for UI display
    };
  } catch (error: any) {
    console.error("Error creating Stripe checkout session:", error);
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
export const handleStripeWebhook = onRequest({secrets: [stripeSecretKey, stripeWebhookSecret]}, async (req, res) => {
  const sig = req.headers["stripe-signature"];

  if (!sig) {
    console.error("Missing stripe-signature header");
    res.status(400).send("Missing signature");
    return;
  }

  const webhookSecret = stripeWebhookSecret.value();
  if (!webhookSecret) {
    console.error("STRIPE_WEBHOOK_SECRET not configured");
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
    console.error("Webhook signature verification failed:", error.message);
    res.status(400).send(`Webhook Error: ${error.message}`);
    return;
  }

  // Handle the event
  if (event.type === "checkout.session.completed") {
    const session = event.data.object as Stripe.Checkout.Session;
    const metadata = session.metadata;

    // Validate required metadata
    if (!metadata?.unit_id || !metadata?.property_id || !metadata?.owner_id) {
      console.error("Missing required metadata in session:", {
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
      // Extract all booking data from metadata
      const unitId = metadata.unit_id;
      const propertyId = metadata.property_id;
      const ownerId = metadata.owner_id;
      const bookingReference = metadata.booking_reference;
      const checkIn = new Date(metadata.check_in);
      const checkOut = new Date(metadata.check_out);
      const guestName = metadata.guest_name;
      const guestEmail = metadata.guest_email;
      const guestPhone = metadata.guest_phone || null;
      const guestCount = parseInt(metadata.guest_count) || 1;
      const totalPrice = parseFloat(metadata.total_price);
      const depositAmount = parseFloat(metadata.deposit_amount);
      const paymentOption = metadata.payment_option;

      // Validate numeric values to prevent NaN issues
      if (isNaN(totalPrice) || isNaN(depositAmount)) {
        console.error("Invalid numeric metadata:", {
          total_price: metadata.total_price,
          deposit_amount: metadata.deposit_amount,
          parsed_totalPrice: totalPrice,
          parsed_depositAmount: depositAmount,
        });
        res.status(400).send("Invalid price metadata");
        return;
      }
      const notes = metadata.notes || null;
      const taxLegalAccepted = metadata.tax_legal_accepted === "true";

      console.log(`Processing Stripe webhook for booking: ${bookingReference}`);
      console.log(`Unit: ${unitId}, CheckIn: ${checkIn}, CheckOut: ${checkOut}`);

      // IDEMPOTENCY CHECK: Prevent duplicate bookings if webhook fires twice
      const existingBookingQuery = await db.collection("bookings")
        .where("stripe_session_id", "==", session.id)
        .limit(1)
        .get();

      if (!existingBookingQuery.empty) {
        const existingBooking = existingBookingQuery.docs[0];
        console.log(`Webhook already processed - booking ${existingBooking.id} exists for session ${session.id}`);
        res.json({
          received: true,
          booking_id: existingBooking.id,
          booking_reference: existingBooking.data().booking_reference,
          status: "already_processed",
          message: "Booking already created for this session",
        });
        return;
      }

      // Convert to Firestore timestamps
      const checkInTimestamp = admin.firestore.Timestamp.fromDate(checkIn);
      const checkOutTimestamp = admin.firestore.Timestamp.fromDate(checkOut);

      // CRITICAL: Use transaction to ensure atomic booking creation
      // This prevents race condition where dates could be double-booked
      const result = await db.runTransaction(async (transaction) => {
        // Re-check availability within transaction
        const conflictingBookingsQuery = db
          .collection("bookings")
          .where("unit_id", "==", unitId)
          .where("status", "in", ["pending", "confirmed"])
          .where("check_in", "<", checkOutTimestamp)
          .where("check_out", ">", checkInTimestamp);

        const conflictingBookings = await transaction.get(conflictingBookingsQuery);

        if (!conflictingBookings.empty) {
          // Date conflict detected - someone else booked between checkout and webhook
          console.error("Date conflict detected during webhook processing:", {
            unitId,
            checkIn: metadata.check_in,
            checkOut: metadata.check_out,
            conflictingCount: conflictingBookings.size,
          });

          // AUTO-REFUND: Payment was successful, but dates are no longer available
          // We must refund the customer automatically
          const paymentIntentId = session.payment_intent as string;

          if (paymentIntentId) {
            const stripeClient = getStripeClient();
            try {
              await stripeClient.refunds.create({
                payment_intent: paymentIntentId,
                reason: "requested_by_customer", // Stripe requires this for bookings
                metadata: {
                  reason: "DATE_CONFLICT",
                  booking_reference: bookingReference,
                  unit_id: unitId,
                  check_in: metadata.check_in,
                  check_out: metadata.check_out,
                },
              });
              console.log(`Auto-refund issued for date conflict: ${paymentIntentId}`);
            } catch (refundError) {
              console.error("CRITICAL: Failed to issue auto-refund:", refundError);
              // Store failed refund for manual intervention
              try {
                await db.collection("refund_pending").add({
                  payment_intent_id: paymentIntentId,
                  stripe_session_id: session.id,
                  reason: "DATE_CONFLICT",
                  booking_reference: bookingReference,
                  unit_id: unitId,
                  property_id: propertyId,
                  owner_id: ownerId,
                  guest_email: guestEmail,
                  guest_name: guestName,
                  amount: depositAmount,
                  check_in: metadata.check_in,
                  check_out: metadata.check_out,
                  error_message: String(refundError),
                  status: "requires_manual_refund",
                  created_at: admin.firestore.FieldValue.serverTimestamp(),
                });
                console.log(`Created refund_pending record for manual intervention`);
              } catch (dbError) {
                console.error("Failed to create refund_pending record:", dbError);
              }
            }
          }

          throw new Error(`DATE_CONFLICT: Dates were booked by another user. Refund ${paymentIntentId ? "attempted" : "skipped (no payment intent)"}`);
        }

        // Create booking document
        const bookingId = db.collection("bookings").doc().id;
        const bookingDocRef = db.collection("bookings").doc(bookingId);

        // Generate secure access token for "View my reservation" email link
        const {token: accessToken, hashedToken} = generateBookingAccessToken();
        const tokenExpiration = calculateTokenExpiration(checkOutTimestamp);

        const bookingData = {
          user_id: null, // Widget bookings are unauthenticated
          unit_id: unitId,
          property_id: propertyId,
          owner_id: ownerId,
          guest_name: guestName,
          guest_email: guestEmail,
          guest_phone: guestPhone,
          check_in: checkInTimestamp,
          check_out: checkOutTimestamp,
          guest_count: guestCount,
          total_price: totalPrice,
          advance_amount: depositAmount,
          deposit_amount: depositAmount,
          remaining_amount: totalPrice - depositAmount,
          paid_amount: depositAmount,
          payment_method: "stripe",
          payment_option: paymentOption,
          payment_status: "paid",
          status: "confirmed", // Stripe payments are always confirmed (paid)
          booking_reference: bookingReference,
          source: "widget",
          notes: notes,
          require_owner_approval: false, // Stripe = no approval needed
          tax_legal_accepted: taxLegalAccepted,
          // Stripe payment details
          stripe_session_id: session.id,
          payment_intent_id: session.payment_intent,
          // Booking lookup security (for "View my reservation" link)
          access_token: hashedToken,
          token_expires_at: tokenExpiration,
          paid_at: admin.firestore.FieldValue.serverTimestamp(),
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        };

        transaction.set(bookingDocRef, bookingData);

        return { bookingId, bookingData, accessToken };
      });

      console.log(`Booking ${result.bookingId} created after Stripe payment`);

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
        console.log("Confirmation email sent to guest");
      } catch (error) {
        console.error("Failed to send confirmation email to guest:", error);
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
          console.log(`Owner payment notification processed (sent if preferences allow): ${ownerData.email}`);
        }
      } catch (error) {
        console.error("Failed to send notification email to owner:", error);
      }

      // Create in-app payment notification for owner
      try {
        await createPaymentNotification(
          ownerId,
          result.bookingId,
          guestName,
          depositAmount
        );
        console.log(`In-app payment notification created for owner ${ownerId}`);
      } catch (notificationError) {
        console.error("Failed to create in-app payment notification:", notificationError);
      }

      res.json({
        received: true,
        booking_id: result.bookingId,
        booking_reference: bookingReference,
        status: "confirmed",
      });
    } catch (error: any) {
      console.error("Error processing webhook:", error);
      res.status(500).send(`Error: ${error.message}`);
    }
  } else {
    // Unexpected event type
    console.log(`Unhandled event type: ${event.type}`);
    res.json({received: true});
  }
});
