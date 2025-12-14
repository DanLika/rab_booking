/**
 * Payment Reminder Email Template V2
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
  generateGreeting,
  generateIntro,
  generateCard,
  generateDetailsTable,
  generateButton,
  generateAlert,
  DetailRow,
  formatCurrency,
  formatDate,
  escapeHtml,
} from "../../utils/template-helpers";

export interface PaymentReminderParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  unitName?: string;
  checkIn: Date;
  depositAmount: number;
  viewBookingUrl?: string;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate payment reminder email HTML
 */
export function generatePaymentReminderEmailV2(
  params: PaymentReminderParams
): string {
  const {
    guestName,
    bookingReference,
    propertyName,
    unitName,
    checkIn,
    depositAmount,
    viewBookingUrl,
    contactEmail,
    contactPhone,
  } = params;

  // Header with bell icon
  const header = generateHeader({
    icon: getBellIcon(),
    title: "Podsjetnik za uplatu",
    subtitle: "Vaša rezervacija čeka uplatu",
    bookingReference: escapeHtml(bookingReference),
  });

  // Warning alert
  const warningAlert = generateAlert({
    type: "warning",
    title: "Uplata potrebna",
    message: "Molimo vas da što prije uplatite kaparu kako bi rezervacija bila potvrđena.",
  });

  // Booking details card
  const bookingDetailsRows: DetailRow[] = [
    {label: "Nekretnina", value: escapeHtml(propertyName)},
  ];
  if (unitName) {
    bookingDetailsRows.push({label: "Jedinica", value: escapeHtml(unitName)});
  }
  bookingDetailsRows.push({label: "Prijava", value: formatDate(checkIn)});
  const bookingDetailsCard = generateCard(
    "Detalji rezervacije",
    generateDetailsTable(bookingDetailsRows)
  );

  // Payment details card
  const paymentDetailsRows: DetailRow[] = [
    {label: "Kapara za uplatu", value: formatCurrency(depositAmount)},
    {label: "Referenca", value: escapeHtml(bookingReference)},
  ];
  const paymentDetailsCard = generateCard(
    "Detalji plaćanja",
    generateDetailsTable(paymentDetailsRows)
  );

  // Important notice alert
  const importantAlert = generateAlert({
    type: "warning",
    message: `VAŽNO: Obavezno navedite referencu rezervacije ${escapeHtml(bookingReference)} u opisu uplate!`,
  });

  // View booking button
  const viewBookingButton = viewBookingUrl ? generateButton({
    text: "Pregledaj rezervaciju",
    url: viewBookingUrl,
  }) : "";

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(guestName))}
    ${generateIntro("Ovo je prijateljski podsjetnik da vaša rezervacija čeka uplatu kapare.")}
    ${warningAlert}
    ${bookingDetailsCard}
    ${paymentDetailsCard}
    ${importantAlert}
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
 * Send Refined Premium payment reminder email via Resend
 * Gmail-optimized with proper HTML escaping
 */
export async function sendPaymentReminderEmailV2(
  resendClient: Resend,
  params: PaymentReminderParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generatePaymentReminderEmailV2(params);
  const subject = `Podsjetnik za uplatu - ${escapeHtml(params.bookingReference)}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
