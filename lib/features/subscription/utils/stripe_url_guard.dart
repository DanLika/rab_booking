/// URL safety guard for Stripe redirect targets.
///
/// Only the two Stripe-hosted domains are acceptable redirect destinations
/// from a subscription checkout or portal session. Anything else (including
/// lookalike hosts such as `checkout.stripe.com.evil.com`) must be rejected.
///
/// Mirrors the CallidusOS `isSafeStripeUrl` pattern. Pure function — no
/// side-effects, easy to unit-test.
library;

/// Exact allowlist of Stripe-hosted domains that may receive a same-tab
/// redirect from the subscription checkout / portal flow.
const Set<String> _kAllowedStripeHosts = <String>{
  'checkout.stripe.com',
  'billing.stripe.com',
};

/// Returns `true` when [url] is safe to redirect the browser to:
///   - scheme must be `https`
///   - host must be exactly one of [_kAllowedStripeHosts]
///
/// Returns `false` for any other input, including malformed URLs, HTTP,
/// and look-alike hosts such as `checkout.stripe.com.evil.com`.
bool isSafeStripeUrl(String url) {
  try {
    final Uri uri = Uri.parse(url);
    return uri.isScheme('https') && _kAllowedStripeHosts.contains(uri.host);
  } catch (_) {
    return false;
  }
}
