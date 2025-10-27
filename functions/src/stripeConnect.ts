import {onCall, HttpsError} from "firebase-functions/v2/https";
import {admin, db} from "./firebase";
import {getStripeClient} from "./stripe";

/**
 * Cloud Function: Create or Get Stripe Connect Account
 *
 * Creates a Stripe Express account for the owner if they don't have one
 */
export const createStripeConnectAccount = onCall(async (request) => {
  // Check authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const ownerId = request.auth.uid;
  const {returnUrl, refreshUrl} = request.data;

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
      console.log(`Creating new Stripe Express account for owner ${ownerId}`);

      const account = await getStripeClient().accounts.create({
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
          platform: "rab-booking",
        },
      });

      stripeAccountId = account.id;

      // Save account ID to Firestore
      await db.collection("users").doc(ownerId).update({
        stripe_account_id: stripeAccountId,
        stripe_connected_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Stripe account ${stripeAccountId} created for owner ${ownerId}`);
    }

    // Create account link for onboarding or re-onboarding
    const accountLink = await getStripeClient().accountLinks.create({
      account: stripeAccountId,
      refresh_url: refreshUrl || returnUrl,
      return_url: returnUrl,
      type: "account_onboarding",
    });

    return {
      success: true,
      accountId: stripeAccountId,
      onboardingUrl: accountLink.url,
    };
  } catch (error: any) {
    console.error("Error creating Stripe Connect account:", error);
    throw new HttpsError(
      "internal",
      error.message || "Failed to create Stripe account"
    );
  }
});

/**
 * Cloud Function: Get Stripe Account Status
 *
 * Returns the status of owner's Stripe account
 */
export const getStripeAccountStatus = onCall(async (request) => {
  // Check authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const ownerId = request.auth.uid;

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
        const balanceData = await getStripeClient().balance.retrieve({
          stripeAccount: stripeAccountId,
        });
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
        console.error("Error fetching balance:", error);
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
    console.error("Error getting Stripe account status:", error);
    throw new HttpsError(
      "internal",
      error.message || "Failed to get account status"
    );
  }
});

/**
 * Cloud Function: Create Stripe Dashboard Link
 *
 * Creates a login link to Stripe Express Dashboard
 */
export const createStripeDashboardLink = onCall(async (request) => {
  // Check authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const ownerId = request.auth.uid;

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

    // Create login link to Stripe Express Dashboard
    const loginLink = await getStripeClient().accounts.createLoginLink(
      stripeAccountId
    );

    return {
      success: true,
      dashboardUrl: loginLink.url,
    };
  } catch (error: any) {
    console.error("Error creating Stripe dashboard link:", error);
    throw new HttpsError(
      "internal",
      error.message || "Failed to create dashboard link"
    );
  }
});

/**
 * Cloud Function: Disconnect Stripe Account
 *
 * Disconnects owner's Stripe account from the platform
 */
export const disconnectStripeAccount = onCall(async (request) => {
  // Check authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const ownerId = request.auth.uid;

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

    // Delete the account from Stripe
    await getStripeClient().accounts.del(stripeAccountId);

    // Remove from Firestore
    await db.collection("users").doc(ownerId).update({
      stripe_account_id: admin.firestore.FieldValue.delete(),
      stripe_connected_at: admin.firestore.FieldValue.delete(),
      stripe_disconnected_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Stripe account ${stripeAccountId} disconnected for owner ${ownerId}`);

    return {
      success: true,
      message: "Stripe account disconnected successfully",
    };
  } catch (error: any) {
    console.error("Error disconnecting Stripe account:", error);
    throw new HttpsError(
      "internal",
      error.message || "Failed to disconnect account"
    );
  }
});

/**
 * Cloud Function: Get Stripe Transactions
 *
 * Returns recent transactions for owner's Stripe account
 */
export const getStripeTransactions = onCall(async (request) => {
  // Check authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const ownerId = request.auth.uid;
  const {limit = 10} = request.data;

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

    // Get charges (payments) from connected account
    const charges = await getStripeClient().charges.list(
      {
        limit: limit,
      },
      {
        stripeAccount: stripeAccountId,
      }
    );

    const transactions = charges.data.map((charge) => ({
      id: charge.id,
      amount: charge.amount / 100,
      currency: charge.currency.toUpperCase(),
      status: charge.status,
      description: charge.description || "",
      created: new Date(charge.created * 1000).toISOString(),
      receiptUrl: charge.receipt_url,
    }));

    return {
      success: true,
      transactions,
      hasMore: charges.has_more,
    };
  } catch (error: any) {
    console.error("Error getting Stripe transactions:", error);
    throw new HttpsError(
      "internal",
      error.message || "Failed to get transactions"
    );
  }
});
