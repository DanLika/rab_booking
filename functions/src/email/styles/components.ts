/**
 * Email Component Styles - Minimalist Design
 *
 * Reusable component styles for cards, buttons, tables, alerts, etc.
 * All styles use inline CSS for maximum email client compatibility.
 * Minimalist design: simple colors, no shadows, reduced padding and font sizes.
 */

import {EMAIL_COLORS_LIGHT, EMAIL_COLORS_DARK} from "./colors";

/**
 * Generate component CSS styles with dark mode support
 */
export function getComponentStyles(): string {
  const light = EMAIL_COLORS_LIGHT;
  const dark = EMAIL_COLORS_DARK;

  return `
    <style>
      /* ==========================================
         CARD COMPONENT
         Simple card with border
         ========================================== */

      .card {
        background-color: ${light.backgroundSecondary};
        border: 1px solid ${light.border};
        border-radius: 0;
        padding: 16px;
        margin-bottom: 16px;
      }

      .card h2 {
        font-size: 16px;
        font-weight: 600;
        color: ${light.text};
        margin: 0 0 12px 0;
      }

      .card:last-child {
        margin-bottom: 0;
      }

      /* ==========================================
         DETAILS TABLE
         Table-based layout for label-value pairs (best email support)
         ========================================== */

      .details-table {
        width: 100%;
        border-collapse: collapse;
      }

      .details-table tr {
        border-bottom: 1px solid ${light.border};
      }

      .details-table tr:last-child {
        border-bottom: none;
      }

      .details-table td {
        padding: 12px 0;
        vertical-align: top;
      }

      .details-table .label {
        font-size: 14px;
        font-weight: 500;
        color: ${light.textSecondary};
        width: 40%;
        padding-right: 16px;
      }

      .details-table .value {
        font-size: 14px;
        font-weight: 400;
        color: ${light.text};
        text-align: right;
      }

      .details-table .value-highlight {
        font-size: 16px;
        font-weight: 600;
        color: ${light.primary};
      }

      /* ==========================================
         BUTTON COMPONENT
         Primary action button with hover effect
         ========================================== */

      .button-container {
        text-align: center;
        margin: 24px 0;
      }

      .button {
        display: inline-block;
        background-color: ${light.primary};
        color: #FFFFFF !important;
        font-size: 14px;
        font-weight: 600;
        text-decoration: none;
        padding: 12px 24px;
        border-radius: 4px;
      }

      .button:hover {
        background-color: ${light.primaryDark};
      }

      .button-secondary {
        background-color: ${light.backgroundSecondary};
        color: ${light.text} !important;
        border: 1px solid ${light.border};
      }

      .button-secondary:hover {
        background-color: ${light.border};
      }

      /* ==========================================
         ALERT COMPONENTS
         Info, warning, error, success messages
         ========================================== */

      .alert {
        padding: 12px;
        border-radius: 0;
        margin-bottom: 16px;
        font-size: 13px;
        line-height: 1.5;
      }

      .alert-info {
        background-color: rgba(59, 130, 246, 0.1);
        border-left: 4px solid ${light.info};
        color: #1E40AF;
      }

      .alert-success {
        background-color: rgba(16, 185, 129, 0.1);
        border-left: 4px solid ${light.success};
        color: #065F46;
      }

      .alert-warning {
        background-color: rgba(245, 158, 11, 0.1);
        border-left: 4px solid ${light.warning};
        color: #92400E;
      }

      .alert-error {
        background-color: rgba(239, 68, 68, 0.1);
        border-left: 4px solid ${light.error};
        color: #991B1B;
      }

      .alert strong {
        display: block;
        font-weight: 600;
        margin-bottom: 4px;
      }

      /* ==========================================
         DIVIDER
         ========================================== */

      .divider {
        height: 1px;
        background-color: ${light.border};
        margin: 16px 0;
        border: none;
      }

      /* ==========================================
         BADGE COMPONENT
         Small colored badge for status/labels
         ========================================== */

      .badge {
        display: inline-block;
        padding: 4px 8px;
        border-radius: 0;
        font-size: 11px;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.5px;
      }

      .badge-success {
        background-color: ${light.success};
        color: #FFFFFF;
      }

      .badge-warning {
        background-color: ${light.warning};
        color: #FFFFFF;
      }

      .badge-error {
        background-color: ${light.error};
        color: #FFFFFF;
      }

      .badge-info {
        background-color: ${light.info};
        color: #FFFFFF;
      }

      .badge-neutral {
        background-color: ${light.border};
        color: ${light.text};
      }

      /* ==========================================
         LIST STYLES
         ========================================== */

      .list {
        list-style: none;
        padding: 0;
        margin: 0;
      }

      .list-item {
        padding: 12px 0;
        border-bottom: 1px solid ${light.border};
        display: flex;
        align-items: center;
      }

      .list-item:last-child {
        border-bottom: none;
      }

      .list-item-icon {
        width: 24px;
        height: 24px;
        margin-right: 12px;
        flex-shrink: 0;
      }

      /* ==========================================
         DARK MODE OVERRIDES
         ========================================== */

      @media (prefers-color-scheme: dark) {
        .card {
          background-color: ${dark.backgroundSecondary} !important;
          border-color: ${dark.border} !important;
        }

        .card h2 {
          color: ${dark.text} !important;
        }

        .details-table tr {
          border-bottom-color: ${dark.border} !important;
        }

        .details-table .label {
          color: ${dark.textSecondary} !important;
        }

        .details-table .value {
          color: ${dark.text} !important;
        }

        .details-table .value-highlight {
          color: ${dark.primary} !important;
        }

        .button {
          background-color: ${dark.primary} !important;
        }

        .button:hover {
          background-color: ${dark.primaryDark} !important;
        }

        .button-secondary {
          background-color: ${dark.backgroundSecondary} !important;
          color: ${dark.text} !important;
          border-color: ${dark.border} !important;
        }

        .button-secondary:hover {
          background-color: ${dark.border} !important;
        }

        .alert-info {
          background-color: rgba(96, 165, 250, 0.15) !important;
          border-left-color: ${dark.info} !important;
          color: #BFDBFE !important;
        }

        .alert-success {
          background-color: rgba(52, 211, 153, 0.15) !important;
          border-left-color: ${dark.success} !important;
          color: #A7F3D0 !important;
        }

        .alert-warning {
          background-color: rgba(251, 191, 36, 0.15) !important;
          border-left-color: ${dark.warning} !important;
          color: #FDE68A !important;
        }

        .alert-error {
          background-color: rgba(248, 113, 113, 0.15) !important;
          border-left-color: ${dark.error} !important;
          color: #FECACA !important;
        }

        .divider {
          background-color: ${dark.border} !important;
        }

        .badge-neutral {
          background-color: ${dark.border} !important;
          color: ${dark.text} !important;
        }

        .list-item {
          border-bottom-color: ${dark.border} !important;
        }
      }

      /* ==========================================
         RESPONSIVE DESIGN
         Better mobile spacing - 16px minimum padding
         ========================================== */

      @media only screen and (max-width: 600px) {
        /* Content wrapper - reduce horizontal padding on mobile */
        .content-wrapper {
          padding: 0 16px 20px 16px !important;
        }

        /* Cards - better mobile spacing */
        .card {
          padding: 16px !important;  /* Increased from 12px for better mobile UX */
          margin-bottom: 16px !important;
        }

        /* Details table - improved readability */
        .details-table .label {
          font-size: 13px !important;  /* Increased from 12px for readability */
        }

        .details-table .value {
          font-size: 14px !important;  /* Increased from 13px for readability */
        }

        .details-table td {
          padding: 10px 0 !important;  /* Reduced from 12px to save vertical space */
        }

        /* Buttons - more touchable on mobile */
        .button {
          padding: 12px 24px !important;  /* Increased from 10px 20px */
          font-size: 14px !important;  /* Increased from 13px */
        }

        .button-container {
          margin: 20px 0 !important;  /* Reduced from 24px to save vertical space */
        }

        /* Alerts - better mobile spacing */
        .alert {
          padding: 14px !important;  /* Increased from 12px */
          margin: 16px 0 !important;
        }

        /* Typography - adjust for mobile screens */
        .greeting,
        .intro,
        .paragraph {
          font-size: 14px !important;
        }
      }
    </style>
  `;
}
