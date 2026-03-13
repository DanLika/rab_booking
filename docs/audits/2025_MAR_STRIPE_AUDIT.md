# Monthly Stripe & Payment Flow Audit - March 2025

**Date:** March 2025
**Scope:** Stripe Security, Payment Flow Integrity, Stripe Connect, Price Validation, Error Handling

## 1. Stripe Security Checks
- [x] **Webhook Signature Validation:** Verified in `functions/src/stripe.ts` (`handleStripeWebhook`). Signature is properly checked using the constructed event from rawBody.
- [x] **Secret Keys:** Verified `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` are securely loaded via Firebase `defineSecret`.
- [x] **Hardcoded Keys:** No hardcoded Stripe keys (`sk_live_`, `sk_test_`, `pk_live_`, `pk_test_`) were found in the application source code.
- [x] **Rate Limiting:** Verified `createStripeCheckoutSession` uses IP-based rate limiting (10 requests per 5 minutes).
- [x] **Minimum Amount Validation:** Verified `depositAmountInCents` is enforced to be at least `Math.max(rawDepositCents, STRIPE_MINIMUM_CENTS)` (50 cents) in `functions/src/stripePayment.ts`.

## 2. Payment Flow Integrity
- [x] **Placeholder Booking:** A placeholder booking is successfully created with status `pending` *before* Stripe checkout redirect.
- [x] **Webhook Status Update:** Webhook handler updates placeholder booking status to `confirmed` after a successful payment event (`checkout.session.completed`).
- [x] **Email & Push Notifications:** After status update to `confirmed`, `sendBookingApprovedEmail` and `sendPaymentPushNotification` are successfully triggered.
- [x] **Status Transitions:** Verified transitions (e.g. `pending` to `confirmed`, and expiration cleanup of `pending`).

## 3. Stripe Connect
- [x] **Account Verification Checks:** Stripe Connect accounts are strictly verified for `charges_enabled`, `card_payments`, and `transfers` capabilities before allowing checkouts.
- [x] **Return/Refresh URLs:** Return URL validation strictly enforces the whitelist structure, securely handling wildcards, and ensures fallbacks for the mobile app (`https://app.bookbed.io`) and widget (`https://view.bookbed.io`).
- [x] **Application Fee:** No `application_fee_amount` is defined; the platform currently takes a 0% fee and routes the full destination transfer to the owner account.

## 4. Price Validation
- [x] **Smart Threshold Logic:** Verified in `functions/src/utils/priceValidation.ts`. A Sentry alert is only triggered if the price difference is greater than €10 OR > 5%, otherwise logged locally.
- [x] **Server-calculated Prices:** Server explicitly ignores locked client pricing if a mismatch occurs and calculates the actual expected price.
- [x] **Deposit Calculation:** Logic in `functions/src/utils/depositCalculation.ts` matches widget displays and properly avoids floating point errors by utilizing integer arithmetic.

## 5. Error Handling
- [x] **Client Protection:** All external Stripe errors are safely caught, generic `HttpsError` exceptions are thrown to avoid leaking internal info to clients.
- [x] **Internal Logging:** All `catch` blocks properly use `logError()` to track specific error states in Cloud Logs.
- [x] **Failed Payments:** Abandoned or expired checkouts are efficiently purged or appropriately dealt with by standard `checkout.session.expired` handling.

**Conclusion:** All critical payment paths and Stripe interactions are highly secure and aligned with BookBed's development and security standards. No modifications to `stripePayment.ts`, `stripeConnect.ts`, or `stripe.ts` were needed. The audit passes completely.
