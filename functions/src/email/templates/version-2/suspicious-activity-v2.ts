/**
 * Suspicious Activity Alert Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Uses helper functions for clean, maintainable code.
 * All user-provided content is HTML-escaped for security.
 */

import {Resend} from "resend";
import {generateEmailHtml} from "../base";
import {getErrorIcon} from "../../utils/svg-icons";
import {
  generateHeader,
  generateCard,
  generateAlert,
  escapeHtml,
} from "../../utils/template-helpers";

export interface SuspiciousActivityParams {
  adminEmail: string;
  activityType: string;
  details: string;
  timestamp?: string;
  ipAddress?: string;
  userAgent?: string;
}

/**
 * Generate suspicious activity alert email HTML
 */
export function generateSuspiciousActivityEmailV2(
  params: SuspiciousActivityParams
): string {
  const {activityType, details, timestamp, ipAddress, userAgent} = params;
  const detectedAt = timestamp || new Date().toISOString();

  // Header with error icon
  const header = generateHeader({
    icon: getErrorIcon(),
    title: "Suspicious Activity Detected",
    subtitle: "Immediate investigation required",
    bookingReference: escapeHtml(activityType),
  });

  // Action required alert
  const actionAlert = generateAlert({
    type: "error",
    title: "Action Required",
    message: "Suspicious activity has been detected in your system. Please investigate immediately.",
  });

  // Activity details card
  const activityDetailsCard = generateCard(
    "Activity Details",
    `
      <div style="background-color: #F9FAFB; border-radius: 8px; padding: 16px; margin-bottom: 16px; border: 1px solid #E5E7EB;">
        <p style="margin: 0 0 12px 0; font-size: 14px; font-weight: 600; color: #1F2937;">
          Description:
        </p>
        <p style="margin: 0; font-size: 13px; font-weight: 400; line-height: 1.5; color: #374151; font-family: 'Courier New', monospace;">
          ${escapeHtml(details)}
        </p>
      </div>
      <div style="border-top: 1px solid #E5E7EB; padding-top: 16px;">
        <div style="margin-bottom: 8px;">
          <span style="font-size: 13px; font-weight: 400; color: #6B7280;">Detected at:</span>
          <span style="font-size: 13px; font-weight: 600; color: #1F2937; margin-left: 8px;">${escapeHtml(detectedAt)}</span>
        </div>
        ${ipAddress ? `
        <div style="margin-bottom: 8px;">
          <span style="font-size: 13px; font-weight: 400; color: #6B7280;">IP Address:</span>
          <span style="font-size: 13px; font-weight: 600; color: #1F2937; margin-left: 8px;">${escapeHtml(ipAddress)}</span>
        </div>
        ` : ""}
        ${userAgent ? `
        <div>
          <span style="font-size: 13px; font-weight: 400; color: #6B7280;">User Agent:</span>
          <span style="font-size: 12px; font-weight: 400; color: #6B7280; margin-left: 8px; word-break: break-all;">${escapeHtml(userAgent)}</span>
        </div>
        ` : ""}
      </div>
    `
  );

  // Recommended actions card
  const actionsCard = generateCard(
    "Recommended Actions",
    `
      <ul style="margin: 0; padding-left: 20px; font-size: 14px; font-weight: 400; line-height: 1.7; color: #1F2937;">
        <li style="margin-bottom: 6px;">Review the activity details carefully</li>
        <li style="margin-bottom: 6px;">Check system logs for related events</li>
        <li style="margin-bottom: 6px;">Verify if this is a false positive</li>
        <li>Take appropriate security measures if confirmed</li>
      </ul>
    `
  );

  // Security notice alert
  const securityNotice = generateAlert({
    type: "warning",
    message: "This is an automated security alert. Please do not reply to this email.",
  });

  // Combine all content
  const content = `
    ${actionAlert}
    ${activityDetailsCard}
    ${actionsCard}
    ${securityNotice}
  `;

  // Generate complete email
  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: "BookBed Security System",
    },
  });
}

/**
 * Send Refined Premium suspicious activity alert email via Resend
 * Gmail-optimized with proper HTML escaping
 */
export async function sendSuspiciousActivityEmailV2(
  resendClient: Resend,
  params: SuspiciousActivityParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateSuspiciousActivityEmailV2(params);
  const subject = `⚠️ Suspicious Activity Detected - ${escapeHtml(params.activityType)}`;

  await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.adminEmail,
    subject: subject,
    html: html,
  });
}
