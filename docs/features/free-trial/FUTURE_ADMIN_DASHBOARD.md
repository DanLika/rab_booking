# Future Feature Planning: Admin Dashboard

This document outlines the requirements for a future Admin Dashboard, designed to replace the manual Firestore Console workflow for user management.

**Note:** This is a planning document for a future phase and is **not** in the scope of the initial "Free Trial" implementation.

---

## 1. Overview

The goal of the Admin Dashboard is to provide a secure and user-friendly web interface for administrators to manage users, monitor platform activity, and configure system-level settings without needing direct access to the Firebase backend.

## 2. Core Features

-   **TRIAL-020.1: User Management Table**
    -   A searchable, sortable, and filterable table of all users on the platform.
    -   **Columns:** User ID, Display Name, Email, Account Status, Trial Expires At, Registration Date.
    -   **Filtering:** Filter by `accountStatus` (e.g., show all `trial_expired` users).
    -   **Search:** Search by email or display name.

-   **TRIAL-020.2: One-Click Status Changes**
    -   Buttons or dropdown menus next to each user to perform quick actions:
        -   **Activate:** Change status from `trial_expired` to `active`.
        -   **Suspend:** Change status to `suspended`.
        -   **Reactivate:** Change status from `suspended` to `active`.
        -   **Extend Trial:** A modal to set a new `trialExpiresAt` date.

-   **TRIAL-020.3: Bulk Actions**
    -   Ability to select multiple users (e.g., all expired trials) and apply a status change in a single operation.

-   **TRIAL-020.4: User Detail View**
    -   Clicking a user opens a detailed view showing:
        -   All user profile fields.
        -   A log of status change history (who changed it, when, and why).
        -   Basic metrics (e.g., number of properties, total bookings).

-   **TRIAL-020.5: Reporting & Metrics**
    -   A dashboard view with key platform metrics:
        -   New user registrations over time.
        -   Trial conversion rate (manual activations).
        -   Number of active vs. expired users.
        -   List of trials expiring within the next 7 days.

## 3. Future Integration with Payments (Phase 3)

-   **TRIAL-020.6: Subscription Management**
    -   The dashboard will integrate with Stripe to show subscription details.
    -   Admins will be able to:
        -   View a user's current subscription plan and status.
        -   Manually cancel a subscription.
        -   Issue refunds or credits.
        -   View payment history.

## 4. Technical & Security Considerations

-   **Access Control:** The entire dashboard must be protected by a security rule or backend check that ensures only users with the `isAdmin: true` custom claim can access it.
-   **Audit Trail:** All actions taken within the Admin Dashboard (e.g., changing a user's status) must be logged securely for auditing purposes. The `statusChangedBy` and `statusChangedAt` fields are the first step in this process.
-   **Infrastructure:** It could be built as a separate web application (e.g., using a simple framework like Vue or React) or as a protected section within the main Flutter web app.
