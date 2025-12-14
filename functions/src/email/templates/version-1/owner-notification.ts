/**
 * Owner Notification Email Template
 *
 * Sent to property owners when a new booking is created.
 * Includes guest information and booking details.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "../base";
import {getInfoIcon} from "../../utils/svg-icons";
import {
  generateHeader,
  generateCard,
  generateDetailsTable,
  generateAlert,
  DetailRow,
  formatCurrency,
  formatDate,
  calculateNights,
} from "../../utils/template-helpers";

/**
 * Owner notification email parameters
 */
export interface OwnerNotificationParams {
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
}

/**
 * Generate owner notification email HTML
 */
export function generateOwnerNotificationEmail(
  params: OwnerNotificationParams
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
  } = params;

  const nights = calculateNights(checkIn, checkOut);

  // Header
  const header = generateHeader({
    icon: getInfoIcon(),
    title: "Nova rezervacija",
    subtitle: "Imate novu rezervaciju",
    bookingReference: bookingReference,
  });

  // Info alert
  const infoAlert = generateAlert({
    type: "info",
    title: "Nova rezervacija",
    message: "Primili ste novu rezervaciju. Provjerite detalje u nastavku.",
  });

  // Guest info card
  const guestInfoRows: DetailRow[] = [
    {label: "Ime gosta", value: guestName},
    {label: "Email", value: guestEmail},
  ];

  if (guestPhone) {
    guestInfoRows.push({label: "Telefon", value: guestPhone});
  }

  const guestInfoCard = generateCard(
    "Informacije o gostu",
    generateDetailsTable(guestInfoRows)
  );

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
    {label: "Broj noćenja", value: `${nights} ${nights === 1 ? "noć" : nights < 5 ? "noći" : "noći"}`},
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

  // Combine all content
  const content = `
    <p class="greeting">Nova rezervacija</p>
    ${infoAlert}
    ${guestInfoCard}
    ${bookingDetailsCard}
    ${paymentDetailsCard}
    <p class="intro">Provjerite rezervaciju u vašem dashboard-u.</p>
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
  });
}

/**
 * Send owner notification email via Resend
 */
export async function sendOwnerNotificationEmail(
  resendClient: Resend,
  params: OwnerNotificationParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateOwnerNotificationEmail(params);
  const subject = `Nova rezervacija - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.ownerEmail,
    subject: subject,
    html: html,
    text: stripHtml(html),
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
