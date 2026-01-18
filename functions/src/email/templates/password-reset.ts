/**
 * Password Reset Email Template V2
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
  generateCard,
  generateAlert,
  escapeHtml,
} from "../utils/template-helpers";

export interface PasswordResetParams {
  email: string;
  resetLink: string;
  expiresInMinutes?: number;
}

/**
 * Generate password reset email HTML
 */
export function generatePasswordResetEmailV2(
  params: PasswordResetParams
): string {
  const {resetLink, expiresInMinutes = 60} = params;

  // Header with warning icon
  const header = generateHeader({
    icon: getWarningIcon(),
    title: "Resetiranje lozinke",
    subtitle: "Zatražili ste resetiranje lozinke za vaš BookBed nalog",
  });

  // Reset button
  const resetButton = generateButton({
    text: "Resetiraj lozinku",
    url: resetLink,
  });

  // Alternative link card
  const alternativeLinkCard = generateCard(
    "",
    `
      <p style="margin: 0 0 12px 0; font-size: 14px; font-weight: 500; color: #6B7280; line-height: 1.5;">
        Dugme ne radi? Kopirajte i zalijepite link ispod u vaš browser:
      </p>
      <p style="margin: 0; font-size: 13px; font-weight: 400; color: #3B82F6; word-break: break-all; font-family: 'Courier New', Courier, monospace; line-height: 1.6;">
        ${escapeHtml(resetLink)}
      </p>
    `
  );

  // Security alert
  const securityAlert = generateAlert({
    type: "warning",
    title: "Sigurnosna napomena",
    message: "Ako niste zatražili resetiranje lozinke, možete sigurno ignorisati ovaj email. Vaša lozinka se neće promijeniti dok ne kliknete na link i kreirajte novu lozinku.",
  });

  // Expiry info alert
  const expiryAlert = generateAlert({
    type: "info",
    title: `Link ističe za ${expiresInMinutes} minuta`,
    message: `Za sigurnost, link za resetiranje lozinke je ograničen na ${expiresInMinutes} minuta. Ako link istekne, zatražite novi.`,
  });

  // Combine all content
  const content = `
    ${generateIntro(`Kliknite na dugme ispod da biste resetirali vašu lozinku. Link će biti aktivan ${expiresInMinutes} minuta.`)}
    ${resetButton}
    ${alternativeLinkCard}
    ${securityAlert}
    ${expiryAlert}
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: "Hvala što koristite BookBed! Ovo je automatski email. Molimo ne odgovarajte na ovu poruku.",
    },
  });
}

/**
 * Send Modern Premium password reset email via Resend
 */
export async function sendPasswordResetEmailV2(
  resendClient: Resend,
  params: PasswordResetParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generatePasswordResetEmailV2(params);
  const subject = "Resetiranje lozinke - BookBed";

  // IMPORTANT: Check the result object - Resend can return success with error inside
  const result = await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.email,
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


