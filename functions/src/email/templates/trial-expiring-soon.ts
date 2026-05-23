/**
 * Trial Expiring Soon Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Sent to users when their free trial is about to expire.
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {sendEmailWithValidation} from "../utils/send-with-validation";
import {generateEmailHtml} from "./base";
import {getWarningIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateGreeting,
  generateIntro,
  generateButton,
  generateAlert,
  escapeHtml,
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
 * @param {TrialExpiringSoonParams} params Parameters for the email
 * @return {string} The generated HTML string
 */
export function generateTrialExpiringSoonEmailV2(
  params: TrialExpiringSoonParams
): string {
  const {userName, daysRemaining, upgradeUrl} = params;

  const titleText = "Vaš BookBed probni period ističe za " +
    `${daysRemaining} dan${daysRemaining > 1 ? "a" : ""}`;

  // Header with warning icon
  const header = generateHeader({
    icon: getWarningIcon(),
    title: titleText,
    subtitle: "Nemojte izgubiti pristup alatima",
  });

  const warningAlert = generateAlert({
    type: "warning",
    title: "Što se događa kada probni period istekne?",
    message: "Izgubit ćete pristup nadzornoj ploči za vlasnike, upravljanju " +
      "rezervacijama i sinkronizaciji kalendara. Vaše postojeće " +
      "rezervacije i podaci će biti sačuvani.",
  });

  const upgradeButton = generateButton({
    text: "Nadogradi račun",
    url: upgradeUrl,
  });

  const introText = "Vaš besplatni probni period za BookBed ističe za " +
    `<strong>${daysRemaining} dan${daysRemaining > 1 ? "a" : ""}</strong>. ` +
    "Kako biste nastavili nesmetano upravljati svojim rezervacijama, " +
    "molimo vas da nadogradite na plaćeni plan.";

  const footerText = "Imate pitanja? Odgovorite na ovaj email " +
    "i rado ćemo vam pomoći.";

  const footerHtml = "<p style=\"margin: 0; font-size: 13px; " +
    `color: #9CA3AF; text-align: center;">${footerText}</p>`;

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(userName))}
    ${generateIntro(introText)}
    ${warningAlert}
    ${upgradeButton}
    ${footerHtml}
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: "Ovaj email je poslao BookBed jer " +
        "vaš probni period uskoro ističe.",
    },
  });
}

/**
 * Send trial expiring soon email via Resend
 *
 * @param {Resend} resendClient The Resend client
 * @param {TrialExpiringSoonParams} params Parameters for the email
 * @param {string} fromEmail The sender email
 * @param {string} fromName The sender name
 * @return {Promise<void>} A promise that resolves when sent
 */
export async function sendTrialExpiringSoonEmailV2(
  resendClient: Resend,
  params: TrialExpiringSoonParams,
  fromEmail: string,
  fromName: string
): Promise<string | undefined> {
  const html = generateTrialExpiringSoonEmailV2(params);
  const subject = "⏰ Vaš BookBed probni period ističe za " +
    `${params.daysRemaining} dan${params.daysRemaining > 1 ? "a" : ""}`;

  return sendEmailWithValidation(resendClient, {
    from: `${fromName} <${fromEmail}>`,
    to: params.email,
    subject: subject,
    html: html,
  });
}
