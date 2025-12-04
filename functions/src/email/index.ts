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
} from "./templates/booking-confirmation";

export {
  sendBookingConfirmationEmailV2,
  generateBookingConfirmationEmailV2,
} from "./templates/booking-confirmation-v2";

export {
  sendBookingApprovedEmail,
  generateBookingApprovedEmail,
  type BookingApprovedParams,
} from "./templates/booking-approved";

export {
  sendBookingApprovedEmailV2,
  generateBookingApprovedEmailV2,
} from "./templates/booking-approved-v2";

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
} from "./templates/cancellation";

export {
  sendGuestCancellationEmailV2,
  generateGuestCancellationEmailV2,
} from "./templates/guest-cancellation-v2";

export {
  sendRefundNotificationEmailV2,
  generateRefundNotificationEmailV2,
} from "./templates/refund-notification-v2";

export {
  sendOwnerNotificationEmail,
  generateOwnerNotificationEmail,
  type OwnerNotificationParams,
} from "./templates/owner-notification";

export {
  sendPendingBookingRequestEmailV2,
  generatePendingBookingRequestEmailV2,
  type PendingBookingRequestParams,
} from "./templates/pending-request-v2";

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
} from "./templates/reminder";

export {
  sendPaymentReminderEmailV2,
  generatePaymentReminderEmailV2,
} from "./templates/payment-reminder-v2";

export {
  sendCheckInReminderEmailV2,
  generateCheckInReminderEmailV2,
} from "./templates/check-in-reminder-v2";

export {
  sendCheckOutReminderEmailV2,
  generateCheckOutReminderEmailV2,
} from "./templates/check-out-reminder-v2";

export {
  sendCustomGuestEmail,
  generateCustomGuestEmail,
  type CustomGuestEmailParams,
} from "./templates/custom-email";

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
