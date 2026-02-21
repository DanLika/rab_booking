import {
  formatDate,
  escapeHtml,
  formatCurrency,
  calculateNights,
} from "../src/email/utils/template-helpers";

describe("Email Template Helpers", () => {
  describe("formatDate", () => {
    it("should format date in Croatian locale with Zagreb timezone", () => {
      // Create a date that is definitely different in UTC vs Zagreb
      // 2026-06-01 00:00:00 UTC is 2026-06-01 02:00:00 CEST (Zagreb)
      // 2026-06-01 23:00:00 UTC is 2026-06-02 01:00:00 CEST (Zagreb)

      const date = new Date("2026-06-01T23:00:00Z");
      const formatted = formatDate(date);

      // Should show June 2nd because of +2h offset
      expect(formatted).toContain("2. lipnja 2026.");
    });

    it("should handle different months correctly", () => {
      const date = new Date("2026-01-01T12:00:00Z");
      const formatted = formatDate(date);
      expect(formatted).toContain("1. siječnja 2026.");
    });
  });

  describe("escapeHtml", () => {
    it("should escape special characters", () => {
      const unsafe = '<script>alert("xss")</script>';
      const safe = escapeHtml(unsafe);
      expect(safe).toBe("&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;");
    });

    it("should handle ampersands", () => {
      const unsafe = "Me & You";
      const safe = escapeHtml(unsafe);
      expect(safe).toBe("Me &amp; You");
    });

    it("should return empty string for null/undefined", () => {
      expect(escapeHtml(null)).toBe("");
      expect(escapeHtml(undefined)).toBe("");
    });
  });

  describe("formatCurrency", () => {
    it("should format EUR correctly", () => {
      expect(formatCurrency(123.45)).toBe("€123.45");
      expect(formatCurrency(100)).toBe("€100.00");
      expect(formatCurrency(0)).toBe("€0.00");
    });
  });

  describe("calculateNights", () => {
    it("should calculate nights between dates", () => {
      const checkIn = new Date("2026-06-01");
      const checkOut = new Date("2026-06-05");
      expect(calculateNights(checkIn, checkOut)).toBe(4);
    });

    it("should round up for partial days", () => {
      const checkIn = new Date("2026-06-01T14:00:00");
      const checkOut = new Date("2026-06-02T10:00:00");
      // Less than 24 hours but spans a night contextually, though logic is purely diff/msPerDay rounded
      // The implementation is Math.ceil(diffTime / (1000 * 60 * 60 * 24))
      // 20 hours diff -> 20/24 = 0.83 -> ceil -> 1
      expect(calculateNights(checkIn, checkOut)).toBe(1);
    });
  });
});
