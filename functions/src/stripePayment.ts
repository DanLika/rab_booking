import {onCall, onRequest, HttpsError} from "firebase-functions/v2/https";
import Stripe from "stripe";
import {defineSecret} from "firebase-functions/params";
import {
  sendBookingApprovedEmail,
  sendOwnerNotificationEmail,
} from "./emailService";
import {admin, db} from "./firebase";
import {getStripeClient, stripeSecretKey} from "./stripe";
import {createPaymentNotification} from "./notificationService";

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
 * Creates a Stripe checkout session for 20% deposit payment
 * Security: Validates booking access and return URL
 */
export const createStripeCheckoutSession = onCall({secrets: [stripeSecretKey]}, async (request) => {
  const {bookingId, returnUrl, guestEmail} = request.data;

  // Debug logging
  console.log("createStripeCheckoutSession called with:", {
    bookingId,
    returnUrl: returnUrl ? "provided" : "not provided",
    guestEmail: guestEmail || "NOT PROVIDED",
    hasAuth: !!request.auth,
  });

  if (!bookingId) {
    throw new HttpsError("invalid-argument", "Booking ID is required");
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
    // Fetch booking details
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw new HttpsError("not-found", "Booking not found");
    }

    const booking = bookingDoc.data()!;

    // SECURITY: Validate access to this booking
    // Allow if: 1) Guest email matches, or 2) Authenticated owner
    const isGuestAccess = guestEmail &&
      booking.guest_email?.toLowerCase() === guestEmail.toLowerCase();
    const isOwnerAccess = request.auth?.uid === booking.owner_id;
    const isAuthenticatedUser = request.auth?.uid != null;

    // For guest checkout (no auth), require matching email
    // For authenticated users, allow if they're the owner
    if (!isGuestAccess && !isOwnerAccess && !isAuthenticatedUser) {
      // If no auth and no matching email, this could be an attack
      if (!request.auth && !guestEmail) {
        console.error(`Unauthorized checkout attempt for booking ${bookingId}`);
        throw new HttpsError("permission-denied", "Guest email required for checkout");
      }
    }

    // Fetch unit and property details
    const unitDoc = await db.collection("units").doc(booking.unit_id).get();
    const unitData = unitDoc.data();
    const propertyDoc = await db
      .collection("properties")
      .doc(booking.property_id)
      .get();
    const propertyData = propertyDoc.data();

    // Get owner's Stripe Connect account ID
    const ownerId = propertyData?.owner_id;
    if (!ownerId) {
      throw new HttpsError("not-found", "Property owner not found");
    }

    const ownerDoc = await db.collection("users").doc(ownerId).get();
    const ownerStripeAccountId = ownerDoc.data()?.stripe_account_id;

    if (!ownerStripeAccountId) {
      throw new HttpsError(
        "failed-precondition",
        "Owner has not connected their Stripe account. Please contact the property owner."
      );
    }

    const depositAmountInCents = Math.round(booking.deposit_amount * 100);

    // Note: Platform fee is 0 for now (as requested)
    // To add platform fee later, uncomment these lines:
    // const platformFeePercent = 0.10; // 10%
    // const platformFee = Math.round(depositAmountInCents * platformFeePercent);

    // Create Stripe checkout session with destination charge
    const stripeClient = getStripeClient();

    // Build success/cancel URLs properly
    // Widget sends returnUrl with query params (e.g., ?property=x&unit=y&payment=stripe)
    // We need to append session_id as a query parameter, NOT append /booking-success path
    let successUrl: string;
    let cancelUrl: string;

    if (returnUrl) {
      // Widget embedded in external website - return there with session_id
      // Check if URL already has query params
      successUrl = returnUrl.includes("?")
        ? `${returnUrl}&stripe_status=success&session_id={CHECKOUT_SESSION_ID}`
        : `${returnUrl}?stripe_status=success&session_id={CHECKOUT_SESSION_ID}`;
      cancelUrl = returnUrl.includes("?")
        ? `${returnUrl}&stripe_status=cancelled`
        : `${returnUrl}?stripe_status=cancelled`;
    } else {
      // No returnUrl provided - use default app URLs
      successUrl = "https://rab-booking-248fc.web.app/booking-success?session_id={CHECKOUT_SESSION_ID}";
      cancelUrl = "https://rab-booking-248fc.web.app/booking-cancelled";
    }

    const session = await stripeClient.checkout.sessions.create({
      payment_method_types: ["card"],
      mode: "payment",
      line_items: [
        {
          price_data: {
            currency: "eur",
            unit_amount: depositAmountInCents,
            product_data: {
              name: `Booking Deposit - ${booking.booking_reference}`,
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
        // on_behalf_of: Ensures statement descriptor shows owner's business name
        // This is required for proper Connect integration
        on_behalf_of: ownerStripeAccountId,
        // Platform fee (currently 0, can be enabled later)
        // application_fee_amount: platformFee,
        transfer_data: {
          destination: ownerStripeAccountId, // Money goes directly to owner
        },
      },
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: {
        booking_id: bookingId,
        booking_reference: booking.booking_reference,
        unit_id: booking.unit_id,
        property_id: booking.property_id,
        owner_id: ownerId,
      },
      customer_email: booking.guest_email,
    });

    // Update booking with Stripe session ID
    await bookingRef.update({
      stripe_session_id: session.id,
      stripe_account_id: ownerStripeAccountId,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      sessionId: session.id,
      checkoutUrl: session.url,
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
 * Listens for payment success events from Stripe and updates booking status
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
    const bookingId = session.metadata?.booking_id;

    if (!bookingId) {
      console.error("No booking_id in session metadata");
      res.status(400).send("Missing booking_id");
      return;
    }

    try {
      const bookingRef = db.collection("bookings").doc(bookingId);
      const bookingDoc = await bookingRef.get();

      if (!bookingDoc.exists) {
        console.error(`Booking ${bookingId} not found`);
        res.status(404).send("Booking not found");
        return;
      }

      const booking = bookingDoc.data()!;

      // Update booking status to confirmed
      await bookingRef.update({
        status: "confirmed",
        payment_status: "paid",
        payment_method: "stripe",
        paid_amount: booking.deposit_amount,
        stripe_payment_intent: session.payment_intent,
        paid_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Booking ${bookingId} confirmed after Stripe payment`);

      // Fetch unit and property details for emails
      const unitDoc = await db
        .collection("units")
        .doc(booking.unit_id)
        .get();
      const unitData = unitDoc.data();
      const propertyDoc = await db
        .collection("properties")
        .doc(booking.property_id)
        .get();
      const propertyData = propertyDoc.data();

      // Send confirmation email to guest
      try {
        await sendBookingApprovedEmail(
          booking.guest_email || "",
          booking.guest_name || "Guest",
          booking.booking_reference,
          booking.check_in.toDate(),
          booking.check_out.toDate(),
          propertyData?.name || "Property",
          propertyData?.contact_email
        );
        console.log(`Confirmation email sent to ${booking.guest_email}`);
      } catch (error) {
        console.error("Failed to send confirmation email to guest:", error);
      }

      // Send notification email to owner
      try {
        const ownerId = propertyData?.owner_id;
        if (ownerId) {
          const ownerDoc = await db.collection("users").doc(ownerId).get();
          const ownerData = ownerDoc.data();

          if (ownerData?.email) {
            await sendOwnerNotificationEmail(
              ownerData.email,
              ownerData.name || "Owner",
              booking.guest_name || "Guest",
              booking.guest_email || "",
              booking.booking_reference,
              booking.check_in.toDate(),
              booking.check_out.toDate(),
              booking.total_price,
              booking.deposit_amount || 0,
              unitData?.name || "Unit"
            );
            console.log(`Owner notification sent to ${ownerData.email}`);
          }
        }
      } catch (error) {
        console.error("Failed to send notification email to owner:", error);
      }

      // Create in-app payment notification for owner
      try {
        const ownerId = propertyData?.owner_id;
        if (ownerId) {
          await createPaymentNotification(
            ownerId,
            bookingId,
            booking.guest_name || "Guest",
            booking.deposit_amount || 0
          );
          console.log(`In-app payment notification created for owner ${ownerId}`);
        }
      } catch (notificationError) {
        console.error("Failed to create in-app payment notification:", notificationError);
        // Continue - notification failure shouldn't break the flow
      }

      res.json({received: true, booking_id: bookingId, status: "confirmed"});
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
