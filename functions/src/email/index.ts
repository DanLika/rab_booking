/**
 * Email Module - Centralized Export
 *
 * All email templates use minimalist design with HTML escaping for security.
 * Import from this file in emailService.ts and other modules.
 *
 * @example
 * ```ts
 * import {
 *   sendBookingConfirmationEmailV2,
 *   BookingConfirmationParams
 * } from './email';
 * ```
 */

// ==========================================
// EMAIL TEMPLATES
// ==========================================

// Booking Flow
export {
  sendBookingConfirmationEmailV2,
  generateBookingConfirmationEmailV2,
  type BookingConfirmationParams,
} from "./templates/booking-confirmation";

export {
  sendBookingApprovedEmailV2,
  generateBookingApprovedEmailV2,
  type BookingApprovedParams,
} from "./templates/booking-approved";

export {
  sendBookingRejectedEmailV2,
  generateBookingRejectedEmailV2,
  type BookingRejectedParams,
} from "./templates/booking-rejected";

export {
  sendPendingBookingRequestEmailV2,
  generatePendingBookingRequestEmailV2,
  type PendingBookingRequestParams,
} from "./templates/pending-request";

// Cancellation
export {
  sendGuestCancellationEmailV2,
  generateGuestCancellationEmailV2,
  type GuestCancellationParams,
} from "./templates/guest-cancellation";

export {
  sendOwnerCancellationEmailV2,
  generateOwnerCancellationEmailV2,
  type OwnerCancellationParamsV2,
} from "./templates/owner-cancellation";

export {
  sendRefundNotificationEmailV2,
  generateRefundNotificationEmailV2,
  type RefundNotificationParams,
} from "./templates/refund-notification";

// Reminders
export {
  sendCheckInReminderEmailV2,
  generateCheckInReminderEmailV2,
  type CheckInReminderParams,
} from "./templates/check-in-reminder";

export {
  sendCheckOutReminderEmailV2,
  generateCheckOutReminderEmailV2,
  type CheckOutReminderParams,
} from "./templates/check-out-reminder";

export {
  sendPaymentReminderEmailV2,
  generatePaymentReminderEmailV2,
  type PaymentReminderParams,
} from "./templates/payment-reminder";

// Owner Notifications
export {
  sendOwnerNotificationEmailV2,
  generateOwnerNotificationEmailV2,
  type OwnerNotificationParamsV2,
} from "./templates/owner-notification";

export {
  sendPendingOwnerNotificationEmailV2,
  generatePendingOwnerNotificationEmailV2,
  type PendingOwnerNotificationParams,
} from "./templates/pending-owner-notification";

export {
  sendOverbookingDetectedEmailV2,
  generateOverbookingDetectedEmailV2,
  type OverbookingDetectedParams,
} from "./templates/overbooking-detected";

// Auth
export {
  sendEmailVerificationEmailV2,
  generateEmailVerificationEmailV2,
  type EmailVerificationParams,
} from "./templates/email-verification";

export {
  sendPasswordResetEmailV2,
  generatePasswordResetEmailV2,
  type PasswordResetParams,
} from "./templates/password-reset";

// Custom
export {
  sendCustomGuestEmailV2,
  generateCustomGuestEmailV2,
  type CustomGuestEmailParamsV2,
} from "./templates/custom-email";

// ==========================================
// BASE TEMPLATE & STYLES
// ==========================================

export {
  generateEmailHtml,
  type BaseEmailOptions,
} from "./templates/base";

export {
  EMAIL_COLORS_LIGHT,
  EMAIL_COLORS_DARK,
  EMAIL_COLORS_NEUTRAL,
  getEmailColors,
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

// ==========================================
// SVG ICONS
// ==========================================

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

// ==========================================
// TEMPLATE HELPERS
// ==========================================

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
