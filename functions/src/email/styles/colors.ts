/**
 * Email Color Palette - 2025 Modern Design
 *
 * Supports both light and dark themes via CSS prefers-color-scheme.
 * Matches Flutter widget design tokens for brand consistency.
 */

export interface EmailColorScheme {
  // Primary brand colors
  primary: string;
  primaryLight: string;
  primaryDark: string;

  // Neutral colors
  background: string;
  backgroundSecondary: string;
  text: string;
  textSecondary: string;
  border: string;

  // Status colors
  success: string;
  warning: string;
  error: string;
  info: string;

  // Card shadows
  shadowColor: string;
  shadowOpacity: string;
}

/**
 * Light Theme Colors (Default)
 * Used by all email clients, optimized for readability
 */
export const EMAIL_COLORS_LIGHT: EmailColorScheme = {
  // Primary - Purple gradient
  primary: "#6B4CE6",           // Main purple (matches widget)
  primaryLight: "#F5F3FF",      // Light purple background
  primaryDark: "#5B3CD6",       // Darker purple for hover

  // Neutral palette
  background: "#FFFFFF",
  backgroundSecondary: "#F8F9FA",  // Matches widget light theme
  text: "#111827",              // Near black for high contrast
  textSecondary: "#6B7280",     // Medium gray
  border: "#E5E7EB",            // Light gray border

  // Status colors
  success: "#10B981",           // Green
  warning: "#F59E0B",           // Amber
  error: "#EF4444",             // Red
  info: "#3B82F6",              // Blue

  // Shadows
  shadowColor: "0, 0, 0",       // RGB for rgba()
  shadowOpacity: "0.1",         // 10% opacity
};

/**
 * Dark Theme Colors (Enhancement)
 * Only applied in email clients that support prefers-color-scheme: dark
 * Falls back to light theme in older clients
 */
export const EMAIL_COLORS_DARK: EmailColorScheme = {
  // Primary - Lighter purple for dark backgrounds
  primary: "#8B5CF6",           // Lighter purple
  primaryLight: "#2D1B4E",      // Dark purple background
  primaryDark: "#A78BFA",       // Even lighter for hover

  // Neutral palette - matches widget dark theme
  background: "#1A1A1A",        // Very dark gray (matches widget)
  backgroundSecondary: "#2D2D2D", // Medium dark gray (matches widget)
  text: "#F1F5F9",              // slate100 (matches widget)
  textSecondary: "#94A3B8",     // slate400
  border: "#374151",            // Dark border

  // Status colors - brighter for dark background
  success: "#34D399",           // Lighter green
  warning: "#FBBF24",           // Lighter amber
  error: "#F87171",             // Lighter red
  info: "#60A5FA",              // Lighter blue

  // Shadows
  shadowColor: "255, 255, 255", // White shadow for dark mode
  shadowOpacity: "0.05",        // 5% opacity (subtler)
};

/**
 * Neutral Theme Colors (White-Label for Guest Emails)
 * Used for guest-facing emails to maintain white-label experience
 * No brand colors - professional gray palette
 */
export const EMAIL_COLORS_NEUTRAL: EmailColorScheme = {
  // Primary - Dark gray (no brand purple)
  primary: "#374151",           // Medium dark gray
  primaryLight: "#F9FAFB",      // Very light gray
  primaryDark: "#1F2937",       // Darker gray

  // Neutral palette
  background: "#FFFFFF",
  backgroundSecondary: "#F9FAFB",
  text: "#1F2937",              // Soft black (not pure black)
  textSecondary: "#6B7280",     // Medium gray
  border: "#E5E7EB",            // Light gray border

  // Status colors - professional tones
  success: "#059669",           // Professional green
  warning: "#D97706",           // Amber/orange
  error: "#DC2626",             // Professional red
  info: "#2563EB",              // Professional blue

  // Shadows
  shadowColor: "0, 0, 0",       // RGB for rgba()
  shadowOpacity: "0.08",        // Subtle 8% opacity
};

/**
 * Get color scheme by recipient type
 */
export function getEmailColors(recipient: 'guest' | 'owner'): EmailColorScheme {
  return recipient === 'guest' ? EMAIL_COLORS_NEUTRAL : EMAIL_COLORS_LIGHT;
}

/**
 * Get CSS variable declarations for a color scheme
 * Used in inline styles for email compatibility
 */
export function getColorVariables(theme: EmailColorScheme): string {
  return `
    --color-primary: ${theme.primary};
    --color-primary-light: ${theme.primaryLight};
    --color-primary-dark: ${theme.primaryDark};
    --color-bg: ${theme.background};
    --color-bg-secondary: ${theme.backgroundSecondary};
    --color-text: ${theme.text};
    --color-text-secondary: ${theme.textSecondary};
    --color-border: ${theme.border};
    --color-success: ${theme.success};
    --color-warning: ${theme.warning};
    --color-error: ${theme.error};
    --color-info: ${theme.info};
    --shadow-color: ${theme.shadowColor};
    --shadow-opacity: ${theme.shadowOpacity};
  `.trim();
}

/**
 * Legacy color constants for backward compatibility
 * TODO: Remove after migration is complete
 */
export const LEGACY_COLORS = {
  primary: "#6B4CE6",
  primaryLight: "#F5F3FF",
  success: "#10B981",
  successLight: "#D1FAE5",
  warning: "#F59E0B",
  warningLight: "#FEF3C7",
  error: "#EF4444",
  errorLight: "#FEE2E2",
  background: "#FFFFFF",
  textPrimary: "#111827",
  textSecondary: "#6B7280",
  border: "#E5E7EB",
  borderLight: "#F3F4F6",
};
