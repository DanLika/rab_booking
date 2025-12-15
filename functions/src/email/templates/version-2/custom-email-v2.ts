/**
 * Custom Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Allows property owners to send custom messages to guests.
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "../base";
import {getEmailIcon} from "../../utils/svg-icons";
import {
  generateHeader,
  generateGreeting,
  escapeHtml,
} from "../../utils/template-helpers";

/**
 * Custom guest email parameters (V2)
 */
export interface CustomGuestEmailParamsV2 {
  guestEmail: string;
  guestName: string;
  subject: string;
  message: string;
  ownerEmail?: string;
  propertyName?: string;
}

/**
 * Generate custom guest email HTML (V2)
 */
export function generateCustomGuestEmailV2(
  params: CustomGuestEmailParamsV2
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
    title: escapeHtml(subject),
    subtitle: propertyName ? `Poruka od: ${escapeHtml(propertyName)}` : undefined,
  });

  // Escape and format message (preserve line breaks)
  const formattedMessage = escapeHtml(message)
    .replace(/\n/g, "<br>");

  // Combine all content
  const content = `
    ${generateGreeting(escapeHtml(guestName))}
    <div style="padding: 16px 0; font-size: 14px; font-weight: 400; line-height: 1.7; color: #1F2937;">
      ${formattedMessage}
    </div>
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: propertyName ? escapeHtml(propertyName) : undefined,
    },
  });
}

/**
 * Send custom guest email via Resend (V2)
 *
 * SECURITY: message and subject are HTML-escaped in generateCustomGuestEmailV2
 */
export async function sendCustomGuestEmailV2(
  resendClient: Resend,
  params: CustomGuestEmailParamsV2,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateCustomGuestEmailV2(params);

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.guestEmail,
    replyTo: params.ownerEmail || fromEmail,
    subject: params.subject,
    html: html,
  });
}
