/**
 * Trial Expiring Soon Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Sent to users when their trial is about to expire.
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getClockIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateIntro,
  generateButton,
  generateAlert,
  escapeHtml,
} from "../utils/template-helpers";

export interface TrialExpiringSoonParams {
  userName: string;
  daysRemaining: number;
  upgradeUrl: string;
}

/**
 * Generate Trial Expiring Soon email HTML (V2)
 *
 * @param {TrialExpiringSoonParams} params The parameters for the email
 * @return {string} The generated HTML string
 */
export function generateTrialExpiringSoonEmailV2(
  params: TrialExpiringSoonParams
): string {
  const {userName, daysRemaining, upgradeUrl} = params;

  // Header with clock icon
  const plural = daysRemaining === 1 ? "" : "s";
  const header = generateHeader({
    icon: getClockIcon(64),
    title: `Your Trial Expires in ${daysRemaining} Day${plural}`,
    subtitle: "Don't lose access to your booking management tools",
  });

  // Warning alert
  const warningMsg = "You'll lose access to the owner dashboard, booking " +
    "management, and calendar sync features. " +
    "Your existing bookings and data will be preserved.";
  const warningAlert = generateAlert({
    type: "warning",
    title: "What happens when your trial ends?",
    message: warningMsg,
  });

  // Upgrade button
  const upgradeButton = generateButton({
    text: "Upgrade Now",
    url: upgradeUrl,
  });

  // Combine all content
  const introMsg = "Your free trial of BookBed will expire in " +
    `<strong>${daysRemaining} day${plural}</strong>. ` +
    "To continue managing your bookings without interruption, " +
    "please upgrade to a paid plan.";
  const content = `
    <p style="margin: 0 0 16px 0; font-size: 16px; color: #1F2937;">
      Hi ${escapeHtml(userName)},
    </p>
    ${generateIntro(introMsg)}
    ${warningAlert}
    ${upgradeButton}
    <p style="margin: 0; font-size: 13px; color: #9CA3AF; text-align: center;">
      Questions? Reply to this email and we'll help you out.
    </p>
  `;

  // Generate complete email
  const footerText = "This email was sent by BookBed. " +
    "You're receiving this because your trial is expiring soon.";
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: footerText,
    },
  });
}

/**
 * Send Trial Expiring Soon email via Resend (V2)
 *
 * @param {Resend} resendClient The Resend client instance
 * @param {TrialExpiringSoonParams} params The parameters for the email
 * @param {string} fromEmail The sender's email address
 * @param {string} fromName The sender's name
 * @param {string} toEmail The recipient's email address
 * @return {Promise<void>} A promise that resolves when the email is sent
 */
export async function sendTrialExpiringSoonEmailV2(
  resendClient: Resend,
  params: TrialExpiringSoonParams,
  fromEmail: string,
  fromName: string,
  toEmail: string
): Promise<void> {
  const html = generateTrialExpiringSoonEmailV2(params);
  const plural = params.daysRemaining === 1 ? "" : "s";
  const subject = "⏰ Your BookBed trial expires in " +
    `${params.daysRemaining} day${plural}`;

  // IMPORTANT: Check the result object
  // Resend can return success with error inside
  const result = await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: toEmail,
    subject: subject,
    html: html,
  });

  // Resend SDK returns { data, error } - check for error
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const typedResult = result as any;
  if (typedResult.error) {
    const errorMsg = typedResult.error.message ||
      JSON.stringify(typedResult.error);
    throw new Error(`Resend API error: ${errorMsg}`);
  }
}
