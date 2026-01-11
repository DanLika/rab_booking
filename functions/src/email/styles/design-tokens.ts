/**
 * Email Design Tokens
 *
 * Defines spacing, typography, shadows, and layout specs for email templates.
 * Two variants:
 * - PREMIUM: Ultra premium (Airbnb/Apple style) - for main guest confirmations
 * - REFINED: Refined premium (balanced) - for pending/notification emails
 */

export interface DesignTokens {
  // Spacing
  spacing: {
    cardPadding: string;
    sectionGap: string;
    buttonPadding: string;
  };

  // Border radius
  radius: {
    card: string;
    button: string;
  };

  // Typography
  typography: {
    heading: {
      fontSize: string;
      fontWeight: string;
      lineHeight: string;
    };
    body: {
      fontSize: string;
      fontWeight: string;
      lineHeight: string;
    };
    price: {
      fontSize: string;
      fontWeight: string;
      lineHeight: string;
    };
    small: {
      fontSize: string;
      fontWeight: string;
      lineHeight: string;
    };
  };

  // Shadows
  shadows: {
    card: string;
    button: string;
    buttonHover: string;
  };

  // Layout
  layout: {
    maxWidth: string;
    cardStyle: "separated" | "bordered" | "flat";
  };
}

/**
 * OPCIJA B: Ultra Premium Design Tokens
 *
 * Use for:
 * - sendBookingConfirmationEmail
 * - sendBookingApprovedEmail
 * - High-importance guest communications
 */
export const DESIGN_TOKENS_PREMIUM: DesignTokens = {
  spacing: {
    cardPadding: "32px",
    sectionGap: "16px",
    buttonPadding: "16px 32px",
  },

  radius: {
    card: "14px",
    button: "8px",
  },

  typography: {
    heading: {
      fontSize: "24px",
      fontWeight: "700",
      lineHeight: "1.3",
    },
    body: {
      fontSize: "16px",
      fontWeight: "400",
      lineHeight: "1.6",
    },
    price: {
      fontSize: "18px",
      fontWeight: "700",
      lineHeight: "1.4",
    },
    small: {
      fontSize: "14px",
      fontWeight: "400",
      lineHeight: "1.5",
    },
  },

  shadows: {
    card: "0 2px 4px rgba(0, 0, 0, 0.08)",
    button: "0 3px 6px rgba(0, 0, 0, 0.12)",
    buttonHover: "0 6px 12px rgba(0, 0, 0, 0.18)",
  },

  layout: {
    maxWidth: "600px",
    cardStyle: "separated",
  },
};

/**
 * OPCIJA A: Refined Premium Design Tokens
 *
 * Use for:
 * - sendPendingBookingRequestEmail
 * - sendPendingBookingOwnerNotification
 * - sendGuestCancellationEmail
 * - Secondary/notification emails
 */
export const DESIGN_TOKENS_REFINED: DesignTokens = {
  spacing: {
    cardPadding: "28px",
    sectionGap: "16px",
    buttonPadding: "14px 28px",
  },

  radius: {
    card: "12px",
    button: "8px",
  },

  typography: {
    heading: {
      fontSize: "22px",
      fontWeight: "600",
      lineHeight: "1.3",
    },
    body: {
      fontSize: "15px",
      fontWeight: "400",
      lineHeight: "1.6",
    },
    price: {
      fontSize: "16px",
      fontWeight: "600",
      lineHeight: "1.4",
    },
    small: {
      fontSize: "14px",
      fontWeight: "400",
      lineHeight: "1.5",
    },
  },

  shadows: {
    card: "0 1px 2px rgba(0, 0, 0, 0.06)",
    button: "0 2px 4px rgba(0, 0, 0, 0.08)",
    buttonHover: "0 4px 8px rgba(0, 0, 0, 0.12)",
  },

  layout: {
    maxWidth: "600px",
    cardStyle: "separated",
  },
};

/**
 * Get design tokens by variant
 */
export function getDesignTokens(variant: "premium" | "refined" = "refined"): DesignTokens {
  return variant === "premium" ? DESIGN_TOKENS_PREMIUM : DESIGN_TOKENS_REFINED;
}

/**
 * Generate inline styles for card
 */
export function getCardStyles(tokens: DesignTokens, backgroundColor = "#FFFFFF"): string {
  return `
    background-color: ${backgroundColor};
    border-radius: ${tokens.radius.card};
    padding: ${tokens.spacing.cardPadding};
    box-shadow: ${tokens.shadows.card};
    margin-bottom: ${tokens.spacing.sectionGap};
  `.trim();
}

/**
 * Generate inline styles for button
 */
export function getButtonStyles(
  tokens: DesignTokens,
  backgroundColor = "#374151",
  textColor = "#FFFFFF"
): string {
  return `
    display: inline-block;
    background-color: ${backgroundColor};
    color: ${textColor};
    text-decoration: none;
    padding: ${tokens.spacing.buttonPadding};
    border-radius: ${tokens.radius.button};
    box-shadow: ${tokens.shadows.button};
    font-size: ${tokens.typography.body.fontSize};
    font-weight: 600;
    text-align: center;
  `.trim();
}

/**
 * Generate typography styles
 */
export function getTypographyStyles(
  tokens: DesignTokens,
  type: "heading" | "body" | "price" | "small",
  color = "#111827"
): string {
  const styles = tokens.typography[type];
  return `
    font-size: ${styles.fontSize};
    font-weight: ${styles.fontWeight};
    line-height: ${styles.lineHeight};
    color: ${color};
    margin: 0;
  `.trim();
}
