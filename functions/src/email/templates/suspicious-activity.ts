/**
 * Suspicious Activity Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Sent to administrators when suspicious activity is detected
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getWarningIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateIntro,
  generateCard,
  generateDetailsTable,
  generateAlert,
  DetailRow,
  formatDate,
  escapeHtml,
} from "../utils/template-helpers";

export interface SuspiciousActivityParams {
  adminEmail: string;
  eventType: string;
  severity: "low" | "medium" | "high" | "critical";
  description: string;
  ipAddress?: string;
  userId?: string;
  propertyId?: string;
  metadata?: Record<string, unknown>;
  timestamp?: Date;
}

/**
 * Generate suspicious activity email HTML
 * @param {SuspiciousActivityParams} params - The parameters
 * @return {string} The HTML content
 */
export function generateSuspiciousActivityEmailV2(
  params: SuspiciousActivityParams
): string {
  const {
    eventType,
    severity,
    description,
    ipAddress,
    userId,
    propertyId,
    metadata,
    timestamp = new Date(),
  } = params;

  const header = generateHeader({
    icon: getWarningIcon(),
    title: "Suspicious Activity Detected",
    subtitle: "Severity: " + severity.toUpperCase(),
  });

  const intro = generateIntro(
    "The system has detected potentially suspicious activity " +
    "that requires your attention."
  );

  const eventDetails: DetailRow[] = [
    {label: "Event Type", value: escapeHtml(eventType)},
    {label: "Description", value: escapeHtml(description)},
    {label: "Time", value: formatDate(timestamp)},
  ];

  if (ipAddress) {
    eventDetails.push({label: "IP Address", value: escapeHtml(ipAddress)});
  }
  if (userId) {
    eventDetails.push({label: "User ID", value: escapeHtml(userId)});
  }
  if (propertyId) {
    eventDetails.push({label: "Property ID", value: escapeHtml(propertyId)});
  }

  const isHighSeverity = severity === "critical" || severity === "high";
  const alert = generateAlert({
    type: isHighSeverity ? "error" : "warning",
    title: "Action Recommended",
    message: "Please review this activity and take appropriate " +
      "action if necessary. Check the system logs for more details.",
  });

  const detailsCard = generateCard(
    "Activity Details",
    generateDetailsTable(eventDetails)
  );

  let metadataCard = "";
  if (metadata && Object.keys(metadata).length > 0) {
    const metadataRows: DetailRow[] = Object.entries(metadata)
      .map(([key, value]) => {
        const valStr = typeof value === "object" ?
          JSON.stringify(value) : String(value);
        return {
          label: escapeHtml(key),
          value: escapeHtml(valStr),
        };
      });

    metadataCard = generateCard(
      "Additional Context",
      generateDetailsTable(metadataRows)
    );
  }

  const content = `
    ${intro}
    ${alert}
    ${detailsCard}
    ${metadataCard}
  `;

  return generateEmailHtml({
    header,
    content,
    footer: {
      additionalText: "This is an automated security alert from BookBed.",
    },
  });
}

/**
 * Send suspicious activity email via Resend
 * @param {Resend} resendClient - The Resend client
 * @param {SuspiciousActivityParams} params - The parameters
 * @param {string} fromEmail - The from email address
 * @param {string} fromName - The from name
 * @return {Promise<void>}
 */
export async function sendSuspiciousActivityEmailV2(
  resendClient: Resend,
  params: SuspiciousActivityParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateSuspiciousActivityEmailV2(params);

  const subject = `[SECURITY ${params.severity.toUpperCase()}] ` +
    `${escapeHtml(params.eventType)} - BookBed Alert`;

  const result = await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.adminEmail,
    subject: subject,
    html,
  });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const typedResult = result as any;
  if (typedResult.error) {
    const errMsg = typedResult.error.message;
    const errStr = JSON.stringify(typedResult.error);
    throw new Error(`Resend API error: ${errMsg || errStr}`);
  }
}
