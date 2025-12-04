/**
 * Email Service - Refactored with Modern Templates
 *
 * This service provides email sending functionality using modular templates.
 * All email designs are located in ./email/templates/
 *
 * MIGRATION STATUS:
 * ✅ sendBookingConfirmationEmail - Migrated to new template
 * ✅ sendBookingApprovedEmail - Migrated to new template
 * ✅ sendOwnerNotificationEmail - Migrated to new template
 * ✅ sendGuestCancellationEmail - Migrated to new template (previously sendBookingCancellationEmail)
 * ✅ sendOwnerCancellationNotificationEmail - Migrated to new template
 * ✅ sendRefundNotificationEmail - Migrated to new template
 * ✅ sendCustomGuestEmail - Migrated to new template (previously sendCustomEmailToGuest)
 * ✅ sendPaymentReminderEmail - Migrated to new template
 * ✅ sendCheckInReminderEmail - Migrated to new template
 * ✅ sendCheckOutReminderEmail - Migrated to new template
 *
 * NOT YET MIGRATED (kept from old implementation):
 * - sendSuspiciousActivityEmail
 * - sendPendingBookingRequestEmail
 * - sendPendingBookingOwnerNotification
 * - sendBookingRejectedEmail
 * - sendEmailVerificationCode
 */

import {Resend} from "resend";
import {db} from "./firebase";
import {logError, logSuccess} from "./logger";

// Import new email templates
import {
  sendBookingConfirmationEmail as sendBookingConfirmationEmailTemplate,
  sendBookingApprovedEmail as sendBookingApprovedEmailTemplate,
  sendGuestCancellationEmail as sendGuestCancellationEmailTemplate,
  sendOwnerCancellationEmail as sendOwnerCancellationEmailTemplate,
  sendRefundNotificationEmail as sendRefundNotificationEmailTemplate,
  sendOwnerNotificationEmail as sendOwnerNotificationEmailTemplate,
  sendPaymentReminderEmail as sendPaymentReminderEmailTemplate,
  sendCheckInReminderEmail as sendCheckInReminderEmailTemplate,
  sendCheckOutReminderEmail as sendCheckOutReminderEmailTemplate,
  sendCustomGuestEmail as sendCustomGuestEmailTemplate,
  type BookingConfirmationParams,
  type BookingApprovedParams,
  type GuestCancellationParams,
  type OwnerCancellationParams,
  type RefundNotificationParams,
  type OwnerNotificationParams,
  type PaymentReminderParams,
  type CheckInReminderParams,
  type CheckOutReminderParams,
  type CustomGuestEmailParams,
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

    // Send email using new template
    await sendBookingConfirmationEmailTemplate(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME,
      ownerEmail
    );

    logSuccess("Booking confirmation email sent (NEW TEMPLATE)", {email: guestEmail});
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

    // Send email using new template
    await sendBookingApprovedEmailTemplate(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME,
      ownerEmail
    );

    logSuccess("Booking approved email sent (NEW TEMPLATE)", {email: guestEmail});
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

    // Send email using new template
    await sendGuestCancellationEmailTemplate(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Guest cancellation email sent (NEW TEMPLATE)", {email: guestEmail});
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

    // Send email using new template
    await sendRefundNotificationEmailTemplate(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Refund notification email sent (NEW TEMPLATE)", {email: guestEmail});
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

    // Send email using new template
    await sendPaymentReminderEmailTemplate(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Payment reminder email sent (NEW TEMPLATE)", {email: guestEmail});
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

    // Send email using new template
    await sendCheckInReminderEmailTemplate(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Check-in reminder email sent (NEW TEMPLATE)", {email: guestEmail});
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

    // Send email using new template
    await sendCheckOutReminderEmailTemplate(
      getResendClient(),
      params,
      FROM_EMAIL,
      FROM_NAME
    );

    logSuccess("Check-out reminder email sent (NEW TEMPLATE)", {email: guestEmail});
  } catch (error) {
    logError("Error sending check-out reminder email", error);
    throw error;
  }
}

// ==========================================
// EMAIL FUNCTIONS - NOT YET MIGRATED
// (Kept from old implementation)
// ==========================================

// TODO: These functions will be migrated in FAZA 2

/**
 * Send suspicious activity email (NOT YET MIGRATED)
 * Uses old inline HTML template
 */
export async function sendSuspiciousActivityEmail(
  adminEmail: string,
  activityType: string,
  details: string
): Promise<void> {
  const subject = `⚠️ Suspicious Activity Detected - ${activityType}`;
  const html = `
<!DOCTYPE html>
<html>
<body>
  <h1>Suspicious Activity Detected</h1>
  <p><strong>Type:</strong> ${activityType}</p>
  <p><strong>Details:</strong> ${details}</p>
  <p>Please investigate immediately.</p>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: adminEmail,
      subject: subject,
      html: html,
    });
    logSuccess("Suspicious activity email sent", {email: adminEmail});
  } catch (error) {
    logError("Error sending suspicious activity email", error);
    throw error;
  }
}

/**
 * Send pending booking request email (NOT YET MIGRATED)
 * Uses old inline HTML template
 */
export async function sendPendingBookingRequestEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  propertyName: string
): Promise<void> {
  const subject = `Zahtjev za rezervaciju - ${bookingReference}`;
  const html = `
<!DOCTYPE html>
<html>
<body>
  <h1>Zahtjev za rezervaciju zaprimljen</h1>
  <p>Poštovani/a ${guestName},</p>
  <p>Vaš zahtjev za rezervaciju ${propertyName} je zaprimljen.</p>
  <p>Referenca: ${bookingReference}</p>
  <p>Čekamo potvrdu vlasnika nekretnine.</p>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: guestEmail,
      subject: subject,
      html: html,
    });
    logSuccess("Pending booking request email sent", {email: guestEmail});
  } catch (error) {
    logError("Error sending pending booking request email", error);
    throw error;
  }
}

/**
 * Send pending booking owner notification (NOT YET MIGRATED)
 * Uses old inline HTML template
 */
export async function sendPendingBookingOwnerNotification(
  ownerEmail: string,
  bookingReference: string,
  guestName: string,
  propertyName: string
): Promise<void> {
  const subject = `Novi zahtjev za rezervaciju - ${bookingReference}`;
  const html = `
<!DOCTYPE html>
<html>
<body>
  <h1>Novi zahtjev za rezervaciju</h1>
  <p>Gost ${guestName} je poslao zahtjev za rezervaciju ${propertyName}.</p>
  <p>Referenca: ${bookingReference}</p>
  <p>Molimo pregledajte i potvrdite rezervaciju.</p>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: ownerEmail,
      subject: subject,
      html: html,
    });
    logSuccess("Pending booking owner notification sent", {email: ownerEmail});
  } catch (error) {
    logError("Error sending pending booking owner notification", error);
    throw error;
  }
}

/**
 * Send booking rejected email (NOT YET MIGRATED)
 * Uses old inline HTML template
 */
export async function sendBookingRejectedEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  propertyName: string,
  reason?: string
): Promise<void> {
  const subject = `Rezervacija odbijena - ${bookingReference}`;
  const html = `
<!DOCTYPE html>
<html>
<body>
  <h1>Rezervacija odbijena</h1>
  <p>Poštovani/a ${guestName},</p>
  <p>Nažalost, vaša rezervacija ${propertyName} je odbijena.</p>
  <p>Referenca: ${bookingReference}</p>
  ${reason ? `<p>Razlog: ${reason}</p>` : ""}
  <p>Žao nam je zbog neugodnosti.</p>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: guestEmail,
      subject: subject,
      html: html,
    });
    logSuccess("Booking rejected email sent", {email: guestEmail});
  } catch (error) {
    logError("Error sending booking rejected email", error);
    throw error;
  }
}

/**
 * Send email verification code (NOT YET MIGRATED)
 * Uses old inline HTML template
 */
export async function sendEmailVerificationCode(
  email: string,
  code: string
): Promise<void> {
  const subject = "Verifikacijski kod";
  const html = `
<!DOCTYPE html>
<html>
<body>
  <h1>Verifikacijski kod</h1>
  <p>Vaš verifikacijski kod je: <strong>${code}</strong></p>
  <p>Kod vrijedi 10 minuta.</p>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: email,
      subject: subject,
      html: html,
    });
    logSuccess("Email verification code sent", {email});
  } catch (error) {
    logError("Error sending email verification code", error);
    throw error;
  }
}
