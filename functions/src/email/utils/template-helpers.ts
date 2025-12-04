/**
 * Email Template Helpers
 *
 * Helper functions for generating HTML components.
 * All functions return sanitized HTML strings safe for email clients.
 */

/**
 * Escape HTML to prevent XSS attacks
 * CRITICAL: Always escape user-provided content
 */
export function escapeHtml(text: string): string {
  const map: Record<string, string> = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  };
  return text.replace(/[&<>"']/g, (char) => map[char]);
}

/**
 * Format currency in EUR
 */
export function formatCurrency(amount: number): string {
  return `€${amount.toFixed(2)}`;
}

/**
 * Format date in Croatian locale
 */
export function formatDate(date: Date): string {
  return date.toLocaleDateString("hr-HR", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

/**
 * Format date range
 */
export function formatDateRange(startDate: Date, endDate: Date): string {
  return `${formatDate(startDate)} - ${formatDate(endDate)}`;
}

/**
 * Calculate number of nights between two dates
 */
export function calculateNights(checkIn: Date, checkOut: Date): number {
  const diffTime = checkOut.getTime() - checkIn.getTime();
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
}

/**
 * Generate email header with icon and title
 */
export interface HeaderOptions {
  icon: string; // SVG string
  title: string;
  subtitle?: string;
  bookingReference?: string;
}

export function generateHeader(options: HeaderOptions): string {
  const {icon, title, subtitle, bookingReference} = options;

  return `
    <div class="header">
      ${icon}
      <h1>${escapeHtml(title)}</h1>
      ${subtitle ? `<p class="header-subtitle">${escapeHtml(subtitle)}</p>` : ""}
      ${bookingReference ? `
        <div class="booking-ref">
          <span>Referenca</span>
          <strong>${escapeHtml(bookingReference)}</strong>
        </div>
      ` : ""}
    </div>
  `.trim();
}

/**
 * Generate card component with title and content
 */
export function generateCard(title: string, content: string): string {
  return `
    <div class="card">
      <h2>${escapeHtml(title)}</h2>
      ${content}
    </div>
  `.trim();
}

/**
 * Generate details table row
 */
export interface DetailRow {
  label: string;
  value: string;
  highlight?: boolean;
}

export function generateDetailsTable(rows: DetailRow[]): string {
  const rowsHtml = rows.map((row) => `
    <tr>
      <td class="label">${escapeHtml(row.label)}</td>
      <td class="${row.highlight ? "value-highlight" : "value"}">
        ${escapeHtml(row.value)}
      </td>
    </tr>
  `).join("");

  return `
    <table class="details-table">
      ${rowsHtml}
    </table>
  `.trim();
}

/**
 * Generate primary action button
 */
export interface ButtonOptions {
  text: string;
  url: string;
  secondary?: boolean;
}

export function generateButton(options: ButtonOptions): string {
  const {text, url, secondary} = options;
  const buttonClass = secondary ? "button button-secondary" : "button";

  return `
    <div class="button-container">
      <a href="${escapeHtml(url)}" class="${buttonClass}">
        ${escapeHtml(text)}
      </a>
    </div>
  `.trim();
}

/**
 * Generate alert component
 */
export interface AlertOptions {
  type: "info" | "success" | "warning" | "error";
  title?: string;
  message: string;
}

export function generateAlert(options: AlertOptions): string {
  const {type, title, message} = options;

  return `
    <div class="alert alert-${type}">
      ${title ? `<strong>${escapeHtml(title)}</strong>` : ""}
      ${escapeHtml(message)}
    </div>
  `.trim();
}

/**
 * Generate badge component
 */
export type BadgeType = "success" | "warning" | "error" | "info" | "neutral";

export function generateBadge(text: string, type: BadgeType = "neutral"): string {
  return `
    <span class="badge badge-${type}">${escapeHtml(text)}</span>
  `.trim();
}

/**
 * Generate divider
 */
export function generateDivider(): string {
  return '<hr class="divider" />';
}

/**
 * Generate footer with contact info
 */
export interface FooterOptions {
  contactEmail?: string;
  contactPhone?: string;
  additionalText?: string;
}

export function generateFooter(options: FooterOptions = {}): string {
  const {contactEmail, contactPhone, additionalText} = options;

  let footerContent = "";

  if (contactEmail || contactPhone) {
    footerContent += "<p>";
    if (contactEmail && contactPhone) {
      footerContent += `Imate pitanja? Kontaktirajte nas na <a href="mailto:${escapeHtml(contactEmail)}">${escapeHtml(contactEmail)}</a> ili na broj ${escapeHtml(contactPhone)}.`;
    } else if (contactEmail) {
      footerContent += `Imate pitanja? Kontaktirajte nas na <a href="mailto:${escapeHtml(contactEmail)}">${escapeHtml(contactEmail)}</a>.`;
    } else if (contactPhone) {
      footerContent += `Imate pitanja? Kontaktirajte nas na broj ${escapeHtml(contactPhone)}.`;
    }
    footerContent += "</p>";
  }

  if (additionalText) {
    footerContent += `<p>${escapeHtml(additionalText)}</p>`;
  }

  // Default footer text
  if (!footerContent) {
    footerContent = `
      <p>Ovaj email je automatski generisan. Molimo ne odgovarajte direktno na ovaj email.</p>
    `;
  }

  return `
    <div class="footer">
      ${footerContent}
    </div>
  `.trim();
}

/**
 * Generate greeting text
 */
export function generateGreeting(guestName: string): string {
  return `
    <p class="greeting">Poštovani/a ${escapeHtml(guestName)},</p>
  `.trim();
}

/**
 * Generate intro paragraph
 */
export function generateIntro(text: string): string {
  return `
    <p class="intro">${escapeHtml(text)}</p>
  `.trim();
}

/**
 * Generate booking details card
 */
export interface BookingDetails {
  propertyName: string;
  unitName: string;
  checkIn: Date;
  checkOut: Date;
  guests: number;
}

export function generateBookingDetailsCard(details: BookingDetails): string {
  const nights = calculateNights(details.checkIn, details.checkOut);

  const rows: DetailRow[] = [
    {label: "Nekretnina", value: details.propertyName},
    {label: "Jedinica", value: details.unitName},
    {label: "Prijava", value: formatDate(details.checkIn)},
    {label: "Odjava", value: formatDate(details.checkOut)},
    {label: "Broj noćenja", value: `${nights} ${nights === 1 ? "noć" : "noći"}`},
    {label: "Broj gostiju", value: details.guests.toString()},
  ];

  return generateCard("Detalji rezervacije", generateDetailsTable(rows));
}

/**
 * Generate payment details card
 */
export interface PaymentDetails {
  totalAmount: number;
  depositAmount?: number;
  remainingAmount?: number;
  paymentMethod?: string;
}

export function generatePaymentDetailsCard(details: PaymentDetails): string {
  const rows: DetailRow[] = [];

  if (details.depositAmount !== undefined && details.depositAmount > 0) {
    rows.push({label: "Kapara", value: formatCurrency(details.depositAmount)});
  }

  if (details.remainingAmount !== undefined && details.remainingAmount > 0) {
    rows.push({label: "Preostalo za platiti", value: formatCurrency(details.remainingAmount)});
  }

  rows.push({
    label: "Ukupna cijena",
    value: formatCurrency(details.totalAmount),
    highlight: true,
  });

  if (details.paymentMethod) {
    const methodText = details.paymentMethod === "stripe" ? "Kartica" :
                       details.paymentMethod === "bank_transfer" ? "Bankovni prijenos" :
                       "Plaćanje na mjestu";
    rows.push({label: "Način plaćanja", value: methodText});
  }

  return generateCard("Detalji plaćanja", generateDetailsTable(rows));
}

/**
 * Generate complete email wrapper
 */
export function wrapEmailContent(content: string): string {
  return `
    <div class="email-wrapper">
      <div class="email-container">
        ${content}
      </div>
    </div>
  `.trim();
}
