/**
 * CORS Origin Allowlist for Firebase Functions v2 callables.
 *
 * Replaces `cors: true` (reflective Origin — audit/58 F-58-07) on every
 * callable in the codebase. Pass as `cors: getCorsAllowlist()` in
 * `CallableOptions`.
 *
 * Semantics differ from {@link getAllowedReturnDomains}:
 * - Return-URL allowlist gates *redirect destinations* (Stripe `success_url`
 *   / `cancel_url`). It's a string-prefix match including marketing /
 *   `bookbed.io` because users land there post-payment.
 * - This CORS allowlist gates the `Origin` header on browser fetches into
 *   the callable. Marketing `bookbed.io` doesn't host any callable-issuing
 *   client, so it's omitted; the embeddable widget on third-party origins
 *   issues callables from `view.bookbed.io` (iframe origin), not the parent
 *   host.
 *
 * Wildcard customer subdomains (`{tenant}.view.bookbed.io`) are matched via
 * regex. Firebase Functions v2 `cors` accepts `(string | RegExp)[]`.
 */

const BASE_ALLOWED_ORIGINS: string[] = [
  // Production surfaces
  "https://app.bookbed.io",
  "https://view.bookbed.io",
  "https://bookbed-admin.web.app",
  // Firebase Hosting auto-domains for the production project
  "https://bookbed-owner.web.app",
  "https://bookbed-widget.web.app",
  "https://rab-booking-248fc.web.app",
  "https://rab-booking-248fc.firebaseapp.com",
];

// Customer-subdomain widget (jasko-rab.view.bookbed.io etc.) — only the
// widget surface is wildcarded.
const ALLOWED_ORIGIN_REGEX: RegExp[] = [
  /^https:\/\/[a-z0-9][a-z0-9-]*\.view\.bookbed\.io$/,
];

const DEV_ALLOWED_ORIGINS: string[] = [
  "https://bookbed-owner-dev.web.app",
  "https://bookbed-widget-dev.web.app",
  "https://bookbed-admin-dev.web.app",
];

const STAGING_ALLOWED_ORIGINS: string[] = [
  "https://bookbed-owner-staging.web.app",
  "https://bookbed-widget-staging.web.app",
  "https://bookbed-admin-staging.web.app",
];

const LOCAL_DEV_ORIGINS: string[] = [
  "http://localhost:5000",
  "http://localhost:5001",
  "http://localhost:8080",
  "http://127.0.0.1:5000",
  "http://127.0.0.1:5001",
  "http://127.0.0.1:8080",
];

/**
 * Return the CORS allowlist as a `(string | RegExp)[]` ready to feed into
 * Firebase Functions v2 `CallableOptions.cors`.
 *
 * Per-env entries are appended at request time based on `GCP_PROJECT` /
 * `GCLOUD_PROJECT`, so the production list stays minimal.
 */
export function getCorsAllowlist(): (string | RegExp)[] {
  const list: (string | RegExp)[] = [...BASE_ALLOWED_ORIGINS, ...ALLOWED_ORIGIN_REGEX];
  const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
  const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";

  if (projectId === "bookbed-dev" || isEmulator) {
    list.push(...DEV_ALLOWED_ORIGINS);
  }
  if (projectId === "bookbed-staging") {
    list.push(...STAGING_ALLOWED_ORIGINS);
  }
  if (isEmulator) {
    list.push(...LOCAL_DEV_ORIGINS);
  }

  return list;
}
