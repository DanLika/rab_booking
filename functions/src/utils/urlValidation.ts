// Allowed domains for return URL (security whitelist)
// DOMAIN STRUCTURE:
// - bookbed.io = Marketing/Landing page (NOT for widget)
// - app.bookbed.io = Owner Dashboard
// - view.bookbed.io = Booking Widget (main domain)
// - *.view.bookbed.io = Client subdomains (e.g., jasko-rab.view.bookbed.io)
const ALLOWED_RETURN_DOMAINS = [
  "https://bookbed.io",           // Marketing site (for future use)
  "https://app.bookbed.io",       // Owner dashboard
  "https://view.bookbed.io",      // Booking widget (main domain)
  "http://localhost",             // Local development
  "http://127.0.0.1",             // Local development
];

// Allowed wildcard domains for custom client subdomains
// Widget uses view.bookbed.io subdomain structure: {client}.view.bookbed.io
const ALLOWED_WILDCARD_DOMAINS = [
  ".view.bookbed.io", // Client subdomains (e.g., jasko-rab.view.bookbed.io, villa-marija.view.bookbed.io)
];

/**
 * Validates if a return URL is allowed based on whitelist and wildcard rules
 * @param returnUrl - The full return URL to validate
 * @returns true if URL is allowed, false otherwise
 *
 * SECURITY: Uses split-based validation to prevent attacks like "evil-bookbed.io"
 * which would pass endsWith() check but should be blocked
 */
export function isAllowedReturnUrl(returnUrl: string): boolean {
  // Check exact domain matches first
  const exactMatch = ALLOWED_RETURN_DOMAINS.some((domain) =>
    returnUrl.startsWith(domain)
  );

  if (exactMatch) return true;

  // Check wildcard domain matches (e.g., *.view.bookbed.io)
  try {
    const url = new URL(returnUrl);
    const hostname = url.hostname; // e.g., "jasko-rab.view.bookbed.io"

    return ALLOWED_WILDCARD_DOMAINS.some((wildcardDomain) => {
      // FIXED BUG #17: Secure wildcard validation using domain split
      // wildcardDomain = ".view.bookbed.io" → domainWithoutDot = "view.bookbed.io"
      const domainWithoutDot = wildcardDomain.slice(1); // Remove leading dot

      // Split both into parts
      const hostnameParts = hostname.split("."); // ["jasko-rab", "view", "bookbed", "io"]
      const wildcardParts = domainWithoutDot.split("."); // ["view", "bookbed", "io"]

      // SECURITY: Hostname must have MORE parts than wildcard domain
      // This blocks: "evil-view.bookbed.io" (3 parts) vs "view.bookbed.io" (3 parts)
      // This allows: "jasko-rab.view.bookbed.io" (4 parts) vs "view.bookbed.io" (3 parts)
      if (hostnameParts.length <= wildcardParts.length) {
        return false;
      }

      // Check if last N parts of hostname match wildcard domain
      // ["jasko-rab", "view", "bookbed", "io"] → last 3 parts: ["view", "bookbed", "io"]
      const lastParts = hostnameParts.slice(-wildcardParts.length);
      const matches = lastParts.join(".") === domainWithoutDot;

      return matches;
    });
  } catch {
    return false;
  }
}
