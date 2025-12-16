/**
 * Booking Approved Email Template V2
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
 */
export function generateBookingApprovedEmailV2(
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
  const remainingAmount = totalAmount && depositAmount ? totalAmount - depositAmount : 0;

  // Header with success icon
  const header = generateHeader({
    icon: getSuccessIcon(),
    title: "Rezervacija potvrđena!",
    subtitle: "Sjajne vijesti! Radujemo se vašem dolasku",
    bookingReference: escapeHtml(bookingReference),
  });

  // Success alert
  const successAlert = generateAlert({
    type: "success",
    title: "Rezervacija potvrđena",
    message: `Sve je spremno! Očekujemo vas ${formatDate(checkIn)}.`,
  });

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
    {label: "Broj noćenja", value: `${nights} ${nights === 1 ? "noć" : nights < 5 ? "noći" : "noći"}`}
  );
  const bookingDetailsCard = generateCard(
    "Detalji rezervacije",
    generateDetailsTable(bookingDetailsRows)
  );

  // Payment details card (if amounts provided)
  let paymentDetailsCard = "";
  if (totalAmount && depositAmount) {
    const paymentDetailsRows: DetailRow[] = [];
    if (depositAmount > 0) {
      paymentDetailsRows.push({label: "Uplaćeno", value: formatCurrency(depositAmount)});
    }
    if (remainingAmount > 0) {
      paymentDetailsRows.push({
        label: "Preostalo (pri dolasku)",
        value: formatCurrency(remainingAmount),
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

  // View booking button
  const viewBookingButton = viewBookingUrl ? generateButton({
    text: "Pregledaj moju rezervaciju",
    url: viewBookingUrl,
  }) : "";

  // Info alert
  const infoAlert = viewBookingUrl ? generateAlert({
    type: "info",
    message: "Sačuvajte ovaj email kako biste u bilo kojem trenutku mogli pristupiti detaljima rezervacije.",
  }) : "";

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(guestName))}
    ${generateIntro("Vaša rezervacija je uspješno potvrđena! Možete se radovati svom boravku.")}
    ${successAlert}
    ${bookingDetailsCard}
    ${paymentDetailsCard}
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
 * Send Refined Premium booking approved email via Resend
 */
export async function sendBookingApprovedEmailV2(
  resendClient: Resend,
  params: BookingApprovedParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateBookingApprovedEmailV2(params);
  const subject = `Rezervacija potvrđena - ${escapeHtml(params.bookingReference)}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
