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

    // Adriagate re-exports, so this should be a high confidence echo
    expect(result.confidence).toBeGreaterThanOrEqual(0.85);
    expect(result.isProbableEcho).toBe(true);
    // Might be auto_skip or flag_review depending on exact score, but definitely an echo
    expect(["auto_skip", "flag_review"]).toContain(result.recommendedAction);
    expect(result.matchedBookingId).toBe("booking-1");
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

  // Scenario 4: Different Duration (Likely not an echo)
  it("should not flag events with different durations", () => {
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

    // Duration mismatch usually kills confidence
    expect(result.confidence).toBeLessThan(0.85);
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
});
