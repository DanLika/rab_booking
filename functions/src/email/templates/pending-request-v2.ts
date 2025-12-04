/**
 * Pending Booking Request Email Template V2
 * OPCIJA A: Refined Premium Design (Warning Style)
 *
 * Design Specs:
 * - Card padding: 28px
 * - Border radius: 12px (cards), 8px (buttons)
 * - Typography: 22px/600 (heading), 15px/400 (body), 16px/600 (price)
 * - Shadows: 0 1px 2px rgba(0,0,0,0.06) (cards), 0 2px 4px rgba(0,0,0,0.08) (button)
 * - Layout: Separated cards with gaps
 * - Colors: Warning theme (yellow/amber)
 * - NO "View Reservation" button (pending approval)
 */

import {Resend} from "resend";

export interface PendingBookingRequestParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
}

/**
 * Generate Refined Premium pending booking request email
 */
export function generatePendingBookingRequestEmailV2(
  params: PendingBookingRequestParams
): string {
  const {guestName, bookingReference, propertyName} = params;

  return `
<!DOCTYPE html>
<html lang="hr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>Zahtjev za rezervaciju - ${bookingReference}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB; line-height: 1.6;">

  <!-- Main Container -->
  <div style="max-width: 600px; margin: 0 auto; padding: 24px 16px;">

    <!-- Warning Header Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #FEF3C7; margin-bottom: 16px; text-align: center;">
      <!-- Warning Icon -->
      <div style="margin-bottom: 16px;">
        <svg width="64" height="64" viewBox="0 0 64 64" style="display: inline-block;">
          <circle cx="32" cy="32" r="30" fill="#FEF3C7" stroke="#D97706" stroke-width="2"/>
          <circle cx="32" cy="44" r="2" fill="#92400E"/>
          <path d="M32 20 L32 36" stroke="#92400E" stroke-width="4" stroke-linecap="round"/>
        </svg>
      </div>

      <!-- Title -->
      <h1 style="margin: 0 0 8px 0; font-size: 22px; font-weight: 600; line-height: 1.3; color: #1F2937;">
        Zahtjev za rezervaciju zaprimljen
      </h1>

      <!-- Subtitle -->
      <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #6B7280;">
        Čeka se odobrenje vlasnika
      </p>

      <!-- Booking Reference -->
      <div style="display: inline-block; background-color: #FEF3C7; padding: 8px 16px; border-radius: 6px; border: 1px solid #FDE68A;">
        <span style="font-size: 14px; font-weight: 400; color: #92400E;">Referenca:</span>
        <strong style="font-size: 14px; font-weight: 600; color: #78350F; margin-left: 4px;">${bookingReference}</strong>
      </div>
    </div>

    <!-- Greeting -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; margin-bottom: 16px;">
      <p style="margin: 0 0 16px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1F2937;">
        Poštovani/a <strong>${guestName}</strong>,
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1F2937;">
        Vaš zahtjev za rezervaciju u nekretnini <strong>${propertyName}</strong> je uspješno zaprimljen.
      </p>
    </div>

    <!-- Pending Notice Alert -->
    <div style="background-color: #FEF3C7; border-left: 4px solid #D97706; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0 0 8px 0; font-size: 16px; font-weight: 600; color: #92400E;">
        ⏳ Status: Čeka odobrenje
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #78350F;">
        Vlasnik nekretnine će pregledati vaš zahtjev i obavijestit će vas u najkraćem mogućem roku.
        Obično odgovaramo u roku od <strong>24 sata</strong>.
      </p>
    </div>

    <!-- Info Notice -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; margin-bottom: 16px;">
      <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 600; color: #1F2937;">
        Šta je sljedeće?
      </p>
      <ul style="margin: 0; padding-left: 20px; font-size: 15px; font-weight: 400; line-height: 1.8; color: #1F2937;">
        <li style="margin-bottom: 8px;">Vlasnik će pregledati dostupnost za vaše datume</li>
        <li style="margin-bottom: 8px;">Primit ćete email s potvrdom ili alternativnim prijedlogom</li>
        <li>Nakon odobrenja dobit ćete upute za uplatu</li>
      </ul>
    </div>

    <!-- Info Alert -->
    <div style="background-color: #EFF6FF; border-left: 4px solid #2563EB; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0; font-size: 14px; font-weight: 400; line-height: 1.6; color: #1E40AF;">
        ℹ️ Sačuvajte ovaj email sa vašom referencom <strong>${bookingReference}</strong> za buduću komunikaciju.
      </p>
    </div>

    <!-- Footer -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; text-align: center;">
      <p style="margin: 0; font-size: 14px; font-weight: 400; color: #6B7280;">
        Hvala što ste odabrali nas!
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
 * Send Refined Premium pending booking request email via Resend
 */
export async function sendPendingBookingRequestEmailV2(
  resendClient: Resend,
  params: PendingBookingRequestParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generatePendingBookingRequestEmailV2(params);
  const subject = `Zahtjev za rezervaciju zaprimljen - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
