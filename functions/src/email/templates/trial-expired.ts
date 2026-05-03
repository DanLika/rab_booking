/**
 * Trial Expired Email Template V2
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
  generateAlert,
  generateButton,
  escapeHtml,
} from "../utils/template-helpers";

export interface TrialExpiredParams {
  guestEmail: string;
  guestName: string;
  upgradeUrl: string;
}

/**
 * Generate trial expired email HTML
 */
export function generateTrialExpiredEmailV2(
  params: TrialExpiredParams
): string {
  const {guestName, upgradeUrl} = params;

  // Header with warning icon (as sad face or similar isn't standard, warning is appropriate for expiration)
  const header = generateHeader({
    icon: getWarningIcon(),
    title: "Vaš probni period je istekao",
    subtitle: "Ali još uvijek nije kasno za nastavak!",
  });

  // Info alert explaining what happened
  const infoAlert = generateAlert({
    type: "info",
    title: "Vaši podaci su sigurni",
    message: "Sve vaše rezervacije, nekretnine i postavke su sačuvane. Nadogradite svoj račun u bilo kojem trenutku kako biste ponovno dobili puni pristup.",
  });

  // Upgrade button
  const upgradeButton = generateButton({
    text: "Nadogradi račun",
    url: upgradeUrl,
  });

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(guestName))}
    ${generateIntro("Vaš besplatni probni period za BookBed je završio. Vaš račun je sada u načinu samo za čitanje (read-only), što znači da možete pregledavati postojeće podatke, ali ne možete kreirati nove rezervacije ili pristupiti premium značajkama.")}
    ${infoAlert}
    ${upgradeButton}
    <p style="margin: 0; font-size: 13px; color: #9CA3AF; text-align: center; padding-top: 16px;">
      Trebate pomoć pri odluci? Odgovorite na ovaj email i rado ćemo odgovoriti na vaša pitanja.
    </p>
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: "Ovaj email je poslan od strane BookBeda jer je vaš probni period istekao.",
    },
  });
}

/**
 * Send Trial Expired email via Resend
 * Gmail-optimized with proper HTML escaping
 */
export async function sendTrialExpiredEmailV2(
  resendClient: Resend,
  params: TrialExpiredParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateTrialExpiredEmailV2(params);
  const subject = "Vaš BookBed probni period je istekao - Nadogradite za nastavak";

  // IMPORTANT: Check the result object - Resend can return success with error inside
  const result = await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
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
