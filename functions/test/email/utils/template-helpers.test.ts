import {formatDate, escapeHtml, calculateNights} from "../../../src/email/utils/template-helpers";

describe("Template Helpers", () => {
  describe("formatDate", () => {
    it("should format dates correctly with Zagreb timezone in Croatian", () => {
      // 2024-05-15T12:00:00Z -> 15. svibnja 2024.
      const date = new Date("2024-05-15T12:00:00Z");
      const formatted = formatDate(date);
      // Depending on Node version, the output might be slightly different. We check for the main parts.
      expect(formatted).toContain("svibnj");
      expect(formatted).toContain("15");
      expect(formatted).toContain("2024");
    });
  });

  describe("escapeHtml", () => {
    it("should escape special characters", () => {
      expect(escapeHtml("<script>alert('test')</script>")).toBe("&lt;script&gt;alert(&#39;test&#39;)&lt;/script&gt;");
      expect(escapeHtml("John & Doe")).toBe("John &amp; Doe");
      expect(escapeHtml("A \"quote\"")).toBe("A &quot;quote&quot;");
    });

    it("should return empty string for falsy values", () => {
      expect(escapeHtml(null as any)).toBe("");
      expect(escapeHtml(undefined as any)).toBe("");
    });
  });

  describe("calculateNights", () => {
    it("should calculate nights correctly", () => {
      const checkIn = new Date("2024-05-01T14:00:00Z");
      const checkOut = new Date("2024-05-04T10:00:00Z");
      expect(calculateNights(checkIn, checkOut)).toBe(3);
    });
  });
});
