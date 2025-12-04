/**
 * Custom Email Template
 *
 * Allows property owners to send custom messages to guests.
 * Includes basic formatting and safety features.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getEmailIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateGreeting,
  escapeHtml,
} from "../utils/template-helpers";

/**
 * Custom guest email parameters
 */
export interface CustomGuestEmailParams {
  guestEmail: string;
  guestName: string;
  subject: string;
  message: string;
  ownerEmail?: string;
  propertyName?: string;
}

/**
 * Generate custom guest email HTML
 */
export function generateCustomGuestEmail(
  params: CustomGuestEmailParams
): string {
  const {
    guestName,
    subject,
    message,
    propertyName,
  } = params;

  // Header with email icon
  const header = generateHeader({
    icon: getEmailIcon(64, "#FFFFFF"),
    title: subject,
    subtitle: propertyName ? `Poruka od: ${propertyName}` : undefined,
  });

  // Escape and format message (preserve line breaks)
  const formattedMessage = escapeHtml(message)
    .replace(/\n/g, "<br>");

  // Combine all content
  const content = `
    ${generateGreeting(guestName)}
    <div style="padding: 16px 0;">
      ${formattedMessage}
    </div>
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
  });
}

/**
 * Send custom guest email via Resend
 *
 * SECURITY: message and subject are already escaped in generateCustomGuestEmail
 */
export async function sendCustomGuestEmail(
  resendClient: Resend,
  params: CustomGuestEmailParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateCustomGuestEmail(params);

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: params.ownerEmail || fromEmail,
    subject: params.subject,
    html: html,
    text: stripHtml(html),
  });
}

/**
 * Strip HTML tags to create plain text version
 */
function stripHtml(html: string): string {
  return html
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, " ")
    .trim();
}
