/**
 * Password Reset Email Template V2
 * Modern Premium Design - 2025 Redesign
 *
 * Design Specs:
 * - Card padding: 20-24px (mobile-friendly)
 * - Border radius: 12px (cards), 8px (buttons)
 * - Typography: 22px/700 (heading), 14px/400 (body)
 * - Shadows: 0 4px 16px rgba(0,0,0,0.1) (elevated cards)
 * - Colors: Modern gradient theme with blue accent
 * - Premium spacing and visual hierarchy
 */

import {Resend} from "resend";

export interface PasswordResetParams {
  email: string;
  resetLink: string;
  expiresInMinutes?: number;
}

/**
 * Generate Modern Premium password reset email
 */
export function generatePasswordResetEmailV2(
  params: PasswordResetParams
): string {
  const {resetLink, expiresInMinutes = 60} = params;

  return `
<!DOCTYPE html>
<html lang="hr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>Resetiranje lozinke - BookBed</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); line-height: 1.6; min-height: 100vh;">

  <!-- Main Container -->
  <div style="max-width: 600px; margin: 0 auto; padding: 40px 16px;">

    <!-- Premium Header Card with Gradient -->
    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 16px; padding: 32px 24px; box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15); margin-bottom: 24px; text-align: center;">
      <!-- Lock Icon -->
      <div style="margin-bottom: 16px; font-size: 56px; line-height: 1; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.2));">
        🔑
      </div>

      <!-- Title -->
      <h1 style="margin: 0 0 8px 0; font-size: 22px; font-weight: 700; line-height: 1.3; color: #FFFFFF; letter-spacing: -0.5px;">
        Resetiranje lozinke
      </h1>

      <!-- Subtitle -->
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.5; color: rgba(255, 255, 255, 0.95);">
        Zatražili ste resetiranje lozinke za vaš BookBed nalog
      </p>
    </div>

    <!-- Main Content Card -->
    <div style="background-color: #FFFFFF; border-radius: 16px; padding: 32px 24px; box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1); margin-bottom: 20px;">
      <p style="margin: 0 0 20px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #374151;">
        Kliknite na dugme ispod da biste resetirali vašu lozinku. Link će biti aktivan <strong>${expiresInMinutes} minuta</strong>.
      </p>

      <!-- Reset Button -->
      <div style="text-align: center; margin: 28px 0;">
        <a href="${resetLink}" style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #FFFFFF; text-decoration: none; padding: 16px 32px; border-radius: 12px; font-size: 16px; font-weight: 600; box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4); transition: transform 0.2s;">
          Resetiraj lozinku
        </a>
      </div>

      <!-- Alternative Link -->
      <div style="background-color: #F9FAFB; border-radius: 8px; padding: 16px; margin-top: 24px; border: 1px solid #E5E7EB;">
        <p style="margin: 0 0 8px 0; font-size: 13px; font-weight: 500; color: #6B7280;">
          Dugme ne radi? Kopirajte i zalijepite link ispod u vaš browser:
        </p>
        <p style="margin: 0; font-size: 12px; font-weight: 400; color: #3B82F6; word-break: break-all; font-family: 'Courier New', Courier, monospace; line-height: 1.5;">
          ${resetLink}
        </p>
      </div>
    </div>

    <!-- Security Notice Alert - Enhanced -->
    <div style="background: linear-gradient(135deg, #FEF3C7 0%, #FDE68A 100%); border-left: 4px solid #F59E0B; border-radius: 12px; padding: 20px; margin-bottom: 20px; box-shadow: 0 2px 8px rgba(245, 158, 11, 0.15);">
      <div style="display: flex; align-items: flex-start; gap: 12px;">
        <div style="font-size: 24px; line-height: 1;">🔒</div>
        <div>
          <p style="margin: 0 0 8px 0; font-size: 15px; font-weight: 700; color: #92400E; line-height: 1.3;">
            Sigurnosna napomena
          </p>
          <p style="margin: 0; font-size: 14px; font-weight: 400; line-height: 1.6; color: #78350F;">
            Ako niste zatražili resetiranje lozinke, možete sigurno ignorisati ovaj email. Vaša lozinka se neće promijeniti dok ne kliknete na link i kreirajte novu lozinku.
          </p>
        </div>
      </div>
    </div>

    <!-- Expiry Info Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 20px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06); margin-bottom: 20px; border: 1px solid #E5E7EB;">
      <div style="display: flex; align-items: flex-start; gap: 12px;">
        <div style="font-size: 20px; line-height: 1;">⏱️</div>
        <div>
          <p style="margin: 0 0 6px 0; font-size: 15px; font-weight: 600; color: #1F2937;">
            Link ističe za ${expiresInMinutes} minuta
          </p>
          <p style="margin: 0; font-size: 14px; font-weight: 400; line-height: 1.6; color: #6B7280;">
            Za sigurnost, link za resetiranje lozinke je ograničen na ${expiresInMinutes} minuta. Ako link istekne, zatražite novi.
          </p>
        </div>
      </div>
    </div>

    <!-- Footer - Premium -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px 20px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06); text-align: center;">
      <p style="margin: 0 0 8px 0; font-size: 15px; font-weight: 500; color: #1F2937;">
        Hvala što koristite <strong style="color: #667eea;">BookBed</strong>!
      </p>
      <p style="margin: 0; font-size: 13px; font-weight: 400; color: #9CA3AF; line-height: 1.5;">
        Ovo je automatski email. Molimo ne odgovarajte na ovu poruku.
      </p>

      <div style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #E5E7EB;">
        <p style="margin: 0; font-size: 12px; color: #9CA3AF;">
          © ${new Date().getFullYear()} BookBed. Sva prava pridržana.
        </p>
      </div>
    </div>

  </div>
</body>
</html>
  `.trim();
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

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.email,
    subject: subject,
    html: html,
  });
}


