import {
  escapeHtml,
  injectSeo,
  buildPropertyMeta,
  buildUnitMeta,
  splitWidgetHost,
  resolveSubdomain,
  PROD_WIDGET_HOST,
} from "../src/ssr";

const SHELL = [
  "<!DOCTYPE html><html><head>",
  "<title>BookBed - Vacation Rental Management</title>",
  "<meta name=\"description\" content=\"generic\">",
  "<link rel=\"canonical\" href=\"https://app.bookbed.io\" />",
  "<meta property=\"og:title\" content=\"x\">",
  "<meta property=\"og:description\" content=\"x\">",
  "<meta property=\"og:url\" content=\"x\">",
  "<meta property=\"og:image\" content=\"x\">",
  "<meta name=\"twitter:title\" content=\"x\">",
  "<meta name=\"twitter:description\" content=\"x\">",
  "<meta name=\"twitter:image\" content=\"x\">",
  "</head><body><div id=\"native-splash\"></div></body></html>",
].join("\n");

const PROPERTY = {
  id: "p1",
  name: "Villa Marija",
  description: "Seafront villa on Rab island.",
  subdomain: "jasko-rab",
  city: "Rab",
  country: "Croatia",
  basePrice: 120,
  rating: 4.8,
  reviewCount: 12,
  isActive: true,
} as never;

describe("escapeHtml", () => {
  it("neutralizes HTML/script injection", () => {
    const out = escapeHtml("<script>alert(\"x\")</script> & 'q'");
    expect(out).toBe(
      "&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; &#39;q&#39;"
    );
    expect(out).not.toContain("<script>");
  });
});

describe("injectSeo", () => {
  const meta = buildPropertyMeta("jasko-rab", PROPERTY, []);
  const html = injectSeo(SHELL, meta);

  it("replaces title, description, canonical and OG tags", () => {
    expect(html).toContain(
      "<title>Villa Marija — Rab, Croatia | BookBed</title>"
    );
    expect(html).toContain("href=\"https://jasko-rab.view.bookbed.io/\"");
    expect(html).toContain("property=\"og:title\" content=\"Villa Marija");
    expect(html).not.toContain(
      "<title>BookBed - Vacation Rental Management</title>"
    );
  });

  it("injects the SEO block and JSON-LD, leaves the shell intact", () => {
    expect(html).toContain("id=\"ssr-seo\"");
    expect(html).toContain("<h1>Villa Marija</h1>");
    expect(html).toContain("\"@type\":\"LodgingBusiness\"");
    expect(html).toContain("id=\"native-splash\"");
  });

  it("escapes injection in the property name (XSS boundary)", () => {
    const evil = buildPropertyMeta(
      "s",
      {
        id: "p",
        name: "<img src=x onerror=alert(1)>",
        description: "d",
        subdomain: "s",
        isActive: true,
      } as never,
      []
    );
    const out = injectSeo(SHELL, evil);
    expect(out).not.toContain("<img src=x onerror");
    expect(out).toContain("&lt;img src=x");
  });

  it("cannot break out of the JSON-LD block via </script>", () => {
    const evil = buildPropertyMeta(
      "s",
      {
        id: "p",
        name: "</script><img src=x onerror=alert(1)>",
        description: "d",
        subdomain: "s",
        isActive: true,
      } as never,
      []
    );
    const out = injectSeo(SHELL, evil);
    const ldStart = out.indexOf("application/ld+json");
    const ldEnd = out.indexOf("</script>", ldStart);
    const ldBlock = out.slice(ldStart, ldEnd);
    expect(ldBlock).not.toContain("</script>");
    expect(ldBlock).toContain("\\u003c");
  });
});

describe("buildPropertyMeta JSON-LD", () => {
  it("omits aggregateRating when there are no reviews", () => {
    const m = buildPropertyMeta(
      "s",
      {
        id: "p",
        name: "N",
        description: "d",
        subdomain: "s",
        rating: 0,
        reviewCount: 0,
        isActive: true,
      } as never,
      []
    );
    expect(JSON.stringify(m.jsonLd)).not.toContain("aggregateRating");
  });

  it("lists units as internal links", () => {
    const m = buildPropertyMeta(
      "s",
      {
        id: "p",
        name: "N",
        description: "d",
        subdomain: "s",
        isActive: true,
      } as never,
      [
        {
          id: "u1",
          name: "Apartman 6",
          slug: "apartman-6",
          basePrice: 80,
          currency: "EUR",
          maxGuests: 4,
        } as never,
      ]
    );
    expect(m.bodyHtml).toContain(
      "href=\"https://s.view.bookbed.io/apartman-6\""
    );
    expect(m.bodyHtml).toContain("Apartman 6");
  });
});

describe("buildUnitMeta JSON-LD", () => {
  const m = buildUnitMeta("jasko-rab", PROPERTY, {
    id: "u",
    name: "Apartman 6",
    slug: "apartman-6",
    description: "Cozy unit",
    basePrice: 80,
    currency: "EUR",
    maxGuests: 4,
    bedrooms: 2,
    bathrooms: 1,
  } as never);

  it("emits Product + Offer with the unit price", () => {
    const s = JSON.stringify(m.jsonLd);
    expect(s).toContain("\"@type\":\"Product\"");
    expect(s).toContain("\"price\":80");
    expect(s).toContain("\"priceCurrency\":\"EUR\"");
  });

  it("emits a BreadcrumbList property -> unit", () => {
    expect(JSON.stringify(m.jsonLd)).toContain("\"@type\":\"BreadcrumbList\"");
    expect(m.canonical).toBe("https://jasko-rab.view.bookbed.io/apartman-6");
  });
});

describe("splitWidgetHost", () => {
  it("parses a prod client subdomain", () => {
    expect(splitWidgetHost("jasko-rab.view.bookbed.io")).toEqual({
      sub: "jasko-rab",
      hostSuffix: "view.bookbed.io",
    });
  });

  it("parses staging without mistaking it for prod", () => {
    expect(splitWidgetHost("jasko-rab.staging.view.bookbed.io")).toEqual({
      sub: "jasko-rab",
      hostSuffix: "staging.view.bookbed.io",
    });
  });

  it("rejects the bare widget host and unrelated hosts", () => {
    expect(splitWidgetHost("view.bookbed.io")).toBeNull();
    expect(splitWidgetHost("bookbed-widget-dev.web.app")).toBeNull();
    expect(splitWidgetHost("")).toBeNull();
  });

  it("ignores a port and is case-insensitive", () => {
    expect(splitWidgetHost("Jasko-Rab.View.BookBed.io:443")?.sub).toBe(
      "jasko-rab"
    );
  });
});

describe("resolveSubdomain override (dev escape hatch)", () => {
  const prevProject = process.env.GCLOUD_PROJECT;
  afterEach(() => {
    process.env.GCLOUD_PROJECT = prevProject;
  });

  it("honours _ssrSubdomain off prod and renders prod URLs", () => {
    process.env.GCLOUD_PROJECT = "bookbed-dev";
    expect(
      resolveSubdomain("bookbed-widget-dev.web.app", "jasko-rab")
    ).toEqual({sub: "jasko-rab", hostSuffix: PROD_WIDGET_HOST});
  });

  it("REFUSES the override on the production project", () => {
    process.env.GCLOUD_PROJECT = "rab-booking-248fc";
    expect(
      resolveSubdomain("bookbed-widget-dev.web.app", "jasko-rab")
    ).toBeNull();
  });

  it("rejects a malformed override slug", () => {
    process.env.GCLOUD_PROJECT = "bookbed-dev";
    expect(resolveSubdomain("x.web.app", "../evil")).toBeNull();
    expect(resolveSubdomain("x.web.app", "a")).toBeNull();
  });

  it("still parses the real host when no override is given", () => {
    process.env.GCLOUD_PROJECT = "bookbed-dev";
    expect(resolveSubdomain("jasko-rab.view.bookbed.io")?.sub).toBe(
      "jasko-rab"
    );
  });
});
