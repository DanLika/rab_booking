/**
 * Booking Rejected Email Template V2
 * Refined Premium Design (Error Style)
 *
 * Design Specs:
 * - Card padding: 28px
 * - Border radius: 12px (cards), 8px (alerts)
 * - Typography: 22px/600 (heading), 15px/400 (body), 16px/600 (labels)
 * - Shadows: 0 1px 2px rgba(0,0,0,0.06)
 * - Colors: Error theme (red #DC2626)
 * - Optional reason field
 */

import {Resend} from "resend";

export interface BookingRejectedParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  reason?: string;
}

/**
 * Generate Refined Premium booking rejected email
 */
export function generateBookingRejectedEmailV2(
  params: BookingRejectedParams
): string {
  const {guestName, bookingReference, propertyName, reason} = params;

  return `
<!DOCTYPE html>
<html lang="hr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>Rezervacija odbijena - ${bookingReference}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB; line-height: 1.6;">

  <!-- Main Container -->
  <div style="max-width: 600px; margin: 0 auto; padding: 24px 16px;">

    <!-- Error Header Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #FEE2E2; margin-bottom: 16px; text-align: center;">
      <!-- X Circle Icon -->
      <div style="margin-bottom: 16px;">
        <svg width="64" height="64" viewBox="0 0 64 64" style="display: inline-block;">
          <circle cx="32" cy="32" r="30" fill="#FEE2E2" stroke="#DC2626" stroke-width="2"/>
          <path d="M22 22 L42 42 M42 22 L22 42" stroke="#991B1B" stroke-width="4" stroke-linecap="round"/>
        </svg>
      </div>

      <!-- Title -->
      <h1 style="margin: 0 0 8px 0; font-size: 22px; font-weight: 600; line-height: 1.3; color: #1F2937;">
        Rezervacija odbijena
      </h1>

      <!-- Subtitle -->
      <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #6B7280;">
        Žao nam je
      </p>

      <!-- Booking Reference -->
      <div style="display: inline-block; background-color: #FEE2E2; padding: 8px 16px; border-radius: 6px; border: 1px solid #FECACA;">
        <span style="font-size: 14px; font-weight: 400; color: #991B1B;">Referenca:</span>
        <strong style="font-size: 14px; font-weight: 600; color: #7F1D1D; margin-left: 4px;">${bookingReference}</strong>
      </div>
    </div>

    <!-- Greeting -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; margin-bottom: 16px;">
      <p style="margin: 0 0 16px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1F2937;">
        Poštovani/a <strong>${guestName}</strong>,
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1F2937;">
        Nažalost, vaša rezervacija za nekretninu <strong>${propertyName}</strong> je odbijena.
      </p>
    </div>

    ${reason ? `
    <!-- Reason Card -->
    <div style="background-color: #FEE2E2; border-left: 4px solid #DC2626; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0 0 8px 0; font-size: 16px; font-weight: 600; color: #991B1B;">
        📋 Razlog odbijanja
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #7F1D1D;">
        ${reason}
      </p>
    </div>
    ` : ""}

    <!-- What's Next -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; margin-bottom: 16px;">
      <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 600; color: #1F2937;">
        Šta sada?
      </p>
      <ul style="margin: 0; padding-left: 20px; font-size: 15px; font-weight: 400; line-height: 1.8; color: #1F2937;">
        <li style="margin-bottom: 8px;">Možete pokušati rezervisati druge datume</li>
        <li style="margin-bottom: 8px;">Kontaktirajte vlasnika za alternativne opcije</li>
        <li>Istražite druge dostupne nekretnine</li>
      </ul>
    </div>

    <!-- Apology Notice -->
    <div style="background-color: #EFF6FF; border-left: 4px solid #2563EB; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1E40AF;">
        💙 Žao nam je zbog neugodnosti. Nadamo se da ćemo vam uskoro moći omogućiti boravak.
      </p>
    </div>

    <!-- Footer -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; text-align: center;">
      <p style="margin: 0; font-size: 14px; font-weight: 400; color: #6B7280;">
        Hvala na razumijevanju
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
 * Send Refined Premium booking rejected email via Resend
 */
export async function sendBookingRejectedEmailV2(
  resendClient: Resend,
  params: BookingRejectedParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateBookingRejectedEmailV2(params);
  const subject = `Rezervacija odbijena - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
