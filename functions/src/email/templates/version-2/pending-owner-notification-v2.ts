/**
 * Pending Booking Owner Notification Template V2
 * Minimalist Design using Helper Functions
 *
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "../base";
import {getBellIcon} from "../../utils/svg-icons";
import {
  generateHeader,
  generateIntro,
  generateCard,
  generateButton,
  generateAlert,
  escapeHtml,
} from "../../utils/template-helpers";

export interface PendingOwnerNotificationParams {
  ownerEmail: string;
  bookingReference: string;
  guestName: string;
  propertyName: string;
  dashboardUrl?: string;
}

/**
 * Generate pending booking owner notification email HTML
 */
export function generatePendingOwnerNotificationEmailV2(
  params: PendingOwnerNotificationParams
): string {
  const {bookingReference, guestName, propertyName, dashboardUrl} = params;

  // Header with bell icon
  const header = generateHeader({
    icon: getBellIcon(),
    title: "Novi zahtjev za rezervaciju",
    subtitle: "Potrebna je vaša akcija",
    bookingReference: escapeHtml(bookingReference),
  });

  // Booking details card
  const bookingDetailsCard = generateCard(
    "",
    `
      <p style="margin: 0 0 16px 0; font-size: 14px; font-weight: 400; line-height: 1.5; color: #1F2937;">
        Gost <strong>${escapeHtml(guestName)}</strong> je poslao zahtjev za rezervaciju vaše nekretnine:
      </p>
      <div style="background-color: #F9FAFB; border-radius: 8px; padding: 12px; margin-bottom: 12px;">
        <div style="margin-bottom: 6px;">
          <span style="font-size: 13px; font-weight: 400; color: #6B7280;">Nekretnina:</span>
          <span style="font-size: 14px; font-weight: 600; color: #1F2937; margin-left: 4px;">${escapeHtml(propertyName)}</span>
        </div>
        <div>
          <span style="font-size: 13px; font-weight: 400; color: #6B7280;">Gost:</span>
          <span style="font-size: 14px; font-weight: 600; color: #1F2937; margin-left: 4px;">${escapeHtml(guestName)}</span>
        </div>
      </div>
      <p style="margin: 0; font-size: 14px; font-weight: 400; line-height: 1.5; color: #1F2937;">
        Molimo pregledajte detalje i potvrdite ili odbijte rezervaciju.
      </p>
    `
  );

  // Action required alert
  const actionAlert = generateAlert({
    type: "warning",
    title: "Brza akcija preporučena",
    message: "Gosti obično očekuju odgovor u roku od 24 sata. Brz odgovor poboljšava vašu reputaciju.",
  });

  // Dashboard button
  const dashboardButton = dashboardUrl ? generateButton({
    text: "Pregledaj rezervaciju",
    url: dashboardUrl,
  }) : "";

  // What you can do card
  const actionsCard = generateCard(
    "Šta možete uraditi?",
    `
      <ul style="margin: 0; padding-left: 20px; font-size: 13px; font-weight: 400; line-height: 1.7; color: #1F2937;">
        <li style="margin-bottom: 6px;">Pregledajte dostupnost za tražene datume</li>
        <li style="margin-bottom: 6px;">Potvrdite rezervaciju ako su datumi slobodni</li>
        <li>Ponudite alternativne datume ako je potrebno</li>
      </ul>
    `
  );

  // Combine all content
  const content = `
    ${generateIntro(`Gost ${escapeHtml(guestName)} je poslao zahtjev za rezervaciju vaše nekretnine ${escapeHtml(propertyName)}.`)}
    ${bookingDetailsCard}
    ${actionAlert}
    ${dashboardButton}
    ${actionsCard}
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: "BookBed Owner Dashboard",
    },
  });
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
  const subject = `Novi zahtjev za rezervaciju - ${escapeHtml(params.bookingReference)}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.ownerEmail,
    subject: subject,
    html: html,
  });
}
