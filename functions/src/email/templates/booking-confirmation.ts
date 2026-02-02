/**
 * Booking Confirmation Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getSuccessIcon} from "../utils/svg-icons";
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
  calculateNights,
  escapeHtml,
} from "../utils/template-helpers";

export interface BookingConfirmationParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  checkIn: Date;
  checkOut: Date;
  totalAmount: number;
  depositAmount: number;
  unitName: string;
  propertyName: string;
  viewBookingUrl: string;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate booking confirmation email HTML
 */
export function generateBookingConfirmationEmailV2(
  params: BookingConfirmationParams
): string {
  const {
    guestName,
    bookingReference,
    checkIn,
    checkOut,
    totalAmount,
    depositAmount,
    unitName,
    propertyName,
    viewBookingUrl,
    contactEmail,
    contactPhone,
  } = params;

  const nights = calculateNights(checkIn, checkOut);
  const remainingAmount = totalAmount - depositAmount;

  // Header with success icon
  const header = generateHeader({
    icon: getSuccessIcon(),
    title: "Rezervacija potvrđena!",
    subtitle: "Hvala vam na rezervaciji",
    bookingReference: escapeHtml(bookingReference),
  });

  // Booking details card
  const bookingDetailsRows: DetailRow[] = [
    {label: "Nekretnina", value: escapeHtml(propertyName)},
    {label: "Jedinica", value: escapeHtml(unitName)},
    {label: "Prijava", value: formatDate(checkIn)},
    {label: "Odjava", value: formatDate(checkOut)},
    {label: "Broj noćenja", value: `${nights} ${nights === 1 ? "noć" : nights < 5 ? "noći" : "noći"}`},
  ];
  const bookingDetailsCard = generateCard(
    "Detalji rezervacije",
    generateDetailsTable(bookingDetailsRows)
  );

  // Payment details card
  const paymentDetailsRows: DetailRow[] = [];

  if (depositAmount > 0) {
    paymentDetailsRows.push({label: "Avans", value: formatCurrency(depositAmount)});
  }

  if (remainingAmount > 0) {
    paymentDetailsRows.push({
      label: "Preostalo za platiti (pri dolasku)",
      value: formatCurrency(remainingAmount),
    });
  }

  paymentDetailsRows.push({
    label: "Ukupna cijena",
    value: formatCurrency(totalAmount),
    highlight: true,
  });

  const paymentDetailsCard = generateCard(
    "Detalji plaćanja",
    generateDetailsTable(paymentDetailsRows)
  );

  // Payment instructions alert
  const paymentAlert = depositAmount > 0 ?
    generateAlert({
      type: "warning",
      title: "Upute za plaćanje",
      message: `Molimo uplatite avans od ${formatCurrency(depositAmount)} u roku od 7 dana. VAŽNO: Obavezno navedite referencu rezervacije ${escapeHtml(bookingReference)} u opisu uplate!`,
    }) : "";

  // View booking button
  const viewBookingButton = generateButton({
    text: "Pregledaj moju rezervaciju",
    url: viewBookingUrl,
  });

  // Info message
  const infoAlert = generateAlert({
    type: "info",
    message: "Sačuvajte ovaj email kako biste u bilo kojem trenutku mogli pristupiti detaljima rezervacije.",
  });

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(guestName))}
    ${generateIntro("Vaša rezervacija je uspješno zaprimljena i čeka potvrdu uplate.")}
    ${bookingDetailsCard}
    ${paymentDetailsCard}
    ${paymentAlert}
    ${depositAmount > 0 ? "<p class=\"intro\">Kada primimo vašu uplatu, poslat ćemo vam email s potvrdom.</p>" : ""}
    ${viewBookingButton}
    ${infoAlert}
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
 * Send Refined Premium booking confirmation email via Resend
 */
export async function sendBookingConfirmationEmailV2(
  resendClient: Resend,
  params: BookingConfirmationParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateBookingConfirmationEmailV2(params);
  const subject = `Potvrda rezervacije - ${escapeHtml(params.bookingReference)}`;

  // IMPORTANT: Check the result object - Resend can return success with error inside
  const result = await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });

  // Resend SDK returns { data, error } - check for error
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const typedResult = result as any;
  if (typedResult.error) {
    throw new Error(
      `Resend API error: ${typedResult.error.message || JSON.stringify(typedResult.error)}`
    );
  }
}
