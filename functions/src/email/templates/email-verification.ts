/**
 * Email Verification Code Template V2
 * Minimalist Design using Helper Functions
 *
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getInfoIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateCard,
  generateAlert,
  escapeHtml,
} from "../utils/template-helpers";

export interface EmailVerificationParams {
  email: string;
  code: string;
}

/**
 * Generate email verification code email HTML
 */
export function generateEmailVerificationEmailV2(
  params: EmailVerificationParams
): string {
  const {code} = params;

  // Header with info icon
  const header = generateHeader({
    icon: getInfoIcon(),
    title: "Verifikacijski kod",
    subtitle: "Koristite kod ispod za verifikaciju vaše email adrese",
  });

  // Code display card
  const codeCard = generateCard(
    "",
    `
      <p style="margin: 0 0 20px 0; font-size: 15px; font-weight: 500; line-height: 1.6; color: #374151; text-align: center;">
        Vaš verifikacijski kod je:
      </p>
      <div style="background-color: #EFF6FF; border: 2px solid #3B82F6; border-radius: 12px; padding: 24px 20px; margin-bottom: 20px; text-align: center;">
        <div style="font-size: 32px; font-weight: 700; letter-spacing: 6px; color: #1E40AF; font-family: 'Courier New', Courier, monospace;">
          ${escapeHtml(code)}
        </div>
      </div>
      <p style="margin: 0; font-size: 14px; font-weight: 400; color: #6B7280; text-align: center; line-height: 1.5;">
        Kod vrijedi 10 minuta
      </p>
    `
  );

  // Security alert
  const securityAlert = generateAlert({
    type: "warning",
    title: "Sigurnosna napomena",
    message: "Nikada ne dijelite ovaj kod sa drugima. Naš tim nikada neće tražiti vaš verifikacijski kod putem telefona ili emaila.",
  });

  // Help info alert
  const helpAlert = generateAlert({
    type: "info",
    title: "Niste zatražili ovaj kod?",
    message: "Ako niste zatražili verifikaciju, možete sigurno ignorisati ovaj email. Vaš nalog je siguran.",
  });

  // Combine all content
  const content = `
    ${codeCard}
    ${securityAlert}
    ${helpAlert}
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
 * Send Refined Premium email verification code via Resend
 */
export async function sendEmailVerificationEmailV2(
  resendClient: Resend,
  params: EmailVerificationParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateEmailVerificationEmailV2(params);
  const subject = "Verifikacijski kod";

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

  // Log successful send with Resend email ID for debugging
  if (typedResult.data?.id) {
    // eslint-disable-next-line no-console
    console.log(`[EmailVerification] Resend email sent, ID: ${typedResult.data.id}`);
  }
}
