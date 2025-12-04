/**
 * Reminder Email Templates
 *
 * Templates for payment reminders, check-in reminders, and check-out reminders.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getBellIcon, getClockIcon} from "../utils/svg-icons";
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
} from "../utils/template-helpers";

/**
 * Payment reminder email parameters
 */
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
export function generatePaymentReminderEmail(
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
    icon: getBellIcon(64, "#FFFFFF"),
    title: "Podsjetnik za uplatu",
    subtitle: "Vaša rezervacija čeka uplatu",
    bookingReference: bookingReference,
  });

  // Warning alert
  const warningAlert = generateAlert({
    type: "warning",
    title: "Uplata potrebna",
    message: "Molimo vas da što prije uplatite kaparu kako bi rezervacija bila potvrđena.",
  });

  // Booking details card
  const bookingDetailsRows: DetailRow[] = [
    {label: "Nekretnina", value: propertyName},
  ];

  if (unitName) {
    bookingDetailsRows.push({label: "Jedinica", value: unitName});
  }

  bookingDetailsRows.push({label: "Prijava", value: formatDate(checkIn)});

  const bookingDetailsCard = generateCard(
    "Detalji rezervacije",
    generateDetailsTable(bookingDetailsRows)
  );

  // Payment details card
  const paymentDetailsRows: DetailRow[] = [
    {label: "Kapara za uplatu", value: formatCurrency(depositAmount), highlight: true},
    {label: "Referenca", value: bookingReference},
  ];

  const paymentDetailsCard = generateCard(
    "Detalji plaćanja",
    generateDetailsTable(paymentDetailsRows)
  );

  // View booking button (optional)
  const viewBookingButton = viewBookingUrl ?
    generateButton({
      text: "Pregledaj rezervaciju",
      url: viewBookingUrl,
    }) : "";

  // Combine all content
  const content = `
    ${generateGreeting(guestName)}
    ${generateIntro("Ovo je prijateljski podsjetnik da vaša rezervacija čeka uplatu kapare.")}
    ${warningAlert}
    ${bookingDetailsCard}
    ${paymentDetailsCard}
    <p class="intro">VAŽNO: Obavezno navedite referencu rezervacije ${bookingReference} u opisu uplate!</p>
    ${viewBookingButton}
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
 * Check-in reminder email parameters
 */
export interface CheckInReminderParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  unitName?: string;
  checkIn: Date;
  checkInTime?: string;
  address?: string;
  viewBookingUrl?: string;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate check-in reminder email HTML
 */
export function generateCheckInReminderEmail(
  params: CheckInReminderParams
): string {
  const {
    guestName,
    bookingReference,
    propertyName,
    unitName,
    checkIn,
    checkInTime,
    address,
    viewBookingUrl,
    contactEmail,
    contactPhone,
  } = params;

  // Header with clock icon
  const header = generateHeader({
    icon: getClockIcon(64, "#FFFFFF"),
    title: "Uskoro je prijava!",
    subtitle: "Podsjetnik za check-in",
    bookingReference: bookingReference,
  });

  // Info alert
  const infoAlert = generateAlert({
    type: "info",
    title: "Prijava uskoro",
    message: "Radujemo se vašem dolasku!",
  });

  // Booking details card
  const bookingDetailsRows: DetailRow[] = [
    {label: "Nekretnina", value: propertyName},
  ];

  if (unitName) {
    bookingDetailsRows.push({label: "Jedinica", value: unitName});
  }

  bookingDetailsRows.push({label: "Datum prijave", value: formatDate(checkIn)});

  if (checkInTime) {
    bookingDetailsRows.push({label: "Vrijeme prijave", value: checkInTime});
  }

  if (address) {
    bookingDetailsRows.push({label: "Adresa", value: address});
  }

  const bookingDetailsCard = generateCard(
    "Detalji prijave",
    generateDetailsTable(bookingDetailsRows)
  );

  // View booking button (optional)
  const viewBookingButton = viewBookingUrl ?
    generateButton({
      text: "Pregledaj rezervaciju",
      url: viewBookingUrl,
    }) : "";

  // Combine all content
  const content = `
    ${generateGreeting(guestName)}
    ${generateIntro("Ovo je podsjetnik da se vaš check-in približava.")}
    ${infoAlert}
    ${bookingDetailsCard}
    <p class="intro">Ako imate bilo kakvih pitanja, slobodno nas kontaktirajte.</p>
    ${viewBookingButton}
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
 * Check-out reminder email parameters
 */
export interface CheckOutReminderParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  unitName?: string;
  checkOut: Date;
  checkOutTime?: string;
  contactEmail?: string;
  contactPhone?: string;
}

/**
 * Generate check-out reminder email HTML
 */
export function generateCheckOutReminderEmail(
  params: CheckOutReminderParams
): string {
  const {
    guestName,
    bookingReference,
    propertyName,
    unitName,
    checkOut,
    checkOutTime,
    contactEmail,
    contactPhone,
  } = params;

  // Header with clock icon
  const header = generateHeader({
    icon: getClockIcon(64, "#FFFFFF"),
    title: "Uskoro je odjava",
    subtitle: "Podsjetnik za check-out",
    bookingReference: bookingReference,
  });

  // Info alert
  const infoAlert = generateAlert({
    type: "info",
    title: "Odjava uskoro",
    message: "Nadamo se da ste uživali u boravku!",
  });

  // Booking details card
  const bookingDetailsRows: DetailRow[] = [
    {label: "Nekretnina", value: propertyName},
  ];

  if (unitName) {
    bookingDetailsRows.push({label: "Jedinica", value: unitName});
  }

  bookingDetailsRows.push({label: "Datum odjave", value: formatDate(checkOut)});

  if (checkOutTime) {
    bookingDetailsRows.push({label: "Vrijeme odjave", value: checkOutTime});
  }

  const bookingDetailsCard = generateCard(
    "Detalji odjave",
    generateDetailsTable(bookingDetailsRows)
  );

  // Combine all content
  const content = `
    ${generateGreeting(guestName)}
    ${generateIntro("Ovo je podsjetnik da se vaš check-out približava.")}
    ${infoAlert}
    ${bookingDetailsCard}
    <p class="intro">Molimo vas da ostavite smještaj u urednom stanju. Hvala vam na posjeti!</p>
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
 * Send payment reminder email via Resend
 */
export async function sendPaymentReminderEmail(
  resendClient: Resend,
  params: PaymentReminderParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generatePaymentReminderEmail(params);
  const subject = `Podsjetnik za uplatu - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    subject: subject,
    html: html,
    text: stripHtml(html),
  });
}

/**
 * Send check-in reminder email via Resend
 */
export async function sendCheckInReminderEmail(
  resendClient: Resend,
  params: CheckInReminderParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateCheckInReminderEmail(params);
  const subject = `Podsjetnik za prijavu - ${params.bookingReference}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    subject: subject,
    html: html,
    text: stripHtml(html),
  });
}

/**
 * Send check-out reminder email via Resend
 */
export async function sendCheckOutReminderEmail(
  resendClient: Resend,
  params: CheckOutReminderParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateCheckOutReminderEmail(params);
  const subject = `Podsjetnik za odjavu - ${params.bookingReference}`;

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
