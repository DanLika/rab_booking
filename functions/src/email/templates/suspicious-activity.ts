/**
 * Suspicious Activity Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Sent to users when suspicious activity is detected on their account.
 */

import {Resend} from "resend";
import {sendEmailWithValidation} from "../utils/send-with-validation";
import {generateEmailHtml} from "./base";
import {getShieldIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateGreeting,
  generateIntro,
  generateCard,
  generateDetailsTable,
  generateButton,
  generateAlert,
  DetailRow,
  formatDate,
  escapeHtml,
} from "../utils/template-helpers";

export interface SuspiciousActivityParams {
  email: string;
  name: string;
  activityDescription: string;
  time: Date;
  ipAddress: string;
  secureAccountUrl: string;
}

/**
 * Generate suspicious activity email HTML
 */
export function generateSuspiciousActivityEmailV2(
  params: SuspiciousActivityParams
): string {
  const {
    name,
    activityDescription,
    time,
    ipAddress,
    secureAccountUrl,
  } = params;

  const header = generateHeader({
    icon: getShieldIcon(),
    title: "Sigurnosno Upozorenje",
    subtitle: "Detektovana je sumnjiva aktivnost na vašem nalogu",
  });

  const greeting = generateGreeting(escapeHtml(name) || "Korisnik");

  const intro = generateIntro(
    "Primijetili smo neobičnu aktivnost povezanu sa vašim BookBed nalogom. Molimo vas da odmah pregledate detalje ispod."
  );

  const activityDetails: DetailRow[] = [
    {label: "Aktivnost", value: escapeHtml(activityDescription)},
    {label: "Vrijeme", value: formatDate(time)},
    {label: "IP Adresa", value: escapeHtml(ipAddress)},
  ];

  const activityCard = generateCard(
    "Detalji o Aktivnosti",
    generateDetailsTable(activityDetails)
  );

  const alert = generateAlert({
    type: "warning",
    title: "Akcija Potrebna",
    message: "Ako vi niste izvršili ovu akciju, preporučujemo vam da odmah obezbijedite svoj nalog mijenjanjem lozinke.",
  });

  const secureButton = generateButton({
    text: "Obezbijedi Nalog",
    url: secureAccountUrl,
  });

  const content = `
    ${greeting}
    ${intro}
    ${activityCard}
    ${alert}
    ${secureButton}
  `;

  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: "Hvala što koristite BookBed! Ako imate pitanja, slobodno nas kontaktirajte.",
    },
  });
}

/**
 * Send suspicious activity email via Resend
 */
export async function sendSuspiciousActivityEmailV2(
  resendClient: Resend,
  params: SuspiciousActivityParams,
  fromEmail: string,
  fromName: string
): Promise<string | undefined> {
  const html = generateSuspiciousActivityEmailV2(params);

  const subject = "Sigurnosno Upozorenje - Sumnjiva aktivnost na nalogu";

  return sendEmailWithValidation(resendClient, {
    from: `${fromName} <${fromEmail}>`,
    to: params.email,
    subject: subject,
    html,
  });
}
