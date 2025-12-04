/**
 * Payment Reminder Email Template V2
 * OPCIJA A: Refined Premium Design (Warning Style)
 *
 * Design Specs:
 * - Card padding: 28px
 * - Border radius: 12px (cards), 8px (buttons)
 * - Typography: 22px/600 (heading), 15px/400 (body), 16px/600 (price)
 * - Shadows: 0 1px 2px rgba(0,0,0,0.06) (cards), 0 2px 4px rgba(0,0,0,0.08) (button)
 * - Layout: Separated cards with gaps
 * - Colors: Warning theme (yellow/amber)
 */

import {Resend} from "resend";
import {formatCurrency, formatDate} from "../utils/template-helpers";

export interface PaymentReminderParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  unitName?: string;
  checkIn: Date;
  depositAmount: number;
  viewBookingUrl?: string;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate Refined Premium payment reminder email
 */
export function generatePaymentReminderEmailV2(
  params: PaymentReminderParams
): string {
  const {
    guestName,
    bookingReference,
    propertyName,
    unitName,
    checkIn,
    depositAmount,
    viewBookingUrl,
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
  <title>Podsjetnik za uplatu - ${bookingReference}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB; line-height: 1.6;">

  <!-- Main Container -->
  <div style="max-width: 600px; margin: 0 auto; padding: 24px 16px;">

    <!-- Warning Header Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #FEF3C7; margin-bottom: 16px; text-align: center;">
      <!-- Bell Icon -->
      <div style="margin-bottom: 16px;">
        <svg width="64" height="64" viewBox="0 0 64 64" style="display: inline-block;">
          <circle cx="32" cy="32" r="30" fill="#FEF3C7" stroke="#D97706" stroke-width="2"/>
          <!-- Bell shape -->
          <path d="M32 20 C28 20, 25 23, 25 27 L25 35 C25 35, 23 37, 23 39 L41 39 C41 37, 39 35, 39 35 L39 27 C39 23, 36 20, 32 20 Z" fill="#92400E"/>
          <path d="M29 41 C29 43, 30 44, 32 44 C34 44, 35 43, 35 41" stroke="#92400E" stroke-width="2" fill="none" stroke-linecap="round"/>
          <!-- Notification dot -->
          <circle cx="40" cy="24" r="4" fill="#DC2626"/>
        </svg>
      </div>

      <!-- Title -->
      <h1 style="margin: 0 0 8px 0; font-size: 22px; font-weight: 600; line-height: 1.3; color: #1F2937;">
        Podsjetnik za uplatu
      </h1>

      <!-- Subtitle -->
      <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #6B7280;">
        Vaša rezervacija čeka uplatu
      </p>

      <!-- Booking Reference -->
      <div style="display: inline-block; background-color: #FEF3C7; padding: 8px 16px; border-radius: 6px; border: 1px solid #FDE68A;">
        <span style="font-size: 14px; font-weight: 400; color: #92400E;">Referenca:</span>
        <strong style="font-size: 14px; font-weight: 600; color: #78350F; margin-left: 4px;">${bookingReference}</strong>
      </div>
    </div>

    <!-- Greeting -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px;">
      <p style="margin: 0 0 16px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1F2937;">
        Poštovani/a <strong>${guestName}</strong>,
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1F2937;">
        Ovo je prijateljski podsjetnik da vaša rezervacija čeka uplatu kapare.
      </p>
    </div>

    <!-- Warning Alert -->
    <div style="background-color: #FEF3C7; border-left: 4px solid #D97706; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0 0 8px 0; font-size: 16px; font-weight: 600; color: #92400E;">
        ⚠️ Uplata potrebna
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #78350F;">
        Molimo vas da što prije uplatite kaparu kako bi rezervacija bila potvrđena.
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
      </table>
    </div>

    <!-- Payment Details Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px;">
      <h2 style="margin: 0 0 20px 0; font-size: 18px; font-weight: 600; line-height: 1.3; color: #1F2937; border-bottom: 1px solid #E5E7EB; padding-bottom: 12px;">
        Detalji plaćanja
      </h2>

      <table role="presentation" cellpadding="0" cellspacing="0" style="width: 100%; border-collapse: collapse;">
        <tr>
          <td style="padding: 10px 0; font-size: 14px; font-weight: 400; color: #6B7280; vertical-align: top; width: 45%;">
            Kapara za uplatu
          </td>
          <td style="padding: 10px 0; font-size: 16px; font-weight: 600; color: #D97706; text-align: right;">
            ${formatCurrency(depositAmount)}
          </td>
        </tr>
        <tr>
          <td style="padding: 10px 0; font-size: 14px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Referenca
          </td>
          <td style="padding: 10px 0; font-size: 15px; font-weight: 400; color: #1F2937; text-align: right;">
            <strong>${bookingReference}</strong>
          </td>
        </tr>
      </table>
    </div>

    <!-- Important Notice -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 20px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px; text-align: center;">
      <p style="margin: 0; font-size: 15px; font-weight: 600; color: #1F2937;">
        <strong>VAŽNO:</strong> Obavezno navedite referencu rezervacije <strong style="color: #D97706;">${bookingReference}</strong> u opisu uplate!
      </p>
    </div>

    ${viewBookingUrl ? `
    <!-- View Booking Button -->
    <div style="text-align: center; margin-bottom: 16px;">
      <a href="${viewBookingUrl}" style="display: inline-block; background-color: #374151; color: #FFFFFF; text-decoration: none; padding: 14px 28px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08); font-size: 15px; font-weight: 600;">
        Pregledaj rezervaciju
      </a>
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
 * Send Refined Premium payment reminder email via Resend
 */
export async function sendPaymentReminderEmailV2(
  resendClient: Resend,
  params: PaymentReminderParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generatePaymentReminderEmailV2(params);
  const subject = `Podsjetnik za uplatu - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
