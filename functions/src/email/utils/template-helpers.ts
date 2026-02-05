/**
 * Email Template Helpers - Inline Styles Version
 *
 * All functions return HTML with inline styles for Gmail compatibility.
 * Gmail strips CSS classes, so every element must have inline styles.
 *
 * Color palette: Neutral grays, no purple or strong colors.
 */

// ============================================================================
// COLOR PALETTE (Neutral, minimalist)
// ============================================================================

const COLORS = {
  // Backgrounds
  pageBg: "#F9FAFB",
  cardBg: "#FFFFFF",
  cardBgSubtle: "#F3F4F6",

  // Text
  textPrimary: "#1F2937",
  textSecondary: "#6B7280",
  textMuted: "#9CA3AF",

  // Borders
  border: "#E5E7EB",
  borderLight: "#F3F4F6",

  // Buttons
  buttonPrimary: "#374151",
  buttonPrimaryHover: "#1F2937",
  buttonSecondary: "#6B7280",

  // Status colors (muted versions)
  success: "#059669",
  successBg: "#ECFDF5",
  successBorder: "#A7F3D0",

  warning: "#D97706",
  warningBg: "#FFFBEB",
  warningBorder: "#FDE68A",

  error: "#DC2626",
  errorBg: "#FEF2F2",
  errorBorder: "#FECACA",

  info: "#2563EB",
  infoBg: "#EFF6FF",
  infoBorder: "#BFDBFE",
};

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Escape HTML to prevent XSS attacks
 * CRITICAL: Always escape user-provided content
 */
export function escapeHtml(text: string | null | undefined): string {
  if (!text) return "";

  const map: Record<string, string> = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "\"": "&quot;",
    "'": "&#39;",
  };
  return String(text).replace(/[&<>"']/g, (char) => map[char]);
}

/**
 * Format currency in EUR
 */
export function formatCurrency(amount: number): string {
  return `€${amount.toFixed(2)}`;
}

/**
 * Format date in Croatian locale
 *
 * Uses timeZone: "Europe/Zagreb" to ensure dates are displayed correctly
 * regardless of server timezone (Cloud Functions run in UTC).
 *
 * This is sufficient for Croatian properties - the timeZone parameter
 * handles all timezone conversion automatically.
 */
export function formatDate(date: Date): string {
  return date.toLocaleDateString("hr-HR", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
    timeZone: "Europe/Zagreb",
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

// ============================================================================
// HEADER COMPONENT
// ============================================================================

export interface HeaderOptions {
  /** Icon HTML (from svg-icons.ts) OR emoji string */
  icon?: string;
  /** Emoji character (preferred over icon) */
  emoji?: string;
  title: string;
  subtitle?: string;
  bookingReference?: string;
}

export function generateHeader(options: HeaderOptions): string {
  const { icon, emoji, title, subtitle, bookingReference } = options;

  // Use emoji if provided, otherwise use icon HTML, or default to clipboard emoji
  const iconContent = emoji ?
    `<table border="0" cellpadding="0" cellspacing="0" role="presentation" style="margin: 0 auto;">
      <tr><td style="font-size: 48px; line-height: 1; padding-bottom: 16px;">${emoji}</td></tr>
    </table>` :
    (icon ? `<table border="0" cellpadding="0" cellspacing="0" role="presentation" style="margin: 0 auto;">
      <tr><td style="padding-bottom: 16px;">${icon}</td></tr>
    </table>` : `<table border="0" cellpadding="0" cellspacing="0" role="presentation" style="margin: 0 auto;">
      <tr><td style="font-size: 48px; line-height: 1; padding-bottom: 16px;">📋</td></tr>
    </table>`);

  let refHtml = "";
  if (bookingReference) {
    refHtml = `
      <table border="0" cellpadding="0" cellspacing="0" role="presentation" style="margin: 0 auto; margin-top: 16px;">
        <tr>
          <td style="
            background-color: ${COLORS.cardBgSubtle};
            border: 1px solid ${COLORS.border};
            border-radius: 8px;
            padding: 8px 16px;
            text-align: center;
          ">
            <span style="font-size: 12px; color: ${COLORS.textSecondary}; display: block;">Referenca</span>
            <strong style="
              font-size: 16px;
              color: ${COLORS.textPrimary};
              font-family: monospace;
              letter-spacing: 1px;
            ">${escapeHtml(bookingReference)}</strong>
          </td>
        </tr>
      </table>
    `;
  }

  return `
    <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
      <tr>
        <td align="center" style="padding: 32px 24px;">
          ${iconContent}
          <h1 style="
            margin: 0;
            padding-bottom: 8px;
            font-size: 24px;
            font-weight: 700;
            color: ${COLORS.textPrimary};
            line-height: 1.3;
          ">${escapeHtml(title)}</h1>
          ${subtitle ? `
            <p style="
              margin: 0;
              font-size: 14px;
              color: ${COLORS.textSecondary};
              line-height: 1.5;
            ">${escapeHtml(subtitle)}</p>
          ` : ""}
          ${refHtml}
        </td>
      </tr>
    </table>
  `.trim();
}

// ============================================================================
// CARD COMPONENT
// ============================================================================

export function generateCard(title: string, content: string): string {
  return `
    <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%" style="margin-bottom: 20px;">
      <tr>
        <td style="
          background-color: ${COLORS.cardBg};
          border: 1px solid ${COLORS.border};
          border-radius: 12px;
          padding: 20px;
          box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);
        ">
          <h2 style="
            margin: 0;
            padding-bottom: 16px;
            font-size: 16px;
            font-weight: 600;
            color: ${COLORS.textPrimary};
          ">${escapeHtml(title)}</h2>
          ${content}
        </td>
      </tr>
    </table>
  `.trim();
}

// ============================================================================
// DETAILS TABLE COMPONENT
// ============================================================================

export interface DetailRow {
  label: string;
  value: string;
  highlight?: boolean;
}

export function generateDetailsTable(rows: DetailRow[]): string {
  const rowsHtml = rows.map((row) => {
    const valueStyle = row.highlight ?
      `font-size: 18px; font-weight: 700; color: ${COLORS.textPrimary};` :
      `font-size: 14px; color: ${COLORS.textPrimary};`;

    return `
      <tr>
        <td style="
          padding: 10px 0;
          padding-right: 12px;
          font-size: 14px;
          color: ${COLORS.textSecondary};
          border-bottom: 1px solid ${COLORS.borderLight};
          vertical-align: top;
          white-space: nowrap;
        ">${escapeHtml(row.label)}</td>
        <td style="
          padding: 10px 0;
          ${valueStyle}
          text-align: right;
          border-bottom: 1px solid ${COLORS.borderLight};
          vertical-align: top;
          word-break: break-word;
          overflow-wrap: break-word;
        ">${escapeHtml(row.value)}</td>
      </tr>
    `;
  }).join("");

  return `
    <table style="width: 100%; border-collapse: collapse;">
      <colgroup>
        <col style="width: 40%;">
        <col style="width: 60%;">
      </colgroup>
      ${rowsHtml}
    </table>
  `.trim();
}

// ============================================================================
// BUTTON COMPONENT
// ============================================================================

export interface ButtonOptions {
  text: string;
  url: string;
  secondary?: boolean;
}

export function generateButton(options: ButtonOptions): string {
  const { text, url, secondary } = options;

  const bgColor = secondary ? COLORS.cardBg : COLORS.buttonPrimary;
  const textColor = secondary ? COLORS.textPrimary : "#FFFFFF";
  const border = secondary ? `2px solid ${COLORS.border}` : "none";

  return `
    <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%" style="margin: 24px 0;">
      <tr>
        <td align="center">
          <a href="${escapeHtml(url)}" style="
            display: inline-block;
            background-color: ${bgColor};
            color: ${textColor};
            text-decoration: none;
            padding: 14px 32px;
            border-radius: 8px;
            font-size: 15px;
            font-weight: 600;
            border: ${border};
          ">${escapeHtml(text)}</a>
        </td>
      </tr>
    </table>
  `.trim();
}

// ============================================================================
// ALERT COMPONENT
// ============================================================================

export interface AlertOptions {
  type: "info" | "success" | "warning" | "error";
  title?: string;
  message: string;
}

export function generateAlert(options: AlertOptions): string {
  const { type, title, message } = options;

  const emojiMap = {
    info: "ℹ️",
    success: "✅",
    warning: "⚠️",
    error: "❌",
  };

  const colorMap = {
    info: { bg: COLORS.infoBg, border: COLORS.infoBorder, text: COLORS.info },
    success: { bg: COLORS.successBg, border: COLORS.successBorder, text: COLORS.success },
    warning: { bg: COLORS.warningBg, border: COLORS.warningBorder, text: COLORS.warning },
    error: { bg: COLORS.errorBg, border: COLORS.errorBorder, text: COLORS.error },
  };

  const colors = colorMap[type];
  const emoji = emojiMap[type];

  return `
    <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%" style="margin: 20px 0;">
      <tr>
        <td style="
          background-color: ${colors.bg};
          border: 1px solid ${colors.border};
          border-radius: 8px;
          padding: 16px;
        ">
          <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
            <tr>
              <td valign="top" style="font-size: 18px; padding-right: 12px; line-height: 1; width: 30px;">${emoji}</td>
              <td valign="top">
                ${title ? `
                  <strong style="
                    display: block;
                    font-size: 15px;
                    font-weight: 600;
                    color: ${colors.text};
                    padding-bottom: 6px;
                    line-height: 1.4;
                  ">${escapeHtml(title)}</strong>
                ` : ""}
                <span style="
                  font-size: 14px;
                  color: ${COLORS.textSecondary};
                  line-height: 1.6;
                  display: block;
                ">${escapeHtml(message)}</span>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  `.trim();
}

// ============================================================================
// BADGE COMPONENT
// ============================================================================

export type BadgeType = "success" | "warning" | "error" | "info" | "neutral";

export function generateBadge(text: string, type: BadgeType = "neutral"): string {
  const colorMap = {
    success: { bg: COLORS.successBg, text: COLORS.success },
    warning: { bg: COLORS.warningBg, text: COLORS.warning },
    error: { bg: COLORS.errorBg, text: COLORS.error },
    info: { bg: COLORS.infoBg, text: COLORS.info },
    neutral: { bg: COLORS.cardBgSubtle, text: COLORS.textSecondary },
  };

  const colors = colorMap[type];

  return `
    <span style="
      display: inline-block;
      background-color: ${colors.bg};
      color: ${colors.text};
      font-size: 12px;
      font-weight: 600;
      padding: 4px 10px;
      border-radius: 12px;
    ">${escapeHtml(text)}</span>
  `.trim();
}

// ============================================================================
// DIVIDER COMPONENT
// ============================================================================

export function generateDivider(): string {
  return `
    <hr style="
      border: none;
      border-top: 1px solid ${COLORS.border};
      margin: 24px 0;
    " />
  `.trim();
}

// ============================================================================
// FOOTER COMPONENT
// ============================================================================

export interface FooterOptions {
  contactEmail?: string;
  contactPhone?: string;
  additionalText?: string;
}

export function generateFooter(options: FooterOptions = {}): string {
  const { contactEmail, contactPhone, additionalText } = options;

  let contactHtml = "";
  if (contactEmail || contactPhone) {
    if (contactEmail && contactPhone) {
      contactHtml = `Imate pitanja? Kontaktirajte nas na <a href="mailto:${escapeHtml(contactEmail)}" style="color: ${COLORS.textSecondary};">${escapeHtml(contactEmail)}</a> ili na broj ${escapeHtml(contactPhone)}.`;
    } else if (contactEmail) {
      contactHtml = `Imate pitanja? Kontaktirajte nas na <a href="mailto:${escapeHtml(contactEmail)}" style="color: ${COLORS.textSecondary};">${escapeHtml(contactEmail)}</a>.`;
    } else if (contactPhone) {
      contactHtml = `Imate pitanja? Kontaktirajte nas na broj ${escapeHtml(contactPhone)}.`;
    }
  }

  const defaultText = "Ovaj email je automatski generisan. Molimo ne odgovarajte direktno na ovaj email.";

  return `
    <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%" style="border-top: 1px solid ${COLORS.border}; margin-top: 24px;">
      <tr>
        <td align="center" style="padding: 24px;">
          ${contactHtml ? `
            <p style="
              margin: 0;
              padding-bottom: 12px;
              font-size: 13px;
              color: ${COLORS.textSecondary};
              line-height: 1.5;
            ">${contactHtml}</p>
          ` : ""}
          ${additionalText ? `
            <p style="
              margin: 0;
              padding-bottom: 12px;
              font-size: 13px;
              color: ${COLORS.textSecondary};
              line-height: 1.5;
            ">${escapeHtml(additionalText)}</p>
          ` : ""}
          <p style="
            margin: 0;
            font-size: 12px;
            color: ${COLORS.textMuted};
            line-height: 1.5;
          ">${defaultText}</p>
        </td>
      </tr>
    </table>
  `.trim();
}

// ============================================================================
// GREETING & INTRO
// ============================================================================

export function generateGreeting(guestName: string): string {
  return `
    <p class="greeting" style="
      margin: 0 0 12px 0;
      font-size: 16px;
      color: ${COLORS.textPrimary};
      line-height: 1.5;
    ">Poštovani/a <strong>${escapeHtml(guestName)}</strong>,</p>
  `.trim();
}

export function generateIntro(text: string): string {
  return `
    <p class="intro" style="
      margin: 0 0 24px 0;
      font-size: 15px;
      color: ${COLORS.textSecondary};
      line-height: 1.6;
    ">${escapeHtml(text)}</p>
  `.trim();
}

/**
 * Generate paragraph with consistent spacing
 */
export function generateParagraph(text: string, options?: { marginBottom?: string }): string {
  const marginBottom = options?.marginBottom || "16px";
  return `
    <p class="paragraph" style="
      margin: 0 0 ${marginBottom} 0;
      font-size: 15px;
      color: ${COLORS.textPrimary};
      line-height: 1.6;
    ">${escapeHtml(text)}</p>
  `.trim();
}

/**
 * Generate vertical spacer for better section separation
 */
export function generateSpacer(height: "small" | "medium" | "large" = "medium"): string {
  const heightMap = {
    small: "12px",
    medium: "20px",
    large: "32px",
  };
  return `<div style="height: ${heightMap[height]};"></div>`;
}

// ============================================================================
// BOOKING DETAILS CARD
// ============================================================================

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
    { label: "Nekretnina", value: details.propertyName },
    { label: "Jedinica", value: details.unitName },
    { label: "Prijava", value: formatDate(details.checkIn) },
    { label: "Odjava", value: formatDate(details.checkOut) },
    { label: "Broj noćenja", value: `${nights} ${nights === 1 ? "noć" : "noći"}` },
    { label: "Broj gostiju", value: details.guests.toString() },
  ];

  return generateCard("📅 Detalji rezervacije", generateDetailsTable(rows));
}

// ============================================================================
// PAYMENT DETAILS CARD
// ============================================================================

export interface PaymentDetails {
  totalAmount: number;
  depositAmount?: number;
  remainingAmount?: number;
  paymentMethod?: string;
}

export function generatePaymentDetailsCard(details: PaymentDetails): string {
  const rows: DetailRow[] = [];

  if (details.depositAmount !== undefined && details.depositAmount > 0) {
    rows.push({ label: "Avans", value: formatCurrency(details.depositAmount) });
  }

  if (details.remainingAmount !== undefined && details.remainingAmount > 0) {
    rows.push({ label: "Preostalo za platiti", value: formatCurrency(details.remainingAmount) });
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
    rows.push({ label: "Način plaćanja", value: methodText });
  }

  return generateCard("💳 Detalji plaćanja", generateDetailsTable(rows));
}

// ============================================================================
// EMAIL WRAPPER
// ============================================================================

export function wrapEmailContent(content: string): string {
  return `
    <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%" style="
      background-color: ${COLORS.pageBg};
      min-height: 100%;
    ">
      <tr>
        <td align="center" style="padding: 4px;">
          <table border="0" cellpadding="0" cellspacing="0" role="presentation" style="
            max-width: 560px;
            width: 100%;
            background-color: ${COLORS.cardBg};
            border-radius: 12px;
            border: 1px solid ${COLORS.border};
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);
          ">
            <tr>
              <td style="word-wrap: break-word; overflow-wrap: break-word;">
                ${content}
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  `.trim();
}

// ============================================================================
// BANK TRANSFER DETAILS (for payment confirmation emails)
// ============================================================================

export interface BankDetails {
  bankName?: string;
  accountHolder?: string;
  iban?: string;
  swift?: string;
  reference: string;
  amount: number;
}

export function generateBankTransferCard(details: BankDetails): string {
  const rows: DetailRow[] = [];

  if (details.bankName) {
    rows.push({ label: "Banka", value: details.bankName });
  }
  if (details.accountHolder) {
    rows.push({ label: "Primatelj", value: details.accountHolder });
  }
  if (details.iban) {
    rows.push({ label: "IBAN", value: details.iban });
  }
  if (details.swift) {
    rows.push({ label: "SWIFT/BIC", value: details.swift });
  }
  rows.push({ label: "Poziv na broj", value: details.reference, highlight: true });
  rows.push({ label: "Iznos", value: formatCurrency(details.amount), highlight: true });

  return generateCard("🏦 Podaci za uplatu", generateDetailsTable(rows));
}

// ============================================================================
// INFO BOX (lighter version of alert)
// ============================================================================

export function generateInfoBox(text: string): string {
  return `
    <div style="
      background-color: ${COLORS.cardBgSubtle};
      border-radius: 8px;
      padding: 16px;
      margin: 16px 0;
    ">
      <p style="
        margin: 0;
        font-size: 13px;
        color: ${COLORS.textSecondary};
        line-height: 1.5;
      ">💡 ${escapeHtml(text)}</p>
    </div>
  `.trim();
}

// ============================================================================
// LIST COMPONENT
// ============================================================================

export function generateList(items: string[]): string {
  const itemsHtml = items.map((item) => `
    <li style="
      margin-bottom: 8px;
      font-size: 14px;
      color: ${COLORS.textPrimary};
      line-height: 1.5;
    ">${escapeHtml(item)}</li>
  `).join("");

  return `
    <ul style="
      margin: 16px 0;
      padding-left: 24px;
    ">
      ${itemsHtml}
    </ul>
  `.trim();
}
