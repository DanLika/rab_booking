/**
 * Booking Confirmation Email Template V2
 * Mobile-Responsive Premium Design
 *
 * Design Specs:
 * - Card padding: 20-24px (mobile-friendly)
 * - Border radius: 12px (cards), 8px (buttons)
 * - Typography: 20px/600 (heading), 14px/400 (body), 15px/600 (price)
 * - Shadows: 0 1px 2px rgba(0,0,0,0.06) (cards), 0 2px 4px rgba(0,0,0,0.08) (button)
 * - Layout: Separated cards with gaps
 * - Colors: Neutral gray palette (white-label)
 * - Success emoji instead of SVG (Gmail compatibility)
 */

import {Resend} from "resend";
import {formatCurrency, formatDate, calculateNights, escapeHtml} from "../utils/template-helpers";

export interface BookingConfirmationParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  checkIn: Date;
  checkOut: Date;
  totalAmount: number;
  depositAmount: number;
  unitName: string;
  propertyName: string;
  viewBookingUrl: string;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate Refined Premium booking confirmation email
 */
export function generateBookingConfirmationEmailV2(
  params: BookingConfirmationParams
): string {
  const {
    guestName,
    bookingReference,
    checkIn,
    checkOut,
    totalAmount,
    depositAmount,
    unitName,
    propertyName,
    viewBookingUrl,
    contactEmail,
    contactPhone,
  } = params;

  const nights = calculateNights(checkIn, checkOut);
  const remainingAmount = totalAmount - depositAmount;

  return `
<!DOCTYPE html>
<html lang="hr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>Potvrda rezervacije - ${bookingReference}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB; line-height: 1.6;">

  <!-- Main Container -->
  <div style="max-width: 600px; margin: 0 auto; padding: 24px 16px;">

    <!-- Success Header Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px 20px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px; text-align: center;">
      <!-- Success Icon (Emoji - works in all email clients) -->
      <div style="margin-bottom: 12px; font-size: 48px; line-height: 1;">
        ✅
      </div>

      <!-- Title -->
      <h1 style="margin: 0 0 8px 0; font-size: 20px; font-weight: 600; line-height: 1.3; color: #1F2937;">
        Rezervacija potvrđena!
      </h1>

      <!-- Subtitle -->
      <p style="margin: 0 0 12px 0; font-size: 14px; font-weight: 400; line-height: 1.5; color: #6B7280;">
        Hvala vam na rezervaciji
      </p>

      <!-- Booking Reference -->
      <div style="display: inline-block; background-color: #F9FAFB; padding: 8px 12px; border-radius: 6px; border: 1px solid #E5E7EB;">
        <span style="font-size: 13px; font-weight: 400; color: #6B7280;">Referenca:</span>
        <strong style="font-size: 13px; font-weight: 600; color: #1F2937; margin-left: 4px;">${escapeHtml(bookingReference)}</strong>
      </div>
    </div>

    <!-- Greeting -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 20px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px;">
      <p style="margin: 0 0 12px 0; font-size: 14px; font-weight: 400; line-height: 1.5; color: #1F2937;">
        Poštovani/a <strong>${escapeHtml(guestName)}</strong>,
      </p>
      <p style="margin: 0; font-size: 14px; font-weight: 400; line-height: 1.5; color: #1F2937;">
        Vaša rezervacija je uspješno zaprimljena i čeka potvrdu uplate.
      </p>
    </div>

    <!-- Booking Details Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 20px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px;">
      <h2 style="margin: 0 0 16px 0; font-size: 16px; font-weight: 600; line-height: 1.3; color: #1F2937; border-bottom: 1px solid #E5E7EB; padding-bottom: 10px;">
        Detalji rezervacije
      </h2>

      <table role="presentation" cellpadding="0" cellspacing="0" style="width: 100%; border-collapse: collapse;">
        <tr>
          <td style="padding: 8px 0; font-size: 13px; font-weight: 400; color: #6B7280; vertical-align: top; width: 45%;">
            Nekretnina
          </td>
          <td style="padding: 8px 0; font-size: 14px; font-weight: 400; color: #1F2937; text-align: right;">
            ${escapeHtml(propertyName)}
          </td>
        </tr>
        <tr>
          <td style="padding: 8px 0; font-size: 13px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Jedinica
          </td>
          <td style="padding: 8px 0; font-size: 14px; font-weight: 400; color: #1F2937; text-align: right;">
            ${escapeHtml(unitName)}
          </td>
        </tr>
        <tr>
          <td style="padding: 8px 0; font-size: 13px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Prijava
          </td>
          <td style="padding: 8px 0; font-size: 14px; font-weight: 400; color: #1F2937; text-align: right;">
            ${formatDate(checkIn)}
          </td>
        </tr>
        <tr>
          <td style="padding: 8px 0; font-size: 13px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Odjava
          </td>
          <td style="padding: 8px 0; font-size: 14px; font-weight: 400; color: #1F2937; text-align: right;">
            ${formatDate(checkOut)}
          </td>
        </tr>
        <tr>
          <td style="padding: 8px 0; font-size: 13px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Broj noćenja
          </td>
          <td style="padding: 8px 0; font-size: 14px; font-weight: 400; color: #1F2937; text-align: right;">
            ${nights} ${nights === 1 ? "noć" : nights < 5 ? "noći" : "noći"}
          </td>
        </tr>
      </table>
    </div>

    <!-- Payment Details Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 20px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px;">
      <h2 style="margin: 0 0 16px 0; font-size: 16px; font-weight: 600; line-height: 1.3; color: #1F2937; border-bottom: 1px solid #E5E7EB; padding-bottom: 10px;">
        Detalji plaćanja
      </h2>

      <table role="presentation" cellpadding="0" cellspacing="0" style="width: 100%; border-collapse: collapse;">
        ${depositAmount > 0 ? `
        <tr>
          <td style="padding: 8px 0; font-size: 13px; font-weight: 400; color: #6B7280; vertical-align: top; width: 50%;">
            Kapara
          </td>
          <td style="padding: 8px 0; font-size: 14px; font-weight: 400; color: #1F2937; text-align: right;">
            ${formatCurrency(depositAmount)}
          </td>
        </tr>
        ` : ''}

        ${remainingAmount > 0 ? `
        <tr>
          <td style="padding: 8px 0; font-size: 13px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Preostalo (pri dolasku)
          </td>
          <td style="padding: 8px 0; font-size: 14px; font-weight: 400; color: #1F2937; text-align: right;">
            ${formatCurrency(remainingAmount)}
          </td>
        </tr>
        ` : ''}

        <tr style="border-top: 2px solid #E5E7EB;">
          <td style="padding: 12px 0 0 0; font-size: 14px; font-weight: 600; color: #1F2937;">
            Ukupna cijena
          </td>
          <td style="padding: 12px 0 0 0; font-size: 15px; font-weight: 600; color: #1F2937; text-align: right;">
            ${formatCurrency(totalAmount)}
          </td>
        </tr>
      </table>
    </div>

    ${depositAmount > 0 ? `
    <!-- Payment Instructions Alert -->
    <div style="background-color: #FEF3C7; border-left: 4px solid #D97706; border-radius: 8px; padding: 16px; margin-bottom: 16px;">
      <p style="margin: 0 0 6px 0; font-size: 14px; font-weight: 600; color: #92400E;">
        ⚠️ Upute za plaćanje
      </p>
      <p style="margin: 0; font-size: 13px; font-weight: 400; line-height: 1.5; color: #78350F;">
        Molimo uplatite kaparu od <strong>${formatCurrency(depositAmount)}</strong> u roku od 3 dana.
        <strong>VAŽNO:</strong> Obavezno navedite referencu rezervacije <strong>${escapeHtml(bookingReference)}</strong> u opisu uplate!
      </p>
    </div>

    <!-- Payment Confirmation Notice -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 16px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px;">
      <p style="margin: 0; font-size: 13px; font-weight: 400; line-height: 1.5; color: #1F2937; text-align: center;">
        Kada primimo vašu uplatu, poslat ćemo vam email s potvrdom.
      </p>
    </div>
    ` : ''}

    <!-- View Booking Button -->
    <div style="text-align: center; margin-bottom: 16px;">
      <a href="${viewBookingUrl}" style="display: inline-block; background-color: #374151; color: #FFFFFF; text-decoration: none; padding: 12px 24px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08); font-size: 14px; font-weight: 600;">
        Pregledaj moju rezervaciju
      </a>
    </div>

    <!-- Info Alert -->
    <div style="background-color: #EFF6FF; border-left: 4px solid #2563EB; border-radius: 8px; padding: 16px; margin-bottom: 16px;">
      <p style="margin: 0; font-size: 13px; font-weight: 400; line-height: 1.5; color: #1E40AF;">
        ℹ️ Sačuvajte ovaj email kako biste u bilo kojem trenutku mogli pristupiti detaljima rezervacije.
      </p>
    </div>

    <!-- Footer -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 20px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); text-align: center;">
      <p style="margin: 0 0 10px 0; font-size: 13px; font-weight: 400; color: #6B7280;">
        Imate pitanja? Kontaktirajte nas:
      </p>
      ${contactEmail ? `
      <p style="margin: 0 0 4px 0;">
        <a href="mailto:${escapeHtml(contactEmail)}" style="color: #2563EB; text-decoration: none; font-size: 13px;">
          ${escapeHtml(contactEmail)}
        </a>
      </p>
      ` : ''}
      ${contactPhone ? `
      <p style="margin: 0;">
        <a href="tel:${escapeHtml(contactPhone)}" style="color: #2563EB; text-decoration: none; font-size: 13px;">
          ${escapeHtml(contactPhone)}
        </a>
      </p>
      ` : ''}

      <div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid #E5E7EB;">
        <p style="margin: 0; font-size: 11px; color: #9CA3AF;">
          © ${new Date().getFullYear()} BookBed. Sva prava pridržana.
        </p>
      </div>
    </div>

  </div>
</body>
</html>
  `.trim();
}

/**
 * Send Refined Premium booking confirmation email via Resend
 */
export async function sendBookingConfirmationEmailV2(
  resendClient: Resend,
  params: BookingConfirmationParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateBookingConfirmationEmailV2(params);
  const subject = `Potvrda rezervacije - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
