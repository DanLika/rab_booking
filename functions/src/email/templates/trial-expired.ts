/**
 * Trial Expired Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Sent to users when their trial has expired.
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getErrorIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateIntro,
  generateButton,
  generateAlert,
  escapeHtml,
} from "../utils/template-helpers";

export interface TrialExpiredParams {
  userName: string;
  upgradeUrl: string;
}

/**
 * Generate Trial Expired email HTML (V2)
 *
 * @param {TrialExpiredParams} params The parameters for the email
 * @return {string} The generated HTML string
 */
export function generateTrialExpiredEmailV2(
  params: TrialExpiredParams
): string {
  const {userName, upgradeUrl} = params;

  // Header with error icon
  const header = generateHeader({
    icon: getErrorIcon(64),
    title: "Your Trial Has Expired",
    subtitle: "Upgrade to restore full access to BookBed",
  });

  // Info alert
  const infoMsg = "Don't worry, your data is safe! Your property details, " +
    "units, and existing bookings have been preserved.";
  const infoAlert = generateAlert({
    type: "info",
    title: "Your data is safe",
    message: infoMsg,
  });

  // Upgrade button
  const upgradeButton = generateButton({
    text: "Upgrade to Premium",
    url: upgradeUrl,
  });

  // Combine all content
  const introMsg = "Your free trial of BookBed has ended. Your account is " +
    "now in read-only mode, which means you can view your existing data " +
    "but can't create new bookings or access premium features.";
  const content = `
    <p style="margin: 0 0 16px 0; font-size: 16px; color: #1F2937;">
      Hi ${escapeHtml(userName)},
    </p>
    ${generateIntro(introMsg)}
    ${infoAlert}
    ${upgradeButton}
    <p style="margin: 0; font-size: 13px; color: #9CA3AF; text-align: center;">
      Questions? Reply to this email and we'll help you out.
    </p>
  `;

  // Generate complete email
  const footerText = "This email was sent by BookBed. " +
    "You're receiving this because your trial has expired.";
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: footerText,
    },
  });
}

/**
 * Send Trial Expired email via Resend (V2)
 *
 * @param {Resend} resendClient The Resend client instance
 * @param {TrialExpiredParams} params The parameters for the email
 * @param {string} fromEmail The sender's email address
 * @param {string} fromName The sender's name
 * @param {string} toEmail The recipient's email address
 * @return {Promise<void>} A promise that resolves when the email is sent
 */
export async function sendTrialExpiredEmailV2(
  resendClient: Resend,
  params: TrialExpiredParams,
  fromEmail: string,
  fromName: string,
  toEmail: string
): Promise<void> {
  const html = generateTrialExpiredEmailV2(params);
  const subject = "Your BookBed trial has expired - Upgrade to continue";

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
