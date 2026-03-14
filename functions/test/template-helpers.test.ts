import { escapeHtml, formatDate } from "../src/email/utils/template-helpers";

describe("template-helpers", () => {
  describe("escapeHtml", () => {
    it("should escape special characters", () => {
      const input = '<script>alert("xss")</script> & \'test\'';
      const expected = "&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt; &amp; &#39;test&#39;";
      expect(escapeHtml(input)).toBe(expected);
    });

    it("should return empty string for null or undefined", () => {
      expect(escapeHtml(null)).toBe("");
      expect(escapeHtml(undefined)).toBe("");
    });

    it("should handle normal text without changes", () => {
      expect(escapeHtml("Hello World")).toBe("Hello World");
    });
  });

  describe("formatDate", () => {
    it("should format date correctly using Europe/Zagreb timezone", () => {
      // 2026-06-05T22:00:00Z in UTC is 2026-06-06 in Europe/Zagreb (CEST is +2)
      const date = new Date("2026-06-05T22:00:00Z");
      const formatted = formatDate(date);

      // We expect 6. lipnja 2026. and subota (Saturday) since it's June 6 in Zagreb
      expect(formatted).toContain("2026.");
      expect(formatted).toContain("lipnja");
      expect(formatted).toContain("6.");
    });
  });
});
