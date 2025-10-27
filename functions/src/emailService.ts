import {Resend} from "resend";

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
// PRODUCTION: Change to your verified domain (e.g., "noreply@rab-booking.com")
const FROM_EMAIL = "onboarding@resend.dev"; // TEST MODE - emails go to ababic785@gmail.com
const FROM_NAME = "Rab Booking";

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
  ownerEmail?: string
): Promise<void> {
  const subject = `Booking Confirmation - ${bookingReference}`;

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
    });
    console.log(`Booking confirmation email sent to ${guestEmail}`);
  } catch (error) {
    console.error("Error sending booking confirmation email:", error);
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
  const subject = `Payment Confirmed - ${bookingReference}`;

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
    });
    console.log(`Booking approved email sent to ${guestEmail}`);
  } catch (error) {
    console.error("Error sending booking approved email:", error);
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
    });
    console.log(`Owner notification email sent to ${ownerEmail}`);
  } catch (error) {
    console.error("Error sending owner notification email:", error);
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
  const subject = `Booking Cancelled - ${bookingReference}`;

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
    });
    console.log(`Booking cancellation email sent to ${guestEmail}`);
  } catch (error) {
    console.error("Error sending cancellation email:", error);
    throw error;
  }
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
