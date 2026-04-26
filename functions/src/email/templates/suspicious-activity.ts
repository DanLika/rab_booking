/**
 * Suspicious Activity Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getSecurityIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateIntro,
  generateButton,
  generateCard,
  generateAlert,
  generateDetailsTable,
  DetailRow,
  escapeHtml,
} from "../utils/template-helpers";

export interface SuspiciousActivityParams {
  email: string;
  name: string;
  activityDescription: string;
  time: string;
  ipAddress: string;
  deviceInfo: string;
  location: string;
  actionUrl: string;
}

/**
 * Generate suspicious activity email HTML
 *
 * @param {SuspiciousActivityParams} params - Email parameters
 * @return {string} HTML email string
 */
export function generateSuspiciousActivityEmailV2(
  params: SuspiciousActivityParams
): string {
  const {
    name,
    activityDescription,
    time,
    ipAddress,
    deviceInfo,
    location,
    actionUrl,
  } = params;

  // Header with security/shield icon
  const header = generateHeader({
    icon: getSecurityIcon(),
    title: "Sumnjiva aktivnost detektovana",
    subtitle: "Primijetili smo neuobičajenu aktivnost na vašem nalogu",
  });

  // Action button
  const actionButton = generateButton({
    text: "Pregledaj aktivnost",
    url: actionUrl,
  });

  // Security alert
  const securityAlert = generateAlert({
    type: "warning",
    title: "Zahtijeva vašu pažnju",
    message: "Preporučujemo da promijenite lozinku ako ovo niste bili vi.",
  });

  // Details table
  const details: DetailRow[] = [
    {label: "Aktivnost", value: escapeHtml(activityDescription)},
    {label: "Vrijeme", value: escapeHtml(time)},
    {label: "IP Adresa", value: escapeHtml(ipAddress)},
    {label: "Uređaj", value: escapeHtml(deviceInfo)},
    {label: "Lokacija", value: escapeHtml(location)},
  ];

  const detailsCard = generateCard(
    "Detalji aktivnosti",
    generateDetailsTable(details)
  );

  // Combine all content
  const content = `
    ${generateIntro("Poštovani/a " + escapeHtml(name) +
      ", detektovali smo sumnjivu aktivnost na vašem BookBed nalogu. " +
      "Detalji su prikazani ispod.")}
    ${securityAlert}
    ${detailsCard}
    ${actionButton}
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: "Ovo je automatsko sigurnosno obavještenje. " +
        "Molimo ne odgovarajte na ovu poruku.",
    },
  });
}

/**
 * Send Suspicious Activity email via Resend
 *
 * @param {Resend} resendClient - Initialized Resend client
 * @param {SuspiciousActivityParams} params - Email parameters
 * @param {string} fromEmail - Sender email address
 * @param {string} fromName - Sender name
 */
export async function sendSuspiciousActivityEmailV2(
  resendClient: Resend,
  params: SuspiciousActivityParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateSuspiciousActivityEmailV2(params);
  const subject = "Sigurnosno upozorenje: Sumnjiva aktivnost detektovana";

  // IMPORTANT: Check the result object - Resend can return success with error
  const result = await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.email,
    subject: subject,
    html: html,
  });

  // Resend SDK returns { data, error } - check for error
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const typedResult = result as any;
  if (typedResult.error) {
    throw new Error(
      "Resend API error: " +
      (typedResult.error.message || JSON.stringify(typedResult.error))
    );
  }
}
