/**
 * Base Email Styles - Minimalist Design
 *
 * Core CSS styles that work across all email clients.
 * Uses inline styles for maximum compatibility.
 * Includes responsive design with media queries.
 * Minimalist design: simple colors, no gradients, no shadows, reduced padding.
 */

import {EMAIL_COLORS_LIGHT, EMAIL_COLORS_DARK} from "./colors";

/**
 * Generate base CSS styles with both light and dark theme support
 *
 * IMPORTANT: All styles are inlined for email client compatibility.
 * Avoid: flexbox, grid, transform, transition (poor email support)
 * Use: tables, inline-block, absolute positioning
 */
export function getBaseStyles(): string {
  const light = EMAIL_COLORS_LIGHT;
  const dark = EMAIL_COLORS_DARK;

  return `
    <style>
      /* ==========================================
         RESET & BASE STYLES
         ========================================== */

      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }

      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
        font-size: 16px;
        line-height: 1.6;
        color: ${light.text};
        background-color: ${light.backgroundSecondary};
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
      }

      table {
        border-collapse: collapse;
        border-spacing: 0;
        width: 100%;
      }

      img {
        border: 0;
        outline: none;
        text-decoration: none;
        -ms-interpolation-mode: bicubic;
      }

      a {
        text-decoration: none;
      }

      /* ==========================================
         WRAPPER & CONTAINER
         ========================================== */

      .email-wrapper {
        width: 100%;
        max-width: 600px;
        margin: 0 auto;
        background-color: ${light.background};
        border-radius: 0;
        overflow: hidden;
      }

      .email-container {
        width: 100%;
        background-color: ${light.background};
      }

      /* ==========================================
         HEADER
         ========================================== */

      .header {
        background-color: ${light.primary};
        color: #FFFFFF;
        padding: 20px 24px;
        text-align: center;
      }

      .header-icon {
        width: 48px;
        height: 48px;
        margin: 0 auto 12px;
        display: block;
      }

      .header h1 {
        font-size: 20px;
        font-weight: 600;
        margin: 0 0 8px 0;
        color: #FFFFFF;
      }

      .header-subtitle {
        font-size: 14px;
        font-weight: 400;
        opacity: 0.9;
        margin: 0;
      }

      .booking-ref {
        display: inline-block;
        background-color: rgba(255, 255, 255, 0.2);
        padding: 6px 12px;
        border-radius: 4px;
        margin-top: 12px;
      }

      .booking-ref span {
        display: block;
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        opacity: 0.8;
        margin-bottom: 4px;
      }

      .booking-ref strong {
        display: block;
        font-size: 16px;
        font-weight: 600;
        letter-spacing: 0.5px;
      }

      /* ==========================================
         CONTENT AREA
         ========================================== */

      .content {
        padding: 20px 24px;
      }

      .greeting {
        font-size: 16px;
        font-weight: 400;
        color: ${light.text};
        margin: 0 0 8px 0;
      }

      .intro {
        font-size: 16px;
        line-height: 1.6;
        color: ${light.textSecondary};
        margin: 0 0 24px 0;
      }

      /* ==========================================
         TYPOGRAPHY
         ========================================== */

      h2 {
        font-size: 16px;
        font-weight: 600;
        color: ${light.text};
        margin: 0 0 12px 0;
      }

      p {
        font-size: 16px;
        line-height: 1.6;
        color: ${light.text};
        margin: 0 0 16px 0;
      }

      .text-secondary {
        color: ${light.textSecondary};
      }

      .text-small {
        font-size: 14px;
      }

      /* ==========================================
         SPACING UTILITIES
         ========================================== */

      .mb-8 { margin-bottom: 8px !important; }
      .mb-16 { margin-bottom: 16px !important; }
      .mb-24 { margin-bottom: 24px !important; }
      .mb-32 { margin-bottom: 32px !important; }

      .mt-16 { margin-top: 16px !important; }
      .mt-24 { margin-top: 24px !important; }
      .mt-32 { margin-top: 32px !important; }

      /* ==========================================
         FOOTER
         ========================================== */

      .footer {
        padding: 16px 24px;
        text-align: center;
        background-color: ${light.backgroundSecondary};
        border-top: 1px solid ${light.border};
      }

      .footer p {
        font-size: 13px;
        color: ${light.textSecondary};
        margin: 0 0 8px 0;
      }

      .footer a {
        color: ${light.primary};
        text-decoration: underline;
      }

      /* ==========================================
         RESPONSIVE DESIGN
         ========================================== */

      @media only screen and (max-width: 600px) {
        .email-wrapper {
          border-radius: 0 !important;
        }

        .header {
          padding: 16px !important;
        }

        .header h1 {
          font-size: 18px !important;
        }

        .content {
          padding: 16px !important;
        }

        h2 {
          font-size: 15px !important;
        }

        .footer {
          padding: 12px 16px !important;
        }
      }

      /* ==========================================
         DARK MODE SUPPORT
         Applies only in email clients that support prefers-color-scheme
         ========================================== */

      @media (prefers-color-scheme: dark) {
        body {
          background-color: ${dark.backgroundSecondary} !important;
          color: ${dark.text} !important;
        }

        .email-wrapper {
          background-color: ${dark.background} !important;
        }

        .email-container {
          background-color: ${dark.background} !important;
        }

        .header {
          background-color: ${dark.primary} !important;
        }

        .content {
          background-color: ${dark.background} !important;
        }

        .greeting,
        h2,
        p {
          color: ${dark.text} !important;
        }

        .intro,
        .text-secondary {
          color: ${dark.textSecondary} !important;
        }

        .footer {
          background-color: ${dark.backgroundSecondary} !important;
          border-top-color: ${dark.border} !important;
        }

        .footer p {
          color: ${dark.textSecondary} !important;
        }

        .footer a {
          color: ${dark.primary} !important;
        }
      }
    </style>
  `;
}

/**
 * Get base HTML structure
 * Wraps all email content with proper DOCTYPE and meta tags
 */
export function getBaseHtmlWrapper(content: string): string {
  return `
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="color-scheme" content="light dark" />
  <meta name="supported-color-schemes" content="light dark" />
  ${getBaseStyles()}
</head>
<body>
  ${content}
</body>
</html>
  `.trim();
}
