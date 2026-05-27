import Stripe from "stripe";
import {defineSecret} from "firebase-functions/params";

/**
 * Shared Stripe client initialization
 *
 * This file ensures Stripe is initialized only once across all modules.
 * Both stripePayment.ts and stripeConnect.ts import from here.
 */

// Define the secret
export const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

// Initialize Stripe (lazy initialization to avoid deployment errors)
let stripe: Stripe | null = null;

/**
 * Get or initialize Stripe instance
 *
 * SF-040: defense-in-depth prefix assertion. A misconfigured Secret Manager
 * value (sk_live_* on dev, sk_test_* on prod) would silently route real
 * charges to the wrong account. We assert the prefix matches the project
 * before the first Stripe call so the failure is loud and immediate.
 * Analog of the Dart kDebugMode Firebase project-ID assert in
 * .claude/rules/ios-development.md.
 */
export function getStripeClient(): Stripe {
  if (!stripe) {
    const apiKey = stripeSecretKey.value();
    if (!apiKey) {
      throw new Error("STRIPE_SECRET_KEY not configured");
    }

    // SF-040: project-aware prefix check.
    const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
    if (projectId) {
      const isProd = projectId === "rab-booking-248fc";
      const expectedPrefix = isProd ? "sk_live_" : "sk_test_";
      if (!apiKey.startsWith(expectedPrefix)) {
        // Do NOT log the key itself, even partially — the mismatch is the
        // signal; the secret should never appear in logs / Sentry.
        throw new Error(
          `STRIPE_SECRET_KEY mode mismatch: project=${projectId} expects ${expectedPrefix}*`
        );
      }
    }

    stripe = new Stripe(apiKey, {
      apiVersion: "2025-09-30.clover",
    });
  }
  return stripe;
}
