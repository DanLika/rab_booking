/**
 * Refund Notification Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getRefundIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateGreeting,
  generateIntro,
  generateCard,
  generateDetailsTable,
  generateAlert,
  DetailRow,
  formatCurrency,
  escapeHtml,
} from "../utils/template-helpers";

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
export function generateRefundNotificationEmailV2(
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
    bookingReference: escapeHtml(bookingReference),
  });

  // Success alert
  const successAlert = generateAlert({
    type: "success",
    title: "Povrat novca uspješno obrađen",
    message: `Povrat u iznosu od ${formatCurrency(refundAmount)} je obrađen.`,
  });

  // Refund details card
  const refundDetailsRows: DetailRow[] = [
    {label: "Iznos povrata", value: formatCurrency(refundAmount), highlight: true},
    {label: "Status", value: "Obrađeno"},
  ];
  if (reason) {
    refundDetailsRows.push({label: "Razlog", value: escapeHtml(reason)});
  }
  const refundDetailsCard = generateCard(
    "Detalji povrata",
    generateDetailsTable(refundDetailsRows)
  );

  // Info alert
  const infoAlert = generateAlert({
    type: "info",
    title: "Kada će novac stići?",
    message: "Novac bi trebao biti vidljiv na vašem računu u roku od 5-7 radnih dana, ovisno o vašoj banci.",
  });

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(guestName))}
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
      contactEmail: contactEmail ? escapeHtml(contactEmail) : undefined,
      contactPhone: contactPhone ? escapeHtml(contactPhone) : undefined,
      additionalText: "Imate pitanja o povratu novca?",
    },
  });
}

/**
 * Send Refined Premium refund notification email via Resend
 * Gmail-optimized with proper HTML escaping
 */
export async function sendRefundNotificationEmailV2(
  resendClient: Resend,
  params: RefundNotificationParams,
  fromEmail: string,
  fromName: string,
  ownerEmail?: string
): Promise<void> {
  const html = generateRefundNotificationEmailV2(params);
  const subject = `Povrat novca obrađen - ${escapeHtml(params.bookingReference)}`;

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
