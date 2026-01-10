# Data Retention Policy: Free Trial Users

This document outlines the policy for handling the data of users whose free trial has expired and who have not transitioned to an active, paid status.

---

## 1. Core Principle: No Automatic Deletion

-   **TRIAL-026.1: Data Preservation**
    -   The data of a user whose status is `trial_expired` or `suspended` **will not be automatically deleted** from the system.
    -   This ensures that if a user decides to activate their account at a later date, all of their setup, bookings, and property information will be immediately available, providing a seamless reactivation experience.

## 2. Data Accessibility

-   **TRIAL-026.2: User Access**
    -   **Expired Users:** Can still log in to access their data in a **read-only** mode. They can view their properties and bookings but cannot make any modifications or new entries.
    -   **Data Export:** All users, regardless of their `accountStatus`, must have the ability to export their data in a machine-readable format (e.g., JSON), in compliance with GDPR.

-   **TRIAL-026.3: Guest Access**
    -   **Bookings:** Existing bookings made by guests remain in the system. Guests can still access their booking details via their unique booking link.
    -   **Widget:** The booking widget for an expired user will become disabled and will not show any data to the public.

## 3. Manual Deletion (GDPR Compliance)

-   **TRIAL-026.4: Right to Erasure**
    -   Any user, including those with an expired trial, can request the complete deletion of their personal data at any time, in accordance with GDPR's "Right to Erasure."
    -   This process must be handled manually by an administrator upon receiving a verified request.

## 4. Future Considerations

-   **TRIAL-026.5: Auto-Deletion Policy (Phase 2)**
    -   A future iteration of the platform may introduce an automatic data deletion policy.
    -   For example, data for users with a `trial_expired` status might be automatically deleted after a prolonged period of inactivity (e.g., 12 months).
    -   If such a policy is implemented, users must be clearly notified via email well in advance of the scheduled deletion.
    -   **This is not in scope for the initial implementation.**
