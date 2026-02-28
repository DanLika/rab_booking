import { formatDate, escapeHtml } from "../src/email/utils/template-helpers";

describe("template-helpers", () => {
  describe("formatDate", () => {
    it("should format dates using Europe/Zagreb timezone in Croatian locale", () => {
      // Create a date that would be different in UTC vs Europe/Zagreb
      // e.g. 23:00 UTC on Jan 1st is 00:00 (Jan 2nd) in Europe/Zagreb
      const date = new Date("2026-01-01T23:30:00Z");
      const formatted = formatDate(date);

      // Verify the formatted date correctly reflects the local time
      expect(formatted).toContain("2. siječnja 2026.");
      expect(formatted).toContain("petak"); // Jan 2, 2026 is a Friday
    });
  });

  describe("escapeHtml", () => {
    it("should escape all required HTML characters", () => {
      const input = `<script>alert("XSS & fun")</script> 'test'`;
      const expected = `&lt;script&gt;alert(&quot;XSS &amp; fun&quot;)&lt;/script&gt; &#39;test&#39;`;
      expect(escapeHtml(input)).toBe(expected);
    });

    it("should handle null and undefined", () => {
      expect(escapeHtml(null)).toBe("");
      expect(escapeHtml(undefined)).toBe("");
    });
  });
});
