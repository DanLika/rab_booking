/**
 * Guest Cancellation Email Template V2
 * OPCIJA A: Refined Premium Design
 *
 * Design Specs:
 * - Card padding: 28px
 * - Border radius: 12px (cards), 8px (buttons)
 * - Typography: 22px/600 (heading), 15px/400 (body), 16px/600 (price)
 * - Shadows: 0 1px 2px rgba(0,0,0,0.06) (cards), 0 2px 4px rgba(0,0,0,0.08) (button)
 * - Layout: Separated cards with gaps
 * - Colors: Neutral gray palette + Error red
 */

import {Resend} from "resend";
import {formatCurrency, formatDate} from "../utils/template-helpers";

export interface GuestCancellationParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  unitName?: string;
  checkIn: Date;
  checkOut: Date;
  refundAmount?: number;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate Refined Premium guest cancellation email
 */
export function generateGuestCancellationEmailV2(
  params: GuestCancellationParams
): string {
  const {
    guestName,
    bookingReference,
    propertyName,
    unitName,
    checkIn,
    checkOut,
    refundAmount,
    contactEmail,
    contactPhone,
  } = params;

  return `
<!DOCTYPE html>
<html lang="hr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>Rezervacija otkazana - ${bookingReference}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB; line-height: 1.6;">

  <!-- Main Container -->
  <div style="max-width: 600px; margin: 0 auto; padding: 24px 16px;">

    <!-- Error Header Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px; text-align: center; border: 1px solid #FEE2E2;">
      <!-- Error Icon -->
      <div style="margin-bottom: 16px;">
        <svg width="64" height="64" viewBox="0 0 64 64" style="display: inline-block;">
          <circle cx="32" cy="32" r="30" fill="#FEE2E2" stroke="#DC2626" stroke-width="2"/>
          <path d="M20 20L44 44M44 20L20 44" stroke="#DC2626" stroke-width="4" stroke-linecap="round"/>
        </svg>
      </div>

      <!-- Title -->
      <h1 style="margin: 0 0 8px 0; font-size: 22px; font-weight: 600; line-height: 1.3; color: #1F2937;">
        Rezervacija otkazana
      </h1>

      <!-- Subtitle -->
      <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #6B7280;">
        Vaša rezervacija je uspješno otkazana
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
        Primili smo vaš zahtjev za otkazivanje rezervacije.
      </p>
    </div>

    <!-- Warning Alert -->
    <div style="background-color: #FEF3C7; border-left: 4px solid #D97706; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0 0 8px 0; font-size: 16px; font-weight: 600; color: #92400E;">
        ⚠️ Rezervacija otkazana
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #78350F;">
        Sačuvajte ovaj email kao potvrdu otkazivanja.
      </p>
    </div>

    <!-- Booking Details Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px;">
      <h2 style="margin: 0 0 20px 0; font-size: 18px; font-weight: 600; line-height: 1.3; color: #1F2937; border-bottom: 1px solid #E5E7EB; padding-bottom: 12px;">
        Detalji otkazane rezervacije
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
      </table>
    </div>

    ${refundAmount && refundAmount > 0 ? `
    <!-- Refund Info Alert -->
    <div style="background-color: #EFF6FF; border-left: 4px solid #2563EB; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0 0 8px 0; font-size: 16px; font-weight: 600; color: #1E40AF;">
        💰 Povrat novca
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1E40AF;">
        Povrat u iznosu od <strong>${formatCurrency(refundAmount)}</strong> bit će obrađen u roku od <strong>5-7 radnih dana</strong>.
      </p>
    </div>
    ` : ''}

    <!-- Footer -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); text-align: center;">
      <p style="margin: 0 0 12px 0; font-size: 14px; font-weight: 400; color: #6B7280;">
        Imate pitanja o otkazivanju? Kontaktirajte nas:
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
 * Send Refined Premium guest cancellation email via Resend
 */
export async function sendGuestCancellationEmailV2(
  resendClient: Resend,
  params: GuestCancellationParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateGuestCancellationEmailV2(params);
  const subject = `Rezervacija otkazana - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
