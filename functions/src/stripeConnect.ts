import {onCall, HttpsError} from "firebase-functions/v2/https";
import {admin, db} from "./firebase";
import {getStripeClient, stripeSecretKey} from "./stripe";
import {logInfo, logError, logWarn} from "./logger";
import {setUser} from "./sentry";
import {checkRateLimit} from "./utils/rateLimit";
import {requireActiveOwner} from "./utils/requireActiveOwner";
import {logSecurityEvent, SecurityEventType} from "./utils/securityMonitoring";
import {isAllowedReturnUrl} from "./utils/returnUrlValidation";
import {getCorsAllowlist} from "./utils/corsAllowlist";

/**
 * Cloud Function: Create or Get Stripe Connect Account
 *
 * Creates a Stripe Express account for the owner if they don't have one
 */
export const createStripeConnectAccount = onCall({secrets: [stripeSecretKey], cors: getCorsAllowlist()}, async (request) => {
  // SF-078: trial gate BEFORE rate-limit so trial_expired callers don't burn
  // their per-uid budget. Owner subscription/upgrade flow is the separate
  // `createSubscriptionCheckoutSession` callable (EXEMPT) — see audit/110.
  const ownerId = await requireActiveOwner(request.auth);

  // Rate Limiting: Prevent abuse of Stripe Account Link generation
  // 5 calls per 5 minutes per user
  const rawRequest = request.rawRequest as { ip?: string; headers?: Record<string, string> } | undefined;
  const clientIp = rawRequest?.ip || "unknown";

  if (!checkRateLimit(`stripe_connect:${ownerId}`, 5, 300)) {
    logSecurityEvent(
      SecurityEventType.RATE_LIMIT_EXCEEDED,
      {userId: ownerId, action: "stripe_connect", ip: clientIp},
      "medium"
    ).catch(() => {});
    logWarn("createStripeConnectAccount: Rate limit exceeded", {userId: ownerId});
    throw new HttpsError("resource-exhausted", "Too many attempts. Please try again later.");
  }

  const {returnUrl, refreshUrl} = request.data;

  // Set user context for Sentry error tracking
  setUser(ownerId);

  // F-NEW-02: validate both URLs against the BookBed allowlist before
  // handing them to Stripe accountLinks.create. Without this, an attacker
  // who tricks an owner into invoking this CF (XSS, social-engineered link)
  // can land the post-Stripe-Connect-onboarding redirect on a phishing
  // domain — high-trust position immediately after the user types KYC data.
  if (!returnUrl || !isAllowedReturnUrl(returnUrl)) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid returnUrl: must be a BookBed-controlled domain."
    );
  }
  // refreshUrl is optional; fall back to returnUrl. If provided, validate.
  if (refreshUrl && !isAllowedReturnUrl(refreshUrl)) {
    throw new HttpsError(
      "invalid-argument",
      "Invalid refreshUrl: must be a BookBed-controlled domain."
    );
  }

  try {
    // Get owner data
    const ownerDoc = await db.collection("users").doc(ownerId).get();
    if (!ownerDoc.exists) {
      throw new HttpsError("not-found", "Owner not found");
    }

    const ownerData = ownerDoc.data()!;
    let stripeAccountId = ownerData.stripe_account_id;

    // If account doesn't exist, create new Express account
    if (!stripeAccountId) {
      logInfo(`Creating new Stripe Express account for owner ${ownerId}`);

      const account = await getStripeClient().accounts.create(
        {
          type: "express",
          country: "HR", // Croatia
          email: ownerData.email || undefined,
          capabilities: {
            card_payments: {requested: true},
            transfers: {requested: true},
          },
          business_type: "individual",
          metadata: {
            owner_id: ownerId,
            platform: "bookbed",
          },
        },
        // SF-039: idempotencyKey scoped to owner. Network retry of a
        // submitted accounts.create returns the SAME account instead of
        // creating a duplicate Express account and triggering a second
        // KYC flow.
        {idempotencyKey: `connect-account-${ownerId}`}
      );

      stripeAccountId = account.id;

      // Save account ID to Firestore
      await db.collection("users").doc(ownerId).update({
        stripe_account_id: stripeAccountId,
        stripe_connected_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      logInfo(`Stripe account ${stripeAccountId} created for owner ${ownerId}`);
    }

    // Create account link for onboarding or re-onboarding
    // SF-039: idempotencyKey on a 1-minute bucket. Stripe account links are
    // short-lived (~minutes) — a true idempotent key would return a stale
    // link on legitimate re-invocation. Bucket per minute covers network
    // retry of the same request without making "re-onboard" a no-op.
    const minuteBucket = Math.floor(Date.now() / 60000);
    const accountLink = await getStripeClient().accountLinks.create(
      {
        account: stripeAccountId,
        refresh_url: refreshUrl || returnUrl,
        return_url: returnUrl,
        type: "account_onboarding",
      },
      {idempotencyKey: `account-link-${stripeAccountId}-${minuteBucket}`}
    );

    return {
      success: true,
      accountId: stripeAccountId,
      onboardingUrl: accountLink.url,
    };
  } catch (error: any) {
    if (error instanceof HttpsError) throw error;
    logError("Error creating Stripe Connect account", error);
    throw new HttpsError(
      "internal",
      "Failed to create Stripe account."
    );
  }
});

/**
 * Cloud Function: Get Stripe Account Status
 *
 * Returns the status of owner's Stripe account
 */
export const getStripeAccountStatus = onCall({secrets: [stripeSecretKey], cors: getCorsAllowlist()}, async (request) => {
  // Check authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const ownerId = request.auth.uid;

  // Set user context for Sentry error tracking
  setUser(ownerId);

  try {
    // Get owner data
    const ownerDoc = await db.collection("users").doc(ownerId).get();
    if (!ownerDoc.exists) {
      throw new HttpsError("not-found", "Owner not found");
    }

    const stripeAccountId = ownerDoc.data()!.stripe_account_id;

    if (!stripeAccountId) {
      return {
        connected: false,
        message: "No Stripe account connected",
      };
    }

    // Get account details from Stripe
    const account = await getStripeClient().accounts.retrieve(stripeAccountId);

    // Check if account is fully onboarded
    const isOnboarded = account.charges_enabled && account.payouts_enabled;

    // Get balance
    let balance = null;
    if (isOnboarded) {
      try {
        // v22 SDK enforces stripeAccount as RequestOptions, not params.
        const balanceData = await getStripeClient().balance.retrieve(
          {},
          {stripeAccount: stripeAccountId},
        );
        balance = {
          available: balanceData.available.map((b) => ({
            amount: b.amount / 100, // Convert cents to euros
            currency: b.currency.toUpperCase(),
          })),
          pending: balanceData.pending.map((b) => ({
            amount: b.amount / 100,
            currency: b.currency.toUpperCase(),
          })),
        };
      } catch (error) {
        logError("Error fetching balance", error);
      }
    }

    return {
      connected: true,
      accountId: stripeAccountId,
      onboarded: isOnboarded,
      chargesEnabled: account.charges_enabled,
      payoutsEnabled: account.payouts_enabled,
      email: account.email,
      country: account.country,
      balance,
      requirements: {
        currentlyDue: account.requirements?.currently_due || [],
        eventuallyDue: account.requirements?.eventually_due || [],
        pastDue: account.requirements?.past_due || [],
      },
    };
  } catch (error: any) {
    if (error instanceof HttpsError) throw error;
    logError("Error getting Stripe account status", error);
    throw new HttpsError(
      "internal",
      "Failed to get account status."
    );
  }
});

/**
 * Cloud Function: Disconnect Stripe Account
 *
 * Disconnects owner's Stripe account from the platform
 */
export const disconnectStripeAccount = onCall({secrets: [stripeSecretKey], cors: getCorsAllowlist()}, async (request) => {
  // Check authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const ownerId = request.auth.uid;

  // Set user context for Sentry error tracking
  setUser(ownerId);

  try {
    // Get owner data
    const ownerDoc = await db.collection("users").doc(ownerId).get();
    if (!ownerDoc.exists) {
      throw new HttpsError("not-found", "Owner not found");
    }

    const stripeAccountId = ownerDoc.data()!.stripe_account_id;

    if (!stripeAccountId) {
      throw new HttpsError(
        "failed-precondition",
        "No Stripe account connected"
      );
    }

    // Remove integration from Firestore only
    // NOTE: We do NOT delete the Stripe account itself - it remains active
    // and the owner can continue using it independently or reconnect later
    await db.collection("users").doc(ownerId).update({
      stripe_account_id: admin.firestore.FieldValue.delete(),
      stripe_connected_at: admin.firestore.FieldValue.delete(),
      stripe_disconnected_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    logInfo(`Stripe integration removed for owner ${ownerId}. Account ${stripeAccountId} remains active.`);

    return {
      success: true,
      message: "Stripe integracija uklonjena. Vaš Stripe račun ostaje aktivan.",
    };
  } catch (error: any) {
    if (error instanceof HttpsError) throw error;
    logError("Error disconnecting Stripe account", error);
    throw new HttpsError(
      "internal",
      "Failed to disconnect account."
    );
  }
});
