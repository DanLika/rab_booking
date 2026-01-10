# User Journey: Free Trial & Access Control

This document outlines the user's journey from registration through the trial period, expiration, and potential reactivation.

## 1. Registration & Trial Initiation

-   **TRIAL-002.1: New User Registration**
    1.  A new user discovers BookBed and decides to register.
    2.  They complete the standard registration form (email, password).
    3.  Upon successful account creation, their user profile in Firestore is automatically populated with the following trial-related fields:
        -   `accountStatus` is set to `"trial"`.
        -   `trialStartDate` is set to the current timestamp of registration.
        -   `trialExpiresAt` is calculated and set to `trialStartDate + 30 days`.
    4.  The user is logged in and directed to the dashboard, beginning their full-featured trial experience.

## 2. During the 30-Day Trial

-   **TRIAL-002.2: Full Access Period**
    1.  The user has unrestricted access to all features of the BookBed platform.
    2.  (Optional) A subtle, non-intrusive badge or indicator is displayed in the main navigation (e.g., sidebar/drawer) showing the number of days remaining in their trial (e.g., "Trial: 25 days left"). This indicator may change color as the expiration date nears.

## 3. Trial Nearing Expiration

-   **TRIAL-002.3: Warning Period (7 days before expiration)**
    1.  When there are 7 days left in the trial, the user receives the first automated notification.
    2.  **Email:** An email is sent to their registered address with the subject "Your trial is ending soon," explaining what will happen and how to contact support to keep the account active.
    3.  **In-App Notification:** A persistent banner appears at the top of the dashboard, reinforcing the email's message.
    4.  **UI Indicator:** The trial indicator in the UI may turn yellow or become more prominent.
    5.  Similar notifications are sent at the 3-day and 1-day marks.

## 4. Trial Expiration

-   **TRIAL-002.4: Access is Restricted**
    1.  On the 31st day, a scheduled function runs and updates the user's `accountStatus` from `"trial"` to `"trial_expired"`.
    2.  The next time the user tries to access a protected page on the dashboard (or upon their next login), the system checks their status.
    3.  **Redirection:** They are immediately redirected to a dedicated "Trial Expired" screen.
    4.  **Blocked Access:** They can no longer access any core dashboard features (calendar, properties, etc.).
    5.  **Widget Disabled:** Simultaneously, their public-facing booking widget stops working and displays a generic "unavailable" message to potential guests.
    6.  **Guidance:** The "Trial Expired" screen clearly explains what has happened and provides clear instructions on how to contact an administrator to reactivate their account. A logout button is present.

## 5. Post-Trial: Admin Activation

-   **TRIAL-002.5: Manual Reactivation**
    1.  The user contacts the BookBed admin via email as instructed.
    2.  The admin verifies the user and navigates to the Firestore console.
    3.  The admin manually updates the user's document, changing the `accountStatus` from `"trial_expired"` to `"active"`.
    4.  The user is notified (manually by admin, or via an automated "Welcome Back" email).
    5.  The user can now log in again and immediately regains full access to the dashboard and all its features. Their widget becomes functional again.
