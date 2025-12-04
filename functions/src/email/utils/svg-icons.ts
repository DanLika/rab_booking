/**
 * SVG Icon Library for Emails
 *
 * Accessible SVG icons to replace emoji characters.
 * All icons are 64x64 by default for header usage.
 * Can be scaled down for inline usage.
 */

/**
 * Success/Checkmark Icon
 * Used for: Booking confirmation, payment success
 */
export function getSuccessIcon(size = 64, color = "#FFFFFF"): string {
  return `
<svg width="${size}" height="${size}" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="30" fill="rgba(255, 255, 255, 0.2)" stroke="${color}" stroke-width="2"/>
  <path d="M20 32L28 40L44 24" stroke="${color}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
  `.trim();
}

/**
 * Info/Document Icon
 * Used for: Booking details, information sections
 */
export function getInfoIcon(size = 64, color = "#FFFFFF"): string {
  return `
<svg width="${size}" height="${size}" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="30" fill="rgba(255, 255, 255, 0.2)" stroke="${color}" stroke-width="2"/>
  <path d="M32 28V44M32 20V24" stroke="${color}" stroke-width="4" stroke-linecap="round"/>
</svg>
  `.trim();
}

/**
 * Warning Icon
 * Used for: Payment pending, verification needed
 */
export function getWarningIcon(size = 64, color = "#FFFFFF"): string {
  return `
<svg width="${size}" height="${size}" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M32 8L8 54H56L32 8Z" fill="rgba(255, 255, 255, 0.2)" stroke="${color}" stroke-width="2" stroke-linejoin="round"/>
  <path d="M32 24V36M32 40V44" stroke="${color}" stroke-width="3" stroke-linecap="round"/>
</svg>
  `.trim();
}

/**
 * Error/X Icon
 * Used for: Cancellations, errors
 */
export function getErrorIcon(size = 64, color = "#FFFFFF"): string {
  return `
<svg width="${size}" height="${size}" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="30" fill="rgba(255, 255, 255, 0.2)" stroke="${color}" stroke-width="2"/>
  <path d="M22 22L42 42M42 22L22 42" stroke="${color}" stroke-width="4" stroke-linecap="round"/>
</svg>
  `.trim();
}

/**
 * Calendar Icon
 * Used for: Date reminders, check-in/check-out
 */
export function getCalendarIcon(size = 24, color = "#6B4CE6"): string {
  return `
<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="3" y="4" width="18" height="18" rx="2" stroke="${color}" stroke-width="2"/>
  <path d="M3 10H21M8 2V6M16 2V6" stroke="${color}" stroke-width="2" stroke-linecap="round"/>
</svg>
  `.trim();
}

/**
 * Money/Euro Icon
 * Used for: Payment information, pricing
 */
export function getMoneyIcon(size = 24, color = "#6B4CE6"): string {
  return `
<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" stroke="${color}" stroke-width="2"/>
  <path d="M15 8H11C9.89543 8 9 8.89543 9 10C9 11.1046 9.89543 12 11 12H13C14.1046 12 15 12.8954 15 14C15 15.1046 14.1046 16 13 16H9M12 6V8M12 16V18" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
  `.trim();
}

/**
 * Home/Property Icon
 * Used for: Property information
 */
export function getHomeIcon(size = 24, color = "#6B4CE6"): string {
  return `
<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M3 12L5 10M5 10L12 3L19 10M5 10V20C5 20.5523 5.44772 21 6 21H9M19 10L21 12M19 10V20C19 20.5523 18.5523 21 18 21H15M9 21C9.55228 21 10 20.5523 10 20V16C10 15.4477 10.4477 15 11 15H13C13.5523 15 14 15.4477 14 16V20C14 20.5523 14.4477 21 15 21M9 21H15" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
  `.trim();
}

/**
 * User/Guest Icon
 * Used for: Guest information
 */
export function getUserIcon(size = 24, color = "#6B4CE6"): string {
  return `
<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="8" r="4" stroke="${color}" stroke-width="2"/>
  <path d="M6 21V19C6 17.3431 7.34315 16 9 16H15C16.6569 16 18 17.3431 18 19V21" stroke="${color}" stroke-width="2" stroke-linecap="round"/>
</svg>
  `.trim();
}

/**
 * Email Icon
 * Used for: Contact information, email confirmations
 */
export function getEmailIcon(size = 24, color = "#6B4CE6"): string {
  return `
<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="3" y="5" width="18" height="14" rx="2" stroke="${color}" stroke-width="2"/>
  <path d="M3 7L12 13L21 7" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
  `.trim();
}

/**
 * Clock/Time Icon
 * Used for: Check-in/check-out times, reminders
 */
export function getClockIcon(size = 24, color = "#6B4CE6"): string {
  return `
<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" stroke="${color}" stroke-width="2"/>
  <path d="M12 6V12L16 14" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
  `.trim();
}

/**
 * Bell/Notification Icon
 * Used for: Reminders, notifications
 */
export function getBellIcon(size = 24, color = "#6B4CE6"): string {
  return `
<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M15 17H20L18.5951 15.5951C18.2141 15.2141 18 14.6973 18 14.1585V11C18 8.38757 16.3304 6.16509 14 5.34142V5C14 3.89543 13.1046 3 12 3C10.8954 3 10 3.89543 10 5V5.34142C7.66962 6.16509 6 8.38757 6 11V14.1585C6 14.6973 5.78595 15.2141 5.40493 15.5951L4 17H9M15 17V18C15 19.6569 13.6569 21 12 21C10.3431 21 9 19.6569 9 18V17M15 17H9" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
  `.trim();
}

/**
 * Approved/Thumbs Up Icon
 * Used for: Owner approval notifications
 */
export function getApprovedIcon(size = 64, color = "#FFFFFF"): string {
  return `
<svg width="${size}" height="${size}" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="30" fill="rgba(255, 255, 255, 0.2)" stroke="${color}" stroke-width="2"/>
  <path d="M32 20V32M32 32L38 38M32 32L26 38M20 44H44" stroke="${color}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
  `.trim();
}

/**
 * Refund/Money Back Icon
 * Used for: Refund notifications
 */
export function getRefundIcon(size = 64, color = "#FFFFFF"): string {
  return `
<svg width="${size}" height="${size}" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="30" fill="rgba(255, 255, 255, 0.2)" stroke="${color}" stroke-width="2"/>
  <path d="M24 24H40M40 24L36 20M40 24L36 28M28 32H36M28 36H36M22 40H42C43.1046 40 44 39.1046 44 38V26C44 24.8954 43.1046 24 42 24H22C20.8954 24 20 24.8954 20 26V38C20 39.1046 20.8954 40 22 40Z" stroke="${color}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
  `.trim();
}

/**
 * Get icon by name
 * Convenience function to retrieve icon by string name
 */
export function getIcon(
  name: "success" | "info" | "warning" | "error" | "calendar" | "money" |
       "home" | "user" | "email" | "clock" | "bell" | "approved" | "refund",
  size?: number,
  color?: string
): string {
  switch (name) {
    case "success": return getSuccessIcon(size, color);
    case "info": return getInfoIcon(size, color);
    case "warning": return getWarningIcon(size, color);
    case "error": return getErrorIcon(size, color);
    case "calendar": return getCalendarIcon(size, color);
    case "money": return getMoneyIcon(size, color);
    case "home": return getHomeIcon(size, color);
    case "user": return getUserIcon(size, color);
    case "email": return getEmailIcon(size, color);
    case "clock": return getClockIcon(size, color);
    case "bell": return getBellIcon(size, color);
    case "approved": return getApprovedIcon(size, color);
    case "refund": return getRefundIcon(size, color);
    default: return "";
  }
}
