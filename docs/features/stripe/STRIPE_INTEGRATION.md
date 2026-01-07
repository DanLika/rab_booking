# Stripe Integration Guide

**Last Updated**: 2024-07-30
**Status**: Active & Verified

---

## Overview

This document provides a comprehensive overview of the Stripe integration for payment processing in BookBed. It details the payment flow, security measures, and webhook handling.

## Key Files

| File | Purpose |
|---|---|
| `functions/src/stripePayment.ts` | Contains the core Cloud Functions for creating Stripe Checkout sessions and handling webhooks. |
| `functions/src/stripe.ts` | Initializes the Stripe client. |
| `lib/core/services/stripe_service.dart` | Frontend service for interacting with the Stripe Cloud Functions. |

---

## Payment Flow: The "Placeholder Booking" Method

To prevent race conditions (where two users could book and pay for the same dates simultaneously), we use a "placeholder booking" flow. This ensures that dates are reserved *before* the user is redirected to Stripe for payment.

### Step-by-Step Flow

1.  **Client-Side Validation**: The booking widget validates all user inputs (dates, guest info, etc.).
2.  **Price Validation**: The client sends the booking details and the calculated price to the `createStripeCheckoutSession` Cloud Function. The function then performs a **server-side price validation** to ensure the price has not been manipulated on the client.
3.  **Atomic Transaction**:
    *   The function initiates a Firestore atomic transaction.
    *   It checks for any conflicting bookings (with `pending` or `confirmed` status) for the selected dates.
    *   If no conflicts exist, it creates a **placeholder booking** with a `pending` status and an expiration time of 15 minutes (`stripe_pending_expires_at`). This blocks the dates.
4.  **Stripe Checkout Session**:
    *   A Stripe Checkout session is created.
    *   **Crucially**, the ID of the placeholder booking is passed in the session's `metadata`.
    *   The client receives the Stripe Checkout URL and redirects the user to Stripe.
5.  **User Completes Payment**: The user enters their payment details on the Stripe-hosted page.
6.  **Stripe Webhook (`checkout.session.completed`)**:
    *   Stripe sends a webhook to our `handleStripeWebhook` Cloud Function.
    *   The function verifies the webhook signature for security.
    *   It retrieves the `placeholder_booking_id` from the session metadata.
    *   It finds the placeholder booking in Firestore and updates its status from `pending` to `confirmed`.
    *   The `stripe_pending_expires_at` field is removed, making the booking permanent.
7.  **Confirmation**: Confirmation and notification emails are sent to the guest and property owner.

### Handling Abandoned Payments

If a user abandons the Stripe Checkout page, the placeholder booking remains in the `pending` state. A scheduled Cloud Function (`cleanupExpiredPendingBookings`) runs periodically to find and delete any placeholder bookings where `stripe_pending_expires_at` is in the past, freeing up the dates.

---

## Security Measures

Several security measures are in place to protect the payment flow.

### 1. Rate Limiting

The `createStripeCheckoutSession` function is protected by rate limiting to prevent DoS attacks and abuse.
- **Limit**: 10 checkout attempts per 5 minutes per IP address.
- **Implementation**: `checkRateLimit` utility in `functions/src/utils/rateLimit.ts`.

### 2. Server-Side Price Validation

The price calculated on the client is **re-validated on the server** to prevent tampering.
- **Implementation**: `validateBookingPrice` utility in `functions/src/utils/priceValidation.ts`.
- **Behavior**: If a price mismatch is detected, the server re-calculates the correct price and uses that for the Stripe session, logging a security warning.

### 3. Return URL Whitelisting

The `returnUrl` provided by the client (where the user is redirected after payment) is validated against a strict whitelist of allowed domains to prevent open redirect vulnerabilities.
- **Implementation**: `isAllowedReturnUrl` function in `functions/src/stripePayment.ts`.
- **Allowed Domains**: `bookbed.io`, `app.bookbed.io`, `view.bookbed.io`, `*.view.bookbed.io`, and `localhost` for development.

### 4. Stripe Connect Account Verification

Before creating a checkout session, the system verifies that the property owner's Stripe Connect account is fully set up and capable of receiving payments.
- **Checks**:
    - `charges_enabled`: The account can accept charges.
    - `capabilities.card_payments === 'active'`: Card payments are enabled.
    - `capabilities.transfers === 'active'`: Transfers to a bank account are enabled.
- **Implementation**: The `stripe.accounts.retrieve` method is called within `createStripeCheckoutSession`.

### 5. Webhook Signature Verification

All incoming webhooks from Stripe are verified to ensure they are authentic.
- **Implementation**: `stripe.webhooks.constructEvent` is used in `handleStripeWebhook`.
- **Secret**: The webhook signing secret is stored as a Firebase Function secret (`STRIPE_WEBHOOK_SECRET`).

### 6. Security Monitoring

Critical security events are logged to Firestore for monitoring and alerting.
- **Events Logged**:
    - `RATE_LIMIT_EXCEEDED`
    - `INVALID_RETURN_URL`
    - `STRIPE_ACCOUNT_NOT_VERIFIED`
    - `WEBHOOK_SIGNATURE_FAILED`
- **Implementation**: `logSecurityEvent` utility in `functions/src/utils/securityMonitoring.ts`.

---

## Webhook Handling

- **Endpoint**: `handleStripeWebhook` Cloud Function.
- **Events Handled**:
    - `checkout.session.completed`: This is the primary event that confirms a successful payment and triggers the conversion of a placeholder booking to a confirmed booking.

### Idempotency

The webhook handler is idempotent. If Stripe sends the same `checkout.session.completed` event multiple times, the system checks if the booking has already been confirmed and gracefully exits, preventing duplicate processing.
