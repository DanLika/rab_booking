/**
 * Trial Expiring Soon Email Template
 *
 * Sent to users when their free trial is about to expire.
 */

import {getResendClient} from "../../emailService";
import {logError, logSuccess} from "../../logger";
import {generateEmailHtml} from "./base";
import {
  generateHeader,
  generateGreeting,
  generateParagraph,
  generateAlert,
  generateButton,
} from "../utils/template-helpers";

// Standard BookBed from email and name
const FROM_NAME = "BookBed";
const FROM_EMAIL = "info@bookbed.io";

export interface TrialExpiringSoonParams {
  email: string;
  userName: string;
  daysRemaining: number;
  userId: string;
}

/**
 * Generate V2 HTML for trial expiring soon email
 *
 * @param {string} userName - The name of the user
 * @param {number} daysRemaining - Days left in the trial
 * @return {object} The email subject and HTML
 */
export function generateTrialExpiringSoonEmailV2(
  userName: string,
  daysRemaining: number
): { subject: string; html: string } {
  const daysText = daysRemaining === 1 ? "dan" : "dana";
  const subject =
    `Vaš BookBed probni period ističe za ${daysRemaining} ${daysText}`;
  const emoji = "⏰";

  const header = generateHeader({
    emoji,
    title: `Vaš probni period ističe za ${daysRemaining} ${daysText}`,
    subtitle: "Ne gubite pristup alatima za upravljanje rezervacijama",
  });

  const content = `
    ${generateGreeting(userName)}

    ${generateParagraph(
    "Vaš besplatni probni period za BookBed ističe za " +
      `<strong>${daysRemaining} ${daysText}</strong>. Kako biste ` +
      "osigurali neometan nastavak korištenja i upravljanje " +
      "rezervacijama bez prekida, molimo vas da nadogradite svoj račun."
  )}

    ${generateAlert({
    type: "warning",
    title: "Što se događa kada probni period istekne?",
    message: "Izgubit ćete pristup nadzornoj ploči za vlasnike, " +
        "upravljanju rezervacijama i sinkronizaciji kalendara. Vaše " +
        "postojeće rezervacije i podaci bit će sačuvani, ali widget " +
        "za rezervacije prestat će funkcionirati.",
  })}

    ${generateButton({
    text: "Nadogradi račun",
    url: "https://app.bookbed.io/subscription?" +
        `utm_source=trial_warning&utm_medium=email&days=${daysRemaining}`,
  })}

    ${generateParagraph(
    "Imate pitanja? Odgovorite na ovaj email i rado ćemo vam pomoći.",
    {marginBottom: "0"}
  )}
  `;

  const html = generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: "Ovaj email ste primili jer vaš probni period " +
        "uskoro ističe.",
    },
  });

  return {subject, html};
}

/**
 * Send Trial Expiring Soon Email (V2)
 *
 * @param {TrialExpiringSoonParams} params - The parameters
 * @return {Promise<void>} Resolves when sent
 */
export async function sendTrialExpiringSoonEmailV2(
  params: TrialExpiringSoonParams
): Promise<void> {
  const {email, userName, daysRemaining, userId} = params;

  try {
    const resend = getResendClient();
    const {subject, html} = generateTrialExpiringSoonEmailV2(
      userName,
      daysRemaining
    );

    const fromName = process.env.FROM_NAME || FROM_NAME;
    const fromEmail = process.env.FROM_EMAIL || FROM_EMAIL;

    const result = await resend.emails.send({
      from: `${fromName} <${fromEmail}>`,
      to: email,
      subject,
      html,
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const typedResult = result as any;
    if (typedResult.error) {
      throw new Error(
        "Resend API error: " +
        `${typedResult.error.message || JSON.stringify(typedResult.error)}`
      );
    }

    logSuccess("[Trial Email] Expiring warning sent (V2)", {
      email,
      daysRemaining,
      userId,
    });
  } catch (error) {
    logError("[Trial Email] Failed to send expiring warning (V2)", error, {
      email,
      daysRemaining,
      userId,
    });
    throw error;
  }
}

/**
 * Legacy template function
 * @deprecated Use generateTrialExpiringSoonEmailV2 instead
 *
 * @param {string} userName - The name of the user
 * @param {number} daysRemaining - Days left in the trial
 * @return {object} The email subject and HTML
 */
export const getTrialExpiringSoonTemplate = (
  userName: string,
  daysRemaining: number
) => {
  return generateTrialExpiringSoonEmailV2(userName, daysRemaining);
};
