import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getStripeClient, stripeSecretKey} from "./stripe";
import {db} from "./firebase";
import {logInfo, logError, logSuccess} from "./logger";
import {checkRateLimit} from "./utils/rateLimit";
import {isAllowedReturnUrl} from "./utils/returnUrlValidation";
import * as admin from "firebase-admin";

/**
 * Cloud Function: Create Subscription Checkout Session
 *
 * Handles the creation of a Stripe Checkout Session for Owner Subscriptions.
 *
 * Flow:
 * 1. Validate user is authenticated.
 * 2. Check/create Stripe Customer for the user.
 * 3. Create Checkout Session with the selected Price ID.
 * 4. Return the session URL.
 */
export const createSubscriptionCheckoutSession = onCall({secrets: [stripeSecretKey]}, async (request) => {
  // 1. Rate Limiting
  const rawRequest = request.rawRequest as { ip?: string; headers?: Record<string, string> } | undefined;
  const clientIp = rawRequest?.ip ||
        rawRequest?.headers?.["x-forwarded-for"]?.split(",")[0]?.trim() ||
        "unknown";

  if (!checkRateLimit(`sub_checkout:${clientIp}`, 10, 300)) {
    throw new HttpsError("resource-exhausted", "Too many attempts. Please try again later.");
  }

  // 2. Authentication Check
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const userId = request.auth.uid;
  const userEmail = request.auth.token.email;
  const {priceId, returnUrl} = request.data;

  if (!priceId || !returnUrl) {
    throw new HttpsError("invalid-argument", "Missing priceId or returnUrl.");
  }

  // F-NEW-02: validate returnUrl against the BookBed allowlist. Without
  // this, success_url + cancel_url interpolate attacker-controlled domains
  // and leak the {CHECKOUT_SESSION_ID} capability token in the redirect.
  if (!isAllowedReturnUrl(returnUrl)) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid returnUrl: must be a BookBed-controlled domain."
    );
  }

  // Price ID allowlist (audit/38, .claude/rules/stripe.md § Subscription Flow).
  // Source: process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS — comma-separated, loaded
  // from functions/.env.<project> at deploy. Empty/unset = deny-all (fail-CLOSED)
  // so a forgotten env-var cannot reopen the bypass.
  const allowedPriceIds = (process.env.ALLOWED_SUBSCRIPTION_PRICE_IDS || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  if (allowedPriceIds.length === 0) {
    logError("ALLOWED_SUBSCRIPTION_PRICE_IDS is empty — subscription checkout blocked", null, {
      userId,
      requestedPriceId: priceId,
    });
    throw new HttpsError(
      "failed-precondition",
      "Subscription pricing is not configured. Contact support."
    );
  }
  if (!allowedPriceIds.includes(priceId)) {
    logError("Subscription checkout rejected: priceId not in allowlist", null, {
      userId,
      requestedPriceId: priceId,
    });
    throw new HttpsError("invalid-argument", "Price not allowed.");
  }

  try {
    const stripe = getStripeClient();

    // 3. Get or Create Stripe Customer
    const userDocRef = db.collection("users").doc(userId);
    const userDoc = await userDocRef.get();
    const userData = userDoc.data();

    let customerId = userData?.stripe_customer_id;

    if (!customerId) {
      // Create new customer
      logInfo(`Creating new Stripe customer for user ${userId}`);
      const customer = await stripe.customers.create(
        {
          email: userEmail,
          metadata: {
            userId: userId,
          },
        },
        // SF-039: idempotencyKey scoped to userId. Network retry returns
        // the same customer object instead of creating a duplicate.
        {idempotencyKey: `customer-${userId}`}
      );
      customerId = customer.id;

      // Save customer ID to user document
      await userDocRef.update({
        stripe_customer_id: customerId,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      logInfo(`Using existing Stripe customer ${customerId} for user ${userId}`);
    }

    // 4. Create Checkout Session
    // SF-039: idempotencyKey on 1-hour bucket. Subscription checkout
    // sessions expire in 24h; a bucket smaller than that prevents network
    // retry from creating duplicate sessions but still allows the user to
    // restart cleanly after the hour elapses.
    const subCheckoutHourBucket = Math.floor(Date.now() / (60 * 60 * 1000));
    const session = await stripe.checkout.sessions.create(
      {
        customer: customerId,
        line_items: [
          {
            price: priceId,
            quantity: 1,
          },
        ],
        mode: "subscription",
        success_url: `${returnUrl}?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: `${returnUrl}?status=cancelled`,
        client_reference_id: userId,
        allow_promotion_codes: true,
        subscription_data: {
          metadata: {
            userId: userId,
          },
        },
        metadata: {
          userId: userId,
          type: "subscription_upgrade",
        },
      },
      {idempotencyKey: `sub-checkout-${userId}-${priceId}-${subCheckoutHourBucket}`}
    );

    logSuccess(`Created subscription checkout session ${session.id} for user ${userId}`);

    return {
      url: session.url,
      sessionId: session.id,
    };
  } catch (error: any) {
    logError("Error creating subscription checkout session", error);
    throw new HttpsError("internal", "Failed to create checkout session.");
  }
});

/**
 * Cloud Function: Create Customer Portal Session
 * Allows users to manage their billing (cancel, update payment method)
 */
export const createCustomerPortalSession = onCall({secrets: [stripeSecretKey]}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const userId = request.auth.uid;
  const {returnUrl} = request.data;

  // F-NEW-02: validate client-supplied return URL against allowlist before
  // handing to billingPortal.sessions.create. Empty/missing falls back to
  // the hard-coded dashboard URL (safe). Provided URL must pass allowlist.
  if (returnUrl && !isAllowedReturnUrl(returnUrl)) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid returnUrl: must be a BookBed-controlled domain."
    );
  }

  try {
    const stripe = getStripeClient();
    const userDoc = await db.collection("users").doc(userId).get();
    const customerId = userDoc.data()?.stripe_customer_id;

    if (!customerId) {
      throw new HttpsError("failed-precondition", "No subscription account found.");
    }

    // SF-039: idempotencyKey on 1-minute bucket. Portal sessions are
    // short-lived; bucket prevents network-retry duplicates without
    // making "open billing portal" a no-op for long.
    const portalMinuteBucket = Math.floor(Date.now() / 60000);
    const session = await stripe.billingPortal.sessions.create(
      {
        customer: customerId,
        return_url: returnUrl || "https://app.bookbed.io/owner/subscription",
      },
      {idempotencyKey: `portal-${userId}-${portalMinuteBucket}`}
    );

    logSuccess(`Created customer portal session for user ${userId}`);

    return {url: session.url};
  } catch (error: any) {
    if (error instanceof HttpsError) throw error;
    logError("Error creating portal session", error);
    throw new HttpsError("internal", "Failed to create portal session.");
  }
});
