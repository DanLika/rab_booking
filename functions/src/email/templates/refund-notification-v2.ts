/**
 * Refund Notification Email Template V2
 * OPCIJA A: Refined Premium Design (Success/Info Style)
 *
 * Design Specs:
 * - Card padding: 28px
 * - Border radius: 12px (cards), 8px (buttons)
 * - Typography: 22px/600 (heading), 15px/400 (body), 16px/600 (price)
 * - Shadows: 0 1px 2px rgba(0,0,0,0.06) (cards), 0 2px 4px rgba(0,0,0,0.08) (button)
 * - Layout: Separated cards with gaps
 * - Colors: Success/Info theme (green + blue)
 */

import {Resend} from "resend";
import {formatCurrency} from "../utils/template-helpers";

export interface RefundNotificationParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  refundAmount: number;
  reason?: string;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate Refined Premium refund notification email
 */
export function generateRefundNotificationEmailV2(
  params: RefundNotificationParams
): string {
  const {
    guestName,
    bookingReference,
    refundAmount,
    reason,
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
  <title>Povrat novca obrađen - ${bookingReference}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB; line-height: 1.6;">

  <!-- Main Container -->
  <div style="max-width: 600px; margin: 0 auto; padding: 24px 16px;">

    <!-- Success Header Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px; text-align: center; border: 1px solid #D1FAE5;">
      <!-- Refund Icon (Emoji - works in all email clients) -->
      <div style="margin-bottom: 12px; font-size: 48px; line-height: 1;">
        💸
      </div>

      <!-- Title -->
      <h1 style="margin: 0 0 8px 0; font-size: 22px; font-weight: 600; line-height: 1.3; color: #1F2937;">
        Povrat novca obrađen
      </h1>

      <!-- Subtitle -->
      <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #6B7280;">
        Potvrda povrata sredstava
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
        Vaš zahtjev za povrat novca je uspješno obrađen.
      </p>
    </div>

    <!-- Success Alert -->
    <div style="background-color: #D1FAE5; border-left: 4px solid #059669; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0 0 8px 0; font-size: 16px; font-weight: 600; color: #065F46;">
        ✓ Povrat novca uspješno obrađen
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #047857;">
        Povrat u iznosu od <strong>${formatCurrency(refundAmount)}</strong> je obrađen.
      </p>
    </div>

    <!-- Refund Details Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); margin-bottom: 16px;">
      <h2 style="margin: 0 0 20px 0; font-size: 18px; font-weight: 600; line-height: 1.3; color: #1F2937; border-bottom: 1px solid #E5E7EB; padding-bottom: 12px;">
        Detalji povrata
      </h2>

      <table role="presentation" cellpadding="0" cellspacing="0" style="width: 100%; border-collapse: collapse;">
        <tr>
          <td style="padding: 10px 0; font-size: 14px; font-weight: 400; color: #6B7280; vertical-align: top; width: 45%;">
            Iznos povrata
          </td>
          <td style="padding: 10px 0; font-size: 16px; font-weight: 600; color: #059669; text-align: right;">
            ${formatCurrency(refundAmount)}
          </td>
        </tr>
        <tr>
          <td style="padding: 10px 0; font-size: 14px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Status
          </td>
          <td style="padding: 10px 0; font-size: 15px; font-weight: 400; color: #1F2937; text-align: right;">
            <span style="display: inline-block; background-color: #D1FAE5; color: #065F46; padding: 4px 12px; border-radius: 6px; font-size: 14px; font-weight: 600;">Obrađeno</span>
          </td>
        </tr>
        ${reason ? `
        <tr>
          <td style="padding: 10px 0; font-size: 14px; font-weight: 400; color: #6B7280; vertical-align: top;">
            Razlog
          </td>
          <td style="padding: 10px 0; font-size: 15px; font-weight: 400; color: #1F2937; text-align: right;">
            ${reason}
          </td>
        </tr>
        ` : ''}
      </table>
    </div>

    <!-- Info Alert -->
    <div style="background-color: #EFF6FF; border-left: 4px solid #2563EB; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0 0 8px 0; font-size: 16px; font-weight: 600; color: #1E40AF;">
        ℹ️ Kada će novac stići?
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1E40AF;">
        Novac bi trebao biti vidljiv na vašem računu u roku od <strong>5-7 radnih dana</strong>, ovisno o vašoj banci.
      </p>
    </div>

    <!-- Footer -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); text-align: center;">
      <p style="margin: 0 0 12px 0; font-size: 14px; font-weight: 400; color: #6B7280;">
        Imate pitanja o povratu novca? Kontaktirajte nas:
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
 * Send Refined Premium refund notification email via Resend
 */
export async function sendRefundNotificationEmailV2(
  resendClient: Resend,
  params: RefundNotificationParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateRefundNotificationEmailV2(params);
  const subject = `Povrat novca obrađen - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
