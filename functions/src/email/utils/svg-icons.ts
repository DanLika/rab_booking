/**
 * Emoji Icon Library for Emails
 *
 * Gmail and many email clients strip SVG tags, so we use emoji instead.
 * All functions maintain the same signature for backwards compatibility.
 * Size parameter is used for font-size.
 */

/**
 * Helper to create emoji icon with consistent styling
 */
function emojiIcon(emoji: string, size = 64): string {
  return `<div style="font-size: ${size}px; line-height: 1; text-align: center;">${emoji}</div>`;
}

/**
 * Success/Checkmark Icon
 * Used for: Booking confirmation, payment success
 */
export function getSuccessIcon(size = 64, _color?: string): string {
  return emojiIcon("✅", size);
}

/**
 * Info/Document Icon
 * Used for: Booking details, information sections
 */
export function getInfoIcon(size = 64, _color?: string): string {
  return emojiIcon("ℹ️", size);
}

/**
 * Warning Icon
 * Used for: Payment pending, verification needed
 */
export function getWarningIcon(size = 64, _color?: string): string {
  return emojiIcon("⚠️", size);
}

/**
 * Error/X Icon
 * Used for: Cancellations, errors
 */
export function getErrorIcon(size = 64, _color?: string): string {
  return emojiIcon("❌", size);
}

/**
 * Calendar Icon
 * Used for: Date reminders, check-in/check-out
 */
export function getCalendarIcon(size = 24, _color?: string): string {
  return emojiIcon("📅", size);
}

/**
 * Money/Euro Icon
 * Used for: Payment information, pricing
 */
export function getMoneyIcon(size = 24, _color?: string): string {
  return emojiIcon("💰", size);
}

/**
 * Home/Property Icon
 * Used for: Property information
 */
export function getHomeIcon(size = 24, _color?: string): string {
  return emojiIcon("🏠", size);
}

/**
 * User/Guest Icon
 * Used for: Guest information
 */
export function getUserIcon(size = 24, _color?: string): string {
  return emojiIcon("👤", size);
}

/**
 * Email Icon
 * Used for: Contact information, email confirmations
 */
export function getEmailIcon(size = 24, _color?: string): string {
  return emojiIcon("✉️", size);
}

/**
 * Clock/Time Icon
 * Used for: Check-in/check-out times, reminders
 */
export function getClockIcon(size = 24, _color?: string): string {
  return emojiIcon("⏰", size);
}

/**
 * Bell/Notification Icon
 * Used for: Reminders, notifications
 */
export function getBellIcon(size = 24, _color?: string): string {
  return emojiIcon("🔔", size);
}

/**
 * Approved/Thumbs Up Icon
 * Used for: Owner approval notifications
 */
export function getApprovedIcon(size = 64, _color?: string): string {
  return emojiIcon("✅", size);
}

/**
 * Refund/Money Back Icon
 * Used for: Refund notifications
 */
export function getRefundIcon(size = 64, _color?: string): string {
  return emojiIcon("💸", size);
}

/**
 * Shield/Security Icon
 * Used for: Security alerts, suspicious activity
 */
export function getShieldIcon(size = 64, _color?: string): string {
  return emojiIcon("🛡️", size);
}

/**
 * Get icon by name
 * Convenience function to retrieve icon by string name
 */
export function getIcon(
  name: "success" | "info" | "warning" | "error" | "calendar" | "money" |
       "home" | "user" | "email" | "clock" | "bell" | "approved" | "refund" | "shield",
  size?: number,
  _color?: string
): string {
  switch (name) {
  case "success": return getSuccessIcon(size);
  case "info": return getInfoIcon(size);
  case "warning": return getWarningIcon(size);
  case "error": return getErrorIcon(size);
  case "calendar": return getCalendarIcon(size);
  case "money": return getMoneyIcon(size);
  case "home": return getHomeIcon(size);
  case "user": return getUserIcon(size);
  case "email": return getEmailIcon(size);
  case "clock": return getClockIcon(size);
  case "bell": return getBellIcon(size);
  case "approved": return getApprovedIcon(size);
  case "refund": return getRefundIcon(size);
  case "shield": return getShieldIcon(size);
  default: return "";
  }
}
