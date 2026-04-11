import { formatDate, escapeHtml, generateButton } from "../../../src/email/utils/template-helpers";

describe("Email Template Helpers", () => {
  describe("formatDate", () => {
    it("should format Date object", () => {
      const date = new Date("2026-05-15T12:00:00Z");
      expect(formatDate(date)).toContain("2026");
    });
  });

  describe("escapeHtml", () => {
    it("should escape basic HTML characters", () => {
      expect(escapeHtml("<script>alert('xss')</script>")).toBe("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;");
      expect(escapeHtml('Hello "World" & Universe')).toBe("Hello &quot;World&quot; &amp; Universe");
    });

    it("should handle empty strings and non-strings", () => {
      expect(escapeHtml("")).toBe("");
      expect(escapeHtml(null as any)).toBe("");
      expect(escapeHtml(undefined as any)).toBe("");
    });
  });

  describe("generateButton", () => {
    it("should generate a primary button", () => {
      const btn = generateButton({ url: "https://example.com", text: "Click Me" });
      expect(btn).toContain("https://example.com");
      expect(btn).toContain("Click Me");
      expect(btn).toContain("background-color");
    });
  });
});
