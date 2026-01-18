/**
 * Overbooking Detected Email Template V2
 * Minimalist Design using Helper Functions
 *
 * Sent to owners when an overbooking conflict is detected
 */

import {Resend} from "resend";
import {generateEmailHtml} from "./base";
import {getWarningIcon} from "../utils/svg-icons";
import {
  generateHeader,
  generateGreeting,
  generateIntro,
  generateCard,
  generateDetailsTable,
  generateButton,
  generateAlert,
  DetailRow,
  formatDate,
  escapeHtml,
} from "../utils/template-helpers";

export interface OverbookingDetectedParams {
  ownerEmail: string;
  ownerName: string;
  unitName: string;
  conflictId: string;
  booking1GuestName: string;
  booking1CheckIn: Date;
  booking1CheckOut: Date;
  booking1Source: string;
  booking2GuestName: string;
  booking2CheckIn: Date;
  booking2CheckOut: Date;
  booking2Source: string;
  conflictDates: Date[];
  viewConflictUrl?: string;
  blockBookingComUrl?: string;
  blockAirbnbUrl?: string;
  viewInAppUrl?: string;
}

/**
 * Generate overbooking detected email HTML
 */
export function generateOverbookingDetectedEmailV2(
  params: OverbookingDetectedParams
): string {
  const {
    ownerName,
    unitName,
    conflictId,
    booking1GuestName,
    booking1CheckIn,
    booking1CheckOut,
    booking2GuestName,
    booking2CheckIn,
    booking2CheckOut,
    booking1Source,
    booking2Source,
    conflictDates,
    blockBookingComUrl,
    blockAirbnbUrl,
    viewInAppUrl,
  } = params;

  const conflictDateRange = conflictDates.length > 0
    ? `${formatDate(conflictDates[0])} - ${formatDate(conflictDates[conflictDates.length - 1])}`
    : "Unknown dates";

  const header = generateHeader({
    icon: getWarningIcon(),
    title: "Overbooking Detected",
    subtitle: "Immediate action required",
  });

  const greeting = generateGreeting(escapeHtml(ownerName));

  const intro = generateIntro(
    `An overbooking conflict has been detected for ${escapeHtml(unitName)}. Immediate action is required to resolve this conflict.`
  );

  const conflictDetails: DetailRow[] = [
    {label: "Unit", value: escapeHtml(unitName)},
    {label: "Conflict Dates", value: conflictDateRange},
    {label: "Conflict ID", value: conflictId},
  ];

  const booking1Details: DetailRow[] = [
    {label: "Guest", value: escapeHtml(booking1GuestName)},
    {label: "Check-in", value: formatDate(booking1CheckIn)},
    {label: "Check-out", value: formatDate(booking1CheckOut)},
    {label: "Source", value: escapeHtml(booking1Source)},
  ];

  const booking2Details: DetailRow[] = [
    {label: "Guest", value: escapeHtml(booking2GuestName)},
    {label: "Check-in", value: formatDate(booking2CheckIn)},
    {label: "Check-out", value: formatDate(booking2CheckOut)},
    {label: "Source", value: escapeHtml(booking2Source)},
  ];

  const alert = generateAlert({
    type: "warning",
    title: "Action Required",
    message: "Please resolve this conflict immediately by blocking dates on the appropriate platform or cancelling one of the bookings.",
  });

  const conflictDetailsCard = generateCard(
    "Conflict Details",
    generateDetailsTable(conflictDetails)
  );

  const booking1Card = generateCard(
    "Booking 1",
    generateDetailsTable(booking1Details)
  );

  const booking2Card = generateCard(
    "Booking 2",
    generateDetailsTable(booking2Details)
  );

  const buttons: string[] = [];
  if (viewInAppUrl) {
    buttons.push(
      generateButton({
        text: "View in App",
        url: viewInAppUrl,
      })
    );
  }
  if (blockBookingComUrl) {
    buttons.push(
      generateButton({
        text: "Block on Booking.com",
        url: blockBookingComUrl,
        secondary: true,
      })
    );
  }
  if (blockAirbnbUrl) {
    buttons.push(
      generateButton({
        text: "Block on Airbnb",
        url: blockAirbnbUrl,
        secondary: true,
      })
    );
  }

  const instructionsAlert = generateAlert({
    type: "info",
    title: "What to do:",
    message: "1. Review both bookings to determine which one should be kept\n2. Block the conflicting dates on the appropriate external platform\n3. Contact the guest if cancellation is necessary\n4. Update the booking status in the app",
  });

  const content = `
    ${greeting}
    ${intro}
    ${alert}
    ${conflictDetailsCard}
    ${booking1Card}
    ${booking2Card}
    ${buttons.join("")}
    ${instructionsAlert}
  `;

  return generateEmailHtml({
    header,
    content,
  });
}

/**
 * Send overbooking detected email via Resend
 */
export async function sendOverbookingDetectedEmailV2(
  resendClient: Resend,
  params: OverbookingDetectedParams,
  fromEmail: string,
  fromName: string
): Promise<void> {
  const html = generateOverbookingDetectedEmailV2(params);

  const subject = `Overbooking Detected - Immediate Action Required - ${escapeHtml(params.conflictId)}`;

  // IMPORTANT: Check the result object - Resend can return success with error inside
  const result = await resendClient.emails.send({
    from: `${fromName} <${fromEmail}>`,
    to: params.ownerEmail,
    subject: subject,
    html,
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

