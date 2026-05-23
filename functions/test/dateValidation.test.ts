/**
 * SF-026 — dateValidation.ts unit tests.
 *
 * Cover:
 *  - UTC midnight (Zagreb civil day) normalization at write (STEP 6)
 *  - DST boundary scenarios (spring-forward, fall-back)
 *  - calculateBookingNights output for normalized inputs
 */

jest.mock("../src/firebase", () => {
  return {
    admin: {
      firestore: {
        Timestamp: {
          fromDate: (date: Date) => ({
            toDate: () => date,
            toMillis: () => date.getTime(),
          }),
        },
      },
    },
  };
});

import {
  validateAndConvertBookingDates,
  validateOwnerBookingDates,
  calculateBookingNights,
  normalizeToZagrebCivilDayUTC,
} from "../src/utils/dateValidation";
import {admin} from "../src/firebase";

function ts(date: Date): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(date);
}

describe("normalizeToZagrebCivilDayUTC", () => {
  it("Zagreb midnight summer (UTC+2) maps to UTC midnight of same civil day", () => {
    // Picker emits 2026-06-01T00:00:00+02:00 → parsed as 2026-05-31T22:00:00Z.
    // Civil day in Zagreb = 2026-06-01.
    const input = new Date("2026-05-31T22:00:00Z");
    const normalized = normalizeToZagrebCivilDayUTC(input);
    expect(normalized.toISOString()).toBe("2026-06-01T00:00:00.000Z");
  });

  it("Zagreb midnight winter (UTC+1) maps to UTC midnight of same civil day", () => {
    // 2026-12-01T00:00:00+01:00 → 2026-11-30T23:00:00Z.
    const input = new Date("2026-11-30T23:00:00Z");
    const normalized = normalizeToZagrebCivilDayUTC(input);
    expect(normalized.toISOString()).toBe("2026-12-01T00:00:00.000Z");
  });

  it("UTC noon stays on the same civil day", () => {
    const input = new Date("2026-06-15T12:00:00Z");
    const normalized = normalizeToZagrebCivilDayUTC(input);
    expect(normalized.toISOString()).toBe("2026-06-15T00:00:00.000Z");
  });

  it("Already-UTC-midnight passes through unchanged", () => {
    const input = new Date("2026-06-01T00:00:00Z");
    const normalized = normalizeToZagrebCivilDayUTC(input);
    expect(normalized.toISOString()).toBe("2026-06-01T00:00:00.000Z");
  });

  it("idempotent: normalizing twice yields the same value", () => {
    const input = new Date("2026-05-31T22:00:00Z");
    const once = normalizeToZagrebCivilDayUTC(input);
    const twice = normalizeToZagrebCivilDayUTC(once);
    expect(twice.toISOString()).toBe(once.toISOString());
  });
});

describe("validateAndConvertBookingDates — STEP 6 normalization", () => {
  // Stub `now` so past-date check doesn't reject our test inputs.
  const realDate = Date;
  beforeAll(() => {
    const fixedNow = new realDate("2026-01-01T00:00:00Z").getTime();
    class FakeDate extends realDate {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      constructor(...args: any[]) {
        if (args.length === 0) {
          super(fixedNow);
        } else {
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          super(...(args as [any]));
        }
      }
      static override now() {
        return fixedNow;
      }
    }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (global as any).Date = FakeDate;
  });
  afterAll(() => {
    global.Date = realDate;
  });

  it("Zagreb-civil-day picker input normalizes to UTC midnight of that day", () => {
    const checkIn = "2026-06-01T00:00:00+02:00"; // UTC 2026-05-31T22:00Z
    const checkOut = "2026-06-04T00:00:00+02:00"; // UTC 2026-06-03T22:00Z
    const {checkInDate, checkOutDate} = validateAndConvertBookingDates(
      checkIn,
      checkOut
    );
    expect(checkInDate.toDate().toISOString()).toBe("2026-06-01T00:00:00.000Z");
    expect(checkOutDate.toDate().toISOString()).toBe("2026-06-04T00:00:00.000Z");
  });

  it("DST spring-forward booking yields agreed nights count", () => {
    // Zagreb DST starts 2026-03-29 02:00 local → 03:00 (loses 1h).
    // Booking 2026-03-28 → 2026-04-01: 4 civil nights.
    const checkIn = "2026-03-28T00:00:00+01:00"; // UTC 2026-03-27T23:00Z (winter)
    const checkOut = "2026-04-01T00:00:00+02:00"; // UTC 2026-03-31T22:00Z (summer)
    const {checkInDate, checkOutDate} = validateAndConvertBookingDates(
      checkIn,
      checkOut
    );
    expect(checkInDate.toDate().toISOString()).toBe("2026-03-28T00:00:00.000Z");
    expect(checkOutDate.toDate().toISOString()).toBe("2026-04-01T00:00:00.000Z");

    // Both derivation algorithms agree on 4.
    const tsNights = calculateBookingNights(checkInDate, checkOutDate);
    expect(tsNights).toBe(4);

    const dartFloorNights = Math.floor(
      (checkOutDate.toDate().getTime() - checkInDate.toDate().getTime()) /
        (1000 * 60 * 60 * 24)
    );
    expect(dartFloorNights).toBe(4);
  });

  it("DST fall-back booking yields agreed nights count", () => {
    // Zagreb DST ends 2026-10-25 03:00 local → 02:00 (gains 1h).
    // Booking 2026-10-24 → 2026-10-26: 2 civil nights.
    const checkIn = "2026-10-24T00:00:00+02:00"; // UTC 2026-10-23T22:00Z (summer)
    const checkOut = "2026-10-26T00:00:00+01:00"; // UTC 2026-10-25T23:00Z (winter)
    const {checkInDate, checkOutDate} = validateAndConvertBookingDates(
      checkIn,
      checkOut
    );
    expect(checkInDate.toDate().toISOString()).toBe("2026-10-24T00:00:00.000Z");
    expect(checkOutDate.toDate().toISOString()).toBe("2026-10-26T00:00:00.000Z");

    const tsNights = calculateBookingNights(checkInDate, checkOutDate);
    expect(tsNights).toBe(2);

    const dartFloorNights = Math.floor(
      (checkOutDate.toDate().getTime() - checkInDate.toDate().getTime()) /
        (1000 * 60 * 60 * 24)
    );
    expect(dartFloorNights).toBe(2);
  });

  it("Single-night booking (next-day check-out) yields nights=1", () => {
    const checkIn = "2026-06-01T00:00:00+02:00";
    const checkOut = "2026-06-02T00:00:00+02:00";
    const {checkInDate, checkOutDate} = validateAndConvertBookingDates(
      checkIn,
      checkOut
    );
    expect(calculateBookingNights(checkInDate, checkOutDate)).toBe(1);
  });

  it("Long booking across both DST transitions yields civil-day count", () => {
    // 2026-03-15 → 2026-11-10: 240 civil days in Zagreb.
    const checkIn = "2026-03-15T00:00:00+01:00";
    const checkOut = "2026-11-10T00:00:00+01:00";
    const {checkInDate, checkOutDate} = validateAndConvertBookingDates(
      checkIn,
      checkOut
    );
    expect(calculateBookingNights(checkInDate, checkOutDate)).toBe(240);
  });

  it("Rejects check-out <= check-in", () => {
    expect(() =>
      validateAndConvertBookingDates(
        "2026-06-02T00:00:00+02:00",
        "2026-06-02T00:00:00+02:00"
      )
    ).toThrow(/Check-out date must be after check-in date/);
  });
});

describe("calculateBookingNights", () => {
  it("Returns N for normalized UTC-midnight Timestamps", () => {
    expect(
      calculateBookingNights(
        ts(new Date("2026-06-01T00:00:00Z")),
        ts(new Date("2026-06-04T00:00:00Z"))
      )
    ).toBe(3);
  });

  it("Throws when nights < 1", () => {
    expect(() =>
      calculateBookingNights(
        ts(new Date("2026-06-04T00:00:00Z")),
        ts(new Date("2026-06-04T00:00:00Z"))
      )
    ).toThrow(/< 1 night/);
  });
});

describe("validateOwnerBookingDates — owner-side variant", () => {
  it("Accepts past check-in (owner recording historical stay)", () => {
    // 30 days ago — would fail the widget validator.
    const past = new Date();
    past.setUTCDate(past.getUTCDate() - 30);
    const pastPlus5 = new Date(past);
    pastPlus5.setUTCDate(pastPlus5.getUTCDate() + 5);

    const result = validateOwnerBookingDates(
      past.toISOString(),
      pastPlus5.toISOString()
    );
    expect(result.checkInDate).toBeDefined();
    expect(result.checkOutDate).toBeDefined();
  });

  it("Normalizes to Zagreb civil day (parity with widget validator)", () => {
    // Picker emits 2026-06-01T00:00:00+02:00 → UTC midnight 2026-06-01.
    const result = validateOwnerBookingDates(
      "2026-06-01T00:00:00+02:00",
      "2026-06-04T00:00:00+02:00"
    );
    expect(result.checkInDate.toDate().toISOString()).toBe("2026-06-01T00:00:00.000Z");
    expect(result.checkOutDate.toDate().toISOString()).toBe("2026-06-04T00:00:00.000Z");
  });

  it("Rejects check-out <= check-in", () => {
    expect(() =>
      validateOwnerBookingDates(
        "2026-06-02T00:00:00+02:00",
        "2026-06-02T00:00:00+02:00"
      )
    ).toThrow(/Check-out date must be after check-in date/);
  });

  it("Rejects missing check-in", () => {
    expect(() =>
      validateOwnerBookingDates(undefined, "2026-06-02T00:00:00+02:00")
    ).toThrow(/Check-in date is required/);
  });

  it("Rejects unparseable dates", () => {
    expect(() =>
      validateOwnerBookingDates("not-a-date", "also-not-a-date")
    ).toThrow();
  });
});
