# Future Feature Planning: Payment Integration

This document outlines the high-level plan for integrating a payment and subscription system, which will serve as Phase 2 of the "Free Trial & Access Control" feature.

**Note:** This is a planning document for a future phase and is **not** in the scope of the initial implementation.

---

## 1. Overview

The goal is to transition from a manual, admin-gated activation system to a fully automated, self-service subscription model. This will allow users to activate their accounts by purchasing a subscription plan directly within the application.

## 2. Subscription Tiers & Billing

-   **TRIAL-030.1: Proposed Tiers**
    -   **Free/Hobby:** (Optional) A perpetually free but heavily feature-limited tier.
    -   **Basic:** The standard tier, offering all core features currently available.
    -   **Pro:** An advanced tier with premium features (e.g., advanced analytics, channel manager integrations).

-   **TRIAL-030.2: Billing Cycles**
    -   **Monthly:** A standard recurring monthly payment.
    -   **Yearly:** A recurring annual payment, offered at a discount to incentivize long-term commitment.

## 3. Technology Stack

-   **TRIAL-030.3: Payment Provider**
    -   **Stripe Subscriptions** will be the primary payment provider due to its robust API, developer-friendly documentation, and built-in support for recurring billing.

## 4. User Flow & Core Logic

-   **TRIAL-030.4: Payment Flow**
    1.  A user with an expired trial is presented with a choice of subscription plans on the "Trial Expired" screen.
    2.  Upon selecting a plan, the user is redirected to a **Stripe Checkout** session.
    3.  The user enters their payment details on the secure, Stripe-hosted page.
    4.  Upon successful payment, a **Stripe webhook** (`checkout.session.completed`) is sent to a dedicated Cloud Function.
    5.  The webhook handler verifies the event and updates the user's `accountStatus` in Firestore to `"active"`. It also stores the `stripeCustomerId` and `subscriptionId` on the user's document.

-   **TRIAL-030.5: Subscription Management**
    -   **Cancellation:** Users will be able to cancel their subscription from their profile settings. The cancellation will take effect at the end of the current billing period. A webhook (`customer.subscription.deleted`) will update their `accountStatus` back to `trial_expired` (or a new `cancelled` status).
    -   **Payment Failures:** Stripe's built-in "Smart Retries" will handle temporary payment failures. A webhook (`invoice.payment_failed`) will be used to notify the user and, after a configurable number of failures, their status will be changed to `suspended`.
    -   **Plan Changes:** Users will be able to upgrade or downgrade between tiers. Stripe will handle the proration logic automatically.

## 5. Firestore Schema Additions

The `users/{userId}` document will be extended to include:

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `stripeCustomerId` | `string` | The user's unique customer ID in Stripe. |
| `subscriptionId` | `string` | The ID of their active Stripe subscription. |
| `subscriptionStatus` | `string` | The current status of the subscription (e.g., `active`, `past_due`). |
| `currentPlanId` | `string` | The ID of the product/plan they are subscribed to. |
