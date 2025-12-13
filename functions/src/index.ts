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

// Export iCal export function (Public calendar feed)
export * from "./icalExport";

// Export iCal export management (Generate/revoke URLs)
export * from "./icalExportManagement";

// Export booking access verification functions (Booking lookup)
export * from "./verifyBookingAccess";

// Export email verification functions (OTP for guest bookings)
export * from "./emailVerification";

// Export password reset function (Custom email template)
export * from "./passwordReset";

// Export notification preferences functions (Owner email opt-out)
export * from "./notificationPreferences";

// Export guest booking cancellation function
export * from "./guestCancelBooking";

// Export resend booking email function
export * from "./resendBookingEmail";

// Export subdomain management functions
export * from "./subdomainService";

// Export cleanup scheduled functions (Stripe pending bookings)
export * from "./cleanupExpiredPendingBookings";
