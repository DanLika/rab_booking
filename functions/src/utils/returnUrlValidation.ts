/**
 * Return URL allowlist validation for Stripe redirect surfaces.
 *
 * Extracted from stripePayment.ts (F-NEW-02) so that every Stripe call
 * that takes a client-controlled return URL — booking checkout, subscription
 * checkout, billing portal, Connect onboarding — runs the same validator.
 *
 * SECURITY model:
 * - Exact domain prefix match against an allowlist
 * - Per-env additions (bookbed-dev / bookbed-staging Hosting domains) appended
 *   at request time from GCP_PROJECT so the prod list stays minimal
 * - Wildcard subdomain match (`*.view.bookbed.io`) using split-based parts
 *   comparison — blocks "evil-view.bookbed.io" (3 parts) but allows
 *   "jasko-rab.view.bookbed.io" (4 parts).
 */

const BASE_ALLOWED_DOMAINS = [
  "https://bookbed.io", // Marketing site
  "https://app.bookbed.io", // Owner dashboard
  "https://view.bookbed.io", // Booking widget main
  "http://localhost", // Local dev
  "http://127.0.0.1", // Local dev
];

const ALLOWED_WILDCARD_DOMAINS = [
  ".view.bookbed.io", // Client subdomains (e.g., jasko-rab.view.bookbed.io)
];

export function getAllowedReturnDomains(): string[] {
  const base = [...BASE_ALLOWED_DOMAINS];
  const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
  if (projectId === "bookbed-dev" || process.env.FUNCTIONS_EMULATOR === "true") {
    base.push("https://bookbed-widget-dev.web.app");
    base.push("https://bookbed-owner-dev.web.app");
  }
  if (projectId === "bookbed-staging") {
    base.push("https://bookbed-widget-staging.web.app");
    base.push("https://bookbed-owner-staging.web.app");
  }
  return base;
}

/**
 * Validate a return URL against the allowlist.
 *
 * Returns true if URL matches any allowed prefix OR any allowed wildcard
 * subdomain. Returns false on malformed URLs (URL constructor throws).
 *
 * @param returnUrl Full URL string from client
 */
export function isAllowedReturnUrl(returnUrl: string): boolean {
  if (!returnUrl || typeof returnUrl !== "string") return false;

  // Exact-prefix match first
  const allowedDomains = getAllowedReturnDomains();
  if (allowedDomains.some((domain) => returnUrl.startsWith(domain))) {
    return true;
  }

  // Wildcard match (split-based; blocks "evil-view.bookbed.io")
  try {
    const url = new URL(returnUrl);
    const hostname = url.hostname;
    return ALLOWED_WILDCARD_DOMAINS.some((wildcardDomain) => {
      const domainWithoutDot = wildcardDomain.slice(1); // ".view.bookbed.io" -> "view.bookbed.io"
      const hostnameParts = hostname.split(".");
      const wildcardParts = domainWithoutDot.split(".");
      // Hostname must have MORE parts than wildcard domain.
      if (hostnameParts.length <= wildcardParts.length) {
        return false;
      }
      const lastParts = hostnameParts.slice(-wildcardParts.length);
      return lastParts.join(".") === domainWithoutDot;
    });
  } catch {
    return false;
  }
}

/**
 * Convenience: throw HttpsError("invalid-argument", ...) when URL is not allowed.
 *
 * Callers in Stripe CFs do this same dance repeatedly; this hoists it.
 *
 * Note: `field` is included in the thrown message so end-users see *which*
 * URL was rejected when a CF takes multiple (e.g. Stripe Connect's
 * return_url + refresh_url).
 */
export function assertAllowedReturnUrl(
  returnUrl: string,
  field: string,
  HttpsError: new (code: string, message: string) => Error
): void {
  if (!isAllowedReturnUrl(returnUrl)) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid ${field}: must be a BookBed-controlled domain.`
    );
  }
}
