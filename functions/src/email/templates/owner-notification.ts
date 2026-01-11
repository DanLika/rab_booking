/**
 * Owner New Booking Notification Template V2
 * Minimalist Design using Helper Functions
 *
 * Sent to property owners when a new booking is CONFIRMED.
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getSuccessIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateIntro,
  generateCard,
  generateDetailsTable,
  generateButton,
  DetailRow,
  formatCurrency,
  formatDate,
  calculateNights,
  escapeHtml,
} from "../utils/template-helpers";

/**
 * Owner notification email parameters (V2)
 */
export interface OwnerNotificationParamsV2 {
  ownerEmail: string;
  bookingReference: string;
  guestName: string;
  guestEmail: string;
  guestPhone?: string;
  propertyName: string;
  unitName?: string;
  checkIn: Date;
  checkOut: Date;
  guests: number;
  totalAmount: number;
  depositAmount?: number;
  paymentMethod?: string;
  dashboardUrl?: string;
}

/**
 * Generate owner notification email HTML (V2)
 */
export function generateOwnerNotificationEmailV2(
  params: OwnerNotificationParamsV2
): string {
  const {
    bookingReference,
    guestName,
    guestEmail,
    guestPhone,
    propertyName,
    unitName,
    checkIn,
    checkOut,
    guests,
    totalAmount,
    depositAmount,
    paymentMethod,
    dashboardUrl,
  } = params;

  const nights = calculateNights(checkIn, checkOut);

  // Header with success icon
  const header = generateHeader({
    icon: getSuccessIcon(),
    title: "Nova potvrđena rezervacija",
    subtitle: "Imate novu rezervaciju",
    bookingReference: escapeHtml(bookingReference),
  });

  // Guest info card
  const guestInfoRows: DetailRow[] = [
    {label: "Ime gosta", value: escapeHtml(guestName)},
    {label: "Email", value: escapeHtml(guestEmail)},
  ];

  if (guestPhone) {
    guestInfoRows.push({label: "Telefon", value: escapeHtml(guestPhone)});
  }

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
    {label: "Broj noćenja", value: `${nights} ${nights === 1 ? "noć" : "noći"}`},
    {label: "Broj gostiju", value: guests.toString()}
  );

  const bookingDetailsCard = generateCard(
    "Detalji rezervacije",
    generateDetailsTable(bookingDetailsRows)
  );

  // Payment details card
  const paymentDetailsRows: DetailRow[] = [];

  if (depositAmount && depositAmount > 0) {
    paymentDetailsRows.push({label: "Kapara", value: formatCurrency(depositAmount)});
    paymentDetailsRows.push({
      label: "Preostalo",
      value: formatCurrency(totalAmount - depositAmount),
    });
  }

  paymentDetailsRows.push({
    label: "Ukupna cijena",
    value: formatCurrency(totalAmount),
    highlight: true,
  });

  if (paymentMethod) {
    const methodText = paymentMethod === "stripe" ? "Kartica" :
      paymentMethod === "bank_transfer" ? "Bankovni prijenos" :
        "Plaćanje na mjestu";
    paymentDetailsRows.push({label: "Način plaćanja", value: methodText});
  }

  const paymentDetailsCard = generateCard(
    "Detalji plaćanja",
    generateDetailsTable(paymentDetailsRows)
  );

  // Dashboard button
  const dashboardButton = dashboardUrl ? generateButton({
    text: "Pogledaj rezervaciju",
    url: dashboardUrl,
  }) : "";

  // Combine all content
  const content = `
    ${generateIntro(`Gost ${escapeHtml(guestName)} je uspješno rezervirao vaš smještaj.`)}
    ${guestInfoCard}
    ${bookingDetailsCard}
    ${paymentDetailsCard}
    ${dashboardButton}
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
 * Send owner notification email via Resend (V2)
 */
export async function sendOwnerNotificationEmailV2(
  resendClient: Resend,
  params: OwnerNotificationParamsV2,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateOwnerNotificationEmailV2(params);
  const subject = `Nova rezervacija - ${escapeHtml(params.bookingReference)}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.ownerEmail,
    subject: subject,
    html: html,
  });
}
