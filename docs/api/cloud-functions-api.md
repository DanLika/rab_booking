# Cloud Functions API Reference

This document provides a reference for the public-facing, callable Cloud Functions used in the application.

---

## `createBookingAtomic`

Creates a new booking while ensuring that the requested dates are available. This function uses a Firestore transaction to prevent double bookings.

**Request Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `unitId` | `string` | Yes | The ID of the rental unit to be booked. |
| `propertyId` | `string` | Yes | The ID of the property that the unit belongs to. |
| `checkIn` | `string` | Yes | The check-in date in `YYYY-MM-DD` format. |
| `checkOut` | `string` | Yes | The check-out date in `YYYY-MM-DD` format. |
| `guestName` | `string` | Yes | The full name of the guest. |
| `guestEmail` | `string` | Yes | The email address of the guest. |
| `guestPhone` | `string` | No | The phone number of the guest. |
| `guestCount` | `number` | Yes | The number of guests. |
| `totalPrice` | `number` | Yes | The total price for the booking. |
| `paymentMethod` | `string` | Yes | The selected payment method. Can be `stripe`, `bank_transfer`, or `pay_on_arrival`. |
| `paymentOption` | `string` | Yes | The selected payment option. Can be `deposit` or `full`. |
| `requireOwnerApproval`| `boolean`| No | If `true`, the booking will be created with a `pending` status. Defaults to `false`. |
| `notes` | `string` | No | Any additional notes or requests from the guest. |
| `idempotencyKey` | `string` | No | A unique key to prevent duplicate bookings on retries. Recommended for all client calls. |

**Success Response:**

```json
{
  "success": true,
  "bookingId": "...",
  "bookingReference": "...",
  "status": "pending" | "confirmed",
  "paymentStatus": "pending" | "not_required",
  "message": "..."
}
```

**Error Codes:**

| Code | Message | Description |
|---|---|---|
| `invalid-argument` | Invalid booking data. | One or more required fields are missing or invalid. |
| `not-found` | Property not found. | The provided `propertyId` does not exist. |
| `failed-precondition` | Property configuration error. | The property is missing an owner or has other configuration issues. |
| `resource-exhausted` | Too many booking attempts. | The user has exceeded the rate limit for creating bookings. |
| `already-exists` | Dates no longer available. | Another booking was confirmed for the selected dates during the booking process. |
| `permission-denied` | Payment method not enabled. | The selected payment method is not enabled for this property. |
| `internal` | Failed to create booking. | An unexpected server error occurred. |

---

## `verifyBookingAccess`

Verifies a guest's access to a booking's details. Access can be verified in two ways:

1.  **With an Access Token:** By providing the `bookingReference`, `email`, and a valid `accessToken` (typically from a secure link in a confirmation email).
2.  **Without an Access Token:** By providing only the `bookingReference` and `email` for a manual lookup.

**Request Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `bookingReference` | `string` | Yes | The unique reference code for the booking (e.g., `BK-2024-123456`). |
| `email` | `string` | Yes | The email address of the guest who made the booking. |
| `accessToken` | `string` | No | A secure token that grants temporary access to the booking details. |

**Success Response:**

Returns a comprehensive booking object with all relevant details.

```json
{
  "success": true,
  "booking": {
    "bookingId": "...",
    "bookingReference": "...",
    "propertyName": "...",
    "unitName": "...",
    "guestName": "...",
    "guestEmail": "...",
    "checkIn": "...",
    "checkOut": "...",
    "totalPrice": "...",
    "status": "...",
    // ... and other details
  }
}
```

**Error Codes:**

| Code | Message | Description |
|---|---|---|
| `invalid-argument` | Booking reference and email are required. | One or both of the required fields are missing. |
| `not-found` | Booking not found. | The provided `bookingReference` does not exist. |
| `permission-denied` | Email does not match booking records. | The provided `email` does not match the email on the booking. |
| `permission-denied` | Invalid or expired access link. | The provided `accessToken` is invalid or has expired. |
| `internal` | Failed to verify booking access. | An unexpected server error occurred. |

---

## `guestCancelBooking`

Allows a guest to cancel their own booking, provided the cancellation is within the allowed time frame.

**Request Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `bookingId` | `string` | Yes | The ID of the booking to be canceled. |
| `bookingReference` | `string` | Yes | The unique reference code for the booking. |
| `guestEmail` | `string` | Yes | The email address of the guest who made the booking. |

**Success Response:**

```json
{
  "success": true,
  "message": "Booking cancelled successfully. You will receive a confirmation email shortly.",
  "bookingReference": "...",
  "cancelledAt": "..."
}
```

**Error Codes:**

| Code | Message | Description |
|---|---|---|
| `invalid-argument` | Missing required fields. | One or more of the required fields are missing. |
| `not-found` | Booking not found. | The provided `bookingId` does not exist. |
| `permission-denied` | Invalid booking reference or email. | The provided credentials do not match the booking records. |
| `failed-precondition` | Cannot cancel booking with status: ... | The booking is not in a cancellable state (e.g., it has already been completed or canceled). |
| `failed-precondition` | Cancellation deadline has passed. | The time for guest cancellations has expired. |
| `internal` | Failed to cancel booking. | An unexpected server error occurred. |

---
