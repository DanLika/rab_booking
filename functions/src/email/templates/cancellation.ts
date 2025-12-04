/**
 * Cancellation Email Templates
 *
 * Templates for guest cancellations and refund notifications.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getErrorIcon, getRefundIcon} from "../utils/svg-icons";
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
} from "../utils/template-helpers";

/**
 * Guest cancellation email parameters
 */
export interface GuestCancellationParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  unitName?: string;
  checkIn: Date;
  checkOut: Date;
  refundAmount?: number;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate guest cancellation email HTML
 */
export function generateGuestCancellationEmail(
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
    contactEmail,
    contactPhone,
  } = params;

  // Header with error icon
  const header = generateHeader({
    icon: getErrorIcon(),
    title: "Rezervacija otkazana",
    subtitle: "Vaša rezervacija je uspješno otkazana",
    bookingReference: bookingReference,
  });

  // Warning alert
  const warningAlert = generateAlert({
    type: "warning",
    title: "Rezervacija otkazana",
    message: "Vaša rezervacija je uspješno otkazana. Molimo vas da sačuvate ovaj email kao potvrdu.",
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
    {label: "Odjava", value: formatDate(checkOut)}
  );

  const bookingDetailsCard = generateCard(
    "Detalji otkazane rezervacije",
    generateDetailsTable(bookingDetailsRows)
  );

  // Refund info (if applicable)
  const refundAlert = refundAmount && refundAmount > 0 ?
    generateAlert({
      type: "info",
      title: "Povrat novca",
      message: `Povrat u iznosu od ${formatCurrency(refundAmount)} bit će obrađen u roku od 5-7 radnih dana.`,
    }) : "";

  // Combine all content
  const content = `
    ${generateGreeting(guestName)}
    ${generateIntro("Primili smo vaš zahtjev za otkazivanje rezervacije.")}
    ${warningAlert}
    ${bookingDetailsCard}
    ${refundAlert}
    <p class="intro">Ako imate pitanja o otkazivanju, slobodno nas kontaktirajte.</p>
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
 * Owner cancellation notification email parameters
 */
export interface OwnerCancellationParams {
  ownerEmail: string;
  bookingReference: string;
  guestName: string;
  guestEmail: string;
  propertyName: string;
  unitName?: string;
  checkIn: Date;
  checkOut: Date;
  totalAmount: number;
}

/**
 * Generate owner cancellation notification email HTML
 */
export function generateOwnerCancellationEmail(
  params: OwnerCancellationParams
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
  } = params;

  // Header
  const header = generateHeader({
    icon: getErrorIcon(),
    title: "Gost je otkazao rezervaciju",
    subtitle: "Obavijest o otkazivanju",
    bookingReference: bookingReference,
  });

  // Alert
  const alert = generateAlert({
    type: "warning",
    title: "Otkazivanje rezervacije",
    message: `Gost ${guestName} je otkazao rezervaciju ${bookingReference}.`,
  });

  // Guest info card
  const guestInfoRows: DetailRow[] = [
    {label: "Ime gosta", value: guestName},
    {label: "Email", value: guestEmail},
  ];

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
    {label: "Ukupna cijena", value: formatCurrency(totalAmount), highlight: true}
  );

  const bookingDetailsCard = generateCard(
    "Detalji otkazane rezervacije",
    generateDetailsTable(bookingDetailsRows)
  );

  // Combine all content
  const content = `
    <p class="greeting">Obavijest o otkazivanju</p>
    ${alert}
    ${guestInfoCard}
    ${bookingDetailsCard}
    <p class="intro">Termini su sada slobodni za nove rezervacije.</p>
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
  });
}

/**
 * Refund notification email parameters
 */
export interface RefundNotificationParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  refundAmount: number;
  reason?: string;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate refund notification email HTML
 */
export function generateRefundNotificationEmail(
  params: RefundNotificationParams
): string {
  const {
    guestName,
    bookingReference,
    refundAmount,
    reason,
    contactEmail,
    contactPhone,
  } = params;

  // Header with refund icon
  const header = generateHeader({
    icon: getRefundIcon(),
    title: "Povrat novca obrađen",
    subtitle: "Potvrda povrata sredstava",
    bookingReference: bookingReference,
  });

  // Success alert
  const successAlert = generateAlert({
    type: "success",
    title: "Povrat novca uspješno obrađen",
    message: `Povrat u iznosu od ${formatCurrency(refundAmount)} je uspješno obrađen.`,
  });

  // Refund details card
  const refundDetailsRows: DetailRow[] = [
    {label: "Iznos povrata", value: formatCurrency(refundAmount), highlight: true},
    {label: "Status", value: "Obrađeno"},
  ];

  if (reason) {
    refundDetailsRows.push({label: "Razlog", value: reason});
  }

  const refundDetailsCard = generateCard(
    "Detalji povrata",
    generateDetailsTable(refundDetailsRows)
  );

  // Info alert
  const infoAlert = generateAlert({
    type: "info",
    message: "Novac bi trebao biti vidljiv na vašem računu u roku od 5-7 radnih dana, ovisno o vašoj banci.",
  });

  // Combine all content
  const content = `
    ${generateGreeting(guestName)}
    ${generateIntro("Vaš zahtjev za povrat novca je uspješno obrađen.")}
    ${successAlert}
    ${refundDetailsCard}
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
 * Send guest cancellation email via Resend
 */
export async function sendGuestCancellationEmail(
  resendClient: Resend,
  params: GuestCancellationParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateGuestCancellationEmail(params);
  const subject = `Potvrda otkazivanja - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    subject: subject,
    html: html,
    text: stripHtml(html),
  });
}

/**
 * Send owner cancellation notification via Resend
 */
export async function sendOwnerCancellationEmail(
  resendClient: Resend,
  params: OwnerCancellationParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateOwnerCancellationEmail(params);
  const subject = `Otkazivanje rezervacije - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.ownerEmail,
    subject: subject,
    html: html,
    text: stripHtml(html),
  });
}

/**
 * Send refund notification via Resend
 */
export async function sendRefundNotificationEmail(
  resendClient: Resend,
  params: RefundNotificationParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateRefundNotificationEmail(params);
  const subject = `Povrat novca - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
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
