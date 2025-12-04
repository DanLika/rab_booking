/**
 * Check-Out Reminder Email Template V2
 * OPCIJA A: Refined Premium Design (Info Style)
 *
 * Design Specs:
 * - Card padding: 28px
 * - Border radius: 12px (cards), 8px (buttons)
 * - Typography: 22px/600 (heading), 15px/400 (body), 16px/600 (price)
 * - Shadows: 0 1px 2px rgba(0,0,0,0.06) (cards), 0 2px 4px rgba(0,0,0,0.08) (button)
 * - Layout: Separated cards with gaps
 * - Colors: Info theme (blue)
 */

import {Resend} from "resend";
import {formatDate} from "../utils/template-helpers";

export interface CheckOutReminderParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  unitName?: string;
  checkOut: Date;
  checkOutTime?: string;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate Refined Premium check-out reminder email
 */
export function generateCheckOutReminderEmailV2(
  params: CheckOutReminderParams
): string {
  const {
    guestName,
    bookingReference,
    propertyName,
    unitName,
    checkOut,
    checkOutTime,
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
  <title>Podsjetnik za odjavu - ${bookingReference}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB; line-height: 1.6;">

  <!-- Main Container -->
  <div style="max-width: 600px; margin: 0 auto; padding: 24px 16px;">

    <!-- Info Header Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #DBEAFE; margin-bottom: 16px; text-align: center;">
      <!-- Clock Icon -->
      <div style="margin-bottom: 16px;">
        <svg width="64" height="64" viewBox="0 0 64 64" style="display: inline-block;">
          <circle cx="32" cy="32" r="30" fill="#DBEAFE" stroke="#2563EB" stroke-width="2"/>
          <!-- Clock face -->
          <circle cx="32" cy="32" r="18" fill="none" stroke="#1E40AF" stroke-width="3"/>
          <!-- Clock hands pointing to 11 -->
          <path d="M32 32 L28 18" stroke="#1E40AF" stroke-width="3" stroke-linecap="round"/>
          <path d="M32 32 L42 28" stroke="#1E40AF" stroke-width="3" stroke-linecap="round"/>
          <!-- Center dot -->
          <circle cx="32" cy="32" r="2" fill="#1E40AF"/>
        </svg>
      </div>

      <!-- Title -->
      <h1 style="margin: 0 0 8px 0; font-size: 22px; font-weight: 600; line-height: 1.3; color: #1F2937;">
        Uskoro je odjava
      </h1>

      <!-- Subtitle -->
      <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #6B7280;">
        Podsjetnik za check-out
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
        Ovo je podsjetnik da se vaš check-out približava.
      </p>
    </div>

    <!-- Info Alert -->
    <div style="background-color: #EFF6FF; border-left: 4px solid #2563EB; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0 0 8px 0; font-size: 16px; font-weight: 600; color: #1E40AF;">
        🏖️ Odjava uskoro
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1E40AF;">
        Nadamo se da ste uživali u boravku!
      </p>
    </div>

    <!-- Check-Out Details Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px;">
      <h2 style="margin: 0 0 20px 0; font-size: 18px; font-weight: 600; line-height: 1.3; color: #1F2937; border-bottom: 1px solid #E5E7EB; padding-bottom: 12px;">
        Detalji odjave
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
            Datum odjave
          </td>
          <td style="padding: 10px 0; font-size: 15px; font-weight: 600; color: #2563EB; text-align: right;">
            ${formatDate(checkOut)}
          </td>
        </tr>
        ${checkOutTime ? `
        <tr>
          <td style="padding: 10px 0; font-size: 14px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Vrijeme odjave
          </td>
          <td style="padding: 10px 0; font-size: 15px; font-weight: 600; color: #2563EB; text-align: right;">
            ${checkOutTime}
          </td>
        </tr>
        ` : ''}
      </table>
    </div>

    <!-- Thank You Notice -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 20px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px; text-align: center;">
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1F2937;">
        Molimo vas da ostavite smještaj u urednom stanju. <strong>Hvala vam na posjeti!</strong>
      </p>
    </div>

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
 * Send Refined Premium check-out reminder email via Resend
 */
export async function sendCheckOutReminderEmailV2(
  resendClient: Resend,
  params: CheckOutReminderParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateCheckOutReminderEmailV2(params);
  const subject = `Podsjetnik za odjavu - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
