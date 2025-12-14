/**
 * Booking Rejected Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "../base";
import {getErrorIcon} from "../../utils/svg-icons";
import {
  generateHeader,
  generateGreeting,
  generateIntro,
  generateCard,
  generateAlert,
  escapeHtml,
} from "../../utils/template-helpers";

export interface BookingRejectedParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  reason?: string;
}

/**
 * Generate booking rejected email HTML
 */
export function generateBookingRejectedEmailV2(
  params: BookingRejectedParams
): string {
  const {guestName, bookingReference, propertyName, reason} = params;

  // Header with error icon
  const header = generateHeader({
    icon: getErrorIcon(),
    title: "Rezervacija odbijena",
    subtitle: "Žao nam je",
    bookingReference: escapeHtml(bookingReference),
  });

  // Reason alert (if provided)
  const reasonAlert = reason ? generateAlert({
    type: "error",
    title: "Razlog odbijanja",
    message: escapeHtml(reason),
  }) : "";

  // What's next card
  const whatsNextCard = generateCard(
    "Šta sada?",
    `
      <ul style="margin: 0; padding-left: 20px; font-size: 14px; font-weight: 400; line-height: 1.7; color: #1F2937;">
        <li style="margin-bottom: 6px;">Možete pokušati rezervisati druge datume</li>
        <li style="margin-bottom: 6px;">Kontaktirajte vlasnika za alternativne opcije</li>
        <li>Istražite druge dostupne nekretnine</li>
      </ul>
    `
  );

  // Apology alert
  const apologyAlert = generateAlert({
    type: "info",
    message: "Žao nam je zbog neugodnosti. Nadamo se da ćemo vam uskoro moći omogućiti boravak.",
  });

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(guestName))}
    ${generateIntro(`Nažalost, vaša rezervacija za nekretninu ${escapeHtml(propertyName)} je odbijena.`)}
    ${reasonAlert}
    ${whatsNextCard}
    ${apologyAlert}
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: "Hvala na razumijevanju",
    },
  });
}

/**
 * Send Refined Premium booking rejected email via Resend
 * Gmail-optimized with proper HTML escaping
 */
export async function sendBookingRejectedEmailV2(
  resendClient: Resend,
  params: BookingRejectedParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateBookingRejectedEmailV2(params);
  const subject = `Rezervacija odbijena - ${escapeHtml(params.bookingReference)}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
