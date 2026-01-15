/**
 * Email Service - Refactored with Modern Templates
 *
 * This service provides email sending functionality using modular templates.
 * All email designs are located in ./email/templates/
 *
 * MIGRATION STATUS:
 * ✅ sendBookingConfirmationEmail - Migrated to V2 template (Refined Premium)
 * ✅ sendBookingApprovedEmail - Migrated to V2 template (Refined Premium)
 * ✅ sendOwnerNotificationEmail - Migrated to V2 template (Refined Premium)
 * ✅ sendGuestCancellationEmail - Migrated to V2 template (Refined Premium)
 * ✅ sendOwnerCancellationNotificationEmail - Migrated to V2 template (Refined Premium)
 * ✅ sendRefundNotificationEmail - Migrated to V2 template (Refined Premium)
 * ✅ sendCustomGuestEmail - Migrated to V2 template (Refined Premium)
 * ✅ sendPaymentReminderEmail - Migrated to V2 template (Refined Premium)
 * ✅ sendCheckInReminderEmail - Migrated to V2 template (Refined Premium)
 * ✅ sendCheckOutReminderEmail - Migrated to V2 template (Refined Premium)
 * ✅ sendPendingBookingRequestEmail - Migrated to V2 template (Refined Premium)
 * ✅ sendEmailVerificationCode - Migrated to V2 template (Refined Premium)
 * ✅ sendPendingBookingOwnerNotification - Migrated to V2 template (Refined Premium)
 * ✅ sendBookingRejectedEmail - Migrated to V2 template (Refined Premium)
 *
 * ALL EMAIL FUNCTIONS FULLY MIGRATED! 🎉
 *
 * TODO: Suspicious Activity Email (deferred for future implementation)
 */

import { Resend } from "resend";
import { db } from "./firebase";
import { logError, logSuccess } from "./logger";

// Import new email templates (V2 - OPCIJA A: Refined Premium)
import { escapeHtml } from "./email/utils/template-helpers";
import {
  sendBookingConfirmationEmailV2,
  sendPendingBookingRequestEmailV2,
  sendBookingApprovedEmailV2,
  sendGuestCancellationEmailV2,
  sendRefundNotificationEmailV2,
  sendPaymentReminderEmailV2,
  sendCheckInReminderEmailV2,
  sendCheckOutReminderEmailV2,
  sendOwnerCancellationEmailV2,
  sendOwnerNotificationEmailV2,
  sendCustomGuestEmailV2,
  type BookingConfirmationParams,
  type PendingBookingRequestParams,
  type BookingApprovedParams,
  type GuestCancellationParams,
  type OwnerCancellationParamsV2,
  type RefundNotificationParams,
  type OwnerNotificationParamsV2,
  type PaymentReminderParams,
  type CheckInReminderParams,
  type CheckOutReminderParams,
  type CustomGuestEmailParamsV2,
  sendEmailVerificationEmailV2,
  type EmailVerificationParams,
  sendPendingOwnerNotificationEmailV2,
  type PendingOwnerNotificationParams,
  sendBookingRejectedEmailV2,
  type BookingRejectedParams,
} from "./email";

// ==========================================
// CONFIGURATION & HELPER FUNCTIONS
// ==========================================

// Lazy initialization of Resend client (avoids issues with Firebase CLI analysis)
let resend: Resend | null = null;
export function getResendClient(): Resend {
  if (!resend) {
    const apiKey = process.env.RESEND_API_KEY;
    if (!apiKey) {
      throw new Error(
        "RESEND_API_KEY environment variable not configured. " +
        "Get your API key from: https://resend.com/api-keys"
      );
    }
    resend = new Resend(apiKey);
    logSuccess("[EmailService] Resend client initialized", {
      keyPrefix: apiKey.substring(0, 7) + "...",
    });
  }
  return resend;
}

// Email regex for validation
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Lazy initialization for email config (avoids issues with Firebase CLI analysis)
let _fromEmail: string | null = null;
let _fromName: string | null = null;
let _configLogged = false;

function getFromEmail(): string {
  if (!_fromEmail) {
    const fromEmailRaw = process.env.FROM_EMAIL;
    if (!fromEmailRaw) {
      throw new Error(
        "FROM_EMAIL environment variable not configured. " +
        "Set this to your verified Resend sender email (e.g., bookings@yourdomain.com). " +
        "See: https://resend.com/docs/send-with-nodejs#2-send-email"
      );
    }
    if (!EMAIL_REGEX.test(fromEmailRaw)) {
      throw new Error(
        `FROM_EMAIL is not a valid email address: ${fromEmailRaw}. ` +
        "Must be a valid email format (e.g., bookings@yourdomain.com)"
      );
    }
    _fromEmail = fromEmailRaw;
    logConfigOnce();
  }
  return _fromEmail;
}

function getFromName(): string {
  if (!_fromName) {
    const fromNameRaw = process.env.FROM_NAME;
    if (!fromNameRaw) {
      throw new Error(
        "FROM_NAME environment variable not configured. " +
        "Set this to your sender display name (e.g., 'BookBed', 'Villa Marija Bookings')." +
        "This appears as the 'From' name in emails."
      );
    }
    _fromName = fromNameRaw;
    logConfigOnce();
  }
  return _fromName;
}

function logConfigOnce(): void {
  if (!_configLogged && _fromEmail && _fromName) {
    logSuccess("[EmailService] Configured sender email", {
      fromEmail: _fromEmail,
      fromName: _fromName,
    });
    _configLogged = true;
  }
}

// For backwards compatibility - use these getters directly
const FROM_EMAIL = (): string => getFromEmail();
const FROM_NAME = (): string => getFromName();

// Widget URL for booking lookup
// IMPORTANT: Widget lives on view.bookbed.io, NOT bookbed.io (which is for marketing)
const WIDGET_URL = process.env.WIDGET_URL || "https://view.bookbed.io";
const BOOKING_DOMAIN = process.env.BOOKING_DOMAIN || null;
// View booking URL for booking details page (automatically derived from BOOKING_DOMAIN)
// If BOOKING_DOMAIN is set, use view.{BOOKING_DOMAIN}, otherwise null
const VIEW_BOOKING_URL = BOOKING_DOMAIN ? `https://view.${BOOKING_DOMAIN}` : null;

// ==========================================
// PROPERTY DATA HELPER (DRY - Single Fetch)
// ==========================================

/**
 * Property data needed for emails
 */
interface PropertyData {
  contactEmail?: string;
  subdomain?: string;
}

/**
 * Fetch property data (contact_email + subdomain) in a single query
 *
 * This helper eliminates duplicate Firestore fetches across email functions.
 * Previously, each email function would fetch the property document separately,
 * resulting in 2+ reads per email send.
 *
 * @param propertyId - The property document ID
 * @param operation - Operation name for logging context
 * @returns PropertyData with contactEmail and subdomain, or empty object on error
 */
async function fetchPropertyData(
  propertyId: string | undefined,
  operation: string
): Promise<PropertyData> {
  if (!propertyId) {
    return {};
  }

  try {
    const propertyDoc = await db.collection("properties").doc(propertyId).get();

    if (!propertyDoc.exists) {
      logError("[EmailService] Property not found", null, {
        propertyId,
        operation,
      });
      return {};
    }

    const data = propertyDoc.data();
    return {
      contactEmail: data?.contact_email,
      subdomain: data?.subdomain,
    };
  } catch (error) {
    logError("[EmailService] Failed to fetch property data", error, {
      propertyId,
      operation,
    });
    return {};
  }
}

// ==========================================
// INPUT VALIDATION HELPERS
// ==========================================

/**
 * Validate email format
 *
 * @param email - Email address to validate
 * @param fieldName - Field name for error messages
 * @throws Error if email is invalid
 */
function validateEmail(email: string, fieldName: string): void {
  if (!email || typeof email !== "string") {
    throw new Error(`${fieldName} is required`);
  }
  if (!EMAIL_REGEX.test(email.trim())) {
    throw new Error(`${fieldName} is not a valid email address: ${email}`);
  }
}

/**
 * Validate required string field
 *
 * @param value - String value to validate
 * @param fieldName - Field name for error messages
 * @throws Error if value is empty or not a string
 */
function validateRequiredString(value: string, fieldName: string): void {
  if (!value || typeof value !== "string" || value.trim().length === 0) {
    throw new Error(`${fieldName} is required and must be a non-empty string`);
  }
}

/**
 * Validate amount is non-negative
 *
 * @param amount - Amount to validate
 * @param fieldName - Field name for error messages
 * @throws Error if amount is negative
 */
function validateAmount(amount: number, fieldName: string): void {
  if (typeof amount !== "number" || isNaN(amount)) {
    throw new Error(`${fieldName} must be a valid number`);
  }
  if (amount < 0) {
    throw new Error(`${fieldName} cannot be negative: ${amount}`);
  }
}

/**
 * Validate date is a valid Date object
 *
 * @param date - Date to validate
 * @param fieldName - Field name for error messages
 * @throws Error if date is invalid
 */
function validateDate(date: Date, fieldName: string): void {
  if (!(date instanceof Date) || isNaN(date.getTime())) {
    throw new Error(`${fieldName} must be a valid Date object`);
  }
}

/**
 * Validate subdomain format (DNS-safe)
 *
 * Rules (RFC 1123):
 * - Lowercase alphanumeric + hyphens only
 * - Cannot start or end with hyphen
 * - Length: 1-63 characters (DNS limit)
 *
 * Examples:
 * - ✅ Valid: "villa-marija", "apartman1", "a", "my-property-123"
 * - ❌ Invalid: "-invalid", "invalid-", "UPPERCASE", "has_underscore", ""
 */
function isValidSubdomain(subdomain: string): boolean {
  // RFC 1123 subdomain pattern (case-insensitive, but we enforce lowercase)
  const SUBDOMAIN_REGEX = /^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$/;
  return SUBDOMAIN_REGEX.test(subdomain);
}

/**
 * Generate view booking URL with subdomain support
 *
 * If BOOKING_DOMAIN is configured (production):
 *   Returns: https://{subdomain}.{BOOKING_DOMAIN}/view?ref=XXX&email=XXX&token=XXX&lang=XXX
 *
 * If BOOKING_DOMAIN is not set (testing/development):
 *   Returns: https://widget.web.app/view?subdomain=XXX&ref=XXX&email=XXX&token=XXX&lang=XXX
 *
 * If subdomain is not set or invalid:
 *   Returns: https://widget.web.app/view?ref=XXX&email=XXX&token=XXX&lang=XXX (fallback)
 *
 * SECURITY: Subdomain is validated against RFC 1123 to prevent URL injection
 *
 * @param bookingReference - The booking reference code
 * @param guestEmail - Guest email for URL params
 * @param accessToken - Access token for URL params
 * @param propertyData - Pre-fetched property data (avoids duplicate Firestore reads)
 * @param language - Optional language code (hr, en, de, it) to include in URL
 */
function generateViewBookingUrl(
  bookingReference: string,
  guestEmail: string,
  accessToken: string,
  propertyData?: PropertyData,
  language?: string
): string {
  const params = new URLSearchParams();
  params.set("ref", bookingReference);
  params.set("email", guestEmail);
  params.set("token", accessToken);
  
  // Add language if provided and valid
  if (language && ['hr', 'en', 'de', 'it'].includes(language.toLowerCase())) {
    params.set("lang", language.toLowerCase());
  }

  // Use pre-fetched subdomain (validated)
  let subdomain: string | null = null;
  if (propertyData?.subdomain) {
    const rawSubdomain = propertyData.subdomain;

    // SECURITY: Validate subdomain format before using in URL
    if (isValidSubdomain(rawSubdomain)) {
      subdomain = rawSubdomain;
    } else {
      logError("[EmailService] Invalid subdomain format - using fallback URL", null, {
        subdomain: rawSubdomain,
        reason: "Failed RFC 1123 validation",
      });
    }
  }

  // Generate URL based on configuration
  // Use VIEW_BOOKING_URL if set (for booking details page on view.bookbed.io)
  // Otherwise use subdomain logic for widget
  if (VIEW_BOOKING_URL) {
    // Production: view.bookbed.io/view?ref=XXX
    return `${VIEW_BOOKING_URL}/view?${params.toString()}`;
  } else if (subdomain) {
    if (BOOKING_DOMAIN) {
      // Production: subdomain.domain.com/view?ref=XXX
      return `https://${subdomain}.${BOOKING_DOMAIN}/view?${params.toString()}`;
    } else {
      // Testing: widget.web.app/view?subdomain=XXX&ref=XXX
      params.set("subdomain", subdomain);
      return `${WIDGET_URL}/view?${params.toString()}`;
    }
  } else {
    // Fallback: widget.web.app/view?ref=XXX
    return `${WIDGET_URL}/view?${params.toString()}`;
  }
}

// ==========================================
// EMAIL FUNCTIONS - MIGRATED TO NEW TEMPLATES
// ==========================================

/**
 * Send booking confirmation email to guest
 *
 * MIGRATED: Now uses modern email template with card-based layout
 */
export async function sendBookingConfirmationEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  checkIn: Date,
  checkOut: Date,
  totalAmount: number,
  depositAmount: number,
  unitName: string,
  propertyName: string,
  accessToken: string,
  ownerEmail?: string,
  propertyId?: string
): Promise<void> {
  // Input validation
  validateEmail(guestEmail, "guestEmail");
  validateRequiredString(guestName, "guestName");
  validateRequiredString(bookingReference, "bookingReference");
  validateDate(checkIn, "checkIn");
  validateDate(checkOut, "checkOut");
  validateAmount(totalAmount, "totalAmount");
  validateAmount(depositAmount, "depositAmount");

  try {
    // Fetch property data ONCE (contactEmail + subdomain)
    const propertyData = await fetchPropertyData(propertyId, "booking_confirmation");

    // Generate view booking URL with pre-fetched data (no duplicate fetch)
    const viewBookingUrl = generateViewBookingUrl(
      bookingReference,
      guestEmail,
      accessToken,
      propertyData
    );

    // Build params for new template
    const params: BookingConfirmationParams = {
      guestEmail,
      guestName,
      bookingReference,
      checkIn,
      checkOut,
      totalAmount,
      depositAmount,
      unitName,
      propertyName,
      viewBookingUrl,
      contactEmail: propertyData.contactEmail || ownerEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendBookingConfirmationEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME(),
      ownerEmail
    );

    logSuccess("Booking confirmation email sent (V2 - Refined Premium)", { email: guestEmail });
  } catch (error) {
    logError("Error sending booking confirmation email", error);
    throw error;
  }
}

/**
 * Send booking approved email to guest
 *
 * MIGRATED: Now uses modern email template with success gradient
 */
export async function sendBookingApprovedEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  checkIn: Date,
  checkOut: Date,
  propertyName: string,
  ownerEmail?: string,
  accessToken?: string,
  totalAmount?: number,
  depositAmount?: number,
  propertyId?: string
): Promise<void> {
  // Input validation
  validateEmail(guestEmail, "guestEmail");
  validateRequiredString(guestName, "guestName");
  validateRequiredString(bookingReference, "bookingReference");
  validateDate(checkIn, "checkIn");
  validateDate(checkOut, "checkOut");
  if (totalAmount !== undefined) validateAmount(totalAmount, "totalAmount");
  if (depositAmount !== undefined) validateAmount(depositAmount, "depositAmount");

  try {
    // Fetch property data ONCE (contactEmail + subdomain)
    const propertyData = await fetchPropertyData(propertyId, "booking_approved");

    // Generate view booking URL if accessToken provided (uses pre-fetched data)
    const viewBookingUrl = accessToken ? generateViewBookingUrl(
      bookingReference,
      guestEmail,
      accessToken,
      propertyData
    ) : undefined;

    // Build params for new template
    const params: BookingApprovedParams = {
      guestEmail,
      guestName,
      bookingReference,
      checkIn,
      checkOut,
      propertyName,
      unitName: undefined, // unitName not available in this context
      viewBookingUrl,
      totalAmount,
      depositAmount,
      contactEmail: propertyData.contactEmail || ownerEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendBookingApprovedEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME(),
      ownerEmail
    );

    logSuccess("Booking approved email sent (V2 - Refined Premium)", { email: guestEmail });
  } catch (error) {
    logError("Error sending booking approved email", error);
    throw error;
  }
}

/**
 * Send owner notification email
 *
 * MIGRATED: Now uses V2 template (Refined Premium)
 */
export async function sendOwnerNotificationEmail(
  ownerEmail: string,
  bookingReference: string,
  guestName: string,
  guestEmail: string,
  guestPhone: string | undefined,
  propertyName: string,
  unitName: string,
  checkIn: Date,
  checkOut: Date,
  guests: number,
  totalAmount: number,
  depositAmount: number,
  paymentMethod?: string
): Promise<void> {
  // Input validation
  validateEmail(ownerEmail, "ownerEmail");
  validateRequiredString(bookingReference, "bookingReference");
  validateRequiredString(guestName, "guestName");
  validateEmail(guestEmail, "guestEmail");
  validateRequiredString(propertyName, "propertyName");
  validateRequiredString(unitName, "unitName");
  validateDate(checkIn, "checkIn");
  validateDate(checkOut, "checkOut");
  validateAmount(guests, "guests");
  validateAmount(totalAmount, "totalAmount");
  validateAmount(depositAmount, "depositAmount");

  try {
    // Build params for V2 template
    const params: OwnerNotificationParamsV2 = {
      ownerEmail,
      bookingReference,
      guestName,
      guestEmail,
      guestPhone,
      propertyName,
      unitName,
      checkIn,
      checkOut,
      guests,
      totalAmount,
      depositAmount,
      paymentMethod,
    };

    // Send email using V2 template (Refined Premium)
    await sendOwnerNotificationEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME()
    );

    logSuccess("Owner notification email sent (V2 - Refined Premium)", { email: ownerEmail });
  } catch (error) {
    logError("Error sending owner notification email", error);
    throw error;
  }
}

/**
 * Send guest cancellation email
 *
 * MIGRATED: Previously named sendBookingCancellationEmail
 */
export async function sendGuestCancellationEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  propertyName: string,
  unitName: string | undefined,
  checkIn: Date,
  checkOut: Date,
  refundAmount?: number,
  propertyId?: string,
  cancellationReason?: string,
  cancelledByOwner?: boolean
): Promise<void> {
  // Input validation
  validateEmail(guestEmail, "guestEmail");
  validateRequiredString(guestName, "guestName");
  validateRequiredString(bookingReference, "bookingReference");
  validateDate(checkIn, "checkIn");
  validateDate(checkOut, "checkOut");
  if (refundAmount !== undefined) validateAmount(refundAmount, "refundAmount");

  try {
    // Fetch property data ONCE (contactEmail + subdomain)
    const propertyData = await fetchPropertyData(propertyId, "guest_cancellation");

    // Build params for new template
    const params: GuestCancellationParams = {
      guestEmail,
      guestName,
      bookingReference,
      propertyName,
      unitName,
      checkIn,
      checkOut,
      refundAmount,
      cancellationReason,
      cancelledByOwner,
      contactEmail: propertyData.contactEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendGuestCancellationEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME()
    );

    logSuccess("Guest cancellation email sent (V2 - Refined Premium)", { email: guestEmail });
  } catch (error) {
    logError("Error sending guest cancellation email", error);
    throw error;
  }
}

// Backward compatibility alias
export const sendBookingCancellationEmail = sendGuestCancellationEmail;

/**
 * Send owner cancellation notification email
 *
 * MIGRATED: Now uses V2 template (Refined Premium)
 */
export async function sendOwnerCancellationNotificationEmail(
  ownerEmail: string,
  bookingReference: string,
  guestName: string,
  guestEmail: string,
  propertyName: string,
  unitName: string | undefined,
  checkIn: Date,
  checkOut: Date,
  totalAmount: number
): Promise<void> {
  // Input validation
  validateEmail(ownerEmail, "ownerEmail");
  validateRequiredString(bookingReference, "bookingReference");
  validateRequiredString(guestName, "guestName");
  validateEmail(guestEmail, "guestEmail");
  validateRequiredString(propertyName, "propertyName");
  validateDate(checkIn, "checkIn");
  validateDate(checkOut, "checkOut");
  validateAmount(totalAmount, "totalAmount");

  try {
    // Build params for V2 template
    const params: OwnerCancellationParamsV2 = {
      ownerEmail,
      bookingReference,
      guestName,
      guestEmail,
      propertyName,
      unitName,
      checkIn,
      checkOut,
      totalAmount,
    };

    // Send email using V2 template (Refined Premium)
    await sendOwnerCancellationEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME()
    );

    logSuccess("Owner cancellation notification sent (V2 - Refined Premium)", { email: ownerEmail });
  } catch (error) {
    logError("Error sending owner cancellation notification", error);
    throw error;
  }
}

/**
 * Send refund notification email
 *
 * MIGRATED: Now uses modern email template
 */
export async function sendRefundNotificationEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  refundAmount: number,
  reason?: string,
  propertyId?: string
): Promise<void> {
  // Input validation
  validateEmail(guestEmail, "guestEmail");
  validateRequiredString(guestName, "guestName");
  validateRequiredString(bookingReference, "bookingReference");
  validateAmount(refundAmount, "refundAmount");

  try {
    // Fetch property data ONCE (contactEmail + subdomain)
    const propertyData = await fetchPropertyData(propertyId, "refund_notification");

    // Build params for new template
    const params: RefundNotificationParams = {
      guestEmail,
      guestName,
      bookingReference,
      refundAmount,
      reason,
      contactEmail: propertyData.contactEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendRefundNotificationEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME()
    );

    logSuccess("Refund notification email sent (V2 - Refined Premium)", { email: guestEmail });
  } catch (error) {
    logError("Error sending refund notification email", error);
    throw error;
  }
}

/**
 * Send custom email to guest
 *
 * MIGRATED: Now uses V2 template (Refined Premium)
 */
export async function sendCustomGuestEmail(
  guestEmail: string,
  guestName: string,
  subject: string,
  message: string,
  ownerEmail?: string,
  propertyName?: string
): Promise<void> {
  // Input validation
  validateEmail(guestEmail, "guestEmail");
  validateRequiredString(guestName, "guestName");
  validateRequiredString(subject, "subject");
  validateRequiredString(message, "message");
  if (ownerEmail) validateEmail(ownerEmail, "ownerEmail");

  try {
    // Build params for V2 template
    const params: CustomGuestEmailParamsV2 = {
      guestEmail,
      guestName,
      subject,
      message,
      ownerEmail,
      propertyName,
    };

    // Send email using V2 template (Refined Premium)
    await sendCustomGuestEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME()
    );

    logSuccess("Custom guest email sent (V2 - Refined Premium)", { email: guestEmail });
  } catch (error) {
    logError("Error sending custom guest email", error);
    throw error;
  }
}

// Backward compatibility alias
export const sendCustomEmailToGuest = sendCustomGuestEmail;

/**
 * Send payment reminder email
 *
 * MIGRATED: Now uses modern email template
 */
export async function sendPaymentReminderEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  propertyName: string,
  unitName: string | undefined,
  checkIn: Date,
  depositAmount: number,
  accessToken?: string,
  propertyId?: string
): Promise<void> {
  // Input validation
  validateEmail(guestEmail, "guestEmail");
  validateRequiredString(guestName, "guestName");
  validateRequiredString(bookingReference, "bookingReference");
  validateDate(checkIn, "checkIn");
  validateAmount(depositAmount, "depositAmount");

  try {
    // Fetch property data ONCE (contactEmail + subdomain)
    const propertyData = await fetchPropertyData(propertyId, "payment_reminder");

    // Generate view booking URL if accessToken provided (uses pre-fetched data)
    const viewBookingUrl = accessToken ? generateViewBookingUrl(
      bookingReference,
      guestEmail,
      accessToken,
      propertyData
    ) : undefined;

    // Build params for new template
    const params: PaymentReminderParams = {
      guestEmail,
      guestName,
      bookingReference,
      propertyName,
      unitName,
      checkIn,
      depositAmount,
      viewBookingUrl,
      contactEmail: propertyData.contactEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendPaymentReminderEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME()
    );

    logSuccess("Payment reminder email sent (V2 - Refined Premium)", { email: guestEmail });
  } catch (error) {
    logError("Error sending payment reminder email", error);
    throw error;
  }
}

/**
 * Send check-in reminder email
 *
 * MIGRATED: Now uses modern email template
 */
export async function sendCheckInReminderEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  propertyName: string,
  unitName: string | undefined,
  checkIn: Date,
  checkInTime?: string,
  address?: string,
  accessToken?: string,
  propertyId?: string
): Promise<void> {
  // Input validation
  validateEmail(guestEmail, "guestEmail");
  validateRequiredString(guestName, "guestName");
  validateRequiredString(bookingReference, "bookingReference");
  validateDate(checkIn, "checkIn");

  try {
    // Fetch property data ONCE (contactEmail + subdomain)
    const propertyData = await fetchPropertyData(propertyId, "checkin_reminder");

    // Generate view booking URL if accessToken provided (uses pre-fetched data)
    const viewBookingUrl = accessToken ? generateViewBookingUrl(
      bookingReference,
      guestEmail,
      accessToken,
      propertyData
    ) : undefined;

    // Build params for new template
    const params: CheckInReminderParams = {
      guestEmail,
      guestName,
      bookingReference,
      propertyName,
      unitName,
      checkIn,
      checkInTime,
      address,
      viewBookingUrl,
      contactEmail: propertyData.contactEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendCheckInReminderEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME()
    );

    logSuccess("Check-in reminder email sent (V2 - Refined Premium)", { email: guestEmail });
  } catch (error) {
    logError("Error sending check-in reminder email", error);
    throw error;
  }
}

/**
 * Send check-out reminder email
 *
 * MIGRATED: Now uses modern email template
 */
export async function sendCheckOutReminderEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  propertyName: string,
  unitName: string | undefined,
  checkOut: Date,
  checkOutTime?: string,
  propertyId?: string
): Promise<void> {
  // Input validation
  validateEmail(guestEmail, "guestEmail");
  validateRequiredString(guestName, "guestName");
  validateRequiredString(bookingReference, "bookingReference");
  validateDate(checkOut, "checkOut");

  try {
    // Fetch property data ONCE (contactEmail + subdomain)
    const propertyData = await fetchPropertyData(propertyId, "checkout_reminder");

    // Build params for new template
    const params: CheckOutReminderParams = {
      guestEmail,
      guestName,
      bookingReference,
      propertyName,
      unitName,
      checkOut,
      checkOutTime,
      contactEmail: propertyData.contactEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendCheckOutReminderEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME()
    );

    logSuccess("Check-out reminder email sent (V2 - Refined Premium)", { email: guestEmail });
  } catch (error) {
    logError("Error sending check-out reminder email", error);
    throw error;
  }
}

// ==========================================
// ADDITIONAL EMAIL FUNCTIONS
// ==========================================

// NOTE: sendSuspiciousActivityEmail has been removed (TODO for future implementation)

/**
 * Bank details for bank transfer payments
 */
export interface BankDetails {
  bankName?: string;
  accountHolder?: string;
  iban?: string;
  swift?: string;
}

/**
 * Send pending booking request email
 * MIGRATED: Now uses V2 template (OPCIJA A: Refined Premium, warning theme)
 *
 * @param guestEmail - Guest's email address
 * @param guestName - Guest's name
 * @param bookingReference - Booking reference code
 * @param propertyName - Property name
 * @param paymentMethod - Optional payment method (if 'bank_transfer', includes bank details)
 * @param depositAmount - Optional deposit amount for bank transfer
 * @param bankDetails - Optional bank details (required if paymentMethod is 'bank_transfer')
 */
export async function sendPendingBookingRequestEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  propertyName: string,
  paymentMethod?: string,
  depositAmount?: number,
  bankDetails?: BankDetails
): Promise<void> {
  // Input validation
  validateEmail(guestEmail, "guestEmail");
  validateRequiredString(guestName, "guestName");
  validateRequiredString(bookingReference, "bookingReference");
  validateRequiredString(propertyName, "propertyName");

  try {
    // Build params for V2 template
    const params: PendingBookingRequestParams = {
      guestEmail,
      guestName,
      bookingReference,
      propertyName,
      paymentMethod,
      depositAmount,
      bankDetails,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendPendingBookingRequestEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME()
    );

    logSuccess("Pending booking request email sent (V2 - Refined Premium)", {
      email: guestEmail,
      paymentMethod,
      hasBankDetails: !!bankDetails?.iban,
    });
  } catch (error) {
    logError("Error sending pending booking request email", error);
    throw error;
  }
}

/**
 * Send pending booking owner notification
 * MIGRATED: Now uses V2 template (OPCIJA A: Refined Premium, warning theme)
 */
export async function sendPendingBookingOwnerNotification(
  ownerEmail: string,
  bookingReference: string,
  guestName: string,
  propertyName: string,
  dashboardUrl?: string
): Promise<void> {
  // Input validation
  validateEmail(ownerEmail, "ownerEmail");
  validateRequiredString(bookingReference, "bookingReference");
  validateRequiredString(guestName, "guestName");
  validateRequiredString(propertyName, "propertyName");

  try {
    // Build params for V2 template
    const params: PendingOwnerNotificationParams = {
      ownerEmail,
      bookingReference,
      guestName,
      propertyName,
      dashboardUrl,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendPendingOwnerNotificationEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME()
    );

    logSuccess("Pending booking owner notification sent (V2 - Refined Premium)", { email: ownerEmail });
  } catch (error) {
    logError("Error sending pending booking owner notification", error);
    throw error;
  }
}

/**
 * Send booking rejected email
 * MIGRATED: Now uses V2 template (OPCIJA A: Refined Premium, error theme)
 */
export async function sendBookingRejectedEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  propertyName: string,
  reason?: string,
  ownerEmail?: string
): Promise<void> {
  // Input validation
  validateEmail(guestEmail, "guestEmail");
  validateRequiredString(guestName, "guestName");
  validateRequiredString(bookingReference, "bookingReference");
  validateRequiredString(propertyName, "propertyName");
  if (ownerEmail) validateEmail(ownerEmail, "ownerEmail");

  try {
    // Build params for V2 template
    const params: BookingRejectedParams = {
      guestEmail,
      guestName,
      bookingReference,
      propertyName,
      reason,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendBookingRejectedEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME(),
      ownerEmail
    );

    logSuccess("Booking rejected email sent (V2 - Refined Premium)", { email: guestEmail });
  } catch (error) {
    logError("Error sending booking rejected email", error);
    throw error;
  }
}

/**
 * Send email verification code
 * MIGRATED: Now uses V2 template (OPCIJA A: Refined Premium, info/security theme)
 */
export async function sendEmailVerificationCode(
  email: string,
  code: string
): Promise<void> {
  // Input validation
  validateEmail(email, "email");
  validateRequiredString(code, "code");

  try {
    // Build params for V2 template
    const params: EmailVerificationParams = {
      email,
      code,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendEmailVerificationEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL(),
      FROM_NAME()
    );

    logSuccess("Email verification code sent (V2 - Refined Premium)", { email });
  } catch (error) {
    logError("Error sending email verification code", error);
    throw error;
  }
}


// ============================================================================
// TRIAL EMAIL FUNCTIONS
// ============================================================================

/**
 * Send Trial Expiring Warning Email
 *
 * Notifies user that their trial is about to expire.
 *
 * @param email - User's email address
 * @param name - User's name
 * @param daysRemaining - Number of days until trial expires (1, 3, or 7)
 * @param userId - User ID for tracking
 */
export async function sendTrialExpiringEmail(
  email: string,
  name: string,
  daysRemaining: number,
  userId: string
): Promise<void> {
  try {
    const resend = getResendClient();

    const upgradeUrl = `https://app.bookbed.io/subscription?utm_source=trial_warning&utm_medium=email&days=${daysRemaining}`;

    const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Trial is Expiring Soon</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB;">
  <div style="max-width: 560px; margin: 0 auto; padding: 20px;">
    <div style="background-color: #FFFFFF; border-radius: 12px; border: 1px solid #E5E7EB; overflow: hidden; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);">
      
      <!-- Header -->
      <div style="text-align: center; padding: 32px 24px; background: linear-gradient(135deg, #FEF3C7 0%, #FDE68A 100%);">
        <div style="font-size: 48px; margin-bottom: 16px;">⏰</div>
        <h1 style="margin: 0 0 8px 0; font-size: 24px; font-weight: 700; color: #1F2937;">
          Your Trial Expires in ${daysRemaining} Day${daysRemaining === 1 ? "" : "s"}
        </h1>
        <p style="margin: 0; font-size: 14px; color: #6B7280;">
          Don't lose access to your booking management tools
        </p>
      </div>
      
      <!-- Content -->
      <div style="padding: 24px;">
        <p style="margin: 0 0 16px 0; font-size: 16px; color: #1F2937;">
          Hi ${escapeHtml(name)},
        </p>
        
        <p style="margin: 0 0 16px 0; font-size: 15px; color: #6B7280; line-height: 1.6;">
          Your free trial of BookBed will expire in <strong>${daysRemaining} day${daysRemaining === 1 ? "" : "s"}</strong>. 
          To continue managing your bookings without interruption, please upgrade to a paid plan.
        </p>
        
        <!-- Warning Box -->
        <div style="background-color: #FFFBEB; border: 1px solid #FDE68A; border-radius: 8px; padding: 16px; margin: 20px 0;">
          <div style="display: flex; align-items: flex-start;">
            <span style="font-size: 18px; margin-right: 12px;">⚠️</span>
            <div>
              <strong style="display: block; font-size: 15px; color: #D97706; margin-bottom: 6px;">
                What happens when your trial ends?
              </strong>
              <span style="font-size: 14px; color: #6B7280; line-height: 1.5;">
                You'll lose access to the owner dashboard, booking management, and calendar sync features. 
                Your existing bookings and data will be preserved.
              </span>
            </div>
          </div>
        </div>
        
        <!-- CTA Button -->
        <div style="text-align: center; margin: 24px 0;">
          <a href="${upgradeUrl}" style="display: inline-block; background-color: #374151; color: #FFFFFF; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-size: 15px; font-weight: 600;">
            Upgrade Now
          </a>
        </div>
        
        <p style="margin: 0; font-size: 13px; color: #9CA3AF; text-align: center;">
          Questions? Reply to this email and we'll help you out.
        </p>
      </div>
      
      <!-- Footer -->
      <div style="text-align: center; padding: 24px; border-top: 1px solid #E5E7EB;">
        <p style="margin: 0; font-size: 12px; color: #9CA3AF;">
          This email was sent by BookBed. You're receiving this because your trial is expiring soon.
        </p>
      </div>
    </div>
  </div>
</body>
</html>
    `.trim();

    await resend.emails.send({
      from: `${FROM_NAME()} <${FROM_EMAIL()}>`,
      to: email,
      subject: `⏰ Your BookBed trial expires in ${daysRemaining} day${daysRemaining === 1 ? "" : "s"}`,
      html,
    });

    logSuccess("[Trial Email] Expiring warning sent", {
      email,
      daysRemaining,
      userId,
    });
  } catch (error) {
    logError("[Trial Email] Failed to send expiring warning", error, {
      email,
      daysRemaining,
      userId,
    });
    throw error;
  }
}

/**
 * Send Trial Expired Email
 *
 * Notifies user that their trial has expired.
 *
 * @param email - User's email address
 * @param name - User's name
 * @param userId - User ID for tracking
 */
export async function sendTrialExpiredEmail(
  email: string,
  name: string,
  userId: string
): Promise<void> {
  try {
    const resend = getResendClient();

    const upgradeUrl = `https://app.bookbed.io/subscription?utm_source=trial_expired&utm_medium=email`;

    const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Trial Has Expired</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB;">
  <div style="max-width: 560px; margin: 0 auto; padding: 20px;">
    <div style="background-color: #FFFFFF; border-radius: 12px; border: 1px solid #E5E7EB; overflow: hidden; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);">
      
      <!-- Header -->
      <div style="text-align: center; padding: 32px 24px; background: linear-gradient(135deg, #FEE2E2 0%, #FECACA 100%);">
        <div style="font-size: 48px; margin-bottom: 16px;">😢</div>
        <h1 style="margin: 0 0 8px 0; font-size: 24px; font-weight: 700; color: #1F2937;">
          Your Trial Has Expired
        </h1>
        <p style="margin: 0; font-size: 14px; color: #6B7280;">
          But it's not too late to continue!
        </p>
      </div>
      
      <!-- Content -->
      <div style="padding: 24px;">
        <p style="margin: 0 0 16px 0; font-size: 16px; color: #1F2937;">
          Hi ${escapeHtml(name)},
        </p>
        
        <p style="margin: 0 0 16px 0; font-size: 15px; color: #6B7280; line-height: 1.6;">
          Your free trial of BookBed has ended. Your account is now in read-only mode, 
          which means you can view your existing data but can't create new bookings or 
          access premium features.
        </p>
        
        <!-- Info Box -->
        <div style="background-color: #EFF6FF; border: 1px solid #BFDBFE; border-radius: 8px; padding: 16px; margin: 20px 0;">
          <div style="display: flex; align-items: flex-start;">
            <span style="font-size: 18px; margin-right: 12px;">ℹ️</span>
            <div>
              <strong style="display: block; font-size: 15px; color: #2563EB; margin-bottom: 6px;">
                Your data is safe
              </strong>
              <span style="font-size: 14px; color: #6B7280; line-height: 1.5;">
                All your bookings, properties, and settings are preserved. 
                Upgrade anytime to regain full access.
              </span>
            </div>
          </div>
        </div>
        
        <!-- CTA Button -->
        <div style="text-align: center; margin: 24px 0;">
          <a href="${upgradeUrl}" style="display: inline-block; background-color: #059669; color: #FFFFFF; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-size: 15px; font-weight: 600;">
            Upgrade to Continue
          </a>
        </div>
        
        <p style="margin: 0; font-size: 13px; color: #9CA3AF; text-align: center;">
          Need help deciding? Reply to this email and we'll answer your questions.
        </p>
      </div>
      
      <!-- Footer -->
      <div style="text-align: center; padding: 24px; border-top: 1px solid #E5E7EB;">
        <p style="margin: 0; font-size: 12px; color: #9CA3AF;">
          This email was sent by BookBed. You're receiving this because your trial has expired.
        </p>
      </div>
    </div>
  </div>
</body>
</html>
    `.trim();

    await resend.emails.send({
      from: `${FROM_NAME()} <${FROM_EMAIL()}>`,
      to: email,
      subject: "Your BookBed trial has expired - Upgrade to continue",
      html,
    });

    logSuccess("[Trial Email] Expired notification sent", {
      email,
      userId,
    });
  } catch (error) {
    logError("[Trial Email] Failed to send expired notification", error, {
      email,
      userId,
    });
    throw error;
  }
}
