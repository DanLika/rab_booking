/**
 * Pending Booking Request Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getWarningIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateGreeting,
  generateIntro,
  generateCard,
  generateAlert,
  generateBankTransferCard,
  escapeHtml,
} from "../utils/template-helpers";

export interface BankDetailsParams {
  bankName?: string;
  accountHolder?: string;
  iban?: string;
  swift?: string;
}

export interface PendingBookingRequestParams {
  guestEmail: string;
  guestName: string;
  bookingReference: string;
  propertyName: string;
  /** Payment method - if 'bank_transfer', include bank details */
  paymentMethod?: string;
  /** Total amount for bank transfer (deposit or full amount) */
  depositAmount?: number;
  /** Bank details (required if paymentMethod is 'bank_transfer') */
  bankDetails?: BankDetailsParams;
}

/**
 * Generate pending booking request email HTML
 */
export function generatePendingBookingRequestEmailV2(
  params: PendingBookingRequestParams
): string {
  const {guestName, bookingReference, propertyName, paymentMethod, depositAmount, bankDetails} = params;

  // Check if this is a bank transfer booking with valid bank details
  const isBankTransfer = paymentMethod === "bank_transfer" &&
    depositAmount &&
    depositAmount > 0 &&
    bankDetails &&
    bankDetails.iban;

  // Header with warning icon
  const header = generateHeader({
    icon: getWarningIcon(),
    title: "Zahtjev za rezervaciju zaprimljen",
    subtitle: "Čeka se odobrenje vlasnika",
    bookingReference: escapeHtml(bookingReference),
  });

  // Pending notice alert
  const pendingAlert = generateAlert({
    type: "warning",
    title: "Status: Čeka odobrenje",
    message: "Vlasnik nekretnine će pregledati vaš zahtjev i obavijestit će vas u najkraćem mogućem roku. Obično odgovaramo u roku od 24 sata.",
  });

  // Bank transfer card (only for bank_transfer payment method)
  let bankTransferSection = "";
  if (isBankTransfer) {
    bankTransferSection = generateBankTransferCard({
      bankName: bankDetails.bankName,
      accountHolder: bankDetails.accountHolder,
      iban: bankDetails.iban,
      swift: bankDetails.swift,
      reference: bookingReference,
      amount: depositAmount,
    });

    // Add payment instruction alert
    bankTransferSection += generateAlert({
      type: "info",
      title: "Upute za uplatu",
      message: "Uplatu izvršite tek NAKON što primite email s potvrdom da je vaša rezervacija odobrena. Uplatnice izvršene prije odobrenja mogu rezultirati komplikacijama.",
    });
  }

  // What's next card - adjust text based on payment method
  const whatNextItems = isBankTransfer ?
    `<ul style="margin: 0; padding-left: 20px; font-size: 13px; font-weight: 400; line-height: 1.7; color: #1F2937;">
        <li style="margin-bottom: 6px;">Vlasnik će pregledati dostupnost za vaše datume</li>
        <li style="margin-bottom: 6px;">Primit ćete email s potvrdom ili alternativnim prijedlogom</li>
        <li style="margin-bottom: 6px;">Nakon odobrenja, izvršite uplatu koristeći podatke iznad</li>
        <li>Rezervacija postaje važeća nakon što vlasnik potvrdi primitak uplate</li>
      </ul>` :
    `<ul style="margin: 0; padding-left: 20px; font-size: 13px; font-weight: 400; line-height: 1.7; color: #1F2937;">
        <li style="margin-bottom: 6px;">Vlasnik će pregledati dostupnost za vaše datume</li>
        <li style="margin-bottom: 6px;">Primit ćete email s potvrdom ili alternativnim prijedlogom</li>
        <li>Nakon odobrenja dobit ćete upute za uplatu</li>
      </ul>`;

  const whatsNextCard = generateCard("Šta je sljedeće?", whatNextItems);

  // Info alert
  const infoAlert = generateAlert({
    type: "info",
    message: `Sačuvajte ovaj email sa vašom referencom ${escapeHtml(bookingReference)} za buduću komunikaciju.`,
  });

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(guestName))}
    ${generateIntro(`Vaš zahtjev za rezervaciju u nekretnini ${escapeHtml(propertyName)} je uspješno zaprimljen.`)}
    ${pendingAlert}
    ${bankTransferSection}
    ${whatsNextCard}
    ${infoAlert}
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: "Hvala što ste odabrali BookBed!",
    },
  });
}

/**
 * Send Refined Premium pending booking request email via Resend
 */
export async function sendPendingBookingRequestEmailV2(
  resendClient: Resend,
  params: PendingBookingRequestParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generatePendingBookingRequestEmailV2(params);
  const subject = `Zahtjev za rezervaciju zaprimljen - ${escapeHtml(params.bookingReference)}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: ownerEmail || fromEmail,
    subject: subject,
    html: html,
  });
}
