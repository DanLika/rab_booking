/**
 * Base Email Styles - Minimal Wrapper
 *
 * Since all components now use inline styles for Gmail compatibility,
 * this file only provides the basic HTML wrapper and reset styles.
 */

/**
 * Generate minimal base CSS for email resets
 * Most styling is done inline in template-helpers.ts
 */
export function getBaseStyles(): string {
  return `
    <style>
      /* Minimal reset - all real styling is inline */
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }

      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
        font-size: 16px;
        line-height: 1.6;
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
      }

      table {
        border-collapse: collapse;
        border-spacing: 0;
      }

      img {
        border: 0;
        outline: none;
        text-decoration: none;
      }

      a {
        text-decoration: none;
      }

      /* Responsive: reduce padding on mobile */
      @media only screen and (max-width: 600px) {
        .email-wrapper {
          padding: 16px 12px !important;
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
  <meta name="color-scheme" content="light" />
  <meta name="supported-color-schemes" content="light" />
  ${getBaseStyles()}
</head>
<body style="margin: 0; padding: 0; background-color: #F9FAFB;">
  ${content}
</body>
</html>
  `.trim();
}
