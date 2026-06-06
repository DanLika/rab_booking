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
// v22 split the namespace: `Stripe` is the callable constructor
// (StripeConstructor) and `Stripe.Stripe` is the class — the latter is
// needed in type position.
let stripe: Stripe.Stripe | null = null;

// F-70-01: bookbed-dev us-central1 Cloud Run runs with Sentry init'd
// (SENTRY_DSN set), and @sentry/node v10's OpenTelemetry HTTP
// auto-instrumentation patches node:https in a way that breaks Stripe
// SDK's default NodeHttpClient — every Stripe call retries 2x then throws
// StripeConnectionError, while raw https.request from the same Cloud Run
// instance returns 200 OK. PROD escapes today only because SENTRY_DSN
// is unset there (audit/74 §1), but the moment PROD wires up Sentry the
// payment CFs would break identically.
//
// Fix: use Stripe.createFetchHttpClient — the SDK's fetch-based client
// goes through global fetch (undici) instead of node:https, bypassing
// the Sentry monkey-patch. Tested on dev: getStripeAccountStatus now
// returns 200 with full account data; createStripeCheckoutSession reaches
// the charges_enabled gate as designed (audit/74 §4).
// Tradeoff: we lose per-request timeout granularity in older Node
// versions; mitigated by Stripe SDK's own `timeout` option.
const stripeHttpClient = Stripe.createFetchHttpClient();

/**
 * Get or initialize Stripe instance
 * @return {Stripe.Stripe} The shared Stripe client instance
 */
export function getStripeClient(): Stripe.Stripe {
  if (!stripe) {
    const apiKey = stripeSecretKey.value();
    if (!apiKey) {
      throw new Error("STRIPE_SECRET_KEY not configured");
    }

    // Pin Stripe API to "2025-09-30.clover" — matches the PROD webhook
    // endpoint api_version (audit/68, [[stripe-webhook-api-version-immutable]])
    // v22 SDK narrows the type to the latest dahlia version; cast keeps the
    // legacy pin without changing server-side schema.
    stripe = new Stripe(apiKey, {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      apiVersion: "2025-09-30.clover" as any,
      httpClient: stripeHttpClient,
    });
  }
  return stripe;
}
