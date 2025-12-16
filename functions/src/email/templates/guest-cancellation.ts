/**
 * Guest Cancellation Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getErrorIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateGreeting,
  generateIntro,
  generateCard,
  generateDetailsTable,
  generateAlert,
  DetailRow,
  formatCurrency,
  formatDate,
  escapeHtml,
} from "../utils/template-helpers";

export interface GuestCancellationParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  unitName?: string;
  checkIn: Date;
  checkOut: Date;
  refundAmount?: number;
  cancellationReason?: string;
  cancelledByOwner?: boolean;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate guest cancellation email HTML
 */
export function generateGuestCancellationEmailV2(
  params: GuestCancellationParams
): string {
  const {
    guestName,
    bookingReference,
    propertyName,
    unitName,
    checkIn,
    checkOut,
    refundAmount,
    cancellationReason,
    cancelledByOwner,
    contactEmail,
    contactPhone,
  } = params;

  // Header with error icon
  const header = generateHeader({
    icon: getErrorIcon(),
    title: "Rezervacija otkazana",
    subtitle: cancelledByOwner ? "Rezervacija je otkazana od strane vlasnika" : "Vaša rezervacija je uspješno otkazana",
    bookingReference: escapeHtml(bookingReference),
  });

  // Warning alert
  const warningAlert = generateAlert({
    type: "warning",
    title: "Rezervacija otkazana",
    message: "Sačuvajte ovaj email kao potvrdu otkazivanja.",
  });

  // Cancellation reason alert (if provided)
  const reasonAlert = cancellationReason ? generateAlert({
    type: "error",
    title: "Razlog otkazivanja",
    message: escapeHtml(cancellationReason),
  }) : "";

  // Booking details card
  const bookingDetailsRows: DetailRow[] = [
    {label: "Nekretnina", value: escapeHtml(propertyName)},
  ];
  if (unitName) {
    bookingDetailsRows.push({label: "Jedinica", value: escapeHtml(unitName)});
  }
  bookingDetailsRows.push(
    {label: "Prijava", value: formatDate(checkIn)},
    {label: "Odjava", value: formatDate(checkOut)}
  );
  const bookingDetailsCard = generateCard(
    "Detalji otkazane rezervacije",
    generateDetailsTable(bookingDetailsRows)
  );

  // Refund alert (if applicable)
  const refundAlert = refundAmount && refundAmount > 0 ? generateAlert({
    type: "info",
    title: "Povrat novca",
    message: `Povrat u iznosu od ${formatCurrency(refundAmount)} bit će obrađen u roku od 5-7 radnih dana.`,
  }) : "";

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(guestName))}
    ${generateIntro("Primili smo vaš zahtjev za otkazivanje rezervacije.")}
    ${warningAlert}
    ${reasonAlert}
    ${bookingDetailsCard}
    ${refundAlert}
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      contactEmail: contactEmail ? escapeHtml(contactEmail) : undefined,
      contactPhone: contactPhone ? escapeHtml(contactPhone) : undefined,
      additionalText: "Imate pitanja o otkazivanju?",
    },
  });
}

/**
 * Send Refined Premium guest cancellation email via Resend
 * Gmail-optimized with proper HTML escaping
 */
export async function sendGuestCancellationEmailV2(
  resendClient: Resend,
  params: GuestCancellationParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateGuestCancellationEmailV2(params);
  const subject = `Rezervacija otkazana - ${escapeHtml(params.bookingReference)}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
