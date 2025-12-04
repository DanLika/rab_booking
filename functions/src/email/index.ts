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
  sendBookingApprovedEmail,
  generateBookingApprovedEmail,
  type BookingApprovedParams,
} from "./templates/booking-approved";

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
  sendOwnerNotificationEmail,
  generateOwnerNotificationEmail,
  type OwnerNotificationParams,
} from "./templates/owner-notification";

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
  LEGACY_COLORS,
  type EmailColorScheme,
} from "./styles/colors";

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
