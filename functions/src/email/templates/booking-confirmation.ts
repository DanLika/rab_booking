/**
 * Booking Confirmation Email Template
 *
 * Sent to guests after they complete a booking.
 * Includes booking details, payment information, and view booking link.
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
} from "../utils/template-helpers";

/**
 * Booking confirmation email parameters
 */
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
export function generateBookingConfirmationEmail(
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
    bookingReference: bookingReference,
  });

  // Booking details card
  const bookingDetailsRows: DetailRow[] = [
    {label: "Nekretnina", value: propertyName},
    {label: "Jedinica", value: unitName},
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
    paymentDetailsRows.push({label: "Kapara", value: formatCurrency(depositAmount)});
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
      message: `Molimo uplatite kaparu od ${formatCurrency(depositAmount)} u roku od 3 dana. VAŽNO: Obavezno navedite referencu rezervacije ${bookingReference} u opisu uplate!`,
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
    ${generateGreeting(guestName)}
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
      contactEmail,
      contactPhone,
    },
  });
}

/**
 * Send booking confirmation email via Resend
 *
 * @param resendClient - Resend client instance
 * @param params - Booking confirmation parameters
 * @param ownerEmail - Optional owner email for reply-to
 */
export async function sendBookingConfirmationEmail(
  resendClient: Resend,
  params: BookingConfirmationParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateBookingConfirmationEmail(params);

  const subject = `Potvrda rezervacije - ${params.bookingReference}`;

  // Generate plain text version (strip HTML)
  const text = stripHtml(html);

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
    text: text,
  });
}

/**
 * Strip HTML tags to create plain text version
 * Used for email clients that don't support HTML
 */
function stripHtml(html: string): string {
  return html
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "") // Remove style tags
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "") // Remove script tags
    .replace(/<[^>]+>/g, "") // Remove all HTML tags
    .replace(/&nbsp;/g, " ") // Replace &nbsp; with space
    .replace(/&amp;/g, "&") // Replace &amp; with &
    .replace(/&lt;/g, "<") // Replace &lt; with <
    .replace(/&gt;/g, ">") // Replace &gt; with >
    .replace(/&quot;/g, '"') // Replace &quot; with "
    .replace(/&#39;/g, "'") // Replace &#39; with '
    .replace(/\s+/g, " ") // Collapse multiple spaces
    .trim();
}
