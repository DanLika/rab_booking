import {Resend} from "resend";
import {logError, logSuccess} from "./logger";

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
const WIDGET_URL = process.env.WIDGET_URL || "https://rab-booking-widget.web.app";

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
  ownerEmail?: string
): Promise<void> {
  const subject = `[RabBooking] Potvrda rezervacije - ${bookingReference}`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #6B8E23; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; background: #f9f9f9; }
    .booking-details { background: white; padding: 15px; margin: 15px 0; border-radius: 8px; }
    .detail-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
    .highlight { background: #fff9c4; padding: 15px; border-radius: 8px; margin: 15px 0; }
    .footer { text-align: center; padding: 20px; color: #777; font-size: 12px; }
    .button { display: inline-block; padding: 12px 24px; background: #6B8E23; color: white; text-decoration: none; border-radius: 6px; margin: 15px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Booking Confirmed!</h1>
      <p>Reference: ${bookingReference}</p>
    </div>

    <div class="content">
      <p>Dear ${guestName},</p>
      <p>Thank you for your booking! Your reservation has been received and is awaiting payment confirmation.</p>

      <div class="booking-details">
        <h3>Booking Details</h3>
        <div class="detail-row">
          <span>Property:</span>
          <strong>${propertyName}</strong>
        </div>
        <div class="detail-row">
          <span>Unit:</span>
          <strong>${unitName}</strong>
        </div>
        <div class="detail-row">
          <span>Check-in:</span>
          <strong>${formatDate(checkIn)}</strong>
        </div>
        <div class="detail-row">
          <span>Check-out:</span>
          <strong>${formatDate(checkOut)}</strong>
        </div>
        <div class="detail-row">
          <span>Reference:</span>
          <strong>${bookingReference}</strong>
        </div>
      </div>

      <div class="booking-details">
        <h3>Payment Details</h3>
        <div class="detail-row">
          <span>Total Amount:</span>
          <strong>€${totalAmount.toFixed(2)}</strong>
        </div>
        <div class="detail-row">
          <span>Deposit (20%):</span>
          <strong>€${depositAmount.toFixed(2)}</strong>
        </div>
        <div class="detail-row">
          <span>Remaining (pay on arrival):</span>
          <strong>€${(totalAmount - depositAmount).toFixed(2)}</strong>
        </div>
      </div>

      <div class="highlight">
        <h3>⚠️ Payment Instructions</h3>
        <p><strong>Please transfer €${depositAmount.toFixed(2)} within 3 days</strong></p>
        <p><strong>Account Holder:</strong> Your Business Name</p>
        <p><strong>Bank:</strong> Your Bank</p>
        <p><strong>IBAN:</strong> HR1234567890123456789</p>
        <p><strong>Reference:</strong> ${bookingReference}</p>
        <p style="font-size: 12px; margin-top: 10px;">⚠️ Important: Include the booking reference in the transfer description!</p>
      </div>

      <p>Once we receive your payment, we will send you a confirmation email.</p>

      <div style="text-align: center; margin: 25px 0;">
        <a href="${WIDGET_URL}/view?ref=${encodeURIComponent(bookingReference)}&email=${encodeURIComponent(guestEmail)}&token=${encodeURIComponent(accessToken)}" class="button">
          📋 View My Booking
        </a>
      </div>

      <p style="font-size: 12px; color: #666; text-align: center;">
        💡 Tip: Save this email to view your booking details anytime, or look up your booking manually using your email and booking reference.
      </p>

      <p>If you have any questions, please contact us.</p>
    </div>

    <div class="footer">
      <p>© 2025 Rab Booking. All rights reserved.</p>
      <p>This email was sent regarding your booking ${bookingReference}</p>
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
 * Send booking approved email to guest
 */
export async function sendBookingApprovedEmail(
  guestEmail: string,
  guestName: string,
  bookingReference: string,
  checkIn: Date,
  checkOut: Date,
  propertyName: string,
  ownerEmail?: string
): Promise<void> {
  const subject = `[RabBooking] Potvrda plaćanja - ${bookingReference}`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #4CAF50; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; background: #f9f9f9; }
    .success-icon { font-size: 48px; margin: 20px 0; }
    .booking-details { background: white; padding: 15px; margin: 15px 0; border-radius: 8px; }
    .footer { text-align: center; padding: 20px; color: #777; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="success-icon">✅</div>
      <h1>Payment Received!</h1>
      <p>Your booking is confirmed</p>
    </div>

    <div class="content">
      <p>Dear ${guestName},</p>
      <p>Great news! We have received your payment and your booking is now confirmed.</p>

      <div class="booking-details">
        <h3>Booking Confirmed</h3>
        <p><strong>Property:</strong> ${propertyName}</p>
        <p><strong>Check-in:</strong> ${formatDate(checkIn)}</p>
        <p><strong>Check-out:</strong> ${formatDate(checkOut)}</p>
        <p><strong>Reference:</strong> ${bookingReference}</p>
      </div>

      <p>We look forward to welcoming you!</p>
      <p>If you have any questions, please don't hesitate to contact us.</p>
    </div>

    <div class="footer">
      <p>© 2025 Rab Booking. All rights reserved.</p>
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
  unitName: string
): Promise<void> {
  const subject = `Nova rezervacija - ${bookingReference}`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #FF9800; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; background: #f9f9f9; }
    .booking-details { background: white; padding: 15px; margin: 15px 0; border-radius: 8px; }
    .alert { background: #fff9c4; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #FBC02D; }
    .footer { text-align: center; padding: 20px; color: #777; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔔 Nova rezervacija!</h1>
      <p>Čeka vašu potvrdu</p>
    </div>

    <div class="content">
      <p>Poštovani ${ownerName},</p>
      <p>Primili ste novu rezervaciju putem booking widget-a.</p>

      <div class="booking-details">
        <h3>Detalji rezervacije</h3>
        <p><strong>Jedinica:</strong> ${unitName}</p>
        <p><strong>Gost:</strong> ${guestName}</p>
        <p><strong>Email:</strong> ${guestEmail}</p>
        <p><strong>Check-in:</strong> ${formatDate(checkIn)}</p>
        <p><strong>Check-out:</strong> ${formatDate(checkOut)}</p>
        <p><strong>Referenca:</strong> ${bookingReference}</p>
      </div>

      <div class="booking-details">
        <h3>Plaćanje</h3>
        <p><strong>Ukupno:</strong> €${totalAmount.toFixed(2)}</p>
        <p><strong>Avans (20%):</strong> €${depositAmount.toFixed(2)}</p>
        <p><strong>Ostatak:</strong> €${(totalAmount - depositAmount).toFixed(2)}</p>
      </div>

      <div class="alert">
        <p><strong>⚠️ Akcija potrebna:</strong></p>
        <p>Gost će izvršiti bankovnu uplatu. Kada primite uplatu od €${depositAmount.toFixed(2)}
        sa referencom <strong>${bookingReference}</strong>, prijavite se u dashboard i odobrite rezervaciju.</p>
      </div>

      <p>Prijavite se u Owner Dashboard da biste upravljali rezervacijom.</p>
    </div>

    <div class="footer">
      <p>© 2025 Rab Booking. All rights reserved.</p>
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
  const subject = `[RabBooking] Otkazana rezervacija - ${bookingReference}`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #f44336; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; background: #f9f9f9; }
    .footer { text-align: center; padding: 20px; color: #777; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Booking Cancelled</h1>
      <p>Reference: ${bookingReference}</p>
    </div>

    <div class="content">
      <p>Dear ${guestName},</p>
      <p>Your booking ${bookingReference} has been cancelled.</p>
      <p><strong>Reason:</strong> ${reason}</p>
      <p>If you have any questions, please contact us.</p>
    </div>

    <div class="footer">
      <p>© 2025 Rab Booking. All rights reserved.</p>
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
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #2c5282; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; background-color: #f9f9f9; }
    .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
    .message { white-space: pre-wrap; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>${subject}</h1>
    </div>

    <div class="content">
      <p>Dear ${guestName},</p>
      <div class="message">${message}</div>
      <p>If you have any questions, please feel free to reply to this email.</p>
    </div>

    <div class="footer">
      <p>© 2025 Rab Booking. All rights reserved.</p>
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
  const subject = "[RabBooking] 🔒 Sigurnosno upozorenje - Nova prijava detektovana";

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #FF5722; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; background: #f9f9f9; }
    .alert-box { background: #fff3e0; border-left: 4px solid #FF9800; padding: 15px; margin: 15px 0; }
    .info-box { background: white; padding: 15px; margin: 15px 0; border-radius: 8px; }
    .footer { text-align: center; padding: 20px; color: #777; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔒 Security Alert</h1>
      <p>New login activity detected</p>
    </div>

    <div class="content">
      <p>Hi ${userName},</p>
      <p>We detected a login to your Rab Booking account from a ${reason === "new_device" ? "new device" : "new location"}.</p>

      <div class="info-box">
        <h3>Login Details</h3>
        <p><strong>When:</strong> ${new Date().toLocaleString("en-GB")}</p>
        ${deviceId ? `<p><strong>Device ID:</strong> ${deviceId}</p>` : ""}
        ${location ? `<p><strong>Location:</strong> ${location}</p>` : ""}
        <p><strong>Reason:</strong> ${reason === "new_device" ? "Login from new device" : "Login from new location"}</p>
      </div>

      <div class="alert-box">
        <h3>⚠️ Was this you?</h3>
        <p>If you recognize this activity, you can safely ignore this email.</p>
        <p><strong>If this wasn't you:</strong></p>
        <ul>
          <li>Change your password immediately</li>
          <li>Review your account activity</li>
          <li>Contact support if you see any suspicious changes</li>
        </ul>
      </div>

      <p>This is an automated security alert to keep your account safe.</p>
    </div>

    <div class="footer">
      <p>© 2025 Rab Booking Security Team</p>
      <p>This email cannot be replied to. For support, please log into your dashboard.</p>
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
  const subject = `[RabBooking] Zahtjev za rezervaciju primljen - ${bookingReference}`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #FF9800; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; background: #f9f9f9; }
    .booking-details { background: white; padding: 15px; margin: 15px 0; border-radius: 8px; }
    .detail-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
    .highlight { background: #fff9c4; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #FBC02D; }
    .footer { text-align: center; padding: 20px; color: #777; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>📋 Booking Request Received</h1>
      <p>Reference: ${bookingReference}</p>
    </div>

    <div class="content">
      <p>Dear ${guestName},</p>
      <p>Thank you for your booking request! We have received your reservation and it is pending approval from the property owner.</p>

      <div class="booking-details">
        <h3>Booking Details</h3>
        <div class="detail-row">
          <span>Property:</span>
          <strong>${propertyName}</strong>
        </div>
        <div class="detail-row">
          <span>Unit:</span>
          <strong>${unitName}</strong>
        </div>
        <div class="detail-row">
          <span>Check-in:</span>
          <strong>${formatDate(checkIn)}</strong>
        </div>
        <div class="detail-row">
          <span>Check-out:</span>
          <strong>${formatDate(checkOut)}</strong>
        </div>
        <div class="detail-row">
          <span>Reference:</span>
          <strong>${bookingReference}</strong>
        </div>
        <div class="detail-row">
          <span>Total Amount:</span>
          <strong>€${totalAmount.toFixed(2)}</strong>
        </div>
      </div>

      <div class="highlight">
        <p><strong>⏳ Pending Approval</strong></p>
        <p>The property owner will review your booking request and contact you shortly with payment details if approved.</p>
        <p>You will receive a confirmation email once your booking is approved.</p>
      </div>

      <p>If you have any questions, please don't hesitate to contact the property owner.</p>
    </div>

    <div class="footer">
      <p>© 2025 Rab Booking. All rights reserved.</p>
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
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #FF9800; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; background: #f9f9f9; }
    .booking-details { background: white; padding: 15px; margin: 15px 0; border-radius: 8px; }
    .alert { background: #fff9c4; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #FBC02D; }
    .footer { text-align: center; padding: 20px; color: #777; font-size: 12px; }
    .action-btn { display: inline-block; padding: 12px 24px; background: #6B8E23; color: white; text-decoration: none; border-radius: 6px; margin: 10px 5px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔔 Nova rezervacija za odobrenje!</h1>
      <p>Čeka vašu potvrdu</p>
    </div>

    <div class="content">
      <p>Poštovani ${ownerName},</p>
      <p>Primili ste novu rezervaciju putem booking widgeta koja zahtijeva vaše odobrenje.</p>

      <div class="booking-details">
        <h3>Detalji rezervacije</h3>
        <p><strong>Jedinica:</strong> ${unitName}</p>
        <p><strong>Gost:</strong> ${guestName}</p>
        <p><strong>Email:</strong> ${guestEmail}</p>
        <p><strong>Telefon:</strong> ${guestPhone}</p>
        <p><strong>Broj gostiju:</strong> ${guestCount}</p>
        <p><strong>Check-in:</strong> ${formatDate(checkIn)}</p>
        <p><strong>Check-out:</strong> ${formatDate(checkOut)}</p>
        <p><strong>Referenca:</strong> ${bookingReference}</p>
        ${notes ? `<p><strong>Napomena:</strong> ${notes}</p>` : ""}
      </div>

      <div class="booking-details">
        <h3>Cijena</h3>
        <p><strong>Ukupno:</strong> €${totalAmount.toFixed(2)}</p>
      </div>

      <div class="alert">
        <p><strong>⚠️ Akcija potrebna:</strong></p>
        <p>Prijavite se u Owner Dashboard da odobrite ili odbijete ovu rezervaciju.</p>
        <p>Nakon odobrenja, kontaktirajte gosta sa detaljima plaćanja.</p>
      </div>

      <p style="text-align: center;">
        <a href="#" class="action-btn">Prijavite se u Dashboard</a>
      </p>
    </div>

    <div class="footer">
      <p>© 2025 Rab Booking. All rights reserved.</p>
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
  const subject = `[RabBooking] Zahtjev za rezervaciju odbijen - ${bookingReference}`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #EF4444; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; background: #f9f9f9; }
    .booking-details { background: white; padding: 15px; margin: 15px 0; border-radius: 8px; }
    .detail-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
    .highlight { background: #FEE2E2; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #EF4444; }
    .footer { text-align: center; padding: 20px; color: #777; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>❌ Booking Request Declined</h1>
      <p>Reference: ${bookingReference}</p>
    </div>

    <div class="content">
      <p>Dear ${guestName},</p>
      <p>We regret to inform you that your booking request has been declined by the property owner.</p>

      <div class="booking-details">
        <h3>Booking Details</h3>
        <div class="detail-row">
          <span>Property:</span>
          <strong>${propertyName}</strong>
        </div>
        <div class="detail-row">
          <span>Unit:</span>
          <strong>${unitName}</strong>
        </div>
        <div class="detail-row">
          <span>Check-in:</span>
          <strong>${formatDate(checkIn)}</strong>
        </div>
        <div class="detail-row">
          <span>Check-out:</span>
          <strong>${formatDate(checkOut)}</strong>
        </div>
        <div class="detail-row">
          <span>Reference:</span>
          <strong>${bookingReference}</strong>
        </div>
      </div>

      ${reason ? `
      <div class="highlight">
        <p><strong>Reason:</strong></p>
        <p>${reason}</p>
      </div>
      ` : ""}

      <p>We apologize for any inconvenience. Please feel free to browse our other available properties or contact us for alternative dates.</p>
    </div>

    <div class="footer">
      <p>© 2025 Rab Booking. All rights reserved.</p>
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
  const subject = "Your Verification Code - Rab Booking";

  // Plain text version (for email clients that don't support HTML)
  const text = `
Your verification code is: ${verificationCode}

This code will expire in 10 minutes.

If you didn't request this code, please ignore this email.

---
Rab Booking
  `.trim();

  // HTML version (clean, simple, spam-filter friendly)
  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
      background-color: #f5f5f5;
    }
    .container {
      background-color: white;
      border-radius: 8px;
      padding: 40px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .header {
      text-align: center;
      margin-bottom: 30px;
    }
    .header h1 {
      color: #2563eb;
      margin: 0;
      font-size: 24px;
    }
    .code-container {
      background-color: #f0f9ff;
      border: 2px solid #2563eb;
      border-radius: 8px;
      padding: 24px;
      text-align: center;
      margin: 24px 0;
    }
    .code {
      font-size: 36px;
      font-weight: bold;
      color: #2563eb;
      letter-spacing: 8px;
      font-family: 'Courier New', monospace;
    }
    .expiry {
      color: #666;
      font-size: 14px;
      margin-top: 12px;
    }
    .instructions {
      background-color: #fef3c7;
      border-left: 4px solid #f59e0b;
      padding: 16px;
      margin: 24px 0;
      border-radius: 4px;
    }
    .instructions p {
      margin: 0;
      color: #78350f;
    }
    .footer {
      text-align: center;
      margin-top: 32px;
      padding-top: 24px;
      border-top: 1px solid #e5e7eb;
      color: #6b7280;
      font-size: 12px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔐 Email Verification</h1>
      <p>Complete your booking by verifying your email</p>
    </div>

    <p>Enter this verification code to continue with your booking:</p>

    <div class="code-container">
      <div class="code">${verificationCode}</div>
      <div class="expiry">⏱️ Expires in 10 minutes</div>
    </div>

    <div class="instructions">
      <p><strong>Important:</strong> If you didn't request this code, please ignore this email. Your booking will not be created without entering the code.</p>
    </div>

    <p style="color: #666; font-size: 14px; text-align: center;">
      This is an automated security email to protect your booking.
    </p>

    <div class="footer">
      <p><strong>Rab Booking</strong></p>
      <p>Secure booking verification system</p>
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
