import { escapeHtml, formatDate, calculateNights, formatCurrency } from "../src/email/utils/template-helpers";

describe("template-helpers", () => {
  describe("escapeHtml", () => {
    it("escapes special characters", () => {
      expect(escapeHtml("<script>alert('test')</script>")).toBe("&lt;script&gt;alert(&#39;test&#39;)&lt;/script&gt;");
      expect(escapeHtml("Tom & Jerry")).toBe("Tom &amp; Jerry");
      expect(escapeHtml('"Hello"')).toBe("&quot;Hello&quot;");
    });

    it("handles null or undefined", () => {
      expect(escapeHtml(null)).toBe("");
      expect(escapeHtml(undefined)).toBe("");
    });
  });

  describe("formatDate", () => {
    it("formats date in Croatian locale with Zagreb timezone", () => {
      const date = new Date("2023-12-25T10:00:00Z");
      const formatted = formatDate(date);
      // Depending on Node version, exact output might vary slightly, but it should contain elements of Croatian date
      expect(formatted).toContain("25.");
      expect(formatted).toMatch(/prosinc?a?c?/);
      expect(formatted).toContain("2023.");
      expect(formatted).toContain("ponedjeljak");
    });

    it("handles dates near midnight correctly due to timezone", () => {
      // 23:00 UTC on Dec 24 is 00:00 or 01:00 on Dec 25 in Zagreb
      const date = new Date("2023-12-24T23:00:00Z");
      const formatted = formatDate(date);
      expect(formatted).toContain("25.");
    });
  });

  describe("calculateNights", () => {
    it("calculates correct number of nights", () => {
      const checkIn = new Date("2023-08-01T00:00:00Z");
      const checkOut = new Date("2023-08-05T00:00:00Z");
      expect(calculateNights(checkIn, checkOut)).toBe(4);
    });

    it("handles same day (0 nights)", () => {
      const checkIn = new Date("2023-08-01T00:00:00Z");
      const checkOut = new Date("2023-08-01T00:00:00Z");
      expect(calculateNights(checkIn, checkOut)).toBe(0);
    });
  });

  describe("formatCurrency", () => {
    it("formats currency correctly", () => {
      expect(formatCurrency(100)).toBe("€100.00");
      expect(formatCurrency(100.5)).toBe("€100.50");
      expect(formatCurrency(100.55)).toBe("€100.55");
    });
  });
});
