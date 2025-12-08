/**
 * Pending Booking Owner Notification Template V2
 * Mobile-Responsive Premium Design (Warning Style)
 *
 * Design Specs:
 * - Card padding: 20-24px (mobile-friendly)
 * - Border radius: 12px (cards), 8px (buttons)
 * - Typography: 20px/600 (heading), 13-14px/400 (body)
 * - Shadows: 0 1px 2px rgba(0,0,0,0.06)
 * - Colors: Warning theme (yellow/amber)
 * - Bell emoji instead of SVG (Gmail compatibility)
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
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px 20px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #FEF3C7; margin-bottom: 16px; text-align: center;">
      <!-- Bell Icon (Emoji - works in all email clients) -->
      <div style="margin-bottom: 12px; font-size: 48px; line-height: 1;">
        🔔
      </div>

      <!-- Title -->
      <h1 style="margin: 0 0 8px 0; font-size: 20px; font-weight: 600; line-height: 1.3; color: #1F2937;">
        Novi zahtjev za rezervaciju
      </h1>

      <!-- Subtitle -->
      <p style="margin: 0 0 12px 0; font-size: 14px; font-weight: 400; line-height: 1.5; color: #6B7280;">
        Potrebna je vaša akcija
      </p>

      <!-- Booking Reference -->
      <div style="display: inline-block; background-color: #FEF3C7; padding: 8px 12px; border-radius: 6px; border: 1px solid #FDE68A;">
        <span style="font-size: 13px; font-weight: 400; color: #92400E;">Referenca:</span>
        <strong style="font-size: 13px; font-weight: 600; color: #78350F; margin-left: 4px;">${bookingReference}</strong>
      </div>
    </div>

    <!-- Booking Details Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 20px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; margin-bottom: 16px;">
      <p style="margin: 0 0 16px 0; font-size: 14px; font-weight: 400; line-height: 1.5; color: #1F2937;">
        Gost <strong>${guestName}</strong> je poslao zahtjev za rezervaciju vaše nekretnine:
      </p>

      <!-- Property Info -->
      <div style="background-color: #F9FAFB; border-radius: 8px; padding: 12px; margin-bottom: 12px;">
        <div style="margin-bottom: 6px;">
          <span style="font-size: 13px; font-weight: 400; color: #6B7280;">🏠 Nekretnina:</span>
          <span style="font-size: 14px; font-weight: 600; color: #1F2937; margin-left: 4px;">${propertyName}</span>
        </div>
        <div>
          <span style="font-size: 13px; font-weight: 400; color: #6B7280;">👤 Gost:</span>
          <span style="font-size: 14px; font-weight: 600; color: #1F2937; margin-left: 4px;">${guestName}</span>
        </div>
      </div>

      <p style="margin: 0; font-size: 14px; font-weight: 400; line-height: 1.5; color: #1F2937;">
        Molimo pregledajte detalje i potvrdite ili odbijte rezervaciju.
      </p>
    </div>

    <!-- Action Required Alert -->
    <div style="background-color: #FEF3C7; border-left: 4px solid #D97706; border-radius: 8px; padding: 16px; margin-bottom: 16px;">
      <p style="margin: 0 0 6px 0; font-size: 14px; font-weight: 600; color: #92400E;">
        ⏰ Brza akcija preporučena
      </p>
      <p style="margin: 0; font-size: 13px; font-weight: 400; line-height: 1.5; color: #78350F;">
        Gosti obično očekuju odgovor u roku od <strong>24 sata</strong>. Brz odgovor poboljšava vašu reputaciju.
      </p>
    </div>

    ${dashboardUrl ? `
    <!-- Action Button -->
    <div style="text-align: center; margin-bottom: 16px;">
      <a href="${dashboardUrl}" style="display: inline-block; background-color: #D97706; color: #FFFFFF; text-decoration: none; padding: 12px 24px; border-radius: 8px; font-size: 14px; font-weight: 600; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08);">
        Pregledaj rezervaciju
      </a>
    </div>
    ` : ""}

    <!-- Info Notice -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 20px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; margin-bottom: 16px;">
      <p style="margin: 0 0 10px 0; font-size: 14px; font-weight: 600; color: #1F2937;">
        Šta možete uraditi?
      </p>
      <ul style="margin: 0; padding-left: 20px; font-size: 13px; font-weight: 400; line-height: 1.7; color: #1F2937;">
        <li style="margin-bottom: 6px;">Pregledajte dostupnost za tražene datume</li>
        <li style="margin-bottom: 6px;">Potvrdite rezervaciju ako su datumi slobodni</li>
        <li>Ponudite alternativne datume ako je potrebno</li>
      </ul>
    </div>

    <!-- Footer -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 20px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; text-align: center;">
      <p style="margin: 0; font-size: 13px; font-weight: 400; color: #6B7280;">
        BookBed Owner Dashboard
      </p>

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
