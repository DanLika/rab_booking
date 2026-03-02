import { analyzeEvent, ExistingBooking } from "../src/utils/echoDetection";

describe("Echo Detection Engine", () => {
  // Helper to create dates
  const createDate = (daysFromNow: number) => {
    const date = new Date();
    date.setUTCHours(0, 0, 0, 0);
    date.setUTCDate(date.getUTCDate() + daysFromNow);
    return date;
  };

  const today = new Date();

  // Scenario 1: No match found (Unique Event)
  it("should recommend save_unique for a unique event with no matching bookings", () => {
    const newEvent = {
      checkIn: createDate(10),
      checkOut: createDate(15), // 5 nights
      source: "airbnb",
      importedAt: today,
    };

    const existingBookings: ExistingBooking[] = [
      {
        id: "booking-1",
        type: "booking",
        checkIn: createDate(20),
        checkOut: createDate(25),
        source: "booking_com",
        importedAt: createDate(-1),
      },
    ];

    const result = analyzeEvent(newEvent, existingBookings);

    expect(result.recommendedAction).toBe("save_unique");
    expect(result.confidence).toBe(0);
    expect(result.isProbableEcho).toBe(false);
  });

  // Scenario 2: Exact Match (Aggregator Echo)
  it("should detect an exact echo from an aggregator", () => {
    const checkIn = createDate(10);
    const checkOut = createDate(15);

    const newEvent = {
      checkIn: checkIn,
      checkOut: checkOut,
      source: "adriagate", // Aggregator
      importedAt: today,
    };

    const existingBookings: ExistingBooking[] = [
      {
        id: "booking-1",
        type: "booking",
        checkIn: checkIn,
        checkOut: checkOut,
        source: "direct", // Native booking
        importedAt: createDate(-1), // Imported earlier
      },
    ];

    const result = analyzeEvent(newEvent, existingBookings);

    // Adriagate re-exports — containment analysis catches exact overlap → auto_skip
    expect(result.confidence).toBeGreaterThanOrEqual(0.85);
    expect(result.isProbableEcho).toBe(true);
    // 100% containment → auto_skip (via N:1 containment path, not 1:1 match)
    expect(result.recommendedAction).toBe("auto_skip");
  });

  // Scenario 3: Date Shift Echo (Holiday-Home)
  it("should detect a date-shifted echo from Holiday-Home", () => {
    const originalCheckIn = createDate(10);
    const originalCheckOut = createDate(15);

    // Holiday-Home shifts dates by 29 days (known bug)
    const shiftedCheckIn = createDate(10 + 29);
    const shiftedCheckOut = createDate(15 + 29);

    const newEvent = {
      checkIn: shiftedCheckIn,
      checkOut: shiftedCheckOut,
      source: "holiday-home",
      importedAt: today,
    };

    const existingBookings: ExistingBooking[] = [
      {
        id: "booking-1",
        type: "booking",
        checkIn: originalCheckIn,
        checkOut: originalCheckOut,
        source: "direct",
        importedAt: createDate(-1),
      },
    ];

    const result = analyzeEvent(newEvent, existingBookings);

    // Should detect despite date shift
    expect(result.confidence).toBeGreaterThanOrEqual(0.85);
    expect(result.isProbableEcho).toBe(true);
    expect(result.matchedBookingId).toBe("booking-1");
  });

  // Scenario 4: Aggregator partial overlap → save_trimmed (not save_unique)
  // Adriagate event covers days 10-15 (5 nights), existing booking covers days 10-12 (2 nights).
  // Containment = 2/5 = 40% → save_trimmed with 3 new nights (days 12-15).
  it("should save_trimmed for aggregator events with partial overlap", () => {
    const checkIn = createDate(10);

    const newEvent = {
      checkIn: checkIn,
      checkOut: createDate(15), // 5 nights
      source: "adriagate",
      importedAt: today,
    };

    const existingBookings: ExistingBooking[] = [
      {
        id: "booking-1",
        type: "booking",
        checkIn: checkIn,
        checkOut: createDate(12), // 2 nights
        source: "direct",
        importedAt: createDate(-1),
      },
    ];

    const result = analyzeEvent(newEvent, existingBookings);

    // Aggregator with partial overlap → save_trimmed
    expect(result.recommendedAction).toBe("save_trimmed");
    expect(result.trimmedRanges).toBeDefined();
    expect(result.trimmedRanges!.length).toBe(1); // One contiguous new range
    expect(result.containmentRatio).toBeCloseTo(0.4, 1); // 2/5 nights blocked
  });

  // Scenario 4b: Non-aggregator (authoritative) with different durations → save_unique
  it("should not flag events with different durations from authoritative sources", () => {
    const checkIn = createDate(10);

    const newEvent = {
      checkIn: checkIn,
      checkOut: createDate(15), // 5 nights
      source: "airbnb", // Authoritative — containment analysis doesn't apply
      importedAt: today,
    };

    const existingBookings: ExistingBooking[] = [
      {
        id: "booking-1",
        type: "booking",
        checkIn: checkIn,
        checkOut: createDate(12), // 2 nights
        source: "direct",
        importedAt: createDate(-1),
      },
    ];

    const result = analyzeEvent(newEvent, existingBookings);

    // Authoritative source — containment not used, standard 1:1 matching
    expect(result.recommendedAction).toBe("save_unique");
  });

  // Scenario 5: Containment (Merged Echo)
  it("should detect a merged echo covering multiple existing bookings", () => {
    const checkIn1 = createDate(10);
    const checkOut1 = createDate(15);
    const checkIn2 = createDate(15);
    const checkOut2 = createDate(20);

    // Merged event covers both ranges: 10 to 20
    const newEvent = {
      checkIn: checkIn1,
      checkOut: checkOut2,
      source: "adriagate",
      importedAt: today,
    };

    const existingBookings: ExistingBooking[] = [
      {
        id: "booking-1",
        type: "booking",
        checkIn: checkIn1,
        checkOut: checkOut1,
        source: "direct",
        importedAt: createDate(-1),
      },
      {
        id: "booking-2",
        type: "booking",
        checkIn: checkIn2,
        checkOut: checkOut2,
        source: "direct",
        importedAt: createDate(-1),
      },
    ];

    const result = analyzeEvent(newEvent, existingBookings);

    // Should detect containment
    expect(result.confidence).toBeGreaterThanOrEqual(0.95); // High confidence for exact union
    expect(result.recommendedAction).toBe("auto_skip");
    expect(result.reasons.some(r => r.includes("Merged echo"))).toBe(true);
  });

  // Scenario 6: Temporal Analysis (Aggregator)
  it("should auto-skip exact aggregator matches even if arriving close together (containment logic)", () => {
    const checkIn = createDate(10);
    const checkOut = createDate(15);
    const now = new Date();

    const newEvent = {
      checkIn: checkIn,
      checkOut: checkOut,
      source: "adriagate",
      importedAt: now,
    };

    const existingBookings: ExistingBooking[] = [
      {
        id: "booking-1",
        type: "ical_event",
        checkIn: checkIn,
        checkOut: checkOut,
        source: "airbnb",
        importedAt: new Date(now.getTime() - 5 * 60000), // 5 minutes ago
      },
    ];

    const result = analyzeEvent(newEvent, existingBookings);

    // Due to containment logic for aggregators, exact 1:1 match boosts confidence to 1.0
    expect(result.recommendedAction).toBe("auto_skip");
  });

  // Scenario 7: Temporal Analysis - True Echo (Long Delay)
  it("should treat events arriving with delay as echoes", () => {
    const checkIn = createDate(10);
    const checkOut = createDate(15);
    const now = new Date();

    const newEvent = {
      checkIn: checkIn,
      checkOut: checkOut,
      source: "adriagate", // Aggregator
      importedAt: now,
    };

    const existingBookings: ExistingBooking[] = [
      {
        id: "booking-1",
        type: "booking", // Native booking
        checkIn: checkIn,
        checkOut: checkOut,
        source: "direct",
        importedAt: new Date(now.getTime() - 3 * 60 * 60000), // 3 hours ago
      },
    ];

    const result = analyzeEvent(newEvent, existingBookings);

    // High confidence due to temporal match
    expect(result.confidence).toBeGreaterThanOrEqual(0.85);
  });

  // ============================================================
  // Interval Subtraction Tests
  // ============================================================

  describe("Interval Subtraction (save_trimmed)", () => {
    // The real-world Adriagate scenario from the plan:
    // BookBed has Booking A (Jul 19-31) + Booking B (Jul 31-Aug 7).
    // Adriagate gets a native booking Aug 7-14.
    // Adriagate merges everything into one VEVENT: Jul 19-Aug 14.
    // Expected: save_trimmed with trimmedRanges = [{Aug 7, Aug 14}]
    it("should trim Adriagate merged event to only new dates (real-world scenario)", () => {
      // Use fixed dates to avoid flaky relative-date issues
      const jul19 = new Date("2026-07-19T00:00:00Z");
      const jul31 = new Date("2026-07-31T00:00:00Z");
      const aug07 = new Date("2026-08-07T00:00:00Z");
      const aug14 = new Date("2026-08-14T00:00:00Z");

      const newEvent = {
        checkIn: jul19,
        checkOut: aug14,  // Merged: 26 nights
        source: "adriagate",
        importedAt: new Date(),
      };

      const existingBookings: ExistingBooking[] = [
        {
          id: "booking-a",
          type: "booking",
          checkIn: jul19,
          checkOut: jul31,  // 12 nights
          source: "direct",
          importedAt: new Date("2026-07-01T00:00:00Z"),
        },
        {
          id: "booking-b",
          type: "booking",
          checkIn: jul31,
          checkOut: aug07,  // 7 nights
          source: "direct",
          importedAt: new Date("2026-07-20T00:00:00Z"),
        },
      ];

      const result = analyzeEvent(newEvent, existingBookings);

      expect(result.recommendedAction).toBe("save_trimmed");
      expect(result.trimmedRanges).toBeDefined();
      expect(result.trimmedRanges!.length).toBe(1);
      // New range should be Aug 7 to Aug 14 (7 nights)
      expect(result.trimmedRanges![0].startDate.toISOString().slice(0, 10)).toBe("2026-08-07");
      expect(result.trimmedRanges![0].endDate.toISOString().slice(0, 10)).toBe("2026-08-14");
      // 19/26 nights blocked
      expect(result.containmentRatio).toBeCloseTo(19 / 26, 2);
      expect(result.reasons.some(r => r.includes("interval subtraction"))).toBe(true);
    });

    // Pure echo (100% containment) → auto_skip (not save_trimmed)
    it("should auto_skip when 100% of nights are already blocked", () => {
      const checkIn = createDate(10);
      const checkOut = createDate(20);

      const newEvent = {
        checkIn,
        checkOut,
        source: "adriagate",
        importedAt: new Date(),
      };

      const existingBookings: ExistingBooking[] = [
        {
          id: "booking-1",
          type: "booking",
          checkIn: createDate(10),
          checkOut: createDate(15),
          source: "direct",
          importedAt: createDate(-1),
        },
        {
          id: "booking-2",
          type: "booking",
          checkIn: createDate(15),
          checkOut: createDate(20),
          source: "direct",
          importedAt: createDate(-1),
        },
      ];

      const result = analyzeEvent(newEvent, existingBookings);

      expect(result.recommendedAction).toBe("auto_skip");
      expect(result.trimmedRanges).toBeUndefined();
    });

    // 0% containment (no overlap) → save_unique (falls through)
    it("should save_unique when aggregator event has zero overlap", () => {
      const newEvent = {
        checkIn: createDate(30),
        checkOut: createDate(37),
        source: "adriagate",
        importedAt: new Date(),
      };

      const existingBookings: ExistingBooking[] = [
        {
          id: "booking-1",
          type: "booking",
          checkIn: createDate(10),
          checkOut: createDate(15),
          source: "direct",
          importedAt: createDate(-1),
        },
      ];

      const result = analyzeEvent(newEvent, existingBookings);

      // No overlap → falls through to 1:1 logic → no match → save_unique
      expect(result.recommendedAction).toBe("save_unique");
      expect(result.trimmedRanges).toBeUndefined();
    });

    // Multiple non-contiguous new ranges (gap in the middle)
    it("should create multiple trimmed ranges for non-contiguous new nights", () => {
      // Merged event: days 10-25 (15 nights)
      // Existing: days 12-18 (6 nights) — blocks the middle
      // Expected new ranges: [10-12] and [18-25]
      const newEvent = {
        checkIn: createDate(10),
        checkOut: createDate(25),
        source: "adriagate",
        importedAt: new Date(),
      };

      const existingBookings: ExistingBooking[] = [
        {
          id: "booking-1",
          type: "booking",
          checkIn: createDate(12),
          checkOut: createDate(18),
          source: "direct",
          importedAt: createDate(-1),
        },
      ];

      const result = analyzeEvent(newEvent, existingBookings);

      expect(result.recommendedAction).toBe("save_trimmed");
      expect(result.trimmedRanges).toBeDefined();
      expect(result.trimmedRanges!.length).toBe(2); // Two non-contiguous ranges
      // 6/15 nights blocked
      expect(result.containmentRatio).toBeCloseTo(6 / 15, 2);
    });

    // PRIORITY TEST: 1:1 confidence 0.90 + 50% containment → save_trimmed (not flag_review)
    it("should prefer save_trimmed over flag_review when containment detects overlap", () => {
      // Adriagate event: days 10-20 (10 nights)
      // Existing booking: days 10-15 (5 nights) — same check-in, 50% overlap
      // 1:1 matching would give moderate confidence (same checkin, different checkout)
      // but containment should override with save_trimmed
      const newEvent = {
        checkIn: createDate(10),
        checkOut: createDate(20), // 10 nights
        source: "adriagate",
        importedAt: new Date(),
      };

      const existingBookings: ExistingBooking[] = [
        {
          id: "booking-1",
          type: "booking",
          checkIn: createDate(10),
          checkOut: createDate(15), // 5 nights — same checkin, different duration
          source: "direct",
          importedAt: new Date(Date.now() - 3 * 60 * 60 * 1000), // 3 hours ago (temporal factor boost)
        },
      ];

      const result = analyzeEvent(newEvent, existingBookings);

      // Containment should win: 5/10 nights blocked → save_trimmed
      expect(result.recommendedAction).toBe("save_trimmed");
      expect(result.recommendedAction).not.toBe("flag_review");
      expect(result.trimmedRanges).toBeDefined();
      expect(result.trimmedRanges!.length).toBe(1);
      expect(result.containmentRatio).toBeCloseTo(0.5, 1);
    });

    // Timezone offset: booking stored at 22:00 UTC (= midnight Zagreb CEST)
    // vs VEVENT parsed at 06:00 UTC — must resolve to same Zagreb calendar date
    it("should handle timezone offset between booking and VEVENT dates", () => {
      // Booking at 22:00 UTC (= midnight Zagreb CEST, Aug 17)
      const bookingCheckIn = new Date("2026-08-16T22:00:00Z");   // Aug 17 in Zagreb
      const bookingCheckOut = new Date("2026-08-30T22:00:00Z");  // Aug 31 in Zagreb

      // VEVENT at 06:00 UTC (typical iCal parser output, Aug 17)
      const veventCheckIn = new Date("2026-08-17T06:00:00Z");    // Aug 17 in Zagreb
      const veventCheckOut = new Date("2026-08-31T06:00:00Z");   // Aug 31 in Zagreb

      const newEvent = {
        checkIn: veventCheckIn,
        checkOut: veventCheckOut,
        source: "adriagate",
        importedAt: new Date(),
      };

      const existingBookings: ExistingBooking[] = [{
        id: "booking-tz",
        type: "booking",
        checkIn: bookingCheckIn,
        checkOut: bookingCheckOut,
        source: "direct",
        importedAt: new Date("2026-08-01T00:00:00Z"),
      }];

      const result = analyzeEvent(newEvent, existingBookings);

      // Must be 100% containment (14/14 nights) → auto_skip
      expect(result.recommendedAction).toBe("auto_skip");
    });

    // Sanity check: timezone conversion produces correct night count
    it("should produce correct YYYY-MM-DD dates via Zagreb timezone conversion", () => {
      // 22:00 UTC = midnight Zagreb (CEST, UTC+2) → should be Aug 17, not Aug 16
      const date = new Date("2026-08-16T22:00:00Z");

      const result = analyzeEvent(
        {checkIn: date, checkOut: new Date("2026-08-17T22:00:00Z"), source: "adriagate", importedAt: new Date()},
        [{id: "b1", type: "booking", checkIn: date, checkOut: new Date("2026-08-17T22:00:00Z"), source: "direct", importedAt: new Date()}]
      );
      // If timezone handling works, 1/1 night overlap → auto_skip
      expect(result.recommendedAction).toBe("auto_skip");
    });

    // Real overbooking: single covering booking with different duration → flag_review
    it("should flag_review when single booking covers all nights but duration differs", () => {
      // Adriagate: Aug 7-14 (7 nights), BookBed: Aug 7-15 (8 nights)
      // 100% contained but 7 ≠ 8 → NOT an echo → flag_review
      const aug07 = new Date("2026-08-07T00:00:00Z");
      const aug14 = new Date("2026-08-14T00:00:00Z");
      const aug15 = new Date("2026-08-15T00:00:00Z");

      const newEvent = {
        checkIn: aug07,
        checkOut: aug14, // 7 nights from Adriagate
        source: "adriagate",
        importedAt: new Date(),
      };

      const existingBookings: ExistingBooking[] = [
        {
          id: "booking-bb",
          type: "booking",
          checkIn: aug07,
          checkOut: aug15, // 8 nights on BookBed
          source: "direct",
          importedAt: new Date("2026-08-01T00:00:00Z"),
        },
      ];

      const result = analyzeEvent(newEvent, existingBookings);

      // 100% contained but duration mismatch (7 vs 8) → flag_review
      expect(result.recommendedAction).toBe("flag_review");
      expect(result.isProbableEcho).toBe(false);
      expect(result.containmentRatio).toBe(1.0);
      expect(result.reasons.some(r => r.includes("overbooking"))).toBe(true);
    });

    // True echo: single covering booking with SAME duration → auto_skip
    it("should auto_skip when single booking covers all nights with same duration", () => {
      // Adriagate: Aug 7-15 (8 nights), BookBed: Aug 7-15 (8 nights)
      // 100% contained AND 8 = 8 → echo → auto_skip
      const aug07 = new Date("2026-08-07T00:00:00Z");
      const aug15 = new Date("2026-08-15T00:00:00Z");

      const newEvent = {
        checkIn: aug07,
        checkOut: aug15, // 8 nights from Adriagate
        source: "adriagate",
        importedAt: new Date(),
      };

      const existingBookings: ExistingBooking[] = [
        {
          id: "booking-bb",
          type: "booking",
          checkIn: aug07,
          checkOut: aug15, // 8 nights on BookBed — same duration
          source: "direct",
          importedAt: new Date("2026-08-01T00:00:00Z"),
        },
      ];

      const result = analyzeEvent(newEvent, existingBookings);

      // Same duration → genuine echo → auto_skip
      expect(result.recommendedAction).toBe("auto_skip");
      expect(result.isProbableEcho).toBe(true);
    });

    // Turnover day: checkout == checkin → no overlap on that night
    it("should handle turnover days correctly (checkout==checkin has no night overlap)", () => {
      // Event: days 15-22 (7 nights)
      // Existing: days 10-15 (checkout on day 15 = no night 15 blocked)
      // Expected: 0% containment → save_unique (falls through)
      const newEvent = {
        checkIn: createDate(15),
        checkOut: createDate(22),
        source: "adriagate",
        importedAt: new Date(),
      };

      const existingBookings: ExistingBooking[] = [
        {
          id: "booking-1",
          type: "booking",
          checkIn: createDate(10),
          checkOut: createDate(15), // Checkout on day 15 — night 15 NOT blocked
          source: "direct",
          importedAt: createDate(-1),
        },
      ];

      const result = analyzeEvent(newEvent, existingBookings);

      // Night sets don't overlap (checkout exclusive), so 0% containment
      // Falls through to 1:1 matching → no date match → save_unique
      expect(result.recommendedAction).toBe("save_unique");
    });
  });
});
