/**
 * Check-Out Reminder Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getClockIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateGreeting,
  generateIntro,
  generateCard,
  generateDetailsTable,
  generateAlert,
  DetailRow,
  formatDate,
  escapeHtml,
} from "../utils/template-helpers";

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
 * Generate check-out reminder email HTML
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

  // Header with clock icon
  const header = generateHeader({
    icon: getClockIcon(),
    title: "Uskoro je odjava",
    subtitle: "Podsjetnik za check-out",
    bookingReference: escapeHtml(bookingReference),
  });

  // Info alert
  const infoAlert = generateAlert({
    type: "info",
    title: "Odjava uskoro",
    message: "Nadamo se da ste uživali u boravku!",
  });

  // Check-out details card
  const checkOutDetailsRows: DetailRow[] = [
    {label: "Nekretnina", value: escapeHtml(propertyName)},
  ];
  if (unitName) {
    checkOutDetailsRows.push({label: "Jedinica", value: escapeHtml(unitName)});
  }
  checkOutDetailsRows.push({label: "Datum odjave", value: formatDate(checkOut)});
  if (checkOutTime) {
    checkOutDetailsRows.push({label: "Vrijeme odjave", value: escapeHtml(checkOutTime)});
  }
  const checkOutDetailsCard = generateCard(
    "Detalji odjave",
    generateDetailsTable(checkOutDetailsRows)
  );

  // Thank you notice
  const thankYouAlert = generateAlert({
    type: "info",
    message: "Molimo vas da ostavite smještaj u urednom stanju. Hvala vam na posjeti!",
  });

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(guestName))}
    ${generateIntro("Ovo je podsjetnik da se vaš check-out približava.")}
    ${infoAlert}
    ${checkOutDetailsCard}
    ${thankYouAlert}
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      contactEmail: contactEmail ? escapeHtml(contactEmail) : undefined,
      contactPhone: contactPhone ? escapeHtml(contactPhone) : undefined,
    },
  });
}

/**
 * Send Refined Premium check-out reminder email via Resend
 * Gmail-optimized with proper HTML escaping
 */
export async function sendCheckOutReminderEmailV2(
  resendClient: Resend,
  params: CheckOutReminderParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateCheckOutReminderEmailV2(params);
  const subject = `Podsjetnik za odjavu - ${escapeHtml(params.bookingReference)}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
