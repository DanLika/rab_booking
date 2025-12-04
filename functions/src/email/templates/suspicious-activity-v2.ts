/**
 * Suspicious Activity Alert Email Template V2
 * Refined Premium Design (Alert/Danger Style)
 *
 * Design Specs:
 * - Card padding: 28px
 * - Border radius: 12px (cards), 8px (alerts)
 * - Typography: 22px/600 (heading), 15px/400 (body), 16px/600 (labels)
 * - Shadows: 0 1px 2px rgba(0,0,0,0.06)
 * - Colors: Alert/Danger theme (red #DC2626)
 * - Admin-focused design
 */

import {Resend} from "resend";

export interface SuspiciousActivityParams {
  adminEmail: string;
  activityType: string;
  details: string;
  timestamp?: string;
  ipAddress?: string;
  userAgent?: string;
}

/**
 * Generate Refined Premium suspicious activity alert email
 */
export function generateSuspiciousActivityEmailV2(
  params: SuspiciousActivityParams
): string {
  const {activityType, details, timestamp, ipAddress, userAgent} = params;
  const detectedAt = timestamp || new Date().toISOString();

  return `
<!DOCTYPE html>
<html lang="hr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>⚠️ Suspicious Activity Detected - ${activityType}</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB; line-height: 1.6;">

  <!-- Main Container -->
  <div style="max-width: 600px; margin: 0 auto; padding: 24px 16px;">

    <!-- Alert Header Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #FEE2E2; margin-bottom: 16px; text-align: center;">
      <!-- Alert Icon -->
      <div style="margin-bottom: 16px;">
        <svg width="64" height="64" viewBox="0 0 64 64" style="display: inline-block;">
          <path d="M32 8 L58 52 L6 52 Z" fill="#FEE2E2" stroke="#DC2626" stroke-width="2"/>
          <circle cx="32" cy="44" r="2" fill="#991B1B"/>
          <path d="M32 26 L32 38" stroke="#991B1B" stroke-width="4" stroke-linecap="round"/>
        </svg>
      </div>

      <!-- Title -->
      <h1 style="margin: 0 0 8px 0; font-size: 22px; font-weight: 600; line-height: 1.3; color: #1F2937;">
        ⚠️ Suspicious Activity Detected
      </h1>

      <!-- Subtitle -->
      <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #6B7280;">
        Immediate investigation required
      </p>

      <!-- Activity Type Badge -->
      <div style="display: inline-block; background-color: #FEE2E2; padding: 8px 16px; border-radius: 6px; border: 1px solid #FECACA;">
        <span style="font-size: 14px; font-weight: 400; color: #991B1B;">Type:</span>
        <strong style="font-size: 14px; font-weight: 600; color: #7F1D1D; margin-left: 4px;">${activityType}</strong>
      </div>
    </div>

    <!-- Alert Notice -->
    <div style="background-color: #FEE2E2; border-left: 4px solid #DC2626; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0 0 8px 0; font-size: 16px; font-weight: 600; color: #991B1B;">
        🚨 Action Required
      </p>
      <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #7F1D1D;">
        Suspicious activity has been detected in your system. Please investigate immediately.
      </p>
    </div>

    <!-- Activity Details Card -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 28px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; margin-bottom: 16px;">
      <p style="margin: 0 0 16px 0; font-size: 16px; font-weight: 600; color: #1F2937;">
        Activity Details
      </p>

      <!-- Details Box -->
      <div style="background-color: #F9FAFB; border-radius: 8px; padding: 16px; margin-bottom: 16px; border: 1px solid #E5E7EB;">
        <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 600; color: #1F2937;">
          Description:
        </p>
        <p style="margin: 0; font-size: 15px; font-weight: 400; line-height: 1.6; color: #374151; font-family: 'Courier New', monospace;">
          ${details}
        </p>
      </div>

      <!-- Metadata -->
      <div style="border-top: 1px solid #E5E7EB; padding-top: 16px;">
        <div style="margin-bottom: 8px;">
          <span style="font-size: 14px; font-weight: 400; color: #6B7280;">⏰ Detected at:</span>
          <span style="font-size: 14px; font-weight: 600; color: #1F2937; margin-left: 8px;">${detectedAt}</span>
        </div>
        ${ipAddress ? `
        <div style="margin-bottom: 8px;">
          <span style="font-size: 14px; font-weight: 400; color: #6B7280;">🌐 IP Address:</span>
          <span style="font-size: 14px; font-weight: 600; color: #1F2937; margin-left: 8px;">${ipAddress}</span>
        </div>
        ` : ""}
        ${userAgent ? `
        <div>
          <span style="font-size: 14px; font-weight: 400; color: #6B7280;">🖥️ User Agent:</span>
          <span style="font-size: 13px; font-weight: 400; color: #6B7280; margin-left: 8px; word-break: break-all;">${userAgent}</span>
        </div>
        ` : ""}
      </div>
    </div>

    <!-- Recommended Actions -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; margin-bottom: 16px;">
      <p style="margin: 0 0 12px 0; font-size: 15px; font-weight: 600; color: #1F2937;">
        Recommended Actions
      </p>
      <ul style="margin: 0; padding-left: 20px; font-size: 15px; font-weight: 400; line-height: 1.8; color: #1F2937;">
        <li style="margin-bottom: 8px;">Review the activity details carefully</li>
        <li style="margin-bottom: 8px;">Check system logs for related events</li>
        <li style="margin-bottom: 8px;">Verify if this is a false positive</li>
        <li>Take appropriate security measures if confirmed</li>
      </ul>
    </div>

    <!-- Security Notice -->
    <div style="background-color: #FEF3C7; border-left: 4px solid #D97706; border-radius: 8px; padding: 20px; margin-bottom: 16px;">
      <p style="margin: 0; font-size: 14px; font-weight: 400; line-height: 1.6; color: #78350F;">
        ⚡ This is an automated security alert. Please do not reply to this email.
      </p>
    </div>

    <!-- Footer -->
    <div style="background-color: #FFFFFF; border-radius: 12px; padding: 24px; box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06); border: 1px solid #F3F4F6; text-align: center;">
      <p style="margin: 0; font-size: 14px; font-weight: 400; color: #6B7280;">
        RabBooking Security System
      </p>

      <div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid #E5E7EB;">
        <p style="margin: 0; font-size: 12px; color: #9CA3AF;">
          © ${new Date().getFullYear()} All rights reserved.
        </p>
      </div>
    </div>

  </div>
</body>
</html>
  `.trim();
}

/**
 * Send Refined Premium suspicious activity alert email via Resend
 */
export async function sendSuspiciousActivityEmailV2(
  resendClient: Resend,
  params: SuspiciousActivityParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateSuspiciousActivityEmailV2(params);
  const subject = `⚠️ Suspicious Activity Detected - ${params.activityType}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.adminEmail,
    subject: subject,
    html: html,
  });
}
