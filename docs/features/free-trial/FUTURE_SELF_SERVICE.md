# Future Feature Planning: Self-Service Activation & Management

This document outlines the user experience for a self-service model where users can manage their subscriptions without administrator intervention.

**Note:** This is a planning document that builds upon the "Payment Integration" plan and is **not** in the scope of the initial implementation.

---

## 1. Self-Service Activation Flow

This flow begins when a user's trial has expired.

-   **TRIAL-031.1: Upgraded "Trial Expired" Screen**
    -   The "Trial Expired" screen will be enhanced from a simple notification page to a sales/conversion page.
    -   It will clearly display:
        -   A prominent call-to-action button: "Activate Your Account" or "Choose a Plan".
        -   A pricing table comparing the available subscription tiers (e.g., Basic vs. Pro).
        -   A summary of key features for each tier.

-   **TRIAL-031.2: Checkout Process**
    1.  User clicks the "Activate" button for their desired plan.
    2.  A Cloud Function is called to create a new **Stripe Checkout Session** associated with the user's ID and the selected price ID.
    3.  The client-side application redirects the user to the secure, Stripe-hosted checkout page.
    4.  User enters their payment information and confirms the subscription.

-   **TRIAL-031.3: Post-Payment Experience**
    1.  Upon successful payment, Stripe redirects the user back to a confirmation page within the BookBed application (e.g., `/payment-success`).
    2.  Simultaneously, a Stripe webhook updates their `accountStatus` to `"active"` in the backend.
    3.  The user immediately regains full access to the dashboard.
    4.  A "Welcome" email is sent, confirming their subscription.
    5.  **Result:** The entire process is automated, requiring zero admin intervention.

## 2. Self-Service Subscription Management

Once a user has an active subscription, they will need a portal to manage it.

-   **TRIAL-031.4: Customer Portal**
    -   A new "Billing" or "Subscription" section will be added to the user's profile settings.
    -   This section will display:
        -   Their current plan.
        -   The price and billing frequency (monthly/yearly).
        -   The date of the next renewal.
        -   A list of past invoices.
    -   The easiest and most secure way to implement this is by integrating the **Stripe Customer Portal**. This is a pre-built, secure page hosted by Stripe that allows customers to manage their own subscriptions.

-   **TRIAL-031.5: Portal Actions**
    -   From the "Billing" section, a button like "Manage Subscription" will call a Cloud Function.
    -   This function will generate a unique, single-use URL for a Stripe Customer Portal session.
    -   The user is redirected to this portal, where they can:
        -   **Cancel** their subscription.
        -   **Update** their payment method.
        -   **Upgrade or downgrade** their plan.
        -   View and download their invoices.
    -   All changes made in the portal will automatically trigger webhooks that keep the Firestore user document in sync.
