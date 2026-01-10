import type Stripe from "stripe";
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
 */
export function getStripeClient(): Stripe {
  if (!stripe) {
    const apiKey = stripeSecretKey.value();
    if (!apiKey) {
      throw new Error("STRIPE_SECRET_KEY not configured");
    }
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const StripeClass = require("stripe");
    stripe = new StripeClass(apiKey, {
      apiVersion: "2025-09-30.clover",
    });
  }
  return stripe as Stripe;
}
