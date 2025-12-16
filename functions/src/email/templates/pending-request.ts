/**
 * Pending Booking Request Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getWarningIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateGreeting,
  generateIntro,
  generateCard,
  generateAlert,
  escapeHtml,
} from "../utils/template-helpers";

export interface PendingBookingRequestParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
}

/**
 * Generate pending booking request email HTML
 */
export function generatePendingBookingRequestEmailV2(
  params: PendingBookingRequestParams
): string {
  const {guestName, bookingReference, propertyName} = params;

  // Header with warning icon
  const header = generateHeader({
    icon: getWarningIcon(),
    title: "Zahtjev za rezervaciju zaprimljen",
    subtitle: "Čeka se odobrenje vlasnika",
    bookingReference: escapeHtml(bookingReference),
  });

  // Pending notice alert
  const pendingAlert = generateAlert({
    type: "warning",
    title: "Status: Čeka odobrenje",
    message: "Vlasnik nekretnine će pregledati vaš zahtjev i obavijestit će vas u najkraćem mogućem roku. Obično odgovaramo u roku od 24 sata.",
  });

  // What's next card
  const whatsNextCard = generateCard(
    "Šta je sljedeće?",
    `
      <ul style="margin: 0; padding-left: 20px; font-size: 13px; font-weight: 400; line-height: 1.7; color: #1F2937;">
        <li style="margin-bottom: 6px;">Vlasnik će pregledati dostupnost za vaše datume</li>
        <li style="margin-bottom: 6px;">Primit ćete email s potvrdom ili alternativnim prijedlogom</li>
        <li>Nakon odobrenja dobit ćete upute za uplatu</li>
      </ul>
    `
  );

  // Info alert
  const infoAlert = generateAlert({
    type: "info",
    message: `Sačuvajte ovaj email sa vašom referencom ${escapeHtml(bookingReference)} za buduću komunikaciju.`,
  });

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(guestName))}
    ${generateIntro(`Vaš zahtjev za rezervaciju u nekretnini ${escapeHtml(propertyName)} je uspješno zaprimljen.`)}
    ${pendingAlert}
    ${whatsNextCard}
    ${infoAlert}
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: "Hvala što ste odabrali BookBed!",
    },
  });
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
  const subject = `Zahtjev za rezervaciju zaprimljen - ${escapeHtml(params.bookingReference)}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
