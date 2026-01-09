# Business Requirements: Free Trial & Access Control

## 1. Overview

This document outlines the business requirements for implementing a 30-day free trial for new users of the BookBed platform. The goal is to allow users to experience the full functionality of the product before committing to a paid plan. This first phase focuses on manual user management after the trial period, with payment integration planned for a future phase.

## 2. Free Trial Period

-   **TRIAL-001.1: Trial Duration**
    -   All new users will receive a free trial of **30 calendar days**.
    -   The trial period begins immediately upon successful account registration.

## 3. Post-Trial Behavior

-   **TRIAL-001.2: Trial Expiration**
    -   When the 30-day trial period expires, the user's account status will change.
    -   **Dashboard Access:** The user will be blocked from accessing the main owner dashboard and all its features (e.g., creating bookings, editing properties). They will be redirected to a "Trial Expired" page.
    -   **Widget Behavior:** The user's embedded booking widget will cease to function for guests. It will display a generic "Booking unavailable" message instead of the calendar.
    -   **Data Integrity:** Existing user data, including properties, bookings, and settings, **will not be deleted**.
    -   **Read-Only Access:** The user will still be able to log in to view their existing data in a read-only mode. This includes viewing booking details and property information. Data export must remain available.

## 4. Account Reactivation

-   **TRIAL-001.3: Unblocking a User**
    -   **Phase 1 (Manual):** An administrator must manually change the user's account status in the Firestore database to restore full access.
    -   **Phase 2 (Future):** A self-service payment and subscription system will be implemented to allow users to reactivate their own accounts.

## 5. User Account Statuses

-   **TRIAL-001.4: Status Definitions**
    -   A new `accountStatus` field will be added to user profiles to manage access. The following statuses are required:
        -   `trial`: The user is within their active 30-day trial period. Full access is granted.
        -   `trial_expired`: The trial period has ended, and the user has not been manually activated. Access is restricted.
        -   `active`: The user has been approved by an admin (or, in the future, has an active subscription). Full access is granted.
        -   `suspended`: The user has been manually blocked by an administrator for any reason (e.g., terms of service violation). Access is restricted.

## 6. Phase 1 Scope and Limitations

-   **TRIAL-001.5: No Automatic Billing**
    -   This initial implementation will **not** include any automatic subscription creation or payment processing. All post-trial activations are manual.

-   **TRIAL-001.6: Admin Control**
    -   Administrators will have full control to override and manually set any user's `accountStatus` at any time.

## 7. Grace Period

-   **TRIAL-001.7: Grace Period Considerations**
    -   There will be no automatic grace period in Phase 1. Access is cut off immediately upon trial expiration. A grace period may be considered for future iterations.

## 8. User Notifications

-   **TRIAL-001.8: Expiration Notifications**
    -   Users must be notified via email and in-app notifications before their trial expires to encourage them to contact support for activation.
    -   A notification will also be sent when the trial has officially expired.
