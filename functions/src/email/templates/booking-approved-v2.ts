/**
 * Booking Approved Email Template V2
 * OPCIJA A: Refined Premium Design
 *
 * Design Specs:
 * - Card padding: 28px
 * - Border radius: 12px (cards), 8px (buttons)
 * - Typography: 22px/600 (heading), 15px/400 (body), 16px/600 (price)
 * - Shadows: 0 1px 2px rgba(0,0,0,0.06) (cards), 0 2px 4px rgba(0,0,0,0.08) (button)
 * - Layout: Separated cards with gaps
 * - Colors: Neutral gray palette (white-label) + Success green
 */

import {Resend} from "resend";
import {formatCurrency, formatDate, calculateNights} from "../utils/template-helpers";

export interface BookingApprovedParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  checkIn: Date;
  checkOut: Date;
  propertyName: string;
  unitName?: string;
  viewBookingUrl?: string;
  totalAmount?: number;
  depositAmount?: number;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate Refined Premium booking approved email
 */
export function generateBookingApprovedEmailV2(
  params: BookingApprovedParams
): string {
  const {
    guestName,
    bookingReference,
    checkIn,
    checkOut,
    propertyName,
    unitName,
    viewBookingUrl,
    totalAmount,
    depositAmount,
    contactEmail,
    contactPhone,
  } = params;

  const nights = calculateNights(checkIn, checkOut);
  const remainingAmount = totalAmount && depositAmount ? totalAmount - depositAmount : 0;

  return `
<!DOCTYPE html>
<html lang="hr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>Rezervacija potvrđena - ${bookingReference}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB; line-height: 1.6;">

  <!-- Main Container -->
  <div style="max-width: 600px; margin: 0 auto; padding: 24px 16px;">

    <!-- Success Header Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px; text-align: center;">
      <!-- Success Icon -->
      <div style="margin-bottom: 16px;">
        <svg width="64" height="64" viewBox="0 0 64 64" style="display: inline-block;">
          <circle cx="32" cy="32" r="30" fill="#D1FAE5" stroke="#059669" stroke-width="2"/>
          <path d="M20 32L28 40L44 24" stroke="#059669" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
        </svg>
      </div>

      <!-- Title -->
      <h1 style="margin: 0 0 8px 0; font-size: 22px; font-weight: 600; line-height: 1.3; color: #1F2937;">
        Rezervacija potvrđena!
      </h1>

      <!-- Subtitle -->
      <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #6B7280;">
        Sjajne vijesti! Radujemo se vašem dolasku
      </p>

      <!-- Booking Reference -->
      <div style="display: inline-block; background-color: #F9FAFB; padding: 8px 16px; border-radius: 6px; border: 1px solid #E5E7EB;">
        <span style="font-size: 14px; font-weight: 400; color: #6B7280;">Referenca:</span>
        <strong style="font-size: 14px; font-weight: 600; color: #1F2937; margin-left: 4px;">${bookingReference}</strong>
      </div>
    </div>

    <!-- Greeting -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px;">
      <p style="margin: 0 0 16px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1F2937;">
        Poštovani/a <strong>${guestName}</strong>,
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1F2937;">
        Vaša rezervacija je uspješno potvrđena! Možete se radovati svom boravku.
      </p>
    </div>

    <!-- Success Alert -->
    <div style="background-color: #D1FAE5; border-left: 4px solid #059669; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0 0 8px 0; font-size: 16px; font-weight: 600; color: #065F46;">
        ✓ Rezervacija potvrđena
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #047857;">
        Sve je spremno! Očekujemo vas ${formatDate(checkIn)}.
      </p>
    </div>

    <!-- Booking Details Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px;">
      <h2 style="margin: 0 0 20px 0; font-size: 18px; font-weight: 600; line-height: 1.3; color: #1F2937; border-bottom: 1px solid #E5E7EB; padding-bottom: 12px;">
        Detalji rezervacije
      </h2>

      <table role="presentation" cellpadding="0" cellspacing="0" style="width: 100%; border-collapse: collapse;">
        <tr>
          <td style="padding: 10px 0; font-size: 14px; font-weight: 400; color: #6B7280; vertical-align: top; width: 45%;">
            Nekretnina
          </td>
          <td style="padding: 10px 0; font-size: 15px; font-weight: 400; color: #1F2937; text-align: right;">
            ${propertyName}
          </td>
        </tr>
        ${unitName ? `
        <tr>
          <td style="padding: 10px 0; font-size: 14px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Jedinica
          </td>
          <td style="padding: 10px 0; font-size: 15px; font-weight: 400; color: #1F2937; text-align: right;">
            ${unitName}
          </td>
        </tr>
        ` : ''}
        <tr>
          <td style="padding: 10px 0; font-size: 14px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Prijava
          </td>
          <td style="padding: 10px 0; font-size: 15px; font-weight: 400; color: #1F2937; text-align: right;">
            ${formatDate(checkIn)}
          </td>
        </tr>
        <tr>
          <td style="padding: 10px 0; font-size: 14px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Odjava
          </td>
          <td style="padding: 10px 0; font-size: 15px; font-weight: 400; color: #1F2937; text-align: right;">
            ${formatDate(checkOut)}
          </td>
        </tr>
        <tr>
          <td style="padding: 10px 0; font-size: 14px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Broj noćenja
          </td>
          <td style="padding: 10px 0; font-size: 15px; font-weight: 400; color: #1F2937; text-align: right;">
            ${nights} ${nights === 1 ? "noć" : nights < 5 ? "noći" : "noći"}
          </td>
        </tr>
      </table>
    </div>

    ${totalAmount && depositAmount ? `
    <!-- Payment Details Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px;">
      <h2 style="margin: 0 0 20px 0; font-size: 18px; font-weight: 600; line-height: 1.3; color: #1F2937; border-bottom: 1px solid #E5E7EB; padding-bottom: 12px;">
        Detalji plaćanja
      </h2>

      <table role="presentation" cellpadding="0" cellspacing="0" style="width: 100%; border-collapse: collapse;">
        ${depositAmount > 0 ? `
        <tr>
          <td style="padding: 10px 0; font-size: 14px; font-weight: 400; color: #6B7280; vertical-align: top; width: 50%;">
            Uplaćeno
          </td>
          <td style="padding: 10px 0; font-size: 15px; font-weight: 400; color: #1F2937; text-align: right;">
            ${formatCurrency(depositAmount)}
          </td>
        </tr>
        ` : ''}

        ${remainingAmount > 0 ? `
        <tr>
          <td style="padding: 10px 0; font-size: 14px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Preostalo (pri dolasku)
          </td>
          <td style="padding: 10px 0; font-size: 15px; font-weight: 400; color: #1F2937; text-align: right;">
            ${formatCurrency(remainingAmount)}
          </td>
        </tr>
        ` : ''}

        <tr style="border-top: 2px solid #E5E7EB;">
          <td style="padding: 16px 0 0 0; font-size: 15px; font-weight: 600; color: #1F2937;">
            Ukupna cijena
          </td>
          <td style="padding: 16px 0 0 0; font-size: 16px; font-weight: 600; color: #1F2937; text-align: right;">
            ${formatCurrency(totalAmount)}
          </td>
        </tr>
      </table>
    </div>
    ` : ''}

    ${viewBookingUrl ? `
    <!-- View Booking Button -->
    <div style="text-align: center; margin-bottom: 16px;">
      <a href="${viewBookingUrl}" style="display: inline-block; background-color: #374151; color: #FFFFFF; text-decoration: none; padding: 14px 28px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08); font-size: 15px; font-weight: 600;">
        Pregledaj moju rezervaciju
      </a>
    </div>

    <!-- Info Alert -->
    <div style="background-color: #EFF6FF; border-left: 4px solid #2563EB; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1E40AF;">
        ℹ️ Sačuvajte ovaj email kako biste u bilo kojem trenutku mogli pristupiti detaljima rezervacije.
      </p>
    </div>
    ` : ''}

    <!-- Footer -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); text-align: center;">
      <p style="margin: 0 0 12px 0; font-size: 14px; font-weight: 400; color: #6B7280;">
        Imate pitanja? Kontaktirajte nas:
      </p>
      ${contactEmail ? `
      <p style="margin: 0 0 6px 0;">
        <a href="mailto:${contactEmail}" style="color: #2563EB; text-decoration: none; font-size: 14px;">
          ${contactEmail}
        </a>
      </p>
      ` : ''}
      ${contactPhone ? `
      <p style="margin: 0;">
        <a href="tel:${contactPhone}" style="color: #2563EB; text-decoration: none; font-size: 14px;">
          ${contactPhone}
        </a>
      </p>
      ` : ''}

      <div style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #E5E7EB;">
        <p style="margin: 0; font-size: 12px; color: #9CA3AF;">
          © ${new Date().getFullYear()} Sva prava pridržana.
        </p>
      </div>
    </div>

  </div>
</body>
</html>
  `.trim();
}

/**
 * Send Refined Premium booking approved email via Resend
 */
export async function sendBookingApprovedEmailV2(
  resendClient: Resend,
  params: BookingApprovedParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateBookingApprovedEmailV2(params);
  const subject = `Rezervacija potvrđena - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
