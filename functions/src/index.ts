/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// Initialize Sentry for error tracking (must be first)
import { initSentry } from "./sentry";
initSentry();

// Export booking management functions
export * from "./bookingManagement";

// Export atomic booking function (prevents race conditions)
export * from "./atomicBooking";

// Export Stripe payment functions
export * from "./stripePayment";

// Export Stripe Connect functions
export * from "./stripeConnect";

// Export Stripe Subscription functions
export * from "./stripeSubscription";

// Export custom email functions (Phase 2)
export * from "./customEmail";

// Export iCal sync functions (Overbooking prevention)
// Note: Scheduled function removed, only manual sync available
export * from "./icalSync";

// Export iCal export function (Public calendar feed)
export * from "./icalExport";

// REMOVED: icalExportManagement - generateIcalExportUrl & revokeIcalExportUrl not used in Dart code

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

// Export update booking token expiration function
export * from "./updateBookingTokenExpiration";

// Export resend booking email function (for owners - requires auth)
export * from "./resendBookingEmail";

// Export resend guest booking email function (for guests - no auth required)
export * from "./resendGuestBookingEmail";

// Export subdomain management functions
export * from "./subdomainService";

// Export cleanup scheduled functions (Stripe pending bookings)
export * from "./cleanupExpiredPendingBookings";

// Export payment deadline checker scheduler
export * from "./bookings/checkPaymentDeadlines";

// Export auto-complete scheduled function (Checked-out bookings)
export * from "./completeCheckedOutBookings";

// Export Booking.com API integration functions
export * from "./bookingComApi";

// Export Airbnb API integration functions
export * from "./airbnbApi";

// Export two-way sync engine
export * from "./twoWaySync";

// Export overbooking notifications
export * from "./overbookingNotifications";

// Export SMS service
export * from "./smsService";

// Export external booking notifications
export * from "./externalBookingNotifications";

// Export sync reminders
export * from "./syncReminders";

// Export authentication rate limiting (IP-based)
export * from "./authRateLimit";

// Export password history management
export * from "./passwordHistory";

// Export token revocation (logout from all devices)
export * from "./revokeTokens";

// Export account deletion (App Store compliance requirement)
export * from "./deleteUserAccount";

// Export unit management (cascade delete on unit deletion)
export * from "./unitManagement";

// Export property management (cascade delete on property deletion)
export * from "./propertyManagement";

// REMOVED: migrations/migrateToSubcollections - One-time migration complete, no longer needed

// Export user creation trigger for trial initialization
export * from "./auth/onUserCreate";

// Export migration scripts
export * from "./migrations/migrateTrialStatus";

// Export trial management functions
export * from "./trial/checkTrialExpiration";
export * from "./trial/sendTrialExpirationWarning";

// Export admin functions
export * from "./admin/updateUserStatus";
