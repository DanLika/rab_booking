import { escapeHtml, formatDate } from "../src/email/utils/template-helpers";

describe("template-helpers", () => {
  describe("escapeHtml", () => {
    it("should escape malicious characters", () => {
      const input = '<script>alert("xss")</script> & it\'s dangerous';
      const result = escapeHtml(input);
      expect(result).toBe("&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt; &amp; it&#39;s dangerous");
    });

    it("should return empty string for null", () => {
      const result = escapeHtml(null as unknown as string);
      expect(result).toBe("");
    });

    it("should return empty string for undefined", () => {
      const result = escapeHtml(undefined as unknown as string);
      expect(result).toBe("");
    });

    it("should handle empty string correctly", () => {
      const result = escapeHtml("");
      expect(result).toBe("");
    });

    it("should handle numbers implicitly converted to string", () => {
      const result = escapeHtml(123 as unknown as string);
      expect(result).toBe("123");
    });

    it("should leave safe strings unchanged", () => {
      const input = "Hello World!";
      const result = escapeHtml(input);
      expect(result).toBe(input);
    });
  });

  describe("formatDate", () => {
    it("should format date with correct locale and timezone (hr-HR, Europe/Zagreb)", () => {
      // 2026-06-15T23:00:00Z is 2026-06-16T01:00:00+02:00 in Zagreb (CEST)
      const date = new Date("2026-06-15T23:00:00Z");
      const result = formatDate(date);

      // We expect the date to reflect the 16th due to timezone shift
      // In hr-HR locale, it typically formats like: "utorak, 16. lipnja 2026."
      expect(result).toContain("16");
      expect(result).toContain("lipnja");
      expect(result).toContain("2026");
    });
  });
});
