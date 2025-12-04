/**
 * Pending Booking Owner Notification Template V2
 * Refined Premium Design (Warning Style)
 *
 * Design Specs:
 * - Card padding: 28px
 * - Border radius: 12px (cards), 8px (buttons)
 * - Typography: 22px/600 (heading), 15px/400 (body), 16px/600 (labels)
 * - Shadows: 0 1px 2px rgba(0,0,0,0.06) (cards), 0 2px 4px rgba(0,0,0,0.08) (button)
 * - Colors: Warning theme (yellow/amber)
 * - Action button: "Pregledaj rezervaciju"
 */

import {Resend} from "resend";

export interface PendingOwnerNotificationParams {
  ownerEmail: string;
  bookingReference: string;
  guestName: string;
  propertyName: string;
  dashboardUrl?: string;
}

/**
 * Generate Refined Premium pending booking owner notification email
 */
export function generatePendingOwnerNotificationEmailV2(
  params: PendingOwnerNotificationParams
): string {
  const {bookingReference, guestName, propertyName, dashboardUrl} = params;

  return `
<!DOCTYPE html>
<html lang="hr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>Novi zahtjev za rezervaciju - ${bookingReference}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB; line-height: 1.6;">

  <!-- Main Container -->
  <div style="max-width: 600px; margin: 0 auto; padding: 24px 16px;">

    <!-- Warning Header Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #FEF3C7; margin-bottom: 16px; text-align: center;">
      <!-- Bell Icon -->
      <div style="margin-bottom: 16px;">
        <svg width="64" height="64" viewBox="0 0 64 64" style="display: inline-block;">
          <path d="M32 12 Q28 12 28 16 L28 18 Q22 20 18 26 Q16 30 16 34 L16 42 L12 46 L52 46 L48 42 L48 34 Q48 30 46 26 Q42 20 36 18 L36 16 Q36 12 32 12 Z" fill="#FEF3C7" stroke="#D97706" stroke-width="2"/>
          <path d="M28 48 Q28 52 32 52 Q36 52 36 48" stroke="#92400E" stroke-width="2" stroke-linecap="round" fill="none"/>
        </svg>
      </div>

      <!-- Title -->
      <h1 style="margin: 0 0 8px 0; font-size: 22px; font-weight: 600; line-height: 1.3; color: #1F2937;">
        Novi zahtjev za rezervaciju
      </h1>

      <!-- Subtitle -->
      <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #6B7280;">
        Potrebna je vaša akcija
      </p>

      <!-- Booking Reference -->
      <div style="display: inline-block; background-color: #FEF3C7; padding: 8px 16px; border-radius: 6px; border: 1px solid #FDE68A;">
        <span style="font-size: 14px; font-weight: 400; color: #92400E;">Referenca:</span>
        <strong style="font-size: 14px; font-weight: 600; color: #78350F; margin-left: 4px;">${bookingReference}</strong>
      </div>
    </div>

    <!-- Booking Details Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; margin-bottom: 16px;">
      <p style="margin: 0 0 20px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1F2937;">
        Gost <strong>${guestName}</strong> je poslao zahtjev za rezervaciju vaše nekretnine:
      </p>

      <!-- Property Info -->
      <div style="background-color: #F9FAFB; border-radius: 8px; padding: 16px; margin-bottom: 16px;">
        <div style="display: flex; align-items: center; margin-bottom: 8px;">
          <span style="font-size: 14px; font-weight: 400; color: #6B7280; margin-right: 8px;">🏠 Nekretnina:</span>
          <span style="font-size: 15px; font-weight: 600; color: #1F2937;">${propertyName}</span>
        </div>
        <div style="display: flex; align-items: center;">
          <span style="font-size: 14px; font-weight: 400; color: #6B7280; margin-right: 8px;">👤 Gost:</span>
          <span style="font-size: 15px; font-weight: 600; color: #1F2937;">${guestName}</span>
        </div>
      </div>

      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1F2937;">
        Molimo pregledajte detalje i potvrdite ili odbijte rezervaciju.
      </p>
    </div>

    <!-- Action Required Alert -->
    <div style="background-color: #FEF3C7; border-left: 4px solid #D97706; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0 0 8px 0; font-size: 16px; font-weight: 600; color: #92400E;">
        ⏰ Brza akcija preporučena
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #78350F;">
        Gosti obično očekuju odgovor u roku od <strong>24 sata</strong>. Brz odgovor poboljšava vašu reputaciju.
      </p>
    </div>

    ${dashboardUrl ? `
    <!-- Action Button -->
    <div style="text-align: center; margin-bottom: 16px;">
      <a href="${dashboardUrl}" style="display: inline-block; background-color: #D97706; color: #FFFFFF; text-decoration: none; padding: 14px 28px; border-radius: 8px; font-size: 15px; font-weight: 600; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08);">
        Pregledaj rezervaciju
      </a>
    </div>
    ` : ""}

    <!-- Info Notice -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; margin-bottom: 16px;">
      <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 600; color: #1F2937;">
        Šta možete uraditi?
      </p>
      <ul style="margin: 0; padding-left: 20px; font-size: 15px; font-weight: 400; line-height: 1.8; color: #1F2937;">
        <li style="margin-bottom: 8px;">Pregledajte dostupnost za tražene datume</li>
        <li style="margin-bottom: 8px;">Potvrdite rezervaciju ako su datumi slobodni</li>
        <li>Ponudite alternativne datume ako je potrebno</li>
      </ul>
    </div>

    <!-- Footer -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; text-align: center;">
      <p style="margin: 0; font-size: 14px; font-weight: 400; color: #6B7280;">
        RabBooking Owner Dashboard
      </p>

      <div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid #E5E7EB;">
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
 * Send Refined Premium pending booking owner notification via Resend
 */
export async function sendPendingOwnerNotificationEmailV2(
  resendClient: Resend,
  params: PendingOwnerNotificationParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generatePendingOwnerNotificationEmailV2(params);
  const subject = `Novi zahtjev za rezervaciju - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.ownerEmail,
    subject: subject,
    html: html,
  });
}
