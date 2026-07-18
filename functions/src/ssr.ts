import {onRequest} from "firebase-functions/v2/https";
import type {DocumentData} from "firebase-admin/firestore";
import {db} from "./firebase";
import {logInfo, logError} from "./logger";
import {getClientIp, hashIp} from "./utils/ipUtils";
import {checkRateLimit} from "./utils/rateLimit";

/**
 * Server-side rendering for the public booking widget (SEO).
 *
 * Flutter renders to <canvas>, which crawlers cannot read. These
 * functions serve real, per-page HTML (title/meta/canonical/OG +
 * visible content + JSON-LD) for the public property/unit pages, then
 * hand off to the real Flutter shell so humans get the full app.
 *
 * Routing (Firebase Hosting rewrites on the `widget` target):
 *   /            -> ssrWidget   property root
 *   /:slug       -> ssrWidget   unit page
 *   /sitemap.xml -> ssrSitemap
 *
 * Drift-proofing: we do NOT reproduce the 800-line Flutter boot
 * sequence. We fetch the actually-deployed index.html shell at runtime
 * and inject our SEO into it, so the boot logic is always current.
 */

const PROD_PROJECT = "rab-booking-248fc";
export const PROD_WIDGET_HOST = "view.bookbed.io";

// Longest first: a staging subdomain must not be parsed as a prod one.
const WIDGET_HOST_SUFFIXES = [
  "staging.view.bookbed.io",
  PROD_WIDGET_HOST,
];

const MARKETING_URL = "https://bookbed.io";

// A real, deployed asset. bookbed.io/og-image.png 404s and
// app.bookbed.io/og-image.png returns the HTML shell, so anything
// pointing there yields a broken social card. TODO: swap in a proper
// 1200x630 branded card when design supplies one.
const FALLBACK_IMAGE = "https://app.bookbed.io/icons/Icon-512.png";
const SHELL_TTL_MS = 5 * 60 * 1000;

/**
 * True on the production Firebase project only.
 * @return {boolean} whether this instance runs in production.
 */
function isProd(): boolean {
  const p = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || "";
  return p === PROD_PROJECT;
}

// ponytail: last-good-wins shell cache, keyed by host so each env serves
// its own build. Refresh attempt every TTL; a failed refresh keeps
// serving the last good shell so a transient fetch blip never breaks the
// page. Upgrade path: bake the shell into the deploy if runtime fetch
// ever proves flaky.
const shellCache = new Map<string, {html: string; at: number}>();

/**
 * Fetch a deployed Flutter shell, cached with last-good fallback.
 * @param {string} host host whose index.html to fetch.
 * @return {Promise<string|null>} shell HTML, or null if never fetched.
 */
async function getShell(host: string): Promise<string | null> {
  const now = Date.now();
  const hit = shellCache.get(host);
  if (hit && now - hit.at < SHELL_TTL_MS) return hit.html;
  try {
    const res = await fetch(`https://${host}/index.html`, {
      redirect: "follow",
    });
    if (!res.ok) throw new Error(`shell ${res.status}`);
    const html = await res.text();
    shellCache.set(host, {html, at: now});
    return html;
  } catch (e) {
    logError("[SSR] shell fetch failed", e, {host});
    return hit?.html ?? null;
  }
}

/**
 * Escape a string for safe interpolation into HTML text/attributes.
 * @param {string} s raw string.
 * @return {string} escaped string.
 */
export function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

/**
 * Collapse control characters for JSON-LD string values.
 * @param {string} s raw string.
 * @return {string} cleaned string.
 */
function jsonLdText(s: string): string {
  // Built without a regex: no-control-regex flags control-char
  // classes however they are written.
  const cleaned = Array.from(s || "")
    .map((ch) => (ch.charCodeAt(0) < 0x20 ? " " : ch))
    .join("");
  return cleaned.replace(/\s+/g, " ").trim();
}

/**
 * Collapse whitespace and clip to a maximum length.
 * @param {string} s raw string.
 * @param {number} n maximum length.
 * @return {string} truncated string.
 */
function truncate(s: string, n: number): string {
  const t = (s || "").replace(/\s+/g, " ").trim();
  if (t.length <= n) return t;
  return t.slice(0, n - 1).replace(/\s+$/, "") + "…";
}

/**
 * Split a Host header into its client subdomain and widget host.
 *
 * Dev has no wildcard: the dev widget site is a plain Firebase Hosting
 * host (bookbed-widget-dev.web.app), so `sub.dev-host` can never
 * resolve. Dev verification therefore goes through the non-prod
 * `_ssrSubdomain` override below, not through this function.
 *
 * @param {string} host raw Host header.
 * @return {{sub: string, hostSuffix: string}|null} parts, or null.
 */
export function splitWidgetHost(
  host: string
): {sub: string; hostSuffix: string} | null {
  const h = (host || "").toLowerCase().split(":")[0];
  for (const suffix of WIDGET_HOST_SUFFIXES) {
    const dotted = `.${suffix}`;
    if (!h.endsWith(dotted)) continue;
    const sub = h.slice(0, -dotted.length);
    if (!sub || sub.includes(".")) return null;
    return {sub, hostSuffix: suffix};
  }
  return null;
}

/** A property subdomain: same shape the app enforces (3-30 chars). */
const SUBDOMAIN_RE = /^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/;

/**
 * First path segments owned by the Flutter router, not by unit slugs.
 * Kept here rather than only in the hosting rewrites so a new app route
 * cannot silently start returning 404 from the SSR path.
 * Mirrors lib/core/config/router_widget.dart.
 */
const RESERVED_PATHS = new Set(["calendar", "view", "embed"]);

/**
 * Whether a first path segment belongs to the Flutter app.
 * @param {string} seg first path segment, already lowercased.
 * @return {boolean} true when the app owns this route.
 */
export function isReservedPath(seg: string): boolean {
  return RESERVED_PATHS.has(seg);
}

/**
 * Resolve which property to render, allowing a non-prod override so the
 * SSR can be exercised on dev, where no wildcard subdomain exists.
 * The override is refused on the production project.
 * @param {string} host raw Host header.
 * @param {unknown} override raw `_ssrSubdomain` query value.
 * @return {{sub: string, hostSuffix: string}|null} parts, or null.
 */
export function resolveSubdomain(
  host: string,
  override?: unknown
): {sub: string; hostSuffix: string} | null {
  if (!isProd() && typeof override === "string" && override) {
    const sub = override.toLowerCase();
    if (SUBDOMAIN_RE.test(sub)) {
      // Render exactly what prod would emit, so a dev check is
      // meaningful: canonical/OG use the prod host.
      return {sub, hostSuffix: PROD_WIDGET_HOST};
    }
    return null;
  }
  return splitWidgetHost(host);
}

interface Meta {
  title: string;
  description: string;
  canonical: string;
  image: string;
  bodyHtml: string;
  jsonLd: object[];
}

/**
 * Inject SEO into the real deployed shell: replace title, description,
 * canonical and OG/Twitter tags, then inject JSON-LD plus a visible
 * content block right after <body>. Flutter boot is untouched.
 * @param {string} shell deployed index.html.
 * @param {Meta} m per-page SEO data.
 * @return {string} the shell with SEO injected.
 */
export function injectSeo(shell: string, m: Meta): string {
  const t = escapeHtml(m.title);
  const d = escapeHtml(truncate(m.description, 160));
  const c = escapeHtml(m.canonical);
  const img = escapeHtml(m.image);

  let out = shell;
  out = out.replace(/<title>[\s\S]*?<\/title>/i, `<title>${t}</title>`);
  out = out.replace(
    /<meta\s+name=["']description["'][^>]*>/i,
    `<meta name="description" content="${d}">`
  );
  out = out.replace(
    /<link\s+rel=["']canonical["'][^>]*>/i,
    `<link rel="canonical" href="${c}" />`
  );
  out = out.replace(
    /<meta\s+property=["']og:title["'][^>]*>/i,
    `<meta property="og:title" content="${t}">`
  );
  out = out.replace(
    /<meta\s+property=["']og:description["'][^>]*>/i,
    `<meta property="og:description" content="${d}">`
  );
  out = out.replace(
    /<meta\s+property=["']og:url["'][^>]*>/i,
    `<meta property="og:url" content="${c}">`
  );
  out = out.replace(
    /<meta\s+property=["']og:image["'][^>]*>/i,
    `<meta property="og:image" content="${img}">`
  );
  out = out.replace(
    /<meta\s+name=["']twitter:title["'][^>]*>/i,
    `<meta name="twitter:title" content="${t}">`
  );
  out = out.replace(
    /<meta\s+name=["']twitter:description["'][^>]*>/i,
    `<meta name="twitter:description" content="${d}">`
  );
  out = out.replace(
    /<meta\s+name=["']twitter:image["'][^>]*>/i,
    `<meta name="twitter:image" content="${img}">`
  );

  // Unicode-escape <, > and & so a value containing "</script>" cannot
  // break out of the JSON-LD block (XSS). Stays valid JSON.
  const ld = m.jsonLd
    .map((o) => {
      const json = JSON.stringify(o)
        .replace(/</g, "\\u003c")
        .replace(/>/g, "\\u003e")
        .replace(/&/g, "\\u0026");
      return `<script type="application/ld+json">${json}</script>`;
    })
    .join("\n");

  // Visible content + JSON-LD injected right after <body>. The
  // native-splash overlay already in the shell covers this for humans
  // until Flutter mounts; crawlers read it. Real property data, so this
  // is neither hidden text nor cloaking.
  const style = "position:absolute;top:0;left:0;width:100%;z-index:0";
  const block =
    `\n${ld}\n<div id="ssr-seo" style="${style}">${m.bodyHtml}</div>\n`;
  out = out.replace(/<body[^>]*>/i, (bodyTag) => `${bodyTag}${block}`);
  return out;
}

interface PropertyDoc {
  id: string;
  name: string;
  description: string;
  subdomain?: string;
  city?: string;
  country?: string;
  address?: string;
  coverImage?: string;
  images?: string[];
  rating?: number;
  reviewCount?: number;
  basePrice?: number;
  isActive?: boolean;
}

interface UnitDoc {
  id: string;
  name: string;
  slug?: string;
  description?: string;
  basePrice?: number;
  currency?: string;
  maxGuests?: number;
  bedrooms?: number;
  bathrooms?: number;
  areaSqm?: number;
  images?: string[];
}

/**
 * Map a Firestore property document to the SSR shape.
 * @param {string} id document id.
 * @param {DocumentData} x raw document data.
 * @return {PropertyDoc} mapped property.
 */
function mapProperty(id: string, x: DocumentData): PropertyDoc {
  return {
    id,
    name: x.name || "",
    description: x.description || "",
    subdomain: x.subdomain,
    city: x.city,
    country: x.country || "Croatia",
    address: x.address,
    coverImage: x.cover_image,
    images: Array.isArray(x.images) ? x.images : [],
    rating: typeof x.rating === "number" ? x.rating : 0,
    reviewCount: typeof x.review_count === "number" ? x.review_count : 0,
    basePrice: typeof x.base_price === "number" ? x.base_price : undefined,
    isActive: x.is_active !== false,
  };
}

/**
 * Map a Firestore unit document to the SSR shape.
 * @param {string} id document id.
 * @param {DocumentData} x raw document data.
 * @return {UnitDoc} mapped unit.
 */
function mapUnit(id: string, x: DocumentData): UnitDoc {
  return {
    id,
    name: x.name || "",
    slug: x.slug,
    description: x.description || "",
    basePrice: typeof x.base_price === "number" ? x.base_price : undefined,
    currency: x.currency || "EUR",
    maxGuests: x.max_guests,
    bedrooms: x.bedrooms,
    bathrooms: x.bathrooms,
    areaSqm: typeof x.area_sqm === "number" ? x.area_sqm : undefined,
    images: Array.isArray(x.images) ? x.images : [],
  };
}

/**
 * Look up a property by its subdomain.
 * @param {string} subdomain client subdomain.
 * @return {Promise<PropertyDoc|null>} property or null.
 */
async function findProperty(subdomain: string): Promise<PropertyDoc | null> {
  const snap = await db
    .collection("properties")
    .where("subdomain", "==", subdomain.toLowerCase())
    .limit(1)
    .get();
  if (snap.empty) return null;
  const doc = snap.docs[0];
  return mapProperty(doc.id, doc.data());
}

/**
 * List the bookable units of a property.
 * @param {string} propertyId parent property id.
 * @return {Promise<UnitDoc[]>} available units.
 */
async function listUnits(propertyId: string): Promise<UnitDoc[]> {
  const snap = await db
    .collection("properties")
    .doc(propertyId)
    .collection("units")
    .where("is_available", "==", true)
    .orderBy("sort_order")
    .get()
    .catch(() => null);
  if (!snap) return [];
  return snap.docs
    .filter((d) => !d.data().deleted_at)
    .map((d) => mapUnit(d.id, d.data()));
}

/**
 * Look up a unit by its URL slug.
 * @param {string} propertyId parent property id.
 * @param {string} slug unit slug.
 * @return {Promise<UnitDoc|null>} unit or null.
 */
async function findUnit(
  propertyId: string,
  slug: string
): Promise<UnitDoc | null> {
  const snap = await db
    .collection("properties")
    .doc(propertyId)
    .collection("units")
    .where("slug", "==", slug.toLowerCase())
    .limit(1)
    .get();
  if (snap.empty) return null;
  const doc = snap.docs[0];
  if (doc.data().deleted_at) return null;
  return mapUnit(doc.id, doc.data());
}

/**
 * Public base URL for a client subdomain.
 * @param {string} sub client subdomain.
 * @param {string} hostSuffix widget host for this environment.
 * @return {string} origin without trailing slash.
 */
function propBaseUrl(sub: string, hostSuffix: string): string {
  return `https://${sub}.${hostSuffix}`;
}

/**
 * Build SEO data for a property root page.
 * @param {string} sub client subdomain.
 * @param {PropertyDoc} p the property.
 * @param {UnitDoc[]} units its bookable units.
 * @param {string} hostSuffix widget host for this environment.
 * @return {Meta} per-page SEO data.
 */
export function buildPropertyMeta(
  sub: string,
  p: PropertyDoc,
  units: UnitDoc[],
  hostSuffix: string = PROD_WIDGET_HOST
): Meta {
  const url = `${propBaseUrl(sub, hostSuffix)}/`;
  const loc = [p.city, p.country].filter(Boolean).join(", ");
  const title = `${p.name}${loc ? ` — ${loc}` : ""} | BookBed`;
  const fallbackImg = FALLBACK_IMAGE;
  const image = p.coverImage || p.images?.[0] || fallbackImg;

  const unitLinks = units
    .filter((u) => u.slug)
    .map((u) => {
      const price = u.basePrice ?
        ` — ${u.basePrice} ${u.currency}/night` :
        "";
      const cap = u.maxGuests ? `, up to ${u.maxGuests} guests` : "";
      const slug = escapeHtml(u.slug as string);
      const href = `${propBaseUrl(sub, hostSuffix)}/${slug}`;
      const label = escapeHtml(u.name);
      const extra = escapeHtml(price + cap);
      return `<li><a href="${href}">${label}</a>${extra}</li>`;
    })
    .join("");

  const locLine = loc ? `<p><strong>${escapeHtml(loc)}</strong></p>` : "";
  const unitBlock = unitLinks ?
    `<h2>Accommodation</h2><ul>${unitLinks}</ul>` :
    "";
  const bodyHtml = `
    <h1>${escapeHtml(p.name)}</h1>
    ${locLine}
    <p>${escapeHtml(p.description)}</p>
    ${unitBlock}
    <p><a href="${MARKETING_URL}">BookBed</a> — book direct.</p>`;

  const hasRating = (p.reviewCount || 0) > 0 && (p.rating || 0) > 0;
  const hasAddress = Boolean(loc || p.address);

  const ld: object[] = [
    {
      "@context": "https://schema.org",
      "@type": "LodgingBusiness",
      "name": jsonLdText(p.name),
      "description": jsonLdText(p.description),
      "url": url,
      "image": image,
      ...(hasAddress ?
        {
          address: {
            "@type": "PostalAddress",
            ...(p.address ? {streetAddress: jsonLdText(p.address)} : {}),
            ...(p.city ? {addressLocality: jsonLdText(p.city)} : {}),
            ...(p.country ? {addressCountry: jsonLdText(p.country)} : {}),
          },
        } :
        {}),
      ...(p.basePrice ? {priceRange: `from €${p.basePrice}`} : {}),
      ...(hasRating ?
        {
          aggregateRating: {
            "@type": "AggregateRating",
            "ratingValue": p.rating,
            "reviewCount": p.reviewCount,
          },
        } :
        {}),
    },
  ];

  return {
    title,
    description: p.description,
    canonical: url,
    image,
    bodyHtml,
    jsonLd: ld,
  };
}

/**
 * Build SEO data for a unit page.
 * @param {string} sub client subdomain.
 * @param {PropertyDoc} p the parent property.
 * @param {UnitDoc} u the unit.
 * @param {string} hostSuffix widget host for this environment.
 * @return {Meta} per-page SEO data.
 */
export function buildUnitMeta(
  sub: string,
  p: PropertyDoc,
  u: UnitDoc,
  hostSuffix: string = PROD_WIDGET_HOST
): Meta {
  const url = `${propBaseUrl(sub, hostSuffix)}/${u.slug}`;
  const title = `${u.name} — ${p.name} | BookBed`;
  const desc = u.description || p.description;
  const fallbackImg = FALLBACK_IMAGE;
  const image =
    u.images?.[0] || p.coverImage || p.images?.[0] || fallbackImg;

  const facts = [
    u.maxGuests ? `${u.maxGuests} guests` : null,
    u.bedrooms ? `${u.bedrooms} bedroom${u.bedrooms > 1 ? "s" : ""}` : null,
    u.bathrooms ?
      `${u.bathrooms} bathroom${u.bathrooms > 1 ? "s" : ""}` :
      null,
    u.areaSqm ? `${u.areaSqm} m²` : null,
  ]
    .filter(Boolean)
    .join(" · ");

  const home = `${propBaseUrl(sub, hostSuffix)}/`;
  const factLine = facts ? `<p>${escapeHtml(facts)}</p>` : "";
  const priceLine = u.basePrice ?
    `<p><strong>From ${u.basePrice} ${u.currency} / night</strong></p>` :
    "";
  const crumb =
    `<a href="${home}">${escapeHtml(p.name)}</a> › ${escapeHtml(u.name)}`;
  const bodyHtml = `
    <nav>${crumb}</nav>
    <h1>${escapeHtml(u.name)}</h1>
    ${factLine}
    ${priceLine}
    <p>${escapeHtml(desc)}</p>
    <p><a href="${home}">All units at ${escapeHtml(p.name)}</a> ·
    <a href="${MARKETING_URL}">BookBed</a></p>`;

  const hasRating = (p.reviewCount || 0) > 0 && (p.rating || 0) > 0;

  const ld: object[] = [
    {
      "@context": "https://schema.org",
      "@type": "Product",
      "name": jsonLdText(`${u.name} — ${p.name}`),
      "description": jsonLdText(desc),
      "url": url,
      "image": image,
      ...(u.basePrice ?
        {
          offers: {
            "@type": "Offer",
            "price": u.basePrice,
            "priceCurrency": u.currency || "EUR",
            "availability": "https://schema.org/InStock",
            "url": url,
          },
        } :
        {}),
      ...(hasRating ?
        {
          aggregateRating: {
            "@type": "AggregateRating",
            "ratingValue": p.rating,
            "reviewCount": p.reviewCount,
          },
        } :
        {}),
    },
    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      "itemListElement": [
        {
          "@type": "ListItem",
          "position": 1,
          "name": jsonLdText(p.name),
          "item": home,
        },
        {
          "@type": "ListItem",
          "position": 2,
          "name": jsonLdText(u.name),
          "item": url,
        },
      ],
    },
  ];

  return {
    title,
    description: desc,
    canonical: url,
    image,
    bodyHtml,
    jsonLd: ld,
  };
}

/**
 * Convert a Firestore timestamp to a YYYY-MM-DD string.
 * @param {unknown} v candidate timestamp.
 * @return {string|undefined} ISO date, or undefined.
 */
function tsToIso(v: unknown): string | undefined {
  const t = v as {toDate?: () => Date};
  if (t && typeof t.toDate === "function") {
    return t.toDate().toISOString().slice(0, 10);
  }
  return undefined;
}

/**
 * SEO entrypoint for public property and unit pages.
 */
export const ssrWidget = onRequest(
  {memory: "256MiB"},
  async (request, response) => {
    if (request.method !== "GET" && request.method !== "HEAD") {
      response.status(405).send("Method Not Allowed");
      return;
    }

    const ipHash = hashIp(getClientIp(request));
    if (!checkRateLimit(`ssr_${ipHash}`, 120, 3600)) {
      response.status(429).send("Too many requests");
      return;
    }

    const host = (request.headers.host as string) || "";
    const parts = resolveSubdomain(host, request.query._ssrSubdomain);
    const shell = await getShell(host.split(":")[0]);

    // No subdomain (bare widget host or dev host) or no shell: fall
    // through to the plain Flutter app.
    if (!parts || !shell) {
      if (shell) {
        response.set("Cache-Control", "public, max-age=60");
        response.status(200).send(shell);
      } else {
        response.status(302).set("Location", "/index.html").send("");
      }
      return;
    }

    try {
      const {sub, hostSuffix} = parts;
      const prop = await findProperty(sub);
      if (!prop || !prop.isActive) {
        response.set("Cache-Control", "public, max-age=120");
        response.status(404).send(shell);
        return;
      }

      const segs = request.path.split("/").filter(Boolean);
      const rawSlug = decodeURIComponent(segs[0] || "").toLowerCase();

      // A route the Flutter app owns (e.g. /calendar): hand over the
      // shell with 200. Treating it as an unknown slug would 404 a page
      // that renders perfectly well, and crawlers would drop it.
      if (rawSlug && isReservedPath(rawSlug)) {
        response.set("Cache-Control", "public, max-age=60");
        response.status(200).send(shell);
        return;
      }

      let meta: Meta;
      if (!rawSlug) {
        const units = await listUnits(prop.id);
        meta = buildPropertyMeta(sub, prop, units, hostSuffix);
      } else {
        const unit = await findUnit(prop.id, rawSlug);
        if (!unit) {
          // Unknown slug: serve the shell, let Flutter route or 404 it.
          response.set("Cache-Control", "public, max-age=120");
          response.status(404).send(shell);
          return;
        }
        meta = buildUnitMeta(sub, prop, unit, hostSuffix);
      }

      logInfo("[SSR] rendered", {sub, slug: rawSlug || "(root)"});
      // Edge-cache hard; property data changes rarely.
      response.set(
        "Cache-Control",
        "public, max-age=300, s-maxage=86400"
      );
      response.status(200).send(injectSeo(shell, meta));
    } catch (e) {
      logError("[SSR] render failed", e, {sub: parts.sub});
      response.set("Cache-Control", "no-store");
      response.status(200).send(shell);
    }
  }
);

/**
 * Sitemap of every public property and unit page.
 */
export const ssrSitemap = onRequest(
  {memory: "256MiB"},
  async (request, response) => {
    const ipHash = hashIp(getClientIp(request));
    if (!checkRateLimit(`sitemap_${ipHash}`, 30, 3600)) {
      response.status(429).send("Too many requests");
      return;
    }

    try {
      const snap = await db
        .collection("properties")
        .where("is_active", "==", true)
        .get();
      const urls: {loc: string; lastmod?: string}[] = [];

      for (const doc of snap.docs) {
        const p = mapProperty(doc.id, doc.data());
        if (!p.subdomain) continue;
        const base = propBaseUrl(p.subdomain, PROD_WIDGET_HOST);
        const lastmod = tsToIso(doc.data().updated_at);
        urls.push({loc: `${base}/`, lastmod});
        const units = await listUnits(p.id);
        for (const u of units) {
          if (!u.slug) continue;
          urls.push({
            loc: `${base}/${encodeURIComponent(u.slug)}`,
            lastmod,
          });
        }
      }

      const rows = urls
        .map((u) => {
          const mod = u.lastmod ? `<lastmod>${u.lastmod}</lastmod>` : "";
          return `  <url><loc>${escapeHtml(u.loc)}</loc>${mod}</url>`;
        })
        .join("\n");
      const ns = "http://www.sitemaps.org/schemas/sitemap/0.9";
      const body =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
        `<urlset xmlns="${ns}">\n${rows}\n</urlset>\n`;

      logInfo("[SSR] sitemap", {count: urls.length});
      response.set("Content-Type", "application/xml");
      response.set(
        "Cache-Control",
        "public, max-age=3600, s-maxage=21600"
      );
      response.status(200).send(body);
    } catch (e) {
      logError("[SSR] sitemap failed", e);
      response.status(500).send("");
    }
  }
);
