/**
 * Booking Approved Email Template
 *
 * Sent to guests when:
 * - Owner manually approves their booking
 * - Stripe payment is successfully confirmed
 *
 * Includes booking details and optional view booking link.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "../base";
import {getSuccessIcon} from "../../utils/svg-icons";
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
} from "../../utils/template-helpers";

/**
 * Booking approved email parameters
 */
export interface BookingApprovedParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  checkIn: Date;
  checkOut: Date;
  propertyName: string;
  unitName?: string;
  viewBookingUrl?: string;
  totalAmount?: number;
  depositAmount?: number;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate booking approved email HTML
 *
 * Uses SUCCESS gradient (green) instead of primary (purple)
 */
export function generateBookingApprovedEmail(
  params: BookingApprovedParams
): string {
  const {
    guestName,
    bookingReference,
    checkIn,
    checkOut,
    propertyName,
    unitName,
    viewBookingUrl,
    totalAmount,
    depositAmount,
    contactEmail,
    contactPhone,
  } = params;

  const nights = calculateNights(checkIn, checkOut);

  // Header with success icon and GREEN gradient
  const header = generateHeader({
    icon: getSuccessIcon(),
    title: "Rezervacija potvrđena!",
    subtitle: "Sjajne vijesti! Vaša rezervacija je uspješno potvrđena.",
    bookingReference: bookingReference,
  });

  // Success alert
  const successAlert = generateAlert({
    type: "success",
    title: "Rezervacija potvrđena",
    message: "Radujemo se vašem dolasku!",
  });

  // Booking details card
  const bookingDetailsRows: DetailRow[] = [
    {label: "Nekretnina", value: propertyName},
  ];

  if (unitName) {
    bookingDetailsRows.push({label: "Jedinica", value: unitName});
  }

  bookingDetailsRows.push(
    {label: "Prijava", value: formatDate(checkIn)},
    {label: "Odjava", value: formatDate(checkOut)},
    {label: "Broj noćenja", value: `${nights} ${nights === 1 ? "noć" : nights < 5 ? "noći" : "noći"}`}
  );

  const bookingDetailsCard = generateCard(
    "Detalji rezervacije",
    generateDetailsTable(bookingDetailsRows)
  );

  // Payment details card (optional)
  let paymentDetailsCard = "";
  if (totalAmount && depositAmount) {
    const paymentDetailsRows: DetailRow[] = [];

    if (depositAmount > 0) {
      paymentDetailsRows.push({label: "Uplaćeno", value: formatCurrency(depositAmount)});
    }

    if (totalAmount > depositAmount) {
      paymentDetailsRows.push({
        label: "Preostalo za platiti (pri dolasku)",
        value: formatCurrency(totalAmount - depositAmount),
      });
    }

    paymentDetailsRows.push({
      label: "Ukupna cijena",
      value: formatCurrency(totalAmount),
      highlight: true,
    });

    paymentDetailsCard = generateCard(
      "Detalji plaćanja",
      generateDetailsTable(paymentDetailsRows)
    );
  }

  // View booking button (optional)
  const viewBookingButton = viewBookingUrl ?
    generateButton({
      text: "Pregledaj moju rezervaciju",
      url: viewBookingUrl,
    }) : "";

  // Info tip (only if view booking link exists)
  const infoAlert = viewBookingUrl ?
    generateAlert({
      type: "info",
      message: "Sačuvajte ovaj email kako biste u bilo kojem trenutku mogli pristupiti detaljima rezervacije.",
    }) : "";

  // Combine all content
  const content = `
    ${generateGreeting(guestName)}
    ${generateIntro("Sjajne vijesti! Vaša rezervacija je uspješno potvrđena.")}
    ${successAlert}
    ${bookingDetailsCard}
    ${paymentDetailsCard}
    ${viewBookingButton}
    ${infoAlert}
  `;

  // Generate complete email with green gradient override
  const html = generateEmailHtml({
    header,
    content,
    footer: {
      contactEmail,
      contactPhone,
    },
  });

  // Override header gradient to green (success color)
  return html.replace(
    "background: linear-gradient(135deg, #6B4CE6 0%, #8B5CF6 100%)",
    "background: linear-gradient(135deg, #10B981 0%, #16A34A 100%)"
  );
}

/**
 * Send booking approved email via Resend
 *
 * @param resendClient - Resend client instance
 * @param params - Booking approved parameters
 * @param ownerEmail - Optional owner email for reply-to
 */
export async function sendBookingApprovedEmail(
  resendClient: Resend,
  params: BookingApprovedParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateBookingApprovedEmail(params);

  const subject = `Rezervacija potvrđena - ${params.bookingReference}`;

  // Generate plain text version
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
 */
function stripHtml(html: string): string {
  return html
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, " ")
    .trim();
}
