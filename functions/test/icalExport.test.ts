import { calculateMinStayGapBlocks, truncateTime, BlockedRange } from "../src/utils/icalUtils";
import { Timestamp } from "firebase-admin/firestore";

describe("iCal Export Helpers", () => {
  describe("truncateTime", () => {
    it("should normalize dates to UTC midnight correctly handling timezone offset", () => {
      // 2026-05-28 00:00 UTC+2 (Europe/Zagreb) -> 2026-05-27 22:00 UTC
      // truncateTime adds 12h -> 2026-05-28 10:00 -> sets to midnight -> 2026-05-28 00:00 UTC
      const date = new Date("2026-05-27T22:00:00Z");
      const truncated = truncateTime(date);
      expect(truncated.toISOString()).toBe("2026-05-28T00:00:00.000Z");
    });

    it("should handle UTC midnight correctly", () => {
      // 2026-05-28 00:00 UTC -> +12h -> 12:00 -> 00:00 same day
      const date = new Date("2026-05-28T00:00:00Z");
      const truncated = truncateTime(date);
      expect(truncated.toISOString()).toBe("2026-05-28T00:00:00.000Z");
    });
  });

  describe("calculateMinStayGapBlocks", () => {
    // Helper to create timestamp from string, simulating UTC dates
    const ts = (dateStr: string) => Timestamp.fromDate(new Date(dateStr));

    it("should return empty array if minStayNights <= 1", () => {
      const bookings = [{
        check_in: ts("2026-01-01T00:00:00Z"),
        check_out: ts("2026-01-05T00:00:00Z")
      }];
      const result = calculateMinStayGapBlocks(bookings, [], [], 1);
      expect(result).toEqual([]);
    });

    it("should detect gap smaller than minStay", () => {
      // Booking A: Jan 1 - Jan 5
      // Booking B: Jan 7 - Jan 10
      // Gap: Jan 5 - Jan 7 (2 nights: Jan 5, Jan 6)
      // Min Stay: 3 nights
      // Expected block: Jan 5 - Jan 6 (inclusive)
      const bookings = [
        { check_in: ts("2026-01-01T00:00:00Z"), check_out: ts("2026-01-05T00:00:00Z") },
        { check_in: ts("2026-01-07T00:00:00Z"), check_out: ts("2026-01-10T00:00:00Z") }
      ];

      const result = calculateMinStayGapBlocks(bookings, [], [], 3);

      expect(result.length).toBe(1);
      expect(result[0].startDate.toISOString()).toContain("2026-01-05");
      expect(result[0].endDate.toISOString()).toContain("2026-01-06");
    });

    it("should NOT block gap >= minStay", () => {
      // Gap: Jan 5 - Jan 8 (3 nights)
      // Min Stay: 3 nights -> Gap fits a 3-night booking -> No block needed
      const bookings = [
        { check_in: ts("2026-01-01T00:00:00Z"), check_out: ts("2026-01-05T00:00:00Z") },
        { check_in: ts("2026-01-08T00:00:00Z"), check_out: ts("2026-01-10T00:00:00Z") }
      ];

      const result = calculateMinStayGapBlocks(bookings, [], [], 3);
      expect(result).toEqual([]);
    });

    it("should merge overlapping bookings and blocked ranges", () => {
      // Booking A: Jan 1 - Jan 5
      // Blocked Range: Jan 4 - Jan 6 (inclusive) -> effectively Jan 4 - Jan 7 (exclusive)
      // Booking B: Jan 9 - Jan 12
      // Merged Interval: Jan 1 - Jan 7
      // Gap: Jan 7 - Jan 9 (2 nights)
      // Min Stay: 3
      // Expected block: Jan 7 - Jan 8
      const bookings = [
        { check_in: ts("2026-01-01T00:00:00Z"), check_out: ts("2026-01-05T00:00:00Z") },
        { check_in: ts("2026-01-09T00:00:00Z"), check_out: ts("2026-01-12T00:00:00Z") },
      ];

      const blockedRanges: BlockedRange[] = [
        { startDate: new Date("2026-01-04T00:00:00Z"), endDate: new Date("2026-01-06T00:00:00Z") }
      ];

      const result = calculateMinStayGapBlocks(bookings, [], blockedRanges, 3);

      expect(result.length).toBe(1);
      expect(result[0].startDate.toISOString()).toContain("2026-01-07");
      expect(result[0].endDate.toISOString()).toContain("2026-01-08");
    });
  });
});
