/**
 * Email Module - Centralized Export
 *
 * All email templates are V2 (Refined Premium minimalist design).
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
// V2 EMAIL TEMPLATES (Refined Premium)
// ==========================================

export {
  sendBookingConfirmationEmailV2,
  generateBookingConfirmationEmailV2,
  type BookingConfirmationParams,
} from "./templates/version-2/booking-confirmation-v2";

export {
  sendBookingApprovedEmailV2,
  generateBookingApprovedEmailV2,
  type BookingApprovedParams,
} from "./templates/version-2/booking-approved-v2";

export {
  sendGuestCancellationEmailV2,
  generateGuestCancellationEmailV2,
  type GuestCancellationParams,
} from "./templates/version-2/guest-cancellation-v2";

export {
  sendRefundNotificationEmailV2,
  generateRefundNotificationEmailV2,
  type RefundNotificationParams,
} from "./templates/version-2/refund-notification-v2";

export {
  sendOwnerNotificationEmailV2,
  generateOwnerNotificationEmailV2,
  type OwnerNotificationParamsV2,
} from "./templates/version-2/owner-notification-v2";

export {
  sendOwnerCancellationEmailV2,
  generateOwnerCancellationEmailV2,
  type OwnerCancellationParamsV2,
} from "./templates/version-2/owner-cancellation-v2";

export {
  sendCustomGuestEmailV2,
  generateCustomGuestEmailV2,
  type CustomGuestEmailParamsV2,
} from "./templates/version-2/custom-email-v2";

export {
  sendPendingBookingRequestEmailV2,
  generatePendingBookingRequestEmailV2,
  type PendingBookingRequestParams,
} from "./templates/version-2/pending-request-v2";

export {
  sendPaymentReminderEmailV2,
  generatePaymentReminderEmailV2,
  type PaymentReminderParams,
} from "./templates/version-2/payment-reminder-v2";

export {
  sendCheckInReminderEmailV2,
  generateCheckInReminderEmailV2,
  type CheckInReminderParams,
} from "./templates/version-2/check-in-reminder-v2";

export {
  sendCheckOutReminderEmailV2,
  generateCheckOutReminderEmailV2,
  type CheckOutReminderParams,
} from "./templates/version-2/check-out-reminder-v2";

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
