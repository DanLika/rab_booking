/**
 * Check-In Reminder Email Template V2
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
  generateButton,
  generateAlert,
  DetailRow,
  formatDate,
  escapeHtml,
} from "../utils/template-helpers";

export interface CheckInReminderParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  unitName?: string;
  checkIn: Date;
  checkInTime?: string;
  address?: string;
  viewBookingUrl?: string;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate check-in reminder email HTML
 */
export function generateCheckInReminderEmailV2(
  params: CheckInReminderParams
): string {
  const {
    guestName,
    bookingReference,
    propertyName,
    unitName,
    checkIn,
    checkInTime,
    address,
    viewBookingUrl,
    contactEmail,
    contactPhone,
  } = params;

  // Header with clock icon
  const header = generateHeader({
    icon: getClockIcon(),
    title: "Uskoro je prijava!",
    subtitle: "Podsjetnik za check-in",
    bookingReference: escapeHtml(bookingReference),
  });

  // Info alert
  const infoAlert = generateAlert({
    type: "info",
    title: "Prijava uskoro",
    message: "Radujemo se vašem dolasku!",
  });

  // Check-in details card
  const checkInDetailsRows: DetailRow[] = [
    {label: "Nekretnina", value: escapeHtml(propertyName)},
  ];
  if (unitName) {
    checkInDetailsRows.push({label: "Jedinica", value: escapeHtml(unitName)});
  }
  checkInDetailsRows.push({label: "Datum prijave", value: formatDate(checkIn)});
  if (checkInTime) {
    checkInDetailsRows.push({label: "Vrijeme prijave", value: escapeHtml(checkInTime)});
  }
  if (address) {
    checkInDetailsRows.push({label: "Adresa", value: escapeHtml(address)});
  }
  const checkInDetailsCard = generateCard(
    "Detalji prijave",
    generateDetailsTable(checkInDetailsRows)
  );

  // Help notice
  const helpNotice = generateAlert({
    type: "info",
    message: "Ako imate bilo kakvih pitanja, slobodno nas kontaktirajte.",
  });

  // View booking button
  const viewBookingButton = viewBookingUrl ? generateButton({
    text: "Pregledaj rezervaciju",
    url: viewBookingUrl,
  }) : "";

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(guestName))}
    ${generateIntro("Ovo je podsjetnik da se vaš check-in približava.")}
    ${infoAlert}
    ${checkInDetailsCard}
    ${helpNotice}
    ${viewBookingButton}
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
 * Send Refined Premium check-in reminder email via Resend
 * Gmail-optimized with proper HTML escaping
 */
export async function sendCheckInReminderEmailV2(
  resendClient: Resend,
  params: CheckInReminderParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateCheckInReminderEmailV2(params);
  const subject = `Podsjetnik za prijavu - ${escapeHtml(params.bookingReference)}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
