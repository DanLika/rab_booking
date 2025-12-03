import {Resend} from "resend";
import * as admin from "firebase-admin";
import {logError, logSuccess, logInfo} from "./logger";

const db = admin.firestore();

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
// TEST MODE: Uses onboarding@resend.dev (emails only go to Resend account owner)
// PRODUCTION: Change to your verified domain (e.g., "noreply@yourdomain.com" or duskolicanin1234@gmail.com)
const FROM_EMAIL = "onboarding@resend.dev"; // TEST MODE - update when you have a custom domain
const FROM_NAME = "Rab Booking";

// Widget URL for booking lookup (configure in environment variables)
// NOTE: This should be the deployed widget URL where guests can view their bookings
// The /view route exists at: WIDGET_URL/view?ref=BOOKING_REF&email=EMAIL&token=TOKEN
const WIDGET_URL = process.env.WIDGET_URL || "https://rab-booking-widget.web.app";

// Optional: Custom booking domain (set when domain is purchased)
// When set, links will use: {subdomain}.{BOOKING_DOMAIN}/view?ref=XXX
// When not set, links will use: WIDGET_URL/view?subdomain=XXX&ref=XXX
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
      logInfo("Generating production subdomain URL", {subdomain, domain: BOOKING_DOMAIN});
      return `https://${subdomain}.${BOOKING_DOMAIN}/view?${params.toString()}`;
    } else {
      // Testing: widget.web.app/view?subdomain=XXX&ref=XXX
      params.set("subdomain", subdomain);
      logInfo("Generating test subdomain URL", {subdomain});
      return `${WIDGET_URL}/view?${params.toString()}`;
    }
  }

  // Fallback: no subdomain
  return `${WIDGET_URL}/view?${params.toString()}`;
}

// ============================================================================
// UNIFIED EMAIL DESIGN SYSTEM - Minimalist Theme
// Matches the embedded booking widget's clean, minimal aesthetic
// User preference: Minimalist colors, not colorful (2025-12-02)
// ============================================================================

// Color palette (minimalist - matching widget design)
const COLORS = {
  primary: "#6B4CE6", // Purple - main brand color (subtle use)
  primaryLight: "#F5F3FF", // Very light purple for backgrounds
  success: "#10B981", // Emerald green (subtle)
  successLight: "#ECFDF5", // Very light green background
  warning: "#F59E0B", // Amber (subtle)
  warningLight: "#FFFBEB", // Very light amber background
  error: "#EF4444", // Red (subtle)
  errorLight: "#FEF2F2", // Very light red background
  background: "#FFFFFF", // White
  sectionBg: "#FAFAFA", // Very light gray for sections
  cardBg: "#FFFFFF", // White for cards
  border: "#E5E7EB", // Light gray border
  textPrimary: "#111827", // Near black
  textSecondary: "#6B7280", // Medium gray
  textMuted: "#9CA3AF", // Light gray text
};

/**
 * Generate base email styles
 */
function getBaseStyles(): string {
  return `
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      line-height: 1.6;
      color: ${COLORS.textPrimary};
      background-color: #F1F5F9;
      margin: 0;
      padding: 20px;
    }
    .email-wrapper {
      max-width: 600px;
      margin: 0 auto;
      background-color: ${COLORS.background};
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1);
    }
    .header {
      background: linear-gradient(135deg, ${COLORS.primary} 0%, #8B5CF6 100%);
      color: white;
      padding: 32px 24px;
      text-align: center;
    }
    .header h1 {
      margin: 0 0 8px 0;
      font-size: 24px;
      font-weight: 600;
    }
    .header p {
      margin: 0;
      opacity: 0.9;
      font-size: 14px;
    }
    .header-icon {
      font-size: 48px;
      margin-bottom: 12px;
    }
    .content {
      padding: 32px 24px;
    }
    .greeting {
      font-size: 16px;
      margin-bottom: 16px;
    }
    .section {
      background-color: ${COLORS.sectionBg};
      border: 1px solid ${COLORS.border};
      border-radius: 12px;
      padding: 20px;
      margin: 20px 0;
    }
    .section-title {
      font-size: 14px;
      font-weight: 600;
      color: ${COLORS.textSecondary};
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin: 0 0 16px 0;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .detail-row {
      display: flex;
      justify-content: space-between;
      padding: 10px 0;
      border-bottom: 1px solid ${COLORS.border};
    }
    .detail-row:last-child {
      border-bottom: none;
    }
    .detail-label {
      color: ${COLORS.textSecondary};
      font-size: 14px;
    }
    .detail-value {
      font-weight: 600;
      color: ${COLORS.textPrimary};
      font-size: 14px;
    }
    .alert-box {
      padding: 16px;
      border-radius: 12px;
      margin: 20px 0;
      display: flex;
      gap: 12px;
    }
    .alert-box.warning {
      background-color: ${COLORS.warningLight};
      border-left: 4px solid ${COLORS.warning};
    }
    .alert-box.success {
      background-color: ${COLORS.successLight};
      border-left: 4px solid ${COLORS.success};
    }
    .alert-box.error {
      background-color: ${COLORS.errorLight};
      border-left: 4px solid ${COLORS.error};
    }
    .alert-box.info {
      background-color: ${COLORS.primaryLight};
      border-left: 4px solid ${COLORS.primary};
    }
    .alert-icon {
      font-size: 20px;
      flex-shrink: 0;
    }
    .alert-content {
      flex: 1;
    }
    .alert-title {
      font-weight: 600;
      margin: 0 0 4px 0;
      font-size: 14px;
    }
    .alert-text {
      margin: 0;
      font-size: 13px;
      color: ${COLORS.textSecondary};
    }
    .button {
      display: inline-block;
      padding: 14px 28px;
      background: linear-gradient(135deg, ${COLORS.primary} 0%, #8B5CF6 100%);
      color: white !important;
      text-decoration: none;
      border-radius: 8px;
      font-weight: 600;
      font-size: 14px;
      text-align: center;
      transition: transform 0.2s;
    }
    .button:hover {
      transform: translateY(-1px);
    }
    .button-container {
      text-align: center;
      margin: 28px 0;
    }
    .footer {
      background-color: ${COLORS.sectionBg};
      padding: 24px;
      text-align: center;
      border-top: 1px solid ${COLORS.border};
    }
    .footer p {
      margin: 4px 0;
      font-size: 12px;
      color: ${COLORS.textMuted};
    }
    .footer-logo {
      font-weight: 600;
      color: ${COLORS.primary};
      font-size: 14px;
      margin-bottom: 8px;
    }
    .tip {
      background-color: ${COLORS.primaryLight};
      padding: 12px 16px;
      border-radius: 8px;
      font-size: 13px;
      color: ${COLORS.textSecondary};
      text-align: center;
      margin: 16px 0;
    }
    .divider {
      height: 1px;
      background-color: ${COLORS.border};
      margin: 24px 0;
    }
  `;
}

/**
 * Send booking confirmation email to guest
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
  const subject = `Potvrda rezervacije - ${bookingReference}`;

  // Generate view booking URL with subdomain support
  const viewBookingUrl = await generateViewBookingUrl(
    bookingReference,
    guestEmail,
    accessToken,
    propertyId
  );

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>${getBaseStyles()}</style>
</head>
<body>
  <div class="email-wrapper">
    <div class="header">
      <div class="header-icon">✅</div>
      <h1>Rezervacija potvrđena!</h1>
      <p>Referenca: ${bookingReference}</p>
    </div>

    <div class="content">
      <p class="greeting">Poštovani/a ${guestName},</p>
      <p>Hvala vam na rezervaciji! Vaša rezervacija je zaprimljena i čeka potvrdu uplate.</p>

      <div class="section">
        <div class="section-title">📋 Detalji rezervacije</div>
        <div class="detail-row">
          <span class="detail-label">Nekretnina</span>
          <span class="detail-value">${propertyName}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Jedinica</span>
          <span class="detail-value">${unitName}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Check-in</span>
          <span class="detail-value">${formatDate(checkIn)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Check-out</span>
          <span class="detail-value">${formatDate(checkOut)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Referenca</span>
          <span class="detail-value">${bookingReference}</span>
        </div>
      </div>

      <div class="section">
        <div class="section-title">💳 Detalji plaćanja</div>
        <div class="detail-row">
          <span class="detail-label">Ukupna cijena</span>
          <span class="detail-value">€${totalAmount.toFixed(2)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Avans</span>
          <span class="detail-value">€${depositAmount.toFixed(2)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Ostatak (plaća se pri dolasku)</span>
          <span class="detail-value">€${(totalAmount - depositAmount).toFixed(2)}</span>
        </div>
      </div>

      <div class="alert-box warning">
        <div class="alert-icon">💸</div>
        <div class="alert-content">
          <p class="alert-title">Upute za plaćanje</p>
          <p class="alert-text">Molimo uplatite €${depositAmount.toFixed(2)} u roku od 3 dana.<br>
          <strong>Poziv na broj:</strong> ${bookingReference}<br>
          <em>Važno: Obavezno navedite referencu rezervacije u opisu uplate!</em></p>
        </div>
      </div>

      <p>Kada primimo vašu uplatu, poslat ćemo vam email s potvrdom.</p>

      <div class="button-container">
        <a href="${viewBookingUrl}" class="button">
          📋 Pregledaj moju rezervaciju
        </a>
      </div>

      <div class="tip">
        💡 Savjet: Sačuvajte ovaj email kako biste u bilo kojem trenutku mogli pristupiti detaljima rezervacije.
      </div>

      <p>Ako imate pitanja, slobodno nas kontaktirajte.</p>
    </div>

    <div class="footer">
      <div class="footer-logo">🏠 Rab Booking</div>
      <p>© 2025 Rab Booking. Sva prava pridržana.</p>
      <p>Ovaj email je poslan u vezi s vašom rezervacijom ${bookingReference}</p>
    </div>
  </div>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: guestEmail,
      replyTo: ownerEmail || FROM_EMAIL,
      subject: subject,
      html: html,
      text: stripHtml(html),
    });
    logSuccess("Booking confirmation email sent", {email: guestEmail});
  } catch (error) {
    logError("Error sending booking confirmation email", error);
    throw error;
  }
}

/**
 * Send booking approved email to guest (Stripe payment confirmed)
 * NOTE: This is the ONLY email sent for successful Stripe payments
 * Includes "View my reservation" button if accessToken is provided
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
  const subject = `Rezervacija potvrđena - ${bookingReference}`;

  // Generate view booking URL with subdomain support
  const viewBookingUrl = accessToken ? await generateViewBookingUrl(
    bookingReference,
    guestEmail,
    accessToken,
    propertyId
  ) : null;

  // Build the "View my reservation" button HTML if token is provided
  const viewBookingButton = viewBookingUrl ? `
      <div class="button-container">
        <a href="${viewBookingUrl}" class="button">
          📋 Pregledaj moju rezervaciju
        </a>
      </div>

      <div class="tip">
        💡 Savjet: Sačuvajte ovaj email kako biste u bilo kojem trenutku mogli pristupiti detaljima rezervacije.
      </div>
  ` : "";

  // Build payment details section if amounts are provided
  const paymentSection = (totalAmount && depositAmount) ? `
      <div class="section">
        <div class="section-title">💳 Detalji plaćanja</div>
        <div class="detail-row">
          <span class="detail-label">Uplaćeno</span>
          <span class="detail-value">€${depositAmount.toFixed(2)}</span>
        </div>
        ${totalAmount > depositAmount ? `
        <div class="detail-row">
          <span class="detail-label">Ostatak (plaća se pri dolasku)</span>
          <span class="detail-value">€${(totalAmount - depositAmount).toFixed(2)}</span>
        </div>
        ` : ""}
        <div class="detail-row">
          <span class="detail-label">Ukupna cijena</span>
          <span class="detail-value">€${totalAmount.toFixed(2)}</span>
        </div>
      </div>
  ` : "";

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>${getBaseStyles()}
    .header { background: linear-gradient(135deg, ${COLORS.success} 0%, #16A34A 100%); }
  </style>
</head>
<body>
  <div class="email-wrapper">
    <div class="header">
      <div class="header-icon">🎉</div>
      <h1>Rezervacija potvrđena!</h1>
      <p>Referenca: ${bookingReference}</p>
    </div>

    <div class="content">
      <p class="greeting">Poštovani/a ${guestName},</p>
      <p>Sjajne vijesti! Vaša rezervacija je uspješno potvrđena.</p>

      <div class="alert-box success">
        <div class="alert-icon">✅</div>
        <div class="alert-content">
          <p class="alert-title">Rezervacija potvrđena</p>
          <p class="alert-text">Radujemo se vašem dolasku!</p>
        </div>
      </div>

      <div class="section">
        <div class="section-title">📋 Detalji rezervacije</div>
        <div class="detail-row">
          <span class="detail-label">Nekretnina</span>
          <span class="detail-value">${propertyName}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Check-in</span>
          <span class="detail-value">${formatDate(checkIn)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Check-out</span>
          <span class="detail-value">${formatDate(checkOut)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Referenca</span>
          <span class="detail-value">${bookingReference}</span>
        </div>
      </div>

      ${paymentSection}

      ${viewBookingButton}

      <p>Ako imate pitanja, slobodno nas kontaktirajte.</p>
    </div>

    <div class="footer">
      <div class="footer-logo">🏠 Rab Booking</div>
      <p>© 2025 Rab Booking. Sva prava pridržana.</p>
      <p>Ovaj email je poslan u vezi s vašom rezervacijom ${bookingReference}</p>
    </div>
  </div>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: guestEmail,
      replyTo: ownerEmail || FROM_EMAIL,
      subject: subject,
      html: html,
      text: stripHtml(html),
    });
    logSuccess("Booking approved email sent", {email: guestEmail});
  } catch (error) {
    logError("Error sending booking approved email", error);
    throw error;
  }
}

/**
 * Send new booking notification to owner
 * NOTE: This email contains MORE details than guest email (phone, notes, guest count)
 * Used for: Bank transfer, Pay on Arrival auto-confirmed bookings
 */
export async function sendOwnerNotificationEmail(
  ownerEmail: string,
  ownerName: string,
  guestName: string,
  guestEmail: string,
  bookingReference: string,
  checkIn: Date,
  checkOut: Date,
  totalAmount: number,
  depositAmount: number,
  unitName: string,
  guestPhone?: string,
  guestCount?: number,
  notes?: string
): Promise<void> {
  const subject = `Nova rezervacija - ${bookingReference}`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>${getBaseStyles()}
    .header { background: linear-gradient(135deg, ${COLORS.warning} 0%, #D97706 100%); }
  </style>
</head>
<body>
  <div class="email-wrapper">
    <div class="header">
      <div class="header-icon">🔔</div>
      <h1>Nova rezervacija!</h1>
      <p>Čeka vašu potvrdu</p>
    </div>

    <div class="content">
      <p class="greeting">Poštovani/a ${ownerName},</p>
      <p>Primili ste novu rezervaciju putem booking widgeta.</p>

      <div class="section">
        <div class="section-title">👤 Podaci o gostu</div>
        <div class="detail-row">
          <span class="detail-label">Ime i prezime</span>
          <span class="detail-value">${guestName}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Email</span>
          <span class="detail-value">${guestEmail}</span>
        </div>
        ${guestPhone ? `
        <div class="detail-row">
          <span class="detail-label">Telefon</span>
          <span class="detail-value">${guestPhone}</span>
        </div>` : ""}
        ${guestCount ? `
        <div class="detail-row">
          <span class="detail-label">Broj gostiju</span>
          <span class="detail-value">${guestCount}</span>
        </div>` : ""}
      </div>

      <div class="section">
        <div class="section-title">📋 Detalji rezervacije</div>
        <div class="detail-row">
          <span class="detail-label">Jedinica</span>
          <span class="detail-value">${unitName}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Check-in</span>
          <span class="detail-value">${formatDate(checkIn)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Check-out</span>
          <span class="detail-value">${formatDate(checkOut)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Referenca</span>
          <span class="detail-value">${bookingReference}</span>
        </div>
        ${notes ? `
        <div class="detail-row">
          <span class="detail-label">Napomena gosta</span>
          <span class="detail-value">${notes}</span>
        </div>` : ""}
      </div>

      <div class="section">
        <div class="section-title">💳 Plaćanje</div>
        <div class="detail-row">
          <span class="detail-label">Ukupno</span>
          <span class="detail-value">€${totalAmount.toFixed(2)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Avans</span>
          <span class="detail-value">€${depositAmount.toFixed(2)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Ostatak</span>
          <span class="detail-value">€${(totalAmount - depositAmount).toFixed(2)}</span>
        </div>
      </div>

      <div class="alert-box warning">
        <div class="alert-icon">⚠️</div>
        <div class="alert-content">
          <p class="alert-title">Akcija potrebna</p>
          <p class="alert-text">Gost će izvršiti bankovnu uplatu. Kada primite uplatu od €${depositAmount.toFixed(2)} sa referencom <strong>${bookingReference}</strong>, prijavite se u dashboard i odobrite rezervaciju.</p>
        </div>
      </div>

      <div class="button-container">
        <a href="https://rab-booking-owner.web.app" class="button">
          🖥️ Otvori Dashboard
        </a>
      </div>
    </div>

    <div class="footer">
      <div class="footer-logo">🏠 Rab Booking</div>
      <p>© 2025 Rab Booking. Sva prava pridržana.</p>
    </div>
  </div>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: ownerEmail,
      subject: subject,
      html: html,
      text: stripHtml(html),
    });
    logSuccess("Owner notification email sent", {email: ownerEmail});
  } catch (error) {
    logError("Error sending owner notification email", error);
    throw error;
  }
}

/**
 * Send booking cancellation email
 */
export async function sendBookingCancellationEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  reason: string,
  ownerEmail?: string
): Promise<void> {
  const subject = `Rezervacija otkazana - ${bookingReference}`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>${getBaseStyles()}
    .header { background: linear-gradient(135deg, ${COLORS.error} 0%, #DC2626 100%); }
  </style>
</head>
<body>
  <div class="email-wrapper">
    <div class="header">
      <div class="header-icon">❌</div>
      <h1>Rezervacija otkazana</h1>
      <p>Referenca: ${bookingReference}</p>
    </div>

    <div class="content">
      <p class="greeting">Poštovani/a ${guestName},</p>
      <p>Vaša rezervacija ${bookingReference} je otkazana.</p>

      <div class="alert-box error">
        <div class="alert-icon">ℹ️</div>
        <div class="alert-content">
          <p class="alert-title">Razlog otkazivanja</p>
          <p class="alert-text">${reason}</p>
        </div>
      </div>

      <p>Ako imate pitanja, slobodno nas kontaktirajte.</p>
    </div>

    <div class="footer">
      <div class="footer-logo">🏠 Rab Booking</div>
      <p>© 2025 Rab Booking. Sva prava pridržana.</p>
    </div>
  </div>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: guestEmail,
      replyTo: ownerEmail || FROM_EMAIL,
      subject: subject,
      html: html,
      text: stripHtml(html),
    });
    logSuccess("Booking cancellation email sent", {email: guestEmail});
  } catch (error) {
    logError("Error sending cancellation email", error);
    throw error;
  }
}

/**
 * Send custom email to guest (Phase 2 feature)
 * Allows property owners to send custom messages to guests
 */
export async function sendCustomEmailToGuest(
  guestEmail: string,
  guestName: string,
  subject: string,
  message: string,
  ownerEmail?: string
): Promise<void> {
  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>${getBaseStyles()}
    .message-content {
      white-space: pre-wrap;
      background-color: ${COLORS.sectionBg};
      padding: 20px;
      border-radius: 12px;
      border: 1px solid ${COLORS.border};
      margin: 20px 0;
    }
  </style>
</head>
<body>
  <div class="email-wrapper">
    <div class="header">
      <div class="header-icon">✉️</div>
      <h1>${subject}</h1>
    </div>

    <div class="content">
      <p class="greeting">Poštovani/a ${guestName},</p>
      <div class="message-content">${message}</div>
      <p>Ako imate pitanja, slobodno odgovorite na ovaj email.</p>
    </div>

    <div class="footer">
      <div class="footer-logo">🏠 Rab Booking</div>
      <p>© 2025 Rab Booking. Sva prava pridržana.</p>
    </div>
  </div>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: guestEmail,
      replyTo: ownerEmail || FROM_EMAIL,
      subject: subject,
      html: html,
      text: stripHtml(html),
    });
    logSuccess("Custom email sent", {email: guestEmail});
  } catch (error) {
    logError("Error sending custom email", error);
    throw error;
  }
}

/**
 * Send suspicious activity alert email (Phase 3 security feature)
 * Alerts user when login from new device or location is detected
 */
export async function sendSuspiciousActivityEmail(
  userEmail: string,
  userName: string,
  deviceId: string | undefined,
  location: string | undefined,
  reason: string
): Promise<void> {
  const subject = "🔒 Sigurnosno upozorenje - Nova prijava";

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>${getBaseStyles()}
    .header { background: linear-gradient(135deg, #DC2626 0%, #B91C1C 100%); }
  </style>
</head>
<body>
  <div class="email-wrapper">
    <div class="header">
      <div class="header-icon">🔒</div>
      <h1>Sigurnosno upozorenje</h1>
      <p>Nova prijava detektovana</p>
    </div>

    <div class="content">
      <p class="greeting">Poštovani/a ${userName},</p>
      <p>Detektovali smo prijavu na vaš Rab Booking račun s ${reason === "new_device" ? "novog uređaja" : "nove lokacije"}.</p>

      <div class="section">
        <div class="section-title">🔐 Detalji prijave</div>
        <div class="detail-row">
          <span class="detail-label">Vrijeme</span>
          <span class="detail-value">${new Date().toLocaleString("hr-HR")}</span>
        </div>
        ${deviceId ? `
        <div class="detail-row">
          <span class="detail-label">ID uređaja</span>
          <span class="detail-value">${deviceId}</span>
        </div>` : ""}
        ${location ? `
        <div class="detail-row">
          <span class="detail-label">Lokacija</span>
          <span class="detail-value">${location}</span>
        </div>` : ""}
        <div class="detail-row">
          <span class="detail-label">Razlog upozorenja</span>
          <span class="detail-value">${reason === "new_device" ? "Prijava s novog uređaja" : "Prijava s nove lokacije"}</span>
        </div>
      </div>

      <div class="alert-box warning">
        <div class="alert-icon">⚠️</div>
        <div class="alert-content">
          <p class="alert-title">Je li ovo bila vaša prijava?</p>
          <p class="alert-text">Ako prepoznajete ovu aktivnost, možete sigurno ignorirati ovaj email.</p>
        </div>
      </div>

      <div class="alert-box error">
        <div class="alert-icon">🚨</div>
        <div class="alert-content">
          <p class="alert-title">Ako OVO NISTE bili vi:</p>
          <p class="alert-text">
            • Odmah promijenite lozinku<br>
            • Pregledajte aktivnost svog računa<br>
            • Kontaktirajte podršku ako primijetite sumnjive promjene
          </p>
        </div>
      </div>

      <p style="color: ${COLORS.textSecondary}; font-size: 13px;">Ovo je automatsko sigurnosno upozorenje za zaštitu vašeg računa.</p>
    </div>

    <div class="footer">
      <div class="footer-logo">🔒 Rab Booking Security</div>
      <p>© 2025 Rab Booking. Sva prava pridržana.</p>
      <p>Na ovaj email se ne može odgovoriti. Za podršku se prijavite u dashboard.</p>
    </div>
  </div>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} Security <${FROM_EMAIL}>`,
      to: userEmail,
      subject: subject,
      html: html,
      text: stripHtml(html),
    });
    logSuccess("Suspicious activity alert sent", {email: userEmail});
  } catch (error) {
    logError("Error sending suspicious activity email", error);
    throw error;
  }
}

/**
 * Send pending booking request email to guest (no payment required)
 */
export async function sendPendingBookingRequestEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  checkIn: Date,
  checkOut: Date,
  totalAmount: number,
  unitName: string,
  propertyName: string
): Promise<void> {
  const subject = `Zahtjev za rezervaciju primljen - ${bookingReference}`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>${getBaseStyles()}
    .header { background: linear-gradient(135deg, ${COLORS.warning} 0%, #D97706 100%); }
  </style>
</head>
<body>
  <div class="email-wrapper">
    <div class="header">
      <div class="header-icon">📋</div>
      <h1>Zahtjev zaprimljen</h1>
      <p>Referenca: ${bookingReference}</p>
    </div>

    <div class="content">
      <p class="greeting">Poštovani/a ${guestName},</p>
      <p>Hvala vam na zahtjevu za rezervaciju! Vaš zahtjev je zaprimljen i čeka odobrenje vlasnika.</p>

      <div class="section">
        <div class="section-title">📋 Detalji rezervacije</div>
        <div class="detail-row">
          <span class="detail-label">Nekretnina</span>
          <span class="detail-value">${propertyName}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Jedinica</span>
          <span class="detail-value">${unitName}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Check-in</span>
          <span class="detail-value">${formatDate(checkIn)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Check-out</span>
          <span class="detail-value">${formatDate(checkOut)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Referenca</span>
          <span class="detail-value">${bookingReference}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Ukupna cijena</span>
          <span class="detail-value">€${totalAmount.toFixed(2)}</span>
        </div>
      </div>

      <div class="alert-box info">
        <div class="alert-icon">⏳</div>
        <div class="alert-content">
          <p class="alert-title">Čeka se odobrenje</p>
          <p class="alert-text">Vlasnik će pregledati vaš zahtjev i uskoro vas kontaktirati s detaljima plaćanja ako bude odobren. Primit ćete email s potvrdom kada vaša rezervacija bude odobrena.</p>
        </div>
      </div>

      <p>Ako imate pitanja, slobodno kontaktirajte vlasnika.</p>
    </div>

    <div class="footer">
      <div class="footer-logo">🏠 Rab Booking</div>
      <p>© 2025 Rab Booking. Sva prava pridržana.</p>
    </div>
  </div>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: guestEmail,
      subject: subject,
      html: html,
      text: stripHtml(html),
    });
    logSuccess("Pending booking request email sent to guest", {email: guestEmail});
  } catch (error) {
    logError("Error sending pending booking request email", error);
    throw error;
  }
}

/**
 * Send pending booking notification to owner (no payment)
 */
export async function sendPendingBookingOwnerNotification(
  ownerEmail: string,
  ownerName: string,
  guestName: string,
  guestEmail: string,
  guestPhone: string,
  bookingReference: string,
  checkIn: Date,
  checkOut: Date,
  totalAmount: number,
  unitName: string,
  guestCount: number,
  notes?: string
): Promise<void> {
  const subject = `Nova rezervacija za odobrenje - ${bookingReference}`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>${getBaseStyles()}
    .header { background: linear-gradient(135deg, ${COLORS.warning} 0%, #D97706 100%); }
  </style>
</head>
<body>
  <div class="email-wrapper">
    <div class="header">
      <div class="header-icon">🔔</div>
      <h1>Nova rezervacija!</h1>
      <p>Čeka vaše odobrenje</p>
    </div>

    <div class="content">
      <p class="greeting">Poštovani/a ${ownerName},</p>
      <p>Primili ste novu rezervaciju putem booking widgeta koja zahtijeva vaše odobrenje.</p>

      <div class="section">
        <div class="section-title">📋 Detalji rezervacije</div>
        <div class="detail-row">
          <span class="detail-label">Jedinica</span>
          <span class="detail-value">${unitName}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Gost</span>
          <span class="detail-value">${guestName}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Email</span>
          <span class="detail-value">${guestEmail}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Telefon</span>
          <span class="detail-value">${guestPhone}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Broj gostiju</span>
          <span class="detail-value">${guestCount}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Check-in</span>
          <span class="detail-value">${formatDate(checkIn)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Check-out</span>
          <span class="detail-value">${formatDate(checkOut)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Referenca</span>
          <span class="detail-value">${bookingReference}</span>
        </div>
        ${notes ? `
        <div class="detail-row">
          <span class="detail-label">Napomena</span>
          <span class="detail-value">${notes}</span>
        </div>` : ""}
      </div>

      <div class="section">
        <div class="section-title">💳 Cijena</div>
        <div class="detail-row">
          <span class="detail-label">Ukupno</span>
          <span class="detail-value">€${totalAmount.toFixed(2)}</span>
        </div>
      </div>

      <div class="alert-box warning">
        <div class="alert-icon">⚠️</div>
        <div class="alert-content">
          <p class="alert-title">Akcija potrebna</p>
          <p class="alert-text">Prijavite se u Owner Dashboard da odobrite ili odbijete ovu rezervaciju. Nakon odobrenja, kontaktirajte gosta s detaljima plaćanja.</p>
        </div>
      </div>

      <div class="button-container">
        <a href="https://rab-booking-owner.web.app" class="button">
          🖥️ Otvori Dashboard
        </a>
      </div>
    </div>

    <div class="footer">
      <div class="footer-logo">🏠 Rab Booking</div>
      <p>© 2025 Rab Booking. Sva prava pridržana.</p>
    </div>
  </div>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: ownerEmail,
      subject: subject,
      html: html,
      text: stripHtml(html),
    });
    logSuccess("Pending booking owner notification sent", {email: ownerEmail});
  } catch (error) {
    logError("Error sending pending booking owner notification", error);
    throw error;
  }
}

/**
 * Send booking rejection email to guest
 */
export async function sendBookingRejectedEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  checkIn: Date,
  checkOut: Date,
  unitName: string,
  propertyName: string,
  reason?: string
): Promise<void> {
  const subject = `Zahtjev za rezervaciju odbijen - ${bookingReference}`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>${getBaseStyles()}
    .header { background: linear-gradient(135deg, ${COLORS.error} 0%, #DC2626 100%); }
  </style>
</head>
<body>
  <div class="email-wrapper">
    <div class="header">
      <div class="header-icon">❌</div>
      <h1>Zahtjev odbijen</h1>
      <p>Referenca: ${bookingReference}</p>
    </div>

    <div class="content">
      <p class="greeting">Poštovani/a ${guestName},</p>
      <p>Žao nam je, ali vaš zahtjev za rezervaciju je odbijen od strane vlasnika.</p>

      <div class="section">
        <div class="section-title">📋 Detalji rezervacije</div>
        <div class="detail-row">
          <span class="detail-label">Nekretnina</span>
          <span class="detail-value">${propertyName}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Jedinica</span>
          <span class="detail-value">${unitName}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Check-in</span>
          <span class="detail-value">${formatDate(checkIn)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Check-out</span>
          <span class="detail-value">${formatDate(checkOut)}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Referenca</span>
          <span class="detail-value">${bookingReference}</span>
        </div>
      </div>

      ${reason ? `
      <div class="alert-box error">
        <div class="alert-icon">ℹ️</div>
        <div class="alert-content">
          <p class="alert-title">Razlog odbijanja</p>
          <p class="alert-text">${reason}</p>
        </div>
      </div>
      ` : ""}

      <p>Ispričavamo se na neugodnosti. Slobodno pretražite naše druge dostupne nekretnine ili nas kontaktirajte za alternativne termine.</p>
    </div>

    <div class="footer">
      <div class="footer-logo">🏠 Rab Booking</div>
      <p>© 2025 Rab Booking. Sva prava pridržana.</p>
    </div>
  </div>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: guestEmail,
      subject: subject,
      html: html,
      text: stripHtml(html),
    });
    logSuccess("Booking rejection email sent to guest", {email: guestEmail});
  } catch (error) {
    logError("Error sending booking rejection email", error);
    throw error;
  }
}

/**
 * Helper: Strip HTML tags for plain text email fallback
 */
function stripHtml(html: string): string {
  return html
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "") // Remove style tags
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "") // Remove script tags
    .replace(/<[^>]+>/g, "") // Remove all HTML tags
    .replace(/&nbsp;/g, " ") // Replace &nbsp; with space
    .replace(/&amp;/g, "&") // Replace &amp; with &
    .replace(/&lt;/g, "<") // Replace &lt; with <
    .replace(/&gt;/g, ">") // Replace &gt; with >
    .replace(/&quot;/g, '"') // Replace &quot; with "
    .replace(/&#39;/g, "'") // Replace &#39; with '
    .replace(/\n\s*\n\s*\n/g, "\n\n") // Remove excessive blank lines
    .trim();
}

/**
 * Helper: Format date for email display
 */
function formatDate(date: Date): string {
  return date.toLocaleDateString("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

/**
 * Send email verification code to guest (OTP for booking)
 *
 * This sends a 6-digit code that the guest must enter to verify their email
 * before completing a booking (if requireEmailVerification is enabled)
 */
export async function sendEmailVerificationCode(
  guestEmail: string,
  verificationCode: string
): Promise<void> {
  const subject = "Vaš verifikacijski kod - Rab Booking";

  // Plain text version (for email clients that don't support HTML)
  const text = `
Vaš verifikacijski kod je: ${verificationCode}

Kod ističe za 10 minuta.

Ako niste zatražili ovaj kod, molimo ignorirajte ovaj email.

---
Rab Booking
  `.trim();

  // HTML version (clean, simple, spam-filter friendly)
  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>${getBaseStyles()}
    .code-box {
      background: linear-gradient(135deg, ${COLORS.primaryLight} 0%, #F3E8FF 100%);
      border: 2px solid ${COLORS.primary};
      border-radius: 16px;
      padding: 32px;
      text-align: center;
      margin: 28px 0;
    }
    .verification-code {
      font-size: 42px;
      font-weight: 700;
      color: ${COLORS.primary};
      letter-spacing: 12px;
      font-family: 'Courier New', monospace;
      margin: 0;
    }
    .code-expiry {
      color: ${COLORS.textSecondary};
      font-size: 14px;
      margin-top: 16px;
    }
  </style>
</head>
<body>
  <div class="email-wrapper">
    <div class="header">
      <div class="header-icon">🔐</div>
      <h1>Verifikacija emaila</h1>
      <p>Dovršite rezervaciju verifikacijom vašeg emaila</p>
    </div>

    <div class="content">
      <p class="greeting">Poštovani/a,</p>
      <p>Unesite ovaj verifikacijski kod kako biste nastavili s rezervacijom:</p>

      <div class="code-box">
        <p class="verification-code">${verificationCode}</p>
        <p class="code-expiry">⏱️ Ističe za 10 minuta</p>
      </div>

      <div class="alert-box warning">
        <div class="alert-icon">⚠️</div>
        <div class="alert-content">
          <p class="alert-title">Važno</p>
          <p class="alert-text">Ako niste zatražili ovaj kod, molimo ignorirajte ovaj email. Vaša rezervacija neće biti kreirana bez unosa koda.</p>
        </div>
      </div>

      <p style="color: ${COLORS.textSecondary}; font-size: 13px; text-align: center;">
        Ovo je automatski sigurnosni email za zaštitu vaše rezervacije.
      </p>
    </div>

    <div class="footer">
      <div class="footer-logo">🔐 Rab Booking</div>
      <p>Sigurni sustav verifikacije rezervacija</p>
      <p>© 2025 Rab Booking. Sva prava pridržana.</p>
    </div>
  </div>
</body>
</html>
  `;

  try {
    await getResendClient().emails.send({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: guestEmail,
      subject: subject,
      html: html,
      text: text,
    });
    logSuccess("Email verification code sent", {email: guestEmail});
  } catch (error) {
    logError("Error sending verification code email", error);
    throw error;
  }
}
