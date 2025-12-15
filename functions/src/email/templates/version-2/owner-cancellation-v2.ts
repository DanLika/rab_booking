/**
 * Owner Cancellation Notification Template V2
 * Minimalist Design using Helper Functions
 *
 * Sent to property owners when a guest cancels their booking.
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "../base";
import {getWarningIcon} from "../../utils/svg-icons";
import {
  generateHeader,
  generateIntro,
  generateCard,
  generateDetailsTable,
  generateAlert,
  DetailRow,
  formatCurrency,
  formatDate,
  escapeHtml,
} from "../../utils/template-helpers";

/**
 * Owner cancellation notification email parameters (V2)
 */
export interface OwnerCancellationParamsV2 {
  ownerEmail: string;
  bookingReference: string;
  guestName: string;
  guestEmail: string;
  propertyName: string;
  unitName?: string;
  checkIn: Date;
  checkOut: Date;
  totalAmount: number;
  refundAmount?: number;
  cancellationReason?: string;
}

/**
 * Generate owner cancellation notification email HTML (V2)
 */
export function generateOwnerCancellationEmailV2(
  params: OwnerCancellationParamsV2
): string {
  const {
    bookingReference,
    guestName,
    guestEmail,
    propertyName,
    unitName,
    checkIn,
    checkOut,
    totalAmount,
    refundAmount,
    cancellationReason,
  } = params;

  // Header with warning icon
  const header = generateHeader({
    icon: getWarningIcon(),
    title: "Rezervacija otkazana",
    subtitle: "Gost je otkazao rezervaciju",
    bookingReference: escapeHtml(bookingReference),
  });

  // Alert about cancellation
  const cancellationAlert = generateAlert({
    type: "warning",
    title: "Obavijest o otkazivanju",
    message: `Gost ${escapeHtml(guestName)} je otkazao svoju rezervaciju.`,
  });

  // Guest info card
  const guestInfoRows: DetailRow[] = [
    {label: "Ime gosta", value: escapeHtml(guestName)},
    {label: "Email", value: escapeHtml(guestEmail)},
  ];

  const guestInfoCard = generateCard(
    "Informacije o gostu",
    generateDetailsTable(guestInfoRows)
  );

  // Booking details card
  const bookingDetailsRows: DetailRow[] = [
    {label: "Nekretnina", value: escapeHtml(propertyName)},
  ];

  if (unitName) {
    bookingDetailsRows.push({label: "Jedinica", value: escapeHtml(unitName)});
  }

  bookingDetailsRows.push(
    {label: "Prijava", value: formatDate(checkIn)},
    {label: "Odjava", value: formatDate(checkOut)},
    {label: "Ukupna cijena", value: formatCurrency(totalAmount)}
  );

  if (cancellationReason) {
    bookingDetailsRows.push({label: "Razlog otkazivanja", value: escapeHtml(cancellationReason)});
  }

  const bookingDetailsCard = generateCard(
    "Detalji otkazane rezervacije",
    generateDetailsTable(bookingDetailsRows)
  );

  // Refund info alert (if applicable)
  const refundAlert = refundAmount && refundAmount > 0 ?
    generateAlert({
      type: "info",
      title: "Povrat novca",
      message: `Povrat u iznosu od ${formatCurrency(refundAmount)} bit će obrađen automatski.`,
    }) : "";

  // Availability info card
  const availabilityCard = generateCard(
    "",
    `
      <p style="margin: 0; font-size: 14px; font-weight: 400; line-height: 1.6; color: #1F2937;">
        Termini od <strong>${formatDate(checkIn)}</strong> do <strong>${formatDate(checkOut)}</strong> su sada slobodni za nove rezervacije.
      </p>
    `
  );

  // Combine all content
  const content = `
    ${generateIntro(`Gost ${escapeHtml(guestName)} je otkazao svoju rezervaciju za ${escapeHtml(propertyName)}.`)}
    ${cancellationAlert}
    ${guestInfoCard}
    ${bookingDetailsCard}
    ${refundAlert}
    ${availabilityCard}
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
 * Send owner cancellation notification email via Resend (V2)
 */
export async function sendOwnerCancellationEmailV2(
  resendClient: Resend,
  params: OwnerCancellationParamsV2,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateOwnerCancellationEmailV2(params);
  const subject = `Otkazivanje rezervacije - ${escapeHtml(params.bookingReference)}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.ownerEmail,
    subject: subject,
    html: html,
  });
}
