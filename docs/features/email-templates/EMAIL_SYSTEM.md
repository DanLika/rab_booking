# Email System Documentation

**Last Updated**: 2024-07-30
**Status**: Active & Verified

---

## Overview

BookBed uses the Resend API for sending transactional emails. All templates use a minimalist design with HTML escaping for security and inline CSS for Gmail compatibility.

---

## Template List (16 templates)

### Booking Flow (4)
| Template | Recipient | Trigger Function | Trigger Description |
|---|---|---|---|
| `booking-confirmation.ts` | Guest | `sendBookingConfirmationEmail` | Sent after a booking is successfully created and payment is confirmed. |
| `booking-approved.ts` | Guest | `sendBookingApprovedEmail` | Sent to the guest when a property owner approves a pending booking request. |
| `booking-rejected.ts` | Guest | `sendBookingRejectedEmail` | Sent to the guest when a property owner rejects a pending booking request. |
| `pending-request.ts` | Guest | `sendPendingBookingRequestEmail` | Sent to the guest after they submit a booking request that requires owner approval. |

### Cancellation (3)
| Template | Recipient | Trigger Function | Trigger Description |
|---|---|---|---|
| `guest-cancellation.ts` | Guest | `sendGuestCancellationEmail` | Sent to the guest when they cancel a booking. |
| `owner-cancellation.ts` | Guest | `sendOwnerCancellationNotificationEmail` | Sent to the guest when the property owner cancels their booking. |
| `refund-notification.ts` | Guest | `sendRefundNotificationEmail` | Sent to the guest when a refund is processed for their booking. |

### Reminders (3)
| Template | Recipient | Trigger Function | Trigger Description |
|---|---|---|---|
| `check-in-reminder.ts` | Guest | `sendCheckInReminderEmail` | Scheduled to be sent **7 days** before the check-in date. |
| `check-out-reminder.ts` | Guest | `sendCheckOutReminderEmail` | Scheduled to be sent 1 day before the check-out date. |
| `payment-reminder.ts` | Guest | `sendPaymentReminderEmail` | Scheduled to be sent on **Day 6** of a 7-day payment window for pending bank transfer bookings. |

### Owner Notifications (3)
| Template | Recipient | Trigger Function | Trigger Description |
|---|---|---|---|
| `owner-notification.ts` | Owner | `sendOwnerNotificationEmail` | Sent to the property owner when a new booking is confirmed. |
| `pending-owner-notification.ts` | Owner | `sendPendingBookingOwnerNotification` | Sent to the property owner when a guest submits a new booking request that requires approval. |
| `overbooking-detected.ts` | Owner | `sendOverbookingDetectedEmailV2` | Sent to the property owner when a booking conflict (overbooking) is detected. |

### Auth (2)
| Template | Recipient | Trigger Function | Trigger Description |
|---|---|---|---|
| `email-verification.ts` | User | `sendEmailVerificationCode` | Sent to a new user to verify their email address during registration. |
| `password-reset.ts` | User | `sendPasswordResetEmail` | Sent to a user when they request to reset their password. |

### Custom (1)
| Template | Recipient | Trigger Function | Trigger Description |
|---|---|---|---|
| `custom-email.ts` | Any | `sendCustomGuestEmail` | Sent manually by a property owner to any email address. |

---

## Folder Structure

```
functions/src/email/
├── templates/
│   ├── base.ts
│   ├── booking-confirmation.ts
│   ├── booking-approved.ts
│   ├── booking-rejected.ts
│   ├── pending-request.ts
│   ├── guest-cancellation.ts
│   ├── owner-cancellation.ts
│   ├── refund-notification.ts
│   ├── check-in-reminder.ts
│   ├── check-out-reminder.ts
│   ├── payment-reminder.ts
│   ├── owner-notification.ts
│   ├── pending-owner-notification.ts
│   ├── overbooking-detected.ts
│   ├── email-verification.ts
│   ├── password-reset.ts
│   └── custom-email.ts
├── utils/
│   └── template-helpers.ts
├── styles/
│   └── base-styles.ts
└── index.ts
```

---

## Key Parameters & Logic

### Payment Flow
- **Payment Deadline (Bank Transfer)**: 7 days
- **Payment Reminder**: Sent on Day 6 (1 day before deadline)
- **Auto-Cancellation**: Pending bank transfer bookings are automatically cancelled if not paid within 7 days.

### Reminders
- **Check-in Reminder**: 7 days before check-in
- **Check-out Reminder**: 1 day before check-out

---

## Multi-Language Support

- **Supported Languages**:
    - `hr` (Hrvatski)
    - `en` (English)
    - `de` (Deutsch)
    - `it` (Italiano)
- **Implementation**:
    - Owner Dashboard emails support `hr` and `en`.
    - Guest-facing widget emails support all four languages.
    - Language is determined by the `lang` URL parameter, browser settings, or defaults to `hr`.

---

## Security: HTML Escaping

**CRITICAL**: All user-provided content **MUST** be escaped to prevent XSS vulnerabilities. The `escapeHtml` utility is used for this purpose.

```typescript
import { escapeHtml } from "../utils/template-helpers";

// ✅ CORRECT
const html = `<div>${escapeHtml(guestName)}</div>`;

// ❌ WRONG
const html = `<div>${guestName}</div>`;
```

- **What is escaped**: Guest names, owner names, booking references, property/unit names, contact info, reasons for cancellation/rejection, and all other user-generated input.

---

## Design Standards

- **Philosophy**: Minimalist, flat design. No gradients or shadows. Sharp edges with minimal `border-radius`.
- **Colors**: A neutral color palette is used for consistency. See `base-styles.ts` for details.

---

## Template Anatomy & Helper Functions

Templates are constructed using a set of reusable helper functions from `template-helpers.ts`. This ensures consistency and simplifies template creation.

- **Structure**: Each template file exports a `generate...Email` function that builds the HTML and a `send...Email` function that sends it via Resend.
- **Key Helpers**: `generateEmailHtml`, `generateHeader`, `generateCard`, `generateButton`, `generateDetailsTable`, etc.

---

## Related Files

| File | Purpose |
|---|---|
| `functions/src/emailService.ts` | Contains the core logic for sending most emails. |
| `functions/src/passwordReset.ts` | Handles the trigger for the password reset email. |
| `functions/src/overbookingNotifications.ts`| Handles the trigger for the overbooking detected email. |
| `functions/src/emailNotificationHelper.ts` | Manages user notification preferences. |
| `functions/src/email/index.ts` | Central export for all email templates and functions. |
