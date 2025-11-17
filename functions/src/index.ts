/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// Export booking management functions
export * from "./bookingManagement";

// Export atomic booking function (prevents race conditions)
export * from "./atomicBooking";

// Export Stripe payment functions
export * from "./stripePayment";

// Export Stripe Connect functions
export * from "./stripeConnect";

// Export custom email functions (Phase 2)
export * from "./customEmail";

// Export security alert functions (Phase 3)
export * from "./securityEmail";

// Export iCal sync functions (Overbooking prevention)
// Note: Scheduled function removed, only manual sync available
export * from "./icalSync";

// Export cleanup functions for abandoned Stripe bookings
export * from "./cleanupAbandonedBookings";

// Export booking access verification functions (Booking lookup)
export * from "./verifyBookingAccess";

// Export email verification functions (OTP for guest bookings)
export * from "./emailVerification";

// Export widget configuration setup function
export * from "./setupWidgetConfig";

// Export guest booking cancellation function
export * from "./guestCancelBooking";
