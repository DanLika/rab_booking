/**
 * Trial Expiring Soon Email Template V2
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
  generateIntro,
  generateButton,
  generateAlert,
} from "../utils/template-helpers";

export interface TrialExpiringSoonParams {
  email: string;
  userName: string;
  daysRemaining: number;
  upgradeUrl: string;
}

/**
 * Generate trial expiring soon email HTML
 *
 * @param {TrialExpiringSoonParams} params Parameters
 * @return {string} Generated HTML string
 */
export function generateTrialExpiringSoonEmailV2(
  params: TrialExpiringSoonParams,
): string {
  const {userName, daysRemaining, upgradeUrl} = params;
  const daysText = daysRemaining === 1 ? "dan" : "dana";

  // Header
  const header = generateHeader({
    icon: getWarningIcon(),
    title: `Probni period ističe za ${daysRemaining} ${daysText}`,
    subtitle: "Nemojte izgubiti pristup alatima za upravljanje rezervacijama",
  });

  // Intro
  const intro = generateIntro(
    `Poštovani/a ${userName}, vaš besplatni probni period za BookBed ` +
      `ističe za ${daysRemaining} ${daysText}. Kako biste nastavili ` +
      "koristiti BookBed bez prekida, molimo vas da aktivirate svoj račun.",
  );

  // Alert
  const warningAlert = generateAlert({
    type: "warning",
    title: "Što se događa kada probni period istekne?",
    message:
      "Izgubit ćete pristup nadzornoj ploči, a vaš widget za " +
      "rezervacije prestat će funkcionirati. Vaši podaci će biti " +
      "sačuvani i sigurni.",
  });

  // Upgrade button
  const upgradeButton = generateButton({
    text: "Aktivirajte račun",
    url: upgradeUrl,
  });

  // Combine all content
  const content = `
    ${intro}
    ${warningAlert}
    ${upgradeButton}
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText:
        "Hvala što koristite BookBed! Ako imate bilo " +
        "kakvih pitanja, slobodno odgovorite na ovaj email.",
    },
  });
}

/**
 * Send Trial Expiring Soon email via Resend
 *
 * @param {Resend} resendClient Resend API client
 * @param {TrialExpiringSoonParams} params Parameters
 * @param {string} fromEmail Sender email
 * @param {string} fromName Sender name
 */
export async function sendTrialExpiringSoonEmailV2(
  resendClient: Resend,
  params: TrialExpiringSoonParams,
  fromEmail: string,
  fromName: string,
): Promise<void> {
  const html = generateTrialExpiringSoonEmailV2(params);
  const daysText = params.daysRemaining === 1 ? "dan" : "dana";
  const subject = "⏰ Vaš BookBed probni period ističe za " +
    `${params.daysRemaining} ${daysText}`;

  const result = await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.email,
    subject: subject,
    html: html,
  });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const typedResult = result as any;
  if (typedResult.error) {
    const errorMsg =
      typedResult.error.message || JSON.stringify(typedResult.error);
    throw new Error(`Resend API error: ${errorMsg}`);
  }
}
