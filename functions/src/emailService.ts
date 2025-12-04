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
 * ✅ sendSuspiciousActivityEmail - Migrated to V2 template (Refined Premium)
 *
 * ALL EMAIL FUNCTIONS FULLY MIGRATED! 🎉
 */

import {Resend} from "resend";
import {db} from "./firebase";
import {logError, logSuccess} from "./logger";

// Import new email templates (V2 - OPCIJA A: Refined Premium)
import {
  sendBookingConfirmationEmailV2,
  sendPendingBookingRequestEmailV2,
  sendBookingApprovedEmailV2,
  sendGuestCancellationEmailV2,
  sendRefundNotificationEmailV2,
  sendPaymentReminderEmailV2,
  sendCheckInReminderEmailV2,
  sendCheckOutReminderEmailV2,
  sendOwnerCancellationEmail as sendOwnerCancellationEmailTemplate,
  sendOwnerNotificationEmail as sendOwnerNotificationEmailTemplate,
  sendCustomGuestEmail as sendCustomGuestEmailTemplate,
  type BookingConfirmationParams,
  type PendingBookingRequestParams,
  type BookingApprovedParams,
  type GuestCancellationParams,
  type OwnerCancellationParams,
  type RefundNotificationParams,
  type OwnerNotificationParams,
  type PaymentReminderParams,
  type CheckInReminderParams,
  type CheckOutReminderParams,
  type CustomGuestEmailParams,
  sendEmailVerificationEmailV2,
  type EmailVerificationParams,
  sendPendingOwnerNotificationEmailV2,
  type PendingOwnerNotificationParams,
  sendBookingRejectedEmailV2,
  type BookingRejectedParams,
  sendSuspiciousActivityEmailV2,
  type SuspiciousActivityParams,
} from "./email";

// ==========================================
// CONFIGURATION & HELPER FUNCTIONS
// ==========================================

// Lazy initialize Resend (to avoid deployment errors)
let resend: Resend | null = null;

/**
 * Get or initialize Resend instance
 */
function getResendClient(): Resend {
  if (!resend) {
    const apiKey = process.env.RESEND_API_KEY || "";
    if (!apiKey) {
      throw new Error("RESEND_API_KEY not configured");
    }
    resend = new Resend(apiKey);
  }
  return resend;
}

// Email sender address
const FROM_EMAIL = process.env.FROM_EMAIL || "onboarding@resend.dev";
const FROM_NAME = process.env.FROM_NAME || "Rab Booking";

// Widget URL for booking lookup
const WIDGET_URL = process.env.WIDGET_URL || "https://rab-booking-widget.web.app";
const BOOKING_DOMAIN = process.env.BOOKING_DOMAIN || null;

/**
 * Generate view booking URL with subdomain support
 *
 * If BOOKING_DOMAIN is configured (production):
 *   Returns: https://{subdomain}.{BOOKING_DOMAIN}/view?ref=XXX&email=XXX&token=XXX
 *
 * If BOOKING_DOMAIN is not set (testing/development):
 *   Returns: https://widget.web.app/view?subdomain=XXX&ref=XXX&email=XXX&token=XXX
 *
 * If subdomain is not set:
 *   Returns: https://widget.web.app/view?ref=XXX&email=XXX&token=XXX (fallback)
 */
async function generateViewBookingUrl(
  bookingReference: string,
  guestEmail: string,
  accessToken: string,
  propertyId?: string
): Promise<string> {
  const params = new URLSearchParams();
  params.set("ref", bookingReference);
  params.set("email", guestEmail);
  params.set("token", accessToken);

  // Try to get subdomain from property
  let subdomain: string | null = null;
  if (propertyId) {
    try {
      const propertyDoc = await db.collection("properties").doc(propertyId).get();
      if (propertyDoc.exists) {
        subdomain = propertyDoc.data()?.subdomain || null;
      }
    } catch (error) {
      logError("Failed to fetch property subdomain for email", error);
    }
  }

  // Generate URL based on configuration
  if (subdomain) {
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
  try {
    // Generate view booking URL
    const viewBookingUrl = await generateViewBookingUrl(
      bookingReference,
      guestEmail,
      accessToken,
      propertyId
    );

    // Get contact email from property
    let contactEmail: string | undefined;
    if (propertyId) {
      try {
        const propertyDoc = await db.collection("properties").doc(propertyId).get();
        contactEmail = propertyDoc.data()?.contact_email;
      } catch (error) {
        // Ignore error, contactEmail will be undefined
      }
    }

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
      contactEmail: contactEmail || ownerEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendBookingConfirmationEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME,
      ownerEmail
    );

    logSuccess("Booking confirmation email sent (V2 - Refined Premium)", {email: guestEmail});
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
  try {
    // Generate view booking URL if accessToken provided
    const viewBookingUrl = accessToken ? await generateViewBookingUrl(
      bookingReference,
      guestEmail,
      accessToken,
      propertyId
    ) : undefined;

    // Get contact email and unit name from property
    let contactEmail: string | undefined;
    let unitName: string | undefined;
    if (propertyId) {
      try {
        const propertyDoc = await db.collection("properties").doc(propertyId).get();
        contactEmail = propertyDoc.data()?.contact_email;
      } catch (error) {
        // Ignore error
      }
    }

    // Build params for new template
    const params: BookingApprovedParams = {
      guestEmail,
      guestName,
      bookingReference,
      checkIn,
      checkOut,
      propertyName,
      unitName,
      viewBookingUrl,
      totalAmount,
      depositAmount,
      contactEmail: contactEmail || ownerEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendBookingApprovedEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME,
      ownerEmail
    );

    logSuccess("Booking approved email sent (V2 - Refined Premium)", {email: guestEmail});
  } catch (error) {
    logError("Error sending booking approved email", error);
    throw error;
  }
}

/**
 * Send owner notification email
 *
 * MIGRATED: Now uses modern email template
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
  try {
    // Build params for new template
    const params: OwnerNotificationParams = {
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

    // Send email using new template
    await sendOwnerNotificationEmailTemplate(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Owner notification email sent (NEW TEMPLATE)", {email: ownerEmail});
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
  propertyId?: string
): Promise<void> {
  try {
    // Get contact email from property
    let contactEmail: string | undefined;
    if (propertyId) {
      try {
        const propertyDoc = await db.collection("properties").doc(propertyId).get();
        contactEmail = propertyDoc.data()?.contact_email;
      } catch (error) {
        // Ignore error
      }
    }

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
      contactEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendGuestCancellationEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Guest cancellation email sent (V2 - Refined Premium)", {email: guestEmail});
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
 * MIGRATED: Now uses modern email template
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
  try {
    // Build params for new template
    const params: OwnerCancellationParams = {
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

    // Send email using new template
    await sendOwnerCancellationEmailTemplate(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Owner cancellation notification sent (NEW TEMPLATE)", {email: ownerEmail});
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
  try {
    // Get contact email from property
    let contactEmail: string | undefined;
    if (propertyId) {
      try {
        const propertyDoc = await db.collection("properties").doc(propertyId).get();
        contactEmail = propertyDoc.data()?.contact_email;
      } catch (error) {
        // Ignore error
      }
    }

    // Build params for new template
    const params: RefundNotificationParams = {
      guestEmail,
      guestName,
      bookingReference,
      refundAmount,
      reason,
      contactEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendRefundNotificationEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Refund notification email sent (V2 - Refined Premium)", {email: guestEmail});
  } catch (error) {
    logError("Error sending refund notification email", error);
    throw error;
  }
}

/**
 * Send custom email to guest
 *
 * MIGRATED: Previously named sendCustomEmailToGuest
 */
export async function sendCustomGuestEmail(
  guestEmail: string,
  guestName: string,
  subject: string,
  message: string,
  ownerEmail?: string,
  propertyName?: string
): Promise<void> {
  try {
    // Build params for new template
    const params: CustomGuestEmailParams = {
      guestEmail,
      guestName,
      subject,
      message,
      ownerEmail,
      propertyName,
    };

    // Send email using new template
    await sendCustomGuestEmailTemplate(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Custom guest email sent (NEW TEMPLATE)", {email: guestEmail});
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
  try {
    // Generate view booking URL if accessToken provided
    const viewBookingUrl = accessToken ? await generateViewBookingUrl(
      bookingReference,
      guestEmail,
      accessToken,
      propertyId
    ) : undefined;

    // Get contact email from property
    let contactEmail: string | undefined;
    if (propertyId) {
      try {
        const propertyDoc = await db.collection("properties").doc(propertyId).get();
        contactEmail = propertyDoc.data()?.contact_email;
      } catch (error) {
        // Ignore error
      }
    }

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
      contactEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendPaymentReminderEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Payment reminder email sent (V2 - Refined Premium)", {email: guestEmail});
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
  try {
    // Generate view booking URL if accessToken provided
    const viewBookingUrl = accessToken ? await generateViewBookingUrl(
      bookingReference,
      guestEmail,
      accessToken,
      propertyId
    ) : undefined;

    // Get contact email from property
    let contactEmail: string | undefined;
    if (propertyId) {
      try {
        const propertyDoc = await db.collection("properties").doc(propertyId).get();
        contactEmail = propertyDoc.data()?.contact_email;
      } catch (error) {
        // Ignore error
      }
    }

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
      contactEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendCheckInReminderEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Check-in reminder email sent (V2 - Refined Premium)", {email: guestEmail});
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
  try {
    // Get contact email from property
    let contactEmail: string | undefined;
    if (propertyId) {
      try {
        const propertyDoc = await db.collection("properties").doc(propertyId).get();
        contactEmail = propertyDoc.data()?.contact_email;
      } catch (error) {
        // Ignore error
      }
    }

    // Build params for new template
    const params: CheckOutReminderParams = {
      guestEmail,
      guestName,
      bookingReference,
      propertyName,
      unitName,
      checkOut,
      checkOutTime,
      contactEmail,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendCheckOutReminderEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Check-out reminder email sent (V2 - Refined Premium)", {email: guestEmail});
  } catch (error) {
    logError("Error sending check-out reminder email", error);
    throw error;
  }
}

// ==========================================
// ADDITIONAL EMAIL FUNCTIONS
// ==========================================

/**
 * Send suspicious activity email
 * MIGRATED: Now uses V2 template (OPCIJA A: Refined Premium, alert/danger theme)
 */
export async function sendSuspiciousActivityEmail(
  adminEmail: string,
  activityType: string,
  details: string,
  timestamp?: string,
  ipAddress?: string,
  userAgent?: string
): Promise<void> {
  try {
    // Build params for V2 template
    const params: SuspiciousActivityParams = {
      adminEmail,
      activityType,
      details,
      timestamp,
      ipAddress,
      userAgent,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendSuspiciousActivityEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Suspicious activity email sent (V2 - Refined Premium)", {email: adminEmail});
  } catch (error) {
    logError("Error sending suspicious activity email", error);
    throw error;
  }
}

/**
 * Send pending booking request email
 * MIGRATED: Now uses V2 template (OPCIJA A: Refined Premium, warning theme)
 */
export async function sendPendingBookingRequestEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  propertyName: string
): Promise<void> {
  try {
    // Build params for V2 template
    const params: PendingBookingRequestParams = {
      guestEmail,
      guestName,
      bookingReference,
      propertyName,
    };

    // Send email using V2 template (OPCIJA A: Refined Premium)
    await sendPendingBookingRequestEmailV2(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Pending booking request email sent (V2 - Refined Premium)", {email: guestEmail});
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
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Pending booking owner notification sent (V2 - Refined Premium)", {email: ownerEmail});
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
      FROM_EMAIL,
      FROM_NAME,
      ownerEmail
    );

    logSuccess("Booking rejected email sent (V2 - Refined Premium)", {email: guestEmail});
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
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Email verification code sent (V2 - Refined Premium)", {email});
  } catch (error) {
    logError("Error sending email verification code", error);
    throw error;
  }
}
