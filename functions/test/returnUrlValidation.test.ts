/**
 * Unit tests for utils/returnUrlValidation.ts (audit/100 H-1, H-2).
 *
 * H-1 (open redirect): replaced `startsWith()` prefix match with
 * `new URL()` host+protocol equality. Closes the
 * `https://bookbed.io.evil.com/...` prefix bypass and the
 * `https://attacker@bookbed.io/...` userinfo trick.
 *
 * H-2 (SF-073 regression): localhost / 127.0.0.1 must NOT appear in PROD's
 * allowlist. They are appended only when FUNCTIONS_EMULATOR is set.
 */

import {
  getAllowedReturnDomains,
  isAllowedReturnUrl,
} from "../src/utils/returnUrlValidation";

const ORIGINAL_ENV = {
  FUNCTIONS_EMULATOR: process.env.FUNCTIONS_EMULATOR,
  GCP_PROJECT: process.env.GCP_PROJECT,
  GCLOUD_PROJECT: process.env.GCLOUD_PROJECT,
};

afterEach(() => {
  process.env.FUNCTIONS_EMULATOR = ORIGINAL_ENV.FUNCTIONS_EMULATOR;
  process.env.GCP_PROJECT = ORIGINAL_ENV.GCP_PROJECT;
  process.env.GCLOUD_PROJECT = ORIGINAL_ENV.GCLOUD_PROJECT;
});

function clearEnv() {
  delete process.env.FUNCTIONS_EMULATOR;
  delete process.env.GCP_PROJECT;
  delete process.env.GCLOUD_PROJECT;
}

describe("isAllowedReturnUrl — H-1 host-only validation", () => {
  beforeEach(clearEnv);

  test("legit https://bookbed.io/success ALLOWED", () => {
    expect(isAllowedReturnUrl("https://bookbed.io/success")).toBe(true);
  });

  test("legit https://app.bookbed.io/owner/billing/success ALLOWED", () => {
    expect(isAllowedReturnUrl("https://app.bookbed.io/owner/billing/success")).toBe(true);
  });

  test("legit https://view.bookbed.io/widget/success ALLOWED", () => {
    expect(isAllowedReturnUrl("https://view.bookbed.io/widget/success")).toBe(true);
  });

  test("H-1: prefix-bypass https://bookbed.io.evil.com/... REJECTED", () => {
    expect(isAllowedReturnUrl("https://bookbed.io.evil.com/cb")).toBe(false);
  });

  test("H-1: prefix-bypass https://app.bookbed.io.evil.com/... REJECTED", () => {
    expect(isAllowedReturnUrl("https://app.bookbed.io.evil.com/cb")).toBe(false);
  });

  test("H-1: userinfo trick https://bookbed.io@evil.com/... REJECTED (parsed host = evil.com)", () => {
    expect(isAllowedReturnUrl("https://bookbed.io@evil.com/cb")).toBe(false);
  });

  test("H-1: userinfo trick https://attacker@bookbed.io/... REJECTED (credentials present)", () => {
    expect(isAllowedReturnUrl("https://attacker@bookbed.io/cb")).toBe(false);
  });

  test("H-1: user:pass userinfo https://u:p@bookbed.io/... REJECTED", () => {
    expect(isAllowedReturnUrl("https://u:p@bookbed.io/cb")).toBe(false);
  });

  test("H-1: protocol mismatch http://bookbed.io/... REJECTED", () => {
    expect(isAllowedReturnUrl("http://bookbed.io/cb")).toBe(false);
  });

  test("malformed URL REJECTED", () => {
    expect(isAllowedReturnUrl("not-a-url")).toBe(false);
  });

  test("empty string REJECTED", () => {
    expect(isAllowedReturnUrl("")).toBe(false);
  });

  test("non-string REJECTED", () => {
    expect(isAllowedReturnUrl(undefined as unknown as string)).toBe(false);
  });

  // ---- wildcard *.view.bookbed.io ----

  test("wildcard: legit https://jasko-rab.view.bookbed.io/... ALLOWED", () => {
    expect(isAllowedReturnUrl("https://jasko-rab.view.bookbed.io/widget/success")).toBe(true);
  });

  test("wildcard: prefix-bypass https://evil-view.bookbed.io/... REJECTED (3 parts vs 3 parts)", () => {
    expect(isAllowedReturnUrl("https://evil-view.bookbed.io/cb")).toBe(false);
  });

  test("wildcard: http (not https) on subdomain REJECTED", () => {
    expect(isAllowedReturnUrl("http://jasko-rab.view.bookbed.io/cb")).toBe(false);
  });

  test("wildcard: deep subdomain https://x.y.view.bookbed.io/... ALLOWED", () => {
    expect(isAllowedReturnUrl("https://x.y.view.bookbed.io/cb")).toBe(true);
  });
});

describe("getAllowedReturnDomains / isAllowedReturnUrl — H-2 SF-073 localhost gate", () => {
  beforeEach(clearEnv);

  test("PROD default (no env): http://localhost REJECTED", () => {
    expect(isAllowedReturnUrl("http://localhost/cb")).toBe(false);
    expect(isAllowedReturnUrl("http://localhost:5000/cb")).toBe(false);
  });

  test("PROD default (no env): http://127.0.0.1 REJECTED", () => {
    expect(isAllowedReturnUrl("http://127.0.0.1/cb")).toBe(false);
    expect(isAllowedReturnUrl("http://127.0.0.1:5000/cb")).toBe(false);
  });

  test("PROD bookbed-dev project + NO emulator: localhost REJECTED", () => {
    process.env.GCP_PROJECT = "bookbed-dev";
    expect(isAllowedReturnUrl("http://localhost/cb")).toBe(false);
  });

  test("emulator (FUNCTIONS_EMULATOR=true): http://localhost ALLOWED", () => {
    process.env.FUNCTIONS_EMULATOR = "true";
    expect(isAllowedReturnUrl("http://localhost/cb")).toBe(true);
    expect(isAllowedReturnUrl("http://localhost:5000/cb")).toBe(true);
  });

  test("emulator: http://127.0.0.1 ALLOWED", () => {
    process.env.FUNCTIONS_EMULATOR = "true";
    expect(isAllowedReturnUrl("http://127.0.0.1/cb")).toBe(true);
  });

  test("PROD allowlist excludes localhost entries", () => {
    const list = getAllowedReturnDomains();
    expect(list).not.toContain("http://localhost");
    expect(list).not.toContain("http://127.0.0.1");
  });

  test("emulator allowlist includes localhost entries", () => {
    process.env.FUNCTIONS_EMULATOR = "true";
    const list = getAllowedReturnDomains();
    expect(list).toContain("http://localhost");
    expect(list).toContain("http://127.0.0.1");
  });

  test("bookbed-dev project (no emulator): dev hosting domains added, no localhost", () => {
    process.env.GCP_PROJECT = "bookbed-dev";
    const list = getAllowedReturnDomains();
    expect(list).toContain("https://bookbed-widget-dev.web.app");
    expect(list).toContain("https://bookbed-owner-dev.web.app");
    expect(list).not.toContain("http://localhost");
  });

  test("PROD project (rab-booking-248fc): only base + no localhost", () => {
    process.env.GCP_PROJECT = "rab-booking-248fc";
    const list = getAllowedReturnDomains();
    expect(list).toEqual([
      "https://bookbed.io",
      "https://app.bookbed.io",
      "https://view.bookbed.io",
    ]);
  });
});
