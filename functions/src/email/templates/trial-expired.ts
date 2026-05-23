/**
 * Trial Expired Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Sent to users when their free trial has expired.
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {sendEmailWithValidation} from "../utils/send-with-validation";
import {generateEmailHtml} from "./base";
import {
  generateHeader,
  generateGreeting,
  generateIntro,
  generateButton,
  generateAlert,
  escapeHtml,
} from "../utils/template-helpers";

export interface TrialExpiredParams {
  email: string;
  userName: string;
  upgradeUrl: string;
}

/**
 * Generate trial expired email HTML
 *
 * @param {TrialExpiredParams} params Parameters for the email
 * @return {string} The generated HTML string
 */
export function generateTrialExpiredEmailV2(
  params: TrialExpiredParams
): string {
  const {userName, upgradeUrl} = params;

  // Header with warning icon (could be sad face but emoji fits the style)
  const header = generateHeader({
    emoji: "😢",
    title: "Vaš probni period je istekao",
    subtitle: "Ali još uvijek nije kasno za nastavak!",
  });

  const infoAlert = generateAlert({
    type: "info",
    title: "Vaši podaci su sigurni",
    message: "Sve vaše rezervacije, nekretnine i postavke su sačuvane. " +
      "Nadogradite račun u bilo kojem trenutku kako biste povratili " +
      "potpuni pristup svim značajkama.",
  });

  const upgradeButton = generateButton({
    text: "Nadogradi za nastavak",
    url: upgradeUrl,
  });

  const introText = "Vaš besplatni probni period za BookBed je završio. " +
    "Vaš račun je sada u načinu samo za čitanje, što znači da možete " +
    "pregledavati svoje postojeće podatke, ali ne možete stvarati " +
    "nove rezervacije niti pristupati premium značajkama.";

  const footerText = "Trebate pomoć pri odluci? Odgovorite na ovaj email " +
    "i rado ćemo odgovoriti na vaša pitanja.";

  const footerHtml = "<p style=\"margin: 0; font-size: 13px; " +
    "color: #9CA3AF; text-align: center;\">" + footerText + "</p>";

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(userName))}
    ${generateIntro(introText)}
    ${infoAlert}
    ${upgradeButton}
    ${footerHtml}
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: "Ovaj email je poslao BookBed jer " +
        "je vaš probni period istekao.",
    },
  });
}

/**
 * Send trial expired email via Resend
 *
 * @param {Resend} resendClient The Resend client
 * @param {TrialExpiredParams} params Parameters for the email
 * @param {string} fromEmail The sender email
 * @param {string} fromName The sender name
 * @return {Promise<void>} A promise that resolves when sent
 */
export async function sendTrialExpiredEmailV2(
  resendClient: Resend,
  params: TrialExpiredParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateTrialExpiredEmailV2(params);
  const subject = "Vaš BookBed probni period je istekao - Nadogradite račun";
  await sendEmailWithValidation(resendClient, {
    from: `${fromName} <${fromEmail}>`,
    to: params.email,
    subject: subject,
    html: html,
  });
}
