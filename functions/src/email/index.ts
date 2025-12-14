/**
 * Email Module - Centralized Export
 *
 * Exports all email template functions and utilities.
 * Import from this file in emailService.ts and other modules.
 *
 * @example
 * ```ts
 * import {
 *   sendBookingConfirmationEmail,
 *   BookingConfirmationParams
 * } from './email';
 * ```
 */

// Template functions
export {
  sendBookingConfirmationEmail,
  generateBookingConfirmationEmail,
  type BookingConfirmationParams,
} from "./templates/version-1/booking-confirmation";

export {
  sendBookingConfirmationEmailV2,
  generateBookingConfirmationEmailV2,
} from "./templates/version-2/booking-confirmation-v2";

export {
  sendBookingApprovedEmail,
  generateBookingApprovedEmail,
  type BookingApprovedParams,
} from "./templates/version-1/booking-approved";

export {
  sendBookingApprovedEmailV2,
  generateBookingApprovedEmailV2,
} from "./templates/version-2/booking-approved-v2";

export {
  sendGuestCancellationEmail,
  sendOwnerCancellationEmail,
  sendRefundNotificationEmail,
  generateGuestCancellationEmail,
  generateOwnerCancellationEmail,
  generateRefundNotificationEmail,
  type GuestCancellationParams,
  type OwnerCancellationParams,
  type RefundNotificationParams,
} from "./templates/version-1/cancellation";

export {
  sendGuestCancellationEmailV2,
  generateGuestCancellationEmailV2,
} from "./templates/version-2/guest-cancellation-v2";

export {
  sendRefundNotificationEmailV2,
  generateRefundNotificationEmailV2,
} from "./templates/version-2/refund-notification-v2";

export {
  sendOwnerNotificationEmail,
  generateOwnerNotificationEmail,
  type OwnerNotificationParams,
} from "./templates/version-1/owner-notification";

export {
  sendPendingBookingRequestEmailV2,
  generatePendingBookingRequestEmailV2,
  type PendingBookingRequestParams,
} from "./templates/version-2/pending-request-v2";

export {
  sendPaymentReminderEmail,
  sendCheckInReminderEmail,
  sendCheckOutReminderEmail,
  generatePaymentReminderEmail,
  generateCheckInReminderEmail,
  generateCheckOutReminderEmail,
  type PaymentReminderParams,
  type CheckInReminderParams,
  type CheckOutReminderParams,
} from "./templates/version-1/reminder";

export {
  sendPaymentReminderEmailV2,
  generatePaymentReminderEmailV2,
} from "./templates/version-2/payment-reminder-v2";

export {
  sendCheckInReminderEmailV2,
  generateCheckInReminderEmailV2,
} from "./templates/version-2/check-in-reminder-v2";

export {
  sendCheckOutReminderEmailV2,
  generateCheckOutReminderEmailV2,
} from "./templates/version-2/check-out-reminder-v2";

export {
  sendCustomGuestEmail,
  generateCustomGuestEmail,
  type CustomGuestEmailParams,
} from "./templates/version-1/custom-email";

export {
  sendEmailVerificationEmailV2,
  generateEmailVerificationEmailV2,
  type EmailVerificationParams,
} from "./templates/version-2/email-verification-v2";

export {
  sendPendingOwnerNotificationEmailV2,
  generatePendingOwnerNotificationEmailV2,
  type PendingOwnerNotificationParams,
} from "./templates/version-2/pending-owner-notification-v2";

export {
  sendBookingRejectedEmailV2,
  generateBookingRejectedEmailV2,
  type BookingRejectedParams,
} from "./templates/version-2/booking-rejected-v2";

export {
  sendSuspiciousActivityEmailV2,
  generateSuspiciousActivityEmailV2,
  type SuspiciousActivityParams,
} from "./templates/version-2/suspicious-activity-v2";

export {
  sendPasswordResetEmailV2,
  generatePasswordResetEmailV2,
  type PasswordResetParams,
} from "./templates/version-2/password-reset-v2";

export {
  sendOverbookingDetectedEmailV2,
  generateOverbookingDetectedEmailV2,
  type OverbookingDetectedParams,
} from "./templates/version-2/overbooking-detected-v2";

// Base template
export {
  generateEmailHtml,
  type BaseEmailOptions,
} from "./templates/base";

// Styles
export {
  EMAIL_COLORS_LIGHT,
  EMAIL_COLORS_DARK,
  EMAIL_COLORS_NEUTRAL,
  getEmailColors,
  LEGACY_COLORS,
  type EmailColorScheme,
} from "./styles/colors";

export {
  DESIGN_TOKENS_PREMIUM,
  DESIGN_TOKENS_REFINED,
  getDesignTokens,
  getCardStyles,
  getButtonStyles,
  getTypographyStyles,
  type DesignTokens,
} from "./styles/design-tokens";

export {
  getBaseStyles,
  getBaseHtmlWrapper,
} from "./styles/base-styles";

export {
  getComponentStyles,
} from "./styles/components";

// SVG Icons
export {
  getSuccessIcon,
  getInfoIcon,
  getWarningIcon,
  getErrorIcon,
  getCalendarIcon,
  getMoneyIcon,
  getHomeIcon,
  getUserIcon,
  getEmailIcon,
  getClockIcon,
  getBellIcon,
  getApprovedIcon,
  getRefundIcon,
  getIcon,
} from "./utils/svg-icons";

// Template helpers
export {
  escapeHtml,
  formatCurrency,
  formatDate,
  formatDateRange,
  calculateNights,
  generateHeader,
  generateCard,
  generateDetailsTable,
  generateButton,
  generateAlert,
  generateBadge,
  generateDivider,
  generateFooter,
  generateGreeting,
  generateIntro,
  generateBookingDetailsCard,
  generatePaymentDetailsCard,
  wrapEmailContent,
  type HeaderOptions,
  type DetailRow,
  type ButtonOptions,
  type AlertOptions,
  type BadgeType,
  type FooterOptions,
  type BookingDetails,
  type PaymentDetails,
} from "./utils/template-helpers";
