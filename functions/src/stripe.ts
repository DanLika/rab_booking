import Stripe from "stripe";

/**
 * Shared Stripe client initialization
 *
 * This file ensures Stripe is initialized only once across all modules.
 * Both stripePayment.ts and stripeConnect.ts import from here.
 */

// Initialize Stripe (lazy initialization to avoid deployment errors)
let stripe: Stripe | null = null;

/**
 * Get or initialize Stripe instance
 */
export function getStripeClient(): Stripe {
  if (!stripe) {
    const apiKey = process.env.STRIPE_SECRET_KEY || "";
    if (!apiKey) {
      throw new Error("STRIPE_SECRET_KEY not configured");
    }
    stripe = new Stripe(apiKey, {
      apiVersion: "2025-09-30.clover",
    });
  }
  return stripe;
}
