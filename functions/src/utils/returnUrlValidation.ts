/**
 * Return URL allowlist validation for Stripe redirect surfaces.
 *
 * Extracted from stripePayment.ts (F-NEW-02) so that every Stripe call
 * that takes a client-controlled return URL — booking checkout, subscription
 * checkout, billing portal, Connect onboarding — runs the same validator.
 *
 * SECURITY model:
 * - Exact protocol+hostname match against an allowlist (parsed via URL constructor).
 *   The previous `startsWith()` check accepted "https://bookbed.io.evil.com/..." and
 *   "https://bookbed.io@evil.com/..." (userinfo trick) — fixed in audit/100.
 * - Userinfo (user:pass@) rejected outright — Stripe's redirect callers never
 *   need it, and email clients render leading host even when the URL parser
 *   resolves to a trailing host.
 * - Per-env additions (bookbed-dev / bookbed-staging Hosting domains) appended
 *   at request time from GCP_PROJECT so the prod list stays minimal.
 * - Local-dev hosts (http://localhost / http://127.0.0.1) gated behind
 *   FUNCTIONS_EMULATOR — mirrors stripePayment.ts:46-71 (SF-073). The earlier
 *   extracted util shipped them unconditionally, regressing SF-073 in PROD;
 *   audit/100 H-2 restores the gate.
 * - Wildcard subdomain match (`*.view.bookbed.io`) using split-based parts
 *   comparison — blocks "evil-view.bookbed.io" (3 parts) but allows
 *   "jasko-rab.view.bookbed.io" (4 parts). Wildcards are https-only.
 */

const BASE_ALLOWED_DOMAINS = [
  "https://bookbed.io", // Marketing site
  "https://app.bookbed.io", // Owner dashboard
  "https://view.bookbed.io", // Booking widget main
];

// SF-073 / audit/100 H-2: local-dev hosts must NEVER appear in PROD's allowlist.
// A PROD returnUrl pointing to localhost is an exfil vector (attacker-controlled
// host on the operator's network gets the success-redirect with session info).
// Appended only when FUNCTIONS_EMULATOR is set.
const LOCAL_DEV_DOMAINS = [
  "http://localhost",
  "http://127.0.0.1",
];

const ALLOWED_WILDCARD_DOMAINS = [
  ".view.bookbed.io", // Client subdomains (e.g., jasko-rab.view.bookbed.io)
];

export function getAllowedReturnDomains(): string[] {
  const base = [...BASE_ALLOWED_DOMAINS];
  const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
  const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";
  if (projectId === "bookbed-dev" || isEmulator) {
    base.push("https://bookbed-widget-dev.web.app");
    base.push("https://bookbed-owner-dev.web.app");
  }
  if (projectId === "bookbed-staging") {
    base.push("https://bookbed-widget-staging.web.app");
    base.push("https://bookbed-owner-staging.web.app");
  }
  if (isEmulator) {
    base.push(...LOCAL_DEV_DOMAINS);
  }
  return base;
}

/**
 * Validate a return URL against the allowlist.
 *
 * Returns true if URL's protocol+hostname match any allowed entry, or if the
 * URL's hostname matches an allowed wildcard subdomain. Returns false on
 * malformed URLs, URLs that carry userinfo, or URLs that fail strict
 * protocol+hostname equality.
 *
 * @param returnUrl Full URL string from client
 */
export function isAllowedReturnUrl(returnUrl: string): boolean {
  if (!returnUrl || typeof returnUrl !== "string") return false;

  let parsed: URL;
  try {
    parsed = new URL(returnUrl);
  } catch {
    return false;
  }

  // Reject URLs that carry credentials (user:pass@). Stripe redirects never
  // need them, and `https://bookbed.io@evil.com/...` would route to evil.com
  // while the leading text fools casual reviewers.
  if (parsed.username !== "" || parsed.password !== "") return false;

  const allowedDomains = getAllowedReturnDomains();

  // Exact protocol + hostname match. Port left permissive: allowed entries do
  // not specify a port, so any input port (including emulator's :5000) passes
  // when hostname+protocol align.
  for (const domainStr of allowedDomains) {
    let allowed: URL;
    try {
      allowed = new URL(domainStr);
    } catch {
      continue;
    }
    if (
      parsed.protocol === allowed.protocol &&
      parsed.hostname === allowed.hostname
    ) {
      return true;
    }
  }

  // Wildcard match (split-based; blocks "evil-view.bookbed.io"). https-only.
  if (parsed.protocol !== "https:") return false;
  const hostnameParts = parsed.hostname.split(".");
  return ALLOWED_WILDCARD_DOMAINS.some((wildcardDomain) => {
    const domainWithoutDot = wildcardDomain.slice(1); // ".view.bookbed.io" -> "view.bookbed.io"
    const wildcardParts = domainWithoutDot.split(".");
    // Hostname must have MORE parts than wildcard domain.
    if (hostnameParts.length <= wildcardParts.length) return false;
    const lastParts = hostnameParts.slice(-wildcardParts.length);
    return lastParts.join(".") === domainWithoutDot;
  });
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
