/**
 * Email Verification Code Template V2
 * Refined Premium Design (Info/Security Style)
 *
 * Design Specs:
 * - Card padding: 28px
 * - Border radius: 12px (cards), 8px (code box)
 * - Typography: 22px/600 (heading), 15px/400 (body)
 * - Shadows: 0 1px 2px rgba(0,0,0,0.06)
 * - Colors: Info/Blue theme (#2563EB)
 * - Large verification code display
 */

import {Resend} from "resend";

export interface EmailVerificationParams {
  email: string;
  code: string;
}

/**
 * Generate Refined Premium email verification code email
 */
export function generateEmailVerificationEmailV2(
  params: EmailVerificationParams
): string {
  const {code} = params;

  return `
<!DOCTYPE html>
<html lang="hr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>Verifikacijski kod</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB; line-height: 1.6;">

  <!-- Main Container -->
  <div style="max-width: 600px; margin: 0 auto; padding: 24px 16px;">

    <!-- Security Header Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #DBEAFE; margin-bottom: 16px; text-align: center;">
      <!-- Shield Icon -->
      <div style="margin-bottom: 16px;">
        <svg width="64" height="64" viewBox="0 0 64 64" style="display: inline-block;">
          <path d="M32 8 L48 14 L48 30 Q48 42 32 54 Q16 42 16 30 L16 14 Z" fill="#DBEAFE" stroke="#2563EB" stroke-width="2"/>
          <path d="M28 32 L30 34 L36 28" stroke="#1E40AF" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
        </svg>
      </div>

      <!-- Title -->
      <h1 style="margin: 0 0 8px 0; font-size: 22px; font-weight: 600; line-height: 1.3; color: #1F2937;">
        Verifikacijski kod
      </h1>

      <!-- Subtitle -->
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #6B7280;">
        Koristite kod ispod za verifikaciju email adrese
      </p>
    </div>

    <!-- Verification Code Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; margin-bottom: 16px; text-align: center;">
      <p style="margin: 0 0 16px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #1F2937;">
        Vaš verifikacijski kod je:
      </p>

      <!-- Large Code Display -->
      <div style="background-color: #EFF6FF; border: 2px solid #2563EB; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
        <div style="font-size: 36px; font-weight: 700; letter-spacing: 8px; color: #1E40AF; font-family: 'Courier New', monospace;">
          ${code}
        </div>
      </div>

      <p style="margin: 0; font-size: 14px; font-weight: 400; line-height: 1.6; color: #6B7280;">
        Kod vrijedi <strong>10 minuta</strong>
      </p>
    </div>

    <!-- Security Notice Alert -->
    <div style="background-color: #FEF3C7; border-left: 4px solid #D97706; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0 0 8px 0; font-size: 16px; font-weight: 600; color: #92400E;">
        🔒 Sigurnosna napomena
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #78350F;">
        Nikada ne dijelite ovaj kod sa drugima. Naš tim nikada neće tražiti vaš verifikacijski kod.
      </p>
    </div>

    <!-- Help Info -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; margin-bottom: 16px;">
      <p style="margin: 0 0 8px 0; font-size: 15px; font-weight: 600; color: #1F2937;">
        Niste zatražili ovaj kod?
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #6B7280;">
        Ako niste zatražili verifikaciju, možete sigurno ignorisati ovaj email.
      </p>
    </div>

    <!-- Footer -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; text-align: center;">
      <p style="margin: 0; font-size: 14px; font-weight: 400; color: #6B7280;">
        Hvala što koristite našu uslugu!
      </p>

      <div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid #E5E7EB;">
        <p style="margin: 0; font-size: 12px; color: #9CA3AF;">
          © ${new Date().getFullYear()} Sva prava pridržana.
        </p>
      </div>
    </div>

  </div>
</body>
</html>
  `.trim();
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

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.email,
    subject: subject,
    html: html,
  });
}
